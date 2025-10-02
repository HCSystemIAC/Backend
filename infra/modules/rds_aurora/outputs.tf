output "db_cluster_arn"  { value = aws_rds_cluster.this.arn }
output "db_cluster_id"   { value = aws_rds_cluster.this.id }
output "writer_endpoint" { value = aws_rds_cluster.this.endpoint }
output "reader_endpoint" { value = aws_rds_cluster.this.reader_endpoint }

output "db_master_secret_arn" {
  value = aws_secretsmanager_secret.db_master.arn
}
