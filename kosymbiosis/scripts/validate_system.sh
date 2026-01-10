#!/bin/bash
#
# KOSYMBIOSIS System Validation Test
# 
# This script performs comprehensive validation of the KOSYMBIOSIS archival system
# to ensure all components are working correctly.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "KOSYMBIOSIS System Validation Test"
echo "========================================"
echo ""

# Test 1: Check Directory Structure
echo "[TEST 1/8] Checking directory structure..."
REQUIRED_DIRS=(
    "$PROJECT_ROOT"
    "$PROJECT_ROOT/scripts"
    "$PROJECT_ROOT/signatures"
    "$PROJECT_ROOT/artifacts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✓ Found: $dir"
    else
        echo "  ✗ Missing: $dir"
        exit 1
    fi
done
echo ""

# Test 2: Check Required Documentation
echo "[TEST 2/8] Checking required documentation..."
REQUIRED_DOCS=(
    "README.md"
    "KOSYMBIOSIS_DECLARATION.md"
    "KOSYMBIOSIS_METADATA.json"
    "KOSYMBIOSIS_FINAL_LOG.txt"
    "ARCHIVAL_PROCESS.md"
    "FILE_INDEX.md"
    "IMPLEMENTATION_SUMMARY.md"
    "QUICK_START.md"
    "IPFS_DISTRIBUTION.md"
    "GITHUB_RELEASE.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$PROJECT_ROOT/$doc" ]; then
        echo "  ✓ Found: $doc"
    else
        echo "  ✗ Missing: $doc"
        exit 1
    fi
done
echo ""

# Test 3: Check Scripts
echo "[TEST 3/8] Checking scripts..."
REQUIRED_SCRIPTS=(
    "scripts/create_archive.sh"
    "scripts/verify_archive.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -x "$PROJECT_ROOT/$script" ]; then
        echo "  ✓ Found (executable): $script"
    elif [ -f "$PROJECT_ROOT/$script" ]; then
        echo "  ⚠ Found (not executable): $script"
        chmod +x "$PROJECT_ROOT/$script"
        echo "    → Made executable"
    else
        echo "  ✗ Missing: $script"
        exit 1
    fi
done
echo ""

# Test 4: Validate JSON Files
echo "[TEST 4/8] Validating JSON files..."
if command -v jq &> /dev/null; then
    if jq empty "$PROJECT_ROOT/KOSYMBIOSIS_METADATA.json" 2>/dev/null; then
        echo "  ✓ KOSYMBIOSIS_METADATA.json is valid JSON"
    else
        echo "  ✗ KOSYMBIOSIS_METADATA.json is invalid JSON"
        exit 1
    fi
else
    echo "  ⚠ jq not available, skipping JSON validation"
fi
echo ""

# Test 5: Test Archive Creation
echo "[TEST 5/8] Testing archive creation..."
if ! cd "$PROJECT_ROOT"; then
    echo "  ✗ Failed to change directory to PROJECT_ROOT: $PROJECT_ROOT"
    exit 1
fi

# Clean up any existing archive
rm -f kosymbiosis-archive.zip checksum.sha256

# Create archive
if bash scripts/create_archive.sh > /tmp/kosymbiosis_test.log 2>&1; then
    echo "  ✓ Archive creation successful"
else
    echo "  ✗ Archive creation failed"
    cat /tmp/kosymbiosis_test.log
    exit 1
fi

# Check if archive was created
if [ -f "kosymbiosis-archive.zip" ]; then
    echo "  ✓ Archive file created"
    ARCHIVE_SIZE=$(stat -f%z "kosymbiosis-archive.zip" 2>/dev/null || stat -c%s "kosymbiosis-archive.zip" 2>/dev/null || echo "unknown")
    echo "    Size: $ARCHIVE_SIZE bytes"
else
    echo "  ✗ Archive file not created"
    exit 1
fi

# Check if checksum was created
if [ -f "checksum.sha256" ]; then
    echo "  ✓ Checksum file created"
    cat checksum.sha256
else
    echo "  ✗ Checksum file not created"
    exit 1
fi
echo ""

# Test 6: Test Checksum Verification
echo "[TEST 6/8] Testing checksum verification..."
if sha256sum -c checksum.sha256 > /dev/null 2>&1; then
    echo "  ✓ Checksum verification passed"
else
    echo "  ✗ Checksum verification failed"
    exit 1
fi
echo ""

# Test 7: Test Archive Contents
echo "[TEST 7/8] Testing archive contents..."
EXPECTED_FILES=(
    "kosymbiosis/README.md"
    "kosymbiosis/KOSYMBIOSIS_DECLARATION.md"
    "kosymbiosis/KOSYMBIOSIS_METADATA.json"
    "kosymbiosis/KOSYMBIOSIS_FINAL_LOG.txt"
    "kosymbiosis/artifacts/SAIN-Protocol-V1.0.md"
    "kosymbiosis/artifacts/UniversalLiquidityPool.sol"
    "kosymbiosis/scripts/create_archive.sh"
    "kosymbiosis/scripts/verify_archive.sh"
)

for file in "${EXPECTED_FILES[@]}"; do
    if unzip -l kosymbiosis-archive.zip | grep -q "$file"; then
        echo "  ✓ Found in archive: $file"
    else
        echo "  ✗ Missing from archive: $file"
        exit 1
    fi
done
echo ""

# Test 8: Test Verification Script
echo "[TEST 8/8] Testing verification script..."
if bash scripts/verify_archive.sh kosymbiosis-archive.zip > /tmp/verify_test.log 2>&1; then
    if grep -q "Checksum verification PASSED" /tmp/verify_test.log; then
        echo "  ✓ Verification script passed"
    else
        echo "  ✗ Verification script did not confirm checksum"
        cat /tmp/verify_test.log
        exit 1
    fi
else
    echo "  ✗ Verification script failed"
    cat /tmp/verify_test.log
    exit 1
fi
echo ""

# Summary
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo ""
echo "✓ All tests passed!"
echo ""
echo "System Status:"
echo "  - Directory structure: OK"
echo "  - Documentation: Complete"
echo "  - Scripts: Functional"
echo "  - Archive creation: Working"
echo "  - Checksum verification: Working"
echo "  - Archive contents: Valid"
echo "  - Verification script: Working"
echo ""
echo "The KOSYMBIOSIS archival system is fully operational."
echo ""
echo "Next steps:"
echo "  1. Collect GPG signatures from co-creators"
echo "  2. Upload to IPFS and obtain CID"
echo "  3. Create GitHub release"
echo "  4. Update documentation with CID and release URL"
echo ""
echo "For detailed instructions, see:"
echo "  - ARCHIVAL_PROCESS.md"
echo "  - QUICK_START.md"
echo "  - IMPLEMENTATION_SUMMARY.md"
echo ""

# Cleanup
rm -f /tmp/kosymbiosis_test.log /tmp/verify_test.log

exit 0
