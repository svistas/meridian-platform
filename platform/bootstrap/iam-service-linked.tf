# RDS needs its service-linked role to exist before it can create databases.
# Creating it here means the CI apply role does not need
# iam:CreateServiceLinkedRole.
#
# This account already had the role (created 2024-02-02), so the bootstrap
# adopts it rather than creating a second one. In a fresh account, remove the
# import block below and Terraform will create it.

resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
  description      = "Allows Amazon RDS to manage AWS resources on your behalf"
}

import {
  to = aws_iam_service_linked_role.rds
  id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
}
