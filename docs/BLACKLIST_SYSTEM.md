# EUYSTACIO Framework - Permanent Blacklist System

## Overview

The **Permanent Blacklist System** is a critical security component of the EUYSTACIO framework designed to protect the network from malicious nodes, compromised entities, and security threats. This system implements a three-tier blacklist architecture with integration to MISP (Malware Information Sharing Platform) policy triggers.

## Architecture

### Three-Tier Blacklist Structure

As specified in the requirements, the blacklist system comprises **three main components**:

#### 1. Address Blacklist (Component 1)
- **Purpose**: Block malicious or compromised node addresses
- **Scope**: Sentinel AI Nodes (SANs), EFA DIDs, and other blockchain addresses
- **Implementation**: `blacklistedAddresses` mapping in BlacklistManager contract
- **Use Cases**:
  - Nodes repeatedly violating ethical constraints
  - Compromised SAN nodes
  - Addresses associated with attack attempts
  - Entities engaged in data theft or manipulation

#### 2. CID Blacklist (Component 2)
- **Purpose**: Block malicious or compromised IPFS Content Identifiers
- **Scope**: Model versions, training data, and other content-addressed resources
- **Implementation**: `blacklistedCIDs` mapping in BlacklistManager contract
- **Use Cases**:
  - Malicious model versions (backdoored AI models)
  - Poisoned training datasets
  - Compromised Ethical Adaptation Layers (EAL)
  - Unauthorized model distributions

#### 3. DID Blacklist (Component 3)
- **Purpose**: Block compromised Decentralized Identifiers
- **Scope**: EFA (Euystacio Field Agent) DIDs and other identity credentials
- **Implementation**: `blacklistedDIDs` mapping in BlacklistManager contract
- **Use Cases**:
  - Compromised EFA identities
  - Stolen or cloned credentials
  - DIDs associated with social engineering attacks
  - Sybil attack prevention

## MISP Integration

### INT_MISP_POLICY_TRIGGERS

The system includes integration with **MISP (Malware Information Sharing Platform)** policy triggers for automated threat response:

- **Threat Intelligence Sharing**: Automatically receive and act on threat indicators
- **Severity-Based Response**: Actions scaled based on threat level (1-5)
- **Automated Blacklisting**: High-severity threats (4-5) trigger automatic permanent blacklisting
- **Evidence Tracking**: All MISP triggers are cryptographically linked to evidence hashes

### MISP Trigger Activation

```solidity
function activateMISPTrigger(
    string calldata indicatorType,
    uint256 severityLevel,
    bytes32 threatHash,
    address entityToBlacklist
) external
```

**Severity Levels**:
- **Level 1**: Low - Monitoring only
- **Level 2**: Moderate - Flagged for review
- **Level 3**: Medium - Increased scrutiny
- **Level 4**: High - Automatic temporary blacklist
- **Level 5**: Critical - Permanent blacklist with immediate effect

## Blacklist Types

### Permanent vs. Temporary Blacklists

- **Permanent Blacklists** (`isPermanent: true`):
  - Cannot be removed except by unanimous GGC decision
  - Reserved for severe violations (data theft, repeated attacks, system sabotage)
  - Cryptographically immutable with evidence hash anchoring
  
- **Temporary Blacklists** (`isPermanent: false`):
  - Can be removed by GGC multisig after review
  - Used for suspected but unconfirmed violations
  - Subject to appeal and re-evaluation

## Security Features

### 1. Evidence-Based Blacklisting
Every blacklist entry requires:
- **Evidence Hash**: Cryptographic link to proof (SEP ID, investigation report, MISP indicator)
- **Timestamp**: Immutable record of when entity was blacklisted
- **Reporter**: Identity of the EFA or monitor who initiated the blacklist
- **Reason**: Human-readable explanation

### 2. Multi-Layer Protection
The system protects against:
- **Communication from Suspicious Nodes**: Blocked at submitSEP level
- **Malicious Model Deployment**: CID verification before model usage
- **Identity Theft**: DID verification for EFA operations
- **Coordinated Attacks**: Batch blacklisting capability

### 3. Integration Points

#### EIMClient Integration
```solidity
// Automatic blacklist check on SEP submission
function submitSEP(...) {
    // Check if SAN is blacklisted
    if (isBlacklisted) revert("SAN node is blacklisted");
    // Check if model CID is blacklisted
    if (isCIDBlacklisted) revert("Model CID is blacklisted");
}
```

#### SAN Registration Protection
```solidity
// Prevent blacklisted entities from registering
function registerSAN(address san) {
    require(!isBlacklisted, "Cannot register blacklisted address");
}
```

## Governance

### Authorization Model

1. **GGC Multisig**: Ultimate authority
   - Can authorize/revoke reporters
   - Can remove non-permanent blacklists
   - Can update contract references
   - Cannot remove permanent blacklists (immutable)

2. **Authorized Reporters**: EFAs and Monitors
   - Can submit blacklist requests
   - Can activate MISP triggers
   - Subject to penalty for false reports

3. **VCE Integration**: Automatic Blacklisting
   - When VCE threshold is met (default: 3 EFAs)
   - Automatically triggers MISP policy
   - Evidence: VCE consensus hash

## Operational Procedures

### Blacklisting an Entity

1. **Detection**: Threat identified through:
   - VCE (Veto Consensus Event)
   - MISP threat intelligence
   - Manual EFA investigation
   - Automated monitoring alerts

2. **Evidence Collection**:
   - Gather SEP (Sentinel Evidence Package)
   - Document violation details
   - Generate evidence hash
   - Determine severity level

3. **Submission**:
   ```solidity
   blacklistAddress(
       suspiciousNode,
       "Repeated EAL violations - Evidence: SEP#12345",
       evidenceHash,
       true  // permanent
   );
   ```

4. **Enforcement**:
   - Immediate effect on all network operations
   - Node quarantined (cannot submit SEPs)
   - Existing operations may be reverted
   - Collateral slashing (if applicable)

### Query Functions

```solidity
// Check if address is blacklisted
(bool isBlacklisted, bool isPermanent) = blacklistManager.isAddressBlacklisted(nodeAddress);

// Check multiple entity types at once
bool blocked = blacklistManager.isAnyBlacklisted(address, cid, did);

// Get full blacklist entry details
BlacklistEntry memory entry = blacklistManager.getBlacklistEntry(address);

// Get statistics
(uint256 addresses, uint256 cids, uint256 dids, uint256 mispCount) = 
    blacklistManager.getBlacklistStats();
```

## VCE to Blacklist Pipeline

### Automatic Escalation

1. **VCE Triggered**: 3+ EFAs report violation
2. **VCE Executed**: Consensus reached (67% threshold)
3. **MISP Activated**: Severity level 5 (Critical)
4. **Automatic Blacklist**: Node permanently blacklisted
5. **Network Quarantine**: All communications blocked
6. **Evidence Anchored**: Immutable on-chain record

### Flow Diagram

```
VCE Detection (EFA) 
    ↓
VCE Accumulation (3+ EFAs)
    ↓
VCE Execution (67% consensus)
    ↓
MISP Trigger Activation (Severity: 5)
    ↓
Permanent Blacklist
    ↓
Network-Wide Block (All Components)
```

## Testing Ecosystem State

The problem statement mentions **"ECOSYSTEM TESTING su repository upstream IP"** status. The blacklist system supports this through:

1. **Test Mode**: Blacklist manager can be deployed in test configuration
2. **Evidence Simulation**: SEP hashes can be simulated for testing
3. **MISP Mock Data**: Test threat intelligence without real incidents
4. **Reversible Testing**: Non-permanent blacklists for testing scenarios

## Best Practices

### For EFAs (Euystacio Field Agents)

1. **Due Diligence**: Always collect sufficient evidence before reporting
2. **Severity Assessment**: Accurately classify threat level (1-5)
3. **Documentation**: Provide clear, detailed reasons
4. **False Positive Prevention**: Double-check before marking as permanent
5. **Collaboration**: Coordinate with other EFAs for VCE consensus

### For GGC (Global Governance Council)

1. **Regular Audits**: Review blacklist entries monthly
2. **Appeal Process**: Maintain mechanism for legitimate appeals
3. **Reporter Accountability**: Monitor for abuse or false reports
4. **Update Procedures**: Keep MISP integration current
5. **Transparency**: Publish anonymized blacklist statistics

## Contract Deployment

### Deployment Order

1. **Deploy BlacklistManager**:
   ```solidity
   BlacklistManager blacklistManager = new BlacklistManager(ggcMultisig);
   ```

2. **Update EIMClient** (or deploy new version):
   ```solidity
   EIMClient eimClient = new EIMClient(ggcMultisig, tfkVerifier, blacklistManager);
   ```

3. **Authorize Initial Reporters**:
   ```solidity
   blacklistManager.authorizeReporter(efaAddress1);
   blacklistManager.authorizeReporter(eimClientAddress);
   ```

### Configuration Parameters

- **VCE Threshold**: 3 EFAs (configurable via `setVCEThreshold`)
- **MISP Auto-Blacklist Level**: Severity ≥ 4
- **Permanent Ban Criteria**: Defined by GGC policy
- **Evidence Hash Algorithm**: SHA-256 (keccak256 in Solidity)

## Security Guarantees

### Immutability
- Permanent blacklists cannot be removed programmatically
- Evidence hashes provide cryptographic proof
- Timestamp ensures temporal ordering

### Transparency
- All blacklist actions emit events
- Evidence is publicly verifiable (if not sensitive)
- Statistics available on-chain

### Decentralization
- Multiple authorized reporters (EFAs)
- No single point of control
- VCE consensus required for auto-blacklisting

### Protection Coverage

✅ **Blocks**:
- Malicious SAN nodes from submitting SEPs
- Compromised models from being deployed
- Stolen DIDs from participating in governance
- Coordinated attacks through batch detection

✅ **Prevents**:
- Data theft through quarantined nodes
- Model poisoning via CID blacklisting
- Identity fraud via DID blacklisting
- Replay attacks through permanent records

## Future Enhancements

1. **Appeal Mechanism**: Smart contract-based appeal process
2. **Reputation System**: Track reporter accuracy
3. **ML-Based Detection**: AI-assisted threat classification
4. **Cross-Chain Sync**: Share blacklists across multiple networks
5. **Automated MISP Integration**: Direct feed from threat intelligence sources

## References

- **SAIN Protocol V1.0**: Sentinel AI Network governance framework
- **VCE Specification**: Veto Consensus Event mechanism
- **SEP Schema**: Sentinel Evidence Package structure
- **MISP Project**: https://www.misp-project.org/

## Contact & Support

For security incidents or blacklist appeals:
- **Email**: security@euystacio.example
- **Emergency**: GGC Multisig contact
- **Documentation**: https://github.com/hannesmitterer/nexus

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-15  
**Status**: Operational  
**Classification**: Public
