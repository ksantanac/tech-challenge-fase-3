locals {
  # 3 bancos PostgreSQL — um por microsserviço.
  databases = {
    auth      = "auth_db"
    flags     = "flags_db"
    targeting = "targeting_db"
  }
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Permite Postgres (5432) a partir dos nos do EKS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL do node group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-rds-sg" }
}

resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg"
  description = "Permite Redis (6379) a partir dos nos do EKS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis do node group"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-redis-sg" }
}

# ---------------------------------------------------------------------------
# RDS PostgreSQL (3 instâncias, em subnets privadas)
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.project}-db-subnets" }
}

resource "aws_db_instance" "postgres" {
  for_each = local.databases

  identifier             = "${var.project}-${each.key}-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = each.value
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  tags                   = { Name = "${var.project}-${each.key}-db" }
}

# ---------------------------------------------------------------------------
# ElastiCache Redis (single node, sem TLS -> conexao redis:// simples)
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]
  tags                 = { Name = "${var.project}-redis" }
}

# ---------------------------------------------------------------------------
# DynamoDB — tabela de analytics
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
  tags = { Name = "ToggleMasterAnalytics" }
}
