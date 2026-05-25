# VPC Module

Creates the AWS network foundation for the Redemption platform: VPC, public/private/isolated/intra subnets, internet gateway, optional NAT gateway, route tables, and VPC Flow Logs delivered to S3.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "prod-redemption-vpc"
  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidr   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidr  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  isolated_subnet_cidr = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  intra_subnet_cidr    = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  azs                  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

  create_nat = true

  environment     = "prod"
  cluster_name    = "redemption"
  enable_eks_tags = true

  vpc_flow_logs_bucket_arn = module.buckets.vpc_flow_logs_bucket_arn
}
```

## Notes

- `create_nat = true` creates one NAT gateway with an Elastic IP in the first public subnet.
- `enable_eks_tags = true` adds `kubernetes.io/role/elb` to public subnets and `kubernetes.io/role/internal-elb` + `karpenter.sh/discovery` to private subnets.
- VPC Flow Logs are delivered to an S3 bucket in Parquet format with per-hour partitioning.
- Subnet CIDR blocks are computed from `vpc_cidr` in the environment root — see `environments/prod/main.tf` locals.
- AZ assignment falls back to `data.aws_availability_zones` if `azs` is not provided.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_name` | `string` | — | VPC name used in Name tags |
| `vpc_cidr` | `string` | — | CIDR block for the VPC |
| `public_subnet_cidr` | `list(string)` | — | CIDR blocks for public subnets |
| `private_subnet_cidr` | `list(string)` | — | CIDR blocks for private subnets |
| `isolated_subnet_cidr` | `list(string)` | — | CIDR blocks for isolated subnets |
| `intra_subnet_cidr` | `list(string)` | — | CIDR blocks for intra subnets |
| `azs` | `list(string)` | — | Availability zones for subnet placement |
| `create_nat` | `bool` | `true` | Whether to create a NAT gateway and private route table |
| `environment` | `string` | — | Environment name used for subnet tagging |
| `enable_eks_tags` | `bool` | `true` | Add EKS/Karpenter discovery tags to subnets |
| `cluster_name` | `string` | `null` | EKS cluster name (required when `enable_eks_tags` is true) |
| `vpc_flow_logs_bucket_arn` | `string` | `null` | S3 bucket ARN for VPC Flow Logs delivery |
| `vpc_flow_log_iam_role_arn` | `string` | `null` | IAM role ARN for VPC Flow Logs (optional for S3 delivery) |
| `aws_cloudwatch_vpc_flow_log_group_arn` | `string` | `null` | CloudWatch log group ARN (not used when delivering to S3) |

## Outputs

| Name | Description |
|------|-------------|
| `vpc` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `isolated_subnet_ids` | List of isolated subnet IDs |
| `intra_subnet_ids` | List of intra subnet IDs |

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
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_rt_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.intra_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.isolated_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_cloudwatch_vpc_flow_log_group_arn"></a> [aws\_cloudwatch\_vpc\_flow\_log\_group\_arn](#input\_aws\_cloudwatch\_vpc\_flow\_log\_group\_arn) | ARN of the CloudWatch log group to use for VPC Flow Logs (optional) | `string` | `null` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | List of availability zones for the subnets | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster (required when enable\_eks\_tags is true) | `string` | `null` | no |
| <a name="input_create_nat"></a> [create\_nat](#input\_create\_nat) | Boolean flag to specify if a NAT gateway should be created | `bool` | `true` | no |
| <a name="input_enable_eks_tags"></a> [enable\_eks\_tags](#input\_enable\_eks\_tags) | Whether to add EKS-specific tags (kubernetes.io/role/elb, karpenter.sh/discovery) to subnets | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_intra_subnet_cidr"></a> [intra\_subnet\_cidr](#input\_intra\_subnet\_cidr) | List of CIDR blocks for the intra subnets | `list(string)` | n/a | yes |
| <a name="input_isolated_subnet_cidr"></a> [isolated\_subnet\_cidr](#input\_isolated\_subnet\_cidr) | List of CIDR blocks for the isolated subnets | `list(string)` | n/a | yes |
| <a name="input_private_subnet_cidr"></a> [private\_subnet\_cidr](#input\_private\_subnet\_cidr) | List of CIDR blocks for the private subnets | `list(string)` | n/a | yes |
| <a name="input_public_subnet_cidr"></a> [public\_subnet\_cidr](#input\_public\_subnet\_cidr) | List of CIDR blocks for the public subnets | `list(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_flow_log_iam_role_arn"></a> [vpc\_flow\_log\_iam\_role\_arn](#input\_vpc\_flow\_log\_iam\_role\_arn) | ARN of the IAM role to use for VPC Flow Logs (optional) | `string` | `null` | no |
| <a name="input_vpc_flow_logs_bucket_arn"></a> [vpc\_flow\_logs\_bucket\_arn](#input\_vpc\_flow\_logs\_bucket\_arn) | ARN of the S3 bucket to use for VPC Flow Logs (optional) | `string` | `null` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_intra_subnet_ids"></a> [intra\_subnet\_ids](#output\_intra\_subnet\_ids) | The names of the intra subnets |
| <a name="output_isolated_subnet_ids"></a> [isolated\_subnet\_ids](#output\_isolated\_subnet\_ids) | The names of the isolated subnets |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The names of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The names of the public subnets |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | The name of the VPC |
<!-- END_TF_DOCS -->
