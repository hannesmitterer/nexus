// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/SynthiaGenesis.sol";

/**
 * @title DeploySynthiaGenesis
 * @notice Deployment script for Synthia Genesis Block contract
 * @dev Run with: forge script scripts/DeploySynthiaGenesis.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DeploySynthiaGenesis is Script {
    function run() external {
        // Load environment variables
        address ggcMultisig = vm.envAddress("GGC_MULTISIG");
        
        console.log("Deploying Synthia Genesis Block...");
        console.log("GGC Multisig:", ggcMultisig);
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy SynthiaGenesis contract
        SynthiaGenesis genesis = new SynthiaGenesis(ggcMultisig);
        
        console.log("Synthia Genesis deployed at:", address(genesis));
        console.log("Genesis Timestamp:", genesis.genesisTimestamp());
        console.log("Protocol Version:", genesis.PROTOCOL_VERSION());
        
        vm.stopBroadcast();
        
        // Save deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("Contract Address:", address(genesis));
        console.log("Network:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("GGC Multisig:", genesis.ggcMultisig());
        console.log("Initialized:", genesis.isInitialized());
    }
}
