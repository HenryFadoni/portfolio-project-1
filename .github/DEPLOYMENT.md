# GitHub Actions CI/CD Deployment Guide

This document explains how to set up and use the comprehensive CI/CD pipeline for the Portfolio FastAPI application.

## 🚀 Pipeline Overview

The GitHub Actions workflow provides a complete CI/CD pipeline with:

1. **Code Quality** - Linting with flake8 and testing with pytest
2. **Docker Build** - Multi-stage Docker build and push to ECR
3. **Infrastructure** - Terraform plan and apply
4. **Blue/Green Deployment** - Zero-downtime deployment with AWS CodeDeploy
5. **Automatic Rollback** - Rollback on deployment failure
6. **Health Checks** - Post-deployment verification

## 📋 Prerequisites

### 1. AWS Account Setup
- AWS Account with appropriate permissions
- IAM user with programmatic access
- S3 bucket for Terraform state
- DynamoDB table for Terraform state locking

### 2. GitHub Repository Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `123456789012` |

### 3. AWS Permissions

The IAM user needs the following permissions:
- ECR: Full access for image push/pull
- ECS: Full access for service deployment
- CodeDeploy: Full access for blue/green deployments
- ALB: Read/Write access for load balancer management
- IAM: PassRole for service roles
- S3: Access to Terraform state bucket
- DynamoDB: Access to Terraform lock table

## 🔄 Workflow Triggers

### Automatic Triggers
- **Push to `main`**: Full CI/CD pipeline with deployment
- **Push to `develop`**: CI pipeline only (test + lint)
- **Pull Request to `main`**: CI pipeline only

### Manual Triggers
You can manually trigger deployments from the GitHub Actions tab.

## 📊 Pipeline Stages

### Stage 1: Test and Lint
```yaml
- Checkout code
- Set up Python 3.11
- Cache dependencies
- Install requirements
- Run flake8 linting
- Run pytest tests
```

**Fails if**: Linting errors or test failures

### Stage 2: Build and Push
```yaml
- Configure AWS credentials
- Login to ECR
- Build Docker image
- Tag with commit SHA
- Push to ECR
```

**Runs only**: On `main` branch after successful tests

### Stage 3: Terraform Plan
```yaml
- Setup Terraform
- Initialize Terraform
- Validate configuration
- Create plan
- Upload plan artifact
```

**Always runs**: For visibility into infrastructure changes

### Stage 4: Terraform Apply
```yaml
- Download plan artifact
- Apply infrastructure changes
```

**Runs only**: On `main` branch with manual approval (production environment)

### Stage 5: ECS Deployment
```yaml
- Get current task definition
- Update with new image
- Create CodeDeploy application/deployment group
- Trigger blue/green deployment
- Monitor deployment progress
```

**Features**:
- Zero-downtime blue/green deployment
- Automatic traffic shifting
- Health check validation

### Stage 6: Rollback (if needed)
```yaml
- Stop failed deployment
- Rollback to previous task definition
- Wait for rollback completion
- Notify of rollback
```

**Triggers**: Automatically on deployment failure

### Stage 7: Health Check
```yaml
- Get load balancer DNS
- Perform health checks
- Validate application response
```

**Validates**: Application is responding correctly post-deployment

## 🛠 Configuration

### Environment Variables
Update the workflow environment variables in `.github/workflows/ci-cd.yml`:

```yaml
env:
  AWS_REGION: us-east-1                    # Your AWS region
  ECR_REPOSITORY: portfolio-app            # ECR repository name
  ECS_SERVICE: portfolio-dev-service       # ECS service name
  ECS_CLUSTER: portfolio-dev-cluster       # ECS cluster name
  CONTAINER_NAME: portfolio-app            # Container name in task definition
```

### Terraform Variables
Ensure your `terraform.tfvars` includes:

```hcl
# Update with your ECR repository URI
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest"
```

## 🔍 Monitoring and Troubleshooting

### GitHub Actions Dashboard
- View workflow runs in the "Actions" tab
- Check logs for each step
- Download artifacts (Terraform plans)

### AWS Console Monitoring
- **ECS**: Monitor service health and tasks
- **CodeDeploy**: Track deployment progress
- **CloudWatch**: View application logs and metrics
- **ALB**: Monitor target group health

### Common Issues

#### 1. ECR Push Failures
```bash
# Check ECR repository exists
aws ecr describe-repositories --repository-names portfolio-app

# Create if missing
aws ecr create-repository --repository-name portfolio-app
```

#### 2. Terraform State Lock
```bash
# Check DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock

# Force unlock if needed (use with caution)
terraform force-unlock LOCK_ID
```

#### 3. CodeDeploy Service Role
```bash
# Verify service role exists
aws iam get-role --role-name portfolio-dev-codedeploy-service-role

# Check role is in Terraform state
terraform state list | grep codedeploy
```

#### 4. Health Check Failures
```bash
# Check load balancer targets
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Check application logs
aws logs get-log-events --log-group-name /aws/ecs/portfolio-dev
```

## 🔄 Blue/Green Deployment Details

### How It Works
1. **Blue Environment**: Current production version
2. **Green Environment**: New version being deployed
3. **Traffic Shift**: Gradual or immediate switch
4. **Validation**: Health checks and monitoring
5. **Completion**: Terminate old version or rollback

### Deployment Configuration
- **Ready Option**: Continue deployment automatically
- **Termination Wait**: 5 minutes before terminating blue environment
- **Rollback**: Automatic on failure detection

### Monitoring Points
- Target group health checks
- Application health endpoint (`/health`)
- CloudWatch alarms
- Custom health validation

## 📝 Best Practices

### Code Quality
- Write comprehensive tests
- Follow PEP 8 style guidelines
- Use type hints
- Document complex functions

### Security
- Use GitHub repository secrets for sensitive data
- Rotate AWS credentials regularly
- Enable branch protection rules
- Require code reviews for main branch

### Deployment
- Test in development environment first
- Monitor deployments closely
- Have rollback plan ready
- Use feature flags for risky changes

### Infrastructure
- Keep Terraform state in S3 with versioning
- Use consistent naming conventions
- Tag all resources appropriately
- Regular backup of critical data

## 🚨 Emergency Procedures

### Manual Rollback
```bash
# Get previous task definition
aws ecs list-task-definitions --family-prefix portfolio-dev-service --status ACTIVE

# Update service with previous definition
aws ecs update-service \
  --cluster portfolio-dev-cluster \
  --service portfolio-dev-service \
  --task-definition portfolio-dev-service:PREVIOUS_REVISION \
  --force-new-deployment
```

### Stop Deployment
```bash
# Stop CodeDeploy deployment
aws deploy stop-deployment --deployment-id d-XXXXXXXXX --auto-rollback-enabled
```

### Infrastructure Recovery
```bash
# Import existing resources if needed
terraform import aws_ecs_service.app cluster-name/service-name

# Force refresh state
terraform refresh
```

This deployment pipeline provides enterprise-grade CI/CD with comprehensive monitoring, automatic rollback, and zero-downtime deployments.
