# ==========================================
# VPC PRINCIPAL (Aplicaciones y Tráfico Público)
# ==========================================
resource "aws_vpc" "principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-principal-${local.suffix}" }
}

# Subredes Públicas (Para ALB y NAT Gateways)
resource "aws_subnet" "pub_a" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "subnet-pub-a-${local.suffix}" }
}

resource "aws_subnet" "pub_b" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "subnet-pub-b-${local.suffix}" }
}

# Subredes Privadas para Aplicaciones (EC2)
resource "aws_subnet" "priv_app_a" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "subnet-priv-app-a-${local.suffix}" }
}

resource "aws_subnet" "priv_app_b" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "subnet-priv-app-b-${local.suffix}" }
}

# Subredes Privadas para Datos (RDS Transaccional y Redis)
resource "aws_subnet" "priv_data_a" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "subnet-priv-data-a-${local.suffix}" }
}

resource "aws_subnet" "priv_data_b" {
  vpc_id            = aws_vpc.principal.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "subnet-priv-data-b-${local.suffix}" }
}

# ==========================================
# VPC SECUNDARIA (Bodega de Datos / Histórica)
# ==========================================
resource "aws_vpc" "secundaria" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "vpc-secundaria-${local.suffix}" }
}

resource "aws_subnet" "sec_data_a" {
  vpc_id            = aws_vpc.secundaria.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "subnet-sec-data-a-${local.suffix}" }
}

resource "aws_subnet" "sec_data_b" {
  vpc_id            = aws_vpc.secundaria.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "subnet-sec-data-b-${local.suffix}" }
}

# ==========================================
# CONECTIVIDAD: VPC PEERING
# ==========================================
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.principal.id
  peer_vpc_id   = aws_vpc.secundaria.id
  auto_accept   = true
  tags          = { Name = "peering-${local.suffix}" }
}

# ==========================================
# GATEWAYS E INTERNET (VPC Principal)
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.principal.id
  tags   = { Name = "igw-${local.suffix}" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "eip-nat-${local.suffix}" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_a.id
  tags          = { Name = "nat-${local.suffix}" }
}

# ==========================================
# TABLAS DE RUTEO Y ENLACES
# ==========================================

# Ruteo Público (VPC Principal)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-public-${local.suffix}" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.public.id
}

# Ruteo Privado (VPC Principal -> Apps y Datos internos)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.principal.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  route {
    cidr_block                = aws_vpc.secundaria.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
  tags = { Name = "rt-private-${local.suffix}" }
}

resource "aws_route_table_association" "priv_app_a" {
  subnet_id      = aws_subnet.priv_app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv_app_b" {
  subnet_id      = aws_subnet.priv_app_b.id
  route_table_id = aws_route_table.private.id
}

# Ruteo VPC Secundaria (Hacia la VPC Principal vía Peering)
resource "aws_route_table" "secundaria" {
  vpc_id = aws_vpc.secundaria.id
  route {
    cidr_block                = aws_vpc.principal.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
  tags = { Name = "rt-secundaria-${local.suffix}" }
}

resource "aws_route_table_association" "sec_a" {
  subnet_id      = aws_subnet.sec_data_a.id
  route_table_id = aws_route_table.secundaria.id
}

resource "aws_route_table_association" "sec_b" {
  subnet_id      = aws_subnet.sec_data_b.id
  route_table_id = aws_route_table.secundaria.id
}
