terraform {
  # >= 1.10 because the path's Terraform (phase 2 onwards) uses native S3 state
  # locking (`use_lockfile`), which was introduced in 1.10. The bootstrap itself
  # keeps local state: it creates the bucket that everything else stores state in.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
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
