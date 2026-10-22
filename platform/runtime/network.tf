# The egress half of the network, which the bootstrap deliberately left out.
#
# The bootstrap's VPC has two private subnets and no way out: no internet
# gateway, no NAT. That is right for path 01, where a database should never
# reach the internet, and it keeps the standing bill at zero. Nodes, though,
# have to pull images and talk to the EKS API, so a session adds the egress
# path and takes it away again.
#
# Everything in this file is billed by the hour or carries an hourly public
# IPv4 charge, which is why it lives in the session stack and not the
# bootstrap.

data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

resource "aws_internet_gateway" "session" {
  vpc_id = var.vpc_id

  tags = {
    Name = "meridian-session"
  }
}

# One public subnet, holding only the NAT gateway. Nothing else is placed here:
# the services themselves stay in the private subnets.
resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_subnet.private[var.private_subnet_ids[0]].availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name                     = "meridian-session-public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.session.id
  }

  tags = {
    Name = "meridian-session-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "meridian-session-nat"
  }
}

# A single NAT gateway, not one per availability zone. One is a single point of
# failure and the textbook answer is one per AZ; in a sandbox that is paying
# USD 0.048 an hour twice over for a cluster that is deleted at the end of the
# day.
resource "aws_nat_gateway" "session" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "meridian-session"
  }

  depends_on = [aws_internet_gateway.session]
}

# The private subnets belong to the bootstrap, but their route out belongs to
# the session: this route table is associated while a session is up and
# released when it ends, after which the subnets fall back to the VPC's main
# route table and have no path to the internet again.
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.session.id
  }

  tags = {
    Name = "meridian-session-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each = toset(var.private_subnet_ids)

  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}
