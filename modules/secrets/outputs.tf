output "logs_bucket_kms_key_arn" {
  value       = aws_kms_key.logs_bucket_kms_key.arn
  description = "The ARN of the KMS key used for encrypting VPC Flow Logs in the S3 bucket"
}
