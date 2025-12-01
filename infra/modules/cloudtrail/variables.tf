variable "name_prefix" {
  description = "Prefijo común (ej: HC-dev)"
  type        = string
}

variable "s3_data_events_bucket_arn" {
  description = "ARN del bucket S3 cuyos data events se quieren registrar (adjuntos)"
  type        = string
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
