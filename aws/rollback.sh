#!/bin/bash

# Nexus WIP Rollback Script
# This script handles rollback to a previous deployment checkpoint

set -e

# Determine script and repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ENVIRONMENT=${ENVIRONMENT:-"wip"}
REGION=${AWS_REGION:-"us-east-1"}
STACK_NAME="nexus-sovereignshield-${ENVIRONMENT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║           Nexus WIP Rollback Mechanism                    ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

CHECKPOINT_ID=$1

if [ -z "${CHECKPOINT_ID}" ]; then
    echo -e "${RED}Error: Checkpoint ID required${NC}"
    echo "Usage: $0 <checkpoint-id>"
    echo ""
    echo "Available checkpoints:"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    DEPLOYMENT_BUCKET="nexus-deployment-${ENVIRONMENT}-${ACCOUNT_ID}"
    aws s3 ls s3://${DEPLOYMENT_BUCKET}/checkpoints/ --recursive 2>/dev/null || echo "No checkpoints found"
    exit 1
fi

echo -e "${YELLOW}▶ Rolling back to checkpoint: ${CHECKPOINT_ID}${NC}"

# Get orchestrator function from stack
ORCHESTRATOR_FUNCTION=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`DeploymentOrchestratorFunction`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "${ORCHESTRATOR_FUNCTION}" ]; then
    echo -e "${RED}Error: Could not find orchestrator function${NC}"
    exit 1
fi

# Invoke rollback via Lambda
echo -e "${YELLOW}▶ Invoking rollback orchestrator...${NC}"
aws lambda invoke \
    --function-name ${ORCHESTRATOR_FUNCTION} \
    --payload "{\"action\":\"rollback\",\"checkpointId\":\"${CHECKPOINT_ID}\",\"reason\":\"Manual rollback initiated\"}" \
    --cli-binary-format raw-in-base64-out \
    --region ${REGION} \
    /tmp/rollback-response.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rollback completed${NC}"
    cat /tmp/rollback-response.json | python -m json.tool 2>/dev/null || cat /tmp/rollback-response.json
    
    # Restore contracts from checkpoint
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    DEPLOYMENT_BUCKET="nexus-deployment-${ENVIRONMENT}-${ACCOUNT_ID}"
    
    echo ""
    echo -e "${YELLOW}▶ Restoring contracts from checkpoint...${NC}"
    aws s3 cp \
        s3://${DEPLOYMENT_BUCKET}/checkpoints/${CHECKPOINT_ID}/SovereignShield.sol \
        ${REPO_ROOT}/contracts/SovereignShield.sol.restored \
        2>/dev/null && echo -e "${GREEN}✓ SovereignShield.sol restored${NC}"
    
    echo ""
    echo -e "${GREEN}Rollback successful. Please review restored files before deploying.${NC}"
else
    echo -e "${RED}✗ Rollback failed${NC}"
    exit 1
fi
