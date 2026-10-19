# RDS needs its service-linked role to exist before it can create databases.
# Creating it here means the CI apply role does not need
# iam:CreateServiceLinkedRole.

resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
  description      = "Allows Amazon RDS to manage AWS resources on your behalf"
}
