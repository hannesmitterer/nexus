# Governance Framework - Hardhat Workflows

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Date**: 2026-01-13  
**Framework**: Euystacio / SAIN Protocol

---

## Overview

The Hardhat Governance Framework provides automated, decentralized decision-making infrastructure for the Nexus ecosystem. This implementation ensures alignment with the Euystacio governance framework through:

- **Automated Workflows**: Hardhat-based deployment and testing automation
- **Governance Metrics Registry**: Smart contract tracking quorum and sustainability thresholds
- **Anchored Records**: Cryptographically secured governance decisions with IPFS integration
- **Stress-Tested**: Validated for production deployment on Polygon

## Quick Start

```bash
# Install dependencies
npm install --legacy-peer-deps

# Compile contracts
npm run compile

# Run tests
npm test

# Run stress tests
npm run stress-test

# Validate implementation
bash scripts/validate-governance.sh

# Deploy to testnet (Mumbai)
npx hardhat run scripts/deploy/deploy-governance-sync.js --network mumbai

# Deploy to mainnet (Polygon)
npx hardhat run scripts/deploy/deploy-governance-sync.js --network polygon
```

## Key Features

### 🏛️ Governance Metrics Registry

Smart contract providing:

- **Quorum Management**: Configurable thresholds (51%-90%, default 67%)
- **Sustainability Tracking**: TRE, PV, ISF metrics with compliance checking
- **Record Anchoring**: Immutable governance decisions with IPFS CIDs
- **Multi-signature Control**: 7-of-9 GGC governance
- **Historical Audit**: Complete metrics and decision history

### 🚀 Deployment Workflows

Two deployment approaches:

1. **Standard Deployment** (`hardhat deploy`)
   - Tagged deployment system
   - Automatic verification
   - Network-specific artifacts

2. **Synchronous Deployment** (custom script)
   - Step-by-step process
   - Cryptographic anchoring
   - Deployment record generation
   - Configuration validation

### ✅ Testing Infrastructure

Comprehensive test coverage:

- **Unit Tests**: 12+ test cases (335 lines)
  - Deployment validation
  - Access control
  - Threshold management
  - Record anchoring
  - Metrics tracking

- **Stress Tests**: 7 scenarios (325 lines)
  - Rapid deployments (10 contracts)
  - Record anchoring (50+ records)
  - Batch operations (20+ executions)
  - Metrics recording (100+ snapshots)
  - Data integrity validation

### 📚 Documentation

Complete guides:

1. **Hardhat Governance Workflows** (`docs/HARDHAT_GOVERNANCE_WORKFLOWS.md`)
   - Architecture overview
   - Setup instructions
   - Deployment procedures
   - Testing guidelines
   - Best practices

2. **Integration Guide** (`docs/GOVERNANCE_INTEGRATION_GUIDE.md`)
   - Quick start
   - Environment setup
   - Integration examples
   - Automated workflows
   - Monitoring setup

3. **Implementation Summary** (`GOVERNANCE_FRAMEWORK_SUMMARY.md`)
   - Component overview
   - Features description
   - Deployment readiness
   - Security considerations

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│         Governance Metrics Registry (Smart Contract)    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Quorum Management        Sustainability Tracking       │
│  ├─ Set Threshold        ├─ TRE (≥0.30%)              │
│  ├─ Validate Range       ├─ PV (≤5.0%)                │
│  └─ Event Logging        └─ ISF (≥75)                 │
│                                                          │
│  Record Anchoring         Metrics Storage               │
│  ├─ Hash Generation      ├─ Snapshots                  │
│  ├─ IPFS Integration     ├─ History                    │
│  └─ Execution Tracking   └─ Compliance Check           │
│                                                          │
└─────────────────────────────────────────────────────────┘
                           ▲
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐      ┌─────▼──────┐    ┌─────▼──────┐
   │   ULP   │      │    TFK     │    │    EIM     │
   │Contract │      │  Verifier  │    │   Client   │
   └─────────┘      └────────────┘    └────────────┘
```

## Sustainability Metrics

### TRE - Tasso di Rigenerazione Etica

**Definition**: Ethical regeneration rate measuring ecosystem health

**Target**: ≥0.30% annually  
**Range**: 0.01% - 10%  
**Calculation**: (Regenerative Actions / Total Actions) × 100

### PV - Planetary Violence

**Definition**: Environmental and social harm index

**Maximum**: ≤5.0%  
**Range**: 0% - 20%  
**Calculation**: (Harmful Impacts / Total Impacts) × 100

### ISF - Integral Scarcity Factor

**Definition**: Resource abundance and accessibility measure

**Minimum**: ≥75 (on 0-100 scale)  
**Range**: 0 - 100  
**Calculation**: Composite of resource availability metrics

## Deployment Guide

### Prerequisites

- Node.js ≥16.0.0
- Hardhat installed
- GGC Multisig wallet (7-of-9)
- Network access (Polygon/Mumbai)
- Sufficient MATIC for gas

### Environment Setup

Create `.env`:

```env
POLYGON_RPC_URL=https://polygon-rpc.com
MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com
DEPLOYER_PRIVATE_KEY=your_private_key
GGC_MULTISIG_ADDRESS=0x...
POLYGONSCAN_API_KEY=your_api_key
```

### Local Testing

```bash
# Start Hardhat node
npx hardhat node

# Deploy (in new terminal)
npx hardhat run scripts/deploy/deploy-governance-sync.js --network hardhat
```

### Testnet Deployment

```bash
# Deploy to Mumbai
npx hardhat run scripts/deploy/deploy-governance-sync.js --network mumbai

# Verify contract
npx hardhat verify --network mumbai <ADDRESS> <GGC_MULTISIG>
```

### Mainnet Deployment

```bash
# Deploy to Polygon
npx hardhat run scripts/deploy/deploy-governance-sync.js --network polygon

# Verify on Polygonscan
npx hardhat verify --network polygon <ADDRESS> <GGC_MULTISIG>
```

## Integration Examples

### Recording Metrics

```javascript
const registry = await ethers.getContractAt(
  "GovernanceMetricsRegistry",
  registryAddress
);

await registry.recordMetricsSnapshot(
  35,   // TRE: 0.35%
  420,  // PV: 4.20%
  82    // ISF: 82
);

const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
```

### Anchoring Decisions

```javascript
const decisionHash = ethers.keccak256(
  ethers.toUtf8Bytes(JSON.stringify(decisionData))
);

await registry.anchorGovernanceRecord(
  decisionHash,
  7800,           // 78% quorum
  "QmIPFSCID..."  // IPFS content ID
);
```

### Checking Compliance

```javascript
const config = await registry.getGovernanceConfig();
const latest = await registry.latestMetrics();
const [isSustainable, failures] = await registry.checkSustainabilityCompliance();

console.log("Sustainability:", isSustainable);
console.log("Failed Metrics:", failures);
```

## Testing

### Run All Tests

```bash
npm test
```

### Run Specific Tests

```bash
# Unit tests only
npx hardhat test test/GovernanceMetricsRegistry.test.js

# Stress tests only
npm run stress-test

# With gas reporting
REPORT_GAS=true npm test
```

### Validation

```bash
# Validate entire implementation
bash scripts/validate-governance.sh
```

## Security

### Access Control

- All governance functions require GGC multisig (7-of-9)
- Parameter bounds enforced in contract
- Events emitted for all critical operations
- Records are immutable once anchored

### Best Practices

1. ✅ Test on Mumbai before mainnet
2. ✅ Verify contracts on Polygonscan
3. ✅ Use hardware wallets for mainnet
4. ✅ Maintain deployment artifacts
5. ✅ Regular security audits

### Recommendations

- External audit before mainnet deployment
- Formal verification of critical functions
- Multi-signature wallet testing
- Emergency procedures documentation

## Monitoring

### Key Metrics

Monitor these values regularly:

```javascript
// Governance effectiveness (target: >80%)
const effectiveness = await registry.getGovernanceEffectiveness();

// Current compliance status
const [isSustainable, failures] = await registry.checkSustainabilityCompliance();

// Configuration
const config = await registry.getGovernanceConfig();
```

### Alert Triggers

Set up alerts for:

- Sustainability threshold violations
- Low governance effectiveness (<80%)
- Unauthorized access attempts
- Parameter changes

## File Structure

```
nexus/
├── contracts/
│   └── GovernanceMetricsRegistry.sol     # Main contract
├── deploy/
│   └── 01_deploy_governance_registry.js  # Standard deploy
├── scripts/
│   ├── deploy/
│   │   └── deploy-governance-sync.js     # Sync deploy
│   └── validate-governance.sh            # Validation
├── test/
│   ├── GovernanceMetricsRegistry.test.js # Unit tests
│   └── stress/
│       └── DeploymentStressTest.js       # Stress tests
├── docs/
│   ├── HARDHAT_GOVERNANCE_WORKFLOWS.md   # Workflows guide
│   └── GOVERNANCE_INTEGRATION_GUIDE.md   # Integration guide
├── deployments/                          # Artifacts
├── hardhat.config.js                     # Hardhat config
├── package.json                          # Dependencies
└── GOVERNANCE_FRAMEWORK_SUMMARY.md       # Summary
```

## NPM Scripts

```json
{
  "compile": "hardhat compile",
  "test": "hardhat test",
  "test:governance": "hardhat test test/GovernanceMetricsRegistry.test.js",
  "stress-test": "hardhat test test/stress/DeploymentStressTest.js",
  "deploy:local": "hardhat deploy --network hardhat",
  "deploy:mumbai": "hardhat deploy --network mumbai",
  "deploy:polygon": "hardhat deploy --network polygon"
}
```

## Support

- **Documentation**: `/docs/` directory
- **Issues**: GitHub Issues
- **Governance**: governance@euystacio.example
- **Repository**: https://github.com/hannesmitterer/nexus

## License

MIT License - See repository for details

## Acknowledgments

Developed for the Euystacio framework and SAIN Protocol as part of the Nexus Global Governance Initiative (GGI).

---

**Ready for Production**: All components validated and tested  
**Next Steps**: Testnet deployment → External audit → Mainnet launch
