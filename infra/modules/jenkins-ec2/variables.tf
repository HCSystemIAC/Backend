# infra/modules/jenkins-ec2/variables.tf
variable "name_prefix" {
  description = "Prefijo lógico del entorno, ej: HC-dev"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para Jenkins"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Nombre del key pair EXISTENTE para acceder por SSH"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs que pueden hacer SSH (22) a Jenkins"
  type        = list(string)
}

variable "allowed_http_cidrs" {
  description = "CIDRs que pueden acceder al puerto 8080 de Jenkins"
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
}
