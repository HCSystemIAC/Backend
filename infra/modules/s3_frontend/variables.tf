variable "bucket_name" {
  description = "Nombre del bucket S3 para la SPA frontend"
  type        = string
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}

variable "create_dummy_index" {
  description = "Si es true, crea un index.html dummy para pruebas"
  type        = bool
  default     = false
}

variable "index_key" {
  description = "Key del archivo de índice (por defecto index.html)"
  type        = string
  default     = "index.html"
}

variable "index_content" {
  description = "Contenido HTML simple para el index.html dummy"
  type        = string
  default     = "<!doctype html><html><head><meta charset=\"utf-8\"><title>HC SPA</title></head><body><h1>HC Frontend</h1><p>Bucket S3 frontend listo como origin de CloudFront.</p></body></html>"
}
