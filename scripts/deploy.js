// Hardhat deployment script for SyntropicToken on Optimism L2.
//
// Usage:
//   npx hardhat run scripts/deploy.js --network optimism
//
// Required environment variables (set in .env or shell):
//   PRIVATE_KEY   – deployer private key (without 0x prefix)
//   OPTIMISM_RPC  – RPC URL for Optimism (mainnet or Sepolia testnet)
//
// Network configuration (hardhat.config.js excerpt):
//   networks: {
//     optimism: {
//       url: process.env.OPTIMISM_RPC || "https://mainnet.optimism.io",
//       accounts: [`0x${process.env.PRIVATE_KEY}`],
//       chainId: 10,
//     },
//     "optimism-sepolia": {
//       url: process.env.OPTIMISM_SEPOLIA_RPC || "https://sepolia.optimism.io",
//       accounts: [`0x${process.env.PRIVATE_KEY}`],
//       chainId: 11155420,
//     },
//   }

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying SyntropicToken with account:", deployer.address);
  console.log(
    "Account balance:",
    ethers.formatEther(await ethers.provider.getBalance(deployer.address)),
    "ETH"
  );

  const SyntropicToken = await ethers.getContractFactory("SyntropicToken");

  // The constructor requires an initial owner; we use the deployer address.
  const token = await SyntropicToken.deploy(deployer.address);
  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("SyntropicToken deployed to:", address);
  console.log(
    "Initial supply (STOK):",
    ethers.formatUnits(await token.totalSupply(), await token.decimals())
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
