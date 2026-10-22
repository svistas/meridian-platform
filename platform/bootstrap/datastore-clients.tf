# Who is allowed to talk to a datastore.
#
# This group has no rules of its own and never will. Its only job is to be a
# name that both paths can point at: path 01 lets its databases accept
# connections from members of this group, and path 02 makes its nodes members.
#
# The alternative -- path 02 editing path 01's security groups when a session
# starts -- works, but it means one path reaching into another path's
# resources, and a failed teardown leaves a rule behind on a database that
# outlives the session. Membership inverts that: the database's rule is
# written once by the path that owns the database, and joining or leaving is
# the client's business.
#
# It lives in the bootstrap because it must outlive both a session and any
# individual datastore.

resource "aws_security_group" "datastore_clients" {
  name        = "meridian-datastore-clients"
  description = "Membership marker: anything in this group may reach a platform datastore. Deliberately has no rules of its own."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "meridian-datastore-clients"
  }

  lifecycle {
    create_before_destroy = true
  }
}
