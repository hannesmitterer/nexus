/**
 * Universal Liquidity Pool (ULP) Deployment Script
 * 
 * This script deploys the ULP contract to Polygon network (mainnet or testnet)
 * with proper parameter validation and post-deployment verification.
 * 
 * Usage:
 *   - Testnet: npx hardhat run scripts/deploy.js --network mumbai
 *   - Mainnet: npx hardhat run scripts/deploy.js --network polygon
 * 
 * Prerequisites:
 *   - Configure .env file with required addresses and keys
 *   - Ensure deployer wallet has sufficient MATIC for gas
 *   - Verify all contract addresses are correct for target network
 */

const hre = require("hardhat");
const { ethers } = require("hardhat");

// Color codes for console output
const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function logSection(title) {
  log(`\n${"=".repeat(60)}`, colors.bright);
  log(title, colors.bright + colors.cyan);
  log("=".repeat(60), colors.bright);
}

function logSuccess(message) {
  log(`✓ ${message}`, colors.green);
}

function logWarning(message) {
  log(`⚠ ${message}`, colors.yellow);
}

function logError(message) {
  log(`✗ ${message}`, colors.red);
}

function logInfo(message) {
  log(`ℹ ${message}`, colors.blue);
}

/**
 * Validate deployment parameters
 */
function validateParameters(sainToken, stablecoin, ggcMultisig) {
  logSection("Parameter Validation");
  
  const errors = [];
  
  // Validate addresses are not zero
  if (sainToken === ethers.constants.AddressZero) {
    errors.push("SAIN Token address cannot be zero address");
  }
  if (stablecoin === ethers.constants.AddressZero) {
    errors.push("Stablecoin address cannot be zero address");
  }
  if (ggcMultisig === ethers.constants.AddressZero) {
    errors.push("GGC Multisig address cannot be zero address");
  }
  
  // Validate addresses are valid checksummed addresses
  try {
    ethers.utils.getAddress(sainToken);
    logSuccess(`SAIN Token address: ${sainToken}`);
  } catch (e) {
    errors.push(`Invalid SAIN Token address: ${sainToken}`);
  }
  
  try {
    ethers.utils.getAddress(stablecoin);
    logSuccess(`Stablecoin address: ${stablecoin}`);
  } catch (e) {
    errors.push(`Invalid Stablecoin address: ${stablecoin}`);
  }
  
  try {
    ethers.utils.getAddress(ggcMultisig);
    logSuccess(`GGC Multisig address: ${ggcMultisig}`);
  } catch (e) {
    errors.push(`Invalid GGC Multisig address: ${ggcMultisig}`);
  }
  
  // Return validation result
  if (errors.length > 0) {
    logError("Validation failed with errors:");
    errors.forEach((error) => logError(`  - ${error}`));
    return false;
  }
  
  logSuccess("All parameters validated successfully");
  return true;
}

/**
 * Display network information
 */
async function displayNetworkInfo() {
  logSection("Network Information");
  
  const network = await ethers.provider.getNetwork();
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  
  logInfo(`Network: ${network.name} (Chain ID: ${network.chainId})`);
  logInfo(`Deployer: ${deployer.address}`);
  logInfo(`Balance: ${ethers.utils.formatEther(balance)} MATIC`);
  
  // Check if deployer has sufficient balance
  const minimumBalance = ethers.utils.parseEther("0.1"); // 0.1 MATIC minimum
  if (balance.lt(minimumBalance)) {
    logWarning(`Low balance! Consider adding more MATIC for gas fees.`);
  }
  
  return { network, deployer, balance };
}

/**
 * Deploy ULP contract
 */
async function deployULP(sainToken, stablecoin, ggcMultisig, deployer) {
  logSection("Contract Deployment");
  
  logInfo("Compiling contracts...");
  const UniversalLiquidityPool = await ethers.getContractFactory("UniversalLiquidityPool");
  
  logInfo("Deploying Universal Liquidity Pool...");
  logInfo(`  - SAIN Token: ${sainToken}`);
  logInfo(`  - Stablecoin: ${stablecoin}`);
  logInfo(`  - GGC Multisig: ${ggcMultisig}`);
  
  const ulp = await UniversalLiquidityPool.deploy(sainToken, stablecoin, ggcMultisig);
  
  logInfo("Waiting for deployment transaction to be mined...");
  await ulp.deployed();
  
  logSuccess(`ULP deployed to: ${ulp.address}`);
  logInfo(`Deployment transaction hash: ${ulp.deployTransaction.hash}`);
  
  return ulp;
}

/**
 * Verify deployed contract state
 */
async function verifyDeployment(ulp, expectedSain, expectedStable, expectedMultisig) {
  logSection("Post-Deployment Verification");
  
  logInfo("Verifying contract state variables...");
  
  const sainToken = await ulp.sainToken();
  const stablecoin = await ulp.stablecoin();
  const ggcMultisig = await ulp.ggcMultisig();
  const stabilizationFee = await ulp.stabilizationFee();
  const trePledgeRate = await ulp.trePledgeRate();
  const minPriceFloor = await ulp.MIN_PRICE_FLOOR();
  const requiredConfirmations = await ulp.REQUIRED_CONFIRMATIONS();
  const totalSigners = await ulp.TOTAL_SIGNERS();
  
  let allChecksPass = true;
  
  // Verify SAIN token address
  if (sainToken === expectedSain) {
    logSuccess(`SAIN Token: ${sainToken}`);
  } else {
    logError(`SAIN Token mismatch! Expected: ${expectedSain}, Got: ${sainToken}`);
    allChecksPass = false;
  }
  
  // Verify stablecoin address
  if (stablecoin === expectedStable) {
    logSuccess(`Stablecoin: ${stablecoin}`);
  } else {
    logError(`Stablecoin mismatch! Expected: ${expectedStable}, Got: ${stablecoin}`);
    allChecksPass = false;
  }
  
  // Verify GGC Multisig address
  if (ggcMultisig === expectedMultisig) {
    logSuccess(`GGC Multisig: ${ggcMultisig}`);
  } else {
    logError(`GGC Multisig mismatch! Expected: ${expectedMultisig}, Got: ${ggcMultisig}`);
    allChecksPass = false;
  }
  
  // Verify default parameters
  logSuccess(`Stabilization Fee: ${stabilizationFee} basis points (${stabilizationFee / 100}%)`);
  logSuccess(`TRE Pledge Rate: ${trePledgeRate} basis points (${trePledgeRate / 100}%)`);
  logSuccess(`MIN_PRICE_FLOOR: ${ethers.utils.formatEther(minPriceFloor)} stablecoin`);
  logSuccess(`Required Confirmations: ${requiredConfirmations} of ${totalSigners}`);
  
  // Test view functions
  logInfo("\nTesting view functions...");
  
  const [sain, stable] = await ulp.getUlpPair();
  logSuccess(`getUlpPair(): [${sain}, ${stable}]`);
  
  const [stabFee, trePledge, minFloor, currentPrice] = await ulp.getPoolParameters();
  logSuccess(`getPoolParameters(): Fee=${stabFee}, TRE=${trePledge}, Floor=${ethers.utils.formatEther(minFloor)}, Price=${ethers.utils.formatEther(currentPrice)}`);
  
  const [sainLiq, stableLiq, treFunds] = await ulp.getPoolLiquidity();
  logSuccess(`getPoolLiquidity(): SAIN=${sainLiq}, Stable=${stableLiq}, TRE=${treFunds}`);
  
  const [multisig, reqConf, totalSign] = await ulp.getGovernanceConfig();
  logSuccess(`getGovernanceConfig(): Multisig=${multisig}, Required=${reqConf}, Total=${totalSign}`);
  
  return allChecksPass;
}

/**
 * Generate deployment summary
 */
function generateDeploymentSummary(ulp, network, deployer) {
  logSection("Deployment Summary");
  
  const networkName = network.name === "matic" ? "Polygon Mainnet" : network.name;
  const explorerUrl = network.chainId === 137 
    ? `https://polygonscan.com/address/${ulp.address}`
    : network.chainId === 80001
    ? `https://mumbai.polygonscan.com/address/${ulp.address}`
    : "N/A";
  
  log("\n" + "─".repeat(60));
  log(`Network: ${networkName} (Chain ID: ${network.chainId})`);
  log(`Deployer: ${deployer.address}`);
  log(`ULP Contract: ${ulp.address}`);
  log(`Transaction: ${ulp.deployTransaction.hash}`);
  if (explorerUrl !== "N/A") {
    log(`Explorer: ${explorerUrl}`);
  }
  log("─".repeat(60) + "\n");
  
  logInfo("Next Steps:");
  log("  1. Save the contract address for future reference");
  log("  2. Verify the contract on Polygonscan:");
  log(`     npx hardhat verify --network ${network.name} ${ulp.address} <SAIN_TOKEN> <STABLECOIN> <GGC_MULTISIG>`);
  log("  3. Update ULP_DEPLOYMENT_GUIDE.md with deployment addresses");
  log("  4. Test contract functions from GGC Multisig wallet");
  log("  5. Set up monitoring for contract events and state");
  
  logWarning("\nIMPORTANT: Store this deployment information securely!");
}

/**
 * Main deployment function
 */
async function main() {
  try {
    logSection("Universal Liquidity Pool (ULP) Deployment");
    
    // Load environment variables
    const sainToken = process.env.SAIN_TOKEN_ADDRESS;
    const stablecoin = process.env.STABLECOIN_ADDRESS;
    const ggcMultisig = process.env.GGC_MULTISIG_ADDRESS;
    
    // Check if environment variables are set
    if (!sainToken || !stablecoin || !ggcMultisig) {
      logError("Missing required environment variables!");
      logError("Please ensure the following are set in your .env file:");
      if (!sainToken) logError("  - SAIN_TOKEN_ADDRESS");
      if (!stablecoin) logError("  - STABLECOIN_ADDRESS");
      if (!ggcMultisig) logError("  - GGC_MULTISIG_ADDRESS");
      logInfo("\nSee .env.example for configuration template");
      process.exit(1);
    }
    
    // Validate parameters
    if (!validateParameters(sainToken, stablecoin, ggcMultisig)) {
      logError("Deployment aborted due to parameter validation errors");
      process.exit(1);
    }
    
    // Display network info
    const { network, deployer, balance } = await displayNetworkInfo();
    
    // Confirm deployment (for mainnet)
    if (network.chainId === 137) {
      logWarning("\n⚠️  WARNING: You are deploying to POLYGON MAINNET! ⚠️");
      logWarning("Please ensure all parameters are correct.");
      logWarning("This will cost real MATIC for gas fees.\n");
      
      // In a production script, you might want to add a confirmation prompt here
      // For automated deployments, remove this section
    }
    
    // Deploy contract
    const ulp = await deployULP(sainToken, stablecoin, ggcMultisig, deployer);
    
    // Wait for a few block confirmations
    logInfo("\nWaiting for block confirmations...");
    await ulp.deployTransaction.wait(5);
    logSuccess("Transaction confirmed!");
    
    // Verify deployment
    const verificationPassed = await verifyDeployment(
      ulp,
      sainToken,
      stablecoin,
      ggcMultisig
    );
    
    if (!verificationPassed) {
      logError("\n⚠️  Deployment verification found issues!");
      logWarning("Please review the errors above before proceeding.");
    } else {
      logSuccess("\n✓ All deployment verifications passed!");
    }
    
    // Generate summary
    generateDeploymentSummary(ulp, network, deployer);
    
    logSuccess("\n🎉 Deployment completed successfully! 🎉\n");
    
  } catch (error) {
    logError("\n❌ Deployment failed!");
    logError(`Error: ${error.message}`);
    
    if (error.stack) {
      logInfo("\nStack trace:");
      console.error(error.stack);
    }
    
    process.exit(1);
  }
}

// Execute deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
