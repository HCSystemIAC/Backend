variable "region" {
  description = "AWS region del entorno"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nombre corto del proyecto"
  type        = string
  default     = "HC"
}

variable "env" {
  description = "Nombre del ambiente"
  type        = string
  default     = "dev"
}
