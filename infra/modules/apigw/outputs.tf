output "rest_api_id" {
  description = "ID del REST API de API Gateway"
  value       = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  description = "URL base para invocar el API (stage incluido)"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/${var.stage_name}"
}

output "authorizer_id" {
  description = "ID del authorizer Cognito"
  value       = aws_api_gateway_authorizer.cognito.id
}
