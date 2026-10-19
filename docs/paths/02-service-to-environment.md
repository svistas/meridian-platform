# Path 02: Service to environment

> Path record (structure after *Thinking in Platforms*, Template D). Status: **selected for MVP, second to build.**
> Evidence: interviews 01, 04, 05; control functions (Tomás, Cloud Ops).

## D1. Path anchor

| Field | Notes |
|---|---|
| Path name | Service to environment |
| Intent (plain language) | Get my new service running in an environment without waiting on one person |
| Trigger | A new service has code ready to run for the first time |
| Frequency (rough) | ~15 new services per year across Meridian (1–2 per typical team per year) |

## D2. Current reality

1. Developer copies a CI workflow from another team's repository and fixes it.
2. Developer asks Tomás to add the service to the Helm setup.
3. Tomás creates the namespace, Helm values, IAM role, ingress and DNS, and wires secrets and dashboards.
4. First deploy happens when Tomás is available.

**Main frictions (max 3):**
- A single person on the critical path, with undocumented knowledge
- CI copied and debugged per service
- New joiners learn deployment by shadowing, not from the system

## D3. Input and output

| | |
|---|---|
| **Minimal input** | Service name and owning team; container image built by CI; the environment; the port it listens on |
| **Output (definition of done)** | The service running and reachable in the environment, with its own identity, its secrets available, health checks passing, and basic dashboards, without a hand-off to Tomás |

## D4. Constraints

| Kind | Notes |
|---|---|
| Hard gates | Each service gets its own runtime identity (no shared credentials); no public exposure unless explicitly requested |
| Dependencies | Uses Path 01 when the service needs a datastore |
| Rule owners | SRE (runtime prerequisites), Cloud Ops (network, IAM) |

## Cost of inactivity (directional, lower bound)

| Who | Hours per run |
|---|---|
| Developer (CI copying, coordination, waiting on hand-offs) | 16 |
| Tomás | 8 |
| **Total** | **24** |

24 h × €75 × 15 runs ≈ **€27,000 per year.**

Not included: releases paused when Tomás is away, and the onboarding effect (five weeks to a first production change).

## D5. Impact and validation

To be filled in during the MVP.
