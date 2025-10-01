variable "name_prefix"        { type = string }
variable "subnet_ids"         { type = list(string) }
variable "sg_lambda_id"       { type = string }
variable "kms_env_arn"        { type = string }
variable "rds_proxy_endpoint" { type = string }
variable "s3_adjuntos_bucket" { type = string }
variable "tags"               { type = map(string) }
