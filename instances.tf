# ==========================================
# GRUPOS DE SEGURIDAD (SECURITY GROUPS)
# ==========================================

# SG para el ALB
resource "aws_security_group" "alb" {
  name        = "group-alb-${local.suffix}"
  description = "Permite trafico HTTPS publico"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para las Instancias EC2 (Solo aceptan tráfico desde el ALB)
resource "aws_security_group" "ec2" {
  name        = "group-ec2-${local.suffix}"
  description = "Permite trafico solo desde el ALB"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para las Bases de Datos (Solo aceptan tráfico desde las EC2)
resource "aws_security_group" "rds" {
  name        = "group-rds-${local.suffix}"
  description = "Permite acceso a BD desde las EC2"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port       = 5432 # PostgreSQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
}

# SG para Redis (Solo acepta tráfico desde las EC2)
resource "aws_security_group" "redis" {
  name        = "group-redis-${local.suffix}"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
}

# SG para VPC Secundaria (Permite tráfico de datos desde la VPC Principal)
resource "aws_security_group" "sec_rds" {
  name        = "group-sec-rds-${local.suffix}"
  description = "Permite trafico de datos desde la VPC Principal"
  vpc_id      = aws_vpc.secundaria.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.principal.cidr_block]
  }
}

# ==========================================
# BALANCEADOR DE CARGA (ALB)
# ==========================================
resource "aws_lb" "alb" {
  name               = "alb-${var.proyecto}-${var.operacion}-01" # Máx 32 caracteres
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]
  
  enable_deletion_protection = false
  tags                       = { Name = "alb-${local.suffix}" }
}

# Target Group de ejemplo para enrutar tráfico
resource "aws_lb_target_group" "tg" {
  name     = "tg-apps-${var.proyecto}-${var.operacion}-01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.principal.id
}

# Certificado SSL Falso/Mock para cumplir con el requerimiento de ACM sin dominio real
resource "aws_acm_certificate" "cert" {
  domain_name       = "casino.promarketing.cl"
  validation_method = "DNS"
  tags              = { Name = "acm-${local.suffix}" }
  lifecycle { create_before_destroy = true }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ==========================================
# SERVIDORES DE APLICACIÓN (EC2)
# ==========================================
# Usamos una AMI genérica de Amazon Linux 2023 para ca-central-1
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"]
  }
}

# Lista de microservicios solicitados
variable "microservicios" {
  type    = list(string)
  default = ["frontsite", "backoffice", "webapi", "gameapi"]
}

resource "aws_instance" "apps" {
  count                  = length(var.microservicios)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t4g.medium"
  # Distribuye balanceadamente entre la subred privada A y B
  subnet_id              = count.index % 2 == 0 ? aws_subnet.priv_app_a.id : aws_subnet.priv_app_b.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  tags = {
    Name = "${var.microservicios[count.index]}-${local.suffix}"
  }
}

# ==========================================
# BASES DE DATOS (RDS)
# ==========================================

# Subnet Group Principal
resource "aws_db_subnet_group" "principal" {
  name       = "dbsng-principal-${local.suffix}"
  subnet_ids = [aws_subnet.priv_data_a.id, aws_subnet.priv_data_b.id]
}

# RDS Principal (Transaccional - Multi-AZ)
resource "aws_db_instance" "transaccional" {
  identifier             = "rds-tx-${local.suffix}"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t4g.medium"
  username               = "dbadmin"
  password               = "SuperSecurePassword123!" # Nota: En prod usar Secrets Manager
  db_subnet_group_name   = aws_db_subnet_group.principal.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = true
  skip_final_snapshot    = true
}

# Subnet Group Secundaria
resource "aws_db_subnet_group" "secundaria" {
  name       = "dbsng-secundario-${local.suffix}"
  subnet_ids = [aws_subnet.sec_data_a.id, aws_subnet.sec_data_b.id]
}

# RDS Histórico (Bodega de datos en VPC Secundaria)
resource "aws_db_instance" "historico" {
  identifier             = "rds-hist-${local.suffix}"
  allocated_storage      = 50
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t4g.medium"
  username               = "dbadmin"
  password               = "AnotherSecurePassword123!"
  db_subnet_group_name   = aws_db_subnet_group.secundaria.name
  vpc_security_group_ids = [aws_security_group.sec_rds.id]
  multi_az               = false
  skip_final_snapshot    = true
}

# ==========================================
# MEMORIA CACHÉ (REDIS)
# ==========================================
resource "aws_elasticache_subnet_group" "redis" {
  name       = "cache-sng-${var.proyecto}-${var.operacion}"
  subnet_ids = [aws_subnet.priv_data_a.id, aws_subnet.priv_data_b.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id        = "redis-${var.proyecto}-${var.operacion}"
  description                 = "Cluster de Redis para Cache de Casino"
  node_type                   = "cache.t4g.medium"
  num_cache_clusters          = 2 # Alta Disponibilidad (Primario + Réplica)
  parameter_group_name        = "default.redis7"
  port                        = 6379
  subnet_group_name           = aws_elasticache_subnet_group.redis.name
  security_group_ids          = [aws_security_group.redis.id]
  automatic_failover_enabled  = true
}