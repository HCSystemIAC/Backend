variable "name_prefix"     { type = string }
variable "domain_prefix"   { type = string }
variable "callback_urls"   { type = list(string) }
variable "logout_urls"     { type = list(string) }
variable "allowed_origins" { type = list(string) }
variable "tags"            { type = map(string) }
