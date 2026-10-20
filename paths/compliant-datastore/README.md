# Compliant datastore

Ask for a Postgres database by adding one file in a pull request. On merge you
get a database you are allowed to put patient data in, with the protection
already applied and nothing to negotiate.

> This is the reference for the request format. The full walkthrough written
> for the Appointments engineer is phase 6 of the
> [build brief](../../docs/paths/01-compliant-datastore-build-brief.md).

## Asking for a datastore

Add a file to `requests/`, named after your service, and open a pull request:

`requests/appointment-reminders.yaml`

```yaml
service: appointment-reminders
team: appointments
cost_center: patient-app
environment: sandbox
engine: postgres
size: small
classification: phi
data_leaves_meridian: "no"
```

The file name must match `service`. All eight fields are required.

| Field | What to write |
|---|---|
| `service` | Lowercase with hyphens. Becomes the database identifier, so it must start with a letter |
| `team` | The team that owns the service |
| `cost_center` | Which budget pays for it |
| `environment` | `sandbox` — the only value the MVP builds |
| `engine` | `postgres` — the only engine the MVP builds |
| `size` | `small` (db.t4g.micro, 20 GB) or `medium` (db.t4g.small, 50 GB) |
| `classification` | `phi`, `non-phi` or `unsure` |
| `data_leaves_meridian` | `"no"` (any case, or the YAML `false`), or the destination, like `"sms-vendor"` |

Removing the file and merging destroys the database.

## What you get, whatever you asked for

Every datastore is built the same way. None of this is yours to set, and none
of it can be switched off by a request file:

- Storage encrypted with the platform's own KMS key
- Never reachable from the internet; private subnets, no ingress until a
  service is attached
- 35 days of backups
- TLS required (`rds.force_ssl = 1`)
- Postgres logs in CloudWatch, kept 90 days, with connections and
  disconnections logged
- A master password generated and held by AWS Secrets Manager
- Tags for service, team, cost centre, classification and ownership

This is deliberate. Because every datastore gets PHI-grade protection
regardless of how you classify it, saying `non-phi` buys you nothing — so
there is no reason to say it unless it is true. See
[ADR-0002](../../docs/adr/0002-compliant-datastore-path-design.md).

## Classification, and when a human gets involved

`classification` is recorded, not acted on. It is how Security answers "which
datastores hold patient data", so it has to be honest.

Two answers bring a human in, and the pull request is labelled
`needs-security-review`:

- `classification: unsure` — someone decides before the data is used
- `data_leaves_meridian` naming a destination — what is sent, and under which
  agreement, needs review

Neither blocks the merge in the sandbox. The flag is the point.

## Finding your password

It is never in Terraform, in a log, or in this repository. CI cannot read it
either. Ask Secrets Manager:

```sh
aws secretsmanager get-secret-value \
  --secret-id "$(aws rds describe-db-instances \
      --db-instance-identifier appointment-reminders \
      --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text)" \
  --query SecretString --output text
```

## Checking it yourself

```sh
pip install -r requirements.txt
python3 scripts/validate_requests.py                 # before you push
python3 -m unittest discover -s scripts -p 'test_*.py'
```
