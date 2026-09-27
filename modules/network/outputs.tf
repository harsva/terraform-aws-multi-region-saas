output "vpc_id" {
  description = "The VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private (app) subnets."
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "IDs of the isolated data subnets."
  value       = aws_subnet.data[*].id
}
