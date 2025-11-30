output "trail_arn" {
  description = "ARN del CloudTrail configurado"
  value       = aws_cloudtrail.this.arn
}

output "logs_bucket_name" {
  description = "Nombre del bucket donde se almacenan los logs de CloudTrail"
  value       = aws_s3_bucket.logs.bucket
}
