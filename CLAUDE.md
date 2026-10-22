# meridian-platform

An Internal Developer Platform for Meridian Health, a fictional healthcare
company. Portfolio project following *Thinking in Platforms* (von Grünberg &
Galante) and the PlatformEngineering.org AWS reference architecture.

## Rules

### Current stage: Stage 2, MVP (non-production)

ADR-0001 is accepted. Build the MVP paths in order, one at a time.

Path 01, the compliant datastore, is **validated**: it ran for real, all
guarantee checks passed, and the removal path was exercised. Path 02, service
to environment, is **in progress** -- designed in ADR-0005, with ADR-0006
settling that it runs on ephemeral EKS sessions. Path 03 is **not started**.

- Non-production only: a local cluster or a sandbox account, never production.
- Do NOT add identity, a central policy engine or state yet. Security rules
  are defaults inside the path itself (the book's MVP scope).
- Do not design for reusability across paths; the MVP may be thrown away.
- Build the capability behind a simple expert interface first (e.g. a script
  or repository convention); a workflow-embedded interface comes later.
- Synthetic data only.

### Vocabulary

Use the paths-to-outcome vocabulary from `docs/glossary.md` consistently — value
stream, path, interface, capability (promise / implementation), output,
identity, policy, state, golden path, MVP, production system. Do not substitute
near-synonyms from other frameworks when a glossary term exists. If a needed
term is missing from the glossary, add the heading and flag it rather than
inventing a parallel vocabulary.

### No real PHI

Never use or generate real protected health information. All sample data must be
synthetic — Synthea or equivalent. This holds for examples in prose, fixtures,
diagrams and screenshots alike.

### Simulated interviews

Interviews in `docs/discovery/` are simulated, not conducted with real people.
Label each one as such at the top of the file, and never present simulated
findings as field research.

### Decisions get ADRs

Every significant decision gets an ADR in `docs/adr/`, following the MADR
template established in `0000-record-architecture-decisions.md`, numbered
sequentially.
