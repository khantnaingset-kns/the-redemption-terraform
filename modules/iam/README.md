# IAM Module

Creates shared IAM policies consumed by the EKS module: Fargate CloudWatch Logs, S3 logging access, and ALB Controller permissions.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  eks_logs_bucket_arn = module.buckets.eks_logs_bucket_arn
}
```

## Notes

- `fargate_cloudwatch_logs_policy` — allows Fargate pods in `kube-system` and `argocd` to write to CloudWatch Logs. Passed to the EKS module as `fargate_cloudwatch_logs_policy_arn`.
- `logging_s3_access` — grants full S3 access to the EKS logs bucket. Used by the Loki IRSA role in the EKS module. Passed as `logging_s3_access_policy_arn`.
- `alb_controller_policy` — contains the standard permissions required by the AWS Load Balancer Controller. Does not include `wafv2:GetWebACL` — only `wafv2` and `waf-regional` describe/associate/disassociate actions plus Shield, IAM, Cognito, and ACM read permissions.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `eks_logs_bucket_arn` | `string` | — | ARN of the EKS logs bucket granted to logging workloads |

## Outputs

| Name | Description |
|------|-------------|
| `fargate_cloudwatch_logs_policy_arn` | ARN of the Fargate CloudWatch Logs IAM policy |
| `logging_s3_access_policy_arn` | ARN of the S3 logging access IAM policy |
| `alb_controller_policy_arn` | ARN of the AWS Load Balancer Controller IAM policy |

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
| [aws_iam_policy.alb_controller_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.fargate_cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.logging_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_logs_bucket_arn"></a> [eks\_logs\_bucket\_arn](#input\_eks\_logs\_bucket\_arn) | The ARN of the S3 bucket for EKS logs | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_controller_policy_arn"></a> [alb\_controller\_policy\_arn](#output\_alb\_controller\_policy\_arn) | The ARN of the IAM policy for the AWS Load Balancer Controller |
| <a name="output_fargate_cloudwatch_logs_policy_arn"></a> [fargate\_cloudwatch\_logs\_policy\_arn](#output\_fargate\_cloudwatch\_logs\_policy\_arn) | The ARN of the IAM policy for Fargate CloudWatch Logs |
| <a name="output_logging_s3_access_policy_arn"></a> [logging\_s3\_access\_policy\_arn](#output\_logging\_s3\_access\_policy\_arn) | The ARN of the IAM policy for S3 access for logging |
<!-- END_TF_DOCS -->
