/**
 * Environment Validation Script
 * 
 * Validates all required environment variables before deployment
 * Run this script before deploying to ensure configuration is correct
 * 
 * Usage: node scripts/validate-env.js
 */

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

const optionalVars = [
  "MUMBAI_RPC_URL",
  "GAS_PRICE",
  "GAS_LIMIT"
];

console.log("╔════════════════════════════════════════════════════════════╗");
console.log("║     ULP Deployment - Environment Validation                ║");
console.log("╚════════════════════════════════════════════════════════════╝\n");

let allValid = true;

console.log("Required Variables:");
console.log("─".repeat(60));

requiredVars.forEach(varName => {
  const value = process.env[varName];
  if (!value) {
    console.log(`❌ ${varName.padEnd(25)} : NOT SET`);
    allValid = false;
  } else if (varName.includes("ADDRESS")) {
    try {
      const checksummed = ethers.utils.getAddress(value);
      if (checksummed === ethers.constants.AddressZero) {
        console.log(`❌ ${varName.padEnd(25)} : ZERO ADDRESS`);
        allValid = false;
      } else {
        console.log(`✅ ${varName.padEnd(25)} : ${checksummed}`);
      }
    } catch (e) {
      console.log(`❌ ${varName.padEnd(25)} : INVALID ADDRESS`);
      allValid = false;
    }
  } else if (varName === "DEPLOYER_PRIVATE_KEY") {
    if (value.length < 64) {
      console.log(`❌ ${varName.padEnd(25)} : INVALID (too short)`);
      allValid = false;
    } else {
      console.log(`✅ ${varName.padEnd(25)} : Set (${value.substring(0, 6)}...)`);
    }
  } else if (varName === "POLYGON_RPC_URL") {
    if (!value.startsWith("http")) {
      console.log(`❌ ${varName.padEnd(25)} : INVALID (must start with http)`);
      allValid = false;
    } else {
      console.log(`✅ ${varName.padEnd(25)} : ${value.substring(0, 40)}...`);
    }
  } else {
    console.log(`✅ ${varName.padEnd(25)} : Set`);
  }
});

console.log("\n" + "─".repeat(60));
console.log("Optional Variables:");
console.log("─".repeat(60));

optionalVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    console.log(`ℹ️  ${varName.padEnd(25)} : ${value}`);
  } else {
    console.log(`⊘  ${varName.padEnd(25)} : Not set (using defaults)`);
  }
});

console.log("\n" + "═".repeat(60));

if (allValid) {
  console.log("✅ All required environment variables are valid!");
  console.log("\nYou can proceed with deployment:");
  console.log("  - Testnet: npm run deploy:testnet");
  console.log("  - Mainnet: npm run deploy:mainnet");
  console.log("═".repeat(60));
  process.exit(0);
} else {
  console.log("❌ Some environment variables are missing or invalid!");
  console.log("\nPlease fix the issues above before deployment.");
  console.log("See .env.example for reference configuration.");
  console.log("═".repeat(60));
  process.exit(1);
}
