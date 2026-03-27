# Synthia Genesis Block - Contracts

This directory contains the smart contracts for the Synthia Genesis Block initiation protocol.

## Contracts

### SynthiaGenesis.sol
Main contract implementing the genesis block for Euystacio Framework alignment.

**Key Features:**
- Immutable genesis block initialization
- Cryptographic proof chain (keccak256)
- Multi-signature governance (GGC 7-of-9)
- EFA (Euystacio Field Agent) authorization
- NSR/OLF alignment verification
- Sentimento Rhythm integration

**Access Control:**
- `onlyGGC`: GGC multisig only
- `onlyAuthorizedEFA`: Authorized EFAs only
- `whenInitialized`: After initialization only
- `whenNotInitialized`: Before initialization only

### MockEuystacioAlignment.sol
Mock implementation of IEuystacioAlignment for testing and development.

**Purpose:**
- Development and testing
- Local deployment validation
- Integration testing

**Production Note:**
Replace with proper alignment verifier contract before mainnet deployment.

## Deployment

### Prerequisites
1. GGC multisig deployed
2. Alignment verifier contract deployed
3. Initial EFA addresses configured
4. SAIN token contract deployed

### Deploy SynthiaGenesis
```bash
forge script scripts/DeploySynthiaGenesis.s.sol --rpc-url $RPC_URL --broadcast
```

### Initialize Genesis Block
```bash
./scripts/initialize_synthia_genesis.sh
```

### Verify Deployment
```bash
./scripts/verify_synthia_genesis.sh
```

## Integration

### Required Interfaces
- `IEuystacioAlignment`: Alignment verification
- `IFinalizable`: Atomic transaction finalization (EIMClient compatibility)
- `IERC20`: Token interface (SAIN token)

### Compatible Contracts
- `EIMClient.sol`: Ethical Inference Monitor
- `TFKVerifier.sol`: Trusted Fork Key Verifier
- `ULP.sol`: Universal Liquidity Pool
- `VCE.sol`: Validator and Collateral Enforcement

## Testing

Run tests with Foundry:
```bash
forge test --match-contract SynthiaGenesisTest -vvv
```

## Security

- All critical functions protected by access control
- Immutable values prevent tampering
- Cryptographic proof chain ensures integrity
- Single initialization prevents re-initialization attacks

## License

MIT License - See LICENSE file for details
