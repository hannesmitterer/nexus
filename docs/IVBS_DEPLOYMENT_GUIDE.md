# IVBS Deployment Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2026-01-13  
**Framework:** Euystacio / SAIN Protocol / GGI

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Contract Deployment Order](#contract-deployment-order)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Integration with Existing Systems](#integration-with-existing-systems)
6. [Post-Deployment Checklist](#post-deployment-checklist)

---

## Prerequisites

### Required

- Solidity compiler version: ^0.8.20
- Ethereum-compatible network (Polygon mainnet recommended)
- GGC multisig wallet deployed and configured
- Minimum 5 Red Code Authorities identified
- EFA validator addresses ready
- IPFS infrastructure operational

### Tools

```bash
# Install required tools
npm install -g @foundry-rs/foundry
npm install -g hardhat
```

### Environment Setup

```bash
# Set environment variables
export POLYGON_RPC="https://polygon-rpc.com"
export DEPLOYER_PRIVATE_KEY="0x..."
export GGC_MULTISIG="0x..."
export TECHNICAL_VALIDATOR="0x..."
```

---

## Contract Deployment Order

### Step 1: Deploy Red Code Veto Contract

```bash
# Deploy IVBS_RedCodeVeto
forge create contracts/IVBS_RedCodeVeto.sol:IVBS_RedCodeVeto \
  --constructor-args $GGC_MULTISIG \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Save the deployed address
export RED_CODE_VETO="0x..."
```

**Verify deployment:**
```bash
cast call $RED_CODE_VETO "ggcMultisig()" --rpc-url $POLYGON_RPC
# Should return: $GGC_MULTISIG
```

### Step 2: Deploy Triple-Sign Validation Contract

```bash
# Deploy IVBS_TripleSignValidation
forge create contracts/IVBS_TripleSignValidation.sol:IVBS_TripleSignValidation \
  --constructor-args $TECHNICAL_VALIDATOR $GGC_MULTISIG $RED_CODE_VETO \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Save the deployed address
export TRIPLE_SIGN="0x..."
```

**Verify deployment:**
```bash
cast call $TRIPLE_SIGN "technicalValidator()" --rpc-url $POLYGON_RPC
# Should return: $TECHNICAL_VALIDATOR

cast call $TRIPLE_SIGN "ggcMultisig()" --rpc-url $POLYGON_RPC
# Should return: $GGC_MULTISIG

cast call $TRIPLE_SIGN "redCodeVetoContract()" --rpc-url $POLYGON_RPC
# Should return: $RED_CODE_VETO
```

### Step 3: Deploy Vacuum Anchor Contract

```bash
# Deploy IVBS_VacuumAnchor
forge create contracts/IVBS_VacuumAnchor.sol:IVBS_VacuumAnchor \
  --constructor-args $TRIPLE_SIGN $GGC_MULTISIG \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Save the deployed address
export VACUUM_ANCHOR="0x..."
```

**Verify deployment:**
```bash
cast call $VACUUM_ANCHOR "tripleSignContract()" --rpc-url $POLYGON_RPC
# Should return: $TRIPLE_SIGN

cast call $VACUUM_ANCHOR "ggcMultisig()" --rpc-url $POLYGON_RPC
# Should return: $GGC_MULTISIG
```

### Step 4: Deploy Integration Contract

```bash
# Get TFKVerifier address (existing contract)
export TFK_VERIFIER="0x..."

# Deploy IVBS_Integration
forge create contracts/IVBS_Integration.sol:IVBS_Integration \
  --constructor-args $RED_CODE_VETO $TRIPLE_SIGN $VACUUM_ANCHOR $TFK_VERIFIER $GGC_MULTISIG \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Save the deployed address
export IVBS_INTEGRATION="0x..."
```

**Verify deployment:**
```bash
cast call $IVBS_INTEGRATION "redCodeVeto()" --rpc-url $POLYGON_RPC
# Should return: $RED_CODE_VETO

cast call $IVBS_INTEGRATION "tripleSignValidation()" --rpc-url $POLYGON_RPC
# Should return: $TRIPLE_SIGN

cast call $IVBS_INTEGRATION "vacuumAnchor()" --rpc-url $POLYGON_RPC
# Should return: $VACUUM_ANCHOR

cast call $IVBS_INTEGRATION "tfkVerifier()" --rpc-url $POLYGON_RPC
# Should return: $TFK_VERIFIER
```

---

## Configuration

### Appoint Red Code Authorities

You need to appoint at least 5 RCAs with geographic diversity.

```bash
# Prepare RCA list
RCA_1="0x..."  # North America
RCA_2="0x..."  # Europe
RCA_3="0x..."  # Asia
RCA_4="0x..."  # South America
RCA_5="0x..."  # Africa/Oceania

# Appoint each RCA (requires GGC multisig)
cast send $RED_CODE_VETO \
  "appointRCA(address,string,string)" \
  $RCA_1 \
  "North America RCA" \
  "North America" \
  --from $GGC_MULTISIG \
  --rpc-url $POLYGON_RPC

# Repeat for RCA_2 through RCA_5
```

**Verify RCA appointments:**
```bash
cast call $RED_CODE_VETO "activeRCACount()" --rpc-url $POLYGON_RPC
# Should return: 5 (or more)

cast call $RED_CODE_VETO "isActiveRCA(address)" $RCA_1 --rpc-url $POLYGON_RPC
# Should return: true
```

### Configure IPFS Environment

```bash
# Update environment variables for IVBS operations
cat >> ~/.bashrc << EOF
# IVBS Configuration
export IPFS_GATEWAY="https://ipfs.io/ipfs"
export PINATA_API_KEY="your_pinata_api_key"
export WEB3_STORAGE_TOKEN="your_web3storage_token"
export INFURA_PROJECT_ID="your_infura_project_id"
export CONTRACT_VACUUM_ANCHOR="$VACUUM_ANCHOR"
export CONTRACT_TRIPLE_SIGN="$TRIPLE_SIGN"
export CONTRACT_RED_CODE_VETO="$RED_CODE_VETO"
export CONTRACT_IVBS_INTEGRATION="$IVBS_INTEGRATION"
EOF

source ~/.bashrc
```

### Test IPFS Operations Script

```bash
# Run health check
./scripts/ivbs_operations.sh health-check

# Expected output:
# ✓ IPFS daemon running
# ✓ Pinata configured
# ✓ Web3.Storage configured
# ✓ All contracts configured
```

---

## Verification

### Contract Verification on Block Explorer

**Polygon PolygonScan:**

```bash
# Verify Red Code Veto
forge verify-contract $RED_CODE_VETO \
  contracts/IVBS_RedCodeVeto.sol:IVBS_RedCodeVeto \
  --chain-id 137 \
  --constructor-args $(cast abi-encode "constructor(address)" $GGC_MULTISIG) \
  --etherscan-api-key $POLYGONSCAN_API_KEY

# Verify Triple-Sign Validation
forge verify-contract $TRIPLE_SIGN \
  contracts/IVBS_TripleSignValidation.sol:IVBS_TripleSignValidation \
  --chain-id 137 \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" $TECHNICAL_VALIDATOR $GGC_MULTISIG $RED_CODE_VETO) \
  --etherscan-api-key $POLYGONSCAN_API_KEY

# Verify Vacuum Anchor
forge verify-contract $VACUUM_ANCHOR \
  contracts/IVBS_VacuumAnchor.sol:IVBS_VacuumAnchor \
  --chain-id 137 \
  --constructor-args $(cast abi-encode "constructor(address,address)" $TRIPLE_SIGN $GGC_MULTISIG) \
  --etherscan-api-key $POLYGONSCAN_API_KEY

# Verify Integration
forge verify-contract $IVBS_INTEGRATION \
  contracts/IVBS_Integration.sol:IVBS_Integration \
  --chain-id 137 \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address,address)" $RED_CODE_VETO $TRIPLE_SIGN $VACUUM_ANCHOR $TFK_VERIFIER $GGC_MULTISIG) \
  --etherscan-api-key $POLYGONSCAN_API_KEY
```

### Functional Testing

**Test 1: Create Triple-Sign Request**
```bash
# Create test request
TEST_DATA_HASH=$(echo -n "test_data" | keccak256)

cast send $TRIPLE_SIGN \
  "createTripleSignRequest(bytes32,string)" \
  $TEST_DATA_HASH \
  "TEST_REQUEST" \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Verify creation
REQUEST_COUNT=$(cast call $TRIPLE_SIGN "requestCount()" --rpc-url $POLYGON_RPC)
echo "Request count: $REQUEST_COUNT"
# Should be > 0
```

**Test 2: Submit Red Code Veto**
```bash
# Create test proposal
TEST_PROPOSAL_ID=1

# Sign veto message (as RCA)
MESSAGE="Proposal_${TEST_PROPOSAL_ID}_VETO_Test"
SIGNATURE=$(cast wallet sign "$MESSAGE" --private-key $RCA_1_PRIVATE_KEY)

# Submit veto
cast send $RED_CODE_VETO \
  "submitRedCodeVeto(uint256,string,bytes)" \
  $TEST_PROPOSAL_ID \
  "Test veto reason" \
  "$SIGNATURE" \
  --private-key $RCA_1_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Verify veto
IS_VETOED=$(cast call $RED_CODE_VETO "isProposalVetoed(uint256)" $TEST_PROPOSAL_ID --rpc-url $POLYGON_RPC)
echo "Proposal vetoed: $IS_VETOED"
# Should return: true
```

**Test 3: Create Vacuum Anchor**
```bash
# First, create and approve a Triple-Sign request
# (This requires going through all three validation tiers)

# For testing, we'll create a minimal anchor after approval
TEST_CID=$(echo -n "QmTestCID..." | keccak256)
TEST_HASH=$(echo -n "test_content" | sha256sum | awk '{print $1}')

# This will fail without Triple-Sign approval (expected)
cast send $VACUUM_ANCHOR \
  "createVacuumAnchor(bytes32,uint8,uint256,string,bytes32,uint256)" \
  $TEST_CID \
  0 \
  1 \
  "Test anchor" \
  "0x$TEST_HASH" \
  1024 \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $POLYGON_RPC
```

---

## Integration with Existing Systems

### TFKVerifier Integration

The IVBS system integrates with the existing TFKVerifier contract through the `IVBS_Integration` contract.

**Update TFKVerifier to use IVBS:**

If you need to modify TFKVerifier to check IVBS approval before executing proposals, add this logic:

```solidity
// In TFKVerifier.sol
function executeProposal(uint256 proposalId) external {
    // ... existing checks ...
    
    // Check IVBS approval
    require(
        ivbsIntegration.verifyProposalIVBSApproval(proposalId),
        "IVBS approval required"
    );
    
    // ... existing execution logic ...
}
```

### K-SYNC Integration

Update K-SYNC coordinator to create Vacuum Anchors before broadcasting updates:

```javascript
// In K-SYNC coordinator
async function broadcastModelUpdate(modelCID) {
    // 1. Create Triple-Sign request
    const tripleSignRequestId = await createTripleSignRequest(modelCID);
    
    // 2. Wait for Triple-Sign approval
    await waitForTripleSignApproval(tripleSignRequestId);
    
    // 3. Create Vacuum Anchor
    const anchorId = await createVacuumAnchor(modelCID, tripleSignRequestId);
    
    // 4. Broadcast update to SANs
    await broadcastUpdate(modelCID, anchorId);
}
```

### Dashboard Integration

Add IVBS monitoring to the Sensisara Dashboard:

**API Endpoints:**
```javascript
// GET /api/ivbs/status
app.get('/api/ivbs/status', async (req, res) => {
    const stats = await vacuumAnchor.getSystemStats();
    const rcaCount = await redCodeVeto.activeRCACount();
    
    res.json({
        vacuum_anchors: {
            total: stats.totalAnchors,
            by_type: {
                STATE: stats.stateAnchors,
                GOVERNANCE: stats.governanceAnchors,
                MODEL: stats.modelAnchors
            }
        },
        red_code_authorities: rcaCount,
        triple_sign_pending: await getPendingTripleSignRequests()
    });
});
```

---

## Post-Deployment Checklist

### Immediate (Day 1)

- [ ] All contracts deployed and verified on block explorer
- [ ] Minimum 5 RCAs appointed and verified
- [ ] Technical validator configured and operational
- [ ] GGC multisig has control of all contracts
- [ ] IPFS infrastructure tested and operational
- [ ] Health check passes successfully

### Week 1

- [ ] Create test Vacuum Anchor for each type (STATE, GOVERNANCE, MODEL)
- [ ] Test complete Triple-Sign workflow (Technical → Governance → Ethical)
- [ ] Test Red Code Veto submission and verification
- [ ] Integrate IVBS with TFKVerifier (if applicable)
- [ ] Update dashboard with IVBS monitoring widgets
- [ ] Document all deployed contract addresses

### Month 1

- [ ] Create first production Vacuum Anchor for system state
- [ ] Establish automated health check cron job
- [ ] Train EFAs and RCAs on IVBS operational procedures
- [ ] Conduct security audit of IVBS contracts
- [ ] Monitor redundancy levels across all anchors
- [ ] Review and optimize IPFS pinning strategy

### Ongoing

- [ ] Weekly: Review anchor verification status
- [ ] Monthly: Audit RCA activity and veto patterns
- [ ] Quarterly: Review and renew RCA terms
- [ ] Annually: Comprehensive security audit

---

## Contract Addresses (Template)

Save these addresses for reference:

```bash
# IVBS Core Contracts
RED_CODE_VETO=0x...
TRIPLE_SIGN_VALIDATION=0x...
VACUUM_ANCHOR=0x...
IVBS_INTEGRATION=0x...

# Existing Contracts
TFK_VERIFIER=0x...
GGC_MULTISIG=0x...
TECHNICAL_VALIDATOR=0x...

# Red Code Authorities
RCA_1=0x...  # North America
RCA_2=0x...  # Europe
RCA_3=0x...  # Asia
RCA_4=0x...  # South America
RCA_5=0x...  # Africa/Oceania
```

---

## Troubleshooting

### Issue: Contract deployment fails

**Symptoms:** Transaction reverts during deployment

**Solutions:**
1. Check gas price and limit
2. Verify constructor arguments are correct
3. Ensure deployer has sufficient balance
4. Check Solidity version matches (^0.8.20)

### Issue: RCA appointment fails

**Symptoms:** `appointRCA` transaction reverts

**Solutions:**
1. Verify caller is GGC multisig
2. Check RCA address is not already appointed
3. Ensure RCA address is valid (not zero address)

### Issue: Triple-Sign creation fails

**Symptoms:** `createTripleSignRequest` reverts

**Solutions:**
1. Verify data hash is not zero
2. Check no existing request for same data hash
3. Ensure caller has necessary permissions

---

## Conclusion

Following this deployment guide ensures the IVBS system is properly deployed, configured, and integrated with existing Euystacio Framework components. For operational procedures, refer to the [IVBS Operational Guide](IVBS_OPERATIONAL_GUIDE.md).

**Phase II Readiness: ✅ OPERATIONAL**

---

*Document Version: 1.0*  
*Last Updated: 2026-01-13*  
*Author: Euystacio Framework / IVBS Implementation Team*
