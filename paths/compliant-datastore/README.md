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

Removing the file and merging destroys the database. Read
[Removing a datastore](#removing-a-datastore) before you do that.

## What to expect

| | |
|---|---|
| You open the pull request | Checks run in about a minute: your request file is validated, and you get a comment showing what would be built |
| It is reviewed and merged | The database is created |
| **About 10 to 15 minutes after the merge** | The database is ready and every guarantee has been verified |

Most of that time is AWS creating the instance; nothing is waiting on a person.
Watch the Actions tab for the `datastore apply` run that starts on merge.

If a check fails, read the comment on your pull request first: validation
errors say what to write instead.

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

## Connecting

You need two things: the endpoint and the password.

**The endpoint.** Two places, whichever is quicker:

- The `datastore apply` run in the **Actions** tab. Its summary lists every
  datastore, and the inventory is attached to the run as an artifact.
- The **AWS console**, under RDS → Databases → your service name. Or:

```sh
aws rds describe-db-instances \
  --db-instance-identifier appointment-reminders \
  --query 'DBInstances[0].Endpoint.{host:Address,port:Port}'
```

The password is in Secrets Manager — see [Finding your
password](#finding-your-password) above.

**TLS is required.** The database refuses connections that are not encrypted
(`rds.force_ssl = 1`), so a client that does not ask for TLS fails to connect
rather than quietly falling back. Set `sslmode=require`:

```
postgresql://meridian:<password>@<host>:5432/appointment_reminders?sslmode=require
```

```sh
psql "host=<host> port=5432 dbname=appointment_reminders user=meridian sslmode=require"
```

The database name is your service name with hyphens turned into underscores,
so `appointment-reminders` holds a database called `appointment_reminders`.

**The database is not reachable from the internet, or from your laptop.** It
sits in private subnets with no inbound rule, which is the point. Connecting a
running service to it is path 02's job.

## Removing a datastore

Delete your request file and merge.

> **The database is destroyed immediately, and the data is gone.**
>
> In the sandbox there is no deletion protection and **no final snapshot**:
> when the apply runs, the instance is deleted and nothing is kept. There is
> no undo, and nobody can restore it for you. The automated backups go with
> the instance.
>
> If there is anything in the database you want, take a copy **before** you
> merge the removal.

This is deliberate for a sandbox holding synthetic data, where leaving
databases running costs money and the teardown habit matters. A production
version of this path would not behave this way.

## Getting help

Open an issue on this repository with the label **`path:compliant-datastore`**.

Useful things to include: your service name, a link to the pull request, and
the failing run. If a check failed, the comment on your pull request usually
says what to change.

Questions about whether your data is PHI are not for the platform team: mark
the request `classification: unsure`, which flags it for Security & Compliance
to decide.

## Checking it yourself

```sh
pip install -r requirements.txt
python3 scripts/validate_requests.py                 # before you push
python3 -m unittest discover -s scripts -p 'test_*.py'
```
