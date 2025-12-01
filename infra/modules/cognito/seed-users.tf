########################################
# Seed de usuarios de prueba (DEV)
# Crea 3 usuarios y los asigna a sus grupos:
#  - ADMIN
#  - MEDICO
#  - AUDITOR
########################################

# Usuario ADMIN
resource "aws_cognito_user" "seed_admin" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = "admin.dev@hc.local"

  # Debe respetar la policy:
  # min 8, mayúscula, minúscula, número
  temporary_password = "AdminDev123"

  # No enviar correo (lo gestionas tú)
  message_action = "SUPPRESS"

  attributes = {
    email          = "admin.dev@hc.local"
    email_verified = "true"
  }
}

resource "aws_cognito_user_in_group" "seed_admin_group" {
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.admin.name
  username     = aws_cognito_user.seed_admin.username
}

# Usuario MEDICO
resource "aws_cognito_user" "seed_medico" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = "medico.dev@hc.local"

  temporary_password = "MedicoDev123"
  message_action     = "SUPPRESS"

  attributes = {
    email          = "medico.dev@hc.local"
    email_verified = "true"
  }
}

resource "aws_cognito_user_in_group" "seed_medico_group" {
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.medico.name
  username     = aws_cognito_user.seed_medico.username
}

# Usuario AUDITOR
resource "aws_cognito_user" "seed_auditor" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = "auditor.dev@hc.local"

  temporary_password = "AuditorDev123"
  message_action     = "SUPPRESS"

  attributes = {
    email          = "auditor.dev@hc.local"
    email_verified = "true"
  }
}

resource "aws_cognito_user_in_group" "seed_auditor_group" {
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.auditor.name
  username     = aws_cognito_user.seed_auditor.username
}
