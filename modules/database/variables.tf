variable "name" {
  description = "Name prefix for database resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "data_subnet_ids" {
  description = "Isolated data subnets for the DB subnet group (min 2 AZs)."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the app tier allowed to reach the DB/proxy."
  type        = string
}

variable "engine_version" {
  description = "Aurora MySQL engine version."
  type        = string
  default     = "8.0.mysql_aurora.3.05.2"
}

variable "instance_class" {
  description = "Aurora instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "reader_count" {
  description = "Number of Aurora reader instances (for HA/read scaling)."
  type        = number
  default     = 1
}

variable "database_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "backup_retention_days" {
  description = "Automated backup retention period."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection (recommended for prod)."
  type        = bool
  default     = true
}

variable "enable_rds_proxy" {
  description = "Provision an RDS Proxy in front of Aurora for graceful failover and connection pooling."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for storage and secret encryption. If null, the AWS-managed key is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
