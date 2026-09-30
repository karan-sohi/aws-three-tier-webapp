# Database module
# Private RDS MySQL instance in the private subnets, reachable only through the DB SG.
# The master password is generated and stored in Secrets Manager by RDS itself
# (manage_master_user_password), so it never appears in code or Terraform state.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# RDS needs a subnet group spanning 2+ AZs, even for a single-AZ instance.
resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-db"

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  # RDS creates the secret (rds!db-...) holding {"username", "password"} and rotates it.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = var.backup_retention_period

  # Demo settings: we tear this down often, so no final snapshot or delete protection,
  # and changes apply now instead of waiting for the maintenance window.
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = {
    Name = "${local.name_prefix}-db"
    Tier = "data"
  }
}
