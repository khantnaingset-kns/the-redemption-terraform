# IAM Module

Creates shared IAM resources consumed by other modules.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  eks_logs_bucket_arn = module.buckets.eks_logs_bucket_arn
}
```

## Notes

- The module currently creates a single CloudWatch Logs policy for EKS Fargate pods.
- The policy is intended to be passed into the EKS module as `fargate_cloudwatch_logs_policy_arn`.
- It also creates an S3 access policy for logging workloads that write to the EKS logs bucket.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `eks_logs_bucket_arn` | `string` | n/a | ARN of the EKS logs bucket granted to logging workloads |

## Outputs

| Name | Description |
|------|-------------|
| `fargate_cloudwatch_logs_policy_arn` | ARN of the Fargate CloudWatch Logs IAM policy |
| `logging_s3_access_policy_arn` | ARN of the S3 logging access IAM policy |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
