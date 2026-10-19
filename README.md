# meridian-platform

An Internal Developer Platform for Meridian Health, a fictional healthcare company.
This is a portfolio project: it works through the design and construction of a
platform as a product, from discovery to a production-ready system, following
*Thinking in Platforms* (Kaspar von Grünberg & Luca Galante) and the
[PlatformEngineering.org](https://platformengineering.org) AWS reference
architecture. The repository is the record of that journey — the reasoning,
the decisions and the artefacts — not just the code that came out of it.

## Journey

### Lesson 0

Before any platform work, Meridian Health was read as a system rather than as a
backlog. The [diagnosis](docs/00-context/diagnosis.md) found a hero-based core
wrapped in bureaucratic gates: shipping depends on a handful of people who hold
the knowledge, while the controls meant to make the organization safe — the Data
Protection Review above all — are slow enough that teams quietly route around
them, which makes it less safe rather than more. The CTO's answer to this was a
mandate to adopt Backstage. That mandate was answered not with a portal but with
a request for discovery time first: a tool chosen before the paths are known
would pave the hero-based core instead of replacing it. The full reading is in
[Lesson 0: Seeing the System](docs/00-context/lesson-0-seeing-the-system.pdf).

### Stage 1 — Getting Started

**Discovery, round 1.** Five simulated interviews with backend developers across
Appointments, Care Notes, Pharmacy Connect, Patient Messaging and Lab Results,
each anchored on one real recent piece of work. Every team described the same
low-resolution value stream — shape the work, set up, build and test, ship, run —
and four of the five pointed at *set up* or *ship* as the phase that hurts;
writing the code was never the problem. The central finding is that "get a
database" and "get through Data Protection Review" are not two intents but one:
developers need a datastore they are allowed to put patient data in, which makes
the review a policy gate inside that path rather than a path of its own — and
one team had already started routing around the gate by describing an
attachments bucket as metadata. Three path candidates came out of the round
(compliant datastore, new service to environment, realistic test environment);
three intents tie on frequency, so the choice needed directional cost and a
team ranking.

**Control functions and path selection.** Security & Compliance, Cloud Ops and
SRE were interviewed after the users, to learn *why* each gate exists
([notes](docs/discovery/control-functions.md)). The Data Protection Review
turned out to be mostly a stable checklist, and the CISO's real need is
visibility of where PHI lives rather than a weekly meeting. Each candidate became
a [path record](docs/paths/README.md) with a directional cost of inactivity:
about €130,800 a year as a lower bound. [ADR-0001](docs/adr/0001-select-mvp-paths-and-first-team.md)
proposes the three MVP paths in build order (compliant datastore, service to
environment, test environment), Appointments as the first team after a
[force-ranking](docs/discovery/team-ranking.md), and a three-person build crew.
The [service lifecycle value stream](docs/value-streams/service-lifecycle.md)
is now mapped, with the three MVP paths placed at the recurring moments that
trigger them and a gaps table recording the friction the MVP deliberately
leaves uncovered. See [docs/discovery/](docs/discovery/) for the notes and
[synthesis](docs/discovery/synthesis.md).

### Stage 2 — MVP

### Stage 3 — Production Readiness

### Stage 4 — Scaling
