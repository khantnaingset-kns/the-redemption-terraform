output "vpc_flow_logs_bucket_arn" {
  value       = aws_s3_bucket.vpc_flow_logs.arn
  description = "The ARN of the S3 bucket for VPC Flow Logs"
}
