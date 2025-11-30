output "domain_name" {
  description = "Dominio público de la distribución CloudFront"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.this.id
}
