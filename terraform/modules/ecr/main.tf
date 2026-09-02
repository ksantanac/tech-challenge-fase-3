resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  # Scan de vulnerabilidades automático ao enviar a imagem (DevSecOps).
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = each.value }
}
