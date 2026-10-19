# Path 01 build brief: compliant datastore (MVP, AWS sandbox)

> Lesson 5. The brief a coding agent works from. Design: [01-compliant-datastore-design.md](01-compliant-datastore-design.md), [ADR-0002](../adr/0002-compliant-datastore-path-design.md). Environment: [ADR-0003](../adr/0003-mvp-runs-in-an-aws-sandbox-account.md).

## What we are building

A developer adds a short request file in a pull request. Automated checks validate it and flag judgment cases. On merge, Terraform creates a Postgres database with PHI-grade defaults that can't be switched off, the password is stored as a managed secret, and the datastore inventory is updated. Removing the request file and merging destroys the database.

## MVP rules (from CLAUDE.md, repeated here)

* Non-production: the AWS sandbox account only. Synthetic data only; in practice, no data at all.
* No central policy engine, no identity system, no state system. The safety rules are hard-coded defaults inside this path.
* Don't design for reuse across paths. Keep everything inside `paths/compliant-datastore/`, except the one-time bootstrap.
* The interface is the request file in a pull request (the expert interface). No portal, no CLI.

## Target layout

```text
platform/bootstrap/                  # one-time setup, applied locally by a human
paths/compliant-datastore/
  requests/                          # one YAML file per datastore
  schema/request.schema.json
  terraform/                         # root module: reads requests/*.yaml
    modules/postgres/                # the "recipe" with fixed defaults
  scripts/
    validate_requests.py             # schema + judgment-case flags
    verify_guarantee.py              # checks real AWS resources after apply
    inventory.py                     # builds the inventory
  README.md                          # how a developer uses the path
inventory/datastores.md              # generated
.github/workflows/
  datastore-plan.yml                 # on pull request
  datastore-apply.yml                # on merge to main
  datastore-teardown.yml             # manual: destroy everything
```

## The request file (the input contract)

```yaml
service: appointment-reminders       # lowercase, hyphens; unique
team: appointments
cost_center: patient-app
environment: sandbox                 # only value allowed in the MVP
engine: postgres                     # only value allowed in the MVP
size: small                          # small | medium
classification: phi                  # phi | non-phi | unsure
data_leaves_meridian: "no"           # "no", or a destination such as "sms-vendor"
```

All fields are required. The request **cannot** set encryption, backups, network exposure, logging or tags. Those belong to the path.

## The output guarantee (what verification checks)

For every request, after apply, `verify_guarantee.py` confirms through the AWS API:

| Property | Required value |
|---|---|
| Storage encrypted | yes, with the platform's customer-managed KMS key |
| Publicly accessible | no; in private subnets only |
| Backup retention | 35 days |
| TLS | enforced (`rds.force_ssl = 1` in the parameter group) |
| Logs | Postgres logs exported to CloudWatch |
| Master password | managed by RDS in Secrets Manager (never in Terraform state or outputs) |
| Tags | `service`, `team`, `cost-center`, `classification`, `managed-by = meridian-platform`, `path = compliant-datastore` |

Size mapping: `small` → `db.t4g.micro`, 20 GB; `medium` → `db.t4g.small`, 50 GB. No Multi-AZ. In the sandbox only: no deletion protection, skip the final snapshot.

## Judgment cases

`validate_requests.py` flags a request when `classification` is `unsure` or `data_leaves_meridian` is not `"no"`. The pull request gets the label `needs-security-review` and a comment explaining why. In the MVP sandbox, the merge is still allowed; the flag is what we're testing.

## Phases (one commit each; stop after each phase for review)

**Phase 1: Bootstrap** (`platform/bootstrap/`). Terraform for: a versioned, encrypted S3 bucket for Terraform state with native S3 locking; the GitHub OIDC identity provider and an IAM role that only this repository's `main` branch and pull requests can assume; one customer-managed KMS key (alias `meridian-datastores`) with rotation on; a minimal VPC with two private subnets in different availability zones and no NAT gateway; a DB subnet group; an AWS Budget at USD 20 with an email alert. Output the role ARN and the bucket name. **A human runs `terraform apply` for this phase locally**, after reading the plan.

**Phase 2: The recipe** (`terraform/` and `modules/postgres/`). The root module reads every `requests/*.yaml` with `fileset` and `yamldecode`, and creates one module instance per request with `for_each`. The module hard-codes every property in the guarantee table. Use `manage_master_user_password = true`. Add one example request: `appointment-reminders.yaml` (the example above). Show `terraform plan` output; don't apply.

**Phase 3: Validation** (`schema/`, `validate_requests.py`). A JSON Schema for the request file and a script that validates every request, checks service names are unique, and prints judgment-case flags. Include unit tests with valid and invalid example requests.

**Phase 4: Workflows.** `datastore-plan.yml` on pull requests touching the path: validate, `terraform fmt -check`, `terraform validate`, `terraform plan`, post the plan summary and any judgment-case flags as a PR comment, and add the label. `datastore-apply.yml` on merge to `main`: apply, then run verification, then regenerate the inventory and commit it with `[skip ci]`. `datastore-teardown.yml`: manual trigger, destroys all datastores. Authenticate with OIDC only (`aws-actions/configure-aws-credentials` with the role ARN from a repository variable). Pin action versions.

**Phase 5: Verification and inventory.** `verify_guarantee.py` checks every row of the guarantee table for every request and exits non-zero on any failure. `inventory.py` writes `inventory/datastores.md`: one row per datastore with service, team, classification, judgment-case flag, requested by (author of the commit that added the request file) and date, using git history.

**Phase 6: Developer README.** `paths/compliant-datastore/README.md`, written for the Appointments engineer: how to request a datastore in under five minutes, what you get, what you can't change and why, how to find your secret, and how to remove the datastore.

## Out of scope for this path's MVP

Redis, queues, buckets; production; connecting a running service (path 02 does that); a portal or CLI; a policy engine; database users beyond the master user.

## Definition of done for the MVP build

* Merging the example request creates a database, and verification passes every row.
* A request marked `unsure` gets the label and comment.
* Removing the request and merging destroys the database.
* The inventory shows the datastore with its classification.
* Time from opening the pull request to a verified database is recorded for the validation interview (Lesson 6).
