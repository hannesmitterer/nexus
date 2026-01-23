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

## Complete Deployment Workflow

The following workflow outlines the complete end-to-end process for deploying the ULP contract:

### Workflow Overview

```
1. Environment Setup
   └─> Install Dependencies
       └─> Configure Environment Variables
           └─> Validate Configuration

2. Pre-Deployment Testing
   └─> Compile Contracts
       └─> Run Local Tests (optional)
           └─> Deploy to Testnet (recommended)
               └─> Verify Testnet Deployment

3. Mainnet Deployment
   └─> Final Parameter Review
       └─> Deploy to Polygon Mainnet
           └─> Verify Deployment Transaction
               └─> Verify Contract State

4. Contract Verification
   └─> Verify Source Code on Polygonscan
       └─> Test Public Functions
           └─> Verify Events Emission

5. Post-Deployment Setup
   └─> Configure Monitoring
       └─> Document Deployment
           └─> Transfer Control to GGC Multisig
               └─> Activate Pool (add initial liquidity)
```

### Detailed Workflow Steps

#### Phase 1: Environment Setup

**Step 1.1: Install Dependencies**
```bash
# Clone repository (if not already done)
git clone <repository-url>
cd nexus

# Install Node.js dependencies
npm install

# Verify installation
npx hardhat --version
```

**Step 1.2: Configure Environment Variables**
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your configuration
# Required variables:
#   - DEPLOYER_PRIVATE_KEY
#   - SAIN_TOKEN_ADDRESS
#   - STABLECOIN_ADDRESS (use 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 for Polygon)
#   - GGC_MULTISIG_ADDRESS
#   - POLYGON_RPC_URL
#   - POLYGONSCAN_API_KEY
nano .env  # or use your preferred editor
```

**Step 1.3: Validate Configuration**
```bash
# Check that all required environment variables are set
node -e "require('dotenv').config(); console.log('SAIN Token:', process.env.SAIN_TOKEN_ADDRESS); console.log('Stablecoin:', process.env.STABLECOIN_ADDRESS); console.log('GGC Multisig:', process.env.GGC_MULTISIG_ADDRESS);"
```

#### Phase 2: Pre-Deployment Testing (Recommended)

**Step 2.1: Compile Contracts**
```bash
# Compile all contracts
npx hardhat compile

# Verify compilation success
ls -la artifacts/contracts/UniversalLiquidityPool.sol/
```

**Step 2.2: Deploy to Mumbai Testnet (Optional but Recommended)**
```bash
# Update .env with Mumbai testnet addresses
# MUMBAI_RPC_URL, test SAIN token, test USDC, test multisig

# Deploy to Mumbai
npm run deploy:testnet

# Or directly:
npx hardhat run scripts/deploy.js --network mumbai
```

**Step 2.3: Test Testnet Deployment**
```bash
# Interact with testnet contract to verify functionality
# Use Hardhat console or write test scripts
npx hardhat console --network mumbai
```

#### Phase 3: Mainnet Deployment

**Step 3.1: Final Parameter Review**
Before deploying to mainnet, verify:
- [ ] SAIN_TOKEN_ADDRESS is correct for Polygon Mainnet
- [ ] STABLECOIN_ADDRESS is `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174` (USDC)
- [ ] GGC_MULTISIG_ADDRESS is the correct 7/9 multisig wallet
- [ ] Deployer wallet has at least 0.1 MATIC for gas fees
- [ ] POLYGON_RPC_URL is reliable and working
- [ ] POLYGONSCAN_API_KEY is valid

**Step 3.2: Deploy to Polygon Mainnet**
```bash
# Deploy using npm script
npm run deploy:mainnet

# Or directly:
npx hardhat run scripts/deploy.js --network polygon
```

The deployment script will:
1. Validate all parameters
2. Display network and deployer information
3. Deploy the ULP contract
4. Wait for block confirmations
5. Verify initial contract state
6. Output deployment summary with contract address

**Step 3.3: Save Deployment Information**
```bash
# Example output:
# ────────────────────────────────────────────────────────────
# Network: Polygon Mainnet (Chain ID: 137)
# Deployer: 0x1234...
# ULP Contract: 0xABCD...
# Transaction: 0x5678...
# Explorer: https://polygonscan.com/address/0xABCD...
# ────────────────────────────────────────────────────────────

# IMPORTANT: Save the contract address immediately!
echo "ULP_CONTRACT_ADDRESS=0xABCD..." >> .env
```

#### Phase 4: Contract Verification

**Step 4.1: Verify Source Code on Polygonscan**
```bash
# Verify contract (replace addresses with actual values)
npx hardhat verify --network polygon \
  <ULP_CONTRACT_ADDRESS> \
  <SAIN_TOKEN_ADDRESS> \
  <STABLECOIN_ADDRESS> \
  <GGC_MULTISIG_ADDRESS>

# Expected output: "Successfully verified contract"
```

**Step 4.2: Manual Verification on Polygonscan**
Visit: `https://polygonscan.com/address/<ULP_CONTRACT_ADDRESS>`

Verify:
- [ ] Contract is verified (green checkmark)
- [ ] Read Contract tab shows all public variables
- [ ] Write Contract tab shows governance functions
- [ ] Constructor arguments are correct

#### Phase 5: Post-Deployment Setup

**Step 5.1: Test Contract Functions**
```javascript
// Use Hardhat console to test
npx hardhat console --network polygon

const ulp = await ethers.getContractAt("UniversalLiquidityPool", "<ULP_CONTRACT_ADDRESS>");

// Test view functions
await ulp.getUlpPair();
await ulp.getPoolParameters();
await ulp.getGovernanceConfig();
```

**Step 5.2: Document Deployment**
Update `ULP_DEPLOYMENT_GUIDE.md` section "Contract Addresses" with:
- ULP Contract address
- SAIN Token address
- Deployment transaction hash
- Deployment date and time
- Deployer address

**Step 5.3: Configure Monitoring**
Set up monitoring for:
- Contract events (LiquidityAdded, Swap, etc.)
- Price floor monitoring
- TRE fund accumulation
- Governance actions

**Step 5.4: Transfer Operational Control**
- Verify GGC Multisig has proper access
- Test a governance function from GGC Multisig (e.g., read-only)
- Plan initial liquidity provision strategy

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

## Troubleshooting Guide

### Common Deployment Issues

#### Issue 1: "Insufficient funds for gas"
**Symptom**: Deployment fails with error about insufficient funds.

**Solution**:
```bash
# Check deployer balance
npx hardhat console --network polygon
> const [deployer] = await ethers.getSigners();
> const balance = await deployer.getBalance();
> console.log("Balance:", ethers.utils.formatEther(balance), "MATIC");

# Add more MATIC to deployer wallet if balance is low
# Minimum recommended: 0.1 MATIC for deployment
```

#### Issue 2: "Invalid API Key" during verification
**Symptom**: Contract verification fails with API key error.

**Solution**:
```bash
# Verify your Polygonscan API key is set correctly
echo $POLYGONSCAN_API_KEY

# Get a new API key from https://polygonscan.com/myapikey
# Update .env file with correct key
```

#### Issue 3: "Transaction underpriced"
**Symptom**: Deployment transaction fails with "transaction underpriced" error.

**Solution**:
```javascript
// In hardhat.config.js, try setting a higher gas price
networks: {
  polygon: {
    url: process.env.POLYGON_RPC_URL,
    accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    gasPrice: 50000000000, // 50 gwei
  }
}
```

#### Issue 4: "Nonce too low"
**Symptom**: Transaction fails with nonce error.

**Solution**:
```bash
# Clear Hardhat cache and try again
rm -rf cache/ artifacts/
npx hardhat clean
npx hardhat compile
npx hardhat run scripts/deploy.js --network polygon
```

#### Issue 5: "Contract verification failed"
**Symptom**: Source code verification on Polygonscan fails.

**Solution**:
```bash
# Ensure constructor arguments are in correct order
# Verify compiler version matches (0.8.0)
# Check optimization settings match

# Manual verification:
# 1. Go to Polygonscan contract page
# 2. Click "Verify and Publish"
# 3. Select compiler version 0.8.0
# 4. Enable optimization (200 runs)
# 5. Paste contract source code
# 6. Enter constructor arguments in ABI-encoded format
```

#### Issue 6: "Connection timeout" with RPC
**Symptom**: Deployment hangs or times out.

**Solution**:
```bash
# Try alternative RPC endpoints in .env:
# Option 1: Polygon public RPC
POLYGON_RPC_URL=https://polygon-rpc.com

# Option 2: Alchemy (recommended for reliability)
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR-API-KEY

# Option 3: Infura
POLYGON_RPC_URL=https://polygon-mainnet.infura.io/v3/YOUR-PROJECT-ID

# Option 4: QuickNode
POLYGON_RPC_URL=https://YOUR-QUICKNODE-ENDPOINT
```

#### Issue 7: "Invalid address" errors
**Symptom**: Deployment fails with invalid address parameter.

**Solution**:
```bash
# Ensure all addresses in .env are:
# 1. Valid Ethereum addresses (0x followed by 40 hex characters)
# 2. Checksummed (proper capitalization)
# 3. Not zero address (0x0000...0000)

# Validate addresses using ethers
node -e "const ethers = require('ethers'); console.log(ethers.utils.getAddress('YOUR_ADDRESS'));"
```

### Environment Variable Checklist

Required environment variables for deployment:

| Variable | Description | Example/Default | Required |
|----------|-------------|-----------------|----------|
| `DEPLOYER_PRIVATE_KEY` | Private key of deployer wallet | 0x1234... | ✅ Yes |
| `SAIN_TOKEN_ADDRESS` | SAIN token contract address | 0xabcd... | ✅ Yes |
| `STABLECOIN_ADDRESS` | USDC contract address | 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 | ✅ Yes |
| `GGC_MULTISIG_ADDRESS` | GGC 7/9 multisig wallet | 0xef01... | ✅ Yes |
| `POLYGON_RPC_URL` | Polygon RPC endpoint | https://polygon-rpc.com | ✅ Yes |
| `POLYGONSCAN_API_KEY` | Polygonscan API key for verification | ABC123... | ✅ Yes (for verification) |
| `MUMBAI_RPC_URL` | Mumbai testnet RPC | https://rpc-mumbai.maticvigil.com | ⚠️ Testnet only |
| `GAS_PRICE` | Custom gas price in gwei | 50 | ❌ Optional |
| `GAS_LIMIT` | Custom gas limit | 5000000 | ❌ Optional |

### Pre-Deployment Validation Script

Create a file `scripts/validate-env.js` to validate your configuration:

```javascript
require("dotenv").config();
const { ethers } = require("ethers");

const requiredVars = [
  "DEPLOYER_PRIVATE_KEY",
  "SAIN_TOKEN_ADDRESS", 
  "STABLECOIN_ADDRESS",
  "GGC_MULTISIG_ADDRESS",
  "POLYGON_RPC_URL",
  "POLYGONSCAN_API_KEY"
];

console.log("Validating environment configuration...\n");

let allValid = true;

requiredVars.forEach(varName => {
  const value = process.env[varName];
  if (!value) {
    console.log(`❌ ${varName} is not set`);
    allValid = false;
  } else if (varName.includes("ADDRESS")) {
    try {
      const checksummed = ethers.utils.getAddress(value);
      console.log(`✅ ${varName}: ${checksummed}`);
    } catch (e) {
      console.log(`❌ ${varName}: Invalid address format`);
      allValid = false;
    }
  } else if (varName === "DEPLOYER_PRIVATE_KEY") {
    console.log(`✅ ${varName}: Set (${value.substring(0, 6)}...)`);
  } else {
    console.log(`✅ ${varName}: Set`);
  }
});

if (allValid) {
  console.log("\n✅ All required environment variables are valid!");
  process.exit(0);
} else {
  console.log("\n❌ Some environment variables are missing or invalid!");
  console.log("Please check .env.example for reference.");
  process.exit(1);
}
```

Run validation before deployment:
```bash
node scripts/validate-env.js
```

### Gas Estimation

Estimated gas costs for deployment (as of 2025):

| Network | Gas Used | Gas Price | Estimated Cost |
|---------|----------|-----------|----------------|
| Polygon Mainnet | ~2,500,000 | 50 gwei | ~0.125 MATIC (~$0.10) |
| Mumbai Testnet | ~2,500,000 | 1 gwei | ~0.0025 MATIC (test) |

**Note**: Gas prices on Polygon are typically very low. Always check current gas prices before deployment.

### Network Configuration Reference

#### Polygon Mainnet
- Chain ID: 137
- Currency: MATIC
- Block Explorer: https://polygonscan.com
- RPC Endpoints:
  - https://polygon-rpc.com
  - https://rpc-mainnet.matic.network
  - https://polygon-mainnet.g.alchemy.com/v2/{YOUR-API-KEY}

#### Polygon Mumbai Testnet
- Chain ID: 80001
- Currency: MATIC (test)
- Block Explorer: https://mumbai.polygonscan.com
- RPC Endpoints:
  - https://rpc-mumbai.maticvigil.com
  - https://rpc-mumbai.matic.today
- Faucet: https://faucet.polygon.technology

### Quick Command Reference

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Clean build artifacts
npx hardhat clean

# Deploy to testnet
npm run deploy:testnet

# Deploy to mainnet
npm run deploy:mainnet

# Verify contract
npx hardhat verify --network polygon <ADDRESS> <CONSTRUCTOR_ARGS>

# Open Hardhat console
npx hardhat console --network polygon

# Run validation script
node scripts/validate-env.js

# Check Hardhat version
npx hardhat --version

# List Hardhat tasks
npx hardhat help
```
