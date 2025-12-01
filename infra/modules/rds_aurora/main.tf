# infra/modules/rds_aurora/main.tf
locals {
  tags      = merge(var.tags, { Component = "rds-aurora" })
  id_prefix = lower(var.name_prefix)  # usar SIEMPRE para identifiers de RDS
}

# Subnet group privado (A/B) — identifiers en minúsculas
resource "aws_db_subnet_group" "this" {
  name       = "${local.id_prefix}-aurora-subnets"
  subnet_ids = var.subnet_ids
  tags       = merge(local.tags, { Name = "${var.name_prefix}-aurora-subnets" })
}

# Secret con credenciales del master (fuente única para Proxy)
resource "aws_secretsmanager_secret" "db_master" {
  name        = "${var.name_prefix}-db-master"
  description = "Master credentials for Aurora cluster (used by RDS Proxy)"
  kms_key_id  = var.kms_key_arn

  # dev: destrucción inmediata sin ventana de recuperación
  recovery_window_in_days = 0

  tags = merge(local.tags, { Name = "${var.name_prefix}-db-master" })
}

resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id

  secret_string = jsonencode({
    username = var.username
    password = var.password
    engine   = "postgresql"
    port     = 5432
    dbname   = "hcdb"
  })
}

# Cluster Aurora PostgreSQL Serverless v2 — identifiers en minúsculas
resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${local.id_prefix}-aurora"
  engine                  = "aurora-postgresql"
  # Dejamos que AWS elija una versión válida por defecto
  # engine_version        = var.engine_version

  engine_mode             = "provisioned" # requerido para Serverless v2
  database_name           = "hcdb"
  master_username         = var.username
  master_password         = var.password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.sg_db_id]
  storage_encrypted       = true
  kms_key_id              = var.kms_key_arn
  backup_retention_period = var.backup_retention_days
  preferred_backup_window = "06:15-06:45"
  deletion_protection     = false
  copy_tags_to_snapshot   = true
  apply_immediately       = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  iam_database_authentication_enabled = false

  skip_final_snapshot = var.skip_final_snapshot

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = merge(local.tags, { Name = "${var.name_prefix}-aurora-cluster" })
}

# Writer (Serverless) — identifier en minúsculas
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${local.id_prefix}-aurora-writer-1"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"

  # Hereda engine/versión del cluster, no fijamos versión aquí
  engine = aws_rds_cluster.this.engine
  # engine_version = aws_rds_cluster.this.engine_version

  publicly_accessible          = false
  performance_insights_enabled = false
  apply_immediately            = true

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-aurora-writer-1"
    Role = "writer"
  })
}
