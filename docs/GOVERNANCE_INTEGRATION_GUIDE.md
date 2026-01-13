# Governance Framework Integration Guide

## Quick Start

This guide provides step-by-step instructions for integrating the Hardhat Governance Framework into your Nexus deployment workflow.

## Prerequisites

Before you begin, ensure you have:

- ✅ Node.js >= 16.0.0 installed
- ✅ Hardhat project initialized (`npm install`)
- ✅ GGC Multisig wallet address (7-of-9)
- ✅ Network access (Polygon mainnet or Mumbai testnet)
- ✅ Sufficient MATIC for deployment gas

## Installation

```bash
# From the nexus repository root
cd /home/runner/work/nexus/nexus

# Install dependencies
npm install --legacy-peer-deps

# Compile contracts
npm run compile
```

## Configuration

### 1. Environment Setup

Create `.env` file with your configuration:

```env
# Network RPC URLs
POLYGON_RPC_URL=https://polygon-rpc.com
MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com

# Deployment wallet private key
DEPLOYER_PRIVATE_KEY=your_private_key_here

# GGC Multisig address (7-of-9 configuration)
GGC_MULTISIG_ADDRESS=0x1234567890123456789012345678901234567890

# Polygonscan API key for verification
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

### 2. Verify Configuration

```bash
# Verify Hardhat configuration
npx hardhat config

# Check network connectivity
npx hardhat run scripts/check-network.js --network mumbai
```

## Deployment Workflow

### Step 1: Test Locally

```bash
# Start local Hardhat node
npx hardhat node

# In a new terminal, deploy to local network
npx hardhat run scripts/deploy/deploy-governance-sync.js --network hardhat
```

Expected output:
```
============================================================
SYNCHRONOUS GOVERNANCE DEPLOYMENT
Network: hardhat
============================================================
...
✓ SUCCESSFULLY DEPLOYED AND ANCHORED
============================================================
```

### Step 2: Deploy to Testnet (Mumbai)

```bash
# Deploy to Mumbai testnet
npx hardhat run scripts/deploy/deploy-governance-sync.js --network mumbai

# Verify deployment
npx hardhat verify --network mumbai <CONTRACT_ADDRESS> <GGC_MULTISIG_ADDRESS>
```

### Step 3: Deploy to Mainnet (Polygon)

```bash
# Deploy to Polygon mainnet
npx hardhat run scripts/deploy/deploy-governance-sync.js --network polygon

# Verify on Polygonscan
npx hardhat verify --network polygon <CONTRACT_ADDRESS> <GGC_MULTISIG_ADDRESS>
```

## Integration with Existing Contracts

### Connecting to ULP Contract

```javascript
// scripts/integrate-ulp.js
const { ethers } = require("hardhat");

async function integrateWithULP() {
  // Get deployed GovernanceMetricsRegistry
  const registryAddress = "0x..."; // From deployment
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    registryAddress
  );

  // Get ULP contract
  const ulpAddress = "0x..."; // Your ULP deployment
  const ulp = await ethers.getContractAt("ULP", ulpAddress);

  // Example: Record ULP metrics
  const treRate = 35; // 0.35% TRE
  const pv = 420;     // 4.20% Planetary Violence
  const isf = 82;     // ISF of 82

  await registry.recordMetricsSnapshot(treRate, pv, isf);
  console.log("✓ ULP metrics recorded in governance registry");
}

integrateWithULP();
```

### Integrating with TFK Verifier

```javascript
// scripts/integrate-tfk.js
const { ethers } = require("hardhat");

async function integrateWithTFK() {
  const registryAddress = "0x...";
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    registryAddress
  );

  // Anchor TFK model retrain decision
  const tfkProposalData = {
    modelCID: "QmNewModel123",
    votingResults: { for: 7, against: 2 },
    timestamp: Date.now()
  };

  const recordHash = ethers.keccak256(
    ethers.toUtf8Bytes(JSON.stringify(tfkProposalData))
  );

  await registry.anchorGovernanceRecord(
    recordHash,
    7800, // 78% quorum achieved
    tfkProposalData.modelCID
  );

  console.log("✓ TFK decision anchored in governance registry");
}

integrateWithTFK();
```

## Automated Governance Workflows

### Daily Metrics Recording

Create a cron job or automated workflow:

```javascript
// scripts/daily-metrics.js
const { ethers } = require("hardhat");

async function recordDailyMetrics() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    process.env.GOVERNANCE_REGISTRY_ADDRESS
  );

  // Fetch current metrics from your monitoring system
  const metrics = await fetchCurrentMetrics();

  // Record snapshot
  await registry.recordMetricsSnapshot(
    metrics.treRate,
    metrics.planetaryViolence,
    metrics.scarcityFactor
  );

  // Check compliance
  const [isSustainable, failures] = await registry.checkSustainabilityCompliance();

  if (!isSustainable) {
    // Alert GGC multisig
    await alertGGC({
      type: "SUSTAINABILITY_FAILURE",
      failures: failures,
      timestamp: Date.now()
    });
  }

  console.log("✓ Daily metrics recorded");
}
```

### Monthly Governance Review

```javascript
// scripts/monthly-review.js
const { ethers } = require("hardhat");

async function monthlyGovernanceReview() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    process.env.GOVERNANCE_REGISTRY_ADDRESS
  );

  // Calculate governance effectiveness
  const effectiveness = await registry.getGovernanceEffectiveness();
  console.log(`Governance Effectiveness: ${effectiveness / 100}%`);

  // Get current configuration
  const config = await registry.getGovernanceConfig();
  console.log("Current Configuration:", {
    quorum: `${config.quorum / 100}%`,
    treTarget: `${config.treTarget / 100}%`,
    pvMax: `${config.pvMax / 100}%`,
    isfMin: config.isfMin.toString()
  });

  // Review metrics history
  const historyLength = await registry.getMetricsHistoryLength();
  console.log(`Total Metrics Snapshots: ${historyLength}`);

  // Generate report
  const report = {
    effectiveness: effectiveness.toString(),
    totalDecisions: (await registry.totalGovernanceDecisions()).toString(),
    executedDecisions: (await registry.executedGovernanceDecisions()).toString(),
    metricsHistory: historyLength.toString()
  };

  // Save report
  const fs = require("fs");
  fs.writeFileSync(
    `reports/governance-${Date.now()}.json`,
    JSON.stringify(report, null, 2)
  );

  console.log("✓ Monthly review completed");
}
```

## Testing Your Integration

### Unit Tests

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/GovernanceMetricsRegistry.test.js

# Run with gas reporting
REPORT_GAS=true npm test
```

### Stress Tests

```bash
# Run stress tests to validate performance
npm run stress-test
```

### Integration Tests

Create custom integration tests:

```javascript
// test/integration/FullWorkflow.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Full Governance Workflow Integration", function () {
  it("Should complete end-to-end governance cycle", async function () {
    // 1. Deploy registry
    const [deployer, ggcMultisig] = await ethers.getSigners();
    const Registry = await ethers.getContractFactory("GovernanceMetricsRegistry");
    const registry = await Registry.deploy(ggcMultisig.address);
    await registry.waitForDeployment();

    // 2. Record initial metrics
    await registry.connect(ggcMultisig).recordMetricsSnapshot(35, 400, 80);

    // 3. Anchor governance decision
    const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
    await registry.connect(ggcMultisig).anchorGovernanceRecord(
      recordHash,
      7000,
      "QmTest123"
    );

    // 4. Execute decision
    const recordId = await registry.recordIds(0);
    await registry.connect(ggcMultisig).executeGovernanceRecord(recordId);

    // 5. Verify effectiveness
    const effectiveness = await registry.getGovernanceEffectiveness();
    expect(effectiveness).to.equal(10000); // 100%

    console.log("✓ Full workflow completed successfully");
  });
});
```

## Monitoring and Maintenance

### Dashboard Integration

Create a monitoring dashboard:

```javascript
// scripts/dashboard-data.js
async function generateDashboardData() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    process.env.GOVERNANCE_REGISTRY_ADDRESS
  );

  const config = await registry.getGovernanceConfig();
  const latest = await registry.latestMetrics();
  const [isSustainable, failures] = await registry.checkSustainabilityCompliance();

  return {
    config: {
      quorum: config.quorum.toString(),
      treTarget: config.treTarget.toString(),
      pvMax: config.pvMax.toString(),
      isfMin: config.isfMin.toString()
    },
    metrics: {
      treRate: latest.treRate.toString(),
      planetaryViolence: latest.planetaryViolence.toString(),
      scarcityFactor: latest.scarcityFactor.toString(),
      timestamp: latest.timestamp.toString()
    },
    status: {
      isSustainable,
      failures: failures
    }
  };
}
```

### Alert System

Set up alerts for threshold violations:

```javascript
// scripts/alert-system.js
async function checkAndAlert() {
  const registry = await ethers.getContractAt(
    "GovernanceMetricsRegistry",
    process.env.GOVERNANCE_REGISTRY_ADDRESS
  );

  const [isSustainable, failures] = await registry.checkSustainabilityCompliance();

  if (!isSustainable) {
    // Send alerts via your preferred method
    await sendEmail({
      to: "ggc@euystacio.example",
      subject: "Sustainability Threshold Violation",
      body: `Failed metrics: ${failures.join(", ")}`
    });

    await sendSlackNotification({
      channel: "#governance-alerts",
      message: `⚠️ Sustainability thresholds violated: ${failures.join(", ")}`
    });
  }
}
```

## Troubleshooting

### Common Issues and Solutions

**Issue**: Cannot connect to network
```bash
# Solution: Check RPC URL and network connectivity
npx hardhat run scripts/check-network.js --network mumbai
```

**Issue**: Insufficient funds for deployment
```bash
# Solution: Fund deployer wallet with MATIC
# Mumbai faucet: https://faucet.polygon.technology/
```

**Issue**: Contract verification fails
```bash
# Solution: Ensure correct compiler version and constructor args
npx hardhat verify --network polygon \
  --contract contracts/GovernanceMetricsRegistry.sol:GovernanceMetricsRegistry \
  <ADDRESS> <GGC_MULTISIG>
```

**Issue**: Transaction reverts with "Only GGC multisig authorized"
```bash
# Solution: Ensure you're calling from the correct GGC multisig address
# Check current multisig:
npx hardhat run scripts/check-multisig.js --network polygon
```

## Best Practices

### Security

1. **Never commit private keys** - Use `.env` files (excluded from git)
2. **Use hardware wallets** for mainnet deployments
3. **Verify all contracts** on Polygonscan after deployment
4. **Test on Mumbai** before mainnet deployment
5. **Multi-signature control** - Always use 7-of-9 GGC multisig

### Governance

1. **Regular metrics recording** - Daily or weekly snapshots
2. **Document all decisions** - Use IPFS for detailed records
3. **Monitor thresholds** - Set up automated alerts
4. **Review effectiveness** - Monthly governance reviews
5. **Execute anchored records** - Maintain high effectiveness rate (>80%)

### Development

1. **Use version control** - Commit deployment artifacts
2. **Comprehensive testing** - Unit tests + integration tests
3. **Gas optimization** - Monitor gas usage in tests
4. **Code review** - Peer review before deployment
5. **Documentation** - Keep guides up to date

## Support and Resources

- **Documentation**: `/docs/HARDHAT_GOVERNANCE_WORKFLOWS.md`
- **Contract Source**: `/contracts/GovernanceMetricsRegistry.sol`
- **Test Suite**: `/test/GovernanceMetricsRegistry.test.js`
- **Deployment Scripts**: `/scripts/deploy/`
- **Issue Tracker**: GitHub Issues
- **Governance Contact**: governance@euystacio.example

## Next Steps

1. ✅ Complete environment setup
2. ✅ Deploy to testnet
3. ✅ Run integration tests
4. ✅ Set up monitoring
5. ✅ Deploy to mainnet
6. ✅ Configure automated workflows
7. ✅ Integrate with existing contracts

---

**Version**: 1.0.0  
**Framework**: Euystacio / SAIN Protocol  
**Last Updated**: 2026-01-13
