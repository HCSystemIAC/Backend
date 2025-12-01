########################################
# Módulo: s3_frontend
# Bucket privado para SPA (sirve como origin de CloudFront OAC)
########################################

locals {
  tags = merge(var.tags, {
    Component = "s3-frontend"
  })
}

# =============================
# Bucket S3 para el frontend
# =============================
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # En dev podrías usar true si quieres permitir borrado con objetos
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
# Opcional: index.html dummy
# =============================
resource "aws_s3_object" "dummy_index" {
  count  = var.create_dummy_index ? 1 : 0
  bucket = aws_s3_bucket.this.bucket
  key    = var.index_key
  content = var.index_content
  content_type = "text/html"
}
