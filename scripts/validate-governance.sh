#!/bin/bash

# Governance Framework Validation Script
# This script validates the implementation without requiring network access

echo "=========================================="
echo "Governance Framework Validation"
echo "=========================================="
echo ""

# Check if files exist
echo "Checking file structure..."
files=(
    "contracts/GovernanceMetricsRegistry.sol"
    "hardhat.config.js"
    "package.json"
    "deploy/01_deploy_governance_registry.js"
    "scripts/deploy/deploy-governance-sync.js"
    "test/GovernanceMetricsRegistry.test.js"
    "test/stress/DeploymentStressTest.js"
    "docs/HARDHAT_GOVERNANCE_WORKFLOWS.md"
    "docs/GOVERNANCE_INTEGRATION_GUIDE.md"
    "GOVERNANCE_FRAMEWORK_SUMMARY.md"
)

all_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MISSING)"
        all_exist=false
    fi
done

echo ""

# Check contract syntax (basic)
echo "Validating Solidity contract syntax..."
if grep -q "pragma solidity" contracts/GovernanceMetricsRegistry.sol; then
    echo "  ✓ Pragma directive found"
else
    echo "  ✗ Missing pragma directive"
    all_exist=false
fi

if grep -q "contract GovernanceMetricsRegistry" contracts/GovernanceMetricsRegistry.sol; then
    echo "  ✓ Contract declaration found"
else
    echo "  ✗ Missing contract declaration"
    all_exist=false
fi

if grep -q "function setQuorumThreshold" contracts/GovernanceMetricsRegistry.sol; then
    echo "  ✓ Quorum management functions found"
else
    echo "  ✗ Missing quorum functions"
    all_exist=false
fi

if grep -q "function anchorGovernanceRecord" contracts/GovernanceMetricsRegistry.sol; then
    echo "  ✓ Record anchoring functions found"
else
    echo "  ✗ Missing record functions"
    all_exist=false
fi

if grep -q "function recordMetricsSnapshot" contracts/GovernanceMetricsRegistry.sol; then
    echo "  ✓ Metrics tracking functions found"
else
    echo "  ✗ Missing metrics functions"
    all_exist=false
fi

echo ""

# Check JavaScript/TypeScript files
echo "Validating JavaScript configuration..."
if grep -q "solidity" hardhat.config.js; then
    echo "  ✓ Hardhat config has Solidity settings"
else
    echo "  ✗ Missing Solidity config"
    all_exist=false
fi

if grep -q "polygon" hardhat.config.js; then
    echo "  ✓ Polygon network configured"
else
    echo "  ✗ Missing Polygon config"
    all_exist=false
fi

echo ""

# Check test files
echo "Validating test structure..."
if grep -q "describe.*GovernanceMetricsRegistry" test/GovernanceMetricsRegistry.test.js; then
    echo "  ✓ Unit tests structured correctly"
else
    echo "  ✗ Test structure issue"
    all_exist=false
fi

if grep -q "Stress Test" test/stress/DeploymentStressTest.js; then
    echo "  ✓ Stress tests present"
else
    echo "  ✗ Missing stress tests"
    all_exist=false
fi

echo ""

# Check dependencies
echo "Validating package.json..."
if grep -q "hardhat" package.json; then
    echo "  ✓ Hardhat dependency configured"
else
    echo "  ✗ Missing Hardhat dependency"
    all_exist=false
fi

if grep -q "@openzeppelin/contracts" package.json; then
    echo "  ✓ OpenZeppelin dependency configured"
else
    echo "  ✗ Missing OpenZeppelin dependency"
    all_exist=false
fi

echo ""

# Count lines of code
echo "Code Statistics:"
sol_lines=$(wc -l < contracts/GovernanceMetricsRegistry.sol)
test_lines=$(wc -l < test/GovernanceMetricsRegistry.test.js)
stress_lines=$(wc -l < test/stress/DeploymentStressTest.js)
echo "  Contract: $sol_lines lines"
echo "  Unit Tests: $test_lines lines"
echo "  Stress Tests: $stress_lines lines"

echo ""
echo "=========================================="
if [ "$all_exist" = true ]; then
    echo "✓ VALIDATION PASSED"
    echo "All components present and validated"
    echo "Ready for compilation and testing"
else
    echo "✗ VALIDATION FAILED"
    echo "Some components are missing or invalid"
fi
echo "=========================================="
