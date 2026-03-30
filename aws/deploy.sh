#!/bin/bash

# Nexus WIP Deployment Script with Rollback Support
# This script deploys SovereignShield quantum-safe security infrastructure to AWS

set -e

# Determine script and repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
ENVIRONMENT=${ENVIRONMENT:-"wip"}
REGION=${AWS_REGION:-"us-east-1"}
STACK_NAME="nexus-sovereignshield-${ENVIRONMENT}"
ENABLE_ROLLBACK=${ENABLE_ROLLBACK:-"true"}
QUANTUM_SAFE_ENABLED=${QUANTUM_SAFE_ENABLED:-"true"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Nexus WIP Deployment - SovereignShield Quantum-Safe     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check AWS CLI
print_step "Checking AWS CLI installation..."
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi
print_success "AWS CLI found"

# Check AWS credentials
print_step "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "AWS credentials valid (Account: ${ACCOUNT_ID})"

# Create checkpoint before deployment
create_checkpoint() {
    local CHECKPOINT_ID="pre-deploy-$(date +%s)"
    local BUCKET="nexus-deployment-${ENVIRONMENT}-${ACCOUNT_ID}"
    print_step "Creating deployment checkpoint: ${CHECKPOINT_ID}"

    # Check if the deployment bucket exists before attempting to upload
    if aws s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
        # Store current state in S3; let failures surface (set -e will abort)
        aws s3 cp "${REPO_ROOT}/contracts/SovereignShield.sol" \
            "s3://${BUCKET}/checkpoints/${CHECKPOINT_ID}/SovereignShield.sol" \
            --region ${REGION}
        print_success "Checkpoint created in S3: ${CHECKPOINT_ID}"
    else
        # Likely first deployment: bucket not created yet; record only a local checkpoint
        print_step "Deployment bucket ${BUCKET} not available yet; storing local checkpoint only"
        print_success "Local checkpoint recorded: ${CHECKPOINT_ID}"
    fi
    
    echo "${CHECKPOINT_ID}" > "${REPO_ROOT}/.last_checkpoint"
}

# Validate CloudFormation template
print_step "Validating CloudFormation template..."
if aws cloudformation validate-template \
    --template-body file://${SCRIPT_DIR}/cloudformation-nexus-wip.yaml \
    --region ${REGION} > /dev/null; then
    print_success "Template validation passed"
else
    print_error "Template validation failed"
    exit 1
fi

# Create checkpoint if rollback enabled
if [ "${ENABLE_ROLLBACK}" = "true" ]; then
    create_checkpoint
fi

# Deploy CloudFormation stack
print_step "Deploying CloudFormation stack: ${STACK_NAME}"
aws cloudformation deploy \
    --template-file ${SCRIPT_DIR}/cloudformation-nexus-wip.yaml \
    --stack-name ${STACK_NAME} \
    --parameter-overrides \
        Environment=${ENVIRONMENT} \
        EnableRollback=${ENABLE_ROLLBACK} \
        QuantumSafeEnabled=${QUANTUM_SAFE_ENABLED} \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${REGION} \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    print_success "Stack deployment completed"
else
    print_error "Stack deployment failed"
    
    if [ "${ENABLE_ROLLBACK}" = "true" ] && [ -f "${REPO_ROOT}/.last_checkpoint" ]; then
        CHECKPOINT_ID=$(cat "${REPO_ROOT}/.last_checkpoint")
        print_step "Initiating automatic rollback to checkpoint: ${CHECKPOINT_ID}"
        
        # Trigger rollback using absolute path
        "${SCRIPT_DIR}/rollback.sh" ${CHECKPOINT_ID}
    fi
    
    exit 1
fi

# Get stack outputs
print_step "Retrieving stack outputs..."
DEPLOYMENT_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`DeploymentBucket`].OutputValue' \
    --output text)

ORCHESTRATOR_FUNCTION=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`DeploymentOrchestratorFunction`].OutputValue' \
    --output text)

print_success "Deployment bucket: ${DEPLOYMENT_BUCKET}"
print_success "Orchestrator function: ${ORCHESTRATOR_FUNCTION}"

# Upload contract artifacts
print_step "Uploading SovereignShield contract to S3..."
aws s3 cp ${REPO_ROOT}/contracts/SovereignShield.sol \
    s3://${DEPLOYMENT_BUCKET}/contracts/SovereignShield.sol \
    --region ${REGION}

aws s3 cp ${REPO_ROOT}/contracts/NTRUVerifier.sol \
    s3://${DEPLOYMENT_BUCKET}/contracts/NTRUVerifier.sol \
    --region ${REGION}

print_success "Contracts uploaded"

# Test deployment orchestrator
print_step "Testing deployment orchestrator..."
DEPLOYMENT_ID="test-deploy-$(date +%s)"
aws lambda invoke \
    --function-name ${ORCHESTRATOR_FUNCTION} \
    --payload "{\"action\":\"deploy\",\"deploymentId\":\"${DEPLOYMENT_ID}\"}" \
    --cli-binary-format raw-in-base64-out \
    --region ${REGION} \
    /tmp/deploy-response.json > /dev/null

if [ $? -eq 0 ]; then
    print_success "Deployment orchestrator test passed"
    cat /tmp/deploy-response.json | python -m json.tool 2>/dev/null || cat /tmp/deploy-response.json
else
    print_error "Deployment orchestrator test failed"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Deployment Completed Successfully              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Stack Name: ${STACK_NAME}"
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo "Quantum-Safe: ${QUANTUM_SAFE_ENABLED}"
echo "Rollback Enabled: ${ENABLE_ROLLBACK}"
echo ""
echo "Next steps:"
echo "1. Deploy smart contracts to blockchain"
echo "2. Configure SovereignShield with validation filters"
echo "3. Register quantum-safe public keys"
echo ""
