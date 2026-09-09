#!/usr/bin/env bash
# =============================================================================
# Cria no cluster o namespace + ConfigMap + Secret do ToggleMaster, lendo os
# endpoints reais dos OUTPUTS do Terraform. Assim os segredos NÃO ficam no git.
#
# Rode depois do `terraform apply` e do `aws eks update-kubeconfig`:
#   DB_PASSWORD='suaSenha' bash scripts/bootstrap-config.sh
# =============================================================================
set -euo pipefail

TF_DIR="$(dirname "$0")/../terraform"
DB_USERNAME="${DB_USERNAME:-toggle_admin}"
: "${DB_PASSWORD:?Defina DB_PASSWORD (a mesma senha usada no terraform.tfvars)}"

echo ">> Lendo outputs do Terraform..."
pushd "$TF_DIR" >/dev/null
REGION=$(terraform output -raw region 2>/dev/null || echo "us-east-1")
REDIS=$(terraform output -raw redis_endpoint)
SQS_URL=$(terraform output -raw sqs_queue_url)
DYNAMO=$(terraform output -raw dynamodb_table_name)
AUTH_HOST=$(terraform output -json rds_endpoints | python -c "import sys,json;print(json.load(sys.stdin)['auth'].split(':')[0])")
FLAG_HOST=$(terraform output -json rds_endpoints | python -c "import sys,json;print(json.load(sys.stdin)['flags'].split(':')[0])")
TARG_HOST=$(terraform output -json rds_endpoints | python -c "import sys,json;print(json.load(sys.stdin)['targeting'].split(':')[0])")
popd >/dev/null

NS=togglemaster
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo ">> Criando ConfigMap..."
kubectl create configmap togglemaster-config -n "$NS" \
  --from-literal=AUTH_SERVICE_URL="http://auth-service:8001" \
  --from-literal=FLAG_SERVICE_URL="http://flag-service:8002" \
  --from-literal=TARGETING_SERVICE_URL="http://targeting-service:8003" \
  --from-literal=REDIS_URL="redis://${REDIS}:6379" \
  --from-literal=AWS_REGION="${REGION}" \
  --from-literal=AWS_SQS_URL="${SQS_URL}" \
  --from-literal=AWS_DYNAMODB_TABLE="${DYNAMO}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">> Criando Secret..."
kubectl create secret generic togglemaster-secrets -n "$NS" \
  --from-literal=AUTH_DATABASE_URL="postgres://${DB_USERNAME}:${DB_PASSWORD}@${AUTH_HOST}:5432/auth_db" \
  --from-literal=FLAG_DATABASE_URL="postgres://${DB_USERNAME}:${DB_PASSWORD}@${FLAG_HOST}:5432/flags_db" \
  --from-literal=TARGETING_DATABASE_URL="postgres://${DB_USERNAME}:${DB_PASSWORD}@${TARG_HOST}:5432/targeting_db" \
  --from-literal=MASTER_KEY="togglemaster-master-key-prod" \
  --from-literal=SERVICE_API_KEY="dev-service-key-local-12345" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo ">> Pronto! Namespace, ConfigMap e Secret criados a partir do Terraform."
echo ">> Agora o ArgoCD pode sincronizar os 5 microsserviços."
