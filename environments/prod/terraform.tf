terraform {
  required_version = "1.15.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.46.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.2"
    }
  }
}
