---
status: accepted
date: 2026-10-19
decision-makers: Sofia Vistas
consulted: Security & Compliance, Cloud Ops, SRE (simulated)
---

# Select the MVP paths, the first team and the build crew

## Context and Problem Statement

Discovery round 1 (five simulated developer interviews) and conversations with the control functions produced three path candidates that tie on frequency. *Thinking in Platforms* recommends an MVP of exactly three paths, built with one team in mind by about three people (the "3x3 method"). Which paths go into the MVP, in what order, for which team, and who builds them?

Accepted by the CTO on 2026-10-19 as part of the [3x3 proposal](../proposal/README.md), with one condition: a demo after the first path.

## Decision Drivers

* Recurrence, user pain, organizational cost and feasibility should overlap (the book's test for a strong first path).
* Directional cost of inactivity, as a lower bound, rather than productivity metrics.
* Risk: Meridian handles PHI, and the current review process is already being routed around.
* The first team must maximize learning and visible impact while minimizing political and operational risk.
* Keep scope small enough for three people to build three paths in weeks, inside a three-month window.

## Considered Options

* **A.** All three candidates: compliant datastore → service to environment → isolated test environment
* **B.** Test environment first, because its estimated cost is high and frequency is every sprint
* **C.** Fewer than three paths, to reduce risk further
* **D.** Defer path selection and run a second discovery round

## Decision Outcome

Chosen option: **A**, because the three candidates are the only recurring intents with a clear start, a clear end, repeated friction and a directional cost; together they cover the "set up" and "ship" phases that four of five interviewees named as the main pain; and they build on each other.

* **Order:** compliant datastore (building), service to environment (discovering), isolated test environment (queued until validated).
* **First team:** Appointments, with Patient Messaging and Lab Results as second and third. See [team ranking](../discovery/team-ranking.md).
* **Build crew:** the lead platform engineer; a product manager at 50%, borrowed from the patient-app product group; and one Cloud Ops engineer seconded full-time. Tomás advises but is not on the crew, so the MVP doesn't deepen the bottleneck it's meant to remove.
* **Scope rule for the MVP:** the security checklist is applied as **defaults inside the datastore path**. A central policy layer, identity and state are deliberately left to Production Readiness, as the book prescribes. Judgment cases still go to a human reviewer.

### Consequences

* Good, because the first path attacks both the largest cost and the largest risk.
* Good, because Security, Cloud Ops and SRE are involved as rule owners from the start, not as afterthoughts.
* Good, because seconding a Cloud Ops engineer moves knowledge out of the queue and into the platform.
* Bad, because Cloud Ops loses one of three people for three months, which may lengthen its queue in the short term.
* Bad, because the test environment estimate rests on two interviews; it may be dropped after validation.
* Neutral, because baking rules into the MVP path is knowingly throwaway work, replaced by a policy layer later.

### Confirmation

The [3x3 proposal](../proposal/README.md) cites this ADR. Each path record's D5 section is completed with before/after measurements during the MVP.

## Pros and Cons of the Options

### B. Test environment first

* Good, because it recurs every sprint.
* Bad, because its evidence is the weakest and its cost estimate the least certain.
* Bad, because it depends on paths 01 and 02 existing.

### C. Fewer than three paths

* Good, because it lowers delivery risk.
* Bad, because one path is too little to show a pattern or to test a platform, rather than a tool.

### D. Another discovery round

* Good, because it would strengthen the evidence for path 03.
* Bad, because platform initiatives die in idle time; the book's advice is to move with enough evidence, not perfect evidence.

## More Information

[Path records](../paths/README.md) · [Control functions](../discovery/control-functions.md) · [Discovery synthesis](../discovery/synthesis.md)
