# infra/modules/rds_proxy/outputs.tf
output "proxy_endpoint" {
  value = aws_db_proxy.this.endpoint
}
