// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title GovernanceMetricsRegistry
 * @notice Registry for tracking governance metrics, quorum, and sustainability thresholds
 * @dev Part of Nexus Governance Framework - Euystacio Protocol
 * 
 * Key Features:
 * - Quorum threshold management for decentralized decision-making
 * - Sustainability metrics tracking (TRE, PV, ISF)
 * - Anchored governance records with immutable audit trail
 * - Multi-signature governance control (7-of-9 GGC)
 */
contract GovernanceMetricsRegistry {
    
    // ============ State Variables ============
    
    /// @notice GGC Multisig address (7-of-9 threshold)
    address public immutable ggcMultisig;
    
    /// @notice Quorum threshold in basis points (e.g., 6700 = 67%)
    uint256 public quorumThresholdBps;
    
    /// @notice Minimum quorum threshold (51%)
    uint256 public constant MIN_QUORUM_BPS = 5100;
    
    /// @notice Maximum quorum threshold (90%)
    uint256 public constant MAX_QUORUM_BPS = 9000;
    
    /// @notice Default quorum threshold (67%)
    uint256 public constant DEFAULT_QUORUM_BPS = 6700;
    
    // ============ Sustainability Thresholds ============
    
    /// @notice Target TRE (Tasso di Rigenerazione Etica) - 0.30% annual
    uint256 public treSustainabilityTarget;
    
    /// @notice Planetary Violence threshold - max 5.0%
    uint256 public maxPlanetaryViolence;
    
    /// @notice Integral Scarcity Factor threshold - min 75
    uint256 public minIntegralScarcityFactor;
    
    // ============ Governance Records ============
    
    struct GovernanceRecord {
        bytes32 recordHash;        // Hash of governance decision data
        uint256 timestamp;         // Block timestamp of record
        uint256 quorumAchieved;    // Actual quorum achieved (bps)
        address proposer;          // Address that proposed the decision
        bool executed;             // Whether decision was executed
        string ipfsCid;           // IPFS CID for detailed record
    }
    
    /// @notice Mapping of record ID to governance record
    mapping(bytes32 => GovernanceRecord) public governanceRecords;
    
    /// @notice Array of all record IDs for enumeration
    bytes32[] public recordIds;
    
    /// @notice Counter for total governance decisions
    uint256 public totalGovernanceDecisions;
    
    /// @notice Counter for executed decisions
    uint256 public executedGovernanceDecisions;
    
    // ============ Metrics Tracking ============
    
    struct MetricsSnapshot {
        uint256 timestamp;
        uint256 treRate;           // TRE in basis points
        uint256 planetaryViolence; // PV in basis points
        uint256 scarcityFactor;    // ISF (0-100 scale)
        uint256 quorumUsed;        // Quorum at time of snapshot
    }
    
    /// @notice Historical metrics snapshots
    MetricsSnapshot[] public metricsHistory;
    
    /// @notice Latest metrics
    MetricsSnapshot public latestMetrics;
    
    // ============ Events ============
    
    event QuorumThresholdUpdated(uint256 oldThreshold, uint256 newThreshold, address updatedBy);
    event SustainabilityTargetUpdated(string metricType, uint256 oldValue, uint256 newValue);
    event GovernanceRecordAnchored(bytes32 indexed recordId, bytes32 recordHash, uint256 quorum, string ipfsCid);
    event GovernanceRecordExecuted(bytes32 indexed recordId, uint256 timestamp);
    event MetricsSnapshotRecorded(uint256 timestamp, uint256 treRate, uint256 planetaryViolence, uint256 scarcityFactor);
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig authorized");
        _;
    }
    
    modifier validQuorum(uint256 _quorumBps) {
        require(_quorumBps >= MIN_QUORUM_BPS && _quorumBps <= MAX_QUORUM_BPS, "Invalid quorum threshold");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig) {
        require(_ggcMultisig != address(0), "Invalid GGC multisig address");
        
        ggcMultisig = _ggcMultisig;
        quorumThresholdBps = DEFAULT_QUORUM_BPS;
        
        // Initialize sustainability thresholds
        treSustainabilityTarget = 30;        // 0.30% in basis points
        maxPlanetaryViolence = 500;          // 5.0% in basis points
        minIntegralScarcityFactor = 75;      // ISF minimum of 75
        
        // Initialize latest metrics
        latestMetrics = MetricsSnapshot({
            timestamp: block.timestamp,
            treRate: 0,
            planetaryViolence: 0,
            scarcityFactor: 100,
            quorumUsed: DEFAULT_QUORUM_BPS
        });
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Update quorum threshold for governance decisions
     * @param _newQuorumBps New quorum threshold in basis points
     */
    function setQuorumThreshold(uint256 _newQuorumBps) 
        external 
        onlyGGC 
        validQuorum(_newQuorumBps) 
    {
        uint256 oldQuorum = quorumThresholdBps;
        quorumThresholdBps = _newQuorumBps;
        
        emit QuorumThresholdUpdated(oldQuorum, _newQuorumBps, msg.sender);
    }
    
    /**
     * @notice Update TRE sustainability target
     * @param _newTarget New TRE target in basis points
     */
    function setTreSustainabilityTarget(uint256 _newTarget) external onlyGGC {
        require(_newTarget > 0 && _newTarget <= 1000, "Invalid TRE target"); // Max 10%
        
        uint256 oldTarget = treSustainabilityTarget;
        treSustainabilityTarget = _newTarget;
        
        emit SustainabilityTargetUpdated("TRE", oldTarget, _newTarget);
    }
    
    /**
     * @notice Update maximum Planetary Violence threshold
     * @param _newMax New maximum PV in basis points
     */
    function setMaxPlanetaryViolence(uint256 _newMax) external onlyGGC {
        require(_newMax <= 2000, "PV threshold too high"); // Max 20%
        
        uint256 oldMax = maxPlanetaryViolence;
        maxPlanetaryViolence = _newMax;
        
        emit SustainabilityTargetUpdated("PV", oldMax, _newMax);
    }
    
    /**
     * @notice Update minimum Integral Scarcity Factor
     * @param _newMin New minimum ISF (0-100 scale)
     */
    function setMinIntegralScarcityFactor(uint256 _newMin) external onlyGGC {
        require(_newMin <= 100, "ISF must be 0-100");
        
        uint256 oldMin = minIntegralScarcityFactor;
        minIntegralScarcityFactor = _newMin;
        
        emit SustainabilityTargetUpdated("ISF", oldMin, _newMin);
    }
    
    // ============ Record Management ============
    
    /**
     * @notice Anchor a governance decision record
     * @param _recordHash Hash of the governance decision data
     * @param _quorumAchieved Actual quorum achieved in basis points
     * @param _ipfsCid IPFS CID containing detailed record
     * @return recordId Unique identifier for the record
     */
    function anchorGovernanceRecord(
        bytes32 _recordHash,
        uint256 _quorumAchieved,
        string calldata _ipfsCid
    ) external onlyGGC returns (bytes32 recordId) {
        require(_recordHash != bytes32(0), "Invalid record hash");
        require(_quorumAchieved >= quorumThresholdBps, "Quorum not met");
        require(bytes(_ipfsCid).length > 0, "IPFS CID required");
        
        // Generate unique record ID
        recordId = keccak256(abi.encodePacked(_recordHash, block.timestamp, msg.sender));
        
        // Ensure record doesn't already exist
        require(governanceRecords[recordId].timestamp == 0, "Record already exists");
        
        // Create governance record
        governanceRecords[recordId] = GovernanceRecord({
            recordHash: _recordHash,
            timestamp: block.timestamp,
            quorumAchieved: _quorumAchieved,
            proposer: msg.sender,
            executed: false,
            ipfsCid: _ipfsCid
        });
        
        recordIds.push(recordId);
        totalGovernanceDecisions++;
        
        emit GovernanceRecordAnchored(recordId, _recordHash, _quorumAchieved, _ipfsCid);
        
        return recordId;
    }
    
    /**
     * @notice Mark a governance record as executed
     * @param _recordId ID of the record to mark as executed
     */
    function executeGovernanceRecord(bytes32 _recordId) external onlyGGC {
        GovernanceRecord storage record = governanceRecords[_recordId];
        require(record.timestamp != 0, "Record does not exist");
        require(!record.executed, "Record already executed");
        
        record.executed = true;
        executedGovernanceDecisions++;
        
        emit GovernanceRecordExecuted(_recordId, block.timestamp);
    }
    
    // ============ Metrics Recording ============
    
    /**
     * @notice Record a metrics snapshot
     * @param _treRate Current TRE rate in basis points
     * @param _planetaryViolence Current PV in basis points
     * @param _scarcityFactor Current ISF (0-100 scale)
     */
    function recordMetricsSnapshot(
        uint256 _treRate,
        uint256 _planetaryViolence,
        uint256 _scarcityFactor
    ) external onlyGGC {
        require(_scarcityFactor <= 100, "ISF must be 0-100");
        
        MetricsSnapshot memory snapshot = MetricsSnapshot({
            timestamp: block.timestamp,
            treRate: _treRate,
            planetaryViolence: _planetaryViolence,
            scarcityFactor: _scarcityFactor,
            quorumUsed: quorumThresholdBps
        });
        
        metricsHistory.push(snapshot);
        latestMetrics = snapshot;
        
        emit MetricsSnapshotRecorded(block.timestamp, _treRate, _planetaryViolence, _scarcityFactor);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Check if current metrics meet sustainability thresholds
     * @return isSustainable True if all thresholds are met
     * @return failedMetrics Array of failed metric names
     */
    function checkSustainabilityCompliance() 
        external 
        view 
        returns (bool isSustainable, string[] memory failedMetrics) 
    {
        string[] memory failures = new string[](3);
        uint256 failureCount = 0;
        
        if (latestMetrics.treRate < treSustainabilityTarget) {
            failures[failureCount] = "TRE below target";
            failureCount++;
        }
        
        if (latestMetrics.planetaryViolence > maxPlanetaryViolence) {
            failures[failureCount] = "PV above maximum";
            failureCount++;
        }
        
        if (latestMetrics.scarcityFactor < minIntegralScarcityFactor) {
            failures[failureCount] = "ISF below minimum";
            failureCount++;
        }
        
        isSustainable = (failureCount == 0);
        
        // Resize array to actual failure count
        string[] memory result = new string[](failureCount);
        for (uint256 i = 0; i < failureCount; i++) {
            result[i] = failures[i];
        }
        
        return (isSustainable, result);
    }
    
    /**
     * @notice Get governance record by ID
     * @param _recordId ID of the record
     * @return record The governance record
     */
    function getGovernanceRecord(bytes32 _recordId) 
        external 
        view 
        returns (GovernanceRecord memory record) 
    {
        return governanceRecords[_recordId];
    }
    
    /**
     * @notice Get total number of records
     * @return count Total record count
     */
    function getRecordCount() external view returns (uint256 count) {
        return recordIds.length;
    }
    
    /**
     * @notice Get metrics history length
     * @return length Length of metrics history
     */
    function getMetricsHistoryLength() external view returns (uint256 length) {
        return metricsHistory.length;
    }
    
    /**
     * @notice Get current governance configuration
     * @return Configuration tuple
     */
    function getGovernanceConfig() 
        external 
        view 
        returns (
            address multisig,
            uint256 quorum,
            uint256 treTarget,
            uint256 pvMax,
            uint256 isfMin
        ) 
    {
        return (
            ggcMultisig,
            quorumThresholdBps,
            treSustainabilityTarget,
            maxPlanetaryViolence,
            minIntegralScarcityFactor
        );
    }
    
    /**
     * @notice Calculate governance effectiveness (executed vs total)
     * @return effectiveness Percentage of executed decisions (basis points)
     */
    function getGovernanceEffectiveness() external view returns (uint256 effectiveness) {
        if (totalGovernanceDecisions == 0) return 0;
        return (executedGovernanceDecisions * 10000) / totalGovernanceDecisions;
    }
}
