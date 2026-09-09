#!/usr/bin/env bash
# =============================================================================
# Instala o ArgoCD no cluster EKS via Helm (GitOps).
# Requer kubectl já apontando para o cluster.
#   bash scripts/install-argocd.sh
# =============================================================================
set -euo pipefail

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --set server.service.type=LoadBalancer \
  --set configs.params."server\.insecure"=true \
  --wait --timeout 10m

echo ">> ArgoCD instalado. Endereço da UI (aguarde o LoadBalancer):"
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
echo ">> Senha inicial do admin:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
