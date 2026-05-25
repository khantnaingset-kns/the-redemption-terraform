# EKS Module

Creates the EKS control plane on Fargate, core add-ons, Karpenter bootstrap resources, EBS CSI driver integration, Loki IRSA role, and ArgoCD deployment.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  environment  = "prod"
  cluster_name = "redemption"

  vpc_id          = module.vpc.vpc
  private_subnets = module.vpc.private_subnet_ids
  intra_subnets   = module.vpc.intra_subnet_ids
  alb_sg_id       = module.alb.security_group_id

  control_plane_scaling_config = {
    tier = "standard"
  }

  fargate_cloudwatch_logs_policy_arn = module.iam.fargate_cloudwatch_logs_policy_arn
  logging_s3_access_policy_arn       = module.iam.logging_s3_access_policy_arn
  karpenter_chart_version            = "1.0.0"
  argocd_chart_version               = "7.8.10"
}
```

## Notes

- The EKS cluster name is composed as `${environment}-${cluster_name}`.
- Worker capacity uses Fargate profiles for `kube-system` and `argocd` namespaces. No managed node groups are created.
- Control plane ENIs use intra subnets; Fargate pods use private subnets.
- EKS add-ons: CoreDNS (v1.14.2, Fargate-optimized), VPC-CNI (v1.21.2), kube-proxy (v1.32.13).
- Karpenter is installed via the `terraform-aws-modules/eks//modules/karpenter` module and deployed as a Helm release with IRSA.
- The EBS CSI driver add-on uses a dedicated IRSA role created via `iam-role-for-service-accounts`.
- Loki IRSA role grants access to the EKS logs S3 bucket for the `o11y:loki-sa` service account.
- ArgoCD runs in the `argocd` namespace on Fargate with a ClusterIP service (ingress disabled pending domain/SSO provisioning).
- Node security group rules allow ALB ingress on port 80 and Cilium health checks on port 4240.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | `dev` | Environment name used in cluster naming and tags |
| `cluster_name` | `string` | — | Base EKS cluster name |
| `vpc_id` | `string` | — | VPC ID for the EKS cluster |
| `private_subnets` | `list(string)` | — | Private subnet IDs for Fargate pods |
| `intra_subnets` | `list(string)` | — | Intra subnet IDs for control plane ENIs |
| `alb_sg_id` | `string` | — | ALB security group ID allowed to reach pods on port 80 |
| `control_plane_scaling_config` | `object({ tier = string })` | — | EKS control plane scaling tier (`standard`, `tier-xl`, etc.) |
| `fargate_cloudwatch_logs_policy_arn` | `string` | — | IAM policy ARN for Fargate CloudWatch Logs |
| `logging_s3_access_policy_arn` | `string` | — | IAM policy ARN for Loki S3 access |
| `karpenter_chart_version` | `string` | — | Karpenter Helm chart version |
| `argocd_chart_version` | `string` | — | ArgoCD Helm chart version |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS cluster API endpoint |
| `cluster_certificate_authority_data` | Base64-encoded cluster CA certificate |
| `oidc_provider_arn` | EKS OIDC provider ARN for IRSA |

<!-- BEGIN_TF_DOCS -->
## Terraform Modules Docs

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_controller_irsa"></a> [alb\_controller\_irsa](#module\_alb\_controller\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts | 6.4.0 |
| <a name="module_ebs_csi_driver_irsa"></a> [ebs\_csi\_driver\_irsa](#module\_ebs\_csi\_driver\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 21.20.0 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | 21.20.0 |
| <a name="module_loki_s3_irsa"></a> [loki\_s3\_irsa](#module\_loki\_s3\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts | 6.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_addon.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_iam_policy_document.karpenter_controller_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_controller_policy_arn"></a> [alb\_controller\_policy\_arn](#input\_alb\_controller\_policy\_arn) | The ARN of the IAM policy for the AWS Load Balancer Controller | `string` | n/a | yes |
| <a name="input_alb_sg_id"></a> [alb\_sg\_id](#input\_alb\_sg\_id) | The ID of the security group to allow inbound access from ALB | `string` | n/a | yes |
| <a name="input_argocd_chart_version"></a> [argocd\_chart\_version](#input\_argocd\_chart\_version) | The version of the ArgoCD Helm chart to deploy | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster | `string` | n/a | yes |
| <a name="input_control_plane_scaling_config"></a> [control\_plane\_scaling\_config](#input\_control\_plane\_scaling\_config) | Configuration for control plane scaling | <pre>object({<br/>    tier = string<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment for which the resources are being provisioned (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_fargate_cloudwatch_logs_policy_arn"></a> [fargate\_cloudwatch\_logs\_policy\_arn](#input\_fargate\_cloudwatch\_logs\_policy\_arn) | The ARN of the IAM policy for Fargate CloudWatch Logs | `string` | n/a | yes |
| <a name="input_intra_subnets"></a> [intra\_subnets](#input\_intra\_subnets) | List of private subnet IDs to be used for the EKS cluster | `list(string)` | n/a | yes |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | The version of the Karpenter Helm chart to deploy | `string` | n/a | yes |
| <a name="input_logging_s3_access_policy_arn"></a> [logging\_s3\_access\_policy\_arn](#input\_logging\_s3\_access\_policy\_arn) | The ARN of the IAM policy for S3 access for logging | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnet IDs to be used for the EKS cluster | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC where the EKS cluster will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_controller_irsa_role_arn"></a> [alb\_controller\_irsa\_role\_arn](#output\_alb\_controller\_irsa\_role\_arn) | ARN of the IAM role for the AWS Load Balancer Controller (IRSA) |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded EKS cluster certificate authority data |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | EKS cluster API endpoint |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS cluster name |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | EKS OIDC provider ARN |
<!-- END_TF_DOCS -->
