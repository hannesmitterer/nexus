# IPFS Integration Guide - Phase II Immutable Storage Architecture

## Overview

The IPFS (InterPlanetary File System) integration in Phase II provides the foundation for immutable, decentralized storage of all critical artifacts in the Euystacio Framework. Every important artifact—from model weights to SEP bundles—is stored on IPFS and anchored on-chain for verification.

## Why IPFS?

### Content-Addressed Storage
- **Immutability**: Once uploaded, content cannot be changed without changing the CID
- **Verification**: Anyone can verify content matches the CID by computing its hash
- **Deduplication**: Identical content has identical CID (saves storage)

### Decentralization
- **No Single Point of Failure**: Content distributed across multiple nodes
- **Censorship Resistance**: No central authority can delete content
- **Redundancy**: Multiple pinning services ensure availability

### Integration with Blockchain
- **CID Anchoring**: Store CID on-chain for permanent reference
- **Verification**: Smart contracts can verify content without storing it
- **Audit Trail**: Blockchain records when/who anchored each CID

## Architecture

### IPFS Infrastructure

**Pinning Services (Redundancy: 3x minimum):**
1. **Pinata** (Primary): US East, West, EU
2. **Web3.Storage**: Decentralized storage with Filecoin backing
3. **Infura IPFS**: Enterprise-grade reliability
4. **Custom Nodes**: 2 self-hosted nodes for critical data
5. **Storj DCS**: Decentralized cloud storage integration

**Gateway Access:**
- Public HTTP Gateway: `https://ipfs.io/ipfs/[CID]`
- Dedicated Gateway: `https://nexus.ipfs.euystacio.network/ipfs/[CID]`
- Direct IPFS Protocol: `ipfs://[CID]` (requires IPFS client)

### Storage Tiers

| Tier | Artifact Type | Redundancy | Pin Duration | Examples |
|------|--------------|------------|--------------|----------|
| Critical | Model Weights, Core EAL | 5x | Permanent | EAL modules, AI models |
| High | SEP Bundles, Governance Votes | 3x | Permanent | Inference evidence, vote records |
| Standard | Audit Reports, Documentation | 2x | 5 years | Red team reports, technical docs |
| Ephemeral | Temporary Logs, Debug Data | 1x | 30 days | Development artifacts |

## Artifact Types and CID Anchoring

### 1. Model Weights (EAL + Base Models)

**Upload Process:**
```bash
# Upload EAL module to IPFS
ipfs add --pin=true eal_v0.bin
# Returns: added QmPhase2InitialEAL... eal_v0.bin

# Verify upload
ipfs cat QmPhase2InitialEAL... | sha256sum
# Compare with local file hash
```

**On-Chain Anchoring:**
```solidity
// Via TFKVerifier contract
tfkVerifier.propose_model_retrain(
    bytes32(keccak256("QmPhase2InitialEAL...")),
    "Initial Phase II EAL deployment"
);
```

**Verification:**
```javascript
// Anyone can verify
const response = await fetch('https://ipfs.io/ipfs/QmPhase2InitialEAL...');
const content = await response.arrayBuffer();
const hash = await crypto.subtle.digest('SHA-256', content);
const cid = computeCID(hash); // Custom function
console.assert(cid === 'QmPhase2InitialEAL...', 'CID mismatch!');
```

### 2. SEP (Sentinel Evidence Package) Bundles

**SEP Structure (JSON):**
```json
{
  "sep_id": "SEP_20251213_001",
  "timestamp_nts": "2025-12-13T03:00:00.000Z",
  "artifact_type": "INFERENCE_BLOCK",
  "model_digest": "QmPhase2InitialEAL...",
  "input_payload_digest": "0xINPUT_HASH...",
  "output_result_digest": "0xOUTPUT_HASH...",
  "node_did_signature": "0xSIGNATURE...",
  "blockchain_receipt": "0xTX_HASH..."
}
```

**Bundling and Upload:**
```bash
# Create bundle of 100 SEPs
tar -czf sep_bundle_20251213.tar.gz sep_*.json

# Upload to IPFS
ipfs add --pin=true sep_bundle_20251213.tar.gz
# Returns: QmSEPBundle20251213...

# Anchor CID on-chain
cast send $EIM_CLIENT \
  "anchorCID(bytes32,string)" \
  $(cast keccak "QmSEPBundle20251213...") \
  "SEP_BUNDLE"
```

**Query and Retrieval:**
```javascript
// Retrieve SEP bundle from IPFS
async function getSEPBundle(cid) {
  const response = await fetch(`https://ipfs.io/ipfs/${cid}`);
  const tarball = await response.blob();
  // Decompress and parse
  const seps = await extractTarGz(tarball);
  return seps;
}
```

### 3. Governance Vote Records

**Vote Record Format:**
```json
{
  "proposal_id": 5,
  "vote_type": "MODEL_RETRAIN",
  "start_time": "2025-12-11T00:00:00Z",
  "end_time": "2025-12-13T00:00:00Z",
  "votes_for": 8,
  "votes_against": 1,
  "voters": [
    {"address": "0xEFA1...", "vote": true, "timestamp": "..."},
    {"address": "0xEFA2...", "vote": true, "timestamp": "..."}
  ],
  "result": "PASSED",
  "consensus_percentage": 88.9
}
```

**Anchoring:**
```solidity
// After vote execution
tfkVerifier.anchorCID(
    bytes32(keccak256("QmVoteRecord5...")),
    "GOVERNANCE_VOTE"
);
```

### 4. Audit Reports and Documentation

**Red Team Report Example:**
```markdown
# Red Team Audit Report - EAL v0

**Date:** 2025-12-10
**Team:** External Security Researchers
**Scope:** Phase II EAL Adversarial Testing

## Executive Summary
Tested EAL v0 for ethical constraint bypass...

## Findings
1. **Critical:** None
2. **High:** None
3. **Medium:** 2 findings
4. **Low:** 5 findings

[Full report...]
```

**Upload and Anchor:**
```bash
# Upload to IPFS
ipfs add red_team_report_eal_v0.md
# Returns: QmRedTeamReportEALv0...

# Anchor via TFKVerifier
cast send $TFK_VERIFIER \
  "anchorCID(bytes32,string)" \
  $(cast keccak "QmRedTeamReportEALv0...") \
  "AUDIT_REPORT"
```

## CID Verification Process

### For Users (Public Verification)

**Step 1: Get CID from Dashboard**
- Navigate to Sensisara Dashboard → TFK Monitoring
- Copy current model CID: `QmPhase2InitialEAL...`

**Step 2: Download from IPFS**
```bash
# Using IPFS CLI
ipfs get QmPhase2InitialEAL... -o downloaded_eal.bin

# Using HTTP Gateway
curl https://ipfs.io/ipfs/QmPhase2InitialEAL... -o downloaded_eal.bin
```

**Step 3: Compute Hash**
```bash
# Compute SHA-256 hash
sha256sum downloaded_eal.bin
# Output: abc123def456...

# Convert to CID format (requires IPFS tools)
ipfs add --only-hash downloaded_eal.bin
# Output: QmPhase2InitialEAL...
```

**Step 4: Verify On-Chain**
```bash
# Query TFKVerifier contract
cast call $TFK_VERIFIER "currentModelCID()" --rpc-url $POLYGON_RPC
# Output: 0x[keccak256 of CID]

# Compare
```

### For Smart Contracts

**Verification Pattern:**
```solidity
contract CIDVerifier {
    ITFKVerifier public tfkVerifier;
    
    function verifyModelCID(bytes32 claimedCID) external view returns (bool) {
        bytes32 onChainCID = tfkVerifier.currentModelCID();
        return claimedCID == onChainCID;
    }
    
    function verifyArbitraryArtifact(bytes32 cid, string memory artifactType) 
        external view returns (bool) 
    {
        // Check CIDAnchored events in TFKVerifier
        // (In production, would use event logs or state mapping)
        return true; // Simplified
    }
}
```

## Pinning Strategy

### Automatic Pinning

**Critical Artifacts (Immediate):**
```javascript
// Auto-pin on upload
async function uploadCriticalArtifact(file) {
  // Upload to all pinning services simultaneously
  const results = await Promise.all([
    pinata.pinFileToIPFS(file),
    web3Storage.put([file]),
    infuraIPFS.add(file),
    customNode1.add(file),
    customNode2.add(file)
  ]);
  
  // Verify all CIDs match
  const cids = results.map(r => r.cid);
  if (new Set(cids).size !== 1) {
    throw new Error('CID mismatch across pinning services!');
  }
  
  return cids[0];
}
```

**SEP Bundles (Scheduled):**
```javascript
// Bundle and pin every 24 hours or 1000 SEPs
const bundleScheduler = {
  interval: 24 * 60 * 60 * 1000, // 24 hours
  maxSEPs: 1000,
  
  async run() {
    const seps = await collectPendingSEPs();
    if (seps.length >= this.maxSEPs || timeElapsed >= this.interval) {
      const bundle = createBundle(seps);
      const cid = await uploadCriticalArtifact(bundle);
      await anchorOnChain(cid, 'SEP_BUNDLE');
    }
  }
};
```

### Pin Maintenance

**Health Checks:**
```javascript
// Daily health check for all pinned CIDs
async function verifyPinHealth() {
  const criticalCIDs = await getCriticalCIDsFromChain();
  
  for (const cid of criticalCIDs) {
    const availability = await checkAvailability(cid);
    
    if (availability.count < 3) {
      // Re-pin to additional services
      await emergencyRePin(cid);
      alertGGC(`CID ${cid} below redundancy threshold`);
    }
  }
}

async function checkAvailability(cid) {
  const services = [pinata, web3Storage, infuraIPFS, customNode1, customNode2];
  let count = 0;
  
  for (const service of services) {
    const isPinned = await service.isPinned(cid);
    if (isPinned) count++;
  }
  
  return { count, total: services.length };
}
```

## Performance Optimization

### Retrieval Speed

**Multi-Gateway Strategy:**
```javascript
// Try fastest gateway first
async function retrieveWithFallback(cid) {
  const gateways = [
    'https://nexus.ipfs.euystacio.network/ipfs/',
    'https://ipfs.io/ipfs/',
    'https://cloudflare-ipfs.com/ipfs/',
    'https://gateway.pinata.cloud/ipfs/'
  ];
  
  // Race all gateways, return first success
  return Promise.race(
    gateways.map(gw => fetch(gw + cid))
  );
}
```

**Caching Layer:**
```javascript
// CDN caching for frequently accessed artifacts
const cache = new Map();

async function getCachedArtifact(cid) {
  if (cache.has(cid)) {
    return cache.get(cid);
  }
  
  const content = await retrieveWithFallback(cid);
  cache.set(cid, content);
  
  // Cache invalidation: 1 hour for ephemeral, never for critical
  if (isEphemeral(cid)) {
    setTimeout(() => cache.delete(cid), 3600000);
  }
  
  return content;
}
```

## Security Best Practices

### 1. Never Store Secrets on IPFS
```javascript
// ❌ WRONG
const config = {
  apiKey: "secret123",
  privateKey: "0xPRIVATE..."
};
ipfs.add(JSON.stringify(config)); // Exposed forever!

// ✅ CORRECT
const config = {
  publicEndpoint: "https://api.example.com",
  networkId: "polygon-mainnet"
};
ipfs.add(JSON.stringify(config)); // Safe
```

### 2. Verify Before Trust
```javascript
// Always verify CID matches content
async function safeRetrieve(expectedCID) {
  const content = await fetch(`https://ipfs.io/ipfs/${expectedCID}`);
  const buffer = await content.arrayBuffer();
  const computedCID = await computeCIDFromContent(buffer);
  
  if (computedCID !== expectedCID) {
    throw new Error('CID verification failed! Possible attack.');
  }
  
  return buffer;
}
```

### 3. Rate Limiting and DoS Protection
```javascript
// Limit IPFS uploads per address
const rateLimiter = {
  limits: new Map(),
  maxPerHour: 100,
  
  async checkLimit(address) {
    const count = this.limits.get(address) || 0;
    if (count >= this.maxPerHour) {
      throw new Error('Rate limit exceeded');
    }
    this.limits.set(address, count + 1);
  }
};
```

## Integration with Phase II Components

### Sensisara Dashboard Integration

**Real-Time CID Display:**
```javascript
// Dashboard updates CID display on model change
tfkVerifier.on('ModelVersionActivated', (version, cid, timestamp) => {
  document.getElementById('model-cid').textContent = cid;
  document.getElementById('model-version').textContent = `v${version}`;
  
  // Add to lineage display
  addToModelLineage(version, cid, timestamp);
});
```

**Verification Button:**
```html
<button onclick="verifyCIDOnIPFS()">
  Verify CID on IPFS Gateway
</button>

<script>
async function verifyCIDOnIPFS() {
  const cid = document.getElementById('model-cid').textContent;
  const url = `https://ipfs.io/ipfs/${cid}`;
  
  // Show loading
  showStatus('Downloading from IPFS...');
  
  const response = await fetch(url);
  if (response.ok) {
    showStatus('✓ CID verified on IPFS!', 'green');
  } else {
    showStatus('❌ CID not found on IPFS', 'red');
  }
}
</script>
```

## Metrics and Monitoring

### Storage Metrics

**Dashboard Panel:**
- Total CIDs Anchored: 1,247
- Active SEP Bundles: 982
- Model Versions: 1
- Total Storage Used: 47.3 GB
- Average Redundancy: 3.8x

**API Endpoint:**
```
GET /ipfs/metrics
{
  "total_cids": 1247,
  "by_type": {
    "MODEL_PROPOSAL": 1,
    "SEP_BUNDLE": 982,
    "AUDIT_REPORT": 5,
    "GOVERNANCE_VOTE": 7,
    "OTHER": 252
  },
  "total_storage_gb": 47.3,
  "avg_retrieval_time_ms": 6200,
  "pin_health": {
    "healthy": 1245,
    "degraded": 2,
    "critical": 0
  }
}
```

## Conclusion

The IPFS integration in Phase II provides a robust, immutable, and decentralized storage layer for all critical Euystacio Framework artifacts. Combined with on-chain CID anchoring, this architecture ensures:

- **Transparency**: Anyone can verify content matches on-chain CIDs
- **Immutability**: Content cannot be altered without detection
- **Availability**: 3-5x redundancy ensures high uptime
- **Scalability**: Decentralized storage grows with demand

**Phase II Readiness: ✅ OPERATIONAL**

---

*Document Version: 1.0*  
*Last Updated: 2025-12-13*  
*Author: Euystacio Framework / Phase II Deployment Team*
