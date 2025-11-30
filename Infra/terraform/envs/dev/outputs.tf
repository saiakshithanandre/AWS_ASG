output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.asg_app.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg_app.asg_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.asg_app.target_group_arn
}
