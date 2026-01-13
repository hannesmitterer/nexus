# Hardhat Governance Workflows Guide

## Overview

This document describes the Hardhat-based workflows for automated governance within the Nexus Euystacio framework. These workflows enable decentralized decision-making automation through smart contracts and provide comprehensive support for governance metrics, quorum management, and sustainability tracking.

## Table of Contents

1. [Architecture](#architecture)
2. [Setup and Installation](#setup-and-installation)
3. [Deployment Workflows](#deployment-workflows)
4. [Governance Metrics Registry](#governance-metrics-registry)
5. [Testing and Validation](#testing-and-validation)
6. [Stress Testing](#stress-testing)
7. [Best Practices](#best-practices)

---

## Architecture

### Components

The Hardhat governance framework consists of:

- **GovernanceMetricsRegistry.sol**: Core smart contract for tracking governance metrics, quorum thresholds, and sustainability indicators
- **Deployment Scripts**: Automated deployment workflows for synchronous and anchored deployments
- **Test Suites**: Comprehensive testing including unit tests and stress tests
- **Configuration**: Hardhat configuration for multiple networks (local, Mumbai testnet, Polygon mainnet)

### Key Features

1. **Quorum Management**: Configurable quorum thresholds (51%-90%) with 67% default
2. **Sustainability Tracking**: 
   - TRE (Tasso di Rigenerazione Etica) - Target: 0.30%
   - PV (Planetary Violence) - Max: 5.0%
   - ISF (Integral Scarcity Factor) - Min: 75
3. **Anchored Records**: Immutable governance decision records with IPFS integration
4. **Multi-signature Control**: 7-of-9 GGC multisig governance

---

## Setup and Installation

### Prerequisites

- Node.js >= 16.0.0
- npm or yarn
- Git

### Installation Steps

```bash
# Clone the repository
git clone https://github.com/hannesmitterer/nexus.git
cd nexus

# Install dependencies
npm install

# Compile contracts
npm run compile
```

### Environment Configuration

Create a `.env` file in the root directory:

```env
# Network Configuration
POLYGON_RPC_URL=https://polygon-rpc.com
MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com

# Deployment Keys
DEPLOYER_PRIVATE_KEY=your_private_key_here

# Contract Addresses
GGC_MULTISIG_ADDRESS=0x...

# API Keys
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

**⚠️ Security Warning**: Never commit `.env` files or private keys to version control.

---

## Deployment Workflows

### Local Deployment (Testing)

Deploy to local Hardhat network for testing:

```bash
# Start local Hardhat node
npx hardhat node

# In a new terminal, deploy contracts
npm run deploy:local
```

### Testnet Deployment (Mumbai)

Deploy to Polygon Mumbai testnet:

```bash
# Deploy using hardhat-deploy
npm run deploy:mumbai

# Or use synchronous deployment script
npx hardhat run scripts/deploy/deploy-governance-sync.js --network mumbai
```

### Mainnet Deployment (Polygon)

Deploy to Polygon mainnet with full anchoring:

```bash
# Deploy with anchored governance records
npx hardhat run scripts/deploy/deploy-governance-sync.js --network polygon

# Verify on Polygonscan
npm run verify:polygon -- <CONTRACT_ADDRESS> <GGC_MULTISIG_ADDRESS>
```

### Synchronous Deployment Features

The synchronous deployment script provides:

1. **Step-by-step deployment** with verification at each stage
2. **Anchored governance records** - cryptographic hash of deployment parameters
3. **Artifact generation** - JSON files with deployment data and ABI
4. **Automatic verification** - validates configuration post-deployment

Example output:

```
============================================================
SYNCHRONOUS GOVERNANCE DEPLOYMENT
Network: polygon
============================================================

Deployer address: 0x...
GGC Multisig: 0x...

============================================================
Step 1: Deploying GovernanceMetricsRegistry
============================================================
✓ GovernanceMetricsRegistry deployed at: 0x...

============================================================
Step 2: Verifying Configuration
============================================================
✓ Configuration verified:
  GGC Multisig: 0x...
  Quorum Threshold: 6700 bps ( 67 %)
  TRE Target: 30 bps
  Max PV: 500 bps
  Min ISF: 75

============================================================
Step 3: Anchoring Deployment Record
============================================================
✓ Deployment record created:
  Record hash: 0x...

✓ SUCCESSFULLY DEPLOYED AND ANCHORED
============================================================
```

---

## Governance Metrics Registry

### Contract Overview

The `GovernanceMetricsRegistry` contract provides:

- **Quorum threshold management** for voting decisions
- **Sustainability metrics tracking** (TRE, PV, ISF)
- **Governance record anchoring** with IPFS integration
- **Historical metrics** for audit and analysis

### Key Functions

#### Governance Configuration

```solidity
// Update quorum threshold (only GGC multisig)
function setQuorumThreshold(uint256 _newQuorumBps) external onlyGGC

// Update sustainability targets
function setTreSustainabilityTarget(uint256 _newTarget) external onlyGGC
function setMaxPlanetaryViolence(uint256 _newMax) external onlyGGC
function setMinIntegralScarcityFactor(uint256 _newMin) external onlyGGC
```

#### Record Management

```solidity
// Anchor a governance decision
function anchorGovernanceRecord(
    bytes32 _recordHash,
    uint256 _quorumAchieved,
    string calldata _ipfsCid
) external onlyGGC returns (bytes32 recordId)

// Execute a governance decision
function executeGovernanceRecord(bytes32 _recordId) external onlyGGC
```

#### Metrics Tracking

```solidity
// Record metrics snapshot
function recordMetricsSnapshot(
    uint256 _treRate,
    uint256 _planetaryViolence,
    uint256 _scarcityFactor
) external onlyGGC

// Check sustainability compliance
function checkSustainabilityCompliance() 
    external view 
    returns (bool isSustainable, string[] memory failedMetrics)
```

### Usage Examples

#### Anchoring a Governance Decision

```javascript
const { ethers } = require("hardhat");

async function anchorDecision() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    "0x..." // deployed address
  );

  // Create decision data
  const decisionData = {
    proposal: "Update TRE target to 0.35%",
    votingResults: { for: 7, against: 2 },
    timestamp: Date.now()
  };

  // Hash the decision
  const recordHash = ethers.keccak256(
    ethers.toUtf8Bytes(JSON.stringify(decisionData))
  );

  // Upload to IPFS and get CID
  const ipfsCid = "QmYourDecisionCID";

  // Anchor on-chain (78% quorum achieved)
  const tx = await registry.anchorGovernanceRecord(
    recordHash,
    7800, // 78% quorum
    ipfsCid
  );

  const receipt = await tx.wait();
  console.log("Decision anchored:", receipt.transactionHash);
}
```

#### Recording Metrics

```javascript
async function recordMonthlyMetrics() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    "0x..."
  );

  // Current sustainability metrics
  const treRate = 35;           // 0.35% TRE
  const planetaryViolence = 420; // 4.20% PV
  const scarcityFactor = 82;     // ISF of 82

  const tx = await registry.recordMetricsSnapshot(
    treRate,
    planetaryViolence,
    scarcityFactor
  );

  await tx.wait();
  console.log("Metrics recorded");

  // Check compliance
  const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
  
  if (isSustainable) {
    console.log("✓ All sustainability thresholds met");
  } else {
    console.log("✗ Failed metrics:", failures);
  }
}
```

---

## Testing and Validation

### Unit Tests

Run comprehensive unit tests:

```bash
# Run all tests
npm test

# Run only governance tests
npm run test:governance

# Run with gas reporting
REPORT_GAS=true npm test
```

### Test Coverage

The test suite covers:

- ✅ Deployment and initialization
- ✅ Quorum threshold management (bounds, authorization)
- ✅ Sustainability threshold updates
- ✅ Governance record anchoring
- ✅ Record execution and tracking
- ✅ Metrics recording and compliance checking
- ✅ Access control (GGC multisig only)
- ✅ Data integrity and validation

### Example Test Output

```
  GovernanceMetricsRegistry
    Deployment
      ✓ Should set the correct GGC multisig address
      ✓ Should initialize with default quorum threshold (67%)
      ✓ Should initialize sustainability thresholds correctly
    Quorum Management
      ✓ Should allow GGC to update quorum threshold
      ✓ Should reject quorum below minimum (51%)
      ✓ Should reject quorum above maximum (90%)
    Governance Record Anchoring
      ✓ Should anchor governance record successfully
      ✓ Should reject record with insufficient quorum
      ✓ Should execute governance record
    Metrics Tracking
      ✓ Should record metrics snapshot
      ✓ Should check sustainability compliance correctly
      ✓ Should detect multiple threshold failures

  12 passing (2.3s)
```

---

## Stress Testing

### Purpose

Stress tests validate the system's ability to handle:

- Rapid sequential deployments
- High-volume record anchoring
- Concurrent operations
- Data integrity under load

### Running Stress Tests

```bash
# Run stress test suite
npm run stress-test

# Or directly with Hardhat
npx hardhat test test/stress/DeploymentStressTest.js
```

### Stress Test Scenarios

1. **Rapid Sequential Deployments**: 10 contract deployments in succession
2. **Record Anchoring Load**: 50 sequential governance records
3. **Batch Execution**: Execute 20 anchored records efficiently
4. **Metrics Recording**: 100 metrics snapshots
5. **Mixed Operations**: 30 concurrent operations of different types
6. **Data Integrity**: Verify all data after heavy load
7. **Gas Analysis**: Track gas usage for key operations

### Example Stress Test Output

```
=== Starting Rapid Deployment Test ===
  Deployment 1: 0x... (523ms)
  Deployment 2: 0x... (489ms)
  ...
  Deployment 10: 0x... (501ms)

✓ All 10 deployments completed in 5124ms
  Average time per deployment: 512.4ms

=== Testing Sequential Record Anchoring ===
  Anchored 10 records...
  Anchored 20 records...
  ...
  Anchored 50 records...

✓ Anchored 50 records in 12389ms
  Average time per record: 247.78ms
```

---

## Best Practices

### Deployment

1. **Always test on Mumbai testnet** before mainnet deployment
2. **Use synchronous deployment script** for production to ensure proper anchoring
3. **Verify contracts on Polygonscan** for transparency
4. **Save deployment artifacts** for audit trail
5. **Document deployment parameters** in governance records

### Governance Operations

1. **Anchor all significant decisions** with IPFS CIDs
2. **Maintain quorum thresholds** between 51% and 90%
3. **Record metrics regularly** (monthly recommended)
4. **Monitor sustainability compliance** and act on failures
5. **Execute anchored records** to maintain governance effectiveness

### Security

1. **Multi-signature control**: Always use 7-of-9 GGC multisig
2. **Parameter validation**: Contract enforces all threshold bounds
3. **Access control**: Only GGC multisig can modify governance parameters
4. **Immutable records**: Anchored records cannot be modified
5. **Audit trail**: All operations emit events for transparency

### Monitoring

Monitor the following metrics:

- **Governance Effectiveness**: `getGovernanceEffectiveness()` - target >80%
- **Sustainability Compliance**: `checkSustainabilityCompliance()` - should be true
- **TRE Rate**: Should be ≥0.30%
- **Planetary Violence**: Should be ≤5.0%
- **Integral Scarcity Factor**: Should be ≥75

### Integration with Existing Systems

The governance framework integrates with:

- **SAIN Protocol**: Provides metrics for TRE and sustainability tracking
- **ULP Contract**: Uses governance decisions for parameter updates
- **EIM Client**: Reports automated monitoring data to registry
- **TFK Verifier**: Anchors model retraining decisions

---

## Troubleshooting

### Common Issues

**Issue**: Deployment fails with "insufficient funds"
- **Solution**: Ensure deployer wallet has enough MATIC for gas

**Issue**: "Only GGC multisig authorized" error
- **Solution**: Verify you're calling from correct GGC multisig address

**Issue**: "Quorum not met" when anchoring record
- **Solution**: Ensure quorum achieved is ≥ current threshold (default 67%)

**Issue**: Contract verification fails on Polygonscan
- **Solution**: Check compiler version matches (0.8.21) and use correct constructor args

### Getting Help

- Documentation: `/docs/` directory
- Issues: GitHub Issues
- Governance: governance@euystacio.example

---

## Appendix

### Contract Constants

```solidity
MIN_QUORUM_BPS = 5100         // 51% minimum quorum
MAX_QUORUM_BPS = 9000         // 90% maximum quorum  
DEFAULT_QUORUM_BPS = 6700     // 67% default quorum
TRE_TARGET = 30               // 0.30% TRE target
MAX_PV = 500                  // 5.0% max planetary violence
MIN_ISF = 75                  // 75 minimum ISF
```

### Network IDs

- Hardhat Local: 31337
- Polygon Mumbai: 80001
- Polygon Mainnet: 137

### Useful Commands

```bash
# Compile contracts
npm run compile

# Run tests
npm test

# Deploy locally
npm run deploy:local

# Deploy to Mumbai
npm run deploy:mumbai

# Deploy to Polygon
npm run deploy:polygon

# Stress test
npm run stress-test

# Clean build artifacts
npx hardhat clean
```

---

**Version**: 1.0.0  
**Last Updated**: 2026-01-13  
**Framework**: Euystacio / SAIN Protocol  
**License**: MIT
