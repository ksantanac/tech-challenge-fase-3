terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }

  # Backend remoto: o state fica em um bucket S3 (não local).
  # O bucket é criado uma única vez por terraform/00-bootstrap-backend.sh.
  # use_lockfile (Terraform >= 1.10) faz o lock no próprio S3, sem precisar de DynamoDB.
  backend "s3" {
    bucket       = "togglemaster-tfstate-885359793851"
    key          = "fase3/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
