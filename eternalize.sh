#!/bin/bash

# ==============================================================================
# IPFS and Pinata Framework Eternalization Script
# ==============================================================================
# This script automates the workflow for eternalizing frameworks using IPFS
# and Pinata. It performs the following steps:
# 1. Checks for and installs IPFS CLI if needed
# 2. Initializes IPFS and starts the daemon
# 3. Adds the documentation folder to IPFS
# 4. Pins the resulting CID to Pinata
# ==============================================================================

set -eo pipefail  # Exit on error and propagate pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="docs"
IPFS_VERSION="v0.27.0"
IPFS_DOWNLOAD_URL="https://dist.ipfs.tech/kubo/${IPFS_VERSION}/kubo_${IPFS_VERSION}_linux-amd64.tar.gz"

# ==============================================================================
# Helper Functions
# ==============================================================================

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ==============================================================================
# Check Prerequisites
# ==============================================================================

check_pinata_jwt() {
    print_status "Checking for PINATA_JWT environment variable..."
    if [ -z "$PINATA_JWT" ]; then
        print_error "PINATA_JWT environment variable is not set."
        echo "Please export your Pinata JWT token:"
        echo "  export PINATA_JWT=\"your_pinata_jwt_token\""
        exit 1
    fi
    print_success "PINATA_JWT is set."
}

check_docs_directory() {
    print_status "Checking for documentation directory..."
    if [ ! -d "$DOCS_DIR" ]; then
        print_error "Documentation directory '$DOCS_DIR' not found."
        echo "Please create a 'docs/' directory in the repository root and add your documentation."
        exit 1
    fi
    
    if [ -z "$(ls -A "$DOCS_DIR")" ]; then
        print_error "Documentation directory '$DOCS_DIR' is empty."
        echo "Please add documentation files to the 'docs/' directory."
        exit 1
    fi
    
    print_success "Documentation directory found and contains files."
}

# ==============================================================================
# IPFS CLI Installation
# ==============================================================================

check_ipfs_installed() {
    if command -v ipfs &> /dev/null; then
        print_success "IPFS CLI is already installed ($(ipfs --version))."
        return 0
    else
        return 1
    fi
}

install_ipfs() {
    print_status "IPFS CLI not found. Installing IPFS CLI..."
    
    # Create temporary directory for download
    TMP_DIR=$(mktemp -d)
    ORIGINAL_DIR=$(pwd)
    cd "$TMP_DIR"
    
    print_status "Downloading IPFS CLI ${IPFS_VERSION}..."
    
    # Try wget first, then curl as fallback
    if command -v wget &> /dev/null; then
        if ! wget -q --show-progress "$IPFS_DOWNLOAD_URL"; then
            print_error "Failed to download IPFS CLI using wget."
            cd "$ORIGINAL_DIR"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        if ! curl -L -o "kubo_${IPFS_VERSION}_linux-amd64.tar.gz" "$IPFS_DOWNLOAD_URL"; then
            print_error "Failed to download IPFS CLI using curl."
            cd "$ORIGINAL_DIR"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    else
        print_error "Neither wget nor curl is available. Cannot download IPFS CLI."
        cd "$ORIGINAL_DIR"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    print_status "Extracting IPFS CLI..."
    tar -xzf "kubo_${IPFS_VERSION}_linux-amd64.tar.gz"
    
    print_status "Installing IPFS CLI..."
    cd kubo
    if ! sudo bash install.sh; then
        print_error "Failed to install IPFS CLI. You may need sudo privileges."
        cd "$ORIGINAL_DIR"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Return to original directory and clean up
    cd "$ORIGINAL_DIR"
    rm -rf "$TMP_DIR"
    
    if command -v ipfs &> /dev/null; then
        print_success "IPFS CLI installed successfully ($(ipfs --version))."
    else
        print_error "IPFS CLI installation verification failed."
        exit 1
    fi
}

# ==============================================================================
# IPFS Daemon Management
# ==============================================================================

initialize_ipfs() {
    print_status "Checking IPFS initialization..."
    
    if [ -d "$HOME/.ipfs" ]; then
        print_success "IPFS repository already initialized."
    else
        print_status "Initializing IPFS repository..."
        if ! ipfs init; then
            print_error "Failed to initialize IPFS repository."
            exit 1
        fi
        print_success "IPFS repository initialized successfully."
    fi
}

start_ipfs_daemon() {
    print_status "Checking IPFS daemon status..."
    
    # Check if daemon is already running
    if ipfs swarm peers &> /dev/null; then
        print_success "IPFS daemon is already running."
        return 0
    fi
    
    print_status "Starting IPFS daemon..."
    print_warning "This may take a few moments..."
    
    # Create secure temporary log file
    DAEMON_LOG=$(mktemp)
    export DAEMON_LOG
    
    # Start daemon in background
    ipfs daemon &> "$DAEMON_LOG" &
    IPFS_DAEMON_PID=$!
    
    # Wait for daemon to be ready
    print_status "Waiting for IPFS daemon to start..."
    RETRY_COUNT=0
    MAX_RETRIES=30
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if ipfs swarm peers &> /dev/null; then
            print_success "IPFS daemon started successfully (PID: $IPFS_DAEMON_PID)."
            return 0
        fi
        sleep 1
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done
    
    print_error "IPFS daemon failed to start within expected time."
    print_error "Check logs at $DAEMON_LOG for details."
    exit 1
}

# ==============================================================================
# Add Documentation to IPFS
# ==============================================================================

add_docs_to_ipfs() {
    print_status "Adding documentation folder to IPFS..."
    print_status "Processing: $DOCS_DIR"
    
    # Add directory recursively and capture output
    if ! IPFS_OUTPUT=$(ipfs add -r "$DOCS_DIR" 2>&1); then
        print_error "Failed to add documentation to IPFS."
        echo "$IPFS_OUTPUT"
        exit 1
    fi
    
    # Extract the CID of the root directory (last line of output)
    CID=$(echo "$IPFS_OUTPUT" | tail -n 1 | awk '{print $2}')
    
    if [ -z "$CID" ]; then
        print_error "Failed to extract CID from IPFS output."
        echo "$IPFS_OUTPUT"
        exit 1
    fi
    
    print_success "Documentation added to IPFS successfully."
    print_success "Root CID: $CID"
    echo ""
    echo "IPFS Gateway URLs:"
    echo "  - https://ipfs.io/ipfs/$CID"
    echo "  - https://gateway.pinata.cloud/ipfs/$CID"
    echo ""
    
    # Export CID for use in pinning
    export DOCS_CID="$CID"
}

# ==============================================================================
# Pin to Pinata
# ==============================================================================

pin_to_pinata() {
    print_status "Pinning CID to Pinata..."
    
    if [ -z "$DOCS_CID" ]; then
        print_error "No CID available to pin."
        exit 1
    fi
    
    # Create JSON payload for Pinata API
    PINATA_PAYLOAD=$(cat <<EOF
{
  "hashToPin": "$DOCS_CID",
  "pinataMetadata": {
    "name": "nexus-docs-$(date +%Y%m%d-%H%M%S)"
  }
}
EOF
)
    
    print_status "Sending pin request to Pinata..."
    
    # Make API request to Pinata and capture both response and HTTP status
    HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        "https://api.pinata.cloud/pinning/pinByHash" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $PINATA_JWT" \
        -d "$PINATA_PAYLOAD")
    
    # Extract HTTP status code (last line) and response body (everything else)
    HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 1)
    PINATA_RESPONSE=$(echo "$HTTP_RESPONSE" | sed '$d')
    
    # Check HTTP status code
    if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        if echo "$PINATA_RESPONSE" | grep -q "ipfsHash"; then
            print_success "Successfully pinned to Pinata!"
            echo "Response: $PINATA_RESPONSE"
        else
            print_warning "Pinata request succeeded but response format unexpected."
            echo "Response: $PINATA_RESPONSE"
        fi
    else
        print_error "Failed to pin to Pinata (HTTP $HTTP_STATUS)."
        echo "Response: $PINATA_RESPONSE"
        exit 1
    fi
}

# ==============================================================================
# Cleanup
# ==============================================================================

cleanup() {
    print_status "Cleaning up..."
    
    # Clean up daemon log file if it exists
    if [ -n "$DAEMON_LOG" ] && [ -f "$DAEMON_LOG" ]; then
        rm -f "$DAEMON_LOG"
    fi
    
    # Daemon will continue running in background
    # User can stop it manually with: ipfs shutdown
    print_success "Script completed."
    echo ""
    echo "Note: IPFS daemon is still running in the background."
    echo "To stop it, run: ipfs shutdown"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    echo "===================================================================="
    echo "  IPFS and Pinata Framework Eternalization Script"
    echo "===================================================================="
    echo ""
    
    # Step 1: Check prerequisites
    check_pinata_jwt
    check_docs_directory
    
    # Step 2: Install IPFS if needed
    if ! check_ipfs_installed; then
        install_ipfs
    fi
    
    # Step 3: Initialize IPFS
    initialize_ipfs
    
    # Step 4: Start IPFS daemon
    start_ipfs_daemon
    
    # Step 5: Add documentation to IPFS
    add_docs_to_ipfs
    
    # Step 6: Pin to Pinata
    pin_to_pinata
    
    echo ""
    echo "===================================================================="
    echo "  Eternalization Complete!"
    echo "===================================================================="
    echo "  Your documentation is now eternalized on IPFS and pinned to Pinata."
    echo "  CID: $DOCS_CID"
    echo "===================================================================="
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Run main function
main
