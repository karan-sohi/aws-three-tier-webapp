output "db_instance_id" {
  value = aws_db_instance.this.identifier
}

output "db_address" {
  description = "Hostname only (no port) - this is what the app's DB_HOST needs."
  value       = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "db_username" {
  value = aws_db_instance.this.username
}

output "db_secret_arn" {
  description = "ARN of the RDS-managed secret - the app's DB_SECRET_ID, and what its IAM policy is scoped to."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
