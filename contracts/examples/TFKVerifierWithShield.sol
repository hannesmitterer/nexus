// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TFKVerifierWithShield - Example integration with SovereignShield
 * @notice This example shows how to integrate SovereignShield with TFKVerifier
 * @dev Reference implementation for quantum-safe model proposal validation
 * 
 * BACKWARD COMPATIBILITY NOTE:
 * This example modifies the propose_model_retrain function signature by adding
 * modelData, signature, and publicKey parameters. This breaks compatibility with
 * existing clients.
 * 
 * For production, consider one of these approaches:
 * 1. Function overloading - Keep old propose_model_retrain and add new version
 * 2. Separate function - Create propose_model_retrain_quantum_safe
 * 3. Optional parameters - Make new parameters optional with defaults
 * 
 * Example with separate function:
 * ```
 * function propose_model_retrain_quantum_safe(
 *     bytes32 ipfsCID,
 *     string calldata description,
 *     bytes calldata modelData,
 *     bytes calldata signature,
 *     bytes calldata publicKey
 * ) external returns (uint256) {
 *     // Quantum-safe validation logic
 * }
 * ```
 */

interface ISovereignShield {
    function validateOperation(
        bytes32 operationId,
        bytes calldata inputData,
        bytes calldata signature,
        bytes calldata publicKey
    ) external returns (bool validated);
}

/**
 * @title TFKVerifierWithShield
 * @notice Enhanced TFKVerifier with SovereignShield quantum-safe validation
 * @dev Key changes from original TFKVerifier:
 *      - Added sovereignShield state variable
 *      - Added modelData, signature, and publicKey parameters to propose_model_retrain
 *      - Added SovereignShield validation before proposal creation
 */
contract TFKVerifierWithShield {
    // ============ State Variables ============
    
    struct ModelProposal {
        bytes32 ipfsCID;
        address proposer;
        uint256 timestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        string description;
    }
    
    bytes32 public currentModelCID;
    uint256 public currentModelVersion;
    uint256 public proposalCount;
    
    mapping(uint256 => ModelProposal) public proposals;
    mapping(address => bool) public authorizedEFAs;
    
    address public ggcMultisig;
    
    // *** ADDED: SovereignShield integration ***
    ISovereignShield public sovereignShield;
    bool public quantumSafeRequired;
    
    uint256 public votingPeriod = 48 hours;
    
    // ============ Events ============
    
    event ModelProposalCreated(
        uint256 indexed proposalId,
        bytes32 indexed ipfsCID,
        address indexed proposer,
        string description
    );
    
    // *** ADDED: SovereignShield events ***
    event QuantumSafeModelValidation(
        uint256 indexed proposalId,
        bytes32 indexed ipfsCID,
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
        bytes32 _initialModelCID,
        address _sovereignShield  // *** ADDED: SovereignShield address ***
    ) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        
        ggcMultisig = _ggcMultisig;
        currentModelCID = _initialModelCID;
        currentModelVersion = 0;
        
        // *** ADDED: Initialize SovereignShield ***
        if (_sovereignShield != address(0)) {
            sovereignShield = ISovereignShield(_sovereignShield);
            quantumSafeRequired = true;
        }
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Propose a new model retraining with quantum-safe verification
     * @dev This is the key integration point with SovereignShield
     * 
     * Changes from original propose_model_retrain:
     * - Added modelData parameter containing the actual model data
     * - Added signature parameter for NTRU quantum-safe signature
     * - Added publicKey parameter for signature verification
     * - Added SovereignShield validation before proposal creation
     * 
     * @param ipfsCID The IPFS content identifier for the new model
     * @param description Human-readable description of the update
     * @param modelData The model data to validate (can be hash or actual data)
     * @param signature NTRU quantum-safe signature
     * @param publicKey NTRU public key for verification
     * @return proposalId The ID of the created proposal
     */
    function propose_model_retrain(
        bytes32 ipfsCID,
        string calldata description,
        bytes calldata modelData,      // *** ADDED: Model data for validation ***
        bytes calldata signature,      // *** ADDED: Quantum-safe signature ***
        bytes calldata publicKey       // *** ADDED: Public key ***
    ) external returns (uint256) {
        require(authorizedEFAs[msg.sender], "Only authorized EFA");
        require(ipfsCID != bytes32(0), "Invalid CID");
        require(ipfsCID != currentModelCID, "CID already active");
        
        uint256 proposalId = proposalCount;
        
        // Create operation ID for SovereignShield
        bytes32 operationId = keccak256(
            abi.encodePacked(ipfsCID, msg.sender, block.timestamp, proposalId)
        );
        
        // *** ADDED: SovereignShield validation ***
        if (address(sovereignShield) != address(0)) {
            // Pack proposal data for validation
            bytes memory proposalData = abi.encodePacked(
                ipfsCID,
                description,
                modelData,
                msg.sender,
                block.timestamp
            );
            
            bool shieldValidated = sovereignShield.validateOperation(
                operationId,
                proposalData,
                signature,
                publicKey
            );
            
            require(shieldValidated, "SovereignShield validation failed");
            
            emit QuantumSafeModelValidation(
                proposalId,
                ipfsCID,
                shieldValidated,
                block.timestamp
            );
        }
        
        // Continue with normal proposal creation
        proposalCount++;
        
        proposals[proposalId] = ModelProposal({
            ipfsCID: ipfsCID,
            proposer: msg.sender,
            timestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            description: description
        });
        
        emit ModelProposalCreated(proposalId, ipfsCID, msg.sender, description);
        
        return proposalId;
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
    
    function authorizeEFA(address efa) external {
        require(msg.sender == ggcMultisig, "Only GGC");
        authorizedEFAs[efa] = true;
    }
}
