terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# Instala o ArgoCD no cluster via Helm (GitOps como código).
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  # Expõe a UI do ArgoCD via LoadBalancer (para mostrar no vídeo).
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # Evita que o ArgoCD tente usar TLS interno duplicado atrás do LB.
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
}
