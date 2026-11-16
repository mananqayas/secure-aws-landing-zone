data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.name
  }
  enable_dns_support   = true
  enable_dns_hostnames = true
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}


resource "aws_subnet" "private_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
resource "aws_route_table" "public_rts" {
  count  = 3
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt-${substr(data.aws_availability_zones.available.names[count.index], -2, 2)}"
  }
}


resource "aws_route_table" "private_rts" {
  count  = 3
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt-${substr(data.aws_availability_zones.available.names[count.index], -2, 2)}"
  }
}

resource "aws_route_table_association" "public" {
  count = 3
  route_table_id = aws_route_table.public_rts[count.index]
  subnet_id = aws_subnet.public_subnets[count.index]
}


resource "aws_route_table_association" "private" {
  count = 3
  route_table_id = aws_route_table.private_rts[count.index]
  subnet_id = aws_subnet.private_subnets[count.index]
}
