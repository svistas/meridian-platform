terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The S3 backend is wired up in phase 4, when CI runs this and the bootstrap
  # bucket exists. Until then this root module keeps local state.
}

provider "aws" {
  region = var.region
}
