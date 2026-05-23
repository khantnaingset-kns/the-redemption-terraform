locals {
  cluster_name = "${var.environment}-${var.cluster_name}"
  tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.20.0"

  name               = local.cluster_name
  kubernetes_version = "1.35"

  # Gives Terraform identity admin access to cluster which will allow deploying helm resources into the cluster
  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  control_plane_scaling_config = {
    tier = var.control_plane_scaling_config.tier
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets
  enable_irsa              = true

  node_security_group_additional_rules = {
    ingress_alb_controller_https = {
      description              = "Allow ALB Controller to communicate with nodes over HTTP"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = var.alb_sg_id
    },
    ingress_cilium_health = {
      description = "Cilium health checks between nodes"
      protocol    = "tcp"
      from_port   = 4240
      to_port     = 4240
      type        = "ingress"
      self        = true # node to node
    }
  }


  addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "fargate"
        resources = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
      preserve      = true
      most_recent   = false
      addon_version = "v1.12.4-eksbuild.1"

      timeouts = {
        create = "25m"
        delete = "10m"
      }
      wait_for_rollout = false
    }

    vpc-cni = {
      preserve      = true
      most_recent   = false
      addon_version = "v1.20.4-eksbuild.1"
    }

    kube-proxy = {
      preserve      = true
      most_recent   = false
      addon_version = "v1.33.5-eksbuild.2"
    }

    metrics-server = {
      preserve         = true
      most_recent      = false
      addon_version    = "v0.7.2-eksbuild.3"
      wait_for_rollout = false
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  encryption_config = {
    resources = ["secrets"]
  }



  fargate_profiles = {
    kube_system = {
      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "eks.amazonaws.com/compute-type" = "fargate"
      }
      taints = [
        {
          key    = "eks.amazonaws.com/compute-type"
          value  = "fargate"
          effect = "NO_SCHEDULE"
        }
      ]
      name = "kube_system"
      selectors = [
        {
          namespace = "kube-system"
          labels    = { "app.kubernetes.io/name" = "karpenter" }
        }
      ]
      iam_role_additional_policies = {
        cloudwatch_logs = var.fargate_cloudwatch_logs_policy_arn
      }
    }
  }

}


module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.20.0"

  cluster_name = module.eks.cluster_name

  // Pod Identity
  create_pod_identity_association = false


  // IRSA Configuration
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${local.cluster_name}-karpenter-node-role"
  iam_policy_description        = "Additional policies for EKS nodes managed by Karpenter in the ${local.cluster_name} cluster"


  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  }

  iam_role_source_assume_policy_documents = [
    data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json,
  ]

}

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = var.karpenter_chart_version
  wait                = true
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  values = [
    yamlencode({
      serviceAccount = {
        name = module.karpenter.service_account
        annotations = {
          "eks.amazonaws.com/role-arn" = module.karpenter.iam_role_arn
        }
      }

      dnsPolicy = "Default"

      settings = {
        clusterName       = module.eks.cluster_name
        clusterEndpoint   = module.eks.cluster_endpoint
        interruptionQueue = module.karpenter.queue_name
      }

      controller = {
        resources = {
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      tolerations = [
        {
          key      = "eks.amazonaws.com/compute-type"
          operator = "Equal"
          value    = "fargate"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}

module "ebs_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  depends_on = [module.eks]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.42.0-eksbuild.1"
  service_account_role_arn = module.ebs_csi_driver_irsa.arn
  configuration_values = jsonencode({
    node = {
      tolerateAllTaints = true
    },
    sidecars : {
      snapshotter : {
        forceEnable : false
      }
    },
  })


  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    module.eks,
    module.ebs_csi_driver_irsa
  ]
}

module "argocd_eks_capability" {
  source       = "terraform-aws-modules/eks/aws//modules/capability"
  version      = "21.20.0"
  type         = "ARGOCD"
  cluster_name = module.eks.cluster_name

  configuration = {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = one(data.aws_ssoadmin_instances.this.arns)
      }
      namespace = "argocd"
      rbac_role_mapping = [{
        role = "ADMIN"
        identity = [{
          id   = data.aws_identitystore_group.aws_administrator.group_id
          type = "SSO_GROUP"
        }]
      }]
    }
  }

  # IAM Role/Policy
  iam_policy_statements = {
    ECRRead = {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
      ]
      resources = ["*"]
    }
  }

  tags = local.tags
}
