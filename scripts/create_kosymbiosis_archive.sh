#!/bin/bash
# KOSYMBIOSIS Archive Creation Script
# This script creates the final archive of the KOSYMBIOSIS project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARCHIVE_NAME="kosymbiosis-final-archive"
ARCHIVE_DIR="${PROJECT_ROOT}/kosymbiosis"

echo "=== KOSYMBIOSIS Archive Creation ==="
echo "Project Root: ${PROJECT_ROOT}"
echo "Archive Directory: ${ARCHIVE_DIR}"
echo ""

# Check if archive directory exists
if [ ! -d "${ARCHIVE_DIR}" ]; then
    echo "Error: KOSYMBIOSIS directory not found at ${ARCHIVE_DIR}"
    exit 1
fi

# Create archive
echo "Creating ZIP archive..."
cd "${PROJECT_ROOT}"
zip -r "${ARCHIVE_NAME}.zip" kosymbiosis/ \
    -x "*.git*" \
    -x "*__pycache__*" \
    -x "*.pyc" \
    -x "*node_modules*" \
    -x "*.DS_Store"

if [ $? -eq 0 ]; then
    echo "✓ Archive created: ${ARCHIVE_NAME}.zip"
else
    echo "✗ Failed to create archive"
    exit 1
fi

# Generate checksum
echo ""
echo "Generating SHA-256 checksum..."
sha256sum "${ARCHIVE_NAME}.zip" > checksum.sha256

if [ $? -eq 0 ]; then
    echo "✓ Checksum created: checksum.sha256"
    cat checksum.sha256
else
    echo "✗ Failed to generate checksum"
    exit 1
fi

# Display file information
echo ""
echo "=== Archive Information ==="
ls -lh "${ARCHIVE_NAME}.zip"
echo ""
echo "Archive contents:"
unzip -l "${ARCHIVE_NAME}.zip" | head -20

echo ""
echo "=== Next Steps ==="
echo "1. Verify checksum: sha256sum -c checksum.sha256"
echo "2. Sign archive with GPG:"
echo "   gpg --detach-sign --armor -o kosymbiosis.sig ${ARCHIVE_NAME}.zip"
echo "   gpg --detach-sign --armor -o kosymbiosis-co1.sig ${ARCHIVE_NAME}.zip"
echo "   gpg --detach-sign --armor -o kosymbiosis-co2.sig ${ARCHIVE_NAME}.zip"
echo "3. Verify signatures:"
echo "   gpg --verify kosymbiosis.sig ${ARCHIVE_NAME}.zip"
echo "   gpg --verify kosymbiosis-co1.sig ${ARCHIVE_NAME}.zip"
echo "   gpg --verify kosymbiosis-co2.sig ${ARCHIVE_NAME}.zip"
echo "4. Upload to IPFS:"
echo "   ipfs add ${ARCHIVE_NAME}.zip"
echo "5. Create GitHub release with all files"
echo ""
echo "=== Archive Creation Complete ==="
