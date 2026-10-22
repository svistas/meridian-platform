# Let the cluster reach path 01's databases.
#
# Path 01 gives every datastore a security group with no ingress at all, so
# nothing can connect to it. That is deliberate: path 01 hands you a database,
# and attaching something to it is path 02's job. This is where the two paths
# meet.
#
# The rule is created here, in the session stack, so it disappears with the
# session. Between sessions the databases go back to accepting nothing.

data "aws_security_groups" "datastores" {
  filter {
    name   = "tag:path"
    values = ["compliant-datastore"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_vpc_security_group_ingress_rule" "datastore_from_cluster" {
  for_each = toset(data.aws_security_groups.datastores.ids)

  security_group_id = each.value
  description       = "Postgres from the path 02 session cluster"

  # Source is the cluster security group, which every node and pod uses, not a
  # CIDR: if the node addresses change the rule still means the same thing.
  referenced_security_group_id = aws_eks_cluster.session.vpc_config[0].cluster_security_group_id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  tags = {
    Name = "datastore-from-session-cluster"
  }
}
