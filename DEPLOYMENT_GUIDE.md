# �� DevOps Showcase Deployment Guide

This guide explains how to deploy the Portfolio API DevOps showcase project.

## 🎯 For DevOps Showcase Purposes

This project is designed to demonstrate DevOps skills and best practices. The CI/CD pipeline is configured to be **reliable and showcase-ready**.

## 📋 Prerequisites

### 1. GitHub Repository Setup
- Fork or clone this repository
- Configure GitHub Secrets in repository settings:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY` 
  - `AWS_ACCOUNT_ID`

### 2. AWS Account Setup
- AWS Account with appropriate permissions
- S3 bucket for Terraform state
- DynamoDB table for Terraform state locking

### 3. Update Configuration
Update these files with your AWS account details:

**provider.tf:**
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "terraform/state"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

## 🚀 Deployment Steps

### Option 1: Automated Deployment (Recommended)

1. **Push to main branch:**
   ```bash
   git add .
   git commit -m "Deploy DevOps showcase"
   git push origin main
   ```

2. **Monitor GitHub Actions:**
   - Go to Actions tab in GitHub
   - Watch the pipeline progress
   - All jobs should complete successfully

### Option 2: Manual Deployment

1. **Deploy Infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Build and Push Image:**
   ```bash
   # Configure AWS CLI
   aws configure
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and push
   docker build -t portfolio-app .
   docker tag portfolio-app:latest \
     <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest
   docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest
   ```

## ✅ Expected Results

After successful deployment, you should have:

### Infrastructure
- ✅ VPC with public/private subnets
- ✅ ECS Fargate cluster
- ✅ RDS PostgreSQL database
- ✅ Application Load Balancer
- ✅ CloudWatch monitoring

### Application
- ✅ FastAPI application running on ECS
- ✅ Health check endpoint responding
- ✅ API documentation available
- ✅ Database connectivity working

### CI/CD Pipeline
- ✅ Code quality checks passing
- ✅ Docker image built and pushed
- ✅ Infrastructure deployed
- ✅ Application deployed
- ✅ Health checks passing

## 🔍 Verification

### Check Application Health
```bash
# Get load balancer DNS
aws elbv2 describe-load-balancers \
  --names portfolio-dev-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Test health endpoint
curl http://<ALB_DNS>/health
```

### Check ECS Service
```bash
aws ecs describe-services \
  --cluster portfolio-dev-cluster \
  --services portfolio-dev-service
```

### Check CloudWatch Logs
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ecs/portfolio"
```

## 🎯 Showcase Features

This project demonstrates:

### DevOps Practices
- ✅ Infrastructure as Code (Terraform)
- ✅ CI/CD Pipelines (GitHub Actions)
- ✅ Container Orchestration (ECS Fargate)
- ✅ Blue/Green Deployments (CodeDeploy)
- ✅ Monitoring & Alerting (CloudWatch)
- ✅ Secrets Management (SSM Parameter Store)

### Technical Skills
- ✅ Python/FastAPI Development
- ✅ Docker Containerization
- ✅ AWS Cloud Services
- ✅ Database Management (PostgreSQL)
- ✅ Load Balancing & Auto-scaling
- ✅ Security Best Practices

### Operational Excellence
- ✅ Automated Testing
- ✅ Code Quality Checks
- ✅ Environment Management
- ✅ Disaster Recovery
- ✅ Documentation
- ✅ Runbooks

## 🚨 Troubleshooting

### Common Issues

1. **ECR Repository Not Found**
   ```bash
   aws ecr create-repository --repository-name portfolio-app
   ```

2. **Terraform State Lock**
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

3. **ECS Service Not Found**
   - Check if Terraform applied successfully
   - Verify ECS cluster exists

4. **Health Check Failures**
   - Check ECS task logs
   - Verify security groups
   - Check load balancer configuration

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Review CloudWatch logs for application issues
- Consult the runbook for operational procedures

## 📊 Cost Optimization

For showcase purposes, the infrastructure is configured for cost efficiency:
- ECS tasks: 256 CPU, 512 MB memory
- RDS: db.t3.micro instance
- Single AZ deployment (can be upgraded to Multi-AZ)

## 🎉 Success Criteria

Your DevOps showcase is successful when:
- ✅ All CI/CD pipeline jobs pass
- ✅ Application is accessible via load balancer
- ✅ Health checks return 200 OK
- ✅ API documentation loads correctly
- ✅ Database connectivity works
- ✅ Monitoring and logging are functional

This demonstrates comprehensive DevOps skills and production-ready practices!
