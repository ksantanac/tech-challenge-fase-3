#!/usr/bin/env bash
# =============================================================================
# Cria o bucket S3 que guarda o terraform.tfstate (backend remoto).
# Rode UMA VEZ antes do primeiro `terraform init`.
#   bash terraform/00-bootstrap-backend.sh
# =============================================================================
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="togglemaster-tfstate-${ACCOUNT_ID}"

echo ">> Conta AWS: ${ACCOUNT_ID}"
echo ">> Bucket do state: ${BUCKET}"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo ">> Bucket já existe, nada a fazer."
else
  echo ">> Criando bucket..."
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo ">> Bucket criado com versionamento e acesso público bloqueado."
fi

echo ""
echo "==========================================================="
echo "Confirme que terraform/versions.tf usa este bucket no backend:"
echo "  bucket = \"${BUCKET}\""
echo "Depois rode:  cd terraform && terraform init"
echo "==========================================================="
