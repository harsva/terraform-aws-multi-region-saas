output "primary_alb_dns_name" {
  description = "Primary region ALB DNS name."
  value       = module.compute_primary.alb_dns_name
}

output "secondary_alb_dns_name" {
  description = "Secondary region ALB DNS name."
  value       = module.compute_secondary.alb_dns_name
}

output "primary_db_proxy_endpoint" {
  description = "Primary Aurora RDS Proxy endpoint (app connects here)."
  value       = module.database_primary.proxy_endpoint
}

output "primary_redis_endpoint" {
  description = "Primary region Redis primary endpoint."
  value       = module.cache_primary.primary_endpoint_address
}

output "secondary_redis_endpoint" {
  description = "Secondary region Redis primary endpoint."
  value       = module.cache_secondary.primary_endpoint_address
}

output "app_fqdn" {
  description = "Application FQDN (Route 53 failover), if DNS is enabled."
  value       = var.hosted_zone_id != "" ? var.app_fqdn : "DNS disabled (hosted_zone_id not set)"
}
