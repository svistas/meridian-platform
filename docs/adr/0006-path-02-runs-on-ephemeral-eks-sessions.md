---
status: accepted
date: 2026-10-22
decision-makers: Sofia Vistas
---

# Path 02 runs on Amazon EKS, created per working session

## Context and Problem Statement

[ADR-0005](0005-service-to-environment-path-design.md) defines path 02's promise without naming a runtime. Meridian runs services on both EKS and ECS. An EKS control plane costs about USD 73 a month on its own, and private compute also needs internet egress (a NAT gateway or VPC endpoints), which costs tens of dollars a month if left running. The sandbox budget is USD 20 a month. Where do path 02's services run, and how is cost contained?

## Decision Drivers

* Fidelity to how Meridian runs services (Tomás's Helm-based EKS setup).
* Kubernetes experience as a portfolio goal.
* Stay within the sandbox budget.
* Keep CI roles narrow: CI should not gain rights to create clusters or IAM roles for nodes.

## Considered Options

* ECS on Fargate, always on
* EKS, always on
* EKS, created for a working session and destroyed afterwards

## Decision Outcome

Chosen option: **EKS, created per working session**, because it gives full Kubernetes fidelity while keeping cost to roughly a dollar or less per hour of use.

* A separate Terraform root, `platform/runtime/`, holds everything that costs money by the hour: the EKS cluster and its nodes, a public subnet with an internet gateway, and one NAT gateway. A human brings it up and down locally (`session up` / `session down`), like the bootstrap.
* Things that should survive between sessions (container registries, service IAM roles) live outside the session stack.
* The cluster enforces the runtime rules too: namespaces use the Kubernetes **restricted** Pod Security standard, so a root container is rejected by the cluster even if a check is missed.
* Services get their AWS identity through **EKS Pod Identity**, one IAM role per service.
* CI deploys to the cluster through an EKS access entry for the apply role. The cluster API endpoint is public with IAM authentication, since GitHub-hosted runners have no fixed addresses.

### Consequences

* Good, because the bill stays near zero between sessions.
* Good, because the cluster rejects non-compliant workloads on its own (defense in depth).
* Bad, because merging a service request while no session is running can't deploy; the apply workflow must say so clearly instead of failing obscurely.
* Bad, because a public API endpoint and broad cluster permissions for the apply role are **known debt**. Production Readiness moves to a private endpoint and a pull-based GitOps deployment (as in the AWS reference architecture), with narrower permissions.
* Neutral, because the path's promise is unchanged; moving to ECS later would change only the implementation.

### Confirmation

`session down` leaves no hourly-billed resource behind: no cluster, no nodes, no NAT gateway, no load balancer. Checked with the AWS CLI after each session.
