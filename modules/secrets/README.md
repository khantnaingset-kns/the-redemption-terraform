# Secrets Module

Creates a KMS key for S3 log bucket encryption with auto-rotation and configurable key administrators.

## Usage

```hcl
module "secrets" {
  source = "../../modules/secrets"

  vpc_name    = "prod-redemption-vpc"
  environment = "prod"

  kms_admin_principal_arns = [
    "arn:aws:iam::123456789012:role/platform-admin"
  ]
}
```

## Notes

- The KMS key uses a 30-day deletion window with automatic annual key rotation enabled.
- The key policy allows account root IAM delegation and VPC Flow Logs delivery service (`delivery.logs.amazonaws.com`) to use the key.
- Additional IAM users or roles can be granted key administration through `kms_admin_principal_arns`.
- The KMS alias is `alias/{environment}-flow-logs-kms-key`.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_name` | `string` | — | VPC name used in KMS key tagging |
| `environment` | `string` | `dev` | Environment used in the KMS alias name |
| `kms_admin_principal_arns` | `list(string)` | `[]` | IAM user or role ARNs allowed to administer the KMS key |

## Outputs

| Name | Description |
|------|-------------|
| `logs_bucket_kms_key_arn` | ARN of the KMS key for encrypted log buckets |

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
| [aws_kms_alias.logs_bucket_kms_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.logs_bucket_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.logs_bucket_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for which the resources are being provisioned (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_kms_admin_principal_arns"></a> [kms\_admin\_principal\_arns](#input\_kms\_admin\_principal\_arns) | Existing IAM role/user ARNs allowed to administer the VPC Flow Logs bucket KMS key. | `list(string)` | `[]` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_logs_bucket_kms_key_arn"></a> [logs\_bucket\_kms\_key\_arn](#output\_logs\_bucket\_kms\_key\_arn) | The ARN of the KMS key used for encrypting VPC Flow Logs in the S3 bucket |
<!-- END_TF_DOCS -->
