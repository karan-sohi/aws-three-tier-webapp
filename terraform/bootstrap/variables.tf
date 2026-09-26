variable "aws_region" {
  description = "Region to create the state bucket and lock table in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Used as a naming prefix so bucket/table names are unique and identifiable."
  type        = string
  default     = "aws-three-tier-webapp"
}
