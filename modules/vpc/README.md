# VPC Module

Creates the AWS network foundation for the Redemption platform: VPC, public/private/isolated/intra subnets, internet gateway, optional single NAT gateway, route tables, and VPC Flow Logs.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "redemption-prod-vpc"
  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidr   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidr  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  isolated_subnet_cidr = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  intra_subnet_cidr    = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
  azs                  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

  environment  = "prod"
  cluster_name = "redemption"

  vpc_flow_log_iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  aws_cloudwatch_vpc_flow_log_group_arn = aws_cloudwatch_log_group.vpc_flow_logs.arn
}
```

## Notes

- `create_nat = true` creates one NAT gateway in the first public subnet.
- `enable_eks_tags = true` adds subnet tags for AWS load balancers and Karpenter discovery.
- VPC Flow Logs are always declared, so provide the IAM role ARN and CloudWatch log group ARN.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
