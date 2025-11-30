# infra/envs/dev/terraform.tfvars
# ===== Core =====
region  = "us-east-1"
project = "HC"
env     = "dev"

# Etiquetas globales
owner      = "Platform"
data_class = "PHI"

# ===== Networking =====
vpc_cidr             = "10.20.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]

# ===== KMS (aliases) =====
kms_alias_db         = "alias/hc-db"
kms_alias_adjuntos   = "alias/hc-adjuntos"
kms_alias_lambda_env = "alias/hc-lambda-env"

# ===== Aurora PostgreSQL Serverless v2 =====
db_engine_version        = "15.5"
db_username              = "hc_admin"
db_password              = "ChangeMe-Strong123!"
db_min_capacity          = 0.5
db_max_capacity          = 2.0
db_backup_retention_days = 7
skip_final_snapshot      = true

# ===== Buckets =====
s3_frontend_bucket = "hc-frontend-dev-116981769615"
s3_adjuntos_bucket = "hc-adjuntos-dev-116981769615"

# ===== CloudFront SPA =====
cf_comment         = "HC SPA dev"
cf_price_class     = "PriceClass_100"
cf_allowed_methods = ["GET", "HEAD"]
spa_index_document = "index.html"
spa_error_document = "index.html"

# ===== Cognito =====
cognito_domain_prefix       = "hc-dev-116981769615"
cognito_oauth_callback_urls = ["https://example.com/callback"]
cognito_oauth_logout_urls   = ["https://example.com/logout"]
cognito_allowed_origins     = ["*"]

# ===== API Gateway =====
apigw_stage_name  = "v1"
apigw_burst_limit = 100
apigw_rate_limit  = 50

# ===== Observabilidad =====
alarm_email = "melissayengle@gmail.com"

# ===== Jenkins EC2 =====
jenkins_instance_type      = "t3.small"
jenkins_key_pair_name = "hc-dev-jenkins-key"
jenkins_allowed_ssh_cidrs  = ["0.0.0.0/0"]
jenkins_allowed_http_cidrs = ["0.0.0.0/0"]
