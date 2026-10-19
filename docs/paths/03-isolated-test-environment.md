# Path 03: Isolated test environment

> Path record (structure after *Thinking in Platforms*, Template D). Status: **selected for MVP, third to build (queued).**
> Evidence: interviews 02, 05 (and a deferred mention in 01); control functions (Tomás). Weakest evidence of the three.

## D1. Path anchor

| Field | Notes |
|---|---|
| Path name | Isolated test environment |
| Intent (plain language) | Test my change against realistic dependencies without competing for shared staging |
| Trigger | A change is ready to test end to end |
| Frequency (rough) | Every sprint, in teams using shared staging heavily (estimated ~6 teams) |

## D2. Current reality

1. Developer claims staging in a Slack channel.
2. If staging is taken or broken by another team, they wait or test less.
3. Change is tested in the shared environment, with whatever data is there.

**Main frictions (max 3):**
- Contention for a single shared environment
- One team's broken deploy blocks everyone's testing
- No clean, known test data

## D3. Input and output

| | |
|---|---|
| **Minimal input** | The service and branch to test; which dependencies it needs |
| **Output (definition of done)** | A temporary environment with the service and its dependencies running, seeded with **synthetic** data only, that cleans itself up |

## D4. Constraints

| Kind | Notes |
|---|---|
| Hard gates | No real PHI in any test environment, ever; environments must expire |
| Dependencies | Builds on Path 02 (a service must be deployable before it can be deployed temporarily) and Path 01 (datastores) |
| Rule owners | Security & Compliance (data), SRE (capacity) |

## Cost of inactivity (directional, lower bound)

Team estimate: about half a day lost per team per sprint to waiting and coordination.

4 h × 26 sprints × 6 teams = 624 h × €75 ≈ **€46,800 per year.**

**Confidence: low.** Based on two interviews; the team count is an extrapolation. Treat as a hypothesis to validate before building.

## D5. Impact and validation

To be filled in during the MVP.
