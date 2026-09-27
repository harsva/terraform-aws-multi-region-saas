variable "name" {
  description = "Name prefix for cache resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "data_subnet_ids" {
  description = "Isolated data subnets for the cache subnet group."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the app tier allowed to reach Redis."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.r6g.large"
}

variable "num_cache_clusters" {
  description = "Number of nodes in the replication group (>=2 enables automatic failover)."
  type        = number
  default     = 2

  validation {
    condition     = var.num_cache_clusters >= 1
    error_message = "num_cache_clusters must be at least 1."
  }
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "kms_key_arn" {
  description = "KMS key ARN for at-rest encryption. If null, the AWS-managed key is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
