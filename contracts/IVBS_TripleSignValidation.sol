// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVBS_TripleSignValidation - Triple-Sign Validation Layer
 * @notice Implements three-tier validation (Technical, Governance, Ethical)
 * @dev Part of Internodal Vacuum Backup System (IVBS) - Phase II Enhancement
 */
contract IVBS_TripleSignValidation {
    // ============ State Variables ============
    
    enum ValidationTier {
        TECHNICAL,    // Automated cryptographic and integrity checks
        GOVERNANCE,   // EFA/GGC multi-signature approval
        ETHICAL       // Red Code Authority review and approval
    }
    
    enum ValidationStatus {
        PENDING,
        APPROVED,
        REJECTED
    }
    
    struct TripleSignRequest {
        bytes32 dataHash;           // Hash of data requiring validation
        string actionType;          // Type of action (e.g., "MODEL_UPDATE", "GOVERNANCE_CHANGE")
        address requester;          // Who initiated the request
        uint256 timestamp;          // When request was created
        
        // Validation states
        ValidationStatus technicalStatus;
        ValidationStatus governanceStatus;
        ValidationStatus ethicalStatus;
        
        // Signatures
        bytes technicalSignature;
        bytes[] governanceSignatures;
        bytes[] ethicalSignatures;
        
        // Metadata
        string technicalReason;
        string governanceReason;
        string ethicalReason;
        
        bool isExecuted;
        uint256 executionTimestamp;
    }
    
    // Request storage
    uint256 public requestCount;
    mapping(uint256 => TripleSignRequest) public requests;
    mapping(bytes32 => uint256) public dataHashToRequestId;
    
    // Authorities
    address public technicalValidator;  // Automated system address
    address public ggcMultisig;         // Governance multisig
    address public redCodeVetoContract; // Red Code Veto contract
    
    // Configuration
    uint256 public constant MIN_GOVERNANCE_SIGNATURES = 7;
    uint256 public constant MIN_ETHICAL_SIGNATURES = 3;
    uint256 public constant REVIEW_PERIOD = 48 hours;
    
    // ============ Events ============
    
    event TripleSignRequestCreated(
        uint256 indexed requestId,
        bytes32 indexed dataHash,
        string actionType,
        address requester
    );
    
    event TechnicalValidationCompleted(
        uint256 indexed requestId,
        ValidationStatus status,
        string reason
    );
    
    event GovernanceValidationCompleted(
        uint256 indexed requestId,
        ValidationStatus status,
        uint256 signatureCount
    );
    
    event EthicalValidationCompleted(
        uint256 indexed requestId,
        ValidationStatus status,
        uint256 signatureCount
    );
    
    event TripleSignApproved(
        uint256 indexed requestId,
        bytes32 indexed dataHash,
        uint256 timestamp
    );
    
    event TripleSignRejected(
        uint256 indexed requestId,
        ValidationTier rejectedTier,
        string reason
    );
    
    event RequestExecuted(
        uint256 indexed requestId,
        bytes32 indexed dataHash,
        uint256 executionTimestamp
    );
    
    // ============ Modifiers ============
    
    modifier onlyTechnicalValidator() {
        require(
            msg.sender == technicalValidator,
            "Only technical validator can execute"
        );
        _;
    }
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig can execute");
        _;
    }
    
    modifier validRequest(uint256 requestId) {
        require(requestId < requestCount, "Invalid request ID");
        require(!requests[requestId].isExecuted, "Request already executed");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _technicalValidator,
        address _ggcMultisig,
        address _redCodeVetoContract
    ) {
        require(_technicalValidator != address(0), "Invalid technical validator");
        require(_ggcMultisig != address(0), "Invalid GGC address");
        require(_redCodeVetoContract != address(0), "Invalid Red Code contract");
        
        technicalValidator = _technicalValidator;
        ggcMultisig = _ggcMultisig;
        redCodeVetoContract = _redCodeVetoContract;
    }
    
    // ============ Request Creation ============
    
    /**
     * @notice Create a new Triple-Sign validation request
     * @param dataHash Hash of the data requiring validation
     * @param actionType Type of action being validated
     * @return requestId The ID of the created request
     */
    function createTripleSignRequest(
        bytes32 dataHash,
        string calldata actionType
    ) external returns (uint256) {
        require(dataHash != bytes32(0), "Invalid data hash");
        require(
            dataHashToRequestId[dataHash] == 0,
            "Request already exists for this data"
        );
        
        uint256 requestId = requestCount++;
        
        TripleSignRequest storage request = requests[requestId];
        request.dataHash = dataHash;
        request.actionType = actionType;
        request.requester = msg.sender;
        request.timestamp = block.timestamp;
        request.technicalStatus = ValidationStatus.PENDING;
        request.governanceStatus = ValidationStatus.PENDING;
        request.ethicalStatus = ValidationStatus.PENDING;
        
        dataHashToRequestId[dataHash] = requestId;
        
        emit TripleSignRequestCreated(requestId, dataHash, actionType, msg.sender);
        
        return requestId;
    }
    
    // ============ Technical Validation ============
    
    /**
     * @notice Submit technical validation result
     * @param requestId ID of the request
     * @param approved Whether technical validation passed
     * @param reason Reason for approval/rejection
     * @param signature Technical validator signature
     */
    function submitTechnicalValidation(
        uint256 requestId,
        bool approved,
        string calldata reason,
        bytes calldata signature
    ) external onlyTechnicalValidator validRequest(requestId) {
        TripleSignRequest storage request = requests[requestId];
        require(
            request.technicalStatus == ValidationStatus.PENDING,
            "Technical validation already completed"
        );
        
        request.technicalStatus = approved ? 
            ValidationStatus.APPROVED : 
            ValidationStatus.REJECTED;
        request.technicalSignature = signature;
        request.technicalReason = reason;
        
        emit TechnicalValidationCompleted(requestId, request.technicalStatus, reason);
        
        if (!approved) {
            emit TripleSignRejected(requestId, ValidationTier.TECHNICAL, reason);
        }
    }
    
    // ============ Governance Validation ============
    
    /**
     * @notice Submit governance validation signatures
     * @param requestId ID of the request
     * @param approved Whether governance approves
     * @param signatures Array of governance signatures (7-of-9 multisig)
     * @param reason Reason for decision
     */
    function submitGovernanceValidation(
        uint256 requestId,
        bool approved,
        bytes[] calldata signatures,
        string calldata reason
    ) external onlyGGC validRequest(requestId) {
        TripleSignRequest storage request = requests[requestId];
        require(
            request.governanceStatus == ValidationStatus.PENDING,
            "Governance validation already completed"
        );
        require(
            request.technicalStatus == ValidationStatus.APPROVED,
            "Technical validation must pass first"
        );
        
        if (approved) {
            require(
                signatures.length >= MIN_GOVERNANCE_SIGNATURES,
                "Insufficient governance signatures"
            );
        }
        
        request.governanceStatus = approved ? 
            ValidationStatus.APPROVED : 
            ValidationStatus.REJECTED;
        request.governanceSignatures = signatures;
        request.governanceReason = reason;
        
        emit GovernanceValidationCompleted(
            requestId, 
            request.governanceStatus, 
            signatures.length
        );
        
        if (!approved) {
            emit TripleSignRejected(requestId, ValidationTier.GOVERNANCE, reason);
        }
    }
    
    // ============ Ethical Validation ============
    
    /**
     * @notice Submit ethical validation signatures (Red Code Authorities)
     * @param requestId ID of the request
     * @param approved Whether ethical review approves
     * @param signatures Array of RCA signatures (3-of-5 threshold)
     * @param reason Reason for decision
     */
    function submitEthicalValidation(
        uint256 requestId,
        bool approved,
        bytes[] calldata signatures,
        string calldata reason
    ) external validRequest(requestId) {
        TripleSignRequest storage request = requests[requestId];
        require(
            request.ethicalStatus == ValidationStatus.PENDING,
            "Ethical validation already completed"
        );
        require(
            request.governanceStatus == ValidationStatus.APPROVED,
            "Governance validation must pass first"
        );
        
        // Verify caller is authorized (RCA or GGC)
        require(
            msg.sender == ggcMultisig || _isRedCodeAuthority(msg.sender),
            "Only RCA or GGC can submit ethical validation"
        );
        
        if (approved) {
            require(
                signatures.length >= MIN_ETHICAL_SIGNATURES,
                "Insufficient ethical signatures"
            );
        }
        
        request.ethicalStatus = approved ? 
            ValidationStatus.APPROVED : 
            ValidationStatus.REJECTED;
        request.ethicalSignatures = signatures;
        request.ethicalReason = reason;
        
        emit EthicalValidationCompleted(
            requestId, 
            request.ethicalStatus, 
            signatures.length
        );
        
        if (approved) {
            emit TripleSignApproved(requestId, request.dataHash, block.timestamp);
        } else {
            emit TripleSignRejected(requestId, ValidationTier.ETHICAL, reason);
        }
    }
    
    // ============ Verification Functions ============
    
    /**
     * @notice Verify if a request has full Triple-Sign approval
     * @param requestId ID of the request
     * @return bool True if all three tiers approved
     */
    function verifyTripleSignApproval(uint256 requestId) 
        external 
        view 
        returns (bool) 
    {
        require(requestId < requestCount, "Invalid request ID");
        
        TripleSignRequest storage request = requests[requestId];
        
        return request.technicalStatus == ValidationStatus.APPROVED &&
               request.governanceStatus == ValidationStatus.APPROVED &&
               request.ethicalStatus == ValidationStatus.APPROVED;
    }
    
    /**
     * @notice Verify Triple-Sign approval by data hash
     * @param dataHash Hash of the data
     * @return bool True if approved
     */
    function verifyTripleSignByHash(bytes32 dataHash) 
        external 
        view 
        returns (bool) 
    {
        uint256 requestId = dataHashToRequestId[dataHash];
        require(requestId != 0 || dataHash == requests[0].dataHash, "No request for this hash");
        
        TripleSignRequest storage request = requests[requestId];
        
        return request.technicalStatus == ValidationStatus.APPROVED &&
               request.governanceStatus == ValidationStatus.APPROVED &&
               request.ethicalStatus == ValidationStatus.APPROVED;
    }
    
    /**
     * @notice Get full request details
     * @param requestId ID of the request
     * @return Request details (excluding signatures for gas efficiency)
     */
    function getRequestDetails(uint256 requestId)
        external
        view
        returns (
            bytes32 dataHash,
            string memory actionType,
            address requester,
            uint256 timestamp,
            ValidationStatus technicalStatus,
            ValidationStatus governanceStatus,
            ValidationStatus ethicalStatus,
            bool isExecuted
        )
    {
        require(requestId < requestCount, "Invalid request ID");
        TripleSignRequest storage request = requests[requestId];
        
        return (
            request.dataHash,
            request.actionType,
            request.requester,
            request.timestamp,
            request.technicalStatus,
            request.governanceStatus,
            request.ethicalStatus,
            request.isExecuted
        );
    }
    
    /**
     * @notice Get validation reasons for a request
     * @param requestId ID of the request
     */
    function getValidationReasons(uint256 requestId)
        external
        view
        returns (
            string memory technicalReason,
            string memory governanceReason,
            string memory ethicalReason
        )
    {
        require(requestId < requestCount, "Invalid request ID");
        TripleSignRequest storage request = requests[requestId];
        
        return (
            request.technicalReason,
            request.governanceReason,
            request.ethicalReason
        );
    }
    
    // ============ Execution Functions ============
    
    /**
     * @notice Mark a request as executed (called by external systems)
     * @param requestId ID of the request
     */
    function markAsExecuted(uint256 requestId) external validRequest(requestId) {
        TripleSignRequest storage request = requests[requestId];
        
        require(
            request.technicalStatus == ValidationStatus.APPROVED &&
            request.governanceStatus == ValidationStatus.APPROVED &&
            request.ethicalStatus == ValidationStatus.APPROVED,
            "Request not fully approved"
        );
        
        require(
            msg.sender == request.requester || 
            msg.sender == ggcMultisig ||
            msg.sender == technicalValidator,
            "Not authorized to mark as executed"
        );
        
        request.isExecuted = true;
        request.executionTimestamp = block.timestamp;
        
        emit RequestExecuted(requestId, request.dataHash, block.timestamp);
    }
    
    // ============ Helper Functions ============
    
    /**
     * @notice Check if address is a Red Code Authority
     * @param account Address to check
     * @return bool True if address is active RCA
     */
    function _isRedCodeAuthority(address account) internal view returns (bool) {
        // Call Red Code Veto contract to verify
        (bool success, bytes memory data) = redCodeVetoContract.staticcall(
            abi.encodeWithSignature("isActiveRCA(address)", account)
        );
        
        if (success && data.length > 0) {
            return abi.decode(data, (bool));
        }
        return false;
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Update technical validator address
     * @param newValidator New validator address
     */
    function updateTechnicalValidator(address newValidator) external onlyGGC {
        require(newValidator != address(0), "Invalid validator address");
        technicalValidator = newValidator;
    }
    
    /**
     * @notice Update GGC multisig address
     * @param newGGC New GGC address
     */
    function updateGGCMultisig(address newGGC) external onlyGGC {
        require(newGGC != address(0), "Invalid GGC address");
        ggcMultisig = newGGC;
    }
    
    /**
     * @notice Update Red Code Veto contract address
     * @param newContract New contract address
     */
    function updateRedCodeContract(address newContract) external onlyGGC {
        require(newContract != address(0), "Invalid contract address");
        redCodeVetoContract = newContract;
    }
}
