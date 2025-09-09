# 🚀 DevOps Showcase: Portfolio API

A comprehensive DevOps showcase project demonstrating modern cloud-native application deployment with Infrastructure as Code, CI/CD pipelines, and automated operations.

## 📋 Project Overview

This project showcases a complete DevOps workflow featuring a FastAPI application deployed on AWS with enterprise-grade infrastructure, automated CI/CD pipelines, and comprehensive monitoring. It demonstrates best practices for cloud-native application development, infrastructure automation, and operational excellence.

### 🎯 Key Features

- **Modern Application**: FastAPI with PostgreSQL integration
- **Infrastructure as Code**: Complete Terraform-managed AWS infrastructure
- **CI/CD Pipeline**: GitHub Actions with blue/green deployments
- **Zero-Downtime Deployments**: AWS CodeDeploy with automatic rollback
- **Comprehensive Monitoring**: CloudWatch logs, alarms, and dashboards
- **Security First**: IAM roles, VPC isolation, and secrets management
- **Auto-Scaling**: ECS Fargate with CPU/memory-based scaling
- **High Availability**: Multi-AZ deployment with load balancing

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud Infrastructure                │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   GitHub        │    │   AWS ECR       │                   │
│  │   Actions       │───▶│   Container     │                   │
│  │   CI/CD         │    │   Registry      │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                        │                          │
│           ▼                        ▼                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                VPC (10.0.0.0/16)                      │   │
│  │  ┌─────────────────┐              ┌─────────────────┐  │   │
│  │  │   Public        │              │   Private       │  │   │
│  │  │   Subnets       │              │   Subnets       │  │   │
│  │  │                 │              │                 │  │   │
│  │  │  ┌───────────┐  │              │  ┌───────────┐  │  │   │
│  │  │  │    ALB    │  │              │  │   ECS     │  │  │   │
│  │  │  │           │  │              │  │  Fargate  │  │  │   │
│  │  │  └───────────┘  │              │  │  Tasks    │  │  │   │
│  │  │                 │              │  └───────────┘  │  │   │
│  │  │  ┌───────────┐  │              │                 │  │   │
│  │  │  │   NAT     │  │              │  ┌───────────┐  │  │   │
│  │  │  │ Gateway   │  │              │  │    RDS    │  │  │   │
│  │  │  └───────────┘  │              │  │PostgreSQL │  │  │   │
│  │  └─────────────────┘              │  └───────────┘  │  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Monitoring & Operations                   │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐         │   │
│  │  │CloudWatch │  │CodeDeploy │  │   SNS     │         │   │
│  │  │  Logs     │  │Blue/Green │  │ Alerts    │         │   │
│  │  └───────────┘  └───────────┘  └───────────┘         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

*Architecture diagram placeholder - detailed diagram to be added*

## 🛠️ Tech Stack

### **Application Layer**
- **FastAPI** - Modern Python web framework
- **PostgreSQL** - Relational database
- **SQLAlchemy** - Python ORM
- **Pydantic** - Data validation
- **Docker** - Containerization

### **Infrastructure Layer**
- **Terraform** - Infrastructure as Code
- **AWS VPC** - Virtual private cloud
- **AWS ECS Fargate** - Container orchestration
- **AWS RDS** - Managed PostgreSQL database
- **AWS ALB** - Application load balancer
- **AWS ECR** - Container registry

### **CI/CD & Operations**
- **GitHub Actions** - CI/CD pipeline
- **AWS CodeDeploy** - Blue/green deployments
- **AWS CloudWatch** - Monitoring and logging
- **AWS SNS** - Notifications
- **AWS SSM** - Secrets management

### **Security & Compliance**
- **AWS IAM** - Identity and access management
- **VPC Security Groups** - Network security
- **AWS Secrets Manager** - Secure credential storage
- **Multi-AZ Deployment** - High availability

## 🚀 How to Run Locally

### Prerequisites
- Python 3.11+
- Docker & Docker Compose
- AWS CLI (for production deployment)
- Terraform 1.6+ (for infrastructure)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd portfolio-project
   ```

2. **Set up development environment**
   ```bash
   # Run the automated setup script
   ./scripts/setup-dev.sh
   
   # Or manually:
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Start with Docker Compose**
   ```bash
   # Start the full stack (app + database)
   docker-compose up --build
   
   # Access the application
   curl http://localhost:8080/health
   # API Documentation: http://localhost:8080/docs
   ```

4. **Run locally with Python**
   ```bash
   # Start PostgreSQL (if not using Docker)
   docker run -d --name portfolio-postgres \
     -e POSTGRES_DB=portfolio_dev \
     -e POSTGRES_USER=dbadmin \
     -e POSTGRES_PASSWORD=password \
     -p 5432:5432 postgres:15-alpine
   
   # Start the application
   source venv/bin/activate
   python run_local.py
   ```

### Development Commands
```bash
# Run tests
./scripts/run-tests.sh

# Format code
./scripts/format-code.sh

# Start development server
./scripts/start-dev.sh
```

## 🔄 How CI/CD Works

### Pipeline Overview

Our CI/CD pipeline implements a comprehensive DevOps workflow with automated testing, building, deployment, and monitoring.

### **Stage 1: Code Quality & Testing**
```yaml
Trigger: Push to any branch
Actions:
  ✓ Checkout code
  ✓ Set up Python 3.11
  ✓ Install dependencies
  ✓ Run flake8 linting
  ✓ Execute pytest test suite
  ✓ Cache dependencies for speed
```

### **Stage 2: Build & Container Registry**
```yaml
Trigger: Push to main branch
Actions:
  ✓ Configure AWS credentials
  ✓ Login to Amazon ECR
  ✓ Build multi-stage Docker image
  ✓ Tag with commit SHA + latest
  ✓ Push to ECR repository
```

### **Stage 3: Infrastructure Planning**
```yaml
Trigger: All branches
Actions:
  ✓ Initialize Terraform
  ✓ Validate configuration
  ✓ Create infrastructure plan
  ✓ Upload plan as artifact
```

### **Stage 4: Infrastructure Deployment**
```yaml
Trigger: Merge to main (with approval)
Actions:
  ✓ Download Terraform plan
  ✓ Apply infrastructure changes
  ✓ Update ECS task definitions
  ✓ Configure load balancers
```

### **Stage 5: Blue/Green Deployment**
```yaml
Trigger: After successful infrastructure deployment
Actions:
  ✓ Create CodeDeploy application
  ✓ Configure deployment group
  ✓ Initiate blue/green deployment
  ✓ Monitor deployment progress
  ✓ Validate health checks
```

### **Stage 6: Automatic Rollback**
```yaml
Trigger: On deployment failure
Actions:
  ✓ Stop failed deployment
  ✓ Rollback to previous version
  ✓ Verify service stability
  ✓ Send notifications
```

### **Stage 7: Post-Deployment Validation**
```yaml
Trigger: After successful deployment
Actions:
  ✓ Resolve load balancer DNS
  ✓ Perform health checks
  ✓ Validate API responses
  ✓ Monitor key metrics
```

### Key Features

- **🔄 Zero-Downtime Deployments**: Blue/green strategy with instant traffic switching
- **🛡️ Automatic Rollback**: Immediate rollback on failure detection
- **📊 Comprehensive Monitoring**: Health checks, metrics, and alerting
- **🔒 Security First**: Secrets management and IAM role-based access
- **⚡ Fast Feedback**: Parallel job execution and dependency caching
- **🎯 Environment Protection**: Production deployments require approval

## 📚 Documentation

- **[FastAPI Application Guide](FastAPI_README.md)** - Detailed application documentation
- **[Deployment Guide](.github/DEPLOYMENT.md)** - Complete CI/CD setup instructions
- **[Runbook](RUNBOOK.md)** - Operational procedures and incident response
