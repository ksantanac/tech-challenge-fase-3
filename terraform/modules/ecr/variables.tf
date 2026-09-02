variable "project" {
  type = string
}

variable "services" {
  description = "Lista de microsserviços (um repositório ECR para cada)"
  type        = list(string)
}
