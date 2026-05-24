output "arn" {
  value       = aws_lb.this.arn
  description = "ALB ARN"
}

output "dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name"
}

output "zone_id" {
  value       = aws_lb.this.zone_id
  description = "ALB hosted zone ID"
}

output "security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ALB target group ARN"
}
