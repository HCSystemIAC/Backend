########################################
# Módulo: cognito
# User Pool + App Client (PKCE) + Hosted UI + Grupos
########################################

data "aws_region" "current" {}

locals {
  tags = merge(var.tags, {
    Component = "cognito"
  })
}

# =============================
# User Pool
# =============================
resource "aws_cognito_user_pool" "this" {
  name = "${var.name_prefix}-user-pool"

  # Usamos el email como username directamente
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  mfa_configuration = "OFF"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = local.tags
}

# =============================
# App Client (PKCE, OAuth2 Code)
# =============================
resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.name_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  supported_identity_providers = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"

  refresh_token_validity = 30
  access_token_validity  = 60
  id_token_validity      = 60
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# =============================
# Hosted UI Domain
# =============================
resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

# =============================
# Grupos de Usuarios
# =============================
resource "aws_cognito_user_group" "admin" {
  name         = "ADMIN"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Administradores del sistema HC"
}

resource "aws_cognito_user_group" "medico" {
  name         = "MEDICO"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Personal médico asistencial"
}

resource "aws_cognito_user_group" "auditor" {
  name         = "AUDITOR"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Usuarios encargados de auditoría"
}
