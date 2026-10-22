terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Same bucket as the bootstrap and path 01, under its own key.
  #
  #   terraform init -backend-config="bucket=<state_bucket_name>"
  backend "s3" {
    key          = "platform/runtime/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      managed-by = "meridian-platform"
      path       = "service-to-environment"
      lifecycle  = "session"
    }
  }
}
