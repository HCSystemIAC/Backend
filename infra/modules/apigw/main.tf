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
  provider_arns   = [
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
    aws_api_gateway_integration.post_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  # Fuerza redeploy si cambia algo relevante
  triggers = {
    redeploy = timestamp()
  }
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id

  tags = local.tags
}

# =============================
# Method settings globales (throttle + logs)
# =============================
resource "aws_api_gateway_method_settings" "global" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "ERROR"
    data_trace_enabled     = false
    metrics_enabled        = true
    throttling_burst_limit = var.burst_limit
    throttling_rate_limit  = var.rate_limit
  }
}
