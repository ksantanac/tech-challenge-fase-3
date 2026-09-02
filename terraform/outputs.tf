output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint da API do EKS"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Comando para conectar o kubectl ao cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR (por serviço)"
  value       = module.ecr.repository_urls
}

output "rds_endpoints" {
  description = "Endpoints das 3 instâncias RDS"
  value       = module.databases.rds_endpoints
}

output "redis_endpoint" {
  description = "Endpoint do ElastiCache Redis"
  value       = module.databases.redis_endpoint
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = module.databases.dynamodb_table_name
}

output "sqs_queue_url" {
  description = "URL da fila SQS"
  value       = module.messaging.queue_url
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
