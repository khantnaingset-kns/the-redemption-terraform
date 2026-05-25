# The Redemption Terraform

Terraform infrastructure-as-code for **The Redemption** — a business-critical microservice handling global hotel point deductions, deployed on AWS EKS.

This repository owns all AWS-layer resources. Kubernetes workload configuration lives in [`redemption-helm`](https://github.com/your-org/redemption-helm). GitOps wiring lives in [`redemption-gitops`](https://github.com/your-org/redemption-gitops).

---

## Repository structure

```
redemption-terraform/
├── modules/
│   ├── alb/          # Application Load Balancer, HTTP listener, target group
│   ├── buckets/      # S3 buckets for VPC Flow Logs, EKS logs, ALB access logs
│   ├── database/     # RDS PostgreSQL instance, security group, parameter group
│   ├── eks/          # EKS cluster (Fargate), Karpenter, ArgoCD, EBS CSI driver
│   ├── iam/          # IAM policies for Fargate CloudWatch, S3 logging, ALB controller
│   ├── secrets/      # KMS key for S3 log bucket encryption
│   ├── vpc/          # VPC, subnets (public / private / isolated / intra), NAT, flow logs
│   └── waf/          # WAF WebACL, managed rule groups, trusted IPs, ALB association
└── environments/
    └── prod/
        ├── backend.tf       # State backend configuration
        ├── main.tf          # Module composition and local values
        ├── outputs.tf       # Environment outputs
        ├── providers.tf     # AWS provider configuration
        ├── terraform.tf     # Terraform version and required providers
        └── variables.tf     # Environment input variables
```

### Module dependency chain

```
secrets → buckets → vpc → iam → alb → eks → database → waf
```

Each module depends only on outputs from modules to its left. Apply in this order; destroy in reverse.

---

## Environment

Only the `prod` environment is currently defined. It provisions a full multi-AZ deployment with NAT gateway, 3 AZs, and WAF enabled.

---

## Module overview

### `modules/secrets`

Provisions encryption resources for log storage.

Key resources:
- KMS key with auto-rotation for S3 log bucket encryption
- KMS alias (`{environment}-flow-logs-kms-key`)
- Key policy allowing root IAM delegation, VPC Flow Logs delivery service, and optional key administrators

### `modules/buckets`

Creates S3 buckets for infrastructure log storage with lifecycle retention and encryption.

Key resources:
- VPC Flow Logs bucket — SSE-KMS encrypted, 30→90-day transition to STANDARD_IA→GLACIER_IR, lifecycle expiration
- EKS logs bucket — SSE-KMS encrypted, same lifecycle rules
- ALB access logs bucket — SSE-S3 (AES256) encrypted (ALB access logging does not support SSE-KMS)
- Public access blocked on all buckets
- Bucket policies for VPC Flow Logs delivery service and ELB log delivery

### `modules/vpc`

Provisions the network foundation.

Key resources:
- VPC with `enable_dns_hostnames` and `enable_dns_support`
- **Four subnet tiers:**
  - `public` — ALB, NAT gateway egress
  - `private` — EKS Fargate profiles, Karpenter-provisioned nodes
  - `isolated` — RDS; no route to NAT, no IGW
  - `intra` — EKS control plane ENIs; no route to NAT, no IGW
- Internet gateway for public subnets
- Optional NAT gateway (single) with Elastic IP for private subnet egress
- VPC Flow Logs → S3 bucket (Parquet format, per-hour partition)
- EKS and Karpenter subnet discovery tags

### `modules/iam`

Provisions IAM policies consumed by the EKS module.

Key resources:
- **Fargate CloudWatch Logs policy** — allows Fargate pods to write to CloudWatch Logs
- **Logging S3 access policy** — grants S3 access to the EKS logs bucket (used by Loki)
- **ALB Controller policy** — full AWS Load Balancer Controller permissions (IRSA-ready)

### `modules/eks`

Provisions the EKS cluster, core add-ons, Karpenter, ArgoCD, and EBS CSI driver.

Key resources:
- EKS cluster (Kubernetes 1.35) via `terraform-aws-modules/eks` with Fargate profiles for `kube-system` and `argocd`
- Control plane in intra subnets, worker capacity in private subnets
- EKS add-ons: CoreDNS (Fargate-optimized), VPC-CNI, kube-proxy
- Karpenter bootstrapped via module + Helm release (IRSA-based)
- EBS CSI driver with dedicated IRSA role
- Loki IRSA role for S3 log bucket access
- ArgoCD deployed via Helm in `argocd` namespace on Fargate
- Cluster creator admin permissions enabled
- OIDC provider for IRSA

### `modules/alb`

Provisions a public, HTTP-only Application Load Balancer.

Key resources:
- Internet-facing ALB in public subnets
- HTTP listener (port 80) forwarding to IP-mode target group
- Security group with configurable ingress CIDR blocks
- ALB access logging to S3
- Health check on `/healthz` with 200-399 matcher

### `modules/database`

Provisions the RDS PostgreSQL database.

Key resources:
- RDS PostgreSQL instance (multi-AZ, gp3 storage with autoscaling)
- DB parameter group enforcing `rds.force_ssl` and `scram-sha-256` password encryption
- DB subnet group in isolated subnets
- Security group with configurable ingress/egress rules
- Performance Insights enabled
- Master password managed via AWS Secrets Manager
- Deletion protection enabled with final snapshot

### `modules/waf`

Provisions the WAF WebACL and associates it with the ALB.

Key resources:
- Regional WebACL with AWS managed rule groups:
  - `AWSManagedRulesKnownBadInputsRuleSet`
  - `AWSManagedRulesSQLiRuleSet`
  - `AWSManagedRulesLinuxRuleSet`
  - `AWSManagedRulesCommonRuleSet` (with `SizeRestrictions_BODY` override to allow)
- Trusted IPs allow-list (prod only)
- Notification endpoint blocking rule (prod only)
- WebACL association to ALB ARN
- WAF logging to CloudWatch Logs (14-day retention)

---

## Architectural decision records

| ADR     | Decision                                                                 |
|---------|--------------------------------------------------------------------------|
| ADR-001 | Multi-AZ EKS with managed node groups over self-managed                  |
| ADR-002 | Karpenter over Cluster Autoscaler for burst node provisioning             |
| ADR-003 | IRSA over static IAM credentials for pod identity                        |
| ADR-004 | External Secrets Operator + Secrets Manager over native Kubernetes secrets |
| ADR-005 | HPA (CPU + custom RPS metrics) over KEDA for HTTP-only traffic scaling    |

Full ADR documents are in [`redemption-assessment/adrs/`](https://github.com/your-org/redemption-assessment/tree/main/adrs).

---

## Prerequisites

| Tool      | Version | Purpose              |
|-----------|---------|----------------------|
| Terraform | ≥ 1.7   | IaC runtime          |
| AWS CLI   | ≥ 2.15  | Credential provider  |
| Helm      | ≥ 3.0   | Chart deployments    |

AWS credentials must have sufficient permissions to create IAM roles, VPC resources, EKS clusters, RDS instances, and WAF WebACLs.

---

## Usage

### 1. Configure remote state backend

Update the S3 bucket name in `environments/prod/backend.tf` before first apply:

```hcl
# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket       = "your-tfstate-bucket"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### 2. Set variable values

```bash
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
# Edit terraform.tfvars — at minimum set: aws_region, cluster_name, vpc_cidr, azs
```

### 3. Apply

```bash
cd environments/prod

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Modules are called in dependency order within `main.tf`. No manual sequencing required.

### 4. Retrieve outputs

```bash
terraform output -json > /tmp/prod-outputs.json
```

---

## Input variables

Key variables defined in `environments/prod/variables.tf`:

| Variable                                | Type           | Default             | Description                                        |
|-----------------------------------------|----------------|---------------------|----------------------------------------------------|
| `aws_region`                            | `string`       | —                   | AWS region for all resources                       |
| `environment`                           | `string`       | `prod`              | Environment name                                   |
| `cluster_name`                          | `string`       | —                   | Base EKS cluster name                              |
| `vpc_cidr`                              | `string`       | —                   | VPC CIDR block                                     |
| `azs`                                   | `list(string)` | —                   | Availability zones for subnet placement            |
| `create_nat`                            | `bool`         | `true`              | Whether to create a NAT gateway                    |
| `enable_eks_tags`                       | `bool`         | `true`              | Add EKS/Karpenter tags to VPC subnets              |
| `karpenter_chart_version`               | `string`       | —                   | Karpenter Helm chart version                       |
| `argocd_chart_version`                  | `string`       | —                   | ArgoCD Helm chart version                          |
| `control_plane_scaling_tier`            | `string`       | `standard`          | EKS control plane scaling tier                     |
| `db_engine`                             | `string`       | `postgres`          | RDS database engine                                |
| `db_engine_version`                     | `string`       | `17`                | RDS engine version                                 |
| `db_instance_class`                     | `string`       | `db.t4g.medium`     | RDS instance class                                 |
| `db_name`                               | `string`       | `theredemption`     | Database name                                      |
| `db_username`                           | `string`       | `dbadmin`           | Master username                                    |
| `db_allocated_storage`                  | `number`       | `20`                | Allocated storage in GB                            |
| `waf_trusted_ips`                       | `list(string)` | `[]`                | Trusted IPs for WAF allow-list (prod)              |

See `environments/prod/variables.tf` for the complete list with defaults and descriptions.

---

## Outputs

| Output key                          | Description                                  |
|-------------------------------------|----------------------------------------------|
| `vpc_id`                            | VPC ID                                       |
| `public_subnet_ids`                 | Public subnet IDs                            |
| `private_subnet_ids`                | Private subnet IDs                           |
| `isolated_subnet_ids`               | Isolated subnet IDs (data layer)             |
| `intra_subnet_ids`                  | Intra subnet IDs                             |
| `cluster_name`                      | EKS cluster name                             |
| `cluster_endpoint`                  | EKS API server endpoint                      |
| `oidc_provider_arn`                 | OIDC provider ARN for IRSA                   |
| `alb_dns_name`                      | ALB DNS name                                 |
| `alb_target_group_arn`              | Target group ARN for TargetGroupBinding      |
| `logs_bucket_kms_key_arn`           | KMS key ARN for log bucket encryption        |
| `fargate_cloudwatch_logs_policy_arn`| Fargate CloudWatch Logs policy ARN           |
| `alb_controller_policy_arn`         | ALB Controller IAM policy ARN                |
| `db_endpoint`                       | RDS endpoint                                 |
| `db_port`                           | RDS port                                     |
| `db_secrets_manager_secret_arn`     | Secrets Manager secret ARN for RDS creds     |
| `waf_web_acl_arn`                   | WAF Web ACL ARN                              |

---

## Security notes

- **IRSA** — all pod-level AWS access uses IAM Roles for Service Accounts. IAM policies (Fargate CloudWatch, S3 logging, ALB controller) are provisioned by the `iam` module and consumed by the `eks` module.
- **Secrets at rest** — RDS master password is managed by AWS Secrets Manager via `manage_master_user_password = true`.
- **Network isolation** — the `isolated` subnet tier hosting RDS has no route to the NAT gateway or internet gateway. The `intra` subnet tier for EKS control plane ENIs is similarly isolated.
- **VPC Flow Logs** — delivered to an SSE-KMS encrypted S3 bucket in Parquet format with per-hour partitioning.
- **WAF** — protects the ALB with AWS managed rule groups (KnownBadInputs, SQLi, Linux, CommonRuleSet). Production additionally blocks notification endpoints and allows a configurable trusted IP set.
- **RDS** — `rds.force_ssl` and `scram-sha-256` password encryption enforced via parameter group. Multi-AZ enabled. Deletion protection active with final snapshot.
- **Buckets** — public access fully blocked. Encryption required. Lifecycle rules transition aged objects through storage tiers.

---

## Related repositories

| Repository              | Contents                                                 |
|-------------------------|----------------------------------------------------------|
| [`redemption-assessment`](https://github.com/your-org/redemption-assessment) | Reviewer guide, ADRs, architecture diagram, design document |
| [`redemption-helm`](https://github.com/your-org/redemption-helm)             | Application Helm chart (Deployment, HPA, PDB, NetworkPolicy) |
| [`redemption-gitops`](https://github.com/your-org/redemption-gitops)         | ArgoCD Application manifests, cluster bootstrap              |

---

## Deployment order (full stack)

```
1. redemption-terraform   ← this repo; provision AWS layer
2. redemption-helm        ← package application chart
3. redemption-gitops      ← ArgoCD syncs chart into cluster
```

See [`redemption-assessment`](https://github.com/your-org/redemption-assessment) for the full step-by-step reviewer walkthrough.
