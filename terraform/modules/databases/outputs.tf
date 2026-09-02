output "rds_endpoints" {
  description = "Map serviço -> endpoint (host:porta) do RDS"
  value       = { for k, db in aws_db_instance.postgres : k => db.endpoint }
}

output "rds_addresses" {
  description = "Map serviço -> host do RDS (sem porta)"
  value       = { for k, db in aws_db_instance.postgres : k => db.address }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}
