terraform {
  backend "s3" {
    bucket       = "the-redemption-terraform-state-prod-837411785224-us-east-1-an"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
