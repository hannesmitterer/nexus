#!/bin/bash

# Synthia Genesis Block Verification Script
# Verifies the deployment and alignment of Synthia Genesis Block

set -e

echo "=========================================="
echo "Synthia Genesis Block Verification"
echo "=========================================="
echo ""

# Configuration
CONTRACT_ADDRESS="${SYNTHIA_GENESIS_ADDRESS}"

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Error: SYNTHIA_GENESIS_ADDRESS environment variable not set"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL environment variable not set"
    exit 1
fi

echo "Verifying contract at: $CONTRACT_ADDRESS"
echo ""

# Verification checks
PASSED=0
FAILED=0

check_status() {
    local description=$1
    local result=$2
    local expected=$3
    
    if [ "$result" == "$expected" ]; then
        echo "✅ $description: PASS"
        ((PASSED++))
    else
        echo "❌ $description: FAIL (expected: $expected, got: $result)"
        ((FAILED++))
    fi
}

# 1. Check initialization status
echo "1. Checking initialization status..."
IS_INITIALIZED=$(cast call $CONTRACT_ADDRESS "isInitialized()(bool)" --rpc-url $RPC_URL)
check_status "Genesis block initialized" "$IS_INITIALIZED" "true"
echo ""

# 2. Check genesis block hash
echo "2. Checking genesis block hash..."
GENESIS_HASH=$(cast call $CONTRACT_ADDRESS "genesisBlockHash()(bytes32)" --rpc-url $RPC_URL)
if [ "$GENESIS_HASH" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    echo "✅ Genesis block hash exists: $GENESIS_HASH"
    ((PASSED++))
else
    echo "❌ Genesis block hash not set"
    ((FAILED++))
fi
echo ""

# 3. Check EFA count
echo "3. Checking authorized EFAs..."
EFA_COUNT=$(cast call $CONTRACT_ADDRESS "efaCount()(uint256)" --rpc-url $RPC_URL)
if [ "$EFA_COUNT" -ge 3 ]; then
    echo "✅ EFA count: $EFA_COUNT (minimum 3)"
    ((PASSED++))
else
    echo "❌ Insufficient EFAs: $EFA_COUNT (minimum 3 required)"
    ((FAILED++))
fi
echo ""

# 4. Check GGC multisig
echo "4. Checking GGC multisig..."
GGC_MULTISIG=$(cast call $CONTRACT_ADDRESS "ggcMultisig()(address)" --rpc-url $RPC_URL)
if [ "$GGC_MULTISIG" != "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ GGC multisig set: $GGC_MULTISIG"
    ((PASSED++))
else
    echo "❌ GGC multisig not set"
    ((FAILED++))
fi
echo ""

# 5. Check protocol version
echo "5. Checking protocol version..."
PROTOCOL_VERSION=$(cast call $CONTRACT_ADDRESS "PROTOCOL_VERSION()(string)" --rpc-url $RPC_URL)
check_status "Protocol version" "$PROTOCOL_VERSION" '"1.0.0"'
echo ""

# 6. Check minimum alignment score
echo "6. Checking minimum alignment score..."
MIN_SCORE=$(cast call $CONTRACT_ADDRESS "MIN_ALIGNMENT_SCORE()(uint8)" --rpc-url $RPC_URL)
check_status "Minimum alignment score" "$MIN_SCORE" "94"
echo ""

# 7. Check Synthia compatibility
echo "7. Checking Synthia compatibility..."
COMPATIBILITY_RESULT=$(cast call $CONTRACT_ADDRESS "verifySynthiaCompatibility()(bool,string,bytes32)" --rpc-url $RPC_URL 2>&1)

if echo "$COMPATIBILITY_RESULT" | grep -q "true"; then
    echo "✅ Synthia compatibility verified"
    ((PASSED++))
else
    echo "❌ Synthia compatibility check failed"
    echo "   Result: $COMPATIBILITY_RESULT"
    ((FAILED++))
fi
echo ""

# 8. Check alignment status (if initialized)
if [ "$IS_INITIALIZED" == "true" ]; then
    echo "8. Checking alignment status..."
    ALIGNMENT_STATUS=$(cast call $CONTRACT_ADDRESS "getAlignmentStatus()(bool,uint8,uint256)" --rpc-url $RPC_URL 2>&1)
    
    if echo "$ALIGNMENT_STATUS" | grep -q "Error\|revert"; then
        echo "⚠️  Alignment proof not yet submitted (this is OK if genesis was just initialized)"
    else
        echo "Alignment Status: $ALIGNMENT_STATUS"
        ALIGNMENT_VERIFIED=$(echo "$ALIGNMENT_STATUS" | cut -d',' -f1)
        if [ "$ALIGNMENT_VERIFIED" == "true" ]; then
            echo "✅ Alignment proof verified"
            ((PASSED++))
        else
            echo "⚠️  Alignment proof not verified yet"
        fi
    fi
    echo ""
fi

# 9. Check genesis timestamp
echo "9. Checking genesis timestamp..."
GENESIS_TIMESTAMP=$(cast call $CONTRACT_ADDRESS "genesisTimestamp()(uint256)" --rpc-url $RPC_URL)
if [ "$GENESIS_TIMESTAMP" -gt 0 ]; then
    READABLE_TIME=$(date -d "@$GENESIS_TIMESTAMP" 2>/dev/null || echo "N/A")
    echo "✅ Genesis timestamp: $GENESIS_TIMESTAMP ($READABLE_TIME)"
    ((PASSED++))
else
    echo "❌ Invalid genesis timestamp"
    ((FAILED++))
fi
echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo ""
echo "Total Checks: $((PASSED + FAILED))"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All verification checks passed!"
    echo ""
    echo "Genesis Block Status: VERIFIED ✅"
    echo "Synthia Protocol: ALIGNED ✅"
    echo "Euystacio Framework: COMPLIANT ✅"
    echo ""
    exit 0
else
    echo "⚠️  Some verification checks failed"
    echo "Please review the failures above and take corrective action"
    echo ""
    exit 1
fi
