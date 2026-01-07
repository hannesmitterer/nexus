#!/bin/bash
#
# KOSYMBIOSIS Archive Creation Script
# 
# This script creates the final immutable archive of the KOSYMBIOSIS project,
# including all artifacts, documentation, and verification materials.
#
# Usage: ./create_archive.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PROJECT_ROOT")"
ARCHIVE_NAME="kosymbiosis-archive"
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
ARCHIVE_DIR="/tmp/${ARCHIVE_NAME}_${TIMESTAMP}"

echo "================================================"
echo "KOSYMBIOSIS Archive Creation Script"
echo "================================================"
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Repository Root: $REPO_ROOT"
echo "Archive Directory: $ARCHIVE_DIR"
echo ""

# Create temporary archive directory
echo "[1/8] Creating archive directory..."
mkdir -p "$ARCHIVE_DIR/kosymbiosis"
mkdir -p "$ARCHIVE_DIR/kosymbiosis/artifacts"
mkdir -p "$ARCHIVE_DIR/kosymbiosis/signatures"
mkdir -p "$ARCHIVE_DIR/kosymbiosis/scripts"

# Copy core KOSYMBIOSIS files
echo "[2/8] Copying core KOSYMBIOSIS documentation..."
cp "$PROJECT_ROOT/README.md" "$ARCHIVE_DIR/kosymbiosis/"
cp "$PROJECT_ROOT/KOSYMBIOSIS_DECLARATION.md" "$ARCHIVE_DIR/kosymbiosis/"
cp "$PROJECT_ROOT/KOSYMBIOSIS_METADATA.json" "$ARCHIVE_DIR/kosymbiosis/"
cp "$PROJECT_ROOT/KOSYMBIOSIS_FINAL_LOG.txt" "$ARCHIVE_DIR/kosymbiosis/"

# Copy protocol specifications
echo "[3/8] Copying protocol specifications..."
cp "$REPO_ROOT/SAIN-Protocol-V1.0.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/Sentinel_MANIFESTO.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/ACTUS_RESONANTIAE_CUSTOS_SENTIMENTO.json" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/HARMONIC_CONFIRMATION_CUSTOS_SENTIMENTO.json" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/docs/CUSTOS_SENTIMENTO.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"

# Copy smart contracts
echo "[4/8] Copying smart contracts..."
cp "$REPO_ROOT/UniversalLiquidityPool.sol" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/Validator_and_Collateral_Enforcement_VCE.sol" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
if [ -d "$REPO_ROOT/contracts" ]; then
    cp -r "$REPO_ROOT/contracts" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
fi

# Copy documentation
echo "[5/8] Copying additional documentation..."
cp "$REPO_ROOT/ULP_DEPLOYMENT_GUIDE.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/ULP_ACCEPTANCE_CRITERIA.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/ULP_README.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/AIC_Manuale_Operativo_Finale.md" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
cp "$REPO_ROOT/Rapporto_di_Allineamento_Zero.txt" "$ARCHIVE_DIR/kosymbiosis/artifacts/"

# Copy dashboard and data
echo "[6/8] Copying dashboard and data files..."
if [ -d "$REPO_ROOT/dashboard" ]; then
    cp -r "$REPO_ROOT/dashboard" "$ARCHIVE_DIR/kosymbiosis/artifacts/"
fi

# Copy verification scripts
echo "[7/8] Copying verification scripts..."
cp "$PROJECT_ROOT/scripts/verify_archive.sh" "$ARCHIVE_DIR/kosymbiosis/scripts/" 2>/dev/null || true
cp "$PROJECT_ROOT/scripts/create_archive.sh" "$ARCHIVE_DIR/kosymbiosis/scripts/" 2>/dev/null || true

# Create the ZIP archive
echo "[8/8] Creating ZIP archive..."
cd "$ARCHIVE_DIR"
zip -r "${ARCHIVE_NAME}.zip" kosymbiosis/
mv "${ARCHIVE_NAME}.zip" "$PROJECT_ROOT/"

# Generate SHA-256 checksum
echo ""
echo "Generating SHA-256 checksum..."
cd "$PROJECT_ROOT"
sha256sum "${ARCHIVE_NAME}.zip" > checksum.sha256

# Display results
echo ""
echo "================================================"
echo "Archive Creation Complete!"
echo "================================================"
echo ""
echo "Archive file: $PROJECT_ROOT/${ARCHIVE_NAME}.zip"
echo "Checksum file: $PROJECT_ROOT/checksum.sha256"
echo ""
echo "Archive checksum:"
cat checksum.sha256
echo ""
echo "Next steps:"
echo "1. Verify the archive: sha256sum -c checksum.sha256"
echo "2. Create GPG signatures (see documentation)"
echo "3. Upload to IPFS"
echo "4. Create GitHub release"
echo ""
echo "To create signatures, run:"
echo "  gpg --detach-sign --armor -o signatures/kosymbiosis.sig ${ARCHIVE_NAME}.zip"
echo ""

# Cleanup
rm -rf "$ARCHIVE_DIR"

echo "Temporary files cleaned up."
echo "Archive creation complete!"
