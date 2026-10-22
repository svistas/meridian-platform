---
status: accepted
date: 2026-10-22
decision-makers: Sofia Vistas
consulted: Patient Messaging team, SRE (simulated)
---

# Design of path 02: declare and deploy, with runtime rules checked before deploy

## Context and Problem Statement

Path 02 must let a developer get a new service running without a hand-off to one SRE. The [deep dive](../paths/02-service-to-environment-design.md) reconstructed the inbox service's first deploy: ~2 weeks, ~16 hours of developer effort, ~8 hours of the SRE's time, and three unwritten rules discovered by failing. Path 01 also left a gap: its databases can't be reached until services run next to them.

## Decision Drivers

* No single person on the critical path.
* Unwritten runtime rules become explicit and are checked before anything runs.
* One interface pattern across paths.
* Public exposure stays a human judgment.
* Buildable in about two weeks inside MVP scope.

## Considered Options

* A. Fully inferred deployment
* B. A shared Helm template for teams to copy
* C. Declare and deploy: a short service file in a pull request, a platform-owned build workflow and deploy recipe

## Decision Outcome

Chosen option: **C**, because it is the only option that is stable, removes the hand-off and copy-paste CI, and fits the MVP.

* The request names: service, team, image source repository, port, health-check path, size, optional path 01 datastore, exposure (`internal` default, `public` flagged).
* Runtime rules are hard defaults: own identity, non-root, resource limits, approved registry, JSON logs, health check passing before "done".
* The pull request checks the service's Dockerfile and declared health endpoint before deploy, so the three rules that broke the inbox deploy fail early and clearly.
* Same expert interface as path 01: a file in a pull request.
* The runtime (EKS or ECS on Fargate) is a separate decision: the promise does not depend on it.

### Consequences

* Good, because path 02 closes path 01's "can't connect yet" gap.
* Good, because the SRE's knowledge becomes versioned defaults he can review.
* Good, because developers learn one interface for both paths.
* Bad, because services need a Dockerfile and a health endpoint first; those without one must add them.
* Neutral, because paging and on-call are deferred to Production Readiness.

### Confirmation

Path validation interview with Patient Messaging after the build, measured against the 24-hour baseline in the [path record](../paths/02-service-to-environment.md).
