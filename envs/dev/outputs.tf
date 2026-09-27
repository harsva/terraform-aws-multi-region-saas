output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.compute.alb_dns_name
}

output "aurora_endpoint" {
  description = "Aurora writer endpoint."
  value       = module.database.cluster_endpoint
}

output "redis_endpoint" {
  description = "Redis primary endpoint."
  value       = module.cache.primary_endpoint_address
}
