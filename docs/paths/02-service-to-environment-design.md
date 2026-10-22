# Path 02 design: service to environment

> Lesson 7. Design sequence from *Thinking in Platforms* (MVP program): deep-dive interview → perfect world → reintroduce reality → options → choose with the user. **Interviews are simulated.** Path record: [02-service-to-environment.md](02-service-to-environment.md). Decision: [ADR-0005](../adr/0005-service-to-environment-path-design.md).

## 1. Deep dive: the last real occurrence

**Who:** backend engineer, Patient Messaging (discovery interview 04), then Tomás (SRE).
**Anchor:** the first deploy of the inbox service, in August.

| # | What happened | Elapsed | Friction |
|---|---|---|---|
| 1 | Code ready; copied a GitHub Actions workflow from the Appointments repo to build a container image | day 0 | Copy-paste CI |
| 2 | Spent ~1.5 days fixing the copied workflow (registry name, image tags, test command) | days 0–2 | Rework |
| 3 | Asked Tomás in Slack to "add us to Helm" | day 2 | Single person on the critical path |
| 4 | Tomás asked: port? health-check path? how much memory? does it need the database? Back-and-forth over two days | days 2–4 | Unwritten required fields |
| 5 | Tomás created a namespace, Helm values, an IAM role for the service, ingress and DNS, wired the database secret, added a dashboard | day 5 | ~1 day of his time, in pieces |
| 6 | First deploy failed: the container ran as root, which the cluster rejects (**unwritten rule**) | day 5 | Rework |
| 7 | Second deploy failed its readiness check: health endpoint didn't exist (**unwritten rule**: every service needs one) | day 6 | Rework |
| 8 | Running in staging; Tomás repeated steps 5–7 for production | days 6–9 | Everything happens twice |

**Retold without gaps:** ~2 weeks and ~16 hours of developer effort plus ~8 hours of Tomás's time, with three unwritten rules discovered by failing.

### Tomás's view: what every service needs (now explicit)

| Prerequisite | Rule (was in Tomás's head) |
|---|---|
| Own runtime identity | One IAM role per service; never shared credentials |
| Runs as non-root | Rejected otherwise |
| Health endpoint | Required; used for readiness and liveness |
| Resource limits | Required; defaults: 0.25 vCPU, 512 MB |
| Image source | Only from Meridian's own container registry |
| Network exposure | Private by default; public only after review |
| Logs | JSON to standard output, collected centrally |
| Database access | Through path 01's secret, never a copied password |

### Input: minimum the path needs

| Field | Notes |
|---|---|
| Service name and owning team | Naming, tags, ownership |
| Container image | Built by CI from the service's repository |
| Port and health-check path | The two questions Tomás always had to ask |
| Size | `small` or `medium` (maps to CPU and memory) |
| Datastore (optional) | The name of a path 01 datastore to connect to |
| Exposure | `internal` (default) or `public` |

### Output: stated as a guarantee

> If a valid request is accepted, the platform ensures the service runs in the sandbox with its own runtime identity, as non-root, with resource limits, passing its health check, reachable inside the private network (or behind a reviewed public endpoint), with its logs collected, connected to its datastore through the managed secret if one was named, and recorded in a service inventory.

### Policy gates

| Gate | Kind | Owner |
|---|---|---|
| Own identity, non-root, limits, approved registry, logs | Hard: always applied | SRE, Security |
| Health check passing before "done" | Hard | SRE |
| `exposure: public` | **Judgment**: flagged for Security | Security & Compliance |

## 2. Perfect world

The developer pushes code. The platform notices a new service, works out how to build it, which port it uses and what it needs, deploys it everywhere and connects it. No file, no questions.

## 3. Reintroduce reality

**Technical.** Ports, health endpoints and dependencies can't be inferred reliably from code. Build steps vary by language.
**Organizational.** Public internet exposure for a healthcare company is a real judgment call; Security keeps it. Tomás must not be paged by the MVP (his stated fear).
**MVP scope.** Non-production, about two weeks, no central policy engine, sandbox budget.

**Key design insight.** The three unwritten rules that broke the inbox deploy (non-root, health endpoint, registry) were discovered *by failing*. The path should check them **before** anything runs, in the pull request, the way path 01's validator checks requests. And because the request can *name a path 01 datastore*, path 02 closes path 01's biggest gap: "I have a database I can't connect to."

## 4. Options

| Option | What it is | Stable | Removes friction | Fits ~2 weeks |
|---|---|---|---|---|
| **A. Fully inferred** | No declaration; platform guesses from code | Low | In theory, all | No |
| **B. Shared template** | Publish Tomás's Helm chart for teams to copy | Medium | Some, but copies drift: today's problem again | Yes |
| **C. Declare and deploy** | A short service file in a PR; platform-owned build workflow and deploy recipe; rules checked before deploy; judgment case flagged | High | Most: no hand-off, no copy-paste CI | Yes |

**Chosen with the user: C.** Same interface shape as path 01, so developers learn one pattern.

| Who | Concern | Response |
|---|---|---|
| Patient Messaging engineer | "Do I still write my own CI?" | No: the path provides the build workflow. Your repo only needs a Dockerfile and a health endpoint |
| Tomás | "Will this page me?" | Not in the MVP: sandbox only, no on-call. Paging is a Production Readiness design question |
| Tomás | "Who owns the recipe?" | The platform team, with Tomás reviewing the runtime defaults he wrote down |

## 5. Still open: where services run

The promise above doesn't name a runtime, on purpose: the book separates a capability's stable **promise** from its replaceable **implementation**. The implementation choice (Kubernetes on EKS, or ECS on Fargate) is a cost and fidelity decision, recorded separately.
