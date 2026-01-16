// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EIMClientWithShield - Example integration with SovereignShield
 * @notice This is an example showing how to integrate SovereignShield with EIMClient
 * @dev This is a reference implementation demonstrating the integration pattern
 * 
 * To use this in production:
 * 1. Deploy SovereignShield and NTRUVerifier
 * 2. Configure appropriate validation filters
 * 3. Update EIMClient constructor to accept SovereignShield address
 * 4. Modify submitSEP to use SovereignShield validation
 */

interface ISovereignShield {
    function validateOperation(
        bytes32 operationId,
        bytes calldata inputData,
        bytes calldata signature,
        bytes calldata publicKey
    ) external returns (bool validated);
    
    function validateOperationLight(
        bytes32 operationId,
        uint256 inputSize
    ) external returns (bool validated);
}

interface ITFKVerifier {
    function currentModelCID() external view returns (bytes32);
}

/**
 * @title EIMClientWithShield
 * @notice Enhanced EIMClient with SovereignShield quantum-safe validation
 * @dev Key changes from original EIMClient:
 *      - Added sovereignShield state variable
 *      - Added signature and publicKey parameters to submitSEP
 *      - Added SovereignShield validation before SEP processing
 *      - Added governance functions to manage SovereignShield integration
 */
contract EIMClientWithShield {
    // ============ State Variables ============
    
    struct SEPValidation {
        bytes32 sepId;
        address sanNode;
        bytes32 operationHash;
        uint256 timestamp;
        bool isValid;
        bool isFinalized;
        string artifactType;
        bytes32 inputDigest;
        bytes32 outputDigest;
        bytes32 modelDigest;
    }
    
    mapping(bytes32 => SEPValidation) public validations;
    mapping(bytes32 => bool) public processedSEPs;
    mapping(address => bool) public registeredSANs;
    
    address public ggcMultisig;
    address public tfkVerifier;
    
    // *** ADDED: SovereignShield integration ***
    ISovereignShield public sovereignShield;
    bool public quantumSafeRequired;
    
    uint256 public totalValidations;
    uint256 public validationTimeout = 5 minutes;
    
    // ============ Events ============
    
    event SEPSubmitted(
        bytes32 indexed sepId,
        address indexed sanNode,
        string artifactType,
        uint256 timestamp
    );
    
    // *** ADDED: SovereignShield events ***
    event QuantumSafeValidationPerformed(
        bytes32 indexed operationHash,
        bool verified,
        uint256 timestamp
    );
    
    event SovereignShieldUpdated(
        address indexed oldShield,
        address indexed newShield
    );
    
    // ============ Constructor ============
    
    constructor(
        address _ggcMultisig, 
        address _tfkVerifier,
        address _sovereignShield  // *** ADDED: SovereignShield address ***
    ) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        require(_tfkVerifier != address(0), "Invalid TFKVerifier address");
        
        ggcMultisig = _ggcMultisig;
        tfkVerifier = _tfkVerifier;
        
        // *** ADDED: Initialize SovereignShield ***
        if (_sovereignShield != address(0)) {
            sovereignShield = ISovereignShield(_sovereignShield);
            quantumSafeRequired = true;
        }
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Submit a SEP for validation with quantum-safe verification
     * @dev This is the key integration point with SovereignShield
     * 
     * Changes from original submitSEP:
     * - Added signature parameter for NTRU quantum-safe signature
     * - Added publicKey parameter for signature verification
     * - Added SovereignShield validation before processing
     * - Can use either full quantum-safe or lightweight validation
     */
    function submitSEP(
        bytes32 sepId,
        string calldata artifactType,
        bytes32 inputDigest,
        bytes32 outputDigest,
        bytes32 modelDigest,
        bytes calldata signature,    // *** ADDED: Quantum-safe signature ***
        bytes calldata publicKey     // *** ADDED: Public key ***
    ) external returns (bytes32 operationHash) {
        require(registeredSANs[msg.sender], "Only registered SAN");
        require(sepId != bytes32(0), "Invalid SEP ID");
        require(!processedSEPs[sepId], "SEP already processed");
        
        operationHash = keccak256(
            abi.encodePacked(sepId, msg.sender, block.timestamp)
        );
        
        // *** ADDED: SovereignShield validation ***
        if (address(sovereignShield) != address(0)) {
            // Pack SEP data for validation
            bytes memory sepData = abi.encodePacked(
                sepId,
                artifactType,
                inputDigest,
                outputDigest,
                modelDigest,
                msg.sender,
                block.timestamp
            );
            
            bool shieldValidated;
            if (quantumSafeRequired) {
                // Full quantum-safe validation with NTRU signature
                shieldValidated = sovereignShield.validateOperation(
                    operationHash,
                    sepData,
                    signature,
                    publicKey
                );
                
                emit QuantumSafeValidationPerformed(
                    operationHash,
                    shieldValidated,
                    block.timestamp
                );
            } else {
                // Lightweight validation (size and rate limiting only)
                shieldValidated = sovereignShield.validateOperationLight(
                    operationHash,
                    sepData.length
                );
            }
            
            require(shieldValidated, "SovereignShield validation failed");
        }
        
        // Continue with normal SEP processing
        validations[operationHash] = SEPValidation({
            sepId: sepId,
            sanNode: msg.sender,
            operationHash: operationHash,
            timestamp: block.timestamp,
            isValid: false,
            isFinalized: false,
            artifactType: artifactType,
            inputDigest: inputDigest,
            outputDigest: outputDigest,
            modelDigest: modelDigest
        });
        
        processedSEPs[sepId] = true;
        totalValidations++;
        
        emit SEPSubmitted(sepId, msg.sender, artifactType, block.timestamp);
        
        return operationHash;
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Update SovereignShield contract address
     * @param newShield New SovereignShield address
     */
    function updateSovereignShield(address newShield) external {
        require(msg.sender == ggcMultisig, "Only GGC");
        address oldShield = address(sovereignShield);
        sovereignShield = ISovereignShield(newShield);
        
        emit SovereignShieldUpdated(oldShield, newShield);
    }
    
    /**
     * @notice Enable or disable quantum-safe requirement
     * @param required True to require quantum-safe validation
     */
    function setQuantumSafeRequired(bool required) external {
        require(msg.sender == ggcMultisig, "Only GGC");
        quantumSafeRequired = required;
    }
    
    function registerSAN(address san) external {
        require(msg.sender == ggcMultisig, "Only GGC");
        registeredSANs[san] = true;
    }
}
