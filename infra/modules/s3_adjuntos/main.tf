########################################
# Módulo: s3_adjuntos
# Bucket privado con SSE-KMS y bloqueo público
########################################

locals {
  tags = merge(var.tags, {
    Component = "s3-adjuntos"
  })
}

# =============================
# Bucket S3 de adjuntos clínicos
# =============================
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # En dev podrías poner true si quieres que se destruya aunque tenga objetos.
  # Para un entorno más realista, lo dejamos en false.
  force_destroy = false

  tags = merge(local.tags, {
    Name = var.bucket_name
  })
}

# =============================
# Bloqueo de acceso público
# =============================
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================
# Cifrado lado servidor (SSE-KMS)
# =============================
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# =============================
# Versioning (recomendable para adjuntos)
# =============================
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}
