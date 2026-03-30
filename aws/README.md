# AWS Deployment Configuration for Nexus WIP

This directory contains AWS infrastructure configuration for deploying the Nexus SovereignShield quantum-safe security system with automated rollback capabilities.

## Overview

The AWS infrastructure provides:

1. **SovereignShield Deployment** - Quantum-safe security layer with NTRU-inspired validation
2. **Automated Rollback** - WIP deployment rollback mechanism for safe experimentation
3. **State Management** - DynamoDB-based deployment state tracking
4. **Checkpoint System** - Versioned snapshots for rollback capabilities

## Components

### CloudFormation Template

`cloudformation-nexus-wip.yaml` - Main infrastructure template that creates:

- **S3 Bucket** - Stores deployment artifacts with versioning
- **DynamoDB Tables** - Track deployment state and checkpoints
- **Lambda Function** - Orchestrates deployments and rollbacks
- **IAM Roles** - Secure permissions for deployment operations
- **CloudWatch** - Monitoring and alerting for deployment failures
- **SNS Topic** - Notifications for deployment events

### Deployment Scripts

- `deploy.sh` - Main deployment script with checkpoint creation
- `rollback.sh` - Rollback to previous checkpoint

## Prerequisites

1. **AWS CLI** - Install and configure:
   ```bash
   aws configure
   ```

2. **AWS Account** with permissions to create:
   - CloudFormation stacks
   - S3 buckets
   - DynamoDB tables
   - Lambda functions
   - IAM roles
   - CloudWatch alarms
   - SNS topics

3. **Environment Variables** (optional):
   - `ENVIRONMENT` - Deployment environment (default: "wip")
   - `AWS_REGION` - AWS region (default: "us-east-1")
   - `ENABLE_ROLLBACK` - Enable rollback (default: "true")
   - `QUANTUM_SAFE_ENABLED` - Enable quantum-safe verification (default: "true")

## Deployment

### 1. Deploy Infrastructure

**Important**: Run the deployment script from the repository root directory.

```bash
# From repository root
chmod +x aws/deploy.sh aws/rollback.sh
./aws/deploy.sh
```

This will:
- Validate the CloudFormation template
- Create a pre-deployment checkpoint
- Deploy the infrastructure stack
- Upload contract artifacts to S3
- Test the deployment orchestrator

### 2. Deploy for Different Environments

```bash
# WIP environment (default) - run from repo root
ENVIRONMENT=wip ./aws/deploy.sh

# Development environment
ENVIRONMENT=dev ./aws/deploy.sh

# Staging environment
ENVIRONMENT=staging ./aws/deploy.sh

# Production environment (rollback disabled by default)
ENVIRONMENT=production ENABLE_ROLLBACK=false ./aws/deploy.sh
```

### 3. Custom Configuration

```bash
# Deploy to specific region
AWS_REGION=eu-west-1 ./aws/deploy.sh

# Disable quantum-safe verification
QUANTUM_SAFE_ENABLED=false ./aws/deploy.sh

# Disable automatic rollback
ENABLE_ROLLBACK=false ./aws/deploy.sh
```

## Rollback

### Automatic Rollback

If a deployment fails and `ENABLE_ROLLBACK=true`, the system automatically rolls back to the last checkpoint.

### Manual Rollback

```bash
# List available checkpoints (run from repo root)
aws s3 ls s3://nexus-deployment-wip-<ACCOUNT_ID>/checkpoints/ --recursive

# Rollback to specific checkpoint
./aws/rollback.sh pre-deploy-1234567890
```

### Using Lambda Orchestrator

```bash
# Get orchestrator function name
FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --stack-name nexus-sovereignshield-wip \
    --query 'Stacks[0].Outputs[?OutputKey==`DeploymentOrchestratorFunction`].OutputValue' \
    --output text)

# Create manual checkpoint
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload '{"action":"checkpoint","deploymentId":"my-deployment","description":"Before major change"}' \
    response.json

# Rollback to checkpoint
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload '{"action":"rollback","checkpointId":"pre-my-deployment"}' \
    response.json
```

## Stack Outputs

After deployment, the stack provides:

- **DeploymentBucket** - S3 bucket for artifacts
- **DeploymentOrchestratorFunction** - Lambda function name
- **DeploymentStateTable** - DynamoDB table for state
- **RollbackCheckpointTable** - DynamoDB table for checkpoints
- **NotificationTopicArn** - SNS topic ARN

Retrieve outputs:

```bash
aws cloudformation describe-stacks \
    --stack-name nexus-sovereignshield-wip \
    --query 'Stacks[0].Outputs'
```

## Monitoring

### CloudWatch Logs

```bash
# View deployment logs
aws logs tail /nexus/deployment/wip --follow
```

### Deployment State

```bash
# Query deployment state
aws dynamodb scan \
    --table-name nexus-deployment-state-wip \
    --max-items 10
```

### Checkpoints

```bash
# Query checkpoints
aws dynamodb scan \
    --table-name nexus-rollback-checkpoints-wip \
    --max-items 10
```

## Security Features

### Quantum-Safe NTRU Verification

When `QUANTUM_SAFE_ENABLED=true`, the deployment:
- Validates NTRU signatures for critical operations
- Ensures quantum-resistant cryptographic verification
- Integrates with NTRUVerifier smart contract

### Rollback Safety

- Automatic checkpoint creation before deployments
- Versioned S3 storage for contract artifacts
- Point-in-time recovery for DynamoDB tables
- 30-day retention for old versions

### Access Control

- IAM roles with least-privilege permissions
- Encrypted S3 buckets with versioning
- DynamoDB point-in-time recovery
- CloudWatch alarms for failed deployments

## Troubleshooting

### Deployment Fails

1. Check CloudFormation events:
   ```bash
   aws cloudformation describe-stack-events \
       --stack-name nexus-sovereignshield-wip
   ```

2. Review Lambda logs:
   ```bash
   aws logs tail /aws/lambda/nexus-deployment-orchestrator-wip --follow
   ```

3. If automatic rollback fails, use manual rollback:
   ```bash
   ./rollback.sh <checkpoint-id>
   ```

### Stack Already Exists

Update the existing stack:
```bash
aws cloudformation update-stack \
    --stack-name nexus-sovereignshield-wip \
    --template-body file://cloudformation-nexus-wip.yaml \
    --parameters ParameterKey=Environment,ParameterValue=wip
```

### Permission Denied

Ensure your AWS credentials have the necessary permissions:
```bash
aws iam get-user
aws sts get-caller-identity
```

## Cleanup

Delete the stack and all resources:

```bash
# Delete stack
aws cloudformation delete-stack --stack-name nexus-sovereignshield-wip

# Empty and delete S3 bucket (if needed)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm s3://nexus-deployment-wip-${ACCOUNT_ID} --recursive
aws s3 rb s3://nexus-deployment-wip-${ACCOUNT_ID}
```

## Integration with Smart Contracts

After AWS infrastructure is deployed:

1. Deploy `SovereignShield.sol` to blockchain
2. Deploy `NTRUVerifier.sol` to blockchain
3. Configure SovereignShield with NTRUVerifier address
4. Integrate with existing contracts (EIMClient, TFKVerifier)
5. Register validation filters and protected contracts

See the main repository README for contract deployment instructions.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  AWS Infrastructure                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │ CloudWatch   │────▶│  SNS Topic   │                  │
│  │   Alarms     │     │ Notifications│                  │
│  └──────────────┘     └──────────────┘                  │
│         │                                                │
│         ▼                                                │
│  ┌──────────────────────────────────────┐               │
│  │   Lambda: Deployment Orchestrator    │               │
│  │  - Deploy with checkpoints           │               │
│  │  - Rollback to previous state        │               │
│  │  - Create manual checkpoints         │               │
│  └──────────────────────────────────────┘               │
│         │              │              │                  │
│         ▼              ▼              ▼                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │ S3 Bucket│   │ DynamoDB │   │ DynamoDB │            │
│  │Artifacts │   │  State   │   │Checkpoint│            │
│  │Versioned │   │  Table   │   │  Table   │            │
│  └──────────┘   └──────────┘   └──────────┘            │
│                                                           │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Blockchain Smart Contracts                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────┐       ┌──────────────────┐        │
│  │ SovereignShield  │◀─────▶│  NTRUVerifier    │        │
│  │  - Validation    │       │  - Quantum-safe  │        │
│  │  - Rate limiting │       │  - NTRU crypto   │        │
│  │  - Checkpoints   │       └──────────────────┘        │
│  └──────────────────┘                                    │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────────┐       ┌──────────────────┐        │
│  │   EIMClient      │       │   TFKVerifier    │        │
│  │  - SEP validation│       │  - Model verify  │        │
│  └──────────────────┘       └──────────────────┘        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Support

For issues or questions:
1. Check CloudFormation stack events
2. Review Lambda function logs
3. Consult the main repository README
4. Open an issue on GitHub
