output "primary_endpoint_address" {
  description = "Primary endpoint for the Redis replication group."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint for the Redis replication group."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "cache_security_group_id" {
  description = "Security group ID of the cache."
  value       = aws_security_group.cache.id
}
