# Minimal network for the sandbox.
#
# Private subnets only: no internet gateway and no NAT gateway. Databases are
# never reachable from the internet, and a NAT gateway would cost more than the
# databases it serves. Two subnets in different availability zones because RDS
# requires a DB subnet group spanning at least two AZs, even for a single-AZ
# instance.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "meridian-sandbox"
  }
}

resource "aws_subnet" "private" {
  for_each = {
    a = { cidr = "10.20.1.0/24", az = data.aws_availability_zones.available.names[0] }
    b = { cidr = "10.20.2.0/24", az = data.aws_availability_zones.available.names[1] }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "meridian-sandbox-private-${each.key}"
  }
}

resource "aws_db_subnet_group" "datastores" {
  name        = "meridian-datastores"
  description = "Private subnets for datastores created by path 01"
  subnet_ids  = [for s in aws_subnet.private : s.id]
}
