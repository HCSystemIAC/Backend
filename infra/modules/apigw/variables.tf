variable "name_prefix" {
  description = "Prefijo común (ej: HC-dev)"
  type        = string
}

variable "region" {
  description = "Región AWS donde se despliega el API"
  type        = string
}

variable "stage_name" {
  description = "Nombre del stage de API Gateway (ej: v1)"
  type        = string
}

variable "burst_limit" {
  description = "Límite de ráfaga (burst) para el throttle del API"
  type        = number
}

variable "rate_limit" {
  description = "Límite de tasa (requests/seg) para el throttle del API"
  type        = number
}

variable "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito usado como authorizer"
  type        = string
}

variable "lambda_pacientes_arn" {
  description = "ARN de la Lambda de pacientes"
  type        = string
}

variable "lambda_historias_arn" {
  description = "ARN de la Lambda de historias"
  type        = string
}

variable "lambda_episodios_arn" {
  description = "ARN de la Lambda de episodios"
  type        = string
}

variable "lambda_adjuntos_arn" {
  description = "ARN de la Lambda de adjuntos"
  type        = string
}

variable "lambda_auditoria_arn" {
  description = "ARN de la Lambda de auditoría"
  type        = string
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
