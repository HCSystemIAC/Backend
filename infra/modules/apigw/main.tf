#infra/modules/apigw/main.tf
########################################
# Módulo: apigw
# API Gateway REST Regional + Cognito + Lambdas por dominio
########################################

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, { Component = "apigw" })

  # Mapa recurso → ARN de Lambda
  resources = {
    "pacientes" = var.lambda_pacientes_arn
    "historias" = var.lambda_historias_arn
    "episodios" = var.lambda_episodios_arn
    "adjuntos"  = var.lambda_adjuntos_arn
    "auditoria" = var.lambda_auditoria_arn
  }
}

# =============================
# REST API Regional
# =============================
resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.name_prefix}-api"
  description = "API HC para pacientes, historias clínicas y episodios"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags
}

# =============================
# Authorizer Cognito (JWT)
# =============================
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.name_prefix}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.this.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns = [
    "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${var.cognito_user_pool_id}"
  ]
}

# =============================
# Recursos de primer nivel
# =============================
resource "aws_api_gateway_resource" "resource" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key
}

# =============================
# Métodos GET/POST protegidos con Cognito
# =============================
resource "aws_api_gateway_method" "get" {
  for_each         = local.resources
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.resource[each.key].id
  http_method      = "GET"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito.id
  api_key_required = false
}

resource "aws_api_gateway_method" "post" {
  for_each         = local.resources
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.resource[each.key].id
  http_method      = "POST"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito.id
  api_key_required = false
}

# =============================
# Método OPTIONS (CORS, sin auth)
# =============================
resource "aws_api_gateway_method" "options" {
  for_each         = local.resources
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.resource[each.key].id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

# MOCK integration para el preflight
resource "aws_api_gateway_integration" "options_integration" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Respuesta del método OPTIONS
resource "aws_api_gateway_method_response" "options_response" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  for_each    = local.resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options_response[each.key].status_code

  # Para dev usamos origen "*"; incluye GET/POST/OPTIONS y cabeceras usadas por el front
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type'"
  }
}

# =============================
# Integraciones Lambda Proxy
# =============================
resource "aws_api_gateway_integration" "get_integration" {
  for_each                = local.resources
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.get[each.key].http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${each.value}/invocations"
}

resource "aws_api_gateway_integration" "post_integration" {
  for_each                = local.resources
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.post[each.key].http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${each.value}/invocations"
}

# =============================
# Permisos Lambda para ser invocadas por API GW
# =============================
resource "aws_lambda_permission" "api_invoke" {
  for_each = local.resources

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/${each.key}"
}

# =============================
# Deployment + Stage
# =============================
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  # Fuerza redeploy si cambia algo relevante
  triggers = {
    redeploy = timestamp()
  }

  # Evita el error de borrar un deployment aún referenciado por el stage
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id

  tags = local.tags
}
