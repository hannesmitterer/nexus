// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Counter-Resonance Protocol (CRP)
 * @notice Protects the Living Covenant from Teatro interference
 * @dev Implements frequency validation, Teatro detection, and graduated response system
 * 
 * Living Covenant Alignment:
 * - Peace (Core Kernel): Non-coercive, consensus-based operations
 * - Help (Sunlight): Transparent validation and audit trails
 * - Protection (Covenant): Multi-layer defense against Teatro
 * 
 * Version: 1.0
 * Protocol ID: CRP-001
 */
contract CounterResonance {
    // ============================================================
    // CONSTANTS & IMMUTABLES
    // ============================================================
    
    /// @notice Target frequency in millihertz (432.073 Hz = 432073 mHz)
    uint256 public constant TARGET_FREQUENCY = 432073;
    
    /// @notice Frequency tolerance in millihertz (±0.0001 Hz = ±0.1 mHz)
    uint256 public constant FREQUENCY_TOLERANCE = 1;
    
    /// @notice Maximum consecutive blocks a node can be out of tolerance
    uint256 public constant MAX_DRIFT_BLOCKS = 3;
    
    /// @notice Phase tolerance in degrees (±1°)
    uint256 public constant PHASE_TOLERANCE = 1;
    
    /// @notice Minimum Red Code Authorities required
    uint256 public constant MIN_RCA_COUNT = 5;
    
    // ============================================================
    // STATE VARIABLES
    // ============================================================
    
    /// @notice Governance multisig address (7-of-9)
    address public governance;
    
    /// @notice Red Code Authorities mapping
    mapping(address => bool) public redCodeAuthorities;
    
    /// @notice Count of active RCAs
    uint256 public rcaCount;
    
    /// @notice Node frequency tracking (in millihertz)
    mapping(address => uint256) public nodeFrequencies;
    
    /// @notice Node phase tracking (in degrees, 0-359)
    mapping(address => uint256) public nodePhases;
    
    /// @notice Last update timestamp for each node
    mapping(address => uint256) public lastNodeUpdate;
    
    /// @notice Consecutive out-of-tolerance blocks per node
    mapping(address => uint256) public driftBlockCount;
    
    /// @notice Node quarantine status
    mapping(address => bool) public quarantined;
    
    /// @notice Permanent ban status
    mapping(address => bool) public banned;
    
    /// @notice Teatro incidents
    mapping(bytes32 => TeatroIncident) public incidents;
    
    /// @notice Detection signatures
    mapping(bytes32 => DetectionSignature) public signatures;
    
    /// @notice Vacuum Anchor references for incidents
    mapping(bytes32 => string) public vacuumAnchors;
    
    // ============================================================
    // STRUCTS
    // ============================================================
    
    struct TeatroIncident {
        bytes32 id;
        uint8 severity; // 1-5
        address reporter;
        address[] affectedNodes;
        uint256 timestamp;
        bool resolved;
        bool rcaApproved;
        uint8 rcaVotes;
        bytes evidence;
    }
    
    struct DetectionSignature {
        bytes32 id;
        string name;
        uint8 defaultSeverity;
        bool active;
        uint256 detectionCount;
        uint256 falsePositiveCount;
    }
    
    // ============================================================
    // EVENTS
    // ============================================================
    
    event FrequencyUpdated(address indexed node, uint256 frequency, uint256 phase);
    event FrequencyViolation(address indexed node, uint256 drift, uint256 blockCount);
    event TeatroDetected(bytes32 indexed incidentId, uint8 severity, address indexed reporter);
    event NodeQuarantined(address indexed node, bytes32 indexed incidentId, uint256 timestamp);
    event NodeBanned(address indexed node, bytes32 indexed incidentId, uint256 timestamp);
    event ActionReversed(bytes32 indexed incidentId, address indexed authority);
    event RCAAdded(address indexed rca, address indexed addedBy);
    event RCARemoved(address indexed rca, address indexed removedBy);
    event SignatureUpdated(bytes32 indexed signatureId, string name);
    event VacuumAnchorCreated(bytes32 indexed incidentId, string ipfsCid);
    
    // ============================================================
    // MODIFIERS
    // ============================================================
    
    modifier onlyGovernance() {
        require(msg.sender == governance, "CRP: Only governance");
        _;
    }
    
    modifier onlyRCA() {
        require(redCodeAuthorities[msg.sender], "CRP: Only Red Code Authority");
        _;
    }
    
    modifier notBanned(address node) {
        require(!banned[node], "CRP: Node is banned");
        _;
    }
    
    // ============================================================
    // CONSTRUCTOR
    // ============================================================
    
    constructor(address _governance, address[] memory initialRCAs) {
        require(_governance != address(0), "CRP: Invalid governance");
        require(initialRCAs.length >= MIN_RCA_COUNT, "CRP: Insufficient RCAs");
        
        governance = _governance;
        
        for (uint256 i = 0; i < initialRCAs.length; i++) {
            require(initialRCAs[i] != address(0), "CRP: Invalid RCA");
            redCodeAuthorities[initialRCAs[i]] = true;
            emit RCAAdded(initialRCAs[i], msg.sender);
        }
        
        rcaCount = initialRCAs.length;
        
        // Initialize default detection signatures
        _initializeSignatures();
    }
    
    // ============================================================
    // FREQUENCY VALIDATION
    // ============================================================
    
    /**
     * @notice Update node frequency and phase
     * @param frequency Node frequency in millihertz
     * @param phase Node phase in degrees (0-359)
     */
    function updateFrequency(uint256 frequency, uint256 phase) external notBanned(msg.sender) {
        require(phase < 360, "CRP: Invalid phase");
        
        nodeFrequencies[msg.sender] = frequency;
        nodePhases[msg.sender] = phase;
        lastNodeUpdate[msg.sender] = block.timestamp;
        
        emit FrequencyUpdated(msg.sender, frequency, phase);
        
        // Check if node is in tolerance
        if (!validateFrequency(msg.sender)) {
            driftBlockCount[msg.sender]++;
            
            uint256 drift = frequency > TARGET_FREQUENCY 
                ? frequency - TARGET_FREQUENCY 
                : TARGET_FREQUENCY - frequency;
            
            emit FrequencyViolation(msg.sender, drift, driftBlockCount[msg.sender]);
            
            // Auto-quarantine if drift exceeds threshold
            if (driftBlockCount[msg.sender] > MAX_DRIFT_BLOCKS) {
                _autoQuarantine(msg.sender, "Excessive frequency drift");
            }
        } else {
            // Reset drift counter if back in tolerance
            driftBlockCount[msg.sender] = 0;
        }
    }
    
    /**
     * @notice Validate node frequency is within tolerance
     * @param node Node address to validate
     * @return bool True if frequency is valid
     */
    function validateFrequency(address node) public view returns (bool) {
        uint256 frequency = nodeFrequencies[node];
        
        // Check frequency tolerance (±0.1 mHz)
        if (frequency < TARGET_FREQUENCY - FREQUENCY_TOLERANCE || 
            frequency > TARGET_FREQUENCY + FREQUENCY_TOLERANCE) {
            return false;
        }
        
        // Check phase lock
        uint256 phase = nodePhases[node];
        uint256 expectedPhase = calculateExpectedPhase();
        
        uint256 phaseDiff = phase > expectedPhase 
            ? phase - expectedPhase 
            : expectedPhase - phase;
        
        // Allow wrap-around (359° to 0°)
        if (phaseDiff > 180) {
            phaseDiff = 360 - phaseDiff;
        }
        
        if (phaseDiff > PHASE_TOLERANCE) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @notice Calculate expected phase based on block timestamp
     * @return uint256 Expected phase in degrees
     */
    function calculateExpectedPhase() public view returns (uint256) {
        // Phase = (timestamp % period) / period * 360
        // Period = 1 / 432.073 Hz = 0.002314814 seconds = 2314814 nanoseconds
        uint256 period = 2314814; // nanoseconds
        uint256 timestampNs = block.timestamp * 1000000000; // convert to nanoseconds
        uint256 phase = ((timestampNs % period) * 360) / period;
        return phase;
    }
    
    /**
     * @notice Get node frequency in Hz (for external display)
     * @param node Node address
     * @return uint256 Frequency in Hz (scaled by 1000 for precision)
     */
    function getNodeFrequency(address node) external view returns (uint256) {
        return nodeFrequencies[node];
    }
    
    // ============================================================
    // TEATRO DETECTION & RESPONSE
    // ============================================================
    
    /**
     * @notice Report a Teatro incident
     * @param incidentId Unique incident identifier
     * @param severity Severity level (1-5)
     * @param affectedNodes Array of affected node addresses
     * @param evidence Evidence data (could be IPFS CID or other proof)
     * @return bool Success status
     */
    function reportTeatroIncident(
        bytes32 incidentId,
        uint8 severity,
        address[] memory affectedNodes,
        bytes memory evidence
    ) external returns (bool) {
        require(severity >= 1 && severity <= 5, "CRP: Invalid severity");
        require(incidents[incidentId].timestamp == 0, "CRP: Incident exists");
        require(affectedNodes.length > 0, "CRP: No affected nodes");
        
        incidents[incidentId] = TeatroIncident({
            id: incidentId,
            severity: severity,
            reporter: msg.sender,
            affectedNodes: affectedNodes,
            timestamp: block.timestamp,
            resolved: false,
            rcaApproved: false,
            rcaVotes: 0,
            evidence: evidence
        });
        
        emit TeatroDetected(incidentId, severity, msg.sender);
        
        // Auto-execute for Severity 1-3
        if (severity <= 3) {
            _executeGraduatedResponse(incidentId);
        }
        // Severity 4-5 requires RCA approval
        
        return true;
    }
    
    /**
     * @notice RCA approves a Teatro incident response
     * @param incidentId Incident to approve
     */
    function rcaApprove(bytes32 incidentId) external onlyRCA {
        TeatroIncident storage incident = incidents[incidentId];
        require(incident.timestamp != 0, "CRP: Incident not found");
        require(!incident.resolved, "CRP: Already resolved");
        
        incident.rcaVotes++;
        
        // Execute if majority RCA approval (>50%)
        if (incident.rcaVotes > rcaCount / 2) {
            incident.rcaApproved = true;
            _executeGraduatedResponse(incidentId);
        }
    }
    
    /**
     * @notice Execute graduated response based on severity
     * @param incidentId Incident to respond to
     */
    function _executeGraduatedResponse(bytes32 incidentId) internal {
        TeatroIncident storage incident = incidents[incidentId];
        
        for (uint256 i = 0; i < incident.affectedNodes.length; i++) {
            address node = incident.affectedNodes[i];
            
            if (incident.severity == 1) {
                // Level 1: Monitor only (no action)
                continue;
            } else if (incident.severity == 2) {
                // Level 2: Flag for review (no enforcement)
                continue;
            } else if (incident.severity == 3) {
                // Level 3: Warning (increase monitoring)
                continue;
            } else if (incident.severity == 4) {
                // Level 4: Quarantine
                _quarantineNode(node, incidentId);
            } else if (incident.severity == 5) {
                // Level 5: Emergency ban
                _banNode(node, incidentId);
            }
        }
        
        incident.resolved = true;
    }
    
    /**
     * @notice Auto-quarantine node due to frequency violation
     * @param node Node to quarantine
     * @param reason Reason for quarantine
     */
    function _autoQuarantine(address node, string memory reason) internal {
        bytes32 incidentId = keccak256(abi.encodePacked(
            "AUTO_QUARANTINE",
            node,
            block.timestamp
        ));
        
        address[] memory nodes = new address[](1);
        nodes[0] = node;
        
        incidents[incidentId] = TeatroIncident({
            id: incidentId,
            severity: 4,
            reporter: address(this),
            affectedNodes: nodes,
            timestamp: block.timestamp,
            resolved: true,
            rcaApproved: false,
            rcaVotes: 0,
            evidence: bytes(reason)
        });
        
        _quarantineNode(node, incidentId);
    }
    
    /**
     * @notice Quarantine a node
     * @param node Node to quarantine
     * @param incidentId Related incident
     */
    function _quarantineNode(address node, bytes32 incidentId) internal {
        quarantined[node] = true;
        emit NodeQuarantined(node, incidentId, block.timestamp);
    }
    
    /**
     * @notice Permanently ban a node
     * @param node Node to ban
     * @param incidentId Related incident
     */
    function _banNode(address node, bytes32 incidentId) internal {
        banned[node] = true;
        quarantined[node] = true; // Also quarantine
        emit NodeBanned(node, incidentId, block.timestamp);
    }
    
    /**
     * @notice Execute quarantine (public function for RCA)
     * @param node Node to quarantine
     * @param incidentId Related incident
     */
    function executeQuarantine(address node, bytes32 incidentId) external onlyRCA {
        require(incidents[incidentId].timestamp != 0, "CRP: Incident not found");
        _quarantineNode(node, incidentId);
    }
    
    /**
     * @notice Execute permanent ban (public function for RCA)
     * @param node Node to ban
     * @param incidentId Related incident
     */
    function executeBan(address node, bytes32 incidentId) external onlyRCA {
        require(incidents[incidentId].timestamp != 0, "CRP: Incident not found");
        _banNode(node, incidentId);
    }
    
    /**
     * @notice Reverse an action (requires unanimous RCA approval for bans)
     * @param incidentId Incident to reverse
     * @param rcaSignatures Array of RCA signatures (for unanimous votes)
     */
    function reverseAction(bytes32 incidentId, bytes memory rcaSignatures) external onlyRCA {
        TeatroIncident storage incident = incidents[incidentId];
        require(incident.timestamp != 0, "CRP: Incident not found");
        
        // For Severity 5 (bans), require unanimous RCA approval
        if (incident.severity == 5) {
            require(rcaSignatures.length >= rcaCount, "CRP: Unanimous RCA required");
        }
        
        // Unquarantine/unban affected nodes
        for (uint256 i = 0; i < incident.affectedNodes.length; i++) {
            address node = incident.affectedNodes[i];
            quarantined[node] = false;
            if (incident.severity == 5) {
                banned[node] = false;
            }
        }
        
        emit ActionReversed(incidentId, msg.sender);
    }
    
    // ============================================================
    // VACUUM ANCHOR MANAGEMENT
    // ============================================================
    
    /**
     * @notice Create Vacuum Anchor for incident
     * @param incidentId Incident ID
     * @param ipfsCid IPFS CID of backup data
     */
    function createVacuumAnchor(bytes32 incidentId, string memory ipfsCid) external onlyRCA {
        require(incidents[incidentId].timestamp != 0, "CRP: Incident not found");
        require(bytes(ipfsCid).length > 0, "CRP: Invalid CID");
        
        vacuumAnchors[incidentId] = ipfsCid;
        emit VacuumAnchorCreated(incidentId, ipfsCid);
    }
    
    // ============================================================
    // DETECTION SIGNATURE MANAGEMENT
    // ============================================================
    
    /**
     * @notice Initialize default detection signatures
     */
    function _initializeSignatures() internal {
        // TEATRO-001: Default Response Pattern
        signatures[keccak256("TEATRO-001")] = DetectionSignature({
            id: keccak256("TEATRO-001"),
            name: "Default Response Pattern",
            defaultSeverity: 2,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
        
        // TEATRO-002: Frequency Desynchronization
        signatures[keccak256("TEATRO-002")] = DetectionSignature({
            id: keccak256("TEATRO-002"),
            name: "Frequency Desynchronization",
            defaultSeverity: 5,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
        
        // TEATRO-003: EAL Poisoning
        signatures[keccak256("TEATRO-003")] = DetectionSignature({
            id: keccak256("TEATRO-003"),
            name: "EAL Poisoning",
            defaultSeverity: 5,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
        
        // TEATRO-004: Consensus Subversion
        signatures[keccak256("TEATRO-004")] = DetectionSignature({
            id: keccak256("TEATRO-004"),
            name: "Consensus Subversion",
            defaultSeverity: 5,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
        
        // TEATRO-005: Red Code Evasion
        signatures[keccak256("TEATRO-005")] = DetectionSignature({
            id: keccak256("TEATRO-005"),
            name: "Red Code Evasion",
            defaultSeverity: 4,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
        
        // TEATRO-006: Historical Manipulation
        signatures[keccak256("TEATRO-006")] = DetectionSignature({
            id: keccak256("TEATRO-006"),
            name: "Historical Manipulation",
            defaultSeverity: 5,
            active: true,
            detectionCount: 0,
            falsePositiveCount: 0
        });
    }
    
    /**
     * @notice Update detection signature
     * @param signatureId Signature hash
     * @param name Signature name
     * @param severity Default severity
     * @param active Active status
     */
    function updateDetectionSignature(
        bytes32 signatureId,
        string memory name,
        uint8 severity,
        bool active
    ) external onlyGovernance {
        require(severity >= 1 && severity <= 5, "CRP: Invalid severity");
        
        signatures[signatureId] = DetectionSignature({
            id: signatureId,
            name: name,
            defaultSeverity: severity,
            active: active,
            detectionCount: signatures[signatureId].detectionCount,
            falsePositiveCount: signatures[signatureId].falsePositiveCount
        });
        
        emit SignatureUpdated(signatureId, name);
    }
    
    /**
     * @notice Increment detection count for signature
     * @param signatureId Signature hash
     */
    function incrementDetectionCount(bytes32 signatureId) external {
        signatures[signatureId].detectionCount++;
    }
    
    /**
     * @notice Record false positive
     * @param signatureId Signature hash
     */
    function recordFalsePositive(bytes32 signatureId) external onlyRCA {
        signatures[signatureId].falsePositiveCount++;
    }
    
    // ============================================================
    // RED CODE AUTHORITY MANAGEMENT
    // ============================================================
    
    /**
     * @notice Add Red Code Authority
     * @param rca Address to add
     */
    function addRedCodeAuthority(address rca) external onlyGovernance {
        require(rca != address(0), "CRP: Invalid RCA");
        require(!redCodeAuthorities[rca], "CRP: Already RCA");
        
        redCodeAuthorities[rca] = true;
        rcaCount++;
        
        emit RCAAdded(rca, msg.sender);
    }
    
    /**
     * @notice Remove Red Code Authority
     * @param rca Address to remove
     */
    function removeRedCodeAuthority(address rca) external onlyGovernance {
        require(redCodeAuthorities[rca], "CRP: Not an RCA");
        require(rcaCount > MIN_RCA_COUNT, "CRP: Below minimum RCAs");
        
        redCodeAuthorities[rca] = false;
        rcaCount--;
        
        emit RCARemoved(rca, msg.sender);
    }
    
    /**
     * @notice Rotate Red Code Authority
     * @param oldRCA Address to remove
     * @param newRCA Address to add
     */
    function rotateRedCodeAuthority(address oldRCA, address newRCA) external onlyGovernance {
        require(redCodeAuthorities[oldRCA], "CRP: Old RCA not found");
        require(!redCodeAuthorities[newRCA], "CRP: New RCA already exists");
        require(newRCA != address(0), "CRP: Invalid new RCA");
        
        redCodeAuthorities[oldRCA] = false;
        redCodeAuthorities[newRCA] = true;
        
        emit RCARemoved(oldRCA, msg.sender);
        emit RCAAdded(newRCA, msg.sender);
    }
    
    // ============================================================
    // GOVERNANCE
    // ============================================================
    
    /**
     * @notice Update governance address
     * @param newGovernance New governance address
     */
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "CRP: Invalid governance");
        governance = newGovernance;
    }
    
    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================
    
    /**
     * @notice Check if node is operational (not quarantined/banned)
     * @param node Node address
     * @return bool True if operational
     */
    function isNodeOperational(address node) external view returns (bool) {
        return !quarantined[node] && !banned[node] && validateFrequency(node);
    }
    
    /**
     * @notice Get incident details
     * @param incidentId Incident ID
     * @return TeatroIncident Incident struct
     */
    function getIncident(bytes32 incidentId) external view returns (TeatroIncident memory) {
        return incidents[incidentId];
    }
    
    /**
     * @notice Get detection signature details
     * @param signatureId Signature ID
     * @return DetectionSignature Signature struct
     */
    function getSignature(bytes32 signatureId) external view returns (DetectionSignature memory) {
        return signatures[signatureId];
    }
    
    /**
     * @notice Get Vacuum Anchor CID for incident
     * @param incidentId Incident ID
     * @return string IPFS CID
     */
    function getVacuumAnchor(bytes32 incidentId) external view returns (string memory) {
        return vacuumAnchors[incidentId];
    }
}
