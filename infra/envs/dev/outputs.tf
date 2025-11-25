# infra/envs/dev/outputs.tf
############################
# Outputs — entorno dev
############################

output "frontend_bucket" {
  description = "Nombre del bucket S3 del frontend"
  value       = try(module.s3_frontend.bucket_name, "")
}

output "cloudfront_domain" {
  description = "Dominio de la distribución CloudFront de la SPA"
  value       = try(module.cloudfront_spa.domain_name, "")
}

output "apigw_invoke_url" {
  description = "Invoke URL del API Gateway"
  value       = try(module.apigw.invoke_url, "")
}

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = try(module.cognito.user_pool_id, "")
}

output "cognito_app_client_id" {
  description = "ID del App Client de Cognito"
  value       = try(module.cognito.app_client_id, "")
}

output "cognito_hosted_ui_domain" {
  description = "Dominio del Hosted UI de Cognito"
  value       = try(module.cognito.hosted_ui_domain, "")
}

output "jenkins_public_ip" {
  description = "IP pública de la instancia Jenkins (dev)"
  value       = try(module.jenkins_ec2.jenkins_public_ip, "")
}

output "jenkins_public_dns" {
  description = "DNS público de la instancia Jenkins (dev)"
  value       = try(module.jenkins_ec2.jenkins_public_dns, "")
}

output "jenkins_url" {
  description = "URL de acceso HTTP a Jenkins"
  value       = try(module.jenkins_ec2.jenkins_url, "")
}
