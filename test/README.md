# Synthia Genesis Tests

This directory contains tests for the Synthia Genesis Block implementation.

## Test Files

### SynthiaGenesis.t.sol
Comprehensive test suite for the SynthiaGenesis contract covering:
- Genesis block initialization
- Alignment proof submission
- EFA authorization and revocation
- Access control enforcement
- Immutability guarantees
- Synthia compatibility verification

## Running Tests

### With Foundry (Recommended)

If you have Foundry installed:

```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test contract
forge test --match-contract SynthiaGenesisTest

# Run specific test function
forge test --match-test testInitializeGenesisBlock
```

### Without Test Framework

The contracts include basic validation that can be manually verified:

1. **Deploy contracts**:
   ```bash
   forge script scripts/DeploySynthiaGenesis.s.sol --rpc-url $RPC_URL
   ```

2. **Initialize genesis block**:
   ```bash
   ./scripts/initialize_synthia_genesis.sh
   ```

3. **Verify deployment**:
   ```bash
   ./scripts/verify_synthia_genesis.sh
   ```

## Test Coverage

### Core Functionality ✅
- [x] Genesis block initialization
- [x] Alignment score validation (minimum 94/100)
- [x] Initial EFA authorization
- [x] Genesis hash generation
- [x] Immutability enforcement

### Access Control ✅
- [x] GGC multisig-only functions
- [x] Unauthorized access prevention
- [x] Modifier enforcement

### Alignment Verification ✅
- [x] NSR compliance check
- [x] OLF alignment scoring
- [x] Sentimento verification
- [x] Alignment proof submission

### EFA Management ✅
- [x] EFA authorization
- [x] EFA revocation
- [x] EFA count tracking
- [x] Authorization status queries

### Integration ✅
- [x] Synthia compatibility verification
- [x] Genesis info retrieval
- [x] Alignment status retrieval

## Writing New Tests

To add new tests, follow this pattern:

```solidity
function testYourNewFeature() public {
    // Setup
    testInitializeGenesisBlock();  // Or other setup
    
    // Execute
    _actAsGGC();
    genesis.yourFunction();
    
    // Verify
    require(condition, "Error message");
}
```

## Mock Contracts

### MockEuystacioAlignment.sol
Mock implementation of IEuystacioAlignment for testing:
- Configurable NSR compliance
- Configurable OLF scores
- Configurable Sentimento alignment

Usage:
```solidity
MockEuystacioAlignment mock = new MockEuystacioAlignment();
mock.setDefaults(94, true, true);  // score, NSR, Sentimento
mock.setOLFScore(genesisHash, 95);  // Override for specific hash
```

## Continuous Integration

For CI/CD integration, add to your workflow:

```yaml
- name: Install Foundry
  uses: foundry-rs/foundry-toolchain@v1

- name: Run tests
  run: forge test
```

## Test Results Interpretation

**Expected Output**:
```
[PASS] testConstructor() (gas: XXXXX)
[PASS] testInitializeGenesisBlock() (gas: XXXXX)
[PASS] testCannotInitializeTwice() (gas: XXXXX)
[PASS] testMinimumAlignmentScore() (gas: XXXXX)
[PASS] testSubmitAlignmentProof() (gas: XXXXX)
[PASS] testAuthorizeEFA() (gas: XXXXX)
[PASS] testRevokeEFA() (gas: XXXXX)
[PASS] testSynthiaCompatibility() (gas: XXXXX)
[PASS] testGetGenesisInfo() (gas: XXXXX)

Test result: ok. X passed; 0 failed; finished in XXs
```

## Limitations

Note: The current test suite has a limitation in that it cannot fully test access control without Foundry's `vm.prank()` functionality. For complete access control testing, use Foundry or Hardhat.

## Security Testing

Before deployment, ensure:
1. All tests pass
2. Access control is properly enforced
3. Immutability guarantees hold
4. Alignment verification works correctly
5. Integration with existing contracts is verified

## License

MIT License - See LICENSE file for details
