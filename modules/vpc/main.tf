data "aws_region" "current" {}
locals {
  availability_zones = var.availability_zones
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
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = false
}


resource "aws_subnet" "private_subnets" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index + 10)
  map_public_ip_on_launch = false
}
resource "aws_route_table" "public_rts" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt-${substr(local.availability_zones[count.index], -2, 2)}"
  }
}


resource "aws_route_table" "private_rts" {

  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt-${substr(local.availability_zones[count.index], -2, 2)}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(local.availability_zones)
  route_table_id = aws_route_table.public_rts[count.index].id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}


resource "aws_route_table_association" "private" {
  count          = length(local.availability_zones)
  route_table_id = aws_route_table.private_rts[count.index].id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

resource "aws_route" "internet_access_route" {
  count                  = length(local.availability_zones)
  route_table_id         = aws_route_table.public_rts[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "nat_gateway_route" {
  count                  = var.enable_nat_gateway ? length(local.availability_zones) : 0
  route_table_id         = aws_route_table.private_rts[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats[count.index].id
}

resource "aws_eip" "eips" {
  count  = var.enable_nat_gateway ? length(local.availability_zones) : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "nats" {
  count         = var.enable_nat_gateway ? length(local.availability_zones) : 0
  allocation_id = aws_eip.eips[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "default-sg-disabled"
  }
}

resource "aws_flow_log" "flow_log" {
  vpc_id                   = aws_vpc.main.id
  log_destination_type     = "s3"
  log_destination          = var.flow_log_bucket_arn
  traffic_type             = "ALL"
  max_aggregation_interval = 60
}


resource "aws_default_network_acl" "default_acl" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  tags = {
    Name = "default-nacl"
  }
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public_subnets[*].id
  tags = {
    Name = "public-nacl"
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_subnets[*].id
  tags = {
    Name = "private-nacl"
  }
}

resource "aws_network_acl_rule" "public_tier" {
  for_each       = var.public_nacl_rules
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_number
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port

}

resource "aws_network_acl_rule" "private_tier" {
  for_each       = var.private_nacl_rules
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_number
  egress         = each.value.egress
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port

}
