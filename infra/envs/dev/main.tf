# infra/envs/dev/main.tf
###########################################################
# main.tf — Orquestación del entorno dev
# Orden: networking → kms → rds_aurora → rds_proxy
#        → s3_frontend → cloudfront_spa → s3_adjuntos
#        → cognito → lambda_function → apigw
#        → observabilidad → cloudtrail → jenkins_ec2
###########################################################

locals {
  name_prefix = "${var.project}-${var.env}"
  tags = {
    Project   = var.project
    Env       = var.env
    Owner     = var.owner
    DataClass = var.data_class
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

############################
# 1) Networking (VPC sin NAT; subredes privadas A/B)
############################
module "networking" {
  source = "../../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = local.tags
}

############################
# 2) KMS (claves separadas)
############################
module "kms" {
  source = "../../modules/kms"

  alias_db         = var.kms_alias_db         # alias/hc-db
  alias_adjuntos   = var.kms_alias_adjuntos   # alias/hc-adjuntos
  alias_lambda_env = var.kms_alias_lambda_env # alias/hc-lambda-env
  tags             = local.tags
}

############################
# 3) Aurora PostgreSQL Serverless v2 (Multi-AZ, PITR)
############################
module "rds_aurora" {
  source = "../../modules/rds_aurora"

  name_prefix           = local.name_prefix
  engine_version        = var.db_engine_version
  username              = var.db_username
  password              = var.db_password
  min_capacity          = var.db_min_capacity
  max_capacity          = var.db_max_capacity
  backup_retention_days = var.db_backup_retention_days
  skip_final_snapshot   = var.skip_final_snapshot # 👈 cableado desde root

  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  sg_db_id    = module.networking.sg_db_id
  kms_key_arn = module.kms.kms_db_arn

  tags = local.tags
}

############################
# 4) RDS Proxy (pooling para Lambda)
############################
module "rds_proxy" {
  source = "../../modules/rds_proxy"

  name_prefix     = local.name_prefix
  subnet_ids      = module.networking.private_subnet_ids
  sg_rds_proxy_id = module.networking.sg_rds_proxy_id

  db_cluster_id = module.rds_aurora.db_cluster_id
  db_secret_arn = module.rds_aurora.db_master_secret_arn

  tags = local.tags
}

############################
# 5) S3 para Frontend (privado)
############################
module "s3_frontend" {
  source = "../../modules/s3_frontend"

  bucket_name = var.s3_frontend_bucket
  tags        = local.tags
}

############################
# 6) CloudFront para SPA (OAC; NO delante del API)
############################
module "cloudfront_spa" {
  source = "../../modules/cloudfront_spa"

  comment         = var.cf_comment
  price_class     = var.cf_price_class
  allowed_methods = var.cf_allowed_methods

  s3_bucket_name = module.s3_frontend.bucket_name
  index_document = var.spa_index_document
  error_document = var.spa_error_document
  tags           = local.tags
}

############################
# 7) S3 de Adjuntos (SSE-KMS + Data Events)
############################
module "s3_adjuntos" {
  source = "../../modules/s3_adjuntos"

  bucket_name = var.s3_adjuntos_bucket
  kms_key_arn = module.kms.kms_adjuntos_arn
  tags        = local.tags
}

############################
# 8) Cognito (Hosted UI + OAuth2/OIDC PKCE + grupos)
############################
module "cognito" {
  source = "../../modules/cognito"

  name_prefix   = local.name_prefix
  domain_prefix = var.cognito_domain_prefix

  callback_urls   = var.cognito_oauth_callback_urls
  logout_urls     = var.cognito_oauth_logout_urls
  allowed_origins = var.cognito_allowed_origins

  tags = local.tags
}

############################
# 9) Lambdas (5) — rol + VPC + env + permisos mínimos
############################
module "lambda_function" {
  source = "../../modules/lambda_function"

  name_prefix  = local.name_prefix
  subnet_ids   = module.networking.private_subnet_ids
  sg_lambda_id = module.networking.sg_lambda_id
  kms_env_arn  = module.kms.kms_lambda_env_arn

  # Si el proxy aún no está aplicado, pasa cadena vacía.
  rds_proxy_endpoint = try(module.rds_proxy.proxy_endpoint, "")
  s3_adjuntos_bucket = module.s3_adjuntos.bucket_name

  # Rutas del código backend (usa paths absolutos para evitar warnings del editor)
  src_pacientes = abspath("${path.root}/../../../backend/pacientes")
  src_historias = abspath("${path.root}/../../../backend/historias")
  src_episodios = abspath("${path.root}/../../../backend/episodios")
  src_adjuntos  = abspath("${path.root}/../../../backend/adjuntos")
  src_auditoria = abspath("${path.root}/../../../backend/auditoria")

  # Parámetros de ejecución (explícitos para acallar el linter)
  runtime         = "python3.12"
  handler         = "app.handler"
  timeout_seconds = 10
  memory_mb       = 256

  # Hereda el stage del ambiente
  stage = var.env

  tags = local.tags
}

############################
# 10) API Gateway (Regional) + Authorizer Cognito
############################
module "apigw" {
  source = "../../modules/apigw"

  name_prefix = local.name_prefix
  region      = var.region
  stage_name  = var.apigw_stage_name
  burst_limit = var.apigw_burst_limit
  rate_limit  = var.apigw_rate_limit

  cognito_user_pool_id = module.cognito.user_pool_id

  # Integraciones por ruta
  lambda_pacientes_arn = module.lambda_function.lambda_pacientes_arn
  lambda_historias_arn = module.lambda_function.lambda_historias_arn
  lambda_episodios_arn = module.lambda_function.lambda_episodios_arn
  lambda_adjuntos_arn  = module.lambda_function.lambda_adjuntos_arn
  lambda_auditoria_arn = module.lambda_function.lambda_auditoria_arn

  tags = local.tags
}

############################
# 11) Observabilidad (CloudWatch Alarms + SNS)
############################
module "observability" {
  source = "../../modules/observability"

  name_prefix = local.name_prefix
  alarm_email = var.alarm_email

  apigw_rest_api_id     = module.apigw.rest_api_id
  apigw_stage_name      = var.apigw_stage_name
  lambda_function_names = module.lambda_function.lambda_names
  db_cluster_arn        = module.rds_aurora.db_cluster_arn

  tags = local.tags
}

############################
# 12) CloudTrail (Mgmt + Data Events SOLO adjuntos)
############################
module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name_prefix               = local.name_prefix
  s3_data_events_bucket_arn = module.s3_adjuntos.bucket_arn
  tags                      = local.tags
}

############################
# 13) Jenkins EC2 (para pipeline de IaC)
############################
module "jenkins_ec2" {
  source = "../../modules/jenkins-ec2"

  name_prefix        = local.name_prefix
  instance_type      = var.jenkins_instance_type
  key_pair_name      = var.jenkins_key_pair_name
  allowed_ssh_cidrs  = var.jenkins_allowed_ssh_cidrs
  allowed_http_cidrs = var.jenkins_allowed_http_cidrs

  tags = local.tags
}
