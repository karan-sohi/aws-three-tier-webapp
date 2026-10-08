output "alb_dns_name" {
  description = "Public DNS name of the load balancer - open it in a browser."
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "The 'LoadBalancer' dimension for ALB metrics in CloudWatch (monitoring module)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "The 'TargetGroup' dimension for target metrics in CloudWatch (monitoring module)."
  value       = aws_lb_target_group.app.arn_suffix
}
