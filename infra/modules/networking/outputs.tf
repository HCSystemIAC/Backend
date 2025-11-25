# infra/modules/networking/outputs.tf
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs de subredes privadas"
  value       = [for s in aws_subnet.private : s.id]
}

output "sg_lambda_id" {
  description = "Security Group para Lambdas"
  value       = aws_security_group.sg_lambda.id
}

output "sg_rds_proxy_id" {
  description = "Security Group para RDS Proxy"
  value       = aws_security_group.sg_rds_proxy.id
}

output "sg_db_id" {
  description = "Security Group para Aurora/DB"
  value       = aws_security_group.sg_db.id
}
