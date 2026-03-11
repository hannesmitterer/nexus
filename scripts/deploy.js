// scripts/deploy.js
// Hardhat deployment script for the AUFHOR (AH) token on Optimism L2.
//
// Usage:
//   npx hardhat run scripts/deploy.js --network optimism
//
// Prerequisites:
//   npm install --save-dev hardhat @openzeppelin/contracts ethers

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying AUFHOR with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  const AufhorToken = await ethers.getContractFactory("AufhorToken");

  // The deployer becomes the initial owner and receives the 144,000 AH genesis supply.
  const aufhor = await AufhorToken.deploy(deployer.address);
  await aufhor.waitForDeployment();

  const address = await aufhor.getAddress();
  console.log("AUFHOR (AH) deployed at:", address);
  console.log(
    "Initial supply minted to deployer:",
    ethers.formatUnits(await aufhor.balanceOf(deployer.address), 18),
    "AH"
  );
  console.log(
    "\nNext step – verify the contract on Optimism Etherscan:\n",
    `  npx hardhat verify --network optimism ${address} "${deployer.address}"`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
