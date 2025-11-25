# infra/modules/rds_aurora/variables.tf
variable "name_prefix" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "backup_retention_days" {
  type = number
}

# No se usa directamente (el cluster usa el subnet group)
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "sg_db_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Si es true, no crea snapshot final al destruir (útil en dev)"
  default     = true
}
