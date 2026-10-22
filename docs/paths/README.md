# Paths

The paths Meridian's platform provides, each with a path record. Path records follow the structure of *Thinking in Platforms*, Template D.

Paths are placed on the service lifecycle value stream: see [../value-streams/service-lifecycle.md](../value-streams/service-lifecycle.md).

## MVP paths (selected in [ADR-0001](../adr/0001-select-mvp-paths-and-first-team.md))

| # | Path | Intent | Status | Cost of inactivity (per year, lower bound) | Confidence |
|---|---|---|---|---|---|
| 01 | [Compliant datastore](01-compliant-datastore.md) | Get a datastore I'm allowed to put patient data in | Validated | ~€57,000 | Medium |
| 02 | [Service to environment](02-service-to-environment.md) | Get my new service running without waiting on one person | Discovering | ~€27,000 | Medium |
| 03 | [Isolated test environment](03-isolated-test-environment.md) | Test against realistic dependencies without competing for staging | Queued | ~€46,800 | Low |
| | **Total** | | | **~€130,800** | |

Path 01 design: see 01-compliant-datastore-design.md and ADR-0002.

## How the cost of inactivity was estimated

Following the book's method: runs per year × hours per run (user team and adjacent teams) × fully loaded hourly cost.

- **Hourly cost:** €75, an assumed blended average engineer cost of ~€54/hour plus ~40% for hiring and employer costs. Fictional, but stated so anyone can recompute.
- **Hours and frequencies:** the interviewees' own estimates, extrapolated to Meridian's ~11 typical teams.
- **Lower bound by design:** excludes calendar delay, context switching, paused releases and compliance risk.

These are leading indicators of friction that exists today. They are deliberately not productivity metrics or DORA metrics, which lag behind change.

## Why this order

1. **Compliant datastore first.** Highest cost, highest risk (mislabelled PHI), clearest boundary, and the rules already exist in a checklist.
2. **Service to environment second.** Removes the single point of failure; still being understood with Tomás.
3. **Isolated test environment last.** Depends on the other two, and has the weakest evidence: it gets validated before it gets built.
