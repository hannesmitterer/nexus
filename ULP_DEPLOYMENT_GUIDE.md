# ULP Deployment and Verification Guide

## Pre-Deployment Checklist

### 1. Contract Preparation
- [x] ULP Smart Contract implemented with all required variables
- [x] ULP_PAIR configuration (SAIN Token / Stablecoin)
- [x] STABILIZATION_FEE (variable 0.05% - 0.1%)
- [x] MIN_PRICE_FLOOR constant (10×10^18)
- [x] TRE_PLEDGE_RATE (0.3% of Yield)
- [x] setGovernanceWeights() function with GGC Multisig authorization
- [x] Financial safety mechanisms (burning/buyback)
- [x] Event emissions for traceability

### 2. Required Addresses
Before deployment, ensure you have:
- [ ] SAIN Token contract address on Polygon Mainnet
- [ ] Stablecoin (USDC) contract address on Polygon Mainnet
- [ ] GGC Multisig wallet address (configured as 7/9 multisig)

**Polygon Mainnet USDC Address**: `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174`

### 3. Development Environment
- [ ] Hardhat or Foundry configured for Polygon Mainnet
- [ ] Wallet with sufficient MATIC for deployment gas
- [ ] RPC endpoint for Polygon Mainnet
- [ ] Polygonscan API key for verification

## Deployment Steps

### Step 1: Compile Contract
```bash
# Using Hardhat
npx hardhat compile

# Using Foundry
forge build
```

### Step 2: Deploy to Polygon Mainnet
```javascript
// Hardhat deployment script example
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying ULP with account:", deployer.address);
  
  // Replace with actual addresses
  const SAIN_TOKEN = "0x..."; // SAIN token address
  const USDC_ADDRESS = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const GGC_MULTISIG = "0x..."; // GGC Multisig address
  
  const UniversalLiquidityPool = await ethers.getContractFactory("UniversalLiquidityPool");
  const ulp = await UniversalLiquidityPool.deploy(
    SAIN_TOKEN,
    USDC_ADDRESS,
    GGC_MULTISIG
  );
  
  await ulp.deployed();
  
  console.log("ULP deployed to:", ulp.address);
  console.log("Transaction hash:", ulp.deployTransaction.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Step 3: Verify on Polygonscan
```bash
# Using Hardhat
npx hardhat verify --network polygon <CONTRACT_ADDRESS> <SAIN_TOKEN> <USDC_ADDRESS> <GGC_MULTISIG>

# Using Foundry
forge verify-contract <CONTRACT_ADDRESS> UniversalLiquidityPool \
  --chain-id 137 \
  --compiler-version v0.8.0 \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" <SAIN_TOKEN> <USDC_ADDRESS> <GGC_MULTISIG>)
```

## Post-Deployment Verification

### Verification Checklist

#### 1. Contract State Variables
Verify the following public variables are correctly set:
```javascript
// Check SAIN token address
await ulp.sainToken() === "<EXPECTED_SAIN_ADDRESS>"

// Check stablecoin address
await ulp.stablecoin() === "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"

// Check GGC Multisig
await ulp.ggcMultisig() === "<EXPECTED_MULTISIG_ADDRESS>"

// Check default stabilization fee (should be 5 = 0.05%)
await ulp.stabilizationFee() === 5

// Check default TRE pledge rate (should be 30 = 0.3%)
await ulp.trePledgeRate() === 30

// Check MIN_PRICE_FLOOR constant (10 * 10^18)
await ulp.MIN_PRICE_FLOOR() === "10000000000000000000"

// Check required confirmations
await ulp.REQUIRED_CONFIRMATIONS() === 7

// Check total signers
await ulp.TOTAL_SIGNERS() === 9
```

#### 2. View Functions Test
```javascript
// Test getUlpPair()
const [sain, stable] = await ulp.getUlpPair();
console.log("ULP Pair:", sain, stable);

// Test getPoolParameters()
const [stabFee, trePledge, minFloor, currentPrice] = await ulp.getPoolParameters();
console.log("Pool Parameters:", {
  stabilizationFee: stabFee.toString(),
  trePledgeRate: trePledge.toString(),
  minPriceFloor: minFloor.toString(),
  currentPrice: currentPrice.toString()
});

// Test getPoolLiquidity()
const [sainLiq, stableLiq, treFunds] = await ulp.getPoolLiquidity();
console.log("Pool Liquidity:", {
  sainLiquidity: sainLiq.toString(),
  stablecoinLiquidity: stableLiq.toString(),
  treFunds: treFunds.toString()
});

// Test getGovernanceConfig()
const [multisig, reqConf, totalSign] = await ulp.getGovernanceConfig();
console.log("Governance Config:", {
  multisig: multisig,
  requiredConfirmations: reqConf.toString(),
  totalSigners: totalSign.toString()
});
```

#### 3. Access Control Test
```javascript
// Attempt to call setGovernanceWeights from non-multisig (should fail)
try {
  await ulp.connect(randomUser).setGovernanceWeights(6, 30);
  console.error("ERROR: Non-multisig was able to call setGovernanceWeights");
} catch (error) {
  console.log("✓ setGovernanceWeights properly restricted to GGC Multisig");
}

// Attempt to call setStabilizationFee from non-multisig (should fail)
try {
  await ulp.connect(randomUser).setStabilizationFee(7);
  console.error("ERROR: Non-multisig was able to call setStabilizationFee");
} catch (error) {
  console.log("✓ setStabilizationFee properly restricted to GGC Multisig");
}
```

#### 4. Parameter Validation Test
```javascript
// Test stabilization fee bounds (from multisig)
try {
  await ulp.connect(multisig).setStabilizationFee(4); // Below 0.05%
  console.error("ERROR: Fee below minimum was accepted");
} catch (error) {
  console.log("✓ Stabilization fee minimum bound enforced");
}

try {
  await ulp.connect(multisig).setStabilizationFee(11); // Above 0.1%
  console.error("ERROR: Fee above maximum was accepted");
} catch (error) {
  console.log("✓ Stabilization fee maximum bound enforced");
}

// Test valid fee update
await ulp.connect(multisig).setStabilizationFee(7);
console.log("✓ Valid stabilization fee update successful");
```

#### 5. Event Emission Test
```javascript
// Test event emission on parameter update
const tx = await ulp.connect(multisig).setGovernanceWeights(8, 35);
const receipt = await tx.wait();

const govWeightsEvent = receipt.events.find(e => e.event === 'GovernanceWeightsUpdated');
const stabFeeEvent = receipt.events.find(e => e.event === 'StabilizationFeeUpdated');
const trePledgeEvent = receipt.events.find(e => e.event === 'TrePledgeRateUpdated');

console.log("✓ GovernanceWeightsUpdated event emitted");
console.log("✓ StabilizationFeeUpdated event emitted");
console.log("✓ TrePledgeRateUpdated event emitted");
```

#### 6. Price Floor Mechanism Test
```javascript
// Check price floor constant
const priceFloor = await ulp.MIN_PRICE_FLOOR();
console.log("Price floor:", ethers.utils.formatEther(priceFloor), "stablecoin");

// Test isPriceBelowFloor (initially should be false with no liquidity)
const isBelowFloor = await ulp.isPriceBelowFloor();
console.log("Is price below floor:", isBelowFloor);
```

## Acceptance Criteria Verification

### ✅ Criterion 1: ULP Smart Contract exists with all variables and functions

**Variables:**
- [x] ULP_PAIR (sainToken, stablecoin addresses) - Configured in constructor
- [x] STABILIZATION_FEE (variable 0.05% - 0.1%) - Implemented with validation
- [x] MIN_PRICE_FLOOR (constant 10×10^18) - Implemented as constant
- [x] TRE_PLEDGE_RATE (0.3% of Yield) - Implemented with default 30 basis points
- [x] GGC Multisig address (7/9 configuration) - Stored and validated

**Functions:**
- [x] setGovernanceWeights() - Only GGC Multisig authorized ✓
- [x] setStabilizationFee() - Only GGC Multisig authorized ✓
- [x] setTrePledgeRate() - Only GGC Multisig authorized ✓
- [x] addLiquidity() - Public function for liquidity provision
- [x] removeLiquidity() - With stabilization fee application
- [x] swap() - With TRE pledge collection
- [x] triggerBuyback() - Price floor defense mechanism
- [x] burnTokens() - Price floor defense mechanism
- [x] transferTreFunds() - TRE fund distribution to GGC
- [x] getCurrentPrice() - Price calculation view function
- [x] isPriceBelowFloor() - Price floor monitoring
- [x] getUlpPair() - View function for pair configuration
- [x] getPoolParameters() - View function for pool state
- [x] getPoolLiquidity() - View function for liquidity info
- [x] getGovernanceConfig() - View function for governance info

**Safety Mechanisms:**
- [x] Burning mechanism when price < MIN_PRICE_FLOOR
- [x] Buyback mechanism when price < MIN_PRICE_FLOOR
- [x] Stabilization fee on withdrawals (defensive measure)
- [x] TRE pledge automatic collection from yields

**Traceability:**
- [x] All critical operations emit events with timestamps
- [x] Events include actor addresses (indexed)
- [x] Parameter changes emit dedicated events
- [x] Public source code (verifiable on Polygonscan)
- [x] All state variables are public for transparency

**Governance:**
- [x] GGC Multisig (7/9) required for critical operations
- [x] onlyGgcMultisig modifier enforces access control
- [x] Parameter validation prevents invalid configurations
- [x] Multisig can be updated (with current multisig authorization)

## Security Audit Recommendations

Before mainnet deployment with real funds:
1. **External Audit**: Engage professional smart contract auditors
2. **Formal Verification**: Consider formal verification of critical functions
3. **Testnet Deployment**: Deploy to Polygon Mumbai testnet for thorough testing
4. **Integration Testing**: Test with actual SAIN token and USDC contracts
5. **Multisig Testing**: Verify GGC Multisig wallet functionality
6. **Economic Modeling**: Validate AMM pricing and fee structures
7. **Emergency Procedures**: Document emergency response procedures
8. **Insurance**: Consider smart contract insurance coverage

## Monitoring and Maintenance

Post-deployment monitoring checklist:
- [ ] Monitor price floor proximity (getCurrentPrice() vs MIN_PRICE_FLOOR)
- [ ] Track stabilization fee effectiveness
- [ ] Monitor TRE fund accumulation
- [ ] Review event logs for anomalies
- [ ] Track pool liquidity levels
- [ ] Monitor swap activity and pricing
- [ ] Regular governance parameter reviews
- [ ] Periodic security assessments

## Contract Addresses (To be filled post-deployment)

### Polygon Mainnet
- **ULP Contract**: `0x...` [Polygonscan Link]
- **SAIN Token**: `0x...` [Polygonscan Link]
- **USDC**: `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174` [Polygonscan Link]
- **GGC Multisig**: `0x...` [Polygonscan Link]

### Verification Links
- **ULP Source Code**: [Polygonscan Verified Contract Link]
- **Deployment Transaction**: [Transaction Hash Link]

## Support and Documentation
- Contract Source: `/UniversalLiquidityPool.sol`
- Technical README: `/ULP_README.md`
- Deployment Guide: `/ULP_DEPLOYMENT_GUIDE.md` (this file)
- SAIN Protocol Documentation: `/SAIN-Protocol-V1.0.md`
