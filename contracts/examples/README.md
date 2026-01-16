# Integration Examples

This directory contains example contracts demonstrating how to integrate SovereignShield quantum-safe security with existing Nexus contracts.

## Overview

These examples show the minimal changes needed to add quantum-safe NTRU validation to existing contracts:

1. **EIMClientWithShield.sol** - Enhanced EIMClient with SovereignShield integration
2. **TFKVerifierWithShield.sol** - Enhanced TFKVerifier with SovereignShield integration

## Key Changes

### Common Pattern

All integrations follow this pattern:

1. Add `ISovereignShield` interface
2. Add `sovereignShield` state variable
3. Add SovereignShield address to constructor
4. Add `signature` and `publicKey` parameters to critical functions
5. Call `sovereignShield.validateOperation()` before processing
6. Add governance functions to update SovereignShield settings

### EIMClientWithShield

Changes from original `EIMClient.sol`:

```solidity
// Added state variables
ISovereignShield public sovereignShield;
bool public quantumSafeRequired;

// Updated constructor
constructor(
    address _ggcMultisig, 
    address _tfkVerifier,
    address _sovereignShield  // NEW
)

// Updated submitSEP function
function submitSEP(
    bytes32 sepId,
    string calldata artifactType,
    bytes32 inputDigest,
    bytes32 outputDigest,
    bytes32 modelDigest,
    bytes calldata signature,    // NEW
    bytes calldata publicKey     // NEW
) external returns (bytes32 operationHash) {
    // ... existing validation ...
    
    // NEW: SovereignShield validation
    if (address(sovereignShield) != address(0)) {
        bytes memory sepData = abi.encodePacked(...);
        bool validated = sovereignShield.validateOperation(
            operationHash,
            sepData,
            signature,
            publicKey
        );
        require(validated, "SovereignShield validation failed");
    }
    
    // ... continue with normal processing ...
}
```

### TFKVerifierWithShield

Changes from original `TFKVerifier.sol`:

```solidity
// Added state variables
ISovereignShield public sovereignShield;
bool public quantumSafeRequired;

// Updated propose_model_retrain function
function propose_model_retrain(
    bytes32 ipfsCID,
    string calldata description,
    bytes calldata modelData,      // NEW
    bytes calldata signature,      // NEW
    bytes calldata publicKey       // NEW
) external returns (uint256) {
    // NEW: SovereignShield validation
    if (address(sovereignShield) != address(0)) {
        bytes memory proposalData = abi.encodePacked(...);
        bool validated = sovereignShield.validateOperation(
            operationId,
            proposalData,
            signature,
            publicKey
        );
        require(validated, "SovereignShield validation failed");
    }
    
    // ... continue with normal proposal creation ...
}
```

## Deployment Order

1. Deploy `NTRUVerifier`:
   ```solidity
   NTRUVerifier verifier = new NTRUVerifier(ggcMultisig);
   ```

2. Deploy `SovereignShield`:
   ```solidity
   SovereignShield shield = new SovereignShield(ggcMultisig, address(verifier));
   ```

3. Configure filters:
   ```solidity
   // SEP filter for EIMClient
   bytes32 sepFilterId = keccak256("SEP_FILTER");
   shield.configureFilter(sepFilterId, 1024*1024, 100, 50, 1 hours, true);
   
   // Model filter for TFKVerifier
   bytes32 modelFilterId = keccak256("MODEL_FILTER");
   shield.configureFilter(modelFilterId, 10*1024*1024, 1024, 10, 1 hours, true);
   ```

4. Deploy enhanced contracts:
   ```solidity
   EIMClientWithShield eim = new EIMClientWithShield(
       ggcMultisig,
       tfkVerifier,
       address(shield)
   );
   
   TFKVerifierWithShield tfk = new TFKVerifierWithShield(
       ggcMultisig,
       initialModelCID,
       address(shield)
   );
   ```

5. Protect contracts:
   ```solidity
   shield.protectContract(address(eim), sepFilterId);
   shield.protectContract(address(tfk), modelFilterId);
   ```

## Usage Examples

### Submitting a SEP with Quantum-Safe Signature

```javascript
// JavaScript/TypeScript example
const sepId = ethers.utils.keccak256(sepData);
const artifactType = "INFERENCE_BLOCK";

// Generate NTRU signature (using hypothetical library)
const keyPair = await generateNTRUKeyPair();
const messageHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
        ['bytes32', 'string', 'bytes32', 'bytes32', 'bytes32'],
        [sepId, artifactType, inputDigest, outputDigest, modelDigest]
    )
);
const signature = await signNTRU(messageHash, keyPair.privateKey);

// Submit SEP
const tx = await eimClient.submitSEP(
    sepId,
    artifactType,
    inputDigest,
    outputDigest,
    modelDigest,
    signature,
    keyPair.publicKey
);
```

### Proposing Model Retrain with Quantum-Safe Validation

```javascript
// JavaScript/TypeScript example
const ipfsCID = ethers.utils.keccak256(modelHash);
const description = "Improved accuracy model v2.0";
const modelData = ethers.utils.toUtf8Bytes(modelMetadata);

// Generate NTRU signature
const keyPair = await generateNTRUKeyPair();
const messageHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
        ['bytes32', 'string', 'bytes'],
        [ipfsCID, description, modelData]
    )
);
const signature = await signNTRU(messageHash, keyPair.privateKey);

// Propose model retrain
const tx = await tfkVerifier.propose_model_retrain(
    ipfsCID,
    description,
    modelData,
    signature,
    keyPair.publicKey
);
```

## Benefits

### Quantum-Safe Security

- **NTRU Signatures**: Lattice-based cryptography resistant to quantum attacks
- **Post-Quantum Ready**: Protects against future quantum computing threats
- **Configurable**: Can be enabled/disabled based on environment

### Scalable Validation

- **Input Size Limits**: Prevents oversized data submission
- **Rate Limiting**: Protects against spam and DoS attacks
- **Per-Contract Filters**: Different rules for different contract types

### Operational Safety

- **Checkpoints**: Create snapshots before critical operations
- **Rollback**: Revert to previous state if needed
- **Monitoring**: Track validation statistics and success rates

## Backward Compatibility

The integration is designed to be backward compatible:

1. **Optional SovereignShield**: If address is `0x0`, contracts work without it
2. **Gradual Rollout**: Can deploy with quantum-safe disabled, then enable later
3. **Lightweight Mode**: Use `validateOperationLight()` for non-critical operations

## Testing

### Unit Test Example

```solidity
// Test SovereignShield integration
function testSubmitSEPWithShield() public {
    // Deploy contracts
    NTRUVerifier verifier = new NTRUVerifier(ggc);
    SovereignShield shield = new SovereignShield(ggc, address(verifier));
    EIMClientWithShield eim = new EIMClientWithShield(
        ggc, tfk, address(shield)
    );
    
    // Configure filter
    bytes32 filterId = keccak256("TEST");
    shield.configureFilter(filterId, 1024, 1, 10, 1 hours, false);
    shield.protectContract(address(eim), filterId);
    
    // Register SAN
    vm.prank(ggc);
    eim.registerSAN(san);
    
    // Submit SEP
    vm.prank(san);
    bytes32 opHash = eim.submitSEP(
        sepId, "TEST", input, output, model,
        signature, publicKey
    );
    
    // Verify
    assertTrue(shield.isOperationValidated(opHash));
}
```

## Migration Guide

To migrate existing contracts:

1. **Review Examples**: Study `EIMClientWithShield.sol` and `TFKVerifierWithShield.sol`
2. **Add Interface**: Import `ISovereignShield` interface
3. **Update Constructor**: Add SovereignShield address parameter
4. **Update Functions**: Add signature and publicKey parameters to critical functions
5. **Add Validation**: Call `sovereignShield.validateOperation()` at start of function
6. **Add Governance**: Add functions to update SovereignShield settings
7. **Test Thoroughly**: Ensure backward compatibility and proper validation

## Security Considerations

1. **Always Verify**: Never skip SovereignShield validation in production
2. **Use Quantum-Safe**: Enable `quantumSafeRequired` for critical operations
3. **Configure Filters**: Set appropriate limits for each contract type
4. **Monitor Statistics**: Track validation success/failure rates
5. **Test Signatures**: Validate NTRU signature generation before deployment

## Resources

- Full Integration Guide: `/docs/SOVEREIGNSHIELD_INTEGRATION.md`
- SovereignShield Contract: `/contracts/SovereignShield.sol`
- NTRUVerifier Contract: `/contracts/NTRUVerifier.sol`
- AWS Deployment: `/aws/README.md`
