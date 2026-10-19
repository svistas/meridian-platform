# Path 01 design: compliant datastore

> Lesson 4. Design sequence from *Thinking in Platforms* (MVP program): deep-dive interview → perfect world → reintroduce reality → options → choose with the user. **Interviews are simulated.** Path record: [01-compliant-datastore.md](01-compliant-datastore.md). Decision: [ADR-0002](../adr/0002-compliant-datastore-path-design.md).

## 1. Deep dive: the last real occurrence

**Who:** backend engineer, Appointments (same person as discovery interview 01).
**Anchor:** the Postgres database for the appointment-reminders service, ~6 weeks ago.
**Ground rule stated up front:** we're reconstructing what happened, not judging or improving it.

### Step-by-step trace (as it happened)

| # | What happened | Elapsed | Friction |
|---|---|---|---|
| 1 | Team decided reminders need their own Postgres database (one database per service is the house convention) | day 0 | |
| 2 | Searched the wiki for "how to get a database"; found a two-year-old page pointing at the Cloud Ops Jira project | day 0 | Knowledge is hard to find |
| 3 | Opened a ticket in free text: engine, "small", staging and production | day 1 | |
| 4 | Cloud Ops asked back for subnets, expected connections, **cost center** and **owning service** for tags | days 1–3 | Unwritten required fields |
| 5 | Cloud Ops asked: "Did you do the Data Protection Review?" Engineer didn't know it applied to staging too | day 3 | Unwritten rule |
| 6 | Filled the 14-question review form. Team debated "does it hold PHI?" for two days; answered yes (patient name + appointment time) | days 3–5 | Classification is a judgment under time pressure |
| 7 | Board met the next Thursday. Reviewer asked for **35-day backup retention** and asked whether reminders leave Meridian via the SMS vendor. Vendor already has a BAA, so approved | day 10 | Unwritten rule; one real judgment question |
| 8 | Cloud Ops copied Terraform from Patient Messaging's database, renamed it, applied in staging | day 13 | Copy-paste infrastructure |
| 9 | Master password stored in Secrets Manager; secret name shared in Slack. Meanwhile the engineer had a copy from a password vault | day 13 | Credentials handled by hand |
| 10 | Service couldn't connect until `sslmode=require` was set; TLS enforcement was undocumented | day 14 | Unwritten rule |
| 11 | Repeated steps 3–9 for production | days 15–24 | Everything happens twice |

**Retold without gaps:** ~3.5 weeks and ~12 hours of the engineer's effort to get two databases, with four unwritten rules discovered along the way.

### Input: minimum the path needs

| Field | Always present? | Notes |
|---|---|---|
| Owning service | Yes | Used for naming and tags |
| Owning team and cost center | Yes | Cloud Ops requirement (tribal knowledge, now explicit) |
| Environment | Yes | `sandbox` only in the MVP |
| Engine | Yes | Postgres only in the MVP (the normal case) |
| Size | Yes | `small` or `medium` |
| Data classification | Yes | `phi`, `non-phi` or `unsure` |
| Data leaves Meridian? | Yes | `no`, or the destination (e.g. an SMS vendor) |

**Variants seen elsewhere (out of MVP scope):** Redis and SQS (Care Notes), S3 buckets (Patient Messaging). **Ugly cases:** a database shared by two services, migrating an existing database, large sizes. All logged, none in the first slice.

### Output: stated as a guarantee

> If a valid request is accepted, the platform ensures a private Postgres database exists for that service, encrypted at rest with a managed key and in transit (TLS enforced), with 35-day backups, access logging on, cost and ownership tags, credentials delivered as a managed secret the service can read, and an entry in the datastore inventory recording who asked, when, and its classification.

### Policy gates

| Gate | Kind | Owner |
|---|---|---|
| Encryption at rest and in transit | Hard: always applied | Security & Compliance |
| No public access | Hard: always applied | Security & Compliance, Cloud Ops |
| Backups, 35-day retention | Hard: always applied (**was tribal knowledge**) | Security & Compliance |
| Access logging | Hard: always applied | Security & Compliance |
| Cost and ownership tags | Hard: always applied (**was tribal knowledge**) | Cloud Ops |
| Data leaves Meridian, or classification `unsure` | Judgment: a human reviewer decides | Security & Compliance |

## 2. Perfect world (the automation ceiling)

Ignoring every constraint: the developer writes code; the platform reads the service's schema and code, works out whether it holds PHI, provisions a compliant database instantly, approves itself, and the service just connects. No form, no ticket, no human, seconds.

## 3. Reintroduce reality

**Technical check.** Automatically classifying PHI from code and schemas is not reliable enough: fields like `notes` or `metadata` can hold anything (the "attachments as metadata" case shows this). An AI classifier would give inconsistent answers on borderline cases, and its mistakes would be invisible.

**Organizational check.**
- Accountability for the classification of patient data can't be delegated to a machine; Raj's team remains accountable.
- The judgment cases (data leaving Meridian) genuinely need a human.
- MVP scope: non-production, no central policy engine, no identity or state system, about two weeks to build.

**Key design insight.** The incentive to under-classify exists because classification changes *speed*: "PHI" means the slow review. If **every** datastore gets the full PHI-grade defaults regardless of its label, the label no longer changes how fast you get your database, so there's nothing to gain by mislabelling. Classification is still recorded (Raj's visibility need), but it stops being a toll gate. The extra cost of encrypting non-PHI data is negligible.

## 4. Options

| Option | What it is | Technical stability | Compliance | Auditability | Fits ~2 weeks | Friction removed |
|---|---|---|---|---|---|---|
| **A. Fully automated** | AI classifies data, platform self-approves everything | Low | Fails: accountability delegated | Low | No | Highest, in theory |
| **B. Self-service with policy engine** | Request form, central policy engine evaluates rules, security dashboard, automated approvals | High | Good | High | **No**: and a central policy layer is Production Readiness scope | High |
| **C. Declare and provision** | Developer declares the datastore in a short request file; the path applies PHI-grade defaults to every datastore, provisions it, delivers the secret and records it; judgment cases are flagged to a reviewer (in the MVP sandbox, with synthetic data only, provisioning still proceeds; before production they will block) | High | Good: humans keep the judgment cases | Good: every request is a reviewed, recorded change | **Yes** | Most of it: ~8 in 10 requests need no human |

**Force-ranked by impact within two weeks:** C, then B (later, in Production Readiness), then A (rejected).

## 5. Chosen with the user

**Option C**, shown to the Appointments engineer and to Raj's reviewer.

| Who | Concern | Response |
|---|---|---|
| Appointments engineer | "Do I need to learn Terraform?" | No. The request file has seven fields; the platform owns the implementation |
| Appointments engineer | "Can I get a database before we decide on PHI?" | Yes: `unsure` still provisions with full defaults in the sandbox and flags the review in parallel |
| Security reviewer | "How do I see where PHI lives?" | Every request lands in a datastore inventory with its classification. Agreed to review judgment cases from that inventory |

Both confirmed it would materially improve the situation. **Interface for the MVP: an expert interface** (a request file submitted as a pull request to the platform repository). A workflow-embedded interface comes later, once the capability is proven stable.
