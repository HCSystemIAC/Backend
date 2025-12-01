variable "bucket_name" {
  description = "Nombre del bucket S3 para adjuntos clínicos"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la CMK KMS usada para cifrar el bucket (SSE-KMS)"
  type        = string
}

variable "versioning_enabled" {
  description = "Habilitar versioning en el bucket de adjuntos"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
