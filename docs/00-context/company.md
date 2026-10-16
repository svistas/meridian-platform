# Company dossier: Meridian Health

> **Fictional company.** Designed for this portfolio so that it shows signals of all three non-platform production systems described in *Thinking in Platforms*, Part 1.

## At a glance

- Founded 2018, offices in Lisbon and Boston
- ~600 employees, **110 engineers in 14 product teams**
- Fully on AWS under a signed Business Associate Agreement (BAA)
- Regulated: HIPAA applies, SOC 2 Type II held, HITRUST certification in progress

## Products

| Product | What it does |
|---|---|
| Patient app | Booking, health records and messaging for patients on mobile |
| Clinician portal | Web workspace where care teams review patients and document visits |
| Telehealth | Video visits between patients and clinicians |
| Prescription refills | Refill requests routed to partner pharmacies |
| Claims and billing | Insurance claims, invoicing and payments |
| EHR Integration Hub | FHIR and HL7 data exchange with partner hospitals |

## How software reaches production today

| Area | What happens | What it costs |
|---|---|---|
| Compute | Half the services on EKS (migration stalled), the rest on ECS, three legacy EC2 services | Two platforms to run; nobody owns finishing |
| CI | Every team writes its own GitHub Actions; billing still runs Jenkins | 14 ways to build the same thing |
| Infrastructure | A Jira ticket to the three-person Cloud Ops team | Median 9 business days per resource |
| Production deploys | Helm charts and shell scripts written by one senior SRE, Tomás | Releases pause when he is away |
| Security review | Data Protection Review: a form, then a weekly review board | Median 12 business days |

## Signals

- **5 weeks** for a new engineer to ship a first production change
- **SOC 2 audit finding:** nobody could show who changed a production S3 bucket policy, or why
- **"Not PHI":** teams describe new resources as holding no patient data to skip the 12-day review

## People around the platform

| Who | Position |
|---|---|
| Helena, CTO | Wants "a developer portal like Spotify's". Mandate: Backstage live by end of Q2, four headcount, KPIs on deployment frequency |
| Raj, CISO | Believes healthcare is too regulated to standardize; every review stays manual |
| Engineering managers (14 teams) | Measured on roadmap delivery; want to be left alone to hit their dates |
| Lead Platform Engineer (the author) | Newly hired. No team yet, no paths yet, and a mandate they didn't write |

## Why the company is shaped this way

- **Size:** inside the boundary where an open-source IDP approach fits (more than 50 developers, existing Kubernetes workloads, basic CI), and large enough that "start with one team" is a real choice.
- **Regulation:** raises the stakes on the enterprise components the book introduces for production: identity, policy and state.
- **The mandate:** mirrors the book's US insurance case (a top-down mandate, optimistic KPIs, a tool-first plan).
