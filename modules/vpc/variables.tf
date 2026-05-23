variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)"
  }
}

variable "vpc_flow_log_iam_role_arn" {
  description = "ARN of the IAM role to use for VPC Flow Logs (optional)"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_flow_log_iam_role_arn == null || can(regex("^arn:aws:iam::[0-9]+:role/.+$", var.vpc_flow_log_iam_role_arn))
    error_message = "vpc_flow_log_iam_role_arn must be a valid IAM role ARN if provided."
  }
}

variable "aws_cloudwatch_vpc_flow_log_group_arn" {
  description = "ARN of the CloudWatch log group to use for VPC Flow Logs (optional)"
  type        = string
  default     = null

  validation {
    condition     = var.aws_cloudwatch_vpc_flow_log_group_arn == null || can(regex("^arn:aws:logs:[^:]+:[0-9]+:log-group:.+$", var.aws_cloudwatch_vpc_flow_log_group_arn))
    error_message = "aws_cloudwatch_vpc_flow_log_group_arn must be a valid CloudWatch log group ARN if provided."
  }
}

variable "public_subnet_cidr" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidr) > 0
    error_message = "At least one CIDR block must be provided for public subnets."
  }

}

variable "private_subnet_cidr" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidr) > 0
    error_message = "At least one CIDR block must be provided for private subnets."
  }
}

variable "isolated_subnet_cidr" {
  description = "List of CIDR blocks for the isolated subnets"
  type        = list(string)

  validation {
    condition     = length(var.isolated_subnet_cidr) > 0
    error_message = "At least one CIDR block must be provided for isolated subnets."
  }
}

variable "intra_subnet_cidr" {
  description = "List of CIDR blocks for the intra subnets"
  type        = list(string)

  validation {
    condition     = length(var.intra_subnet_cidr) > 0
    error_message = "At least one CIDR block must be provided for intra subnets."
  }
}

variable "azs" {
  description = "List of availability zones for the subnets"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= max(length(var.public_subnet_cidr), length(var.private_subnet_cidr), length(var.isolated_subnet_cidr), length(var.intra_subnet_cidr))
    error_message = "The number of availability zones must be at least equal to the largest subnet tier."
  }

}


variable "create_nat" {
  description = "Boolean flag to specify if a NAT gateway should be created"
  type        = bool
  default     = true
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment name cannot be empty."
  }
}

variable "enable_eks_tags" {
  description = "Whether to add EKS-specific tags (kubernetes.io/role/elb, karpenter.sh/discovery) to subnets"
  type        = bool
  default     = true
}


variable "vpc_flow_logs_bucket_arn" {
  description = "ARN of the S3 bucket to use for VPC Flow Logs (optional)"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_flow_logs_bucket_arn == null || can(regex("^arn:aws:s3:::[^/]+$", var.vpc_flow_logs_bucket_arn))
    error_message = "vpc_flow_logs_bucket_arn must be a valid S3 bucket ARN if provided."
  }
}

variable "cluster_name" {
  description = "The name of the EKS cluster (required when enable_eks_tags is true)"
  type        = string
  default     = null

  validation {
    condition     = var.enable_eks_tags == false || var.cluster_name != null
    error_message = "cluster_name is required when enable_eks_tags is true."
  }
}
