variable "project_name" {
  description = "Used to name/tag resources, e.g. 'aws-three-tier-webapp'."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names/tags."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the security groups in (from the networking module)."
  type        = string
}

variable "app_port" {
  description = "Port the app listens on. The ALB forwards to it and the ALB SG may reach it."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port the app tier may reach."
  type        = number
  default     = 3306
}
