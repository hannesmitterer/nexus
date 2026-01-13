// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVBS_VacuumAnchor - Immutable Backup Storage Registry
 * @notice Manages vacuum anchors for IPFS-based distributed backup storage
 * @dev Part of Internodal Vacuum Backup System (IVBS) - Phase II Enhancement
 */
contract IVBS_VacuumAnchor {
    // ============ State Variables ============
    
    enum AnchorType {
        STATE,          // System state snapshots
        GOVERNANCE,     // Decision records
        MODEL,          // AI model versions
        SEP_BUNDLE,     // Sentinel Evidence Package bundles
        AUDIT_REPORT,   // Audit and review reports
        OTHER           // Other critical data
    }
    
    enum AnchorStatus {
        ACTIVE,
        VERIFIED,
        DEGRADED,
        CRITICAL
    }
    
    struct VacuumAnchor {
        uint256 anchorId;
        bytes32 ipfsCID;            // IPFS Content Identifier
        AnchorType anchorType;
        address creator;
        uint256 creationTimestamp;
        uint256 tripleSignRequestId; // Reference to Triple-Sign validation
        
        // Redundancy tracking
        uint8 redundancyLevel;       // Number of pinning services
        uint256 lastVerification;
        AnchorStatus status;
        
        // Metadata
        string description;
        bytes32 contentHash;         // SHA-256 hash for verification
        uint256 sizeBytes;
        
        // Recovery
        bool isRecoveryPoint;
        uint256 blockNumber;
    }
    
    // Anchor storage
    uint256 public anchorCount;
    mapping(uint256 => VacuumAnchor) public anchors;
    mapping(bytes32 => uint256) public cidToAnchorId;
    mapping(AnchorType => uint256[]) public anchorsByType;
    
    // Recovery points
    uint256[] public recoveryPointIds;
    mapping(uint256 => bool) public isRecoveryPoint;
    
    // Authorities
    address public tripleSignContract;
    address public ggcMultisig;
    
    // Configuration
    uint256 public constant MIN_REDUNDANCY = 3;
    uint256 public constant CRITICAL_REDUNDANCY = 2;
    uint256 public constant VERIFICATION_INTERVAL = 24 hours;
    uint256 public constant RECOVERY_POINT_INTERVAL = 1000; // blocks
    
    // Statistics
    mapping(AnchorType => uint256) public anchorCountByType;
    uint256 public totalStorageBytes;
    
    // ============ Events ============
    
    event VacuumAnchorCreated(
        uint256 indexed anchorId,
        bytes32 indexed ipfsCID,
        AnchorType anchorType,
        address indexed creator,
        uint256 tripleSignRequestId
    );
    
    event AnchorVerified(
        uint256 indexed anchorId,
        uint8 redundancyLevel,
        AnchorStatus status
    );
    
    event AnchorStatusChanged(
        uint256 indexed anchorId,
        AnchorStatus oldStatus,
        AnchorStatus newStatus
    );
    
    event RecoveryPointCreated(
        uint256 indexed anchorId,
        uint256 blockNumber
    );
    
    event EmergencyRecoveryInitiated(
        uint256 indexed anchorId,
        address initiator
    );
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig can execute");
        _;
    }
    
    modifier validAnchor(uint256 anchorId) {
        require(anchorId < anchorCount, "Invalid anchor ID");
        _;
    }
    
    modifier tripleSignApproved(uint256 tripleSignRequestId) {
        require(
            _verifyTripleSignApproval(tripleSignRequestId),
            "Triple-Sign approval required"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _tripleSignContract, address _ggcMultisig) {
        require(_tripleSignContract != address(0), "Invalid Triple-Sign contract");
        require(_ggcMultisig != address(0), "Invalid GGC address");
        
        tripleSignContract = _tripleSignContract;
        ggcMultisig = _ggcMultisig;
    }
    
    // ============ Anchor Creation ============
    
    /**
     * @notice Create a new vacuum anchor
     * @param ipfsCID IPFS Content Identifier
     * @param anchorType Type of anchor
     * @param tripleSignRequestId Reference to Triple-Sign validation
     * @param description Human-readable description
     * @param contentHash SHA-256 hash of content
     * @param sizeBytes Size of content in bytes
     * @return anchorId The ID of the created anchor
     */
    function createVacuumAnchor(
        bytes32 ipfsCID,
        AnchorType anchorType,
        uint256 tripleSignRequestId,
        string calldata description,
        bytes32 contentHash,
        uint256 sizeBytes
    ) external tripleSignApproved(tripleSignRequestId) returns (uint256) {
        require(ipfsCID != bytes32(0), "Invalid IPFS CID");
        require(contentHash != bytes32(0), "Invalid content hash");
        require(
            cidToAnchorId[ipfsCID] == 0,
            "Anchor already exists for this CID"
        );
        
        uint256 anchorId = anchorCount++;
        
        VacuumAnchor storage anchor = anchors[anchorId];
        anchor.anchorId = anchorId;
        anchor.ipfsCID = ipfsCID;
        anchor.anchorType = anchorType;
        anchor.creator = msg.sender;
        anchor.creationTimestamp = block.timestamp;
        anchor.tripleSignRequestId = tripleSignRequestId;
        anchor.redundancyLevel = MIN_REDUNDANCY;
        anchor.lastVerification = block.timestamp;
        anchor.status = AnchorStatus.ACTIVE;
        anchor.description = description;
        anchor.contentHash = contentHash;
        anchor.sizeBytes = sizeBytes;
        anchor.blockNumber = block.number;
        
        cidToAnchorId[ipfsCID] = anchorId;
        anchorsByType[anchorType].push(anchorId);
        anchorCountByType[anchorType]++;
        totalStorageBytes += sizeBytes;
        
        // Check if this should be a recovery point
        if (block.number % RECOVERY_POINT_INTERVAL == 0 || anchorType == AnchorType.STATE) {
            anchor.isRecoveryPoint = true;
            recoveryPointIds.push(anchorId);
            isRecoveryPoint[anchorId] = true;
            emit RecoveryPointCreated(anchorId, block.number);
        }
        
        emit VacuumAnchorCreated(
            anchorId,
            ipfsCID,
            anchorType,
            msg.sender,
            tripleSignRequestId
        );
        
        return anchorId;
    }
    
    // ============ Verification Functions ============
    
    /**
     * @notice Update anchor verification status
     * @param anchorId ID of the anchor
     * @param redundancyLevel Current redundancy level
     * @param verified Whether verification passed
     */
    function updateAnchorVerification(
        uint256 anchorId,
        uint8 redundancyLevel,
        bool verified
    ) external validAnchor(anchorId) {
        VacuumAnchor storage anchor = anchors[anchorId];
        
        // Only authorized verifiers or GGC can update
        require(
            msg.sender == ggcMultisig || msg.sender == anchor.creator,
            "Not authorized to verify"
        );
        
        anchor.lastVerification = block.timestamp;
        anchor.redundancyLevel = redundancyLevel;
        
        AnchorStatus oldStatus = anchor.status;
        
        if (!verified) {
            anchor.status = AnchorStatus.CRITICAL;
        } else if (redundancyLevel < CRITICAL_REDUNDANCY) {
            anchor.status = AnchorStatus.CRITICAL;
        } else if (redundancyLevel < MIN_REDUNDANCY) {
            anchor.status = AnchorStatus.DEGRADED;
        } else {
            anchor.status = AnchorStatus.VERIFIED;
        }
        
        emit AnchorVerified(anchorId, redundancyLevel, anchor.status);
        
        if (oldStatus != anchor.status) {
            emit AnchorStatusChanged(anchorId, oldStatus, anchor.status);
        }
    }
    
    /**
     * @notice Verify anchor content hash matches IPFS CID
     * @param anchorId ID of the anchor
     * @param actualContentHash Hash computed from IPFS content
     * @return bool True if hashes match
     */
    function verifyAnchorIntegrity(
        uint256 anchorId,
        bytes32 actualContentHash
    ) external view validAnchor(anchorId) returns (bool) {
        return anchors[anchorId].contentHash == actualContentHash;
    }
    
    // ============ Query Functions ============
    
    /**
     * @notice Get anchor details
     * @param anchorId ID of the anchor
     */
    function getAnchor(uint256 anchorId)
        external
        view
        validAnchor(anchorId)
        returns (
            bytes32 ipfsCID,
            AnchorType anchorType,
            address creator,
            uint256 creationTimestamp,
            uint8 redundancyLevel,
            AnchorStatus status,
            string memory description
        )
    {
        VacuumAnchor storage anchor = anchors[anchorId];
        return (
            anchor.ipfsCID,
            anchor.anchorType,
            anchor.creator,
            anchor.creationTimestamp,
            anchor.redundancyLevel,
            anchor.status,
            anchor.description
        );
    }
    
    /**
     * @notice Get anchor by IPFS CID
     * @param ipfsCID IPFS Content Identifier
     */
    function getAnchorByCID(bytes32 ipfsCID)
        external
        view
        returns (uint256 anchorId)
    {
        anchorId = cidToAnchorId[ipfsCID];
        require(anchorId != 0 || ipfsCID == anchors[0].ipfsCID, "No anchor for this CID");
        return anchorId;
    }
    
    /**
     * @notice Get all anchors of a specific type
     * @param anchorType Type of anchors to retrieve
     */
    function getAnchorsByType(AnchorType anchorType)
        external
        view
        returns (uint256[] memory)
    {
        return anchorsByType[anchorType];
    }
    
    /**
     * @notice Get all recovery points
     */
    function getRecoveryPoints() external view returns (uint256[] memory) {
        return recoveryPointIds;
    }
    
    /**
     * @notice Get latest recovery point
     */
    function getLatestRecoveryPoint() external view returns (uint256) {
        require(recoveryPointIds.length > 0, "No recovery points available");
        return recoveryPointIds[recoveryPointIds.length - 1];
    }
    
    /**
     * @notice Get anchors needing verification
     * @return Array of anchor IDs needing verification
     */
    function getAnchorsNeedingVerification()
        external
        view
        returns (uint256[] memory)
    {
        uint256 needsVerification = 0;
        
        // First pass: count
        for (uint256 i = 0; i < anchorCount; i++) {
            if (block.timestamp - anchors[i].lastVerification > VERIFICATION_INTERVAL) {
                needsVerification++;
            }
        }
        
        // Second pass: populate array
        uint256[] memory result = new uint256[](needsVerification);
        uint256 index = 0;
        for (uint256 i = 0; i < anchorCount; i++) {
            if (block.timestamp - anchors[i].lastVerification > VERIFICATION_INTERVAL) {
                result[index++] = i;
            }
        }
        
        return result;
    }
    
    /**
     * @notice Get system statistics
     */
    function getSystemStats()
        external
        view
        returns (
            uint256 totalAnchors,
            uint256 totalStorage,
            uint256 stateAnchors,
            uint256 governanceAnchors,
            uint256 modelAnchors,
            uint256 totalRecoveryPoints
        )
    {
        return (
            anchorCount,
            totalStorageBytes,
            anchorCountByType[AnchorType.STATE],
            anchorCountByType[AnchorType.GOVERNANCE],
            anchorCountByType[AnchorType.MODEL],
            recoveryPointIds.length
        );
    }
    
    // ============ Recovery Functions ============
    
    /**
     * @notice Initiate emergency recovery from anchor
     * @param anchorId ID of the anchor to recover from
     */
    function initiateEmergencyRecovery(uint256 anchorId)
        external
        onlyGGC
        validAnchor(anchorId)
    {
        VacuumAnchor storage anchor = anchors[anchorId];
        require(anchor.status != AnchorStatus.CRITICAL, "Anchor is critical, cannot use for recovery");
        
        emit EmergencyRecoveryInitiated(anchorId, msg.sender);
    }
    
    /**
     * @notice Manually create recovery point
     * @param anchorId ID of the anchor to mark as recovery point
     */
    function createManualRecoveryPoint(uint256 anchorId)
        external
        onlyGGC
        validAnchor(anchorId)
    {
        VacuumAnchor storage anchor = anchors[anchorId];
        require(!anchor.isRecoveryPoint, "Already a recovery point");
        
        anchor.isRecoveryPoint = true;
        recoveryPointIds.push(anchorId);
        isRecoveryPoint[anchorId] = true;
        
        emit RecoveryPointCreated(anchorId, block.number);
    }
    
    // ============ Helper Functions ============
    
    /**
     * @notice Verify Triple-Sign approval
     * @param tripleSignRequestId Request ID to verify
     * @return bool True if approved
     */
    function _verifyTripleSignApproval(uint256 tripleSignRequestId)
        internal
        view
        returns (bool)
    {
        (bool success, bytes memory data) = tripleSignContract.staticcall(
            abi.encodeWithSignature(
                "verifyTripleSignApproval(uint256)",
                tripleSignRequestId
            )
        );
        
        if (success && data.length > 0) {
            return abi.decode(data, (bool));
        }
        return false;
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Update Triple-Sign contract address
     * @param newContract New contract address
     */
    function updateTripleSignContract(address newContract) external onlyGGC {
        require(newContract != address(0), "Invalid contract address");
        tripleSignContract = newContract;
    }
    
    /**
     * @notice Update GGC multisig address
     * @param newGGC New GGC address
     */
    function updateGGCMultisig(address newGGC) external onlyGGC {
        require(newGGC != address(0), "Invalid GGC address");
        ggcMultisig = newGGC;
    }
}
