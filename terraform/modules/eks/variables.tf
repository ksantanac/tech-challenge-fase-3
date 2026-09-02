variable "project" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "lab_role_arn" {
  description = "ARN da LabRole (usada pelo cluster e node group)"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  type = string
}

variable "node_desired" {
  type = number
}
variable "node_min" {
  type = number
}
variable "node_max" {
  type = number
}
