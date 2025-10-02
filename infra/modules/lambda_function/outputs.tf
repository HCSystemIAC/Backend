# ARNs por función (clave fija del for_each)
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

# Nombres de todas las lambdas (útil para observabilidad)
output "lambda_names" {
  value = [for k, f in aws_lambda_function.fn : f.function_name]
}
