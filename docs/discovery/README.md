# Discovery (Stage 1: Getting Started)

> **All interviews in this folder are simulated.** Meridian Health is a fictional company and the interviewees are fictional characters, played by an AI mentor. The method follows the discovery interview approach in *Thinking in Platforms* (von Grünberg & Galante), Part 3, "Starting a platform initiative".

## Goal of this round

Learn how work actually happens today, so that the organization reveals its first path candidates. Three questions to answer by the end of the round:

1. Which recurring intents are worth turning into the first three paths?
2. Roughly what does it cost Meridian *not* to have those paths?
3. Which team is a good first team for a Minimum Viable Platform?

This round is **not** validation, buy-in, or design. No solutions were proposed in any session.

## Who we talked to, and why

Persona: **backend service developer** (same persona and similar focus across all five, so patterns can be compared).

Selection: we asked engineering managers *"Which teams are most representative of how work typically happens here?"* and avoided:

| Team | Why not this round |
|---|---|
| Claims & Billing | Outlier stack (Jenkins); patterns would not generalize |
| EHR Integration Hub | Most advanced team, with its own tooling; not representative |
| Telehealth | Specialized real-time video infrastructure |

## Interview log

| # | Team | Role | Concrete example anchored on | Notes |
|---|---|---|---|---|
| 01 | Appointments | Backend engineer | Launching the appointment-reminders service last month | [interview-01-appointments.md](interview-01-appointments.md) |
| 02 | Care Notes | Senior backend engineer | Adding a cache and a queue for note autosave | [interview-02-care-notes.md](interview-02-care-notes.md) |
| 03 | Pharmacy Connect | Backend engineer | Last quarter's partner API credential rotation | [interview-03-pharmacy-connect.md](interview-03-pharmacy-connect.md) |
| 04 | Patient Messaging | Backend engineer | First deploy of the new inbox service | [interview-04-patient-messaging.md](interview-04-patient-messaging.md) |
| 05 | Lab Results | Backend engineer (joined 2 months ago) | Shipping a first production change | [interview-05-lab-results.md](interview-05-lab-results.md) |

Synthesis across all five: [synthesis.md](synthesis.md)

## Session setup (used in every interview)

- 60 minutes, one interviewer leading, one note-taker. Recorded with consent.
- Notes captured immediately after each session; **observations kept separate from interpretation**.
- Scripted opening (below) used verbatim for consistency.
- Ideas or feature requests that came up were noted briefly, never discussed.
- Every session ended with: *"Who else should I talk to, to understand how work happens here?"*

### Scripted opening

> Thanks for making time. I'm trying to understand how work actually happens here day to day, especially the parts around your code: getting things set up, tested, shipped and running. This isn't an evaluation of you or your team, and I'm not here to pitch anything. I'll mostly listen. If it's OK, I'd like to anchor on one real, recent piece of work and walk through it step by step. We have an hour; I'll keep us on time. Is it OK if we record so I can focus on listening?

## Templates

Notes use the structure of the book's appendix templates: interview orientation (A), value stream sketch (B), friction and intent landscape (C), path anchor (D1), and team signals (E).
