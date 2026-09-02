data "aws_caller_identity" "current" {}

# Importa a LabRole existente (AWS Academy) — não criamos IAM, apenas referenciamos.
data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

# ---------------------------------------------------------------------------
# 1. Networking — VPC, subnets públicas/privadas, IGW, route tables
# ---------------------------------------------------------------------------
module "networking" {
  source   = "./modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

# ---------------------------------------------------------------------------
# 2. EKS — cluster + node group (usando a LabRole)
# ---------------------------------------------------------------------------
module "eks" {
  source             = "./modules/eks"
  project            = var.project
  cluster_version    = var.cluster_version
  lab_role_arn       = data.aws_iam_role.lab_role.arn
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired       = var.node_desired
  node_min           = var.node_min
  node_max           = var.node_max
}

# ---------------------------------------------------------------------------
# 3. Bancos de dados — 3x RDS PostgreSQL, ElastiCache Redis, DynamoDB
# ---------------------------------------------------------------------------
module "databases" {
  source                 = "./modules/databases"
  project                = var.project
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
}

# ---------------------------------------------------------------------------
# 4. Mensageria — SQS
# ---------------------------------------------------------------------------
module "messaging" {
  source  = "./modules/messaging"
  project = var.project
}

# ---------------------------------------------------------------------------
# 5. ECR — 5 repositórios de imagem
# ---------------------------------------------------------------------------
module "ecr" {
  source   = "./modules/ecr"
  project  = var.project
  services = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}

# ---------------------------------------------------------------------------
# 6. ArgoCD — instalado no cluster via Helm (GitOps)
# ---------------------------------------------------------------------------
module "argocd" {
  source     = "./modules/argocd"
  depends_on = [module.eks]
}
