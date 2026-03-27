// SPDX-License-Identifier: MIT
// Deployment script for SyntropicToken on Optimism L2 (or any EVM-compatible network).
// Uses Hardhat + ethers.js.  Run with: npx hardhat run scripts/deploy.js --network optimism

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying SyntropicToken with account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  const SyntropicToken = await ethers.getContractFactory("SyntropicToken");
  const token = await SyntropicToken.deploy();
  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("SyntropicToken deployed to:", address);

  // ── Register initial Mosaic nodes ────────────────────────────────────────────
  // Node IDs must be Fibonacci numbers (1, 2, 3, 5, 8, 13, …).
  // Replace the placeholder IPFS CIDs with real CIDs after pinning mosaic-node-structure.json.
  const SCHUMANN_MILLIHERTZ = 7830; // 7.83 Hz expressed in millihertz

  const nodesToRegister = [
    { id: 1, cid: "", description: "Root node – Urformel seed" },
    { id: 2, cid: "", description: "Secondary seed node" },
    { id: 3, cid: "", description: "First growth node" },
    { id: 5, cid: "", description: "Second growth node" },
  ];

  console.log("\nRegistering initial Mosaic nodes …");
  for (const node of nodesToRegister) {
    if (node.cid) {
      const tx = await token.registerMosaicNode(node.id, node.cid, SCHUMANN_MILLIHERTZ);
      await tx.wait();
      console.log(`  ✓ Node ${node.id} (${node.description}) registered – CID: ${node.cid}`);
    } else {
      console.log(`  ⚠ Node ${node.id} (${node.description}) skipped – no IPFS CID provided yet.`);
    }
  }

  console.log("\nDeployment complete.");
  console.log("──────────────────────────────────────────────────────");
  console.log("SyntropicToken address :", address);
  console.log("PHI constant           :", (await token.PHI()).toString());
  console.log("Total supply           :", (await token.totalSupply()).toString());
  console.log("Fibonacci sequence len :", (await token.fibonacciLength()).toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
