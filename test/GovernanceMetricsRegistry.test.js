const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GovernanceMetricsRegistry", function () {
  let registry;
  let deployer;
  let ggcMultisig;
  let user1;
  let user2;

  beforeEach(async function () {
    [deployer, ggcMultisig, user1, user2] = await ethers.getSigners();
    
    const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
    registry = await GovernanceMetricsRegistry.deploy(ggcMultisig.address);
    await registry.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct GGC multisig address", async function () {
      const config = await registry.getGovernanceConfig();
      expect(config.multisig).to.equal(ggcMultisig.address);
    });

    it("Should initialize with default quorum threshold (67%)", async function () {
      const config = await registry.getGovernanceConfig();
      expect(config.quorum).to.equal(6700);
    });

    it("Should initialize sustainability thresholds correctly", async function () {
      const config = await registry.getGovernanceConfig();
      expect(config.treTarget).to.equal(30); // 0.30%
      expect(config.pvMax).to.equal(500);    // 5.0%
      expect(config.isfMin).to.equal(75);    // ISF minimum of 75
    });

    it("Should revert with zero address for GGC multisig", async function () {
      const GovernanceMetricsRegistry = await ethers.getContractFactory("GovernanceMetricsRegistry");
      await expect(
        GovernanceMetricsRegistry.deploy(ethers.ZeroAddress)
      ).to.be.revertedWith("Invalid GGC multisig address");
    });
  });

  describe("Quorum Management", function () {
    it("Should allow GGC to update quorum threshold", async function () {
      await expect(registry.connect(ggcMultisig).setQuorumThreshold(7000))
        .to.emit(registry, "QuorumThresholdUpdated")
        .withArgs(6700, 7000, ggcMultisig.address);
      
      const config = await registry.getGovernanceConfig();
      expect(config.quorum).to.equal(7000);
    });

    it("Should reject quorum below minimum (51%)", async function () {
      await expect(
        registry.connect(ggcMultisig).setQuorumThreshold(5000)
      ).to.be.revertedWith("Invalid quorum threshold");
    });

    it("Should reject quorum above maximum (90%)", async function () {
      await expect(
        registry.connect(ggcMultisig).setQuorumThreshold(9100)
      ).to.be.revertedWith("Invalid quorum threshold");
    });

    it("Should reject quorum update from non-GGC address", async function () {
      await expect(
        registry.connect(user1).setQuorumThreshold(7000)
      ).to.be.revertedWith("Only GGC multisig authorized");
    });
  });

  describe("Sustainability Thresholds", function () {
    it("Should allow GGC to update TRE target", async function () {
      await expect(registry.connect(ggcMultisig).setTreSustainabilityTarget(50))
        .to.emit(registry, "SustainabilityTargetUpdated")
        .withArgs("TRE", 30, 50);
      
      const config = await registry.getGovernanceConfig();
      expect(config.treTarget).to.equal(50);
    });

    it("Should allow GGC to update max Planetary Violence", async function () {
      await expect(registry.connect(ggcMultisig).setMaxPlanetaryViolence(300))
        .to.emit(registry, "SustainabilityTargetUpdated")
        .withArgs("PV", 500, 300);
      
      const config = await registry.getGovernanceConfig();
      expect(config.pvMax).to.equal(300);
    });

    it("Should allow GGC to update min Integral Scarcity Factor", async function () {
      await expect(registry.connect(ggcMultisig).setMinIntegralScarcityFactor(80))
        .to.emit(registry, "SustainabilityTargetUpdated")
        .withArgs("ISF", 75, 80);
      
      const config = await registry.getGovernanceConfig();
      expect(config.isfMin).to.equal(80);
    });

    it("Should reject invalid TRE targets", async function () {
      await expect(
        registry.connect(ggcMultisig).setTreSustainabilityTarget(0)
      ).to.be.revertedWith("Invalid TRE target");
      
      await expect(
        registry.connect(ggcMultisig).setTreSustainabilityTarget(1001)
      ).to.be.revertedWith("Invalid TRE target");
    });

    it("Should reject PV threshold above 20%", async function () {
      await expect(
        registry.connect(ggcMultisig).setMaxPlanetaryViolence(2001)
      ).to.be.revertedWith("PV threshold too high");
    });

    it("Should reject ISF above 100", async function () {
      await expect(
        registry.connect(ggcMultisig).setMinIntegralScarcityFactor(101)
      ).to.be.revertedWith("ISF must be 0-100");
    });
  });

  describe("Governance Record Anchoring", function () {
    it("Should anchor governance record successfully", async function () {
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
      const quorum = 7000;
      const ipfsCid = "QmTest123";

      await expect(
        registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, quorum, ipfsCid)
      ).to.emit(registry, "GovernanceRecordAnchored");

      expect(await registry.totalGovernanceDecisions()).to.equal(1);
      expect(await registry.getRecordCount()).to.equal(1);
    });

    it("Should reject record with insufficient quorum", async function () {
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
      const quorum = 6000; // Below default 6700
      const ipfsCid = "QmTest123";

      await expect(
        registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, quorum, ipfsCid)
      ).to.be.revertedWith("Quorum not met");
    });

    it("Should reject record without IPFS CID", async function () {
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
      const quorum = 7000;

      await expect(
        registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, quorum, "")
      ).to.be.revertedWith("IPFS CID required");
    });

    it("Should execute governance record", async function () {
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
      const quorum = 7000;
      const ipfsCid = "QmTest123";

      const tx = await registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, quorum, ipfsCid);
      const receipt = await tx.wait();
      
      // Find the GovernanceRecordAnchored event to get the recordId
      const event = receipt.logs.find(log => {
        try {
          const parsed = registry.interface.parseLog(log);
          return parsed.name === "GovernanceRecordAnchored";
        } catch {
          return false;
        }
      });
      
      const recordId = registry.interface.parseLog(event).args[0];

      await expect(
        registry.connect(ggcMultisig).executeGovernanceRecord(recordId)
      ).to.emit(registry, "GovernanceRecordExecuted");

      expect(await registry.executedGovernanceDecisions()).to.equal(1);
    });

    it("Should calculate governance effectiveness correctly", async function () {
      // No decisions yet
      expect(await registry.getGovernanceEffectiveness()).to.equal(0);

      // Anchor 2 records
      for (let i = 0; i < 2; i++) {
        const recordHash = ethers.keccak256(ethers.toUtf8Bytes(`decision-${i}`));
        await registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, 7000, `QmTest${i}`);
      }

      // 0 of 2 executed = 0%
      expect(await registry.getGovernanceEffectiveness()).to.equal(0);

      // Execute one record
      const recordIds = [];
      for (let i = 0; i < 2; i++) {
        recordIds.push(await registry.recordIds(i));
      }
      
      await registry.connect(ggcMultisig).executeGovernanceRecord(recordIds[0]);

      // 1 of 2 executed = 50% = 5000 bps
      expect(await registry.getGovernanceEffectiveness()).to.equal(5000);
    });
  });

  describe("Metrics Tracking", function () {
    it("Should record metrics snapshot", async function () {
      const treRate = 35;  // 0.35%
      const pv = 400;      // 4.0%
      const isf = 80;      // ISF of 80

      const tx = await registry.connect(ggcMultisig).recordMetricsSnapshot(treRate, pv, isf);
      await expect(tx)
        .to.emit(registry, "MetricsSnapshotRecorded");

      const latest = await registry.latestMetrics();
      expect(latest.treRate).to.equal(treRate);
      expect(latest.planetaryViolence).to.equal(pv);
      expect(latest.scarcityFactor).to.equal(isf);

      expect(await registry.getMetricsHistoryLength()).to.equal(1);
    });

    it("Should check sustainability compliance correctly", async function () {
      // Record good metrics - all thresholds met
      await registry.connect(ggcMultisig).recordMetricsSnapshot(
        35,   // TRE 0.35% (target: 0.30%)
        400,  // PV 4.0% (max: 5.0%)
        80    // ISF 80 (min: 75)
      );

      const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
      expect(isSustainable).to.be.true;
      expect(failures.length).to.equal(0);
    });

    it("Should detect TRE below target", async function () {
      // TRE too low
      await registry.connect(ggcMultisig).recordMetricsSnapshot(
        20,   // TRE 0.20% (target: 0.30%)
        400,  // PV 4.0%
        80    // ISF 80
      );

      const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
      expect(isSustainable).to.be.false;
      expect(failures.length).to.equal(1);
      expect(failures[0]).to.equal("TRE below target");
    });

    it("Should detect PV above maximum", async function () {
      // PV too high
      await registry.connect(ggcMultisig).recordMetricsSnapshot(
        35,   // TRE 0.35%
        600,  // PV 6.0% (max: 5.0%)
        80    // ISF 80
      );

      const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
      expect(isSustainable).to.be.false;
      expect(failures.length).to.equal(1);
      expect(failures[0]).to.equal("PV above maximum");
    });

    it("Should detect ISF below minimum", async function () {
      // ISF too low
      await registry.connect(ggcMultisig).recordMetricsSnapshot(
        35,  // TRE 0.35%
        400, // PV 4.0%
        70   // ISF 70 (min: 75)
      );

      const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
      expect(isSustainable).to.be.false;
      expect(failures.length).to.equal(1);
      expect(failures[0]).to.equal("ISF below minimum");
    });

    it("Should detect multiple threshold failures", async function () {
      // All metrics failing
      await registry.connect(ggcMultisig).recordMetricsSnapshot(
        20,  // TRE too low
        600, // PV too high
        70   // ISF too low
      );

      const [isSustainable, failures] = await registry.checkSustainabilityCompliance();
      expect(isSustainable).to.be.false;
      expect(failures.length).to.equal(3);
    });
  });

  describe("View Functions", function () {
    it("Should return correct governance config", async function () {
      const config = await registry.getGovernanceConfig();
      expect(config.multisig).to.equal(ggcMultisig.address);
      expect(config.quorum).to.equal(6700);
      expect(config.treTarget).to.equal(30);
      expect(config.pvMax).to.equal(500);
      expect(config.isfMin).to.equal(75);
    });

    it("Should retrieve governance record", async function () {
      const recordHash = ethers.keccak256(ethers.toUtf8Bytes("test-decision"));
      const quorum = 7000;
      const ipfsCid = "QmTest123";

      const tx = await registry.connect(ggcMultisig).anchorGovernanceRecord(recordHash, quorum, ipfsCid);
      const receipt = await tx.wait();
      
      const event = receipt.logs.find(log => {
        try {
          const parsed = registry.interface.parseLog(log);
          return parsed.name === "GovernanceRecordAnchored";
        } catch {
          return false;
        }
      });
      
      const recordId = registry.interface.parseLog(event).args[0];
      const record = await registry.getGovernanceRecord(recordId);

      expect(record.recordHash).to.equal(recordHash);
      expect(record.quorumAchieved).to.equal(quorum);
      expect(record.proposer).to.equal(ggcMultisig.address);
      expect(record.executed).to.be.false;
      expect(record.ipfsCid).to.equal(ipfsCid);
    });
  });
});
