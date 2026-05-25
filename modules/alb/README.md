# ALB Module

Creates a public, HTTP-only Application Load Balancer in public subnets. Domain, Route53, HTTPS, and ACM certificate resources are intentionally excluded for this assessment setup.

## Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  alb_name                = "prod-redemption-alb"
  vpc_id                  = module.vpc.vpc
  public_subnet_ids       = module.vpc.public_subnet_ids
  access_logs_bucket_name = module.buckets.alb_logs_bucket_name
  access_logs_prefix      = "alb"

  tags = {
    Environment = "prod"
  }
}
```

## Notes

- The ALB is internet-facing and must be placed in public subnets.
- The HTTP listener on port 80 forwards directly to the target group.
- ALB access log bucket creation and policy ownership live in `modules/buckets`.
- No domain, DNS, ACM certificate, HTTPS listener, or host-header rule is managed here.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `alb_name` | `string` | — | ALB name, limited to 29 chars to keep target group names valid |
| `vpc_id` | `string` | — | VPC ID for the ALB security group and target group |
| `public_subnet_ids` | `list(string)` | — | Public subnet IDs for the internet-facing ALB |
| `access_logs_bucket_name` | `string` | — | S3 bucket name for ALB access logs |
| `access_logs_prefix` | `string` | `alb` | S3 object prefix for ALB access logs |
| `allowed_ingress_cidr_blocks` | `list(string)` | `["0.0.0.0/0"]` | CIDR blocks allowed to access HTTP |
| `target_port` | `number` | `80` | Target group backend port |
| `health_check_path` | `string` | `/healthz` | Target group health check path |
| `enable_deletion_protection` | `bool` | `false` | Whether ALB deletion protection is enabled |
| `tags` | `map(string)` | `{}` | Tags applied to ALB resources |

## Outputs

| Name | Description |
|------|-------------|
| `arn` | ALB ARN |
| `dns_name` | ALB DNS name |
| `zone_id` | ALB hosted zone ID |
| `security_group_id` | ALB security group ID |
| `target_group_arn` | ALB target group ARN |

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
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket_name"></a> [access\_logs\_bucket\_name](#input\_access\_logs\_bucket\_name) | S3 bucket name for ALB access logs | `string` | n/a | yes |
| <a name="input_access_logs_prefix"></a> [access\_logs\_prefix](#input\_access\_logs\_prefix) | S3 prefix for ALB access logs | `string` | `"alb"` | no |
| <a name="input_alb_name"></a> [alb\_name](#input\_alb\_name) | Name of the Application Load Balancer | `string` | n/a | yes |
| <a name="input_allowed_ingress_cidr_blocks"></a> [allowed\_ingress\_cidr\_blocks](#input\_allowed\_ingress\_cidr\_blocks) | CIDR blocks allowed to access the ALB over HTTP | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Whether deletion protection is enabled on the ALB | `bool` | `false` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | HTTP path used for target group health checks | `string` | `"/healthz"` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs where the internet-facing ALB is deployed | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to ALB resources | `map(string)` | `{}` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Port used by the ALB target group | `number` | `80` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the ALB and target group are created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ALB ARN |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | ALB DNS name |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ALB security group ID |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ALB target group ARN |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ALB hosted zone ID |
<!-- END_TF_DOCS -->
