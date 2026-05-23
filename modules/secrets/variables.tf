variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "kms_admin_principal_arns" {
  type        = list(string)
  default     = []
  description = "Existing IAM role/user ARNs allowed to administer the VPC Flow Logs bucket KMS key."

  validation {
    condition     = alltrue([for arn in var.kms_admin_principal_arns : can(regex("^arn:aws:iam::[0-9]+:(user|role)/.+$", arn))])
    error_message = "All entries in kms_admin_principal_arns must be valid IAM role or user ARNs."
  }
}

variable "environment" {
  description = "The environment for which the resources are being provisioned (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment cannot be an empty string."
  }
}