variable "aws_region" {
  description = "AWS region for all prod resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Base EKS cluster name"
  type        = string
}

variable "vpc_name" {
  description = "Optional explicit VPC name. Defaults to environment-cluster_name-vpc."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones for subnet placement"
  type        = list(string)
}

variable "create_nat" {
  description = "Whether to create a NAT gateway for private subnet egress"
  type        = bool
  default     = true
}

variable "enable_eks_tags" {
  description = "Whether to add EKS/Karpenter discovery tags to VPC subnets"
  type        = bool
  default     = true
}

variable "kms_admin_principal_arns" {
  description = "IAM principal ARNs allowed to administer the logs KMS key"
  type        = list(string)
  default     = []
}

variable "vpc_flow_logs_bucket_prefix" {
  description = "Prefix for the VPC Flow Logs bucket"
  type        = string
  default     = "vpc-flow-logs"
}

variable "eks_logs_bucket_prefix" {
  description = "Prefix for the EKS logs bucket"
  type        = string
  default     = "eks-logs"
}

variable "alb_logs_bucket_prefix" {
  description = "Prefix for the ALB access logs bucket"
  type        = string
  default     = "alb-logs"
}

variable "vpc_flow_logs_retention_days" {
  description = "Number of days to retain log objects"
  type        = number
  default     = 365
}

variable "alb_logs_retention_days" {
  description = "Number of days to retain ALB access log objects"
  type        = number
  default     = 365
}

variable "alb_name" {
  description = "Optional explicit ALB name. Defaults to environment-cluster_name-alb."
  type        = string
  default     = ""
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb"
}

variable "alb_allowed_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the public ALB over HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "control_plane_scaling_tier" {
  description = "EKS control plane scaling tier"
  type        = string
  default     = "standard"
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version"
  type        = string
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
}

variable "db_instance_name" {
  description = "Optional explicit RDS instance identifier. Defaults to environment-cluster_name-db."
  type        = string
  default     = ""
}

variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "RDS database engine version"
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "theredemption"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB for RDS autoscaling"
  type        = number
  default     = 100
}

variable "db_performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "waf_trusted_ips" {
  description = "List of IP addresses to add to the WAF trusted IP set (prod only)"
  type        = list(string)
  default     = []
}
