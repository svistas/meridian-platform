terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in the bootstrap's bucket, with native S3 locking so there is
  # no DynamoDB table. The bucket name is account-specific, so it is passed at
  # init time rather than written down here:
  #
  #   terraform init \
  #     -backend-config="bucket=$(terraform -chdir=../../../platform/bootstrap output -raw state_bucket_name)"
  backend "s3" {
    key          = "paths/compliant-datastore/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}
