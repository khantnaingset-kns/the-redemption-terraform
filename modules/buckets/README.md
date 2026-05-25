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
- VPC Flow Logs and EKS logs use server-side encryption with the supplied KMS key (SSE-KMS) and bucket key enabled.
- ALB access logs use SSE-S3 (`AES256`) because AWS ALB access logging does not support SSE-KMS buckets.
- Lifecycle rules transition objects to `STANDARD_IA` after 30 days, `GLACIER_IR` after 90 days, then expire them after the configured retention period.
- The VPC Flow Logs bucket policy document is generated in `data.tf`; attach it with an `aws_s3_bucket_policy` resource if bucket policy enforcement is required by the caller.
- The ALB access logs bucket policy is attached by this module and allows ELB log delivery to write under the configured prefix.
- All buckets have public access fully blocked and `BucketOwnerPreferred` ownership controls.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_flow_logs_bucket_prefix` | `string` | `vpc-flow-logs` | Prefix used in the VPC Flow Logs bucket name |
| `eks_logs_bucket_prefix` | `string` | `eks-logs` | Prefix used in the EKS logs bucket name |
| `alb_logs_bucket_prefix` | `string` | `alb-logs` | Prefix used in the ALB access logs bucket name |
| `alb_logs_prefix` | `string` | `alb` | S3 object prefix for ALB access logs |
| `vpc_flow_logs_retention_days` | `number` | `365` | Number of days before log objects expire |
| `alb_logs_retention_days` | `number` | `365` | Number of days before ALB access log objects expire |
| `logs_bucket_kms_key_arn` | `string` | `null` | KMS key ARN used for SSE-KMS encryption on VPC Flow Logs and EKS logs buckets |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_flow_logs_bucket_arn` | ARN of the VPC Flow Logs bucket |
| `eks_logs_bucket_arn` | ARN of the EKS logs bucket |
| `alb_logs_bucket_arn` | ARN of the ALB access logs bucket |
| `alb_logs_bucket_name` | Name of the ALB access logs bucket |

<!-- BEGIN_TF_DOCS -->
## Terraform Modules Docs

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.eks_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.alb_logs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flow_logs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_logs_bucket_prefix"></a> [alb\_logs\_bucket\_prefix](#input\_alb\_logs\_bucket\_prefix) | The prefix for the ALB access logs S3 bucket name | `string` | `"alb-logs"` | no |
| <a name="input_alb_logs_prefix"></a> [alb\_logs\_prefix](#input\_alb\_logs\_prefix) | S3 object prefix for ALB access logs | `string` | `"alb"` | no |
| <a name="input_alb_logs_retention_days"></a> [alb\_logs\_retention\_days](#input\_alb\_logs\_retention\_days) | The number of days to retain ALB access logs in the S3 bucket | `number` | `365` | no |
| <a name="input_eks_logs_bucket_prefix"></a> [eks\_logs\_bucket\_prefix](#input\_eks\_logs\_bucket\_prefix) | The prefix for the EKS Logs S3 bucket name | `string` | `"eks-logs"` | no |
| <a name="input_logs_bucket_kms_key_arn"></a> [logs\_bucket\_kms\_key\_arn](#input\_logs\_bucket\_kms\_key\_arn) | ARN of the KMS key to use for encrypting VPC Flow Logs in the S3 bucket | `string` | `null` | no |
| <a name="input_vpc_flow_logs_bucket_prefix"></a> [vpc\_flow\_logs\_bucket\_prefix](#input\_vpc\_flow\_logs\_bucket\_prefix) | The prefix for the VPC Flow Logs S3 bucket name | `string` | `"vpc-flow-logs"` | no |
| <a name="input_vpc_flow_logs_retention_days"></a> [vpc\_flow\_logs\_retention\_days](#input\_vpc\_flow\_logs\_retention\_days) | The number of days to retain VPC Flow Logs in the S3 bucket | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_logs_bucket_arn"></a> [alb\_logs\_bucket\_arn](#output\_alb\_logs\_bucket\_arn) | The ARN of the S3 bucket for ALB access logs |
| <a name="output_alb_logs_bucket_name"></a> [alb\_logs\_bucket\_name](#output\_alb\_logs\_bucket\_name) | The name of the S3 bucket for ALB access logs |
| <a name="output_eks_logs_bucket_arn"></a> [eks\_logs\_bucket\_arn](#output\_eks\_logs\_bucket\_arn) | The ARN of the S3 bucket for EKS logs |
| <a name="output_vpc_flow_logs_bucket_arn"></a> [vpc\_flow\_logs\_bucket\_arn](#output\_vpc\_flow\_logs\_bucket\_arn) | The ARN of the S3 bucket for VPC Flow Logs |
<!-- END_TF_DOCS -->
