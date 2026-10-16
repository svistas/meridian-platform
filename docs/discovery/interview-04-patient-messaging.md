# Interview 04: Patient Messaging team

> **Simulated interview.** Fictional company and interviewee.

## A. Orientation

| Field | Notes |
|---|---|
| Team | Patient Messaging (secure inbox between patients and care teams) |
| Role (title only) | Backend engineer |
| Type of work | Launching a new backend service |
| Concrete example (their words) | "Getting the new inbox service out the door in August." |
| Interview type | Exploratory (discovery) |

## B. Value stream sketch

Same shape as interview 01. Phase chosen for depth: **Set up and Ship** ("everything before the first real deploy").

## C. Friction and intent landscape

| Step | Friction point (observation) | Type | Intent |
|---|---|---|---|
| Set up | Postgres via Cloud Ops ticket, ~9 business days | External dependency | Get a database for my service |
| Set up | Data Protection Review: the team described the attachments bucket as not containing PHI (see notes) | External dependency | Know whether my data handling is acceptable so I can ship |
| Set up | CI workflow copied from Appointments repo, then edited | Internal non-core work | Get my service building and tested automatically |
| Ship | First deploy: needed Tomás to create Helm values and namespace; ~1 week including his backlog | External dependency | Get my new service running in an environment |

## Directional cost (their estimates)

- ~4 weeks from repo creation to first production deploy; **~2.5 days** active set-up effort.
- Tomás: "probably a day of his time, spread out."

## E. Team signals

| Signal | Observation |
|---|---|
| Frequency | New services: 1–2 per year; datastores: a few per year |
| Variability | Low: Node.js, Postgres, S3 |
| Existing workarounds | Copying CI; describing data narrowly to avoid review |
| User openness | Open, slightly uneasy when discussing the review |
| Cross-team impact | High |

## Interviewer notes

- When asked to walk through the review step by step, there was a long pause, then: "We said the bucket was for 'message metadata'. Technically attachments can be lab photos." No follow-up judgment was given; the silence did the work. This is the incentive problem from Lesson 0 seen first-hand: **the slow gate pushes people to route around it**.
- Third interview where database + review form one experience.
- Referred us to: Lab Results ("they just onboarded someone new").
