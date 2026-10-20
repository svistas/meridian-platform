---
status: accepted
date: 2026-10-19
decision-makers: Sofia Vistas
---

# The MVP runs in a dedicated AWS sandbox account

## Context and Problem Statement

Path 01 must create real databases whose safety properties (encryption with a managed key, no public access, 35-day backups, TLS enforcement, logging, tags) can be checked, not just described. The MVP is non-production by design. Where should the MVP's resources live?

## Decision Drivers

* Fidelity: the guarantees in [ADR-0002](0002-compliant-datastore-path-design.md) must be real and verifiable.
* Alignment with the PlatformEngineering.org AWS reference architecture.
* Low and predictable cost for a portfolio project.
* No long-lived credentials anywhere.

## Considered Options

* A dedicated AWS sandbox account
* Local only (kind + a Postgres operator)
* LocalStack

## Decision Outcome

Chosen option: **a dedicated AWS sandbox account**, because it is the only option where encryption keys, backups and network isolation are real and can be verified through the AWS API.

The account is not new: it reuses a personal AWS account opened in 2023 and used for Elastic Beanstalk, RDS, EKS and container experiments during 2024. Before the bootstrap was planned it was verified empty of the resources this path touches -- no RDS instances, clusters, snapshots, subnet groups or parameter groups in any region, no S3 buckets, no customer-managed KMS keys and no secrets -- and the leftover RDS service-linked role from 2024 was deleted so the bootstrap creates its own. One long-lived access key on an `admin` IAM user was deactivated, since this ADR rules out long-lived credentials. "Nothing else running in it" should therefore be read as verified for the services this path uses, not as a guarantee about every service in the account.

Guardrails:

* One region (`eu-west-1`), one account, nothing else running in it.
* A monthly budget with an alert at USD 20.
* Smallest instance class; no Multi-AZ; databases are destroyed after each demo.
* GitHub Actions authenticates through **OpenID Connect** to a narrowly scoped IAM role. No access keys stored anywhere.
* Terraform state in a versioned, encrypted S3 bucket with native S3 locking.
* Infrastructure changes are applied by CI after review, or by the platform lead locally for the one-time bootstrap. Coding agents write code and run plans; they don't hold administrator credentials.

### Consequences

* Good, because every guarantee is checked against real AWS resources.
* Good, because OIDC removes a whole class of leaked-credential risk from day one.
* Bad, because it costs money (roughly USD 15 a month per database if left running) and needs a teardown habit.
* Neutral, because this is still non-production: synthetic data only, and nothing here is reused as-is for production.

### Confirmation

The budget alert exists before the first database is created. The build brief's verification script runs after every apply.
