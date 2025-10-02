variable "region" {
  description = "Región AWS para el backend remoto de Terraform"
  type        = string
}

variable "project" {
  description = "Nombre corto del proyecto (tags, nombres)"
  type        = string
  default     = "HC"
}

variable "env" {
  description = "Ambiente lógico (solo para tags del bootstrap)"
  type        = string
  default     = "bootstrap"
}

variable "tfstate_bucket" {
  description = "Nombre del bucket S3 para guardar el terraform.tfstate (debe ser único globalmente)"
  type        = string
}

variable "tf_lock_table" {
  description = "Nombre de la tabla DynamoDB para locks de Terraform"
  type        = string
}

variable "force_destroy" {
  description = "Permite borrar el bucket con objetos (NO usar en prod)"
  type        = bool
  default     = false
}
