########################################
# Módulo: cloudfront_spa
# Distribución CloudFront para SPA con OAC hacia S3 privado
########################################

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Component = "cloudfront-spa"
  })

  origin_id = "s3-frontend-origin"
}

# =======================================
# Origin Access Control (OAC) para S3
# =======================================
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.comment}-oac"
  description                       = "OAC para acceder al bucket S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =======================================
# Distribución CloudFront (SPA)
# =======================================
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = var.comment
  price_class         = var.price_class
  default_root_object = var.index_document

  origin {
    domain_name              = "${var.s3_bucket_name}.s3.amazonaws.com"
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods  = var.allowed_methods        # ej: ["GET","HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  # SPA: redirigir 403/404 al index.html de la app
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.error_document}"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.error_document}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

# =======================================
# Bucket policy para permitir acceso SOLO
# desde esta distribución (OAC)
# =======================================
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOACRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}
