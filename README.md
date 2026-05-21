# The Redemption Terraform

Terraform infrastructure-as-code for **The Redemption** — a business-critical microservice handling global hotel point deductions, deployed on AWS EKS.

This repository owns all AWS-layer resources. Kubernetes workload configuration lives in [`redemption-helm`](https://github.com/your-org/redemption-helm). GitOps wiring lives in [`redemption-gitops`](https://github.com/your-org/redemption-gitops).

---

## Repository structure

```
redemption-terraform/
├── modules/
│   ├── alb/          # Application Load Balancer, listeners, target groups, ACM cert
│   ├── database/     # RDS cluster for application database workload.
│   ├── eks/          # EKS cluster + Karpenter bootstrap (third-party module)
│   ├── iam/          # IRSA roles, KMS key, node instance policies
│   ├── vpc/          # VPC, subnets (public / private / isolated), NAT, flow logs
│   └── waf/          # WebACL, managed rule groups, rate-limit rules, ALB association
└── environments/
    ├── prod/
    │   ├── backend.tf               # State backend configuration
    │   ├── data.tf                  # Data block
    │   ├── main.tf.                 # Modules composer
    │   └── providers.tf             # Providers configurations
    │   └── terraform.tf             # Terraform version and required providers config
    │   └── variables.tf             # Terraform variables
    │   └── terraform.example.tfvars # Example variables input
    ├── uat/
    ├── preprod/
    └── dev/
```

### Module dependency chain

```
iam → vpc → eks → database → alb → waf
```

Each module depends only on outputs from modules to its left. Apply in this order; destroy in reverse.

---

## Environment profiles

| Environment | NAT Gateway | AZs | Node type   | WAF     | Notes                              |
|-------------|-------------|-----|-------------|---------|-------------------------------------|
| `dev`       | Single      | 1   | t3.medium   | Disabled | Cost-optimised; single-AZ acceptable |
| `uat`       | Single      | 2   | t3.large    | Disabled | Functional parity, reduced HA        |
| `preprod`   | Single      | 3   | c6i.large   | Enabled  | Production-equivalent config         |
| `prod`      | Per-AZ      | 3   | c6i.xlarge  | Enabled  | Full HA; per-AZ NAT for AZ isolation |

> **`prod` note:** Per-AZ NAT gateways eliminate cross-AZ traffic during an AZ outage. `dev`/`uat` use a single NAT to minimise cost.

---

## Module overview

### `modules/vpc`

Provisions the network foundation consumed by all other modules.

Key resources:
- VPC with `enable_dns_hostnames` and `enable_dns_support` — required for EKS node registration
- **Three subnet tiers:**
  - `public` — ALB, NAT gateway egress
  - `private` — EKS managed node groups, Karpenter-provisioned nodes
  - `isolated` — RDS / ElastiCache; no route to NAT, no IGW
- NAT gateway(s) — single or per-AZ depending on environment profile
- VPC Flow Logs → CloudWatch Log Group (satisfies security requirement C)
- Explicit `map_public_ip_on_launch = false` on public subnets

### `modules/iam`

Provisions identity and encryption resources.

Key resources:
- **IRSA roles** for each workload that requires AWS API access (ESO, ALB controller, Karpenter controller)
- **KMS key** for EKS secrets envelope encryption and EBS volume encryption
- Node instance profile and policies for managed node groups

### `modules/eks`

Provisions the EKS cluster and bootstraps Karpenter.

Key resources:
- EKS cluster with managed node groups (core system workloads)
- Karpenter bootstrapped via [`terraform-aws-modules/eks`](https://github.com/terraform-aws-modules/terraform-aws-eks) — `NodePool` and `EC2NodeClass` are **not** managed here; they live in the Helm/GitOps layer
- OIDC provider for IRSA
- Envelope encryption enabled via KMS key from `iam` module
- Control plane logging to CloudWatch

### `modules/alb`

Provisions the Application Load Balancer and hands it to the ALB controller via `TargetGroupBinding`.

Key resources:
- ALB (internet-facing, multi-AZ)
- HTTPS listener (port 443) + HTTP → HTTPS redirect listener (port 80)
- Target group (IP mode, for pod-direct routing)
- ACM certificate (DNS validation)
- Security group — allows 443/80 inbound from WAF-associated IPs only

> **Design note (ADR-alb):** The ALB lifecycle is owned by Terraform, not by the ALB Ingress Controller. The controller manages only `TargetGroupBinding`, keeping WAF association clean and ALB deletion safe from accidental `kubectl delete ingress`.

### `modules/waf`

Provisions the WAF WebACL and associates it with the ALB.

Key resources:
- WebACL with AWS Managed Rule groups:
  - `AWSManagedRulesCommonRuleSet`
  - `AWSManagedRulesKnownBadInputsRuleSet`
- Custom rate-limit rule — 2 000 req / 5 min per IP (configurable per environment)
- WebACL association to ALB ARN

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

| Tool          | Version  | Purpose                              |
|---------------|----------|--------------------------------------|
| Terraform     | ≥ 1.7    | IaC runtime                          |
| AWS CLI       | ≥ 2.15   | Credential provider                  |

AWS credentials must have sufficient permissions to create IAM roles, VPC resources, EKS clusters, and WAF WebACLs. Use a role assumption pattern; avoid long-lived access keys.

---

## Usage

### 1. Configure remote state backend

Each environment has its own `backend.tf`. Update the S3 bucket and DynamoDB table names before first apply:

```hcl
# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "your-tfstate-bucket"
    key            = "redemption/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "your-tfstate-lock-table"
    encrypt        = true
  }
}
```

### 2. Review and set variable values

```bash
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
# Edit terraform.tfvars — at minimum set: aws_region, cluster_name, acm_certificate_arn
```

### 3. Apply in dependency order

```bash
# From the environment directory, e.g. prod
cd environments/prod

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Modules are called in dependency order within `main.tf`. No manual sequencing required.

### 4. Retrieve outputs for downstream repos

```bash
terraform output -json > /tmp/prod-outputs.json
```

Key outputs consumed by `redemption-helm` and `redemption-gitops`:

| Output key               | Consumed by        |
|--------------------------|--------------------|
| `cluster_name`           | ArgoCD Application |
| `cluster_endpoint`       | kubeconfig         |
| `alb_target_group_arn`   | Helm values        |
| `oidc_provider_arn`      | IRSA annotations   |
| `kms_key_arn`            | ESO SecretStore    |

---

## Input variables

| Variable                 | Type     | Default        | Description                                          |
|--------------------------|----------|----------------|------------------------------------------------------|
| `aws_region`             | `string` | `ap-southeast-1` | AWS region for all resources                        |
| `cluster_name`           | `string` | —              | EKS cluster name; used as prefix for all resources   |
| `environment`            | `string` | —              | `dev` / `uat` / `preprod` / `prod`                   |
| `vpc_cidr`               | `string` | `10.0.0.0/16`  | VPC CIDR block                                       |
| `nat_gateway_per_az`     | `bool`   | `false`        | Set `true` for prod to enable per-AZ NAT             |
| `node_instance_type`     | `string` | `t3.medium`    | Managed node group instance type                     |
| `enable_waf`             | `bool`   | `false`        | Attach WAF WebACL to ALB                             |
| `waf_rate_limit`         | `number` | `2000`         | Max requests per IP per 5-minute window              |
| `acm_certificate_arn`    | `string` | —              | ARN of the ACM certificate for the HTTPS listener    |

---

## Outputs

| Output key               | Description                                       |
|--------------------------|---------------------------------------------------|
| `vpc_id`                 | VPC ID                                            |
| `private_subnet_ids`     | List of private subnet IDs (EKS nodes)            |
| `isolated_subnet_ids`    | List of isolated subnet IDs (data layer)          |
| `cluster_name`           | EKS cluster name                                  |
| `cluster_endpoint`       | EKS API server endpoint                           |
| `cluster_ca_certificate` | Base64-encoded cluster CA certificate             |
| `oidc_provider_arn`      | OIDC provider ARN for IRSA role bindings          |
| `alb_dns_name`           | ALB DNS name (for CNAME record)                   |
| `alb_target_group_arn`   | Target group ARN for `TargetGroupBinding`         |
| `kms_key_arn`            | KMS key ARN for ESO SecretStore and EBS volumes   |
| `karpenter_node_role_arn`| IAM role ARN for Karpenter-provisioned nodes      |

---

## Security notes

- **No static credentials** — all pod-level AWS access uses IRSA. Managed node instance profiles carry only the minimum permissions required by the kubelet.
- **Secrets at rest** — EKS etcd secrets are envelope-encrypted with the KMS key provisioned by the `iam` module.
- **Network isolation** — the `isolated` subnet tier has no route to the NAT gateway or internet gateway, providing a hard network boundary for the data layer.
- **VPC Flow Logs** — enabled on the VPC and delivered to CloudWatch for audit and incident investigation.
- **WAF** — enabled for `preprod` and `prod`. Rate-limit threshold is configurable; default 2 000 req / 5 min per IP.
- **Public subnets** — `map_public_ip_on_launch = false` is explicitly set; no resources other than the ALB and NAT gateways are placed in public subnets.

---

## Related repositories

| Repository              | Contents                                         |
|-------------------------|--------------------------------------------------|
| [`redemption-assessment`](https://github.com/your-org/redemption-assessment) | Reviewer guide, ADRs, architecture diagram, design document |
| [`redemption-helm`](https://github.com/your-org/redemption-helm)             | Application Helm chart (Deployment, HPA, PDB, NetworkPolicy) |
| [`redemption-gitops`](https://github.com/your-org/redemption-gitops)         | ArgoCD Application manifests, cluster bootstrap |

---

## Deployment order (full stack)

```
1. redemption-terraform   ← this repo; provision AWS layer
2. redemption-helm        ← package application chart
3. redemption-gitops      ← ArgoCD syncs chart into cluster
```

See [`redemption-assessment`](https://github.com/your-org/redemption-assessment) for the full step-by-step reviewer walkthrough.