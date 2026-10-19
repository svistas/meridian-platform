# Bootstrap

One-time setup for the sandbox account, applied **locally by a human** (ADR-0003).
A coding agent writes this and runs `plan`; it does not hold credentials to apply it.

What it creates:

| Resource | Why |
|---|---|
| S3 bucket `meridian-platform-tfstate-<account>` | Terraform state for every later phase. Versioned and encrypted |
| GitHub OIDC provider + role `meridian-platform-ci` | CI authenticates without access keys; only this repo's `main` and pull requests may assume it |
| KMS key, alias `meridian-datastores` | Every datastore is encrypted with it, rotation on |
| VPC with two private subnets + DB subnet group | Databases are never reachable from the internet. No NAT gateway |
| Budget, USD 20/month | Exists before the first database (ADR-0003) |

## Running it

```sh
export AWS_PROFILE=meridian-sandbox
terraform init
terraform plan      # read it
terraform apply
```

Requires Terraform >= 1.10 (see `.tool-versions` at the repository root).

## State

This directory keeps **local** state: it creates the bucket everything else
stores state in, so it cannot store its own state there. `terraform.tfstate`
stays on the machine that applied it and is gitignored. Later phases use the
bucket with native S3 locking (`use_lockfile`), so there is no DynamoDB table.

## After applying

Set the `ci_role_arn` output as a repository variable so the phase 4 workflows
can use it:

```sh
gh variable set AWS_ROLE_ARN --body "$(terraform output -raw ci_role_arn)"
```
