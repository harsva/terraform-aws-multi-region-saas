variable "name" {
  description = "Name prefix for all network resources."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of Availability Zones to spread subnets across (min 2 for HA)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least two Availability Zones are required for multi-AZ high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT). One per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (EC2 ASG). One per AZ."
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for isolated data subnets (Aurora, Redis). One per AZ."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost-optimized, dev) instead of one per AZ (HA, prod)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch for network observability."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention period for VPC flow logs in CloudWatch."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
