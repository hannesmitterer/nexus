# IVBS Operational Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2026-01-13  
**Framework:** Euystacio / SAIN Protocol / GGI

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Red Code Veto Operations](#red-code-veto-operations)
3. [Triple-Sign Validation Workflows](#triple-sign-validation-workflows)
4. [Vacuum Anchor Management](#vacuum-anchor-management)
5. [Emergency Procedures](#emergency-procedures)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

**Required:**
- IPFS daemon installed and running
- Access to Ethereum-compatible wallet
- Network access to Polygon mainnet
- GGC multisig credentials (for authorized operations)

**Optional but Recommended:**
- Pinata API key for enhanced redundancy
- Web3.Storage token for decentralized storage
- Infura project ID for reliable IPFS gateway access

### Initial Setup

1. **Install IPFS:**
   ```bash
   # macOS
   brew install ipfs
   
   # Linux
   wget https://dist.ipfs.io/go-ipfs/v0.14.0/go-ipfs_v0.14.0_linux-amd64.tar.gz
   tar -xvzf go-ipfs_v0.14.0_linux-amd64.tar.gz
   cd go-ipfs
   sudo ./install.sh
   ```

2. **Initialize and Start IPFS:**
   ```bash
   ipfs init
   ipfs daemon &
   ```

3. **Configure Environment:**
   ```bash
   export IPFS_GATEWAY="https://ipfs.io/ipfs"
   export PINATA_API_KEY="your_pinata_key"
   export WEB3_STORAGE_TOKEN="your_web3storage_token"
   export CONTRACT_VACUUM_ANCHOR="0x..."
   export CONTRACT_TRIPLE_SIGN="0x..."
   export CONTRACT_RED_CODE_VETO="0x..."
   ```

4. **Verify Installation:**
   ```bash
   ./scripts/ivbs_operations.sh health-check
   ```

---

## Red Code Veto Operations

### Understanding Red Code Veto

The Red Code Veto mechanism provides critical decision governance by allowing designated Red Code Authorities (RCAs) to prevent actions that violate ethical constraints. Any single RCA can veto a proposal, triggering an automatic audit and review process.

### RCA Responsibilities

**Red Code Authorities must:**
- Review all critical proposals within 24 hours
- Provide detailed justification for any veto
- Maintain geographic and organizational diversity
- Adhere to the Living Covenant values (Peace, Help, Protection)
- Renew or rotate every 12 months

### Submitting a Red Code Veto

**Step 1: Review Proposal**
```bash
# Query proposal details
cast call $CONTRACT_RED_CODE_VETO \
  "proposals(uint256)" \
  <proposal_id> \
  --rpc-url $POLYGON_RPC
```

**Step 2: Prepare Veto Justification**

Create a detailed veto reason document:
- Specific ethical constraint violation
- Impact on TRE (Tasso di Rigenerazione Etica)
- Alternative recommendations
- Supporting evidence

**Step 3: Sign Veto Message**
```bash
# Create message hash
MESSAGE="Proposal_${PROPOSAL_ID}_VETO_${REASON}"
MESSAGE_HASH=$(echo -n "$MESSAGE" | keccak256)

# Sign with RCA private key
SIGNATURE=$(cast wallet sign "$MESSAGE_HASH" --private-key $RCA_PRIVATE_KEY)
```

**Step 4: Submit Veto**
```bash
cast send $CONTRACT_RED_CODE_VETO \
  "submitRedCodeVeto(uint256,string,bytes)" \
  $PROPOSAL_ID \
  "$REASON" \
  "$SIGNATURE" \
  --private-key $RCA_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC
```

**Step 5: Monitor Audit Process**

After veto submission:
- GGC is automatically notified
- Full audit is triggered
- Proposal is blocked from execution
- Review committee convened within 48 hours

### Emergency RCA Rotation

If an RCA is compromised or unavailable:

```bash
# GGC initiates emergency rotation
cast send $CONTRACT_RED_CODE_VETO \
  "emergencyRCARotation(address,address,string,string)" \
  $OLD_RCA_ADDRESS \
  $NEW_RCA_ADDRESS \
  "New RCA Name" \
  "Geographic Jurisdiction" \
  --from $GGC_MULTISIG \
  --rpc-url $POLYGON_RPC
```

---

## Triple-Sign Validation Workflows

### Three-Tier Validation Process

All critical actions require approval from three independent validation tiers:

1. **Technical Validation** - Automated cryptographic and integrity checks
2. **Governance Validation** - EFA/GGC multi-signature approval (7-of-9)
3. **Ethical Validation** - Red Code Authority review and approval (3-of-5)

### Workflow Example: Model Update

**Step 1: Create Triple-Sign Request**
```bash
# Compute data hash (e.g., new model CID)
DATA_HASH=$(echo -n "$NEW_MODEL_CID" | keccak256)

# Create request
REQUEST_ID=$(cast call $CONTRACT_TRIPLE_SIGN \
  "createTripleSignRequest(bytes32,string)" \
  $DATA_HASH \
  "MODEL_UPDATE" \
  --rpc-url $POLYGON_RPC)
```

**Step 2: Technical Validation (Automated)**

The technical validator automatically:
- Verifies IPFS CID integrity
- Checks cryptographic signatures
- Validates model format and size
- Runs integrity tests

```bash
# Technical validator submits result
cast send $CONTRACT_TRIPLE_SIGN \
  "submitTechnicalValidation(uint256,bool,string,bytes)" \
  $REQUEST_ID \
  true \
  "All technical checks passed" \
  $TECH_SIGNATURE \
  --from $TECHNICAL_VALIDATOR \
  --rpc-url $POLYGON_RPC
```

**Step 3: Governance Validation (EFA Vote)**

EFAs vote on the proposal (requires 7-of-9 approval):

```bash
# Each EFA signs approval
EFA_SIGNATURES=()
for EFA in "${EFAS[@]}"; do
  SIG=$(cast wallet sign $DATA_HASH --private-key $EFA_KEY)
  EFA_SIGNATURES+=("$SIG")
done

# GGC submits governance approval
cast send $CONTRACT_TRIPLE_SIGN \
  "submitGovernanceValidation(uint256,bool,bytes[],string)" \
  $REQUEST_ID \
  true \
  "[${EFA_SIGNATURES[*]}]" \
  "EFA consensus achieved (8/9)" \
  --from $GGC_MULTISIG \
  --rpc-url $POLYGON_RPC
```

**Step 4: Ethical Validation (RCA Review)**

RCAs review ethical implications (requires 3-of-5 approval):

```bash
# RCAs sign approval
RCA_SIGNATURES=()
for RCA in "${RCAS[@]}"; do
  SIG=$(cast wallet sign $DATA_HASH --private-key $RCA_KEY)
  RCA_SIGNATURES+=("$SIG")
done

# Submit ethical approval
cast send $CONTRACT_TRIPLE_SIGN \
  "submitEthicalValidation(uint256,bool,bytes[],string)" \
  $REQUEST_ID \
  true \
  "[${RCA_SIGNATURES[*]}]" \
  "No ethical violations detected (4/5 RCAs approve)" \
  --from $RCA_ADDRESS \
  --rpc-url $POLYGON_RPC
```

**Step 5: Verification and Execution**

```bash
# Verify full approval
APPROVED=$(cast call $CONTRACT_TRIPLE_SIGN \
  "verifyTripleSignApproval(uint256)" \
  $REQUEST_ID \
  --rpc-url $POLYGON_RPC)

if [ "$APPROVED" = "true" ]; then
  echo "Triple-Sign approved ✓"
  # Proceed with action execution
else
  echo "Triple-Sign not yet approved"
fi
```

---

## Vacuum Anchor Management

### Creating a Vacuum Anchor

**Automated Process:**

```bash
# Use IVBS operations script
./scripts/ivbs_operations.sh create-anchor \
  /path/to/state_snapshot.json \
  STATE \
  "System state at block 1234567"
```

**Manual Process:**

1. **Upload to IPFS:**
   ```bash
   IPFS_CID=$(ipfs add --quiet --pin=true state_snapshot.json)
   echo "IPFS CID: $IPFS_CID"
   ```

2. **Compute Content Hash:**
   ```bash
   CONTENT_HASH=$(sha256sum state_snapshot.json | awk '{print $1}')
   echo "Content Hash: 0x$CONTENT_HASH"
   ```

3. **Create Triple-Sign Request:**
   ```bash
   DATA_HASH=$(echo -n "$IPFS_CID" | keccak256)
   REQUEST_ID=$(cast call $CONTRACT_TRIPLE_SIGN \
     "createTripleSignRequest(bytes32,string)" \
     $DATA_HASH \
     "VACUUM_ANCHOR_STATE" \
     --rpc-url $POLYGON_RPC)
   ```

4. **Wait for Triple-Sign Approval** (see workflow above)

5. **Register Vacuum Anchor:**
   ```bash
   FILE_SIZE=$(stat -f%z state_snapshot.json)
   
   cast send $CONTRACT_VACUUM_ANCHOR \
     "createVacuumAnchor(bytes32,uint8,uint256,string,bytes32,uint256)" \
     $(echo -n "$IPFS_CID" | keccak256) \
     0 \
     $REQUEST_ID \
     "System state at block 1234567" \
     "0x$CONTENT_HASH" \
     $FILE_SIZE \
     --rpc-url $POLYGON_RPC
   ```

### Verifying Vacuum Anchors

**Automated Verification:**

```bash
./scripts/ivbs_operations.sh verify-anchor $IPFS_CID
```

**Manual Verification:**

1. **Download from IPFS:**
   ```bash
   ipfs get $IPFS_CID -o downloaded_content
   ```

2. **Compute Hash:**
   ```bash
   COMPUTED_HASH=$(sha256sum downloaded_content | awk '{print $1}')
   ```

3. **Query On-Chain Hash:**
   ```bash
   ANCHOR_ID=$(cast call $CONTRACT_VACUUM_ANCHOR \
     "getAnchorByCID(bytes32)" \
     $(echo -n "$IPFS_CID" | keccak256) \
     --rpc-url $POLYGON_RPC)
   
   ON_CHAIN_HASH=$(cast call $CONTRACT_VACUUM_ANCHOR \
     "anchors(uint256)" \
     $ANCHOR_ID \
     --rpc-url $POLYGON_RPC | jq -r '.contentHash')
   ```

4. **Compare:**
   ```bash
   if [ "0x$COMPUTED_HASH" = "$ON_CHAIN_HASH" ]; then
     echo "✓ Anchor integrity verified"
   else
     echo "✗ Integrity check failed!"
   fi
   ```

### Recovery Points

**Automatic Recovery Points:**
- Created every 1000 blocks
- All STATE anchors are recovery points
- Managed automatically by the system

**Manual Recovery Point:**

```bash
./scripts/ivbs_operations.sh recovery-point $ANCHOR_ID
```

---

## Emergency Procedures

### Emergency Recovery

**When to Use:**
- System state corruption detected
- Critical vulnerability requires rollback
- Consensus failure requiring reset

**Procedure:**

1. **Identify Recovery Point:**
   ```bash
   # Get latest recovery point
   RECOVERY_ANCHOR=$(cast call $CONTRACT_VACUUM_ANCHOR \
     "getLatestRecoveryPoint()" \
     --rpc-url $POLYGON_RPC)
   ```

2. **Initiate Recovery (GGC Only):**
   ```bash
   ./scripts/ivbs_operations.sh emergency-recover $RECOVERY_ANCHOR
   ```

3. **Monitor Recovery:**
   - Watch dashboard for recovery progress
   - Verify nodes sync to recovery state
   - Confirm system health restoration

### Emergency RCA Rotation

If an RCA is compromised:

1. **Immediate Deactivation:**
   ```bash
   cast send $CONTRACT_RED_CODE_VETO \
     "removeRCA(address,string)" \
     $COMPROMISED_RCA \
     "Security breach detected" \
     --from $GGC_MULTISIG
   ```

2. **Appoint Replacement:**
   ```bash
   cast send $CONTRACT_RED_CODE_VETO \
     "appointRCA(address,string,string)" \
     $NEW_RCA \
     "Replacement RCA Name" \
     "Geographic Jurisdiction" \
     --from $GGC_MULTISIG
   ```

---

## Monitoring and Maintenance

### Daily Health Checks

**Automated:**
```bash
# Add to cron: 0 0 * * * /path/to/ivbs_operations.sh health-check
./scripts/ivbs_operations.sh health-check
```

**Manual Checks:**

1. **Anchor Verification Status:**
   ```bash
   cast call $CONTRACT_VACUUM_ANCHOR \
     "getAnchorsNeedingVerification()" \
     --rpc-url $POLYGON_RPC
   ```

2. **Red Code Veto Activity:**
   ```bash
   cast call $CONTRACT_RED_CODE_VETO \
     "getActiveRCACount()" \
     --rpc-url $POLYGON_RPC
   ```

3. **Triple-Sign Pending Requests:**
   ```bash
   # Query pending Triple-Sign requests
   # Monitor dashboard for status
   ```

### Weekly Maintenance

**Every Monday:**
- Review all Vacuum Anchors created in past week
- Verify redundancy levels across pinning services
- Audit RCA activity and veto patterns
- Review Triple-Sign approval times

**Checklist:**
- [ ] All anchors have ≥3x redundancy
- [ ] No anchors in CRITICAL status
- [ ] RCA terms expiring in next 30 days
- [ ] Triple-Sign requests processed within 48 hours
- [ ] IPFS pinning services all operational

---

## Troubleshooting

### Issue: Anchor Verification Fails

**Symptoms:**
- Hash mismatch between local and on-chain
- Cannot download content from IPFS

**Solutions:**

1. **Check IPFS daemon:**
   ```bash
   ipfs id
   # If fails, restart daemon
   ipfs daemon &
   ```

2. **Try alternative gateways:**
   ```bash
   curl https://ipfs.io/ipfs/$IPFS_CID
   curl https://cloudflare-ipfs.com/ipfs/$IPFS_CID
   curl https://gateway.pinata.cloud/ipfs/$IPFS_CID
   ```

3. **Re-pin content:**
   ```bash
   ipfs pin add $IPFS_CID
   ```

### Issue: Triple-Sign Validation Stuck

**Symptoms:**
- Request pending for >48 hours
- One validation tier not responding

**Solutions:**

1. **Check which tier is blocking:**
   ```bash
   cast call $CONTRACT_TRIPLE_SIGN \
     "getRequestDetails(uint256)" \
     $REQUEST_ID
   ```

2. **Contact relevant authority:**
   - Technical: Check automated validator service
   - Governance: Notify GGC multisig signers
   - Ethical: Contact RCA members

3. **GGC override (emergency only):**
   - Requires unanimous GGC approval
   - Document reason thoroughly
   - Use only in critical situations

### Issue: Red Code Veto Not Accepted

**Symptoms:**
- Transaction reverts when submitting veto
- "Not an active RCA" error

**Solutions:**

1. **Verify RCA status:**
   ```bash
   cast call $CONTRACT_RED_CODE_VETO \
     "isActiveRCA(address)" \
     $YOUR_ADDRESS
   ```

2. **Check term expiration:**
   ```bash
   cast call $CONTRACT_RED_CODE_VETO \
     "redCodeAuthorities(address)" \
     $YOUR_ADDRESS
   ```

3. **Request renewal:**
   - Contact GGC multisig
   - Submit renewal request
   - Await approval

---

## Conclusion

The IVBS Operational Guide provides comprehensive procedures for managing the Internodal Vacuum Backup System. For questions or issues not covered here, contact the GGC multisig or consult the [IVBS Specification](IVBS_SPECIFICATION.md).

**Remember:**
- Peace (Harmony): Non-coercive operations
- Help (Support): Community collaboration
- Protection (Security): Multi-layered validation

**Phase II Readiness: ✅ OPERATIONAL**

---

*Document Version: 1.0*  
*Last Updated: 2026-01-13*  
*Author: Euystacio Framework / IVBS Implementation Team*
