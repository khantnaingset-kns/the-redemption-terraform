output "fargate_cloudwatch_logs_policy_arn" {
  value       = aws_iam_policy.fargate_cloudwatch_logs_policy.arn
  description = "The ARN of the IAM policy for Fargate CloudWatch Logs"
}