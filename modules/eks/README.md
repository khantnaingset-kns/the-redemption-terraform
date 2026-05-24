# EKS Module

Creates the EKS control plane, core add-ons, Karpenter bootstrap resources, EBS CSI driver integration, and an optional ArgoCD EKS capability configuration.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  environment  = "prod"
  cluster_name = "redemption"

  vpc_id          = module.vpc.vpc
  private_subnets = module.vpc.private_subnet_ids
  intra_subnets   = module.vpc.intra_subnet_ids
  alb_sg_id       = aws_security_group.alb.id

  control_plane_scaling_config = {
    tier = "standard"
  }

  fargate_cloudwatch_logs_policy_arn = module.iam.fargate_cloudwatch_logs_policy_arn
  karpenter_chart_version            = "1.0.0"
  argocd_chart_version               = "9.5.15"
}
```

## Notes

- The EKS cluster name is composed as `${environment}-${cluster_name}`.
- Worker/node capacity uses private subnets; control plane ENIs use intra subnets.
- Karpenter is installed by Helm and configured for IRSA.
- ArgoCD runs in the `argocd` namespace with a dedicated Fargate profile and configurable Helm chart version.
- The EBS CSI add-on uses a dedicated IAM role for its controller service account.
- ArgoCD EKS capability integration requires AWS IAM Identity Center to be configured and the admin group display name to exist.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | `dev` | Environment name used in cluster naming and tags |
| `cluster_name` | `string` | n/a | Base EKS cluster name |
| `vpc_id` | `string` | n/a | VPC ID for the EKS cluster |
| `private_subnets` | `list(string)` | n/a | Private subnet IDs for nodes |
| `intra_subnets` | `list(string)` | n/a | Intra subnet IDs for control plane ENIs |
| `alb_sg_id` | `string` | n/a | ALB security group allowed to reach nodes |
| `control_plane_scaling_config` | `object({ tier = string })` | n/a | EKS control plane scaling tier |
| `fargate_cloudwatch_logs_policy_arn` | `string` | n/a | IAM policy ARN attached to the Fargate profile role |
| `logging_s3_access_policy_arn` | `string` | n/a | IAM policy ARN attached to the Loki S3 IRSA role |
| `karpenter_chart_version` | `string` | n/a | Karpenter Helm chart version |
| `argocd_chart_version` | `string` | n/a | ArgoCD Helm chart version |

## Outputs

This module currently does not expose outputs. Add explicit outputs if downstream modules need cluster endpoint, OIDC provider ARN, or Karpenter role details.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
