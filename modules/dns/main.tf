# Route 53 health check against the regional ALB endpoint.
resource "aws_route53_health_check" "this" {
  fqdn              = var.alb_dns_name
  port              = var.health_check_port
  type              = var.health_check_protocol
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, { Name = "${var.name}-${var.region_role}-healthcheck" })
}

# Failover alias record. PRIMARY serves traffic while healthy; SECONDARY takes
# over automatically when the primary health check fails.
resource "aws_route53_record" "failover" {
  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "A"

  set_identifier = var.region_role # "PRIMARY" or "SECONDARY"

  failover_routing_policy {
    type = var.region_role
  }

  health_check_id = aws_route53_health_check.this.id

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
