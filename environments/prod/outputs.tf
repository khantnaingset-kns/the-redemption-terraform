output "vpc_id" {
  value       = module.vpc.vpc
  description = "Prod VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Prod public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Prod private subnet IDs"
}

output "isolated_subnet_ids" {
  value       = module.vpc.isolated_subnet_ids
  description = "Prod isolated subnet IDs"
}

output "intra_subnet_ids" {
  value       = module.vpc.intra_subnet_ids
  description = "Prod intra subnet IDs"
}

output "vpc_flow_logs_bucket_arn" {
  value       = module.buckets.vpc_flow_logs_bucket_arn
  description = "Prod VPC Flow Logs bucket ARN"
}

output "eks_logs_bucket_arn" {
  value       = module.buckets.eks_logs_bucket_arn
  description = "Prod EKS logs bucket ARN"
}

output "alb_logs_bucket_arn" {
  value       = module.buckets.alb_logs_bucket_arn
  description = "Prod ALB access logs bucket ARN"
}

output "logs_bucket_kms_key_arn" {
  value       = module.secrets.logs_bucket_kms_key_arn
  description = "Prod logs bucket KMS key ARN"
}

output "fargate_cloudwatch_logs_policy_arn" {
  value       = module.iam.fargate_cloudwatch_logs_policy_arn
  description = "Prod Fargate CloudWatch Logs policy ARN"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Prod EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Prod EKS cluster API endpoint"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "Prod EKS OIDC provider ARN"
}

output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "Prod ALB DNS name"
}

output "alb_target_group_arn" {
  value       = module.alb.target_group_arn
  description = "Prod ALB target group ARN"
}

output "db_secrets_manager_secret_arn" {
  value       = module.database.secrets_manager_secret_arn
  description = "Prod RDS Secrets Manager secret ARN"
}

output "db_endpoint" {
  value       = module.database.db_endpoint
  description = "Prod RDS endpoint"
}

output "db_port" {
  value       = module.database.db_port
  description = "Prod RDS port"
}

output "db_instance_arn" {
  value       = module.database.db_instance_arn
  description = "Prod RDS instance ARN"
}

output "db_security_group_id" {
  value       = module.database.security_group_id
  description = "Prod RDS security group ID"
}

output "waf_web_acl_arn" {
  value       = module.waf.web_acl_arn
  description = "Prod WAF Web ACL ARN"
}

output "waf_web_acl_name" {
  value       = module.waf.web_acl_name
  description = "Prod WAF Web ACL name"
}
