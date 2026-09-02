# ---------------------------------------------------------------------------
# Cluster EKS
# authentication_mode = API_AND_CONFIG_MAP  -> compatível com a LabRole (fix da Fase 2:
#   no modo "API" puro o aws-auth é ignorado e os nós não conseguiam entrar no cluster).
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = "${var.project}-eks"
  version  = var.cluster_version
  role_arn = var.lab_role_arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = { Name = "${var.project}-eks" }
}

# ---------------------------------------------------------------------------
# Launch template do node group
# http_put_response_hop_limit = 2 -> permite que os PODS acessem o IMDS e herdem
#   a LabRole (fix da Fase 2: com hop limit 1 os pods davam "Unable to locate credentials"
#   ao acessar SQS/DynamoDB).
# ---------------------------------------------------------------------------
resource "aws_launch_template" "node" {
  name_prefix = "${var.project}-node-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obrigatório
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project}-node" }
  }
}

# ---------------------------------------------------------------------------
# Managed Node Group (usa a LabRole; nós em subnets públicas -> sem custo de NAT)
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-nodes"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = var.public_subnet_ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  tags = { Name = "${var.project}-nodes" }
}
