locals {
  alb_logs_prefix      = trimsuffix(trimprefix(var.alb_logs_prefix, "/"), "/")
  alb_logs_path_prefix = local.alb_logs_prefix == "" ? "AWSLogs" : "${local.alb_logs_prefix}/AWSLogs"
}
