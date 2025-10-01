variable "name_prefix" {
  description = "Prefijo común (p.ej. HC-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "azs" {
  description = "Zonas de disponibilidad (2 AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs para subredes privadas (una por AZ)"
  type        = list(string)
}

variable "tags" {
  description = "Tags globales"
  type        = map(string)
  default     = {}
}
