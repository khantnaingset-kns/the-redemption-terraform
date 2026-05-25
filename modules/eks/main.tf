locals {
  cluster_name = "${var.environment}-${var.cluster_name}"
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
      addon_version = "v1.14.2-eksbuild.4"

      timeouts = {
        create = "25m"
        delete = "10m"
      }
      wait_for_rollout = false
    }

    vpc-cni = {
      preserve      = true
      most_recent   = false
      addon_version = "v1.21.2-eksbuild.2"
    }

    kube-proxy = {
      preserve      = true
      most_recent   = false
      addon_version = "v1.32.13-eksbuild.11"
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
      name = "kube_system"
      # CoreDNS and metrics-server EKS add-ons run in kube-system. This selector
      # gives those pods Fargate capacity before the add-ons are created.
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
      iam_role_additional_policies = {
        cloudwatch_logs = var.fargate_cloudwatch_logs_policy_arn
      }
    }
    argocd = {
      name = "argocd"
      selectors = [
        {
          namespace = "argocd"
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

  cluster_name         = module.eks.cluster_name
  enable_inline_policy = true

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

  namespace = "kube-system"
  name      = "karpenter"

  repository          = "oci://public.ecr.aws/karpenter"
  chart               = "karpenter"
  version             = var.karpenter_chart_version
  wait                = true
  timeout             = 900
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

  create_policy = false
  policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

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

module "loki_s3_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"

  name          = "loki-s3-irsa"
  description   = "IAM Role for Loki to access S3 bucket and invoke Lambda via Function URL"
  create_policy = false
  policies = {
    LokiS3Access = var.logging_s3_access_policy_arn
    # LambdaInvoke = var.lambda_invoke_arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["o11y:loki-sa"]
    }
  }


  depends_on = [module.eks]
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"

  name          = "alb-controller-irsa"
  description   = "IAM Role for AWS Load Balancer Controller"
  create_policy = false
  policies = {
    ALBControllerPolicy = var.alb_controller_policy_arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller-sa"]
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  timeout    = 900

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
        cm = {
          "admin.enabled" = "true"
          url             = "http://localhost:8080"
        }
      }
      server = {
        ingress = {
          enabled = false # Day 2 — pending domain and SSO provisioning
        }
        service = {
          type = "ClusterIP"
        }
      }
      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
      }
      redis = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [module.eks]
}
