variable "project_name" {
  description = "Used to name/tag resources, e.g. 'aws-three-tier-webapp'."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names/tags."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group (from the networking module)."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group attached to the DB (from the security_groups module)."
  type        = string
}

variable "engine_version" {
  description = "MySQL major version. 8.0 left RDS standard support on 2026-07-31 and bills Extended Support, so use 8.4."
  type        = string
  default     = "8.4"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB. 20 is the minimum and within the free tier."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database created on the instance."
  type        = string
  default     = "guestbook"
}

variable "db_username" {
  description = "Master username. The password is managed by RDS in Secrets Manager."
  type        = string
  default     = "admin"
}

variable "backup_retention_period" {
  description = "Days of automated backups to keep. 0 disables them."
  type        = number
  default     = 1
}
