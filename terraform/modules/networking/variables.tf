variable "project_name" {
  description = "Used to name/tag resources, e.g. 'aws-three-tier-webapp'."
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names/tags."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC, e.g. 10.0.0.0/16."
  type        = string
}

variable "availability_zones" {
  description = "AZs to spread subnets across. One public + one private subnet is created per AZ."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least 2 AZs - the ALB requires subnets in 2+ AZs."
  }
}
