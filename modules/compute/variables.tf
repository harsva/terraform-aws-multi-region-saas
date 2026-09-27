variable "name" {
  description = "Name prefix for compute resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for the ASG instances."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID. If null, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = null
}

variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/healthz"
}

variable "user_data" {
  description = "User data script for instances."
  type        = string
  default     = "#!/bin/bash\necho 'bootstrap'\n"
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach (e.g. for SSM/CloudWatch agent)."
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum ASG size."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired ASG capacity."
  type        = number
  default     = 2
}

variable "cpu_target_utilization" {
  description = "Target average CPU utilization for target-tracking autoscaling."
  type        = number
  default     = 60
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. If null, only HTTP listener is created."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection (recommended for prod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
