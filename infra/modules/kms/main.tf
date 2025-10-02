data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id
}

# =========================================================
# 1) CMK para Aurora (DB)
# =========================================================
resource "aws_kms_key" "db" {
  description             = "KMS para cifrar Aurora (HC)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Propietario (root de la cuenta)
      {
        Sid      = "EnableRootPermissions"
        Effect   = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      # Permitir que el servicio RDS/Aurora use la llave en esta cuenta
      {
        Sid    = "AllowRDSServiceUse"
        Effect = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Encrypt","kms:Decrypt","kms:ReEncrypt*",
          "kms:GenerateDataKey*","kms:CreateGrant","kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
  tags = merge(var.tags, { Component = "kms", Purpose = "aurora" })
}

resource "aws_kms_alias" "db" {
  name          = var.alias_db           # ej: alias/hc-db
  target_key_id = aws_kms_key.db.key_id
}

# =========================================================
# 2) CMK para S3 Adjuntos
#    (usaremos esta CMK en el bucket de adjuntos, con política
#     para que S3 la pueda usar y podamos requerir SSE-KMS)
# =========================================================
resource "aws_kms_key" "adjuntos" {
  description             = "KMS para cifrar objetos del bucket de Adjuntos (HC)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Root
      {
        Sid      = "EnableRootPermissions"
        Effect   = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      # Servicio S3 puede usar la llave (para SSE-KMS)
      {
        Sid    = "AllowS3ServiceUse"
        Effect = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = [
          "kms:Encrypt","kms:Decrypt","kms:ReEncrypt*",
          "kms:GenerateDataKey*","kms:CreateGrant","kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
  tags = merge(var.tags, { Component = "kms", Purpose = "s3-adjuntos" })
}

resource "aws_kms_alias" "adjuntos" {
  name          = var.alias_adjuntos     # ej: alias/hc-adjuntos
  target_key_id = aws_kms_key.adjuntos.key_id
}

# =========================================================
# 3) CMK para variables de entorno de Lambda
#    (Lambda descifra env vars en cold start; no requiere NAT)
# =========================================================
resource "aws_kms_key" "lambda_env" {
  description             = "KMS para cifrar variables de entorno de funciones Lambda (HC)"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Root
      {
        Sid      = "EnableRootPermissions"
        Effect   = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      # Servicio Lambda puede usar la llave (para env vars KMS)
      {
        Sid    = "AllowLambdaServiceUse"
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action = [
          "kms:Encrypt","kms:Decrypt","kms:ReEncrypt*",
          "kms:GenerateDataKey*","kms:CreateGrant","kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
  tags = merge(var.tags, { Component = "kms", Purpose = "lambda-env" })
}

resource "aws_kms_alias" "lambda_env" {
  name          = var.alias_lambda_env   # ej: alias/hc-lambda-env
  target_key_id = aws_kms_key.lambda_env.key_id
}
