---
status: accepted
date: 2026-10-19
decision-makers: Sofia Vistas
---

# Separate plan and apply roles for CI

## Context and Problem Statement

Path 01 runs Terraform from GitHub Actions in two situations: on a pull request, to show the author what their request file would create, and on a merge to `main`, to create it. [ADR-0003](0003-mvp-runs-in-an-aws-sandbox-account.md) settled that CI authenticates through OpenID Connect with no stored credentials, but not how much the federated identity may do. The bootstrap's first draft used one role for both. A pull request is untrusted input: anyone who can open one, and any dependency a workflow pulls in, runs code in that context. Should planning and applying share an identity?

## Decision Drivers

* A pull request must not be able to change anything in the account.
* `terraform plan` genuinely needs credentials: it reads state and the real resources.
* Native S3 locking means a plan writes a lock file, so "read-only" is not literally read-only.
* The MVP is throwaway, but credential blast radius is not a lesson worth re-learning in production.

## Considered Options

* One role for both plan and apply, trusted for `main` and pull requests
* Two roles: a read-only plan role for pull requests, an apply role for `main`
* One role, with a branch condition checked inside the workflow

## Decision Outcome

Chosen option: "Two roles", because the GitHub subject claim already distinguishes a pull request from `main`, so the separation costs one extra role and removes write access from the untrusted path entirely.

* `meridian-ci-plan` trusts only `repo:svistas/meridian-platform:pull_request`. It can describe RDS, EC2, KMS, Secrets Manager and CloudWatch Logs, read the state bucket, and write and delete the state lock file — nothing else.
* `meridian-ci-apply` trusts only `repo:svistas/meridian-platform:ref:refs/heads/main`. It can create and destroy datastores.

Both are fenced to `eu-west-1` with an `aws:RequestedRegion` condition, and `kms:CreateGrant` is allowed only when `kms:GrantIsForAWSResource` is true, so a grant can be issued to RDS encrypting its storage but not handed to an arbitrary principal.

### Consequences

* Good, because a malicious or mistaken pull request cannot create, modify or destroy anything.
* Good, because the plan role cannot read secret values, so a plan log cannot leak a database password.
* Good, because the region condition bounds the damage of any over-broad action to the sandbox's one region.
* Bad, because there are two ARNs to configure in the workflows instead of one.
* Bad, because **`rds:*` in the sandbox is known debt, tightened in Production Readiness.** Enumerating RDS actions now would likely fail an apply mid-run on a missing permission, and the MVP's own code is throwaway; the region fence and the role split bound the risk until a Security-owned policy layer replaces this.
* Neutral, because the plan role still holds real credentials: read access to a sandbox with no real data.

### Update, 2026-10-20: trust the immutable subject

The first real CI run failed at the OIDC step with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. CloudTrail showed why: the token GitHub issued carried the subject

```
repo:svistas@150247420/meridian-platform@1422352369:pull_request
```

while the trust policy expected `repo:svistas/meridian-platform:pull_request`. GitHub now identifies the repository in the subject by immutable numeric ids as well as by name, for every repository created after 15 July 2026. Both roles' conditions were rewritten against the id-bearing form, with the ids as variables.

The name-only spelling was **not** kept as an accepted alternative. Accepting it would mean the trust policy is also satisfied by any future repository that takes the name `svistas/meridian-platform` — after this one is renamed, transferred or deleted. Repository names are recyclable; the ids are not. Trusting only the immutable form removes that path entirely, at the cost of the policy needing an update if the repository is ever recreated from scratch, which is the right trade for a policy that grants write access to an AWS account.

This is also a note about method: no amount of reading the YAML, pinning actions or unit testing would have found this. It took one real run.

### Confirmation

The phase 4 workflows reference the two roles by separate repository variables. A pull request that tries to apply fails at the AWS API, not at a check inside the workflow.

## Pros and Cons of the Options

### One role for both

* Good, because it is the smallest amount of configuration.
* Bad, because a pull request runs with permission to destroy every database in the account.

### Two roles

* Good, because the trust boundary is enforced by AWS, from a claim GitHub signs.
* Good, because each policy can be read and reviewed for one purpose.
* Neutral, because it needs two repository variables.

### One role, branch checked in the workflow

* Good, because it needs no extra AWS resources.
* Bad, because the check lives in the same file an attacker is editing in their pull request.
