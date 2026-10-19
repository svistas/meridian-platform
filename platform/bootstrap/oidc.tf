# GitHub Actions authenticates through OpenID Connect. No access keys exist
# anywhere (ADR-0003).

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
}

# Who may assume the role: only this repository, and only from the main branch
# or from a pull request. Nothing else in GitHub can reach this account.
data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:ref:refs/heads/main",
        "repo:${var.github_repository}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "meridian-platform-ci"
  description        = "Assumed by GitHub Actions in ${var.github_repository} to run the compliant-datastore path"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json
}

# What the role may do. Scoped to the services path 01 needs, and to this
# path's own resources where a resource ARN can express that.
data "aws_iam_policy_document" "ci_permissions" {
  # Terraform state.
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
  }

  # Databases, their parameter groups and subnet groups.
  statement {
    sid       = "Databases"
    effect    = "Allow"
    actions   = ["rds:*"]
    resources = ["*"]
  }

  # The master password is managed by RDS in Secrets Manager.
  statement {
    sid    = "ManagedMasterPassword"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:TagResource",
      "secretsmanager:RotateSecret",
    ]
    resources = ["*"]
  }

  # Encryption with the platform key only.
  statement {
    sid    = "PlatformKey"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
    ]
    resources = [aws_kms_key.datastores.arn]
  }

  statement {
    sid       = "ReadKeyAliases"
    effect    = "Allow"
    actions   = ["kms:ListAliases"]
    resources = ["*"]
  }

  # Reading the network, and managing the security groups a datastore needs.
  statement {
    sid    = "Network"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]
  }

  # Postgres logs exported to CloudWatch.
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
    ]
    resources = ["*"]
  }

  # RDS needs its service-linked role to exist.
  statement {
    sid       = "ServiceLinkedRole"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ci" {
  name   = "compliant-datastore"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_permissions.json
}
