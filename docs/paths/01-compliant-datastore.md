# Path 01: Compliant datastore

> Path record (structure after *Thinking in Platforms*, Template D). Status: **selected for MVP, first to build.**
> Evidence: interviews 01, 02, 04; control functions (Security & Compliance, Cloud Ops).

## D1. Path anchor

| Field | Notes |
|---|---|
| Path name | Compliant datastore |
| Intent (plain language) | Get a datastore for my service that I'm allowed to put patient data in |
| Trigger | A service needs persistent storage that doesn't exist yet |
| Frequency (rough) | ~40 per year across Meridian (3–4 per typical team per year, ~11 typical teams) |

## D2. Current reality

1. Developer opens a Jira ticket to Cloud Ops describing the database.
2. Developer fills in the Data Protection Review form, deciding whether the data is PHI.
3. Review board meets weekly; ~2 in 10 submissions are sent back (often for encryption details).
4. Cloud Ops writes or copies Terraform and applies it.
5. Credentials are handed over, sometimes through a password vault first.

**Main frictions (max 3):**
- Two separate queues (Cloud Ops, review board), each measured in weeks
- Rework when the stable checklist rules are missed
- An incentive to under-classify data to skip the review

## D3. Input and output

| | |
|---|---|
| **Minimal input** | Owning service and team; engine (Postgres to start); size class; data classification (PHI / non-PHI) |
| **Output (definition of done)** | A reachable datastore in the requested environment, credentials delivered to the service as a secret, encryption and backups on, classification and ownership tags applied, and a record of who requested it and when |

## D4. Constraints

| Kind | Notes |
|---|---|
| Hard gates | Encryption at rest and in transit; no public access; BAA-eligible service; classification and ownership tags |
| Judgment cases (stay human) | New vendor, data flow leaving Meridian, data leaving its region |
| Rule owners | Security & Compliance (checklist); Cloud Ops (tagging, network) |

## Cost of inactivity (directional, lower bound)

| Who | Hours per run |
|---|---|
| Developer (tickets, forms, rework, chasing) | 12 |
| Cloud Ops | 4 |
| Security reviewer and board share | 3 |
| **Total** | **19** |

19 h × €75 × 40 runs ≈ **€57,000 per year.**

Not included: ~3–5 weeks of calendar delay per run, and the risk of mislabelled PHI, which is the most important cost but isn't monetized here.

## D5. Impact and validation

Validated 21 October 2026 on the first real run: one request file, one pull
request, a database the same morning. Full record, including the simulated
validation interview: [01-compliant-datastore-validation.md](01-compliant-datastore-validation.md).

| Dimension | Before (deep dive) | After (this run) |
|---|---|---|
| Time per run, user team | ~12 hours of effort over 3.5 weeks | Minutes of effort, same morning |
| Waiting | Two human queues: Cloud Ops ~9 days, review board ~12 days | Machine time only |
| Time per run, adjacent teams | Cloud Ops ~4 h, Security ~3 h | Zero: no judgment case, so no human needed |
| Rework | A review re-submission over an encryption detail | None for the developer |
| Unwritten rules | Four, discovered along the way | Zero: all four are enforced defaults, and verified |

All 12 guarantee checks passed against the AWS API. The 3x3 proposal's target —
under two hours, same day — is met.

Two things the run showed that the table does not. The first apply failed on a
platform-side IAM gap; what recovered it was a fast fix and a verification
report showing every promise as PASS, which is the moment trust is most
fragile. And the time is not all saved: the database sits in private subnets,
so a developer gets one they cannot yet connect to. The path's full value
arrives with [path 02](02-service-to-environment.md).
