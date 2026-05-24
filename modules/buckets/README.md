# Buckets Module

Creates S3 buckets used for infrastructure log storage, including VPC Flow Logs, EKS logs, and ALB access logs. Buckets are account/region-scoped, blocked from public access, and configured with lifecycle retention rules.

## Usage

```hcl
module "buckets" {
  source = "../../modules/buckets"

  vpc_flow_logs_bucket_prefix   = "vpc-flow-logs"
  eks_logs_bucket_prefix        = "eks-logs"
  alb_logs_bucket_prefix        = "alb-logs"
  alb_logs_prefix               = "alb"
  vpc_flow_logs_retention_days  = 365
  alb_logs_retention_days       = 365
  logs_bucket_kms_key_arn       = module.secrets.logs_bucket_kms_key_arn
}
```

## Notes

- Bucket names include the current AWS account ID and region.
- VPC Flow Logs and EKS logs use server-side encryption with the supplied KMS key.
- ALB access logs use SSE-S3 (`AES256`) because AWS ALB access logging does not support SSE-KMS buckets.
- Lifecycle rules transition objects to `STANDARD_IA` after 30 days, `GLACIER_IR` after 90 days, then expire them after the configured retention period.
- The VPC Flow Logs bucket policy document is generated in `data.tf`; attach it with an `aws_s3_bucket_policy` resource if bucket policy enforcement is required by the caller.
- The ALB access logs bucket policy is attached by this module and allows ELB log delivery to write under the configured prefix.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_flow_logs_bucket_prefix` | `string` | `vpc-flow-logs` | Prefix used in the VPC Flow Logs bucket name |
| `eks_logs_bucket_prefix` | `string` | `eks-logs` | Prefix used in the EKS logs bucket name |
| `alb_logs_bucket_prefix` | `string` | `alb-logs` | Prefix used in the ALB access logs bucket name |
| `alb_logs_prefix` | `string` | `alb` | S3 object prefix for ALB access logs |
| `vpc_flow_logs_retention_days` | `number` | `365` | Number of days before log objects expire |
| `alb_logs_retention_days` | `number` | `365` | Number of days before ALB access log objects expire |
| `logs_bucket_kms_key_arn` | `string` | `null` | KMS key ARN used for bucket encryption |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_flow_logs_bucket_arn` | ARN of the VPC Flow Logs bucket |
| `eks_logs_bucket_arn` | ARN of the EKS logs bucket |
| `alb_logs_bucket_arn` | ARN of the ALB access logs bucket |
| `alb_logs_bucket_name` | Name of the ALB access logs bucket |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
