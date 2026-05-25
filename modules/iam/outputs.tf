output "fargate_cloudwatch_logs_policy_arn" {
  value       = aws_iam_policy.fargate_cloudwatch_logs_policy.arn
  description = "The ARN of the IAM policy for Fargate CloudWatch Logs"
}

output "logging_s3_access_policy_arn" {
  value       = aws_iam_policy.logging_s3_access.arn
  description = "The ARN of the IAM policy for S3 access for logging"
}

output "alb_controller_policy_arn" {
  value       = aws_iam_policy.alb_controller_policy.arn
  description = "The ARN of the IAM policy for the AWS Load Balancer Controller"
}