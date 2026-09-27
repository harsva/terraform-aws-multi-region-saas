output "health_check_id" {
  description = "ID of the Route 53 health check."
  value       = aws_route53_health_check.this.id
}

output "record_fqdn" {
  description = "The failover record FQDN."
  value       = aws_route53_record.failover.fqdn
}
