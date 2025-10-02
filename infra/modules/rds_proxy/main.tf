locals {
  tags      = merge(var.tags, { Component = "rds-proxy" })
  id_prefix = lower(var.name_prefix) # para names/identifiers con restricciones
}

# IAM role para que el Proxy lea el secret
data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_proxy_role" {
  name               = "${var.name_prefix}-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(local.tags, { Name = "${var.name_prefix}-rds-proxy-role" })
}

# Permisos para leer el Secret de credenciales
data "aws_iam_policy_document" "read_secret" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name   = "${var.name_prefix}-rds-proxy-secrets"
  role   = aws_iam_role.rds_proxy_role.id
  policy = data.aws_iam_policy_document.read_secret.json
}

# RDS Proxy (usa el secret del cluster Aurora)
resource "aws_db_proxy" "this" {
  name                   = "${local.id_prefix}-rds-proxy" # <- minúsculas y empieza con letra
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [var.sg_rds_proxy_id]
  vpc_subnet_ids         = var.subnet_ids
  debug_logging          = false

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = var.db_secret_arn
  }

  tags = merge(local.tags, { Name = "${var.name_prefix}-rds-proxy" })
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "cluster" {
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.default.name
  db_cluster_identifier = var.db_cluster_id
}


