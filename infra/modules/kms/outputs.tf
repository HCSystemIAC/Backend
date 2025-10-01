output "kms_db_arn" {
  description = "ARN de la CMK para Aurora"
  value       = aws_kms_key.db.arn
}

output "kms_adjuntos_arn" {
  description = "ARN de la CMK para S3 Adjuntos"
  value       = aws_kms_key.adjuntos.arn
}

output "kms_lambda_env_arn" {
  description = "ARN de la CMK para variables de entorno Lambda"
  value       = aws_kms_key.lambda_env.arn
}
