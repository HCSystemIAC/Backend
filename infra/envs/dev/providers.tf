terraform {
  backend "s3" {
    bucket         = "hc-tfstate-116981769615-us-east-1"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hc-tf-locks"
    encrypt        = true
    kms_key_id     = "alias/hc-tfstate"
  }
}

provider "aws" {
  region = var.region
}
