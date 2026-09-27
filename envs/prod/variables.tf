variable "project" {
  description = "Project name."
  type        = string
  default     = "saas-platform"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "primary_region" {
  description = "Primary AWS region (active)."
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region (warm standby)."
  type        = string
  default     = "us-west-2"
}

# --- Primary network ---
variable "primary_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "primary_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
variable "primary_public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}
variable "primary_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
}
variable "primary_data_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.96.0/20", "10.0.112.0/20", "10.0.128.0/20"]
}

# --- Secondary network ---
variable "secondary_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
variable "secondary_azs" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
variable "secondary_public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/20"]
}
variable "secondary_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.48.0/20", "10.1.64.0/20", "10.1.80.0/20"]
}
variable "secondary_data_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.96.0/20", "10.1.112.0/20", "10.1.128.0/20"]
}

# --- Compute ---
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
variable "asg_min_size" {
  type    = number
  default = 2
}
variable "asg_max_size" {
  type    = number
  default = 6
}
variable "asg_desired_capacity" {
  type    = number
  default = 2
}
variable "app_port" {
  type    = number
  default = 8080
}
variable "health_check_path" {
  type    = string
  default = "/healthz"
}

# --- Database ---
variable "db_instance_class" {
  type    = string
  default = "db.r6g.large"
}

# --- Cache ---
variable "cache_node_type" {
  type    = string
  default = "cache.r6g.large"
}

# --- DNS (optional; leave hosted_zone_id empty to skip Route 53) ---
variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID. Empty string disables DNS failover records."
  type        = string
  default     = ""
}
variable "app_fqdn" {
  description = "Application FQDN for the failover record."
  type        = string
  default     = "app.example.com"
}
