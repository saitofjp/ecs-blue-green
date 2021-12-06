variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = object({
    public_a  = string
    public_c  = string
    private_a = string
    private_c = string
  })

  default = {
    public_a  = ""
    public_c  = ""
    private_a = ""
    private_c = ""
  }
}

locals {
  az = {
    a = "${data.aws_region.current.name}a"
    c = "${data.aws_region.current.name}c"
    d = "${data.aws_region.current.name}d"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr.public_a
  availability_zone       = local.az.a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-subnet-public-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr.public_c
  availability_zone       = local.az.c
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-subnet-public-c"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr.private_a
  availability_zone = local.az.a

  tags = {
    Name = "${var.project}-subnet-private-a"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr.private_c
  availability_zone = local.az.c

  tags = {
    Name = "${var.project}-subnet-private-c"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-route-table-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-route-table-private"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}
