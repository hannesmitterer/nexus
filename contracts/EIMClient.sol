// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EIMClient - Ethical Inference Monitor Client
 * @notice Automated monitoring and validation of SAN operations with Finalizable interface
 * @dev Part of Euystacio Framework Phase II - Issue #6
 */

interface ITFKVerifier {
    function currentModelCID() external view returns (bytes32);
}

interface IBlacklistManager {
    function isAddressBlacklisted(address entity) external view returns (bool isBlacklisted, bool isPermanent);
    function isCIDBlacklisted(bytes32 cid) external view returns (bool isBlacklisted, bool isPermanent);
    function isDIDBlacklisted(bytes32 did) external view returns (bool isBlacklisted, bool isPermanent);
    function isAnyBlacklisted(address entityAddress, bytes32 entityCID, bytes32 entityDID) external view returns (bool isBlacklisted);
    function activateMISPTrigger(string calldata indicatorType, uint256 severityLevel, bytes32 threatHash, address entityToBlacklist) external;
}

interface IFinalizable {
    /**
     * @notice Finalize a transaction atomically
     * @param operationId Unique identifier for the operation
     * @return success True if finalization succeeded
     */
    function finalize(bytes32 operationId) external returns (bool success);
    
    /**
     * @notice Revert a transaction if validation fails
     * @param operationId Unique identifier for the operation
     * @param reason Human-readable reason for revert
     */
    function revert(bytes32 operationId, string calldata reason) external;
}

contract EIMClient is IFinalizable {
    // ============ State Variables ============
    
    struct SEPValidation {
        bytes32 sepId;              // SEP (Sentinel Evidence Package) ID
        address sanNode;            // SAN (Sentinel AI Node) that generated the SEP
        bytes32 operationHash;      // Hash of the operation
        uint256 timestamp;          // When validation occurred
        bool isValid;               // Validation result
        bool isFinalized;           // Whether operation is finalized
        string artifactType;        // Type of operation (INFERENCE, TRAINING, etc.)
        bytes32 inputDigest;        // Hash of input data
        bytes32 outputDigest;       // Hash of output data
        bytes32 modelDigest;        // Hash of model version used
    }
    
    struct VCETrigger {
        bytes32 sepId;              // SEP that triggered VCE
        address[] reporters;        // EFAs who reported the violation
        uint256 timestamp;          // When VCE was triggered
        bool executed;              // Whether VCE was executed
        string violationType;       // Type of ethical violation
    }
    
    // Validation tracking
    mapping(bytes32 => SEPValidation) public validations;
    mapping(bytes32 => bool) public processedSEPs;
    uint256 public totalValidations;
    uint256 public failedValidations;
    
    // VCE (Veto Consensus Event) tracking
    mapping(bytes32 => VCETrigger) public vceTriggers;
    mapping(bytes32 => mapping(address => bool)) public vceReported; // Track reporters efficiently
    mapping(bytes32 => address) public sepToSAN; // Map SEP ID to SAN node for VCE blacklisting
    uint256 public vceCount;
    
    // Authorized entities
    mapping(address => bool) public authorizedMonitors;  // EIMClient instances
    mapping(address => bool) public authorizedEFAs;      // EFA DIDs for VCE triggers
    mapping(address => bool) public registeredSANs;      // Registered SAN nodes
    
    // Governance
    address public ggcMultisig;
    address public tfkVerifier;  // TFKVerifier contract for model validation
    address public blacklistManager;  // BlacklistManager contract for permanent blocking
    
    // Automation settings
    bool public automationEnabled = true;
    uint256 public vceThreshold = 3;  // Minimum EFAs needed to trigger VCE
    uint256 public validationTimeout = 5 minutes;
    
    // ============ Events ============
    
    event SEPSubmitted(
        bytes32 indexed sepId,
        address indexed sanNode,
        string artifactType,
        uint256 timestamp
    );
    
    event SEPValidated(
        bytes32 indexed sepId,
        bool isValid,
        address indexed validator,
        uint256 timestamp
    );
    
    event OperationFinalized(
        bytes32 indexed operationId,
        bytes32 indexed sepId,
        bool success,
        uint256 timestamp
    );
    
    event OperationReverted(
        bytes32 indexed operationId,
        bytes32 indexed sepId,
        string reason,
        uint256 timestamp
    );
    
    event VCETriggered(
        bytes32 indexed sepId,
        uint256 indexed vceId,
        address[] reporters,
        string violationType,
        uint256 timestamp
    );
    
    event VCEExecuted(
        uint256 indexed vceId,
        bytes32 indexed sepId,
        bool slashingOccurred,
        uint256 timestamp
    );
    
    event TFKVerifierCheckFailed(
        bytes32 indexed operationHash,
        string reason,
        uint256 timestamp
    );
    
    event MonitorAuthorized(address indexed monitor, bool authorized);
    event SANRegistered(address indexed san, bool registered);
    event BlacklistedEntityBlocked(
        address indexed entity,
        bytes32 indexed sepId,
        string reason,
        uint256 timestamp
    );
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig");
        _;
    }
    
    modifier onlyAuthorizedMonitor() {
        require(authorizedMonitors[msg.sender], "Only authorized monitor");
        _;
    }
    
    modifier onlyAuthorizedEFA() {
        require(authorizedEFAs[msg.sender], "Only authorized EFA");
        _;
    }
    
    modifier onlyRegisteredSAN() {
        require(registeredSANs[msg.sender], "Only registered SAN");
        _;
    }
    
    modifier automationActive() {
        require(automationEnabled, "Automation disabled");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig, address _tfkVerifier, address _blacklistManager) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        require(_tfkVerifier != address(0), "Invalid TFKVerifier address");
        // Note: _blacklistManager can be address(0) for backward compatibility
        // It can be set later via updateBlacklistManager()
        
        ggcMultisig = _ggcMultisig;
        tfkVerifier = _tfkVerifier;
        blacklistManager = _blacklistManager;
        
        // Deploy address is first authorized monitor
        authorizedMonitors[address(this)] = true;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Submit a SEP for validation
     * @param sepId Unique SEP identifier (Merkle root hash)
     * @param artifactType Type of operation (INFERENCE_BLOCK, TRAINING_RUN, etc.)
     * @param inputDigest Hash of input data
     * @param outputDigest Hash of output data
     * @param modelDigest Hash of model version used
     * @return operationHash Hash identifying this operation
     */
    function submitSEP(
        bytes32 sepId,
        string calldata artifactType,
        bytes32 inputDigest,
        bytes32 outputDigest,
        bytes32 modelDigest
    ) external onlyRegisteredSAN returns (bytes32 operationHash) {
        require(sepId != bytes32(0), "Invalid SEP ID");
        require(!processedSEPs[sepId], "SEP already processed");
        
        // Check blacklist: Block any blacklisted SAN node or CID
        if (blacklistManager != address(0)) {
            (bool isBlacklisted, ) = IBlacklistManager(blacklistManager).isAddressBlacklisted(msg.sender);
            if (isBlacklisted) {
                emit BlacklistedEntityBlocked(msg.sender, sepId, "Blacklisted SAN node", block.timestamp);
                revert("SAN node is blacklisted");
            }
            
            (bool isCIDBlacklisted, ) = IBlacklistManager(blacklistManager).isCIDBlacklisted(modelDigest);
            if (isCIDBlacklisted) {
                emit BlacklistedEntityBlocked(msg.sender, sepId, "Blacklisted model CID", block.timestamp);
                revert("Model CID is blacklisted");
            }
        }
        
        operationHash = keccak256(
            abi.encodePacked(sepId, msg.sender, block.timestamp)
        );
        
        validations[operationHash] = SEPValidation({
            sepId: sepId,
            sanNode: msg.sender,
            operationHash: operationHash,
            timestamp: block.timestamp,
            isValid: false,  // Pending validation
            isFinalized: false,
            artifactType: artifactType,
            inputDigest: inputDigest,
            outputDigest: outputDigest,
            modelDigest: modelDigest
        });
        
        processedSEPs[sepId] = true;
        sepToSAN[sepId] = msg.sender; // Track SAN for this SEP (for VCE blacklisting)
        totalValidations++;
        
        emit SEPSubmitted(sepId, msg.sender, artifactType, block.timestamp);
        
        // Trigger automatic validation if enabled
        if (automationEnabled) {
            _validateSEP(operationHash);
        }
        
        return operationHash;
    }
    
    /**
     * @notice Validate a submitted SEP
     * @param operationHash The operation to validate
     */
    function validateSEP(bytes32 operationHash) 
        external 
        onlyAuthorizedMonitor 
    {
        _validateSEP(operationHash);
    }
    
    /**
     * @notice Internal validation logic
     * @param operationHash The operation to validate
     */
    function _validateSEP(bytes32 operationHash) internal {
        SEPValidation storage validation = validations[operationHash];
        require(validation.sepId != bytes32(0), "Operation not found");
        require(!validation.isFinalized, "Already finalized");
        
        // Validation checks
        bool isValid = true;
        
        // Check 1: All digests must be non-zero
        if (validation.inputDigest == bytes32(0) || 
            validation.outputDigest == bytes32(0) || 
            validation.modelDigest == bytes32(0)) {
            isValid = false;
        }
        
        // Check 2: Model digest should match current approved model
        // Verify against TFKVerifier to ensure SAN is using approved EAL version
        if (tfkVerifier != address(0)) {
            try ITFKVerifier(tfkVerifier).currentModelCID() returns (bytes32 approvedCID) {
                if (validation.modelDigest != approvedCID) {
                    isValid = false;
                    emit TFKVerifierCheckFailed(
                        operationHash,
                        "Model CID mismatch",
                        block.timestamp
                    );
                }
            } catch {
                // If TFKVerifier call fails, we cannot verify model version
                // Mark as invalid for safety
                isValid = false;
                emit TFKVerifierCheckFailed(
                    operationHash,
                    "TFKVerifier call failed",
                    block.timestamp
                );
            }
        }
        
        // Check 3: Timestamp must be recent (within timeout period)
        if (block.timestamp > validation.timestamp + validationTimeout) {
            isValid = false;
        }
        
        validation.isValid = isValid;
        
        if (!isValid) {
            failedValidations++;
        }
        
        emit SEPValidated(
            validation.sepId, 
            isValid, 
            msg.sender, 
            block.timestamp
        );
        
        // Auto-finalize if valid, or trigger VCE preparation if invalid
        if (isValid) {
            _finalizeOperation(operationHash);
        }
    }
    
    /**
     * @notice Finalize an operation (IFinalizable implementation)
     * @param operationId The operation to finalize
     * @return success True if finalization succeeded
     */
    function finalize(bytes32 operationId) 
        external 
        override 
        returns (bool success) 
    {
        return _finalizeOperation(operationId);
    }
    
    /**
     * @notice Internal finalization logic
     * @param operationHash The operation to finalize
     * @return success True if finalization succeeded
     */
    function _finalizeOperation(bytes32 operationHash) 
        internal 
        returns (bool success) 
    {
        SEPValidation storage validation = validations[operationHash];
        require(validation.sepId != bytes32(0), "Operation not found");
        require(!validation.isFinalized, "Already finalized");
        require(validation.isValid, "Validation failed");
        
        validation.isFinalized = true;
        
        emit OperationFinalized(
            operationHash,
            validation.sepId,
            true,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @notice Revert an operation (IFinalizable implementation)
     * @param operationId The operation to revert
     * @param reason Human-readable reason for revert
     */
    function revert(bytes32 operationId, string calldata reason) 
        external 
        override 
        onlyAuthorizedMonitor 
    {
        SEPValidation storage validation = validations[operationId];
        require(validation.sepId != bytes32(0), "Operation not found");
        require(!validation.isFinalized, "Already finalized");
        
        validation.isFinalized = true;
        validation.isValid = false;
        failedValidations++;
        
        emit OperationReverted(
            operationId,
            validation.sepId,
            reason,
            block.timestamp
        );
    }
    
    /**
     * @notice Trigger a VCE (Veto Consensus Event) for an invalid SEP
     * @param sepId The SEP that violated ethical constraints
     * @param violationType Description of the violation
     */
    function triggerVCE(
        bytes32 sepId,
        string calldata violationType
    ) external onlyAuthorizedEFA automationActive returns (uint256 vceId) {
        require(processedSEPs[sepId], "SEP not found");
        
        // Create unique VCE key including timestamp to prevent collisions
        bytes32 vceKey = keccak256(abi.encodePacked(
            sepId, 
            violationType, 
            vceCount  // Use counter for uniqueness
        ));
        
        VCETrigger storage vce = vceTriggers[vceKey];
        
        if (vce.timestamp == 0) {
            // New VCE
            vceId = vceCount++;
            vce.sepId = sepId;
            vce.timestamp = block.timestamp;
            vce.violationType = violationType;
            vce.executed = false;
        }
        
        // Add reporter if not already added (O(1) lookup via mapping)
        if (!vceReported[vceKey][msg.sender]) {
            vce.reporters.push(msg.sender);
            vceReported[vceKey][msg.sender] = true;
        }
        
        // Execute VCE if threshold reached
        if (vce.reporters.length >= vceThreshold && !vce.executed) {
            emit VCETriggered(
                sepId,
                vceId,
                vce.reporters,
                violationType,
                block.timestamp
            );
            
            // Mark as executed (actual slashing would be done by VCE contract)
            vce.executed = true;
            
            emit VCEExecuted(vceId, sepId, true, block.timestamp);
            
            // Trigger MISP policy if VCE threshold is met and blacklist manager is available
            if (blacklistManager != address(0)) {
                // Find the SAN node that submitted this SEP using our mapping
                address violatingSAN = sepToSAN[sepId];
                
                // Only trigger MISP if we have a valid SAN address
                // (sepId might not be in mapping if it predates this feature)
                if (violatingSAN != address(0)) {
                    // Create evidence hash for VCE consensus
                    bytes32 vceEvidenceHash = keccak256(abi.encodePacked(sepId, violationType, "VCE"));
                    
                    // Trigger MISP with critical severity (5) for VCE violations
                    // This will auto-blacklist the violating SAN
                    try IBlacklistManager(blacklistManager).activateMISPTrigger(
                        violationType,
                        5,  // Critical severity
                        vceEvidenceHash,
                        violatingSAN
                    ) {
                        // MISP trigger activated successfully
                    } catch {
                        // Continue even if MISP trigger fails
                    }
                }
            }
        }
        
        return vceId;
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get validation details
     * @param operationHash The operation hash
     * @return Validation struct data
     */
    function getValidation(bytes32 operationHash)
        external
        view
        returns (
            bytes32 sepId,
            address sanNode,
            uint256 timestamp,
            bool isValid,
            bool isFinalized,
            string memory artifactType
        )
    {
        SEPValidation storage v = validations[operationHash];
        return (
            v.sepId,
            v.sanNode,
            v.timestamp,
            v.isValid,
            v.isFinalized,
            v.artifactType
        );
    }
    
    /**
     * @notice Get VCE trigger details
     * @param vceKey The VCE identifier
     * @return VCE details
     */
    function getVCETrigger(bytes32 vceKey)
        external
        view
        returns (
            bytes32 sepId,
            address[] memory reporters,
            uint256 timestamp,
            bool executed,
            string memory violationType
        )
    {
        VCETrigger storage vce = vceTriggers[vceKey];
        return (
            vce.sepId,
            vce.reporters,
            vce.timestamp,
            vce.executed,
            vce.violationType
        );
    }
    
    /**
     * @notice Get validation statistics
     * @return total, failed, success rate
     */
    function getValidationStats()
        external
        view
        returns (uint256 total, uint256 failed, uint256 successRate)
    {
        total = totalValidations;
        failed = failedValidations;
        if (total > 0) {
            successRate = ((total - failed) * 10000) / total; // Basis points
        }
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Authorize a monitor instance
     * @param monitor The monitor address to authorize
     */
    function authorizeMonitor(address monitor) external onlyGGC {
        require(monitor != address(0), "Invalid address");
        authorizedMonitors[monitor] = true;
        emit MonitorAuthorized(monitor, true);
    }
    
    /**
     * @notice Revoke monitor authorization
     * @param monitor The monitor address to revoke
     */
    function revokeMonitor(address monitor) external onlyGGC {
        authorizedMonitors[monitor] = false;
        emit MonitorAuthorized(monitor, false);
    }
    
    /**
     * @notice Register a SAN node
     * @param san The SAN address to register
     */
    function registerSAN(address san) external onlyGGC {
        require(san != address(0), "Invalid address");
        
        // Check blacklist before registration
        if (blacklistManager != address(0)) {
            (bool isBlacklisted, ) = IBlacklistManager(blacklistManager).isAddressBlacklisted(san);
            require(!isBlacklisted, "Cannot register blacklisted address");
        }
        
        registeredSANs[san] = true;
        emit SANRegistered(san, true);
    }
    
    /**
     * @notice Unregister a SAN node
     * @param san The SAN address to unregister
     */
    function unregisterSAN(address san) external onlyGGC {
        registeredSANs[san] = false;
        emit SANRegistered(san, false);
    }
    
    /**
     * @notice Authorize an EFA for VCE triggers
     * @param efa The EFA address to authorize
     */
    function authorizeEFA(address efa) external onlyGGC {
        require(efa != address(0), "Invalid address");
        authorizedEFAs[efa] = true;
    }
    
    /**
     * @notice Set VCE threshold
     * @param threshold Number of EFAs needed to trigger VCE
     */
    function setVCEThreshold(uint256 threshold) external onlyGGC {
        require(threshold >= 1 && threshold <= 10, "Invalid threshold");
        vceThreshold = threshold;
    }
    
    /**
     * @notice Enable/disable automation
     * @param enabled True to enable, false to disable
     */
    function setAutomationEnabled(bool enabled) external onlyGGC {
        automationEnabled = enabled;
    }
    
    /**
     * @notice Set validation timeout
     * @param timeout Timeout in seconds
     */
    function setValidationTimeout(uint256 timeout) external onlyGGC {
        require(timeout >= 1 minutes && timeout <= 1 hours, "Invalid timeout");
        validationTimeout = timeout;
    }
    
    /**
     * @notice Update GGC multisig address
     * @param newGGC New GGC multisig address
     */
    function updateGGCMultisig(address newGGC) external onlyGGC {
        require(newGGC != address(0), "Invalid address");
        ggcMultisig = newGGC;
    }
    
    /**
     * @notice Update TFKVerifier contract address
     * @param newTFKVerifier New TFKVerifier address
     */
    function updateTFKVerifier(address newTFKVerifier) external onlyGGC {
        require(newTFKVerifier != address(0), "Invalid address");
        tfkVerifier = newTFKVerifier;
    }
    
    /**
     * @notice Update BlacklistManager contract address
     * @param newBlacklistManager New BlacklistManager address (can be address(0) to disable)
     */
    function updateBlacklistManager(address newBlacklistManager) external onlyGGC {
        blacklistManager = newBlacklistManager;
    }
    
    /**
     * @notice Manually trigger MISP policy for a specific SAN
     * @param sanNode SAN address to report
     * @param violationType Type of violation
     * @param severityLevel Severity level (1-5)
     * @param evidenceHash Hash of evidence
     */
    function triggerMISPPolicy(
        address sanNode,
        string calldata violationType,
        uint256 severityLevel,
        bytes32 evidenceHash
    ) external onlyAuthorizedEFA {
        require(blacklistManager != address(0), "BlacklistManager not set");
        require(sanNode != address(0), "Invalid SAN address");
        
        IBlacklistManager(blacklistManager).activateMISPTrigger(
            violationType,
            severityLevel,
            evidenceHash,
            sanNode
        );
    }
}
