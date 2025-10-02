# ====== Inputs core del módulo ======

variable "name_prefix"     { type = string }
variable "subnet_ids"      { type = list(string) }
variable "sg_lambda_id"    { type = string }
variable "kms_env_arn"     { type = string }

# El proxy puede no existir aún; permite cadena vacía
variable "rds_proxy_endpoint" {
  type    = string
  default = ""
}

variable "s3_adjuntos_bucket" { type = string }
variable "tags"               { type = map(string) }

# ====== Rutas del código (carpetas con app.py y requirements.txt) ======
variable "src_pacientes" { type = string }
variable "src_historias" { type = string }
variable "src_episodios" { type = string }
variable "src_adjuntos"  { type = string }
variable "src_auditoria" { type = string }

# ====== Parámetros de ejecución ======
variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "app.handler"
}

variable "timeout_seconds" {
  type    = number
  default = 10
}

variable "memory_mb" {
  type    = number
  default = 256
}

# Para etiquetar/nombrar artefactos (p.ej. alias de versiones)
variable "stage" {
  type    = string
  default = "dev"
}

# ====== Env extra opcional ======
# Te permite inyectar pares clave/valor adicionales al entorno.
variable "extra_env" {
  type    = map(string)
  default = {}
}
