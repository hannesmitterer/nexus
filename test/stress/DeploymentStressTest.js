const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Synchronous Deployment Stress Test", function () {
  // Increase timeout for stress tests
  this.timeout(300000); // 5 minutes

  let deployer;
  let ggcMultisig;
  let registries = [];

  beforeEach(async function () {
    [deployer, ggcMultisig] = await ethers.getSigners();
  });

  describe("Rapid Sequential Deployments", function () {
    it("Should handle 10 rapid sequential deployments", async function () {
      console.log("\n=== Starting Rapid Deployment Test ===");
      const startTime = Date.now();
      
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      
      for (let i = 0; i < 10; i++) {
        const deployStart = Date.now();
        const registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
        await registry.waitForDeployment();
        const deployTime = Date.now() - deployStart;
        
        registries.push(registry);
        console.log(`  Deployment ${i + 1}: ${await registry.getAddress()} (${deployTime}ms)`);
        
        // Verify each deployment
        const config = await registry.getGovernanceConfig();
        expect(config.multisig).to.equal(ggcMultisig.address);
        expect(config.quorum).to.equal(6700);
      }
      
      const totalTime = Date.now() - startTime;
      console.log(`\n✓ All 10 deployments completed in ${totalTime}ms`);
      console.log(`  Average time per deployment: ${totalTime / 10}ms`);
    });
  });

  describe("Governance Record Anchoring Under Load", function () {
    let registry;

    beforeEach(async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
      await registry.waitForDeployment();
    });

    it("Should anchor 50 governance records sequentially", async function () {
      console.log("\n=== Testing Sequential Record Anchoring ===");
      const startTime = Date.now();
      
      for (let i = 0; i < 50; i++) {
        const recordHash = ethers.keccak256(ethers.toUtf8Bytes(`decision-${i}-${Date.now()}`));
        const quorum = 6700 + (i % 10) * 10; // Vary quorum slightly
        const ipfsCid = `QmStressTest${i}`;
        
        const tx = await registry.connect(ggcMultisig).anchorGovernanceRecord(
          recordHash, 
          quorum, 
          ipfsCid
        );
        await tx.wait();
        
        if ((i + 1) % 10 === 0) {
          console.log(`  Anchored ${i + 1} records...`);
        }
      }
      
      const totalTime = Date.now() - startTime;
      const totalRecords = await registry.totalGovernanceDecisions();
      
      expect(totalRecords).to.equal(50);
      console.log(`\n✓ Anchored 50 records in ${totalTime}ms`);
      console.log(`  Average time per record: ${totalTime / 50}ms`);
    });

    it("Should execute all anchored records efficiently", async function () {
      console.log("\n=== Testing Batch Record Execution ===");
      
      // First, anchor 20 records
      const recordIds = [];
      for (let i = 0; i < 20; i++) {
        const recordHash = ethers.keccak256(ethers.toUtf8Bytes(`decision-${i}`));
        const tx = await registry.connect(ggcMultisig).anchorGovernanceRecord(
          recordHash, 
          7000, 
          `QmTest${i}`
        );
        const receipt = await tx.wait();
        
        const event = receipt.logs.find(log => {
          try {
            const parsed = registry.interface.parseLog(log);
            return parsed.name === "GovernanceRecordAnchored";
          } catch {
            return false;
          }
        });
        
        recordIds.push(registry.interface.parseLog(event).args[0]);
      }
      
      console.log(`  Anchored ${recordIds.length} records for execution test`);
      
      // Now execute all of them
      const startTime = Date.now();
      for (let i = 0; i < recordIds.length; i++) {
        const tx = await registry.connect(ggcMultisig).executeGovernanceRecord(recordIds[i]);
        await tx.wait();
        
        if ((i + 1) % 5 === 0) {
          console.log(`  Executed ${i + 1} records...`);
        }
      }
      
      const totalTime = Date.now() - startTime;
      const executed = await registry.executedGovernanceDecisions();
      
      expect(executed).to.equal(20);
      console.log(`\n✓ Executed 20 records in ${totalTime}ms`);
      console.log(`  Average time per execution: ${totalTime / 20}ms`);
    });
  });

  describe("Metrics Recording Under Load", function () {
    let registry;

    beforeEach(async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
      await registry.waitForDeployment();
    });

    it("Should record 100 metrics snapshots", async function () {
      console.log("\n=== Testing Metrics Recording Under Load ===");
      const startTime = Date.now();
      
      for (let i = 0; i < 100; i++) {
        // Vary metrics to simulate real-world changes
        const treRate = 20 + (i % 30);  // Range: 20-50 bps
        const pv = 300 + (i % 400);     // Range: 300-700 bps
        const isf = 70 + (i % 25);      // Range: 70-95
        
        const tx = await registry.connect(ggcMultisig).recordMetricsSnapshot(
          treRate,
          pv,
          isf
        );
        await tx.wait();
        
        if ((i + 1) % 20 === 0) {
          console.log(`  Recorded ${i + 1} snapshots...`);
        }
      }
      
      const totalTime = Date.now() - startTime;
      const historyLength = await registry.getMetricsHistoryLength();
      
      expect(historyLength).to.equal(100);
      console.log(`\n✓ Recorded 100 metrics snapshots in ${totalTime}ms`);
      console.log(`  Average time per snapshot: ${totalTime / 100}ms`);
    });
  });

  describe("Concurrent Operations Stress Test", function () {
    let registry;

    beforeEach(async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
      await registry.waitForDeployment();
    });

    it("Should handle mixed operations under stress", async function () {
      console.log("\n=== Testing Mixed Operations Under Stress ===");
      const startTime = Date.now();
      
      const operations = [];
      
      // Mix of different operations
      for (let i = 0; i < 30; i++) {
        const opType = i % 3;
        
        if (opType === 0) {
          // Anchor governance record
          const recordHash = ethers.keccak256(ethers.toUtf8Bytes(`mixed-decision-${i}`));
          operations.push(
            registry.connect(ggcMultisig).anchorGovernanceRecord(
              recordHash, 
              7000, 
              `QmMixed${i}`
            ).then(tx => tx.wait())
          );
        } else if (opType === 1) {
          // Record metrics
          operations.push(
            registry.connect(ggcMultisig).recordMetricsSnapshot(
              30 + i,
              400 + i * 5,
              75 + i
            ).then(tx => tx.wait())
          );
        } else {
          // Update configuration
          const newQuorum = 6700 + (i % 10) * 10;
          operations.push(
            registry.connect(ggcMultisig).setQuorumThreshold(newQuorum)
              .then(tx => tx.wait())
          );
        }
        
        if ((i + 1) % 10 === 0) {
          console.log(`  Queued ${i + 1} operations...`);
        }
      }
      
      // Execute all operations
      await Promise.all(operations);
      
      const totalTime = Date.now() - startTime;
      
      const totalRecords = await registry.totalGovernanceDecisions();
      const historyLength = await registry.getMetricsHistoryLength();
      
      console.log(`\n✓ Completed 30 mixed operations in ${totalTime}ms`);
      console.log(`  Records anchored: ${totalRecords}`);
      console.log(`  Metrics recorded: ${historyLength}`);
      console.log(`  Average time per operation: ${totalTime / 30}ms`);
    });
  });

  describe("Data Integrity Under Stress", function () {
    let registry;

    beforeEach(async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
      await registry.waitForDeployment();
    });

    it("Should maintain data integrity after heavy load", async function () {
      console.log("\n=== Testing Data Integrity Under Heavy Load ===");
      
      // Anchor many records
      const testData = [];
      for (let i = 0; i < 25; i++) {
        const recordHash = ethers.keccak256(ethers.toUtf8Bytes(`integrity-test-${i}`));
        const quorum = 7000 + i * 10;
        const ipfsCid = `QmIntegrity${i}`;
        
        testData.push({ recordHash, quorum, ipfsCid });
        
        const tx = await registry.connect(ggcMultisig).anchorGovernanceRecord(
          recordHash, 
          quorum, 
          ipfsCid
        );
        await tx.wait();
      }
      
      console.log(`  Anchored ${testData.length} test records`);
      
      // Verify all records
      let verified = 0;
      for (let i = 0; i < testData.length; i++) {
        const recordId = await registry.recordIds(i);
        const record = await registry.getGovernanceRecord(recordId);
        
        expect(record.recordHash).to.equal(testData[i].recordHash);
        expect(record.quorumAchieved).to.equal(testData[i].quorum);
        expect(record.ipfsCid).to.equal(testData[i].ipfsCid);
        verified++;
      }
      
      console.log(`\n✓ All ${verified} records verified successfully`);
      console.log(`  Data integrity maintained: 100%`);
    });
  });

  describe("Gas Efficiency Analysis", function () {
    let registry;

    beforeEach(async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
      await registry.waitForDeployment();
    });

    it("Should track gas usage for key operations", async function () {
      console.log("\n=== Gas Usage Analysis ===");
      
      // Test record anchoring gas
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("gas-test"));
      const anchorTx = await registry.connect(ggcMultisig).anchorGovernanceRecord(
        recordHash, 
        7000, 
        "QmGasTest"
      );
      const anchorReceipt = await anchorTx.wait();
      console.log(`  Anchor Record Gas: ${anchorReceipt.gasUsed.toString()}`);
      
      // Test metrics recording gas
      const metricsTx = await registry.connect(ggcMultisig).recordMetricsSnapshot(35, 400, 80);
      const metricsReceipt = await metricsTx.wait();
      console.log(`  Record Metrics Gas: ${metricsReceipt.gasUsed.toString()}`);
      
      // Test quorum update gas
      const quorumTx = await registry.connect(ggcMultisig).setQuorumThreshold(7500);
      const quorumReceipt = await quorumTx.wait();
      console.log(`  Update Quorum Gas: ${quorumReceipt.gasUsed.toString()}`);
      
      console.log("\n✓ Gas analysis complete");
    });
  });
});
