terraform {
  # Matches the path's Terraform: native S3 state locking (`use_lockfile`).
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in the bucket this configuration creates, which is a
  # chicken-and-egg: the very first apply runs with local state, and the state
  # is then migrated once. See README.md, "State".
  backend "s3" {
    key          = "platform/bootstrap/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed-by = "meridian-platform"
      path       = "bootstrap"
    }
  }
}
