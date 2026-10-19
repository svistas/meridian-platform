# Control functions: round 1

> **Simulated interviews.** Fictional company and interviewees.

Users showed *where* work slows down. These conversations ask *why* each constraint exists and how it must be upheld, so implicit rules become explicit design inputs. Same rules as the user interviews: anchor on real recent cases, pitch no solutions.

## Security & Compliance (Raj, CISO, and the reviewer who runs the Data Protection Review board)

**Anchored on:** the last ten Data Protection Review tickets, pulled up together during the session.

| What we learned | Observation |
|---|---|
| What the review actually checks | A stable checklist: encryption at rest with a managed key, encryption in transit, no public access, backups and retention set, access logging on, the AWS service is BAA-eligible, and the resource carries a data classification tag |
| How often the checklist decides it | Reviewer's estimate: about 8 in 10 reviews are decided by the checklist alone. The rest need real judgment: a new vendor, a new data flow leaving Meridian, or data leaving its region |
| Why the board is weekly | The reviewer is one person; batching protects their time |
| Raj's actual fear | Losing track of **where PHI lives**. The audit finding made this worse. Speed was never his goal; visibility is |
| Known workaround | They suspect teams under-classify data but can't prove it. The review only sees what teams declare |

**Constraint, stated explicitly:** every datastore that may hold PHI must meet the checklist *and* be findable as PHI afterwards. Judgment cases must still reach a human.

## Cloud Ops (team lead)

**Anchored on:** last month's ticket queue.

| What we learned | Observation |
|---|---|
| What the queue contains | Roughly 6 in 10 tickets are variations of four things: a Postgres database, a bucket, a queue, a secret |
| How they fulfil them | Terraform, mostly copied per request rather than reusable modules |
| Why requests go through them | Fear of cost surprises and of losing control of the AWS accounts; one past incident where a developer opened a security group to the internet |
| What they'd like | "Guardrails, so we stop being typists" |

**Constraint, stated explicitly:** anything provisioned must be tagged for cost and ownership, and must never be publicly reachable.

## SRE (Tomás)

**Anchored on:** the last new service he deployed (Patient Messaging's inbox service).

| What we learned | Observation |
|---|---|
| What a new service needs | A namespace, Helm values, an IAM role for the service, ingress and DNS, secrets wired in, dashboards. About a day of his work, spread over a week of interruptions |
| Why only he does it | The Helm setup grew organically; there is no documentation, and he knows it |
| Shared staging | One staging environment for all EKS teams; conflicts are resolved in a Slack channel |
| His position | Wants out of the bottleneck. Worried that any new system will page him when it breaks |

**Constraint, stated explicitly:** every new service needs a defined set of runtime prerequisites (identity, networking, secrets, observability). They are known and repeatable; today they live in one person's head.

## What changed after these conversations

- The datastore review is **mostly deterministic**. The checklist can become defaults inside the path; only judgment cases need a human.
- Raj's real requirement is **visibility of PHI**, not a meeting. A path that classifies and records every datastore can give him more than the board does today.
- Cloud Ops and Tomás are **allies, not obstacles**: both want to stop being bottlenecks.
- Tomás's fear of being paged is a design input for production readiness, not for the MVP.
