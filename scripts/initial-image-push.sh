#!/usr/bin/env bash
# =============================================================================
# Publica uma imagem inicial (:latest) de cada microsserviço no ECR, para o
# ArgoCD conseguir subir os pods ANTES do primeiro run do pipeline de CI.
# Depois, o CI passa a publicar tags versionadas (v1.0.0-<commit>).
#
# Rode após o `terraform apply`:  bash scripts/initial-image-push.sh
# =============================================================================
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
SERVICES=(auth-service flag-service targeting-service evaluation-service analytics-service)
ROOT="$(dirname "$0")/.."

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

for svc in "${SERVICES[@]}"; do
  echo ">> [$svc] build + push :latest"
  docker build -t "${REGISTRY}/${svc}:latest" "${ROOT}/${svc}"
  docker push "${REGISTRY}/${svc}:latest"
done

echo ">> Imagens iniciais publicadas no ECR (${REGISTRY})."
