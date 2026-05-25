locals {
  vpc_name = var.vpc_name != "" ? var.vpc_name : "${var.environment}-${var.cluster_name}-vpc"
  alb_name = var.alb_name != "" ? var.alb_name : "${var.environment}-${var.cluster_name}-alb"

  subnet_newbits = 4
  az_count       = length(var.azs)

  public_subnet_cidr   = [for index in range(local.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, index)]
  private_subnet_cidr  = [for index in range(local.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, index + local.az_count)]
  isolated_subnet_cidr = [for index in range(local.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, index + (local.az_count * 2))]
  intra_subnet_cidr    = [for index in range(local.az_count) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, index + (local.az_count * 3))]
}

module "secrets" {
  source = "../../modules/secrets"

  vpc_name                 = local.vpc_name
  environment              = var.environment
  kms_admin_principal_arns = var.kms_admin_principal_arns
}

module "buckets" {
  source = "../../modules/buckets"

  vpc_flow_logs_bucket_prefix  = var.vpc_flow_logs_bucket_prefix
  eks_logs_bucket_prefix       = var.eks_logs_bucket_prefix
  alb_logs_bucket_prefix       = var.alb_logs_bucket_prefix
  alb_logs_prefix              = var.alb_access_logs_prefix
  vpc_flow_logs_retention_days = var.vpc_flow_logs_retention_days
  alb_logs_retention_days      = var.alb_logs_retention_days
  logs_bucket_kms_key_arn      = module.secrets.logs_bucket_kms_key_arn
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = local.vpc_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = local.public_subnet_cidr
  private_subnet_cidr  = local.private_subnet_cidr
  isolated_subnet_cidr = local.isolated_subnet_cidr
  intra_subnet_cidr    = local.intra_subnet_cidr
  azs                  = var.azs

  create_nat      = var.create_nat
  environment     = var.environment
  enable_eks_tags = var.enable_eks_tags
  cluster_name    = var.cluster_name

  vpc_flow_logs_bucket_arn              = module.buckets.vpc_flow_logs_bucket_arn
  vpc_flow_log_iam_role_arn             = null
  aws_cloudwatch_vpc_flow_log_group_arn = null
}

module "iam" {
  source = "../../modules/iam"

  eks_logs_bucket_arn = module.buckets.eks_logs_bucket_arn
}

module "alb" {
  source = "../../modules/alb"

  alb_name                    = local.alb_name
  vpc_id                      = module.vpc.vpc
  public_subnet_ids           = module.vpc.public_subnet_ids
  access_logs_bucket_name     = module.buckets.alb_logs_bucket_name
  access_logs_prefix          = var.alb_access_logs_prefix
  allowed_ingress_cidr_blocks = var.alb_allowed_ingress_cidr_blocks

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

module "eks" {
  source = "../../modules/eks"

  environment                        = var.environment
  cluster_name                       = var.cluster_name
  vpc_id                             = module.vpc.vpc
  private_subnets                    = module.vpc.private_subnet_ids
  intra_subnets                      = module.vpc.intra_subnet_ids
  alb_sg_id                          = module.alb.security_group_id
  fargate_cloudwatch_logs_policy_arn = module.iam.fargate_cloudwatch_logs_policy_arn
  logging_s3_access_policy_arn       = module.iam.logging_s3_access_policy_arn
  karpenter_chart_version            = var.karpenter_chart_version
  argocd_chart_version               = var.argocd_chart_version

  control_plane_scaling_config = {
    tier = var.control_plane_scaling_tier
  }
}

module "database" {
  source = "../../modules/database"

  vpc_id           = module.vpc.vpc
  sg_name          = "${var.environment}-${var.cluster_name}-db-sg"
  db_subnet_ids    = module.vpc.isolated_subnet_ids
  db_instance_name = var.db_instance_name != "" ? var.db_instance_name : "${var.environment}-${var.cluster_name}-db"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  db_name        = var.db_name
  db_username    = var.db_username

  allocated_storage                     = var.db_allocated_storage
  max_allocated_storage                 = var.db_max_allocated_storage
  performance_insights_retention_period = var.db_performance_insights_retention_period

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr
      description = "PostgreSQL from VPC"
    }
  ]

}

module "waf" {
  source = "../../modules/waf"

  environment = var.environment
  alb_arn     = module.alb.arn
  trusted_ips = var.waf_trusted_ips
}
