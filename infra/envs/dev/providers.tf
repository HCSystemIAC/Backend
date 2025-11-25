# infra/envs/dev/providers.tf
terraform {
  backend "s3" {
    bucket       = "hc-tfstate-116981769615-us-east-1"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}
