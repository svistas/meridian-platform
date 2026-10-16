# Interview 01: Appointments team

> **Simulated interview.** Fictional company and interviewee.

## A. Orientation

| Field | Notes |
|---|---|
| Team | Appointments (backend for booking in the patient app) |
| Role (title only) | Backend engineer |
| Type of work | Launching a new backend service |
| Concrete example (their words) | "The reminders service we put live last month, the one that texts patients before their appointment." |
| Interview type | Exploratory (discovery) |

## B. Value stream sketch (low resolution, their language)

**Intent:** Get a change in front of patients and keep it running.

| Step | What typically happens | Who's involved | Notes |
|---|---|---|---|
| 1. Shape the work | Ticket refined with PM, rough design in a doc | Engineer, PM | Not painful |
| 2. Set up | Repo, CI, any new infra (DB, queue, secrets) | Engineer, Cloud Ops, Security | **"This is where it drags"** |
| 3. Build and test | Code, unit tests, try it in shared staging | Engineer, team | Staging is shared; sometimes blocked |
| 4. Ship | Deploy to production | Engineer, Tomás (SRE) | First deploy of a new service needs Tomás |
| 5. Run | Dashboards, on-call, fixes | Team | OK once running |

**Outcome:** Patients get reminders, no-shows go down.

**Phase chosen for depth:** Step 2, Set up. Asked "which part slows you down again and again?" Answer: "Setting up anything new. The coding part is fine."

## C. Friction and intent landscape (Set up phase)

| Step | Friction point (observation) | Type | Intent (what they need to achieve) |
|---|---|---|---|
| Set up | Postgres database requested via Jira ticket to Cloud Ops; arrived after ~2 weeks | External dependency | Get a database for my service |
| Set up | Data Protection Review form asked whether reminders contain PHI; debate inside the team; board met weekly; ~3 weeks end to end | External dependency | Know whether my data handling is acceptable so I can ship |
| Set up | Copied a GitHub Actions workflow from another team's repo; ~1.5 days fixing it | Internal non-core work | Get my service building and tested automatically |
| Set up | SMS provider API key: created by Cloud Ops in Secrets Manager after a second ticket; meanwhile shared in a password vault | External dependency | Give my service a credential safely |
| Ship | First production deploy waited for Tomás to add the service to the Helm setup (~4 days, he was at a conference) | External dependency | Get my new service running in an environment |

**Other roles at these friction points:** Cloud Ops (3 people), Security & Compliance (review board), Tomás (SRE).

**Deferred (outside chosen phase):** shared staging occasionally blocked by another team's broken deploy.

## D1. Path anchors sketched from this interview

| Path candidate | Intent (plain language) | Trigger | Rough frequency (their estimate) |
|---|---|---|---|
| Datastore | Get a database for my service that I'm allowed to put patient data in | New service or new feature needing storage | "3 or 4 times a year for our team" |
| First deploy | Get my new service running in an environment | New service | "Twice a year" |
| Credential | Give my service a credential safely | New integration | "A few times a year" |

## Directional cost (their estimates)

- Reminders service: ~5 calendar weeks from "code ready" to "live". Engineer estimates **~3 days of their own active effort** spent on set-up work, the rest waiting.
- Adjacent effort: Cloud Ops "maybe half a day"; security reviewer "an hour or two plus the board meeting"; Tomás "half a day".

## E. Team signals

| Signal | Observation |
|---|---|
| Frequency of intent | Medium: new storage or services several times a year |
| Variability | Low: standard Node.js services, Postgres |
| Existing workarounds | Password vault for secrets; copying CI from other repos |
| User openness | Open, specific, not defensive; offered to show tickets |
| Cross-team impact | High: touches Cloud Ops, Security, SRE every time |

## Interviewer notes (interpretation, kept separate)

- The database and the review were described as **one experience**: "getting a database you're allowed to use." Worth testing in other interviews whether this is one intent or two.
- Feature request heard: "Honestly, just give us Terraform access." Logged as a clue, not a requirement: the underlying intent is not waiting.
- Referred us to: Care Notes ("they just went through the same thing").
