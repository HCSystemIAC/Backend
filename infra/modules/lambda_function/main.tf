# infra/modules/lambda_function/main.tf
########################################
# Módulo: lambda_function
########################################

locals {
  tags       = merge(var.tags, { Component = "lambda" })
  name_base  = lower(var.name_prefix)

  functions = {
    pacientes = {
      src_dir = var.src_pacientes
      name    = "${local.name_base}-lambda-pacientes"
    }
    historias = {
      src_dir = var.src_historias
      name    = "${local.name_base}-lambda-historias"
    }
    episodios = {
      src_dir = var.src_episodios
      name    = "${local.name_base}-lambda-episodios"
    }
    adjuntos = {
      src_dir = var.src_adjuntos
      name    = "${local.name_base}-lambda-adjuntos"
    }
    auditoria = {
      src_dir = var.src_auditoria
      name    = "${local.name_base}-lambda-auditoria"
    }
  }
}

############################
# IAM Role (básico)
############################

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(local.tags, { Name = "${var.name_prefix}-lambda-role" })
}

# Logs + VPC ENI
data "aws_iam_policy_document" "inline" {
  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    sid     = "VpcNetworking"
    effect  = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "SecretsRead"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "inline" {
  name   = "${var.name_prefix}-lambda-inline"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.inline.json
}

############################
# Empaquetado por función
############################

# Genera un .zip por cada función desde su carpeta src_dir
data "archive_file" "zip" {
  for_each    = local.functions
  type        = "zip"
  source_dir  = each.value.src_dir
  output_path = "${path.module}/build/${each.key}.zip"
}

############################
# CloudWatch Log Groups
############################
resource "aws_cloudwatch_log_group" "lg" {
  for_each          = local.functions
  name              = "/aws/lambda/${local.functions[each.key].name}"
  retention_in_days = 14
  tags              = local.tags
}

############################
# Lambdas
############################
resource "aws_lambda_function" "fn" {
  for_each = local.functions

  function_name = each.value.name
  description   = "Lambda ${each.key}"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.zip[each.key].output_path
  source_code_hash = data.archive_file.zip[each.key].output_base64sha256

  handler = var.handler          # "app.handler"
  runtime = var.runtime          # "python3.12"
  timeout = var.timeout_seconds  # 10
  memory_size = var.memory_mb    # 256

  kms_key_arn = var.kms_env_arn

  environment {
    variables = merge(
      {
        STAGE               = var.stage
        SERVICE             = "hc"
        RDS_PROXY_ENDPOINT  = var.rds_proxy_endpoint
        S3_ADJUNTOS_BUCKET  = var.s3_adjuntos_bucket
      },
      var.extra_env
    )
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.sg_lambda_id]
  }

  tags = merge(local.tags, { Name = each.value.name })

  depends_on = [aws_iam_role_policy.inline, aws_cloudwatch_log_group.lg]
}
