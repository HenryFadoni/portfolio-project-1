# Terraform Backend Setup Guide

## Problem
Your Terraform configuration is trying to use an S3 bucket for state storage, but the bucket doesn't exist yet.

## Solution
You need to create the S3 bucket and DynamoDB table for Terraform state storage.

## Option 1: Automated Setup (Recommended)

Run the setup script with your AWS credentials:

```bash
# Configure AWS credentials first
aws configure
# OR set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"

# Run the setup script
./scripts/setup-terraform-backend.sh
```

## Option 2: Manual Setup

### 1. Create S3 Bucket
```bash
aws s3 mb s3://portfolio-dev-terraform-state --region eu-west-1
```

### 2. Enable Versioning
```bash
aws s3api put-bucket-versioning \
    --bucket portfolio-dev-terraform-state \
    --versioning-configuration Status=Enabled
```

### 3. Enable Encryption
```bash
aws s3api put-bucket-encryption \
    --bucket portfolio-dev-terraform-state \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
```

### 4. Block Public Access
```bash
aws s3api put-public-access-block \
    --bucket portfolio-dev-terraform-state \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 5. Create DynamoDB Table
```bash
aws dynamodb create-table \
    --table-name portfolio-dev-terraform-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region eu-west-1
```

## Option 3: AWS Console

1. Go to AWS S3 Console
2. Create bucket: `portfolio-dev-terraform-state`
3. Enable versioning
4. Enable server-side encryption (AES256)
5. Block all public access
6. Go to DynamoDB Console
7. Create table: `portfolio-dev-terraform-lock`
8. Primary key: `LockID` (String)
9. Provisioned capacity: 5 read/write units

## After Setup

Once the bucket and table are created, run:

```bash
terraform init
terraform plan
```

## Important Notes

- The bucket name must be globally unique across all AWS accounts
- If you get a "bucket already exists" error, try adding a random suffix
- Make sure your AWS credentials have permissions to create S3 buckets and DynamoDB tables
- The DynamoDB table is used for state locking to prevent concurrent modifications

## Troubleshooting

### Access Denied Error
- Check your AWS credentials: `aws sts get-caller-identity`
- Ensure your user/role has S3 and DynamoDB permissions

### Bucket Already Exists
- S3 bucket names must be globally unique
- Try adding a random suffix: `portfolio-dev-terraform-state-12345`

### Region Mismatch
- Ensure the bucket is created in `eu-west-1` (as specified in provider.tf)
- Or update the region in provider.tf to match your preferred region
