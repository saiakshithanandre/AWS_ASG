output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.app_tg.arn
}
