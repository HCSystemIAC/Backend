#infra/modules/cloudtrail/main.tf
########################################
# Módulo: cloudtrail
# Trail de cuenta + Data Events S3 (adjuntos)
########################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  id_prefix = lower(var.name_prefix)

  tags = merge(var.tags, {
    Component = "cloudtrail"
  })
}

########################################
# Bucket para logs de CloudTrail
########################################

resource "aws_s3_bucket" "logs" {
  bucket = "${local.id_prefix}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.id}"

  force_destroy = false

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-cloudtrail-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política para permitir que CloudTrail escriba en el bucket
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control",
            "aws:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail"
          }
        }
      }
    ]
  })
}

########################################
# CloudTrail: management + S3 data events adjuntos
########################################

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # Management events de toda la cuenta
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  # Data events SOLO para el bucket de adjuntos
  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.s3_data_events_bucket_arn}/"]
    }
  }

  tags = local.tags

  depends_on = [
    aws_s3_bucket_policy.logs
  ]
}
