# Database Module

Provisions an RDS PostgreSQL instance with multi-AZ, encryption, Performance Insights, and a configurable security group placed in isolated subnets.

## Usage

```hcl
module "database" {
  source = "../../modules/database"

  vpc_id           = module.vpc.vpc
  sg_name          = "prod-redemption-db-sg"
  db_subnet_ids    = module.vpc.isolated_subnet_ids
  db_instance_name = "prod-redemption-db"

  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.medium"
  db_name        = "theredemption"
  db_username    = "dbadmin"

  allocated_storage                     = 20
  max_allocated_storage                 = 100
  performance_insights_retention_period = 7

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/16"
      description = "PostgreSQL from VPC"
    }
  ]
}
```

## Notes

- The RDS instance is multi-AZ and uses gp3 storage with autoscaling.
- `manage_master_user_password = true` — master credentials are stored in AWS Secrets Manager.
- The parameter group enforces `rds.force_ssl` and `scram-sha-256` password encryption.
- Deletion protection is enabled (`prevent_destroy` lifecycle rule). A final snapshot is created on destroy.
- Performance Insights is enabled with configurable retention (7–731 days).
- The DB subnet group places the instance in isolated subnets (no internet route).

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_id` | `string` | — | VPC ID for the security group and subnet group |
| `sg_name` | `string` | — | Name for the RDS security group |
| `ingress_rules` | `list(object({...}))` | `[]` | Ingress rules for the RDS security group |
| `egress_rules` | `list(object({...}))` | `[]` | Egress rules for the RDS security group |
| `db_subnet_ids` | `list(string)` | — | Subnet IDs for the DB subnet group (typically isolated) |
| `db_instance_name` | `string` | — | RDS instance identifier |
| `engine` | `string` | `postgres` | Database engine |
| `engine_version` | `string` | `17` | Database engine version |
| `instance_class` | `string` | `db.t4g.micro` | RDS instance class |
| `db_name` | `string` | — | Name of the database to create |
| `db_username` | `string` | — | Master username |
| `allocated_storage` | `number` | `20` | Allocated storage in GB |
| `max_allocated_storage` | `number` | `100` | Max storage in GB for autoscaling |
| `performance_insights_retention_period` | `number` | `7` | PI retention in days (7, 31, 62, 93, 186, 372, or 731) |

## Outputs

| Name | Description |
|------|-------------|
| `secrets_manager_secret_arn` | ARN of the Secrets Manager secret storing RDS master credentials |
| `db_endpoint` | RDS instance endpoint |
| `db_port` | RDS instance port |
| `db_instance_arn` | ARN of the RDS instance |
| `db_instance_id` | ID of the RDS instance |
| `security_group_id` | ID of the RDS security group |
| `db_subnet_group_name` | Name of the DB subnet group |
| `parameter_group_name` | Name of the DB parameter group |

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
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.pg_parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.db_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Allocated storage in GB | `number` | `20` | no |
| <a name="input_db_instance_name"></a> [db\_instance\_name](#input\_db\_instance\_name) | Identifier for the RDS instance | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the database to create | `string` | n/a | yes |
| <a name="input_db_subnet_ids"></a> [db\_subnet\_ids](#input\_db\_subnet\_ids) | Subnet IDs for the RDS subnet group (typically isolated subnets) | `list(string)` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master username for the database | `string` | n/a | yes |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Egress rules for the RDS security group | <pre>list(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine | `string` | `"postgres"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Database engine version | `string` | `"17"` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Ingress rules for the RDS security group | <pre>list(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | RDS instance class | `string` | `"db.t4g.micro"` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Maximum allocated storage in GB for autoscaling | `number` | `100` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | Retention period for Performance Insights in days | `number` | `7` | no |
| <a name="input_sg_name"></a> [sg\_name](#input\_sg\_name) | Name for the RDS security group | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the RDS security group and subnet group will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_endpoint"></a> [db\_endpoint](#output\_db\_endpoint) | RDS instance endpoint |
| <a name="output_db_instance_arn"></a> [db\_instance\_arn](#output\_db\_instance\_arn) | ARN of the RDS instance |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | ID of the RDS instance |
| <a name="output_db_port"></a> [db\_port](#output\_db\_port) | RDS instance port |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the DB subnet group |
| <a name="output_parameter_group_name"></a> [parameter\_group\_name](#output\_parameter\_group\_name) | Name of the DB parameter group |
| <a name="output_secrets_manager_secret_arn"></a> [secrets\_manager\_secret\_arn](#output\_secrets\_manager\_secret\_arn) | ARN of the Secrets Manager secret storing the RDS master credentials |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the RDS security group |
<!-- END_TF_DOCS -->
