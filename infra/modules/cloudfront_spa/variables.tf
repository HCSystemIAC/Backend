variable "comment"         { type = string }
variable "price_class"     { type = string }
variable "allowed_methods" { type = list(string) }
variable "s3_bucket_name"  { type = string }
variable "index_document"  { type = string }
variable "error_document"  { type = string }
variable "tags"            { type = map(string) }
