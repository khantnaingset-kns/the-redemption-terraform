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
| `alb_name` | `string` | n/a | ALB name, limited to 29 chars to keep target group names valid |
| `vpc_id` | `string` | n/a | VPC ID for the ALB security group and target group |
| `public_subnet_ids` | `list(string)` | n/a | Public subnet IDs for the internet-facing ALB |
| `access_logs_bucket_name` | `string` | n/a | S3 bucket name for ALB access logs |
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
<!-- END_TF_DOCS -->
