# meridian-platform

An Internal Developer Platform for Meridian Health, a fictional healthcare
company. Portfolio project following *Thinking in Platforms* (von Grünberg &
Galante) and the PlatformEngineering.org AWS reference architecture.

## Rules

### Current stage: Lesson 0

No platform code, infrastructure or tooling until a path has been selected
through discovery and recorded in `docs/paths/`. Writing, research, interviews
and diagrams are in scope; Terraform, manifests, pipelines, scaffolding and CLI
tools are not. If a task seems to need code, say what the missing discovery is
instead of writing it.

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
