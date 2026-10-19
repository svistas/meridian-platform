# The 3x3 proposal

> Lesson 3. Presented to the CTO at the end of Stage 1 (Getting Started). Slides: [3x3-proposal.pdf](3x3-proposal.pdf).

Following the 3x3 method from *Thinking in Platforms*: three paths, three people, three months, one team.

## Storyline

1. **We listened before proposing anything.** Five developer interviews, three control-function sessions, no solutions pitched.
2. **Developers lose time waiting, not coding.** Each path removes a wait at a recurring moment on the [service lifecycle](../value-streams/service-lifecycle.md).
3. **Today's friction costs at least ~€130,800 a year** ([path records](../paths/README.md)), a lower bound that excludes calendar delay and compliance risk.
4. **The proposal.** Three paths in order (compliant datastore, service to environment, test environment); a crew of the platform lead, a product manager at 50% and one seconded Cloud Ops engineer; one quarter; Appointments as first team.
5. **How we'll know it worked.**

| Path | Today, per run | Target after the MVP |
|---|---|---|
| Compliant datastore | 19 hours, 3–5 weeks | Under 2 hours, same day |
| Service to environment | 24 hours, ~1 week | Under 4 hours, no hand-off |
| Test environment | Half a day per sprint | Validate the need first |

   Adoption signal: Appointments uses the paths unsupervised and would recommend them. **Stop rule:** no measurable improvement on the first path by week 6, and the experiment stops.
6. **Not doing yet:** no portal, no announcement, no demands on teams, no production.

## Investment

About €79k of people's time (2.5 FTE × 3 months × ~140 h × €75), mostly reallocated rather than new hires. The MVP alone won't pay this back; it buys evidence. Savings come as paths reach other teams.

## Decisions requested and outcome

| Decision | Outcome |
|---|---|
| Approve the 3x3 experiment for one quarter | Approved |
| Product manager at 50% from the patient-app group | Approved |
| Second one Cloud Ops engineer for three months | Approved |
| CTO backing with the Appointments engineering manager | Approved |

**Condition added by the CTO:** a demo after the first path. Pre-wired before the meeting: Security & Compliance co-owns the datastore rules.
