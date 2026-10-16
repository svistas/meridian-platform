---
status: accepted
date: 2026-10-16
decision-makers: Sofia Vistas
---

# Record architecture decisions

## Context and Problem Statement

This project builds an Internal Developer Platform for a fictional healthcare
company as a portfolio piece. Its value lies as much in the reasoning behind each
choice as in the artefacts produced. Without a written record, the rationale for
a decision is lost the moment it is made, and later readers — including the
author — cannot tell what was deliberate from what was accidental. How should
significant decisions be captured so that the reasoning survives alongside the
result?

## Decision Drivers

* The journey, not only the end state, is the deliverable.
* Decisions must be reviewable in isolation and in sequence.
* The record should live with the code, in version control, in plain text.
* Overhead must stay low enough that the habit survives all four stages.

## Considered Options

* MADR — Markdown Any Decision Records, in `docs/adr/`
* Nygard-style lightweight ADRs
* A decision log in a single running document
* No formal record; rely on commit messages and prose in the README

## Decision Outcome

Chosen option: "MADR — Markdown Any Decision Records, in `docs/adr/`", because it
keeps the record in version control next to the work, gives each decision a
stable identifier that other documents can cite, and its optional sections let a
small decision stay short while a consequential one gets the full treatment.

### Consequences

* Good, because every significant decision has a durable, linkable home.
* Good, because the sequence of ADRs becomes a readable narrative of the journey.
* Good, because superseded decisions remain visible rather than being edited away.
* Bad, because it adds a writing step to each decision, which must be sustained.
* Neutral, because it requires judgement about what counts as "significant".

### Confirmation

Each stage is reviewed for decisions taken without a corresponding ADR; any
found are recorded retroactively with their original date noted.

## Pros and Cons of the Options

### MADR — Markdown Any Decision Records

* Good, because the template prompts for drivers, options and consequences.
* Good, because sections are optional, so the format scales with the decision.
* Good, because it is widely recognised and needs no explanation to a reader.
* Neutral, because the YAML frontmatter is convention rather than tooling.

### Nygard-style lightweight ADRs

* Good, because it is the smallest format that still captures rationale.
* Bad, because it does not prompt for alternatives considered, which is often
  the most useful part of the record.

### A single running decision log

* Good, because there is only one file to open.
* Bad, because decisions cannot be cited individually or superseded cleanly.
* Bad, because the document grows unreviewable.

### No formal record

* Good, because there is no overhead.
* Bad, because the rationale is lost, which defeats the purpose of the project.

## More Information

Template: [MADR 4.0.0](https://adr.github.io/madr/). Subsequent records follow
the same structure and are numbered sequentially from `0001`.
