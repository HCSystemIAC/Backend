# infra/modules/rds_proxy/variables.tf
variable "name_prefix"     { type = string }
variable "subnet_ids"      { type = list(string) }
variable "sg_rds_proxy_id" { type = string }
variable "db_cluster_id"   { type = string }
variable "db_secret_arn"   { type = string }
variable "tags"            { type = map(string) }
