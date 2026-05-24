# Secrets Module

Creates encryption resources used by infrastructure log storage.

## Usage

```hcl
module "secrets" {
  source = "../../modules/secrets"

  vpc_name    = "redemption-prod-vpc"
  environment = "prod"

  kms_admin_principal_arns = [
    "arn:aws:iam::123456789012:role/platform-admin"
  ]
}
```

## Notes

- The module creates a KMS key and alias for S3 log bucket encryption.
- The key policy allows account root IAM delegation and VPC Flow Logs delivery service usage.
- Additional IAM users or roles can be granted key administration through `kms_admin_principal_arns`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_name` | `string` | n/a | VPC name used in KMS key tagging |
| `environment` | `string` | `dev` | Environment used in the KMS alias name |
| `kms_admin_principal_arns` | `list(string)` | `[]` | IAM user or role ARNs allowed to administer the KMS key |

## Outputs

| Name | Description |
|------|-------------|
| `logs_bucket_kms_key_arn` | ARN of the KMS key for encrypted log buckets |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
