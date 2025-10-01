variable "name_prefix"         { type = string }
variable "region"              { type = string }
variable "stage_name"          { type = string }
variable "burst_limit"         { type = number }
variable "rate_limit"          { type = number }
variable "cognito_user_pool_id"{ type = string }

variable "lambda_pacientes_arn" { type = string }
variable "lambda_historias_arn" { type = string }
variable "lambda_episodios_arn" { type = string }
variable "lambda_adjuntos_arn"  { type = string }
variable "lambda_auditoria_arn" { type = string }

variable "tags" { type = map(string) }
