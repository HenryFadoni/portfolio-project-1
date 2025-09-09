# 🚨 Portfolio API Operations Runbook

This runbook provides step-by-step procedures for common operational tasks, incident response, and troubleshooting for the Portfolio API DevOps showcase project.

## 📋 Table of Contents

1. [Deploying the Application](#1-deploying-the-application)
2. [Rolling Back a Failed Deploy](#2-rolling-back-a-failed-deploy)
3. [Incident Response Procedures](#3-incident-response-procedures)
4. [Troubleshooting Guide](#4-troubleshooting-guide)
5. [Emergency Contacts](#5-emergency-contacts)

---

## 1. Deploying the Application

### 1.1 Automated Deployment (Recommended)

The application uses a fully automated CI/CD pipeline that triggers on pushes to the `main` branch.

#### Prerequisites
- GitHub repository with proper secrets configured
- AWS credentials with appropriate permissions
- Terraform state backend configured

#### Steps

1. **Verify GitHub Secrets**
   ```bash
   # Check that these secrets are configured in GitHub:
   # - AWS_ACCESS_KEY_ID
   # - AWS_SECRET_ACCESS_KEY
   # - AWS_ACCOUNT_ID
   ```

2. **Push to Main Branch**
   ```bash
   git checkout main
   git pull origin main
   git push origin main
   ```

3. **Monitor Deployment**
   - Go to GitHub Actions tab
   - Watch the CI/CD pipeline progress
   - Monitor each stage:
     - ✅ Test and Lint
     - ✅ Build and Push to ECR
     - ✅ Terraform Plan
     - ✅ Terraform Apply (requires approval)
     - ✅ Deploy to ECS
     - ✅ Health Check

4. **Verify Deployment**
   ```bash
   # Get load balancer DNS
   aws elbv2 describe-load-balancers \
     --names portfolio-dev-alb \
     --query 'LoadBalancers[0].DNSName' \
     --output text
   
   # Test health endpoint
   curl http://<ALB_DNS>/health
   ```

### 1.2 Manual Deployment

If automated deployment fails or manual intervention is required:

#### Infrastructure Deployment

1. **Initialize Terraform**
   ```bash
   cd /path/to/portfolio-project
   terraform init
   ```

2. **Plan Infrastructure Changes**
   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply tfplan
   ```

#### Application Deployment

1. **Build and Push Docker Image**
   ```bash
   # Configure AWS credentials
   aws configure
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and tag image
   docker build -t portfolio-app .
   docker tag portfolio-app:latest \
     <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest
   
   # Push to ECR
   docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest
   ```

2. **Update ECS Service**
   ```bash
   # Get current task definition
   aws ecs describe-task-definition \
     --task-definition portfolio-dev-service \
     --query taskDefinition > task-definition.json
   
   # Update image in task definition
   # Edit task-definition.json to update the image URI
   
   # Register new task definition
   aws ecs register-task-definition \
     --cli-input-json file://task-definition.json
   
   # Update service
   aws ecs update-service \
     --cluster portfolio-dev-cluster \
     --service portfolio-dev-service \
     --task-definition portfolio-dev-service:NEW_REVISION
   ```

---

## 2. Rolling Back a Failed Deploy

### 2.1 Automatic Rollback

The CI/CD pipeline includes automatic rollback on deployment failure. If this doesn't work, follow manual procedures.

### 2.2 Manual Rollback

#### Quick Rollback (ECS Service)

1. **Identify Previous Task Definition**
   ```bash
   # List task definitions
   aws ecs list-task-definitions \
     --family-prefix portfolio-dev-service \
     --status ACTIVE \
     --sort DESC
   ```

2. **Rollback to Previous Version**
   ```bash
   # Update service to previous task definition
   aws ecs update-service \
     --cluster portfolio-dev-cluster \
     --service portfolio-dev-service \
     --task-definition portfolio-dev-service:PREVIOUS_REVISION \
     --force-new-deployment
   ```

3. **Verify Rollback**
   ```bash
   # Wait for service to stabilize
   aws ecs wait services-stable \
     --cluster portfolio-dev-cluster \
     --services portfolio-dev-service
   
   # Check service status
   aws ecs describe-services \
     --cluster portfolio-dev-cluster \
     --services portfolio-dev-service
   ```

#### CodeDeploy Rollback

1. **Stop Current Deployment**
   ```bash
   # List active deployments
   aws deploy list-deployments \
     --application-name portfolio-dev-service-app \
     --deployment-group-name portfolio-dev-service-dg
   
   # Stop deployment
   aws deploy stop-deployment \
     --deployment-id <DEPLOYMENT_ID> \
     --auto-rollback-enabled
   ```

2. **Manual Rollback**
   ```bash
   # Create rollback deployment
   aws deploy create-deployment \
     --application-name portfolio-dev-service-app \
     --deployment-group-name portfolio-dev-service-dg \
     --deployment-config-name CodeDeployDefault.ECSAllAtOnceBlueGreen \
     --description "Manual rollback deployment"
   ```

### 2.3 Infrastructure Rollback

If infrastructure changes need to be rolled back:

1. **Revert Terraform State**
   ```bash
   # List Terraform state
   terraform state list
   
   # Show current state
   terraform show
   
   # Import previous state if needed
   terraform import aws_ecs_service.app portfolio-dev-cluster/portfolio-dev-service
   ```

2. **Apply Previous Configuration**
   ```bash
   # Plan rollback
   terraform plan -out=rollback.tfplan
   
   # Apply rollback
   terraform apply rollback.tfplan
   ```

---

## 3. Incident Response Procedures

### 3.1 ECS Tasks Failing

#### Symptoms
- High error rates in CloudWatch logs
- ECS service showing unhealthy tasks
- Load balancer health checks failing
- Application returning 5xx errors

#### Immediate Response (0-5 minutes)

1. **Check ECS Service Status**
   ```bash
   aws ecs describe-services \
     --cluster portfolio-dev-cluster \
     --services portfolio-dev-service \
     --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount}'
   ```

2. **Check Task Health**
   ```bash
   aws ecs list-tasks \
     --cluster portfolio-dev-cluster \
     --service-name portfolio-dev-service
   
   # Get task details
   aws ecs describe-tasks \
     --cluster portfolio-dev-cluster \
     --tasks <TASK_ARN>
   ```

3. **Check Application Logs**
   ```bash
   # Get log group
   aws logs describe-log-groups \
     --log-group-name-prefix "/aws/ecs/portfolio"
   
   # Get recent logs
   aws logs get-log-events \
     --log-group-name "/aws/ecs/portfolio-dev" \
     --log-stream-name <LOG_STREAM> \
     --start-time $(date -d '1 hour ago' +%s)000
   ```

#### Investigation (5-15 minutes)

1. **Check Load Balancer Health**
   ```bash
   # Get target group ARN
   aws elbv2 describe-target-groups \
     --names portfolio-dev-tg
   
   # Check target health
   aws elbv2 describe-target-health \
     --target-group-arn <TARGET_GROUP_ARN>
   ```

2. **Check CloudWatch Alarms**
   ```bash
   aws cloudwatch describe-alarms \
     --alarm-names portfolio-dev-high-cpu \
     portfolio-dev-high-memory \
     portfolio-dev-alb-5xx-errors
   ```

3. **Check Database Connectivity**
   ```bash
   # Check RDS instance status
   aws rds describe-db-instances \
     --db-instance-identifier portfolio-dev-db
   
   # Check database logs
   aws logs get-log-events \
     --log-group-name "/aws/rds/instance/portfolio-dev-db/postgresql" \
     --log-stream-name <LOG_STREAM>
   ```

#### Resolution (15-30 minutes)

1. **Scale Up Service**
   ```bash
   # Increase desired count
   aws ecs update-service \
     --cluster portfolio-dev-cluster \
     --service portfolio-dev-service \
     --desired-count 3
   ```

2. **Restart Service**
   ```bash
   # Force new deployment
   aws ecs update-service \
     --cluster portfolio-dev-cluster \
     --service portfolio-dev-service \
     --force-new-deployment
   ```

3. **Rollback if Necessary**
   ```bash
   # Follow rollback procedures from section 2
   ```

### 3.2 Database Down

#### Symptoms
- Application returning database connection errors
- RDS instance showing as unavailable
- CloudWatch alarms for database metrics
- Application logs showing connection timeouts

#### Immediate Response (0-5 minutes)

1. **Check RDS Status**
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier portfolio-dev-db \
     --query 'DBInstances[0].{Status:DBInstanceStatus,AvailabilityZone:AvailabilityZone,MultiAZ:MultiAZ}'
   ```

2. **Check Database Events**
   ```bash
   aws rds describe-events \
     --source-identifier portfolio-dev-db \
     --source-type db-instance \
     --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S)
   ```

#### Investigation (5-15 minutes)

1. **Check Database Logs**
   ```bash
   # List log files
   aws rds describe-db-log-files \
     --db-instance-identifier portfolio-dev-db
   
   # Download recent log
   aws rds download-db-log-file-portion \
     --db-instance-identifier portfolio-dev-db \
     --log-file-name <LOG_FILE_NAME> \
     --starting-token 0
   ```

2. **Check Security Groups**
   ```bash
   # Get security group ID
   aws rds describe-db-instances \
     --db-instance-identifier portfolio-dev-db \
     --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId'
   
   # Check security group rules
   aws ec2 describe-security-groups \
     --group-ids <SECURITY_GROUP_ID>
   ```

3. **Check Subnet Group**
   ```bash
   aws rds describe-db-subnet-groups \
     --db-subnet-group-name portfolio-dev-db-subnet-group
   ```

#### Resolution (15-60 minutes)

1. **Reboot Database (if safe)**
   ```bash
   aws rds reboot-db-instance \
     --db-instance-identifier portfolio-dev-db
   ```

2. **Failover to Standby (Multi-AZ)**
   ```bash
   aws rds reboot-db-instance \
     --db-instance-identifier portfolio-dev-db \
     --force-failover
   ```

3. **Restore from Snapshot (if necessary)**
   ```bash
   # List available snapshots
   aws rds describe-db-snapshots \
     --db-instance-identifier portfolio-dev-db
   
   # Restore from snapshot
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier portfolio-dev-db-restored \
     --db-snapshot-identifier <SNAPSHOT_ID>
   ```

### 3.3 Load Balancer Issues

#### Symptoms
- 502/503 errors from load balancer
- Target group showing unhealthy targets
- High latency or timeouts
- SSL/TLS certificate issues

#### Immediate Response (0-5 minutes)

1. **Check Load Balancer Status**
   ```bash
   aws elbv2 describe-load-balancers \
     --names portfolio-dev-alb \
     --query 'LoadBalancers[0].{State:State,Type:Type,Scheme:Scheme}'
   ```

2. **Check Target Group Health**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <TARGET_GROUP_ARN>
   ```

#### Investigation (5-15 minutes)

1. **Check Listener Configuration**
   ```bash
   aws elbv2 describe-listeners \
     --load-balancer-arn <LOAD_BALANCER_ARN>
   ```

2. **Check SSL Certificate**
   ```bash
   aws acm list-certificates \
     --certificate-statuses ISSUED
   ```

#### Resolution (15-30 minutes)

1. **Update Target Group Health Check**
   ```bash
   aws elbv2 modify-target-group \
     --target-group-arn <TARGET_GROUP_ARN> \
     --health-check-path /health \
     --health-check-interval-seconds 30 \
     --healthy-threshold-count 2
   ```

2. **Replace Unhealthy Targets**
   ```bash
   # Deregister unhealthy targets
   aws elbv2 deregister-targets \
     --target-group-arn <TARGET_GROUP_ARN> \
     --targets Id=<TARGET_ID>
   ```

---

## 4. Troubleshooting Guide

### 4.1 Common Issues

#### Application Won't Start
```bash
# Check ECS task logs
aws logs get-log-events \
  --log-group-name "/aws/ecs/portfolio-dev" \
  --log-stream-name <TASK_LOG_STREAM>

# Check task definition
aws ecs describe-task-definition \
  --task-definition portfolio-dev-service
```

#### Database Connection Issues
```bash
# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*database*"

# Test connectivity from ECS task
aws ecs execute-command \
  --cluster portfolio-dev-cluster \
  --task <TASK_ARN> \
  --container portfolio-app \
  --interactive \
  --command "/bin/bash"
```

#### High CPU/Memory Usage
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=portfolio-dev-service \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### 4.2 Monitoring Commands

#### Check Service Health
```bash
# Overall service status
aws ecs describe-services \
  --cluster portfolio-dev-cluster \
  --services portfolio-dev-service

# Task health
aws ecs list-tasks \
  --cluster portfolio-dev-cluster \
  --service-name portfolio-dev-service
```

#### Check Infrastructure
```bash
# VPC status
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=portfolio-dev-vpc"

# Subnet status
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<VPC_ID>"
```

#### Check Logs
```bash
# Application logs
aws logs describe-log-streams \
  --log-group-name "/aws/ecs/portfolio-dev" \
  --order-by LastEventTime \
  --descending

# Database logs
aws logs describe-log-streams \
  --log-group-name "/aws/rds/instance/portfolio-dev-db/postgresql"
```

---

## 5. Emergency Contacts

### 5.1 Escalation Matrix

| Severity | Response Time | Contact | Action |
|----------|---------------|---------|---------|
| P0 (Critical) | 15 minutes | On-call Engineer | Immediate response, all hands |
| P1 (High) | 1 hour | On-call Engineer | Response within 1 hour |
| P2 (Medium) | 4 hours | Team Lead | Response within 4 hours |
| P3 (Low) | 24 hours | Team Member | Response within 24 hours |

### 5.2 Communication Channels

- **Slack**: #portfolio-incidents
- **PagerDuty**: On-call rotation
- **Email**: devops-team@company.com
- **Phone**: +1-XXX-XXX-XXXX (Emergency only)

### 5.3 Post-Incident Process

1. **Immediate Response** (0-15 min)
   - Acknowledge incident
   - Assess severity
   - Notify stakeholders

2. **Investigation** (15-60 min)
   - Gather information
   - Identify root cause
   - Implement fix

3. **Resolution** (1-4 hours)
   - Deploy fix
   - Verify resolution
   - Monitor stability

4. **Post-Mortem** (Within 48 hours)
   - Document incident
   - Identify improvements
   - Update runbook
   - Share learnings

### 5.4 Quick Reference

#### Emergency Commands
```bash
# Emergency rollback
aws ecs update-service \
  --cluster portfolio-dev-cluster \
  --service portfolio-dev-service \
  --task-definition portfolio-dev-service:STABLE_REVISION \
  --force-new-deployment

# Emergency scale-up
aws ecs update-service \
  --cluster portfolio-dev-cluster \
  --service portfolio-dev-service \
  --desired-count 5

# Emergency database failover
aws rds reboot-db-instance \
  --db-instance-identifier portfolio-dev-db \
  --force-failover
```

#### Status Page Updates
- Update status page with current status
- Provide ETA for resolution
- Communicate with users via appropriate channels

---

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

*This runbook should be reviewed and updated regularly based on operational learnings and infrastructure changes.*
