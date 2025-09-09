variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group for ALB monitoring"
  type        = string
  default     = ""
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer for ALB monitoring"
  type        = string
  default     = ""
}
