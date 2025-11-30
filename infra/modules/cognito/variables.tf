variable "name_prefix" {
  description = "Prefijo común (ej: HC-dev)"
  type        = string
}

variable "domain_prefix" {
  description = "Prefijo único para el dominio del Hosted UI"
  type        = string
}

variable "callback_urls" {
  description = "URLs de callback para OAuth2/OIDC (PKCE)"
  type        = list(string)
}

variable "logout_urls" {
  description = "URLs de logout para Cognito"
  type        = list(string)
}

variable "allowed_origins" {
  description = "Orígenes permitidos (CORS frontend) - reservado para uso futuro"
  type        = list(string)
}

variable "tags" {
  description = "Tags comunes del proyecto"
  type        = map(string)
  default     = {}
}
