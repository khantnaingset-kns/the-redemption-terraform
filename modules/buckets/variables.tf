variable "vpc_flow_logs_bucket_prefix" {
  description = "The prefix for the VPC Flow Logs S3 bucket name"
  type        = string
  default     = "vpc-flow-logs"
}

variable "eks_logs_bucket_prefix" {
  description = "The prefix for the EKS Logs S3 bucket name"
  type        = string
  default     = "eks-logs"
}

variable "alb_logs_bucket_prefix" {
  description = "The prefix for the ALB access logs S3 bucket name"
  type        = string
  default     = "alb-logs"
}

variable "alb_logs_prefix" {
  description = "S3 object prefix for ALB access logs"
  type        = string
  default     = "alb"

  validation {
    condition     = !can(regex("(^|/)AWSLogs($|/)", var.alb_logs_prefix))
    error_message = "alb_logs_prefix must not include AWSLogs; ALB adds that path automatically."
  }
}

variable "vpc_flow_logs_retention_days" {
  description = "The number of days to retain VPC Flow Logs in the S3 bucket"
  type        = number
  default     = 365
}

variable "alb_logs_retention_days" {
  description = "The number of days to retain ALB access logs in the S3 bucket"
  type        = number
  default     = 365
}

variable "logs_bucket_kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting VPC Flow Logs in the S3 bucket"
  type        = string
  default     = null

  validation {
    condition     = var.logs_bucket_kms_key_arn == null || can(regex("^arn:aws:kms:[^:]+:[0-9]+:key/.+$", var.logs_bucket_kms_key_arn))
    error_message = "logs_bucket_kms_key_arn must be a valid KMS key ARN if provided."
  }
}
