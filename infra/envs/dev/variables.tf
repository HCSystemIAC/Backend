# infra/envs/dev/variables.tf
#################################
# Variables — entorno dev
#################################

# ===== Core =====
variable "region" {
  description = "AWS region del entorno"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nombre corto del proyecto para nombres y tags"
  type        = string
  default     = "HC"
}

variable "env" {
  description = "Nombre del ambiente (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

# Etiquetas globales (se usan en locals.tags)
variable "owner" {
  description = "Responsable del sistema (tag Owner)"
  type        = string
  default     = "Platform"
}

variable "data_class" {
  description = "Clasificación de datos (PHI/PII/etc.)"
  type        = string
  default     = "PHI"
}

# ===== Networking =====
variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "azs" {
  description = "Zonas de disponibilidad a utilizar"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs de subredes privadas (una por AZ)"
  type        = list(string)
}

# ===== KMS (aliases) =====
variable "kms_alias_db" {
  description = "Alias de la CMK para Aurora"
  type        = string
}

variable "kms_alias_adjuntos" {
  description = "Alias de la CMK para S3 de adjuntos"
  type        = string
}

variable "kms_alias_lambda_env" {
  description = "Alias de la CMK para cifrar variables de entorno de Lambda"
  type        = string
}

# ===== Aurora PostgreSQL Serverless v2 =====
variable "db_engine_version" {
  description = "Versión de PostgreSQL para Aurora (p.ej. 15.5)"
  type        = string
}

variable "db_username" {
  description = "Usuario maestro de la BD"
  type        = string
}

variable "db_password" {
  description = "Password del usuario maestro (solo dev; en prod usar Secrets)"
  type        = string
  sensitive   = true
}

variable "db_min_capacity" {
  description = "Capacidad mínima (ACU) de Aurora Serverless v2"
  type        = number
}

variable "db_max_capacity" {
  description = "Capacidad máxima (ACU) de Aurora Serverless v2"
  type        = number
}

variable "db_backup_retention_days" {
  description = "Retención de backups automáticos (días)"
  type        = number
}

variable "skip_final_snapshot" {
  description = "Si es true, no crea snapshot final al destruir (útil en dev)"
  type        = bool
  default     = true
}

# ===== RDS Proxy =====
variable "proxy_name" {
  description = "Nombre lógico del RDS Proxy"
  type        = string
}

# ===== Buckets =====
variable "s3_frontend_bucket" {
  description = "Nombre del bucket S3 para la SPA (privado, usado por CloudFront OAC)"
  type        = string
}

variable "s3_adjuntos_bucket" {
  description = "Nombre del bucket S3 para adjuntos (SSE-KMS obligatorio)"
  type        = string
}

# ===== CloudFront SPA =====
variable "cf_comment" {
  description = "Comentario/identificador de la distribución CloudFront"
  type        = string
}

variable "cf_price_class" {
  description = "Price class de CloudFront (p.ej. PriceClass_100)"
  type        = string
}

variable "cf_allowed_methods" {
  description = "Métodos HTTP permitidos en la distribución (GET/HEAD típicamente)"
  type        = list(string)
}

variable "spa_index_document" {
  description = "Documento de índice del sitio SPA (p.ej. index.html)"
  type        = string
}

variable "spa_error_document" {
  description = "Documento de error usado como fallback SPA (p.ej. index.html)"
  type        = string
}

# ===== Cognito =====
variable "cognito_domain_prefix" {
  description = "Prefijo único para el dominio del Hosted UI de Cognito"
  type        = string
}

variable "cognito_oauth_callback_urls" {
  description = "URLs de callback para OAuth2/OIDC (PKCE)"
  type        = list(string)
}

variable "cognito_oauth_logout_urls" {
  description = "URLs de logout para Cognito"
  type        = list(string)
}

variable "cognito_allowed_origins" {
  description = "Orígenes permitidos para CORS en Cognito"
  type        = list(string)
}

# ===== API Gateway =====
variable "apigw_stage_name" {
  description = "Nombre del stage del API Gateway (p.ej. v1)"
  type        = string
}

variable "apigw_burst_limit" {
  description = "Límite de ráfaga (burst) para el throttle del API"
  type        = number
}

variable "apigw_rate_limit" {
  description = "Límite de tasa (requests/seg) para el throttle del API"
  type        = number
}

# ===== Observabilidad =====
variable "alarm_email" {
  description = "Correo de suscripción para SNS (alarmas)"
  type        = string
}

# ===== Jenkins EC2 =====
variable "jenkins_instance_type" {
  description = "Tipo de instancia EC2 para Jenkins"
  type        = string
}

variable "jenkins_key_pair_name" {
  description = "Nombre del key pair EXISTENTE para SSH a Jenkins"
  type        = string
}

variable "jenkins_allowed_ssh_cidrs" {
  description = "CIDRs que pueden hacer SSH (22) a Jenkins"
  type        = list(string)
}

variable "jenkins_allowed_http_cidrs" {
  description = "CIDRs que pueden acceder a la UI de Jenkins (8080)"
  type        = list(string)
}