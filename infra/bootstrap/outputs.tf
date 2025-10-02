output "kms_key_arn" {
  description = "ARN de la CMK usada para cifrar el tfstate"
  value       = aws_kms_key.tfstate.arn
}

output "tfstate_bucket_name" {
  description = "Nombre del bucket S3 del tfstate"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_lock_table" {
  description = "Nombre de la tabla DynamoDB para locks"
  value       = aws_dynamodb_table.locks.name
}
