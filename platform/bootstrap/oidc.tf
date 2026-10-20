# GitHub Actions authenticates through OpenID Connect. No access keys exist
# anywhere (ADR-0003).
#
# Two roles, not one (ADR-0004): pull requests get a read-only role that can
# run `terraform plan`, and only the main branch gets a role that can change
# anything. A pull request from a fork or a compromised workflow cannot reach
# the apply role.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS no longer uses the thumbprint to validate GitHub's OIDC endpoint: it
  # trusts the certificate chain instead, and populates this list itself. Left
  # unmanaged, Terraform would try to delete AWS's value on every single plan.
  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

locals {
  # GitHub's OIDC subject identifies the repository by immutable numeric ids as
  # well as by name:
  #
  #   repo:<owner>@<owner_id>/<repo>@<repo_id>:<context>
  #
  # Every repository created after 15 July 2026 issues tokens in this form, and
  # this one was. Only the immutable form is trusted here. The older name-only
  # spelling is deliberately not accepted as an alternative: a trust policy
  # written against a name would also be satisfied by a different repository
  # that later takes this name, after this one is renamed or deleted. The ids
  # cannot be recycled, so matching on them closes that off.
  #
  # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
  github_owner = split("/", var.github_repository)[0]
  github_repo  = split("/", var.github_repository)[1]

  oidc_repository = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo}@${var.github_repo_id}"

  oidc_subject_pull_request = "${local.oidc_repository}:pull_request"
  oidc_subject_main         = "${local.oidc_repository}:ref:refs/heads/main"
}

# Trust documents: each role trusts exactly one GitHub subject.

data "aws_iam_policy_document" "plan_assume_role" {
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
      values   = [local.oidc_subject_pull_request]
    }
  }
}

data "aws_iam_policy_document" "apply_assume_role" {
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
      values   = [local.oidc_subject_main]
    }
  }
}

# ---------------------------------------------------------------------------
# meridian-ci-plan: pull requests. Reads everything the path touches, writes
# nothing except the state lock file.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ci_plan" {
  name               = "meridian-ci-plan"
  description        = "Pull requests in ${var.github_repository}: terraform plan only"
  assume_role_policy = data.aws_iam_policy_document.plan_assume_role.json
}

data "aws_iam_policy_document" "ci_plan_permissions" {
  # Read the state, and nothing else in the bucket.
  statement {
    sid       = "ReadTerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "ReadStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  # Native S3 locking: plan takes the lock, so it must write and remove the
  # lock file -- but only the lock file, never the state itself.
  statement {
    sid    = "StateLockFileOnly"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.state.arn}/*.tflock"]
  }

  # Read-only on the services the path reads during a plan.
  statement {
    sid    = "DescribeResources"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource",
      "ec2:Describe*",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetResourcePolicy",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Key metadata only: no Encrypt, Decrypt or CreateGrant.
  statement {
    sid    = "ReadKey"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:ListAliases",
      "kms:GetKeyRotationStatus",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }
}

resource "aws_iam_role_policy" "ci_plan" {
  name   = "compliant-datastore-plan"
  role   = aws_iam_role.ci_plan.id
  policy = data.aws_iam_policy_document.ci_plan_permissions.json
}

# ---------------------------------------------------------------------------
# meridian-ci-apply: the main branch. Creates and destroys datastores.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ci_apply" {
  name               = "meridian-ci-apply"
  description        = "Merges to main in ${var.github_repository}: terraform apply"
  assume_role_policy = data.aws_iam_policy_document.apply_assume_role.json
}

data "aws_iam_policy_document" "ci_apply_permissions" {
  # Terraform state, read and write.
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
  # rds:* is known debt in the sandbox; see ADR-0004. Fenced to one region.
  statement {
    sid       = "Databases"
    effect    = "Allow"
    actions   = ["rds:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # The master password is managed by RDS in Secrets Manager. CI creates and
  # deletes the secret but never reads it: no secretsmanager:GetSecretValue,
  # so no apply log can contain a database password. The developer reads it
  # from Secrets Manager directly.
  statement {
    sid    = "ManagedMasterPassword"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:TagResource",
      "secretsmanager:RotateSecret",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
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
    ]
    resources = [aws_kms_key.datastores.arn]
  }

  # Grants only for AWS services acting on our behalf (RDS encrypting storage),
  # never a grant handed to an arbitrary principal.
  statement {
    sid       = "PlatformKeyGrantsForAWSResources"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = [aws_kms_key.datastores.arn]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid       = "ReadKeyAliases"
    effect    = "Allow"
    actions   = ["kms:ListAliases"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
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

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # Postgres logs exported to CloudWatch. The path owns the log groups, so it
  # must be able to tear them down as well as create them.
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  # No iam:CreateServiceLinkedRole: the bootstrap owns that role
  # (iam-service-linked.tf).
}

resource "aws_iam_role_policy" "ci_apply" {
  name   = "compliant-datastore-apply"
  role   = aws_iam_role.ci_apply.id
  policy = data.aws_iam_policy_document.ci_apply_permissions.json
}
