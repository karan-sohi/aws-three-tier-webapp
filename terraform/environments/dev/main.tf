

module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security_groups" {
  source = "../../modules/security_groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  app_port     = var.app_port
}

module "database" {
  source = "../../modules/database"

  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.networking.private_subnet_ids
  db_security_group_id = module.security_groups.db_security_group_id
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
}

module "app" {
  source = "../../modules/app"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  app_security_group_id = module.security_groups.app_security_group_id
  instance_type         = var.instance_type
  app_port              = var.app_port
  app_repo_url          = var.app_repo_url

  db_address    = module.database.db_address
  db_name       = module.database.db_name
  db_username   = module.database.db_username
  db_secret_arn = module.database.db_secret_arn
}
