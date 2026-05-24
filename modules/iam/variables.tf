variable "eks_logs_bucket_arn" {
  description = "The ARN of the S3 bucket for EKS logs"
  type        = string

  validation {
    condition     = var.eks_logs_bucket_arn == null || can(regex("^arn:aws:s3:::[^:]+$", var.eks_logs_bucket_arn))
    error_message = "eks_logs_bucket_arn must be a valid S3 bucket ARN if provided."
  }
}
