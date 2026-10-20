# Bootstrap

One-time setup for the sandbox account, applied **locally by a human** (ADR-0003).
A coding agent writes this and runs `plan`; it does not hold credentials to apply it.

What it creates:

| Resource | Why |
|---|---|
| S3 bucket `meridian-platform-tfstate-<account>` | Terraform state for every later phase. Versioned and encrypted |
| GitHub OIDC provider + roles `meridian-ci-plan` / `meridian-ci-apply` | CI authenticates without access keys. Pull requests get the read-only plan role; only `main` gets the apply role (ADR-0004) |
| RDS service-linked role | So the apply role never needs `iam:CreateServiceLinkedRole` |
| KMS key, alias `meridian-datastores` | Every datastore is encrypted with it, rotation on |
| VPC with two private subnets + DB subnet group | Databases are never reachable from the internet. No NAT gateway |
| Budget, USD 20/month | Exists before the first database (ADR-0003) |

## Running it

Requires Terraform >= 1.11 (see `.tool-versions` at the repository root).

### The first time, in an account with no state bucket

`versions.tf` configures an S3 backend pointing at a bucket **this
configuration creates**. On a first run that bucket does not exist yet, so
`terraform init` cannot succeed against it. Apply once with local state, then
migrate:

```sh
export AWS_PROFILE=meridian-sandbox

# 1. Apply with local state. The backend block is temporarily out of the way.
mv versions.tf versions.tf.disabled
printf 'terraform {\n  required_version = ">= 1.11"\n  required_providers {\n    aws = { source = "hashicorp/aws", version = "~> 6.0" }\n  }\n}\n\nprovider "aws" {\n  region = var.region\n  default_tags { tags = { managed-by = "meridian-platform", path = "bootstrap" } }\n}\n' > versions.tf
terraform init
terraform plan          # read it
terraform apply

# 2. Put the real file back and migrate the state into the bucket it created.
mv -f versions.tf.disabled versions.tf
terraform init -migrate-state \
  -backend-config="bucket=$(terraform output -raw state_bucket_name)"
```

Terraform asks for confirmation before copying the local state; answer `yes`.
Afterwards `terraform.tfstate` on disk is a leftover and can be deleted.

### Every time after that

```sh
export AWS_PROFILE=meridian-sandbox
terraform init -backend-config="bucket=meridian-platform-tfstate-<account-id>"
terraform plan
terraform apply
```

## State

State lives in the bucket this configuration creates, under
`platform/bootstrap/terraform.tfstate`, with native S3 locking
(`use_lockfile`), so there is no DynamoDB table. The bucket name is
account-specific and is passed with `-backend-config` rather than written into
the repository.

The one-time migration above is the price of the bootstrap creating its own
backend. After it, the bootstrap and the path keep state in the same bucket
under different keys, and nothing depends on a state file on one person's
laptop.

## After applying

Set both role ARNs as repository variables so the phase 4 workflows can use
them:

```sh
gh variable set AWS_PLAN_ROLE_ARN  --body "$(terraform output -raw ci_plan_role_arn)"
gh variable set AWS_APPLY_ROLE_ARN --body "$(terraform output -raw ci_apply_role_arn)"
```

The phase 4 workflows read the Terraform version from `.tool-versions` at the
repository root rather than pinning it again in the workflow files.
