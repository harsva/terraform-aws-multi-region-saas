output "cluster_endpoint" {
  description = "Aurora writer endpoint."
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora reader endpoint."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint (use this from the app for graceful failover). Null if disabled."
  value       = var.enable_rds_proxy ? aws_db_proxy.this[0].endpoint : null
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "db_security_group_id" {
  description = "Security group ID of the database."
  value       = aws_security_group.db.id
}
