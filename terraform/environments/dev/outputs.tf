output "vpc_id" {
  description = "ID of the VPC created for this environment."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "alb_security_group_id" {
  value = module.security_groups.alb_security_group_id
}

output "app_security_group_id" {
  value = module.security_groups.app_security_group_id
}

output "db_security_group_id" {
  value = module.security_groups.db_security_group_id
}

output "db_address" {
  value = module.database.db_address
}

output "db_secret_arn" {
  value = module.database.db_secret_arn
}

output "app_instance_id" {
  value = module.app.instance_id
}
