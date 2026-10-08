output "instance_id" {
  description = "Used by the ALB target group attachment and CloudWatch alarms."
  value       = aws_instance.app.id
}

output "private_ip" {
  value = aws_instance.app.private_ip
}

output "role_name" {
  value = aws_iam_role.app.name
}
