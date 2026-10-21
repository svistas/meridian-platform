# Workflows for path 01

| Workflow | Trigger | AWS role | What it does |
|---|---|---|---|
| `datastore-plan.yml` | every `pull_request` | `meridian-ci-plan` (read-only) | Validates requests, runs the unit tests, `terraform plan`, comments on the PR, labels judgment cases |
| `datastore-apply.yml` | `push` to `main` touching the path | `meridian-ci-apply` | Applies, verifies every guarantee row, publishes the inventory |
| `datastore-teardown.yml` | `workflow_dispatch`, input `destroy` | `meridian-ci-apply` | Destroys every datastore in the path |

No workflow uses `pull_request_target`, no workflow stores an AWS key, and
every third-party action is pinned to a full commit SHA.

## Why the plan workflow has no paths filter

It runs on every pull request and decides for itself whether anything relevant
changed, by diffing against the base branch.

A `paths:` filter looks equivalent and is not. A filtered-out workflow does not
run, which means it never reports a check — so a pull request touching nothing
in the path would wait forever on a required check that is never coming. Making
the workflow always run and exit early keeps the check reporting on every pull
request, which is what a branch protection rule needs.

When nothing relevant changed the job succeeds immediately, posts no comment
and touches no labels; the run summary says why. "Relevant" means
`paths/compliant-datastore/**`, `.github/workflows/datastore-plan.yml`, or
`.tool-versions`.

## Keeping the action pins current

`.github/dependabot.yml` checks weekly and opens a single grouped pull request
for all of them. Pinning to a SHA means a pin never moves on its own,
including past a security fix, so something has to move it deliberately.

## How the judgment-case label is decided

`datastore-plan.yml` runs `validate_requests.py` twice: once for people and
once with `--json`. The label is added or removed on `flags.length > 0` from
the JSON, never on the prose.

This matters because the clean message is *"All requests valid, no judgment
cases."* — which contains the substring `judgment case`. The first version of
the workflow tested for that substring and labelled every clean pull request.
`TestWorkflowLabelDecision` in `scripts/test_validate_requests.py` pins both
halves: that the rule gives the right answer, and that the human-readable text
is genuinely unsafe to branch on.

When a push removes the last judgment case, the workflow takes the label off
again, ignoring a 404 if it was never there.

## Repository variables to create

These are **variables, not secrets**: a role ARN, a bucket name and a few
resource ids are not confidential, and variables stay readable in run logs
where a secret would be masked and far harder to debug.

Fill them from the bootstrap's outputs after it has been applied:

```sh
cd platform/bootstrap
export AWS_PROFILE=meridian-sandbox

gh variable set AWS_REGION                      --body "eu-west-1"
gh variable set AWS_PLAN_ROLE_ARN               --body "$(terraform output -raw ci_plan_role_arn)"
gh variable set AWS_APPLY_ROLE_ARN              --body "$(terraform output -raw ci_apply_role_arn)"
gh variable set TF_STATE_BUCKET                 --body "$(terraform output -raw state_bucket_name)"
gh variable set DATASTORE_KMS_KEY_ARN           --body "$(terraform output -raw kms_key_arn)"
gh variable set DATASTORE_DB_SUBNET_GROUP_NAME  --body "$(terraform output -raw db_subnet_group_name)"
gh variable set DATASTORE_VPC_ID                --body "$(terraform output -raw vpc_id)"
```

Check them with `gh variable list`.

| Variable | Bootstrap output | Used by |
|---|---|---|
| `AWS_REGION` | — (`eu-west-1`, ADR-0003) | all three |
| `AWS_PLAN_ROLE_ARN` | `ci_plan_role_arn` | plan |
| `AWS_APPLY_ROLE_ARN` | `ci_apply_role_arn` | apply, teardown |
| `TF_STATE_BUCKET` | `state_bucket_name` | all three |
| `DATASTORE_KMS_KEY_ARN` | `kms_key_arn` | plan, apply, teardown, verification |
| `DATASTORE_DB_SUBNET_GROUP_NAME` | `db_subnet_group_name` | plan, apply, teardown |
| `DATASTORE_VPC_ID` | `vpc_id` | plan, apply, teardown |

## One label to create

```sh
gh label create needs-security-review \
  --description "A judgment case: Security & Compliance decides" \
  --color D93F0B
```

The plan workflow adds this label itself, but creating it first gives it a
colour and a description.
