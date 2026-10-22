# Path 01 validation: compliant datastore

> Lesson 6. Path validation interview after *Thinking in Platforms* (MVP program), recorded with Template D5.
> **The run was real; the interview is simulated.** The platform lead played the Appointments engineer, using only the path README. Path record: [01-compliant-datastore.md](01-compliant-datastore.md).

## The run (21 Oct 2026)

| Time | Event |
|---|---|
| 10:55 | Request file `appointment-reminders.yaml` committed; PR #6 opened |
| 11:00 | Plan posted (no judgment cases); PR #6 merged; apply started |
| ~11:05 | **Apply failed:** `KMSKeyNotAccessibleFault` from RDS |
| 11:12 | Fix merged (PR #7): CI may read KMS key metadata account-wide; key *use* stays pinned to the platform key |
| ~12:00 | Apply re-run succeeded; **all 12 guarantee checks passed** |

Times marked ~ are approximate (from commit times and the platform lead's notes).

**Developer active effort:** `TODO: active minutes` (writing one file, opening and merging a PR, checking the plan comment).
**One-time platform fix:** ~45 minutes of platform-team time, paid once. Not a per-run cost.

### Verification (from the apply run)

All 12 checks passed: database available; storage encrypted with the platform key; not publicly accessible; 35-day backups; Postgres logs exported; master password managed by RDS; secret encrypted with the platform key; tags; TLS enforced; connection logging; 90-day retention on both log groups.

## D5. Impact and validation

| Dimension | Before (deep dive) | After (this run) |
|---|---|---|
| Time per run, user team | ~12 hours of effort over 3.5 weeks | `TODO` active minutes; same morning |
| Waiting / blocking | Two human queues (Cloud Ops ~9 days, review board ~12 days) | Machine time only: plan in about a minute, database creation in minutes |
| Rework loops | Review re-submission (encryption detail) | None for the developer. One platform-side fix, now permanent |
| Time per run, adjacent teams | Cloud Ops ~4 h, Security ~3 h | **0**: no judgment case, so no human needed |
| Unwritten rules | Four, discovered along the way | Zero: all four are enforced defaults and verified |
| **Target from the 3x3 proposal** | | **Under 2 hours, same day: achieved** |

| Signal | Answer (simulated interview) |
|---|---|
| User effort | Much easier |
| Would use unsupervised? | Yes, *because* the verification report shows what was checked |
| Would recommend to peers? | Yes |
| Net effect | **Relief achieved** |

## Observations

**Fit** *(simulated interview)*. The eight-field request felt natural; nothing in it required infrastructure knowledge. The only hesitation was over `classification`. The README's explanation resolved it without asking anyone.

**Trust.** The first real run failed. With a real user, that is the moment trust is most fragile; what recovered it was a fast fix and a verification report listing every promise as PASS. *Lesson:* never let a first real request be someone else's first run.

**Leverage: saved versus shifted.** Most time is genuinely saved: two queues and four unwritten rules are gone. But some is **shifted**: the database sits in private subnets, so nothing outside AWS can connect to it yet. A developer gets a database they can't use until **path 02** (service to environment) exists. The path's real value only appears once both paths exist.

**An unplanned user.** The request file was written with a coding agent, through the same pull-request interface a human uses. The path didn't need anything special for that. The book notes that AI agents are becoming users of value streams; this path already serves one.

## Remaining frictions and next actions

| Friction | Action |
|---|---|
| Can't connect to the database from outside AWS | Path 02 (service to environment) |
| Empty first run tested the pipeline, not the recipe | Future paths: one real request in a throwaway sandbox before user validation |
| Destroy has never run | Remove the request through a PR after the CTO demo |
