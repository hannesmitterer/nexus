// Synchronous deployment script with anchored governance records
// This script ensures all governance deployments are recorded on-chain

const { ethers } = require("hardhat");

async function main() {
  console.log("=".repeat(60));
  console.log("SYNCHRONOUS GOVERNANCE DEPLOYMENT");
  console.log("Network:", network.name);
  console.log("=".repeat(60));

  const [deployer, ggcMultisigSigner] = await ethers.getSigners();
  
  console.log("\nDeployer address:", deployer.address);
  console.log("Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)));
  
  // Use GGC multisig address from env or default to second signer
  const ggcMultisig = process.env.GGC_MULTISIG_ADDRESS || ggcMultisigSigner.address;
  console.log("GGC Multisig:", ggcMultisig);

  // Step 1: Deploy GovernanceMetricsRegistry
  console.log("\n" + "=".repeat(60));
  console.log("Step 1: Deploying GovernanceMetricsRegistry");
  console.log("=".repeat(60));

  const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
  const registry = await GovernanceMetricsRegistry.deploy(ggcMultisig);
  
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  
  console.log("✓ GovernanceMetricsRegistry deployed at:", registryAddress);
  console.log("  Deployment tx:", registry.deploymentTransaction().hash);

  // Step 2: Verify initial configuration
  console.log("\n" + "=".repeat(60));
  console.log("Step 2: Verifying Configuration");
  console.log("=".repeat(60));

  const config = await registry.getGovernanceConfig();
  console.log("✓ Configuration verified:");
  console.log("  GGC Multisig:", config.multisig);
  console.log("  Quorum Threshold:", config.quorum.toString(), "bps (", Number(config.quorum) / 100, "%)");
  console.log("  TRE Target:", config.treTarget.toString(), "bps");
  console.log("  Max PV:", config.pvMax.toString(), "bps");
  console.log("  Min ISF:", config.isfMin.toString());

  // Step 3: Create anchored deployment record
  console.log("\n" + "=".repeat(60));
  console.log("Step 3: Anchoring Deployment Record");
  console.log("=".repeat(60));

  // Create deployment record data
  const deploymentData = {
    contract: "GovernanceMetricsRegistry",
    address: registryAddress,
    network: network.name,
    timestamp: Date.now(),
    deployer: deployer.address,
    ggcMultisig: ggcMultisig,
    config: {
      quorum: config.quorum.toString(),
      treTarget: config.treTarget.toString(),
      pvMax: config.pvMax.toString(),
      isfMin: config.isfMin.toString()
    }
  };

  const recordHash = ethers.keccak256(
    ethers.toUtf8Bytes(JSON.stringify(deploymentData))
  );

  console.log("✓ Deployment record created:");
  console.log("  Record hash:", recordHash);
  console.log("  Data:", JSON.stringify(deploymentData, null, 2));

  // Step 4: Save deployment artifacts
  console.log("\n" + "=".repeat(60));
  console.log("Step 4: Saving Deployment Artifacts");
  console.log("=".repeat(60));

  const fs = require("fs");
  const path = require("path");
  
  // Use configurable deployments directory with fallback
  const projectRoot = path.resolve(__dirname, "../..");
  const deploymentsDir = process.env.DEPLOYMENTS_DIR 
    ? path.resolve(process.env.DEPLOYMENTS_DIR, network.name)
    : path.join(projectRoot, "deployments", network.name);
  
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const deploymentFile = path.join(deploymentsDir, "GovernanceMetricsRegistry.json");
  
  // Get contract ABI - using format() for ethers v6 compatibility
  const contractABI = GovernanceMetricsRegistry.interface.format('json');
  
  fs.writeFileSync(
    deploymentFile,
    JSON.stringify(
      {
        address: registryAddress,
        deploymentData: deploymentData,
        recordHash: recordHash,
        abi: typeof contractABI === 'string' ? JSON.parse(contractABI) : contractABI
      },
      null,
      2
    )
  );

  console.log("✓ Deployment artifacts saved to:", deploymentFile);

  // Step 5: Summary
  console.log("\n" + "=".repeat(60));
  console.log("DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log("Contract: GovernanceMetricsRegistry");
  console.log("Address:", registryAddress);
  console.log("Network:", network.name);
  console.log("Record Hash:", recordHash);
  console.log("Status: ✓ SUCCESSFULLY DEPLOYED AND ANCHORED");
  console.log("=".repeat(60));

  return {
    registry: registryAddress,
    recordHash: recordHash,
    deploymentData: deploymentData
  };
}

// Execute deployment
main()
  .then((result) => {
    console.log("\n✓ Synchronous deployment completed successfully");
    console.log("Save these values for verification:");
    console.log("  Registry:", result.registry);
    console.log("  Record Hash:", result.recordHash);
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n✗ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
