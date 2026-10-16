# Discovery synthesis: round 1

> Based on five **simulated** discovery interviews (see [README](README.md)).

## The value stream we kept seeing

Across all five teams the developer value stream had the same low-resolution shape:

**Shape the work → Set up → Build and test → Ship → Run**

Four of five interviewees chose **Set up** or **Ship** as the phase that hurts most. Coding itself was never named as the problem. This matches the book's observation that friction sits around the expert work, not in it.

## Recurring intents across interviews

| Recurring intent (plain language) | 01 | 02 | 03 | 04 | 05 | Count |
|---|---|---|---|---|---|---|
| Get a datastore for my service that I'm allowed to put patient data in | ✓ | ✓ | | ✓ | | **3/5** |
| Get my service (or change) running in an environment without waiting on one person | ✓ | | | ✓ | ✓ | **3/5** |
| Test my change against realistic dependencies without blocking others | ✓ (deferred) | ✓ | | | ✓ | **3/5** |
| Get my service building and tested automatically | ✓ | | | ✓ | | 2/5 |
| Give my service a credential safely / rotate it | ✓ | | ✓ | | | 2/5 |
| Get a working development setup | | | | | ✓ | 1/5 |
| Change my service's database safely | | | | | ✓ | 1/5 |

Counts are mentions across interviews, not votes. Three intents tie at 3/5, so frequency alone can't pick the first paths: directional cost and risk will, in the next step.

## Key insight: the datastore and the review are one intent

In every interview where a datastore came up (01, 02, 04), "get a database" and "get through Data Protection Review" were described as a single experience. The developer's real intent is not *a database*; it is **a database I'm allowed to use for patient data**.

That changes how the path is framed:

- The review is not a separate path. It is a **policy gate inside the datastore path**, and its rules belong to Security & Compliance.
- The re-submission in interview 02 was about encryption at rest, a stable rule that could be applied by default.
- The workaround in interview 04 (describing PHI as "metadata") shows the cost of the current gate is not only time but **risk**.

Following the book's guidance on capability boundaries: draw the boundary where *user intent* changes, not where tools or teams change.

## Not path candidates (logged, deliberately excluded)

| Observation | Why excluded |
|---|---|
| Partner pharmacy sandboxes are unreliable (03) | Outside Meridian's control; strong emotion, low platform leverage |
| Local development setup (05) | Real, but seen once; revisit if it recurs |
| Requests for "Terraform access", "ephemeral environments", "Backstage" | Feature requests, kept as clues to underlying intents, not requirements |

## Emerging path candidates (not yet selected)

1. **Datastore**: provision a datastore that is compliant for PHI by default.
2. **New service to environment**: get a new service built, deployed and running without a hand-off to one person.
3. **Test environment**: test a change against realistic dependencies without competing for shared staging.

Selection happens in the next step, after directional cost estimates and a team ranking.

## Next steps

- Turn each candidate into a path record (frequency, trigger, cost of inactivity).
- **Now** bring in control functions (Security & Compliance, Cloud Ops, Tomás) to understand the rules behind each gate. Users showed *where* work slows; control functions explain *why* the constraints exist.
- Force-rank three candidate first teams.
