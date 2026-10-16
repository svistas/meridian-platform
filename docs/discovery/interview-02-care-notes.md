# Interview 02: Care Notes team

> **Simulated interview.** Fictional company and interviewee.

## A. Orientation

| Field | Notes |
|---|---|
| Team | Care Notes (clinician portal backend) |
| Role (title only) | Senior backend engineer |
| Type of work | Adding infrastructure to an existing service |
| Concrete example (their words) | "We added Redis and an SQS queue so notes autosave without losing drafts." |
| Interview type | Exploratory (discovery) |

## B. Value stream sketch

Same shape as interview 01 (shape → set up → build/test → ship → run). Phase chosen for depth: **Set up**, and, mentioned in passing, **Build and test**.

## C. Friction and intent landscape

| Step | Friction point (observation) | Type | Intent |
|---|---|---|---|
| Set up | Two separate Cloud Ops tickets (Redis, SQS); ~8 and ~10 business days | External dependency | Get a datastore / queue for my service |
| Set up | Data Protection Review for Redis because drafts contain clinical notes; asked to re-submit once for missing encryption detail | External dependency | Know whether my data handling is acceptable so I can ship |
| Build and test | Waited ~1.5 days for a free slot in shared staging to test autosave end to end ("we have a Slack channel where you claim staging") | External dependency | Test my change against realistic dependencies without blocking others |
| Ship | Release of the change itself was fine (service already existed) | none | none |

**Other roles involved:** Cloud Ops, Security & Compliance, other teams sharing staging.

## Directional cost (their estimates)

- ~2.5 weeks from "decided to add Redis/SQS" to "available in staging". **~1.5 days** active effort on tickets, re-submission, chasing.
- Staging contention: "maybe once a sprint someone on the team waits half a day or more."

## E. Team signals

| Signal | Observation |
|---|---|
| Frequency | Infra additions: a few per quarter; staging waits: every sprint |
| Variability | Low to medium |
| Existing workarounds | Slack channel to "claim" staging |
| User openness | Open but skeptical ("we've seen tooling initiatives before") |
| Cross-team impact | High |

## Interviewer notes

- Second time the datastore and the review appear together. The re-submission was for **encryption at rest**, a rule that is stable and could be known up front.
- The staging wait was mentioned almost in passing. Quiet frictions like this compound.
- Feature request heard: "Ephemeral environments, like at my last company." Logged as a clue.
- Referred us to: Pharmacy Connect.
