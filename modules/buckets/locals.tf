locals {
  alb_logs_prefix      = trimsuffix(trimprefix(var.alb_logs_prefix, "/"), "/")
  alb_logs_path_prefix = local.alb_logs_prefix == "" ? "AWSLogs" : "${local.alb_logs_prefix}/AWSLogs"

  bucket_name_suffix = format("%s-%s", data.aws_caller_identity.this.account_id, replace(data.aws_region.this.region, "-", ""))

  vpc_flow_logs_bucket_name = format("%s-%s", local.bucket_name_suffix, substr(var.vpc_flow_logs_bucket_prefix, 0, 63 - length(local.bucket_name_suffix) - 1))
  eks_logs_bucket_name      = format("%s-%s", local.bucket_name_suffix, substr(var.eks_logs_bucket_prefix, 0, 63 - length(local.bucket_name_suffix) - 1))
  alb_logs_bucket_name      = format("%s-%s", local.bucket_name_suffix, substr(var.alb_logs_bucket_prefix, 0, 63 - length(local.bucket_name_suffix) - 1))
}
