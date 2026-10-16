# Interview 05: Lab Results team

> **Simulated interview.** Fictional company and interviewee.

## A. Orientation

| Field | Notes |
|---|---|
| Team | Lab Results (ingests lab results and shows them to patients and clinicians) |
| Role (title only) | Backend engineer, joined two months ago |
| Type of work | First production change as a new hire |
| Concrete example (their words) | "My first real change: adding a reference-range field to results." |
| Interview type | Exploratory (discovery) |

## B. Value stream sketch

Same shape as interview 01. Phase chosen for depth: **Build/test and Ship**, seen through a new joiner's eyes.

## C. Friction and intent landscape

| Step | Friction point (observation) | Type | Intent |
|---|---|---|---|
| Build and test | Couldn't run the service locally for ~1 week; setup lived in a teammate's head | Internal non-core work | Get a working development setup |
| Build and test | Needed a schema change on the team's Postgres; unclear who is allowed to run migrations in staging | External dependency | Change my service's database safely |
| Build and test | Waited for a staging slot | External dependency | Test my change against realistic dependencies |
| Ship | Learned to deploy by shadowing Tomás; "there's no doc, there's Tomás" | External dependency | Get my change running in an environment |

## Directional cost (their estimates)

- **~5 weeks** from first day to first production change.
- Teammates' time helping: "a few hours a week for the first month."

## E. Team signals

| Signal | Observation |
|---|---|
| Frequency | Onboarding: the team hired 2 people this year |
| Variability | Low |
| Existing workarounds | Shadowing people |
| User openness | Very open; fresh eyes, no attachment to current setup |
| Cross-team impact | Medium |

## Interviewer notes

- A new joiner sees the system without the habits that make friction invisible to others. Useful voice, though one interview is not a pattern.
- Confirms Tomás as the single point of failure for shipping.
- Local development setup is a real friction but appeared only here so far. Deferred.
