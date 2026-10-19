# Terraform state bucket.
#
# This bucket is where every later phase keeps its state. Locking is native S3
# locking (a .tflock object next to the state file), so there is deliberately no
# DynamoDB table here.
#
# The bootstrap itself cannot store its state in this bucket -- it is the thing
# that creates it -- so the bootstrap keeps local state. See README.md.

data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "meridian-platform-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
