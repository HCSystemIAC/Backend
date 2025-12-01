output "user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.this.id
}

output "app_client_id" {
  description = "ID del App Client de Cognito"
  value       = aws_cognito_user_pool_client.this.id
}

output "hosted_ui_domain" {
  description = "Dominio completo del Hosted UI de Cognito"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.id}.amazoncognito.com"
}
