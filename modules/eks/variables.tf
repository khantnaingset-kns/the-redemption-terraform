variable "environment" {
  description = "The environment for which the resources are being provisioned (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment cannot be an empty string."
  }
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name cannot be an empty string."
  }
}

variable "private_subnets" {
  description = "List of private subnet IDs to be used for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "At least one private subnet ID must be provided."
  }
}

variable "intra_subnets" {
  description = "List of private subnet IDs to be used for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.intra_subnets) > 0
    error_message = "At least one private subnet ID must be provided."
  }
}

variable "control_plane_scaling_config" {
  description = "Configuration for control plane scaling"
  type = object({
    tier = string
  })

  validation {
    condition     = var.control_plane_scaling_config.tier == "standard" || var.control_plane_scaling_config.tier == "tier-xl" || var.control_plane_scaling_config.tier == "tier-2xl" || var.control_plane_scaling_config.tier == "tier-4xl" || var.control_plane_scaling_config.tier == "tier-8xl"
    error_message = "Control plane scaling tier must be either 'standard' or 'tier-xl' or 'tier-2xl' or 'tier-4xl' or 'tier-8xl'."
  }
}

variable "fargate_cloudwatch_logs_policy_arn" {
  description = "The ARN of the IAM policy for Fargate CloudWatch Logs"
  type        = string

  validation {
    condition     = length(var.fargate_cloudwatch_logs_policy_arn) > 0
    error_message = "Fargate logs policy ARN cannot be an empty string."
  }
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be deployed"
  type        = string

  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "VPC ID cannot be an empty string."
  }
}

variable "karpenter_chart_version" {
  description = "The version of the Karpenter Helm chart to deploy"
  type        = string

  validation {
    condition     = length(var.karpenter_chart_version) > 0
    error_message = "Karpenter chart version cannot be an empty string."
  }

}

variable "argocd_admin_group_display_name" {
  description = "Identity Center group display name to map as ArgoCD administrator"
  type        = string
  default     = "AWSAdministratorAccess"

  validation {
    condition     = length(var.argocd_admin_group_display_name) > 0
    error_message = "ArgoCD admin group display name cannot be empty."
  }
}
variable "alb_sg_id" {
  description = "The ID of the security group to allow inbound access from ALB"
  type        = string

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.alb_sg_id))
    error_message = "alb_sg_id must be a valid security group ID (e.g., sg-123abc)."
  }
}