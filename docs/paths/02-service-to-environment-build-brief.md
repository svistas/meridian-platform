# Path 02 build brief: service to environment (MVP, EKS sessions)

> Lesson 8. Design: [02-service-to-environment-design.md](02-service-to-environment-design.md), [ADR-0005](../adr/0005-service-to-environment-path-design.md). Runtime: [ADR-0006](../adr/0006-path-02-runs-on-ephemeral-eks-sessions.md).

## What we are building

A developer adds a short service file in a pull request. Checks validate it, and check the service's Dockerfile and health endpoint before anything runs. On merge, the platform builds the image, pushes it to Meridian's registry, and deploys it to the EKS session cluster with its own identity and the runtime rules built in. If the service names a path 01 datastore, it connects to it through the managed secret. Verification checks the running service against the guarantee, and the service inventory is updated.

## MVP rules (same as path 01)

* Sandbox only; synthetic data only.
* No central policy engine, no identity or state system. Rules are defaults in the path, plus the cluster's restricted Pod Security standard.
* Don't design for reuse beyond what path 02 needs. Path 01 stays untouched except where noted.
* Expert interface: a file in a pull request.

## Target layout

```text
platform/runtime/                    # session stack, applied locally by a human
services/appointment-reminders/      # sample service (portfolio simplification)
paths/service-to-environment/
  requests/                          # one YAML file per service
  schema/request.schema.json
  chart/                             # platform-owned Helm chart: the recipe
  terraform/                         # per-service persistent resources
  scripts/
    validate_requests.py             # request + Dockerfile + health checks
    verify_guarantee.py              # checks the running service
    inventory.py
  README.md
.github/workflows/
  service-plan.yml                   # on pull request
  service-build-deploy.yml           # on merge to main
```

## The request file

```yaml
service: appointment-reminders
team: appointments
source: services/appointment-reminders   # folder with a Dockerfile
port: 8080
health_path: /healthz
size: small                               # small | medium
datastore: appointment-reminders          # optional: a path 01 datastore
exposure: internal                        # internal | public (public is a judgment case)
```

The request cannot set identity, user, privileges, resources beyond the size mapping, image registry, or network policy.

## The output guarantee (what verification checks)

| Property | Required value |
|---|---|
| Running | Deployment available; all replicas ready; health check passing |
| Own identity | A dedicated IAM role via an EKS Pod Identity association; no shared credentials |
| Least privilege | That role can read only its own datastore's secret (if any), nothing else |
| Non-root | `runAsNonRoot: true`, no privilege escalation, read-only root filesystem, all capabilities dropped |
| Resource limits | Set from size: `small` = 0.25 vCPU / 512 Mi, `medium` = 0.5 vCPU / 1 Gi |
| Image source | Only from the service's ECR repository in the sandbox account |
| Exposure | `internal`: a ClusterIP service only, no load balancer. `public` is flagged and not built in the MVP |
| Namespace | One per service, labelled with the restricted Pod Security standard |
| Logs | Container logs collected to CloudWatch |
| Datastore connection | If named: the service reaches its path 01 database over TLS |
| Tags and labels | `service`, `team`, `managed-by = meridian-platform`, `path = service-to-environment` |

## Phases (one commit each; stop after each phase for review)

**Phase 1: Session stack** (`platform/runtime/`). Applied **locally by a human**. A public subnet, internet gateway and a single NAT gateway; an EKS cluster on a current supported Kubernetes version in the bootstrap's private subnets; the smallest node capacity that runs system pods plus two small services (spot is acceptable); the EKS Pod Identity Agent add-on; container log collection to CloudWatch; an EKS access entry giving the CI **apply** role permission to deploy (sandbox debt, per ADR-0006). Allow the path 01 database security groups to accept connections from the cluster's nodes. Provide `make session-up` and `make session-down`, and a check that lists any hourly-billed resource left after `session-down`. Show the plan; don't apply.

**Phase 2: Sample service** (`services/appointment-reminders/`). A tiny HTTP service in Python with `/healthz` (process up) and `/readyz` (can reach its database over TLS when `DATABASE_SECRET_ARN` is set; otherwise reports "no datastore"). Multi-stage Dockerfile, runs as a non-root user, listens on 8080. Synthetic data only: it may create one table of fake reminders. Unit tests.

**Phase 3: Request checks** (`schema/`, `validate_requests.py`). Schema validation; file name equals service; `source` folder exists with a Dockerfile; the Dockerfile's final stage sets a non-root `USER`; the declared port matches `EXPOSE`; `datastore`, if set, names an existing path 01 request; `exposure: public` flagged as a judgment case (label `needs-security-review`). JSON output for the workflow, as path 01 does. Tests.

**Phase 4: Persistent resources and recipe.** Terraform (`terraform/`) per request: an ECR repository (scan on push, immutable tags) and the service's IAM role with a policy limited to its datastore's secret. The Helm chart (`chart/`) with every guarantee hard-coded: security context, limits from size, probes on `health_path`, ClusterIP service, image only from the service's ECR repository. Keep what persists between sessions (ECR, IAM) separate from what lives in the cluster (namespace, Pod Identity association, Helm release).

**Phase 5: Workflows.** `service-plan.yml` on pull requests: validate, Terraform plan, `helm template` and lint, post a summary and flags, same always-run pattern as the datastore plan. `service-build-deploy.yml` on merge: Terraform apply (persistent resources), build and push the image tagged with the commit SHA; then, only if the session cluster exists, create the Pod Identity association and deploy with Helm, waiting for readiness. If no session is running: build and push anyway, then end with a clear message ("runtime is off: run `make session-up` and re-run this job"), not a failure. Extend the CI roles only as far as these steps need, and list every added permission in the PR.

**Phase 6: Verification, inventory, README.** `verify_guarantee.py` checks every row of the guarantee table against the cluster and AWS, including running the database check (`/readyz`) from inside the cluster. `inventory.py` writes the service inventory to the job summary and an artifact. `README.md` written for a developer who has never used the path.

## Definition of done

* With a session running: merging the sample service's request deploys it, and verification passes every row, including reaching its path 01 database over TLS.
* A root container is rejected twice: by the request check, and by the cluster if forced.
* `exposure: public` gets the label and is not built.
* `make session-down` leaves no hourly-billed resources.
