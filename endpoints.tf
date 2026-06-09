# Endpoint tipo Gateway para Amazon S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.principal.id
  service_name      = "com.amazonaws.ca-central-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "vpce-s3-${local.suffix}" }
}

# Endpoint tipo Interface para AWS Secrets Manager
resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = aws_vpc.principal.id
  service_name        = "com.amazonaws.ca-central-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.priv_app_a.id, aws_subnet.priv_app_b.id]
  security_group_ids  = [aws_security_group.vpce_interface.id]
  tags                = { Name = "vpce-secrets-${local.suffix}" }
}

# SG específico para Interfaces de Endpoints (Puerto 443 desde la VPC interna)
resource "aws_security_group" "vpce_interface" {
  name        = "group-vpce-interface-${local.suffix}"
  description = "Seguridad interna para endpoints tipo interface"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.principal.cidr_block]
  }
}