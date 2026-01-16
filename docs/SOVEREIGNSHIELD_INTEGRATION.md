# SovereignShield Integration Guide

## Overview

This guide explains how to integrate SovereignShield quantum-safe security with existing Nexus contracts (EIMClient and TFKVerifier).

## Architecture

SovereignShield provides a modular security layer that can be integrated with existing contracts to add:
- Quantum-safe NTRU signature verification
- Scalable input validation with configurable filters
- Rate limiting protection
- Rollback/checkpoint capabilities for WIP deployments

## Integration Steps

### 1. Deploy Core Contracts

First, deploy the core security contracts:

```solidity
// 1. Deploy NTRUVerifier
NTRUVerifier verifier = new NTRUVerifier(ggcMultisigAddress);

// 2. Deploy SovereignShield
SovereignShield shield = new SovereignShield(
    ggcMultisigAddress,
    address(verifier)
);
```

### 2. Configure Validation Filters

Create custom filters for different contract types:

```solidity
// Filter for EIMClient SEP validation
bytes32 sepFilterId = keccak256("SEP_VALIDATION_FILTER");
shield.configureFilter(
    sepFilterId,
    1024 * 1024,      // maxInputSize: 1MB
    100,              // minInputSize: 100 bytes
    50,               // rateLimit: 50 operations
    1 hours,          // timeWindow
    true              // requireQuantumSafe
);

// Filter for TFKVerifier model proposals
bytes32 modelFilterId = keccak256("MODEL_PROPOSAL_FILTER");
shield.configureFilter(
    modelFilterId,
    10 * 1024 * 1024, // maxInputSize: 10MB (models are larger)
    1024,             // minInputSize: 1KB
    10,               // rateLimit: 10 proposals per hour
    1 hours,          // timeWindow
    true              // requireQuantumSafe
);
```

### 3. Protect Existing Contracts

Register existing contracts with SovereignShield:

```solidity
// Protect EIMClient
shield.protectContract(address(eimClient), sepFilterId);

// Protect TFKVerifier
shield.protectContract(address(tfkVerifier), modelFilterId);
```

### 4. Integrate with EIMClient

Modify EIMClient to use SovereignShield for SEP validation:

```solidity
// In EIMClient contract
contract EIMClient is IFinalizable {
    // Add SovereignShield reference
    SovereignShield public sovereignShield;
    
    // Update constructor
    constructor(
        address _ggcMultisig, 
        address _tfkVerifier,
        address _sovereignShield  // Add this parameter
    ) {
        // ... existing code ...
        sovereignShield = SovereignShield(_sovereignShield);
    }
    
    // Update submitSEP function
    function submitSEP(
        bytes32 sepId,
        string calldata artifactType,
        bytes32 inputDigest,
        bytes32 outputDigest,
        bytes32 modelDigest,
        bytes calldata signature,      // Add NTRU signature
        bytes calldata publicKey        // Add public key
    ) external onlyRegisteredSAN returns (bytes32 operationHash) {
        // Pack SEP data for validation
        bytes memory sepData = abi.encodePacked(
            sepId, 
            artifactType, 
            inputDigest, 
            outputDigest, 
            modelDigest
        );
        
        // Validate with SovereignShield
        require(
            sovereignShield.validateOperation(
                sepId,
                sepData,
                signature,
                publicKey
            ),
            "SovereignShield validation failed"
        );
        
        // ... rest of existing submitSEP logic ...
    }
}
```

### 5. Integrate with TFKVerifier

Modify TFKVerifier to use SovereignShield for model proposals:

```solidity
// In TFKVerifier contract
contract TFKVerifier {
    // Add SovereignShield reference
    SovereignShield public sovereignShield;
    
    // Update constructor
    constructor(
        address _ggcMultisig, 
        bytes32 _initialModelCID,
        address _sovereignShield  // Add this parameter
    ) {
        // ... existing code ...
        sovereignShield = SovereignShield(_sovereignShield);
    }
    
    // Update propose_model_retrain function
    function propose_model_retrain(
        bytes32 ipfsCID,
        string calldata description,
        bytes calldata modelData,      // Add model data
        bytes calldata signature,      // Add NTRU signature
        bytes calldata publicKey       // Add public key
    ) external onlyAuthorizedEFA returns (uint256) {
        // Create operation ID
        bytes32 operationId = keccak256(
            abi.encodePacked(ipfsCID, msg.sender, block.timestamp)
        );
        
        // Validate with SovereignShield
        require(
            sovereignShield.validateOperation(
                operationId,
                modelData,
                signature,
                publicKey
            ),
            "SovereignShield validation failed"
        );
        
        // ... rest of existing propose_model_retrain logic ...
    }
}
```

### 6. Lightweight Validation (Optional)

For operations that don't require quantum-safe verification:

```solidity
// Use lightweight validation
bytes32 operationId = keccak256(abi.encodePacked(data, block.timestamp));
require(
    sovereignShield.validateOperationLight(operationId, data.length),
    "Light validation failed"
);
```

## Generating NTRU Keys and Signatures

### Using JavaScript/TypeScript

```typescript
// Example using a hypothetical NTRU library
import { NTRUKeyPair, NTRUSign } from 'ntru-crypto';

// Generate key pair
const keyPair = NTRUKeyPair.generate({
    N: 743,      // Polynomial degree
    p: 3,        // Small modulus
    q: 2048      // Large modulus
});

// Sign a message
const message = ethers.utils.keccak256(sepData);
const signature = NTRUSign.sign(message, keyPair.privateKey);

// Prepare for contract call
const publicKeyBytes = ethers.utils.hexlify(keyPair.publicKey);
const signatureBytes = ethers.utils.hexlify(signature);

// Call contract
await eimClient.submitSEP(
    sepId,
    artifactType,
    inputDigest,
    outputDigest,
    modelDigest,
    signatureBytes,
    publicKeyBytes
);
```

### Using Python

```python
# Example using a hypothetical NTRU library
from ntru_crypto import NTRUKeyPair, NTRUSign
from web3 import Web3

# Generate key pair
key_pair = NTRUKeyPair.generate(N=743, p=3, q=2048)

# Sign a message
message_hash = Web3.keccak(sep_data)
signature = NTRUSign.sign(message_hash, key_pair.private_key)

# Call contract
tx = eim_client.functions.submitSEP(
    sep_id,
    artifact_type,
    input_digest,
    output_digest,
    model_digest,
    signature,
    key_pair.public_key
).transact({'from': san_address})
```

## Checkpoint and Rollback Usage

### Creating Checkpoints

```solidity
// Create a checkpoint before major operation
sovereignShield.createCheckpoint("Before protocol upgrade");

// Get current checkpoint ID
uint256 currentCheckpoint = sovereignShield.currentCheckpoint();
```

### Rolling Back

```solidity
// Rollback to previous checkpoint (only GGC multisig)
sovereignShield.rollbackToCheckpoint(previousCheckpointId);
```

### Query Checkpoint

```solidity
// Get checkpoint details
(
    bytes32 stateRoot,
    uint256 timestamp,
    string memory description,
    bool canRollback
) = sovereignShield.getCheckpoint(checkpointId);
```

## Monitoring and Statistics

### Get Validation Statistics

```solidity
(
    uint256 total,
    uint256 validated,
    uint256 rejected,
    uint256 quantumVerified,
    uint256 successRate
) = sovereignShield.getStatistics();

console.log("Total operations:", total);
console.log("Success rate:", successRate / 100, "%");
```

### Check Operation Status

```solidity
// Check if operation was validated
bool isValidated = sovereignShield.isOperationValidated(operationId);

// Get operation details
(
    address initiator,
    uint256 timestamp,
    bool validated,
    bool quantumSafeVerified,
    uint256 inputSize
) = sovereignShield.getOperation(operationId);
```

## Best Practices

### 1. Filter Configuration

- **SEP Validation**: Use strict filters with quantum-safe enabled
- **Model Proposals**: Allow larger inputs but maintain rate limits
- **Test Environments**: Use relaxed filters for development

### 2. Rate Limiting

- Set appropriate rate limits based on expected usage
- Use longer time windows for resource-intensive operations
- Monitor and adjust based on actual traffic

### 3. Quantum-Safe Signatures

- Always require quantum-safe signatures for critical operations
- Register public keys before using them
- Rotate keys periodically for enhanced security

### 4. Checkpoints

- Create checkpoints before major upgrades
- Document checkpoint purposes
- Test rollback procedures in non-production environments

### 5. Error Handling

```solidity
try sovereignShield.validateOperation(
    operationId,
    data,
    signature,
    publicKey
) returns (bool validated) {
    if (!validated) {
        // Handle validation failure
        revert("Validation failed");
    }
} catch Error(string memory reason) {
    // Handle error (rate limit, invalid input, etc.)
    emit ValidationError(operationId, reason);
    revert(reason);
}
```

## Testing

### Unit Tests

```solidity
// Test SovereignShield validation
function testValidation() public {
    // Setup
    bytes32 operationId = keccak256("test");
    bytes memory data = abi.encodePacked("test data");
    
    // Mock signature and public key
    bytes memory signature = new bytes(128);
    bytes memory publicKey = new bytes(128);
    
    // Test validation
    bool result = shield.validateOperation(
        operationId,
        data,
        signature,
        publicKey
    );
    
    assertTrue(result, "Validation should succeed");
}
```

### Integration Tests

```solidity
// Test EIMClient with SovereignShield
function testEIMClientIntegration() public {
    // Deploy contracts
    NTRUVerifier verifier = new NTRUVerifier(ggc);
    SovereignShield shield = new SovereignShield(ggc, address(verifier));
    EIMClient eim = new EIMClient(ggc, tfk, address(shield));
    
    // Configure filter
    bytes32 filterId = keccak256("TEST_FILTER");
    shield.configureFilter(filterId, 1024, 1, 10, 1 hours, false);
    shield.protectContract(address(eim), filterId);
    
    // Register SAN
    vm.prank(ggc);
    eim.registerSAN(san);
    
    // Test SEP submission
    vm.prank(san);
    bytes32 opHash = eim.submitSEP(
        sepId, "TEST", input, output, model,
        signature, publicKey
    );
    
    // Verify validation occurred
    assertTrue(shield.isOperationValidated(sepId));
}
```

## Governance

### Update Filter

```solidity
// Only admin or GGC can update filters
sovereignShield.configureFilter(
    filterId,
    newMaxSize,
    newMinSize,
    newRateLimit,
    newTimeWindow,
    requireQuantumSafe
);
```

### Update Quantum Verifier

```solidity
// Only GGC can update verifier
sovereignShield.updateQuantumVerifier(newVerifierAddress);
```

### Activate/Deactivate Filters

```solidity
// Temporarily disable a filter
sovereignShield.setFilterActive(filterId, false);

// Re-enable filter
sovereignShield.setFilterActive(filterId, true);
```

## Security Considerations

1. **Quantum-Safe Requirement**: Always enable for production
2. **Rate Limits**: Set appropriate limits to prevent DoS
3. **Input Validation**: Configure size limits based on use case
4. **Checkpoint Management**: Regular checkpoints for critical operations
5. **Access Control**: Only GGC multisig can perform sensitive operations
6. **Monitoring**: Track statistics and set up alerts for anomalies

## Troubleshooting

### Validation Failures

1. Check filter configuration
2. Verify signature and public key format
3. Check rate limits
4. Ensure contract is protected

### Rate Limit Exceeded

1. Review rate limit settings
2. Adjust time window if needed
3. Implement request queuing if necessary

### Quantum Verification Failures

1. Verify NTRU verifier is deployed and configured
2. Check public key registration
3. Validate signature generation

## Resources

- NTRU Algorithm: [NTRU Wikipedia](https://en.wikipedia.org/wiki/NTRU)
- Post-Quantum Cryptography: [NIST PQC](https://csrc.nist.gov/projects/post-quantum-cryptography)
- SovereignShield Contract: `/contracts/SovereignShield.sol`
- NTRUVerifier Contract: `/contracts/NTRUVerifier.sol`
- AWS Deployment: `/aws/README.md`
