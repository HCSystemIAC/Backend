variable "name_prefix"          { type = string }
variable "alarm_email"          { type = string }
variable "apigw_rest_api_id"    { type = string }
variable "apigw_stage_name"     { type = string }
variable "lambda_function_names"{ type = list(string) }
variable "db_cluster_arn"       { type = string }
variable "tags"                 { type = map(string) }
