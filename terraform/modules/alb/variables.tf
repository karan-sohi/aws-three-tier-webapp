variable "project_name" {
  description = "Used to name/tag resources, e.g. 'aws-three-tier-webapp'."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names/tags."
  type        = string
}

variable "vpc_id" {
  description = "VPC for the target group (from the networking module)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB - at least 2 AZs (from the networking module)."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group attached to the ALB (from the security_groups module)."
  type        = string
}

variable "app_instance_id" {
  description = "EC2 instance registered as the target (from the app module)."
  type        = string
}

variable "app_port" {
  description = "Port the app listens on - the target group forwards to it."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Path the target group health-checks. /health returns 200 only when the app can reach RDS."
  type        = string
  default     = "/health"
}
