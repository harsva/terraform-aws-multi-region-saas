variable "name" {
  description = "Name prefix."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  type        = string
}

variable "record_name" {
  description = "FQDN for the application (e.g. app.example.com)."
  type        = string
}

variable "region_role" {
  description = "Failover role for this region: PRIMARY or SECONDARY."
  type        = string

  validation {
    condition     = contains(["PRIMARY", "SECONDARY"], var.region_role)
    error_message = "region_role must be either PRIMARY or SECONDARY."
  }
}

variable "alb_dns_name" {
  description = "DNS name of the regional ALB."
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the regional ALB."
  type        = string
}

variable "health_check_path" {
  description = "Path used by the Route 53 health check."
  type        = string
  default     = "/healthz"
}

variable "health_check_port" {
  description = "Port used by the Route 53 health check."
  type        = number
  default     = 443
}

variable "health_check_protocol" {
  description = "Protocol used by the Route 53 health check (HTTP or HTTPS)."
  type        = string
  default     = "HTTPS"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
