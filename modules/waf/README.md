# WAF Module

Provisions a regional WAF WebACL with AWS managed rule groups, trusted IP allow-list, notification endpoint blocking, and ALB association. WAF logging is delivered to CloudWatch Logs.

## Usage

```hcl
module "waf" {
  source = "../../modules/waf"

  environment = "prod"
  alb_arn     = module.alb.arn
  trusted_ips = ["203.0.113.0/32"]
}
```

## Notes

- The WebACL uses a default **allow** action. Managed rule groups are applied with `override_action { none {} }` (count-only in non-blocking mode).
- **Managed rule groups:**
  - `AWSManagedRulesKnownBadInputsRuleSet` (priority 0)
  - `AWSManagedRulesSQLiRuleSet` (priority 1)
  - `AWSManagedRulesLinuxRuleSet` (priority 2)
  - `AWSManagedRulesCommonRuleSet` (priority 4) — with `SizeRestrictions_BODY` overridden to allow
- **Trusted IPs** — an IP set is created only in `prod`. An allow rule (priority 3) references it when `trusted_ips` is non-empty.
- **Notification endpoint blocking** — a deny rule (priority 5) blocks requests to `/notification/api/v1/notifications/*-result-notification` paths. Active only in `prod`.
- WAF logs are sent to CloudWatch Logs with 14-day retention.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | — | Environment name used in resource naming |
| `alb_arn` | `string` | — | ARN of the ALB to associate the WebACL with |
| `trusted_ips` | `list(string)` | `[]` | IP addresses to allow (IP set created only in prod) |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_arn` | ARN of the WAFv2 Web ACL |
| `web_acl_name` | Name of the WAFv2 Web ACL |
| `web_acl_capacity` | Capacity units consumed by the Web ACL |

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
| [aws_cloudwatch_log_group.waf_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_wafv2_ip_set.trusted_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.alb_waf_associate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.waf_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_arn"></a> [alb\_arn](#input\_alb\_arn) | ARN of the ALB to associate the WAF Web ACL with | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment in which the resources are deployed | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used to prefix WAF resources | `string` | n/a | yes |
| <a name="input_trusted_ips"></a> [trusted\_ips](#input\_trusted\_ips) | A list of IP addresses to allow for a production environment | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the WAFv2 Web ACL |
| <a name="output_web_acl_capacity"></a> [web\_acl\_capacity](#output\_web\_acl\_capacity) | Capacity units consumed by the Web ACL |
| <a name="output_web_acl_name"></a> [web\_acl\_name](#output\_web\_acl\_name) | Name of the WAFv2 Web ACL |
<!-- END_TF_DOCS -->
