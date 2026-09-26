output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}

output "backend_config_snippet" {
  description = "Paste this into environments/dev/backend.tf"
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.tf_state.bucket}"
    dynamodb_table = "${aws_dynamodb_table.tf_lock.name}"
  EOT
}
