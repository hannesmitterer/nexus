#!/bin/bash

# Synthia Genesis Block Initialization Script
# This script initializes the Synthia Genesis Block with proper alignment parameters

set -e

echo "=========================================="
echo "Synthia Genesis Block Initialization"
echo "=========================================="
echo ""

# Configuration
CONFIG_FILE="synthia_genesis_config.json"
CONTRACT_ADDRESS="${SYNTHIA_GENESIS_ADDRESS}"
GGC_MULTISIG="${GGC_MULTISIG}"
ALIGNMENT_VERIFIER="${ALIGNMENT_VERIFIER}"

# Check prerequisites
if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Error: SYNTHIA_GENESIS_ADDRESS environment variable not set"
    exit 1
fi

if [ -z "$GGC_MULTISIG" ]; then
    echo "Error: GGC_MULTISIG environment variable not set"
    exit 1
fi

if [ -z "$ALIGNMENT_VERIFIER" ]; then
    echo "Error: ALIGNMENT_VERIFIER environment variable not set"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found"
    exit 1
fi

echo "Configuration loaded:"
echo "  Contract Address: $CONTRACT_ADDRESS"
echo "  GGC Multisig: $GGC_MULTISIG"
echo "  Alignment Verifier: $ALIGNMENT_VERIFIER"
echo ""

# Load EFA addresses from config
EFA_ALPHA=$(jq -r '.initial_validators.addresses[0].address // ""' $CONFIG_FILE)
EFA_BETA=$(jq -r '.initial_validators.addresses[1].address // ""' $CONFIG_FILE)
EFA_GAMMA=$(jq -r '.initial_validators.addresses[2].address // ""' $CONFIG_FILE)

# Validate EFA addresses are configured
if [ -z "$EFA_ALPHA" ] || [ -z "$EFA_BETA" ] || [ -z "$EFA_GAMMA" ]; then
    echo "Error: EFA addresses not configured in $CONFIG_FILE"
    echo "Please add valid EFA addresses to initial_validators.addresses in the config file"
    exit 1
fi

# Validate addresses are valid Ethereum addresses (basic check)
if [[ ! "$EFA_ALPHA" =~ ^0x[0-9a-fA-F]{40}$ ]] || [[ ! "$EFA_BETA" =~ ^0x[0-9a-fA-F]{40}$ ]] || [[ ! "$EFA_GAMMA" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo "Error: Invalid EFA address format"
    echo "Addresses must be valid Ethereum addresses (0x + 40 hex characters)"
    exit 1
fi

echo "Initial EFA Validators:"
echo "  EFA-ALPHA: $EFA_ALPHA"
echo "  EFA-BETA:  $EFA_BETA"
echo "  EFA-GAMMA: $EFA_GAMMA"
echo ""

# Compute hashes
echo "Computing alignment hashes..."

SENTIMENTO_HASH=$(cast keccak "Sentimento Rhythm Alignment Proof - Life Continuity - Universal Flourishing")
FRAMEWORK_HASH=$(cast keccak "Euystacio Framework v1.0 - GGI - AIC - EFA")
SAIN_HASH=$(cast keccak "SAIN Protocol V1.0 - Dynasty Axiom - VCE - Friction Veto")

echo "  Sentimento Hash: $SENTIMENTO_HASH"
echo "  Framework Hash:  $FRAMEWORK_HASH"
echo "  SAIN Hash:       $SAIN_HASH"
echo ""

# Get current timestamp
TIMESTAMP=$(date +%s)

# Alignment score (KOSYMBIOSIS standard: 94/100)
ALIGNMENT_SCORE=94

echo "Genesis Parameters:"
echo "  Timestamp: $TIMESTAMP"
echo "  Alignment Score: $ALIGNMENT_SCORE"
echo ""

# Check if already initialized
echo "Checking initialization status..."
IS_INITIALIZED=$(cast call $CONTRACT_ADDRESS "isInitialized()(bool)" --rpc-url $RPC_URL)

if [ "$IS_INITIALIZED" == "true" ]; then
    echo "Warning: Genesis block is already initialized!"
    echo "Skipping initialization..."
else
    echo "Initializing Genesis Block..."
    echo ""
    echo "⚠️  This operation requires GGC multisig approval"
    echo "Please ensure this transaction is submitted through the multisig wallet"
    echo ""
    
    # Prepare initialization call data
    INIT_CALLDATA=$(cast calldata "initializeGenesisBlock((bytes32,bytes32,bytes32,uint256,address[],uint8),address)" \
        "($SENTIMENTO_HASH,$FRAMEWORK_HASH,$SAIN_HASH,$TIMESTAMP,[$EFA_ALPHA,$EFA_BETA,$EFA_GAMMA],$ALIGNMENT_SCORE)" \
        "$ALIGNMENT_VERIFIER")
    
    echo "Initialization call data generated:"
    echo "$INIT_CALLDATA"
    echo ""
    echo "Submit this transaction to the GGC multisig to initialize the genesis block"
    echo ""
fi

# Verify deployment
echo "=========================================="
echo "Verifying Genesis Block Status"
echo "=========================================="
echo ""

# Get genesis info
GENESIS_HASH=$(cast call $CONTRACT_ADDRESS "genesisBlockHash()(bytes32)" --rpc-url $RPC_URL)
GENESIS_TIMESTAMP=$(cast call $CONTRACT_ADDRESS "genesisTimestamp()(uint256)" --rpc-url $RPC_URL)
EFA_COUNT=$(cast call $CONTRACT_ADDRESS "efaCount()(uint256)" --rpc-url $RPC_URL)

echo "Genesis Block Information:"
echo "  Hash: $GENESIS_HASH"
echo "  Timestamp: $GENESIS_TIMESTAMP"
echo "  Initialized: $IS_INITIALIZED"
echo "  EFA Count: $EFA_COUNT"
echo ""

# Check Synthia compatibility
COMPATIBILITY=$(cast call $CONTRACT_ADDRESS "verifySynthiaCompatibility()(bool,string,bytes32)" --rpc-url $RPC_URL)

echo "Synthia Compatibility Check:"
echo "  Result: $COMPATIBILITY"
echo ""

echo "=========================================="
echo "Initialization Complete"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Submit alignment proof using submitAlignmentProof()"
echo "2. Verify alignment status"
echo "3. Integrate with existing nexus contracts"
echo ""
