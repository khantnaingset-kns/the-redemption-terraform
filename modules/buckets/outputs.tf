output "vpc_flow_logs_bucket_arn" {
  value       = aws_s3_bucket.vpc_flow_logs.arn
  description = "The ARN of the S3 bucket for VPC Flow Logs"
}

output "eks_logs_bucket_arn" {
  value       = aws_s3_bucket.eks_logs.arn
  description = "The ARN of the S3 bucket for EKS logs"
}

output "alb_logs_bucket_arn" {
  value       = aws_s3_bucket.alb_logs.arn
  description = "The ARN of the S3 bucket for ALB access logs"
}

output "alb_logs_bucket_name" {
  value       = aws_s3_bucket.alb_logs.bucket
  description = "The name of the S3 bucket for ALB access logs"
}
