variable "comment" {
  description = "Comentario/identificador de la distribución CloudFront"
  type        = string
}

variable "price_class" {
  description = "Price class de CloudFront (ej. PriceClass_100)"
  type        = string
}

variable "allowed_methods" {
  description = "Métodos HTTP permitidos en el comportamiento por defecto"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 privado que sirve la SPA"
  type        = string
}

variable "index_document" {
  description = "Documento de índice de la SPA (ej. index.html)"
  type        = string
}

variable "error_document" {
  description = "Documento de error usado como fallback SPA (ej. index.html)"
  type        = string
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
