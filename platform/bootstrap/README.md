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

Set both role ARNs as repository variables so the phase 4 workflows can use
them:

```sh
gh variable set AWS_PLAN_ROLE_ARN  --body "$(terraform output -raw ci_plan_role_arn)"
gh variable set AWS_APPLY_ROLE_ARN --body "$(terraform output -raw ci_apply_role_arn)"
```

The phase 4 workflows read the Terraform version from `.tool-versions` at the
repository root rather than pinning it again in the workflow files.
