#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bootstrap Script — Creates Terraform Backend Resources
# ═══════════════════════════════════════════════════════════════
# Run this ONCE before the first `terraform init`
# Creates: S3 bucket (state) + DynamoDB table (locks)

set -euo pipefail

AWS_REGION="eu-north-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="data-archival-tf-state-${ACCOUNT_ID}"
LOCK_TABLE="data-archival-tf-locks"

echo "═══════════════════════════════════════════════════"
echo "  Terraform Backend Bootstrap"
echo "  Region:  ${AWS_REGION}"
echo "  Account: ${ACCOUNT_ID}"
echo "  Bucket:  ${STATE_BUCKET}"
echo "  Table:   ${LOCK_TABLE}"
echo "═══════════════════════════════════════════════════"

# ── 1. Create S3 Bucket for Terraform State ──
echo ""
echo "📦 Creating S3 bucket for Terraform state..."
if aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  echo "   ✅ Bucket already exists: ${STATE_BUCKET}"
else
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "${STATE_BUCKET}" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "${STATE_BUCKET}" \
    --server-side-encryption-configuration '{
      "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

  # Block public access
  aws s3api put-public-access-block \
    --bucket "${STATE_BUCKET}" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'

  echo "   ✅ Bucket created: ${STATE_BUCKET}"
fi

# ── 2. Create DynamoDB Table for State Locking ──
echo ""
echo "🔒 Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" 2>/dev/null; then
  echo "   ✅ Table already exists: ${LOCK_TABLE}"
else
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"

  echo "   ⏳ Waiting for table to be active..."
  aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${AWS_REGION}"
  echo "   ✅ Table created: ${LOCK_TABLE}"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Bootstrap complete!"
echo ""
echo "  Next steps:"
echo "    cd infra"
echo "    cp terraform.tfvars.example terraform.tfvars"
echo "    # Edit terraform.tfvars with your values"
echo "    terraform init"
echo "    terraform plan"
echo "    terraform apply"
echo "═══════════════════════════════════════════════════"
