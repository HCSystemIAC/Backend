terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  tags = {
    Project   = var.project
    Env       = var.env
    Owner     = "Platform"
    DataClass = "Meta"
    Purpose   = "tfstate"
  }
}

# --- CMK para cifrar el tfstate (SSE-KMS del bucket backend)
resource "aws_kms_key" "tfstate" {
  description             = "KMS para cifrar Terraform state (${var.project})"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/hc-tfstate"
  target_key_id = aws_kms_key.tfstate.id
}

# --- Bucket S3 para el tfstate
resource "aws_s3_bucket" "tfstate" {
  bucket        = var.tfstate_bucket
  force_destroy = var.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

# Cifrado con KMS propio
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
  }
}

# Bloquear acceso público + exigir TLS
resource "aws_s3_bucket_public_access_block" "bpa" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# --- DynamoDB para locks de Terraform
resource "aws_dynamodb_table" "locks" {
  name         = var.tf_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}
