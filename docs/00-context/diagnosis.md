# Diagnosis: Meridian's production system

> Lesson 0. Reads Meridian through the lens of *Thinking in Platforms*, Part 1. Scores are the lead's judgment, not measurements.

## The lens

The book sorts production systems along two axes: **how explicitly work is designed** and **how continuously someone owns it end to end**.

| | Low end-to-end ownership | High end-to-end ownership |
|---|---|---|
| **Explicit design** | Bureaucratic: controlled, fragmented, slow | Platform-based: designed and owned as a product |
| **Implicit design** | Artisanal: informal, implicit interfaces, variable | Hero-based: knowledge concentrated in a few people, fragile |

## Where Meridian sits

Meridian is not one archetype but the "uneasy mix" the book describes. Each step of its delivery path sits in a different quadrant:

| Quadrant | Evidence at Meridian |
|---|---|
| Artisanal | 14 hand-rolled CI setups; half-finished EKS migration |
| Hero-based | Production deploys depend on Tomás's scripts; infrastructure depends on a three-person Cloud Ops queue |
| Bureaucratic | Data Protection Review board: explicit, controlled, nobody owns the end-to-end outcome |
| Platform-based | Nothing yet. This is the target |

## Verdict

**A hero-based core with bureaucratic gates.** The critical path to production runs through people, not through a system: every EKS deploy depends on one SRE, every new resource waits in one small team's queue, and every PHI decision waits for one weekly board.

**Entry into the self-reinforcing cost loop:** fragility first, with governance expansion close behind. The SOC 2 audit finding will tempt leadership to add more manual review. That is the bureaucratic over-correction the book warns about, and it would make the "not PHI" workaround worse. The answer is not fewer controls but controls designed into paths.

## Value vectors

| Value vector | Score (1–5) | Evidence |
|---|---|---|
| Delivery velocity | 2 | Resources wait 9 days, reviews 12; releases pause for one person |
| Outcome predictability | 2 | The same kind of service is built and shipped 14 different ways |
| Operational resilience | 1 | One engineer's absence stops production deploys |
| Maintenance efficiency | 2 | Two compute platforms and a Jenkins island, maintained in parallel |
| Organizational learning | 2 | Five weeks to a first change; no record of who changed what, or why |
| Incentive alignment | 1 | Labelling data "not PHI" is the rational way to ship on time |

These scores make the diagnosis discussable. They are **not** the business case: early on, the book argues with the cost of inactivity measured in discovery, not with productivity scores or lagging metrics.

## Misconceptions in the room

| Who | Belief (book's misconception) | Reframe, in plain language |
|---|---|---|
| Helena, CTO | "Our tools are our platform" (5) | A portal is one doorway. First decide what developers should be able to do; tools and portals come after. |
| Raj, CISO | "We're too complex to standardize" (4) | Most services combine a handful of building blocks. Encode your rules once per block, and your team stops re-reviewing the same thing. |
| Engineering managers | "Optimizing each team optimizes the org" (2) | Each setup makes sense locally, but 14 setups can't share a single fix. The platform team does the migration work, so no roadmap pays for it. |

## Response to the CTO's mandate

| Accept | Decline, for now | Ask instead |
|---|---|---|
| The goal: faster, safer delivery | Backstage by Q2 as the deliverable | A few weeks to interview developers |
| Her public sponsorship | Four headcount up front | Then a 3x3 proposal: 3 people, 3 paths, 3 months |
| | Deployment frequency as the KPI (lagging) | Measured by the cost of today's friction |

**Outcome:** Helena agreed to a few weeks of discovery. See [docs/discovery/](../discovery/).
