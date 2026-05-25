output "web_acl_arn" {
  value       = aws_wafv2_web_acl.this.arn
  description = "ARN of the WAFv2 Web ACL"
}

output "web_acl_name" {
  value       = aws_wafv2_web_acl.this.name
  description = "Name of the WAFv2 Web ACL"
}

output "web_acl_capacity" {
  value       = aws_wafv2_web_acl.this.capacity
  description = "Capacity units consumed by the Web ACL"
}
