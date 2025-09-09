#!/bin/bash

# Setup script for Terraform S3 backend
# This script creates the necessary S3 bucket and DynamoDB table for Terraform state storage

set -e

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="portfolio"
ENVIRONMENT="dev"
BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-terraform-state-$(date +%s)"
DYNAMODB_TABLE="${PROJECT_NAME}-${ENVIRONMENT}-terraform-lock"

echo "🚀 Setting up Terraform backend infrastructure..."
echo "📍 Region: $AWS_REGION"
echo "🪣 S3 Bucket: $BUCKET_NAME"
echo "🔒 DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured or credentials are invalid"
    echo "Please run: aws configure"
    echo "Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"

# Create S3 bucket
echo "🪣 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Enable versioning
echo "📝 Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔐 Enabling server-side encryption"
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
echo "🚫 Blocking public access"
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table: $DYNAMODB_TABLE"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $AWS_REGION

# Wait for DynamoDB table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $AWS_REGION

echo ""
echo "✅ Terraform backend setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update your provider.tf file with the following backend configuration:"
echo ""
echo "   backend \"s3\" {"
echo "     bucket         = \"$BUCKET_NAME\""
echo "     key            = \"terraform/state\""
echo "     region         = \"$AWS_REGION\""
echo "     encrypt        = true"
echo "     dynamodb_table = \"$DYNAMODB_TABLE\""
echo "   }"
echo ""
echo "2. Run: terraform init"
echo ""
echo "3. Run: terraform plan"
echo ""
echo "💡 Save this information for future reference:"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region: $AWS_REGION"
