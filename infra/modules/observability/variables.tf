variable "name_prefix" {
  description = "Prefijo común (ej: HC-dev)"
  type        = string
}

variable "alarm_email" {
  description = "Correo para suscripción al SNS de alarmas"
  type        = string
}

variable "apigw_rest_api_id" {
  description = "ID del REST API (actualmente no se usa, reservado para ajustes futuros)"
  type        = string
}

variable "apigw_stage_name" {
  description = "Nombre del stage de API Gateway (ej: v1)"
  type        = string
}

variable "lambda_function_names" {
  description = "Lista de nombres de funciones Lambda a monitorear"
  type        = list(string)
}

variable "db_cluster_arn" {
  description = "ARN del cluster Aurora para métricas de RDS"
  type        = string
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
