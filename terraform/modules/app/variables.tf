variable "project_name" {
  description = "Used to name/tag resources, e.g. 'aws-three-tier-webapp'."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names/tags."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets (from the networking module). The instance goes in the first one."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group attached to the instance (from the security_groups module)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port gunicorn listens on. Must match the app SG rule and the ALB target group."
  type        = number
  default     = 8080
}

variable "app_repo_url" {
  description = "Git repo cloned at boot. Must be public - the instance has no Git credentials."
  type        = string
}

variable "app_repo_ref" {
  description = "Branch or tag to clone."
  type        = string
  default     = "main"
}

# --- From the database module ---

variable "db_address" {
  description = "RDS hostname, without the port. Becomes DB_HOST."
  type        = string
}

variable "db_name" {
  description = "Database name. Becomes DB_NAME."
  type        = string
}

variable "db_username" {
  description = "DB master username. Becomes DB_USER."
  type        = string
}

variable "db_secret_arn" {
  description = "RDS-managed secret ARN. Becomes DB_SECRET_ID, and is the only secret the role may read."
  type        = string
}
