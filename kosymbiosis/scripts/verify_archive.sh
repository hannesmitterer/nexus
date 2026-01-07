#!/bin/bash
#
# KOSYMBIOSIS Archive Verification Script
#
# This script verifies the integrity and authenticity of the KOSYMBIOSIS archive
# using SHA-256 checksums and GPG signatures.
#
# Usage: ./verify_archive.sh [path-to-archive.zip]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default archive name
ARCHIVE_FILE="${1:-kosymbiosis-archive.zip}"

echo "================================================"
echo "KOSYMBIOSIS Archive Verification Script"
echo "================================================"
echo ""
echo "Archive file: $ARCHIVE_FILE"
echo ""

# Check if archive exists
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "ERROR: Archive file not found: $ARCHIVE_FILE"
    echo ""
    echo "Usage: $0 [path-to-archive.zip]"
    exit 1
fi

# Check if checksum file exists
CHECKSUM_FILE="checksum.sha256"
if [ ! -f "$CHECKSUM_FILE" ]; then
    echo "WARNING: Checksum file not found: $CHECKSUM_FILE"
    echo "Attempting to locate checksum file..."
    
    # Try alternate locations
    if [ -f "$PROJECT_ROOT/checksum.sha256" ]; then
        CHECKSUM_FILE="$PROJECT_ROOT/checksum.sha256"
        echo "Found checksum file: $CHECKSUM_FILE"
    else
        echo "ERROR: Cannot locate checksum file"
        exit 1
    fi
fi

echo "[1/4] Verifying SHA-256 checksum..."
echo ""

# Verify checksum
if sha256sum -c "$CHECKSUM_FILE"; then
    echo ""
    echo "✓ Checksum verification PASSED"
else
    echo ""
    echo "✗ Checksum verification FAILED"
    echo "ERROR: Archive integrity cannot be verified!"
    exit 1
fi

echo ""
echo "[2/4] Checking for GPG signatures..."
echo ""

# Check for signature files
SIGNATURES_FOUND=0
SIGNATURES_VERIFIED=0

SIG_FILES=(
    "signatures/kosymbiosis.sig"
    "signatures/kosymbiosis-co1.sig"
    "signatures/kosymbiosis-co2.sig"
)

for sig_file in "${SIG_FILES[@]}"; do
    if [ -f "$sig_file" ] || [ -f "$PROJECT_ROOT/$sig_file" ]; then
        SIGNATURES_FOUND=$((SIGNATURES_FOUND + 1))
    fi
done

echo "Found $SIGNATURES_FOUND of 3 required signatures"
echo ""

if [ $SIGNATURES_FOUND -eq 0 ]; then
    echo "WARNING: No signature files found"
    echo "Signature files should be placed in: signatures/"
    echo ""
    echo "Archive integrity verified by checksum only."
    echo "For full verification, obtain and verify GPG signatures."
    exit 0
fi

echo "[3/4] Verifying GPG signatures..."
echo ""

# Verify each signature
for sig_file in "${SIG_FILES[@]}"; do
    # Try both relative and absolute paths
    if [ -f "$sig_file" ]; then
        SIG_PATH="$sig_file"
    elif [ -f "$PROJECT_ROOT/$sig_file" ]; then
        SIG_PATH="$PROJECT_ROOT/$sig_file"
    else
        continue
    fi
    
    echo "Verifying: $sig_file"
    
    if gpg --verify "$SIG_PATH" "$ARCHIVE_FILE" 2>&1; then
        echo "✓ Signature verified: $sig_file"
        SIGNATURES_VERIFIED=$((SIGNATURES_VERIFIED + 1))
    else
        echo "✗ Signature verification failed: $sig_file"
    fi
    echo ""
done

echo "[4/4] Final verification report..."
echo ""
echo "================================================"
echo "Verification Summary"
echo "================================================"
echo ""
echo "Checksum: ✓ VERIFIED"
echo "Signatures found: $SIGNATURES_FOUND / 3"
echo "Signatures verified: $SIGNATURES_VERIFIED / $SIGNATURES_FOUND"
echo ""

if [ $SIGNATURES_VERIFIED -eq 3 ]; then
    echo "✓ FULL VERIFICATION COMPLETE"
    echo ""
    echo "All three signatures verified successfully."
    echo "Archive integrity and authenticity confirmed."
    exit 0
elif [ $SIGNATURES_VERIFIED -gt 0 ]; then
    echo "⚠ PARTIAL VERIFICATION"
    echo ""
    echo "Some signatures verified, but not all three."
    echo "Archive integrity confirmed by checksum."
    exit 0
else
    echo "⚠ CHECKSUM ONLY"
    echo ""
    echo "Archive integrity confirmed by checksum."
    echo "No GPG signatures verified (may not be available yet)."
    exit 0
fi
