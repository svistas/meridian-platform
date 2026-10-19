---
status: accepted
date: 2026-10-19
decision-makers: Sofia Vistas
consulted: Appointments team, Security & Compliance (simulated)
---

# Design of path 01: declare and provision, with PHI-grade defaults for every datastore

## Context and Problem Statement

Path 01 must give developers "a datastore I'm allowed to put patient data in" without two queues and weeks of waiting, while Security & Compliance keeps accountability and visibility. The [deep-dive](../paths/01-compliant-datastore-design.md) reconstructed the last real request: ~3.5 weeks, ~12 hours of developer effort, and four unwritten rules. How should the MVP path work?

## Decision Drivers

* Technical stability: identical requests must produce identical, compliant outputs.
* Policy compliance: humans stay accountable for classification judgment cases.
* Auditability: every datastore must be findable with its classification (the CISO's need).
* Buildable in about two weeks, inside the MVP scope (no central policy engine, identity or state).
* Remove the incentive to under-classify data.

## Considered Options

* A. Fully automated: AI classifies data and the platform self-approves
* B. Self-service with a central policy engine and approval dashboard
* C. Declare and provision: a short request file; PHI-grade defaults applied to every datastore; judgment cases flagged to a human

## Decision Outcome

Chosen option: **C**, because it is the only option that is technically stable, compliant and buildable within two weeks, and it removes most of the friction: about 8 in 10 requests need no human.

The defining choice: **every datastore gets PHI-grade defaults** (encryption at rest and in transit, no public access, 35-day backups, access logging, cost and ownership tags), whatever its classification. Classification is still required and recorded, but no longer changes how fast a developer gets a database, so mislabelling gains nothing.

MVP interface: an **expert interface**, a request file submitted as a pull request to the platform repository. Engine: Postgres only. Environment: sandbox only, synthetic data only.

### Consequences

* Good, because the incentive to under-classify disappears.
* Good, because four unwritten rules (35-day backups, TLS enforcement, cost center and ownership tags, review applies to every environment) become explicit, versioned defaults.
* Good, because the reviewer's time moves to the genuine judgment cases.
* Bad, because non-PHI datastores carry slightly more cost (encryption, longer backups). Accepted as negligible.
* Bad, because rules are hard-coded in the path for now. Knowingly throwaway: a separate, Security-owned policy layer replaces this in Production Readiness.
* Neutral, because the pull-request interface suits developers but not other personas; a workflow-embedded interface comes after the capability is stable.

### Confirmation

Path validation interview with the Appointments team after the build: time per run measured against the 19-hour baseline in the [path record](../paths/01-compliant-datastore.md).

## Pros and Cons of the Options

### A. Fully automated

* Good, because it is the automation ceiling.
* Bad, because classifying PHI from code is not reliable, and accountability can't be delegated.

### B. Central policy engine

* Good, because it is the long-term shape: rules owned and versioned by Security.
* Bad, because it is too large for two weeks and belongs to Production Readiness.
