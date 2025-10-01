locals {
  tags = merge(var.tags, {
    Component = "networking"
  })
}

# ----------------------
# VPC (sin NAT/IGW)
# ----------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ----------------------
# Subredes privadas A/B
# ----------------------
resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-private-${each.value.az}"
    Tier = "private"
  })
}

# ----------------------
# Route tables privadas (solo ruta local)
# ----------------------
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id
  tags = merge(local.tags, {
    Name = "${var.name_prefix}-rtb-private-${each.value.availability_zone}"
  })
}

# Solo la ruta local existe por defecto; la dejamos así (sin IGW/NAT)

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# =========================================================
# Security Groups (modelo en cadena Lambda -> Proxy -> DB)
# =========================================================
# SG para Lambdas (sin ingress; egress 5432 al SG del Proxy)
resource "aws_security_group" "sg_lambda" {
  name        = "${var.name_prefix}-sg-lambda"
  description = "Lambda egress 5432 to RDS Proxy; no ingress from Internet"
  vpc_id      = aws_vpc.this.id

  # No definimos ingress aquí (queda vacío)
  # Egress se añade con aws_security_group_rule para referenciar SG destino

  tags = merge(local.tags, { Name = "${var.name_prefix}-sg-lambda" })
}

# SG para RDS Proxy (ingress 5432 desde Lambdas; egress 5432 hacia DB)
resource "aws_security_group" "sg_rds_proxy" {
  name        = "${var.name_prefix}-sg-rds-proxy"
  description = "RDS Proxy 5432: ingress from Lambda; egress to DB"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name_prefix}-sg-rds-proxy" })
}

# SG para Aurora (DB) (ingress 5432 SOLO desde RDS Proxy; sin egress)
resource "aws_security_group" "sg_db" {
  name        = "${var.name_prefix}-sg-db"
  description = "Aurora ingress 5432 only from RDS Proxy"
  vpc_id      = aws_vpc.this.id

  # No declaramos egress para ser lo más restrictivo posible
  revoke_rules_on_delete = true

  tags = merge(local.tags, { Name = "${var.name_prefix}-sg-db" })
}

# ---------- Reglas explícitas (usar recursos separados) ----------

# Lambda -> Proxy : egress 5432
resource "aws_security_group_rule" "lambda_to_proxy_egress_5432" {
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.sg_lambda.id
  source_security_group_id = aws_security_group.sg_rds_proxy.id  # destino (Terraform usa este campo)
  description              = "Egress 5432 de Lambda hacia RDS Proxy"
}

# Proxy <- Lambda : ingress 5432
resource "aws_security_group_rule" "proxy_from_lambda_ingress_5432" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.sg_rds_proxy.id
  source_security_group_id = aws_security_group.sg_lambda.id
  description              = "Ingress 5432 al RDS Proxy desde Lambdas"
}

# Proxy -> DB : egress 5432
resource "aws_security_group_rule" "proxy_to_db_egress_5432" {
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.sg_rds_proxy.id
  source_security_group_id = aws_security_group.sg_db.id
  description              = "Egress 5432 del RDS Proxy hacia DB"
}

# DB <- Proxy : ingress 5432
resource "aws_security_group_rule" "db_from_proxy_ingress_5432" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.sg_db.id
  source_security_group_id = aws_security_group.sg_rds_proxy.id
  description              = "Ingress 5432 a DB desde RDS Proxy"
}