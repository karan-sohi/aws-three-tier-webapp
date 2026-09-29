variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag resources."
  type        = string
  default     = "aws-three-tier-webapp"
}

variable "environment" {
  description = "Environment name (dev/staging/prod). Used in tags and naming."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread public/private subnets across. Two is enough for the ALB requirement and matches the original build."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "alert_email" {
  description = "Email address for SNS alarm notifications (you'll need to confirm the subscription once)."
  type        = string
}

# --- App/DB tier variables (used by later modules; declared here now so the
# root module's shape is stable as we add modules module-by-module) ---

variable "instance_type" {
  description = "EC2 instance type for the app tier."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "guestbook"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "admin"
}
