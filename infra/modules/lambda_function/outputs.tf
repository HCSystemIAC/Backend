# infra/modules/lambda_function/outputs.tf
output "lambda_pacientes_arn" {
  value = aws_lambda_function.fn["pacientes"].arn
}

output "lambda_historias_arn" {
  value = aws_lambda_function.fn["historias"].arn
}

output "lambda_episodios_arn" {
  value = aws_lambda_function.fn["episodios"].arn
}

output "lambda_adjuntos_arn" {
  value = aws_lambda_function.fn["adjuntos"].arn
}

output "lambda_auditoria_arn" {
  value = aws_lambda_function.fn["auditoria"].arn
}

# Lista con los nombres (para Observabilidad)
output "lambda_names" {
  value = [for k, f in aws_lambda_function.fn : f.function_name]
}
