variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto (prefixo dos recursos)"
  type        = string
  default     = "togglemaster"
}

variable "lab_role_name" {
  description = "Nome da IAM Role existente do AWS Academy (usada pelo cluster e node group, pois não podemos criar roles)"
  type        = string
  default     = "LabRole"
}

# ---- Networking ----
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones usadas"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ---- EKS ----
variable "cluster_version" {
  description = "Versão do Kubernetes no EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "Tipo das instâncias do node group"
  type        = string
  default     = "t3.medium"
}

variable "node_desired" {
  type    = number
  default = 2
}
variable "node_min" {
  type    = number
  default = 1
}
variable "node_max" {
  type    = number
  default = 4
}

# ---- Bancos de dados (RDS) ----
# Senhas via variável sensível — nunca versionar valores reais (use terraform.tfvars, que está no .gitignore).
variable "db_username" {
  description = "Usuário master dos bancos RDS"
  type        = string
  default     = "toggle_admin"
}

variable "db_password" {
  description = "Senha master dos bancos RDS"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe das instâncias RDS"
  type        = string
  default     = "db.t3.micro"
}
