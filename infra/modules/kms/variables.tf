variable "alias_db" {
  description = "Alias para la CMK de base de datos (ej. alias/hc-db)"
  type        = string
}

variable "alias_adjuntos" {
  description = "Alias para la CMK de S3 Adjuntos (ej. alias/hc-adjuntos)"
  type        = string
}

variable "alias_lambda_env" {
  description = "Alias para la CMK de variables de entorno Lambda (ej. alias/hc-lambda-env)"
  type        = string
}

variable "tags" {
  description = "Tags globales"
  type        = map(string)
  default     = {}
}
