// Deploy script for Governance Metrics Registry
// Uses hardhat-deploy plugin for deterministic deployments

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy, log } = deployments;
  const { deployer, ggcMultisig } = await getNamedAccounts();

  log("=========================================");
  log("Deploying GovernanceMetricsRegistry...");
  log("Network:", network.name);
  log("Deployer:", deployer);
  log("GGC Multisig:", ggcMultisig);
  log("=========================================");

  // Deploy GovernanceMetricsRegistry
  const governanceRegistry = await deploy("GovernanceMetricsRegistry", {
    from: deployer,
    args: [ggcMultisig],
    log: true,
    waitConfirmations: network.name === "hardhat" ? 1 : 6,
  });

  log("=========================================");
  log(`GovernanceMetricsRegistry deployed at: ${governanceRegistry.address}`);
  log(`Deployment transaction: ${governanceRegistry.transactionHash}`);
  log("=========================================");

  // Verify configuration
  if (governanceRegistry.newlyDeployed) {
    const registryContract = await ethers.getContractAt(
      "GovernanceMetricsRegistry",
      governanceRegistry.address
    );

    log("\nVerifying deployment configuration...");
    const config = await registryContract.getGovernanceConfig();
    log("GGC Multisig:", config.multisig);
    log("Quorum Threshold:", config.quorum.toString(), "bps");
    log("TRE Target:", config.treTarget.toString(), "bps");
    log("Max PV:", config.pvMax.toString(), "bps");
    log("Min ISF:", config.isfMin.toString());

    // Record deployment in governance record
    const recordHash = ethers.keccak256(
      ethers.toUtf8Bytes(`GovernanceMetricsRegistry-Deployment-${network.name}-${Date.now()}`)
    );
    
    log("\nDeployment record hash:", recordHash);
    log("Store this hash for governance audit trail");
  }

  return true;
};

module.exports.tags = ["GovernanceMetricsRegistry", "governance"];
module.exports.dependencies = [];
