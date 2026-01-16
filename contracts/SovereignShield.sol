// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SovereignShield - Quantum-Safe Security Layer
 * @notice Implements quantum-resistant validation using NTRU-inspired algorithms
 * @dev Modular security layer for Nexus WIP with scalable input validation
 */

/**
 * @dev Interface for quantum-safe signature verification
 * Inspired by NTRU lattice-based cryptography principles
 */
interface IQuantumSafeVerifier {
    function verifyNTRUSignature(
        bytes32 messageHash,
        bytes calldata signature,
        bytes calldata publicKey
    ) external view returns (bool);
}

/**
 * @dev Interface for contracts that can be protected by SovereignShield
 */
interface IShieldedContract {
    function validateOperation(bytes32 operationId) external view returns (bool);
}

contract SovereignShield {
    // ============ State Variables ============
    
    struct ValidationFilter {
        uint256 maxInputSize;        // Maximum input size in bytes
        uint256 minInputSize;        // Minimum input size in bytes
        uint256 rateLimit;           // Max operations per time window
        uint256 timeWindow;          // Time window for rate limiting (seconds)
        bool requireQuantumSafe;     // Require NTRU verification
        bool isActive;               // Filter activation status
    }
    
    struct OperationRecord {
        bytes32 operationHash;
        address initiator;
        uint256 timestamp;
        bool validated;
        bool quantumSafeVerified;
        bytes32 inputHash;
        uint256 inputSize;
    }
    
    struct RateLimitTracker {
        uint256 operationCount;
        uint256 windowStart;
    }
    
    // Security state
    mapping(bytes32 => ValidationFilter) public filters;
    mapping(bytes32 => OperationRecord) public operations;
    mapping(address => RateLimitTracker) public rateLimits;
    
    // Quantum-safe verification
    address public quantumVerifier;
    mapping(bytes32 => bytes) public registeredPublicKeys; // Hash -> Public Key
    
    // Protected contracts registry
    mapping(address => bool) public protectedContracts;
    mapping(address => bytes32) public contractFilterId;
    
    // Governance
    address public admin;
    address public ggcMultisig;
    
    // Rollback mechanism for WIP deployments
    struct Checkpoint {
        bytes32 stateRoot;
        uint256 timestamp;
        string description;
        bool canRollback;
    }
    
    mapping(uint256 => Checkpoint) public checkpoints;
    uint256 public currentCheckpoint;
    uint256 public checkpointCount;
    
    // Statistics
    uint256 public totalOperations;
    uint256 public validatedOperations;
    uint256 public rejectedOperations;
    uint256 public quantumVerifiedOperations;
    
    // ============ Events ============
    
    event FilterConfigured(
        bytes32 indexed filterId,
        uint256 maxInputSize,
        uint256 rateLimit,
        bool requireQuantumSafe
    );
    
    event OperationValidated(
        bytes32 indexed operationHash,
        address indexed initiator,
        bool quantumSafeVerified,
        uint256 timestamp
    );
    
    event OperationRejected(
        bytes32 indexed operationHash,
        address indexed initiator,
        string reason,
        uint256 timestamp
    );
    
    event ContractProtected(
        address indexed contractAddress,
        bytes32 indexed filterId,
        bool protected
    );
    
    event QuantumVerifierUpdated(
        address indexed oldVerifier,
        address indexed newVerifier
    );
    
    event PublicKeyRegistered(
        bytes32 indexed keyHash,
        address indexed owner,
        uint256 timestamp
    );
    
    event CheckpointCreated(
        uint256 indexed checkpointId,
        bytes32 stateRoot,
        string description,
        uint256 timestamp
    );
    
    event RollbackExecuted(
        uint256 indexed fromCheckpoint,
        uint256 indexed toCheckpoint,
        uint256 timestamp
    );
    
    event RateLimitExceeded(
        address indexed initiator,
        uint256 currentCount,
        uint256 limit
    );
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == ggcMultisig, "Only admin");
        _;
    }
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig");
        _;
    }
    
    modifier validFilter(bytes32 filterId) {
        require(filters[filterId].isActive, "Filter not active");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig, address _quantumVerifier) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        
        admin = msg.sender;
        ggcMultisig = _ggcMultisig;
        quantumVerifier = _quantumVerifier;
        
        // Create initial checkpoint
        _createCheckpoint("Initial deployment", true);
        
        // Configure default filter
        _configureDefaultFilter();
    }
    
    // ============ Core Validation Functions ============
    
    /**
     * @notice Validate an operation with quantum-safe checks
     * @param operationId Unique identifier for the operation
     * @param inputData The input data to validate
     * @param signature Optional NTRU signature for quantum-safe verification
     * @param publicKey Optional public key for signature verification
     * @return validated True if validation passed
     */
    function validateOperation(
        bytes32 operationId,
        bytes calldata inputData,
        bytes calldata signature,
        bytes calldata publicKey
    ) external returns (bool validated) {
        require(operationId != bytes32(0), "Invalid operation ID");
        require(operations[operationId].timestamp == 0, "Operation already processed");
        
        totalOperations++;
        
        // Get filter for calling contract
        bytes32 filterId = contractFilterId[msg.sender];
        if (filterId == bytes32(0)) {
            filterId = keccak256("DEFAULT_FILTER");
        }
        
        ValidationFilter storage filter = filters[filterId];
        require(filter.isActive, "No active filter");
        
        // Rate limiting check
        if (!_checkRateLimit(tx.origin, filter)) {
            rejectedOperations++;
            emit OperationRejected(
                operationId,
                tx.origin,
                "Rate limit exceeded",
                block.timestamp
            );
            return false;
        }
        
        // Input size validation
        if (inputData.length > filter.maxInputSize || inputData.length < filter.minInputSize) {
            rejectedOperations++;
            emit OperationRejected(
                operationId,
                tx.origin,
                "Input size out of range",
                block.timestamp
            );
            return false;
        }
        
        // Quantum-safe verification if required
        bool quantumVerified = false;
        if (filter.requireQuantumSafe) {
            if (quantumVerifier == address(0) || signature.length == 0 || publicKey.length == 0) {
                rejectedOperations++;
                emit OperationRejected(
                    operationId,
                    tx.origin,
                    "Quantum-safe verification required",
                    block.timestamp
                );
                return false;
            }
            
            bytes32 messageHash = keccak256(inputData);
            quantumVerified = IQuantumSafeVerifier(quantumVerifier).verifyNTRUSignature(
                messageHash,
                signature,
                publicKey
            );
            
            if (!quantumVerified) {
                rejectedOperations++;
                emit OperationRejected(
                    operationId,
                    tx.origin,
                    "Quantum signature verification failed",
                    block.timestamp
                );
                return false;
            }
            
            quantumVerifiedOperations++;
        }
        
        // Record the operation
        operations[operationId] = OperationRecord({
            operationHash: operationId,
            initiator: tx.origin,
            timestamp: block.timestamp,
            validated: true,
            quantumSafeVerified: quantumVerified,
            inputHash: keccak256(inputData),
            inputSize: inputData.length
        });
        
        validatedOperations++;
        
        emit OperationValidated(
            operationId,
            tx.origin,
            quantumVerified,
            block.timestamp
        );
        
        return true;
    }
    
    /**
     * @notice Lightweight validation for operations that don't require quantum-safe
     * @param operationId Unique identifier for the operation
     * @param inputSize Size of the input data
     * @return validated True if validation passed
     */
    function validateOperationLight(
        bytes32 operationId,
        uint256 inputSize
    ) external returns (bool validated) {
        require(operationId != bytes32(0), "Invalid operation ID");
        require(operations[operationId].timestamp == 0, "Operation already processed");
        
        totalOperations++;
        
        bytes32 filterId = contractFilterId[msg.sender];
        if (filterId == bytes32(0)) {
            filterId = keccak256("DEFAULT_FILTER");
        }
        
        ValidationFilter storage filter = filters[filterId];
        require(filter.isActive, "No active filter");
        require(!filter.requireQuantumSafe, "Quantum-safe required");
        
        // Rate limiting check
        if (!_checkRateLimit(tx.origin, filter)) {
            rejectedOperations++;
            return false;
        }
        
        // Input size validation
        if (inputSize > filter.maxInputSize || inputSize < filter.minInputSize) {
            rejectedOperations++;
            return false;
        }
        
        // Record the operation
        operations[operationId] = OperationRecord({
            operationHash: operationId,
            initiator: tx.origin,
            timestamp: block.timestamp,
            validated: true,
            quantumSafeVerified: false,
            inputHash: bytes32(0),
            inputSize: inputSize
        });
        
        validatedOperations++;
        
        return true;
    }
    
    /**
     * @notice Check if an operation was validated
     * @param operationId The operation to check
     * @return validated True if operation was validated
     */
    function isOperationValidated(bytes32 operationId) external view returns (bool) {
        return operations[operationId].validated;
    }
    
    /**
     * @notice Get operation details
     * @param operationId The operation to query
     * @return Operation details
     */
    function getOperation(bytes32 operationId)
        external
        view
        returns (
            address initiator,
            uint256 timestamp,
            bool validated,
            bool quantumSafeVerified,
            uint256 inputSize
        )
    {
        OperationRecord storage op = operations[operationId];
        return (
            op.initiator,
            op.timestamp,
            op.validated,
            op.quantumSafeVerified,
            op.inputSize
        );
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Check rate limit for an address
     */
    function _checkRateLimit(address user, ValidationFilter storage filter) 
        internal 
        returns (bool) 
    {
        if (filter.rateLimit == 0) {
            return true; // No rate limit
        }
        
        RateLimitTracker storage tracker = rateLimits[user];
        
        // Reset window if expired
        if (block.timestamp >= tracker.windowStart + filter.timeWindow) {
            tracker.windowStart = block.timestamp;
            tracker.operationCount = 0;
        }
        
        // Check limit
        if (tracker.operationCount >= filter.rateLimit) {
            emit RateLimitExceeded(user, tracker.operationCount, filter.rateLimit);
            return false;
        }
        
        tracker.operationCount++;
        return true;
    }
    
    /**
     * @dev Configure default filter
     */
    function _configureDefaultFilter() internal {
        bytes32 defaultFilterId = keccak256("DEFAULT_FILTER");
        filters[defaultFilterId] = ValidationFilter({
            maxInputSize: 1024 * 1024, // 1MB
            minInputSize: 1,
            rateLimit: 100,
            timeWindow: 1 hours,
            requireQuantumSafe: false,
            isActive: true
        });
    }
    
    /**
     * @dev Create a checkpoint for rollback capability
     */
    function _createCheckpoint(string memory description, bool canRollback) internal {
        bytes32 stateRoot = keccak256(
            abi.encodePacked(
                totalOperations,
                validatedOperations,
                rejectedOperations,
                block.timestamp
            )
        );
        
        checkpoints[checkpointCount] = Checkpoint({
            stateRoot: stateRoot,
            timestamp: block.timestamp,
            description: description,
            canRollback: canRollback
        });
        
        emit CheckpointCreated(checkpointCount, stateRoot, description, block.timestamp);
        
        currentCheckpoint = checkpointCount;
        checkpointCount++;
    }
    
    // ============ Configuration Functions ============
    
    /**
     * @notice Configure a validation filter
     * @param filterId Unique identifier for the filter
     * @param maxInputSize Maximum input size in bytes
     * @param minInputSize Minimum input size in bytes
     * @param rateLimit Maximum operations per time window (0 for unlimited)
     * @param timeWindow Time window for rate limiting in seconds
     * @param requireQuantumSafe Whether to require NTRU verification
     */
    function configureFilter(
        bytes32 filterId,
        uint256 maxInputSize,
        uint256 minInputSize,
        uint256 rateLimit,
        uint256 timeWindow,
        bool requireQuantumSafe
    ) external onlyAdmin {
        require(filterId != bytes32(0), "Invalid filter ID");
        require(maxInputSize >= minInputSize, "Invalid size range");
        require(maxInputSize <= 10 * 1024 * 1024, "Max size too large"); // 10MB limit
        
        if (rateLimit > 0) {
            require(timeWindow >= 1 minutes && timeWindow <= 24 hours, "Invalid time window");
        }
        
        filters[filterId] = ValidationFilter({
            maxInputSize: maxInputSize,
            minInputSize: minInputSize,
            rateLimit: rateLimit,
            timeWindow: timeWindow,
            requireQuantumSafe: requireQuantumSafe,
            isActive: true
        });
        
        emit FilterConfigured(
            filterId,
            maxInputSize,
            rateLimit,
            requireQuantumSafe
        );
    }
    
    /**
     * @notice Protect a contract with a specific filter
     * @param contractAddress The contract to protect
     * @param filterId The filter to apply
     */
    function protectContract(
        address contractAddress,
        bytes32 filterId
    ) external onlyAdmin validFilter(filterId) {
        require(contractAddress != address(0), "Invalid contract address");
        
        protectedContracts[contractAddress] = true;
        contractFilterId[contractAddress] = filterId;
        
        emit ContractProtected(contractAddress, filterId, true);
    }
    
    /**
     * @notice Unprotect a contract
     * @param contractAddress The contract to unprotect
     */
    function unprotectContract(address contractAddress) external onlyAdmin {
        protectedContracts[contractAddress] = false;
        delete contractFilterId[contractAddress];
        
        emit ContractProtected(contractAddress, bytes32(0), false);
    }
    
    /**
     * @notice Register a quantum-safe public key
     * @param publicKey The NTRU public key
     */
    function registerPublicKey(bytes calldata publicKey) external {
        require(publicKey.length > 0, "Invalid public key");
        
        bytes32 keyHash = keccak256(abi.encodePacked(msg.sender, publicKey));
        registeredPublicKeys[keyHash] = publicKey;
        
        emit PublicKeyRegistered(keyHash, msg.sender, block.timestamp);
    }
    
    /**
     * @notice Update quantum verifier contract
     * @param newVerifier New verifier contract address
     */
    function updateQuantumVerifier(address newVerifier) external onlyGGC {
        address oldVerifier = quantumVerifier;
        quantumVerifier = newVerifier;
        
        emit QuantumVerifierUpdated(oldVerifier, newVerifier);
    }
    
    // ============ Rollback Functions ============
    
    /**
     * @notice Create a manual checkpoint for rollback
     * @param description Description of the checkpoint
     */
    function createCheckpoint(string calldata description) external onlyAdmin {
        _createCheckpoint(description, true);
    }
    
    /**
     * @notice Execute rollback to a previous checkpoint (for WIP deployments)
     * @param checkpointId The checkpoint to roll back to
     */
    function rollbackToCheckpoint(uint256 checkpointId) external onlyGGC {
        require(checkpointId < checkpointCount, "Invalid checkpoint");
        require(checkpointId < currentCheckpoint, "Cannot rollback to current or future");
        require(checkpoints[checkpointId].canRollback, "Checkpoint not rollbackable");
        
        uint256 fromCheckpoint = currentCheckpoint;
        currentCheckpoint = checkpointId;
        
        emit RollbackExecuted(fromCheckpoint, checkpointId, block.timestamp);
        
        // Create a new checkpoint after rollback
        _createCheckpoint("Post-rollback checkpoint", true);
    }
    
    /**
     * @notice Get checkpoint details
     * @param checkpointId The checkpoint ID
     * @return stateRoot, timestamp, description, canRollback
     */
    function getCheckpoint(uint256 checkpointId)
        external
        view
        returns (
            bytes32 stateRoot,
            uint256 timestamp,
            string memory description,
            bool canRollback
        )
    {
        require(checkpointId < checkpointCount, "Invalid checkpoint");
        Checkpoint storage cp = checkpoints[checkpointId];
        return (cp.stateRoot, cp.timestamp, cp.description, cp.canRollback);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get validation statistics
     * @return total, validated, rejected, quantumVerified, successRate
     */
    function getStatistics()
        external
        view
        returns (
            uint256 total,
            uint256 validated,
            uint256 rejected,
            uint256 quantumVerified,
            uint256 successRate
        )
    {
        total = totalOperations;
        validated = validatedOperations;
        rejected = rejectedOperations;
        quantumVerified = quantumVerifiedOperations;
        
        if (total > 0) {
            successRate = (validated * 10000) / total; // Basis points
        }
    }
    
    /**
     * @notice Get filter configuration
     * @param filterId The filter ID
     * @return Filter configuration
     */
    function getFilter(bytes32 filterId)
        external
        view
        returns (
            uint256 maxInputSize,
            uint256 minInputSize,
            uint256 rateLimit,
            uint256 timeWindow,
            bool requireQuantumSafe,
            bool isActive
        )
    {
        ValidationFilter storage filter = filters[filterId];
        return (
            filter.maxInputSize,
            filter.minInputSize,
            filter.rateLimit,
            filter.timeWindow,
            filter.requireQuantumSafe,
            filter.isActive
        );
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Update admin address
     * @param newAdmin New admin address
     */
    function updateAdmin(address newAdmin) external onlyGGC {
        require(newAdmin != address(0), "Invalid address");
        admin = newAdmin;
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
     * @notice Activate or deactivate a filter
     * @param filterId The filter to modify
     * @param active New activation status
     */
    function setFilterActive(bytes32 filterId, bool active) external onlyAdmin {
        require(filters[filterId].maxInputSize > 0, "Filter not configured");
        filters[filterId].isActive = active;
    }
}
