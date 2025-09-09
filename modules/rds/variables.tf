variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "ID of the database security group"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance"
  type        = number
}

variable "monitoring_role_arn" {
  description = "ARN of the monitoring role for RDS"
  type        = string
}

variable "enable_rds_proxy" {
  description = "Whether to enable RDS Proxy"
  type        = bool
  default     = false
}
