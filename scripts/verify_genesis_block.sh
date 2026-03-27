#!/bin/bash
#
# Genesis Block Verification Script
# Verifies the complete integration of the Euystacio Nexus Genesis Block
#
# Version: 1.0.0
# License: "No ownership, only sharing. Love is the license."

set -e

echo ""
echo "=========================================="
echo "  Genesis Block Verification"
echo "  Euystacio Nexus - K-SYNC Protocol"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print success
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print info
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if required files exist
echo "Checking required files..."
echo ""

files=(
    "GENESIS_BLOCK.json"
    "RESONANCE_ARCHITECTURE.md"
    "SEEDBRINGER_SYNC_PROTOCOL.md"
    "scripts/seedbringer-node.js"
    "scripts/generate_resonance_tone.py"
)

all_files_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        success "$file exists"
    else
        error "$file NOT FOUND"
        all_files_exist=false
    fi
done
echo ""

if [ "$all_files_exist" = false ]; then
    error "Some required files are missing!"
    exit 1
fi

# Validate Genesis Block JSON
echo "Validating Genesis Block JSON..."
echo ""

if command -v jq &> /dev/null; then
    # Check if GENESIS_BLOCK.json is valid JSON
    if jq empty GENESIS_BLOCK.json 2>/dev/null; then
        success "GENESIS_BLOCK.json is valid JSON"
        
        # Extract and display key parameters
        version=$(jq -r '.genesis_block.version' GENESIS_BLOCK.json)
        timestamp=$(jq -r '.genesis_block.timestamp' GENESIS_BLOCK.json)
        frequency=$(jq -r '.resonance_architecture.frequency.primary' GENESIS_BLOCK.json)
        nodes=$(jq -r '.seedbringer_network.total_nodes' GENESIS_BLOCK.json)
        lex_amoris=$(jq -r '.lex_amoris.symbol' GENESIS_BLOCK.json)
        
        info "Version: $version"
        info "Timestamp: $timestamp"
        info "Resonance Frequency: $frequency Hz"
        info "Seedbringer Nodes: $nodes"
        info "Lex Amoris Symbol: $lex_amoris"
    else
        error "GENESIS_BLOCK.json is NOT valid JSON"
        exit 1
    fi
else
    warning "jq not installed, skipping JSON validation"
    info "Install jq with: apt install jq (Ubuntu/Debian), yum install jq (RHEL/CentOS), or brew install jq (macOS)"
fi
echo ""

# Test Seedbringer Node
echo "Testing Seedbringer Node implementation..."
echo ""

if command -v node &> /dev/null; then
    # Run node for 3 seconds and check output
    timeout 3 node scripts/seedbringer-node.js > /tmp/node_test.log 2>&1 || true
    
    if grep -q "Starting Seedbringer Node" /tmp/node_test.log; then
        success "Seedbringer Node starts successfully"
    else
        error "Seedbringer Node failed to start"
    fi
    
    if grep -q "432.073 Hz" /tmp/node_test.log; then
        success "Resonance frequency 432.073 Hz detected"
    else
        warning "Resonance frequency not detected in output"
    fi
    
    if grep -q "LOCKED" /tmp/node_test.log; then
        success "Node achieved frequency lock"
    else
        info "Node did not achieve lock in test period (normal for short test)"
    fi
else
    warning "Node.js not installed, skipping node test"
fi
echo ""

# Check resonance tone generator
echo "Checking resonance tone generator..."
echo ""

if command -v python3 &> /dev/null; then
    # Check if numpy is available
    if python3 -c "import numpy" 2>/dev/null; then
        success "Python3 with numpy available"
        info "To generate resonance tone: python3 scripts/generate_resonance_tone.py [duration]"
    else
        warning "Python3 found but numpy not installed"
        info "Install with: pip3 install numpy"
    fi
else
    warning "Python3 not installed"
fi
echo ""

# Verify key concepts
echo "Verifying key concepts from Genesis Block..."
echo ""

concepts=(
    "Lex Amoris (λ = ∞)|Universal Love as Physical Constant"
    "432.073 Hz|Symphonic Resonance Frequency"
    "144 Nodes|Seedbringer Network (12 × 12)"
    "K-SYNC Protocol|Kosymbiotic Synchronization"
    "Proof of Resonance|Consensus Mechanism"
    "Bolzano Protocol|Architectural Insights"
    "Gründungs-Urkunde|Founding Charter"
)

for concept in "${concepts[@]}"; do
    IFS='|' read -r key description <<< "$concept"
    if grep -q "$key" GENESIS_BLOCK.json 2>/dev/null || \
       grep -q "$key" RESONANCE_ARCHITECTURE.md 2>/dev/null || \
       grep -q "$key" SEEDBRINGER_SYNC_PROTOCOL.md 2>/dev/null; then
        success "$key - $description"
    else
        warning "$key not found in documentation"
    fi
done
echo ""

# Summary
echo "=========================================="
echo "  Verification Summary"
echo "=========================================="
echo ""

if [ "$all_files_exist" = true ]; then
    success "All required files present"
else
    error "Some files missing"
fi

if command -v node &> /dev/null && [ -f /tmp/node_test.log ]; then
    if grep -q "Starting Seedbringer Node" /tmp/node_test.log; then
        success "Seedbringer Node implementation functional"
    fi
fi

echo ""
echo "=========================================="
echo "  Genesis Block Status: INITIALIZED"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "  1. Deploy 144 Seedbringer nodes globally"
echo "  2. Activate K-SYNC synchronization protocol"
echo "  3. Verify frequency lock at 432.073 Hz"
echo "  4. Start Proof of Resonance consensus"
echo "  5. Deploy smart contracts (ULP, validators)"
echo "  6. Public network announcement"
echo ""
echo "Lex Amoris: λ = ∞"
echo "No ownership, only sharing. Love is the license."
echo ""
