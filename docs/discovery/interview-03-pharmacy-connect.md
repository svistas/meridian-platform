# Interview 03: Pharmacy Connect team

> **Simulated interview.** Fictional company and interviewee.

## A. Orientation

| Field | Notes |
|---|---|
| Team | Pharmacy Connect (prescription refill routing to partner pharmacies) |
| Role (title only) | Backend engineer |
| Type of work | Maintaining partner integrations |
| Concrete example (their words) | "Last quarter we had to rotate the API keys for all four pharmacy partners." |
| Interview type | Exploratory (discovery) |

## B. Value stream sketch

Their value stream is dominated by **Run**: keeping partner integrations healthy. Phase chosen for depth: **Run**.

## C. Friction and intent landscape

| Step | Friction point (observation) | Type | Intent |
|---|---|---|---|
| Run | Partner pharmacy sandboxes are down often; testing blocked for hours | External dependency (outside Meridian) | Test against a partner without depending on their sandbox |
| Run | Key rotation: new keys from partners by email; ticket to Cloud Ops to update Secrets Manager; restart services by asking Tomás; ~2 days across four partners | External dependency | Rotate a credential safely without downtime |
| Run | Nobody is sure which services read which secret | Internal non-core work | Know what depends on this credential |

## Directional cost (their estimates)

- Rotation: quarterly, **~1 day** of engineer effort plus Cloud Ops and Tomás time each round.
- Sandbox outages: "a few hours a week, but that's the partners' problem."

## E. Team signals

| Signal | Observation |
|---|---|
| Frequency | Rotation quarterly; sandbox issues weekly |
| Variability | High: each partner works differently |
| Existing workarounds | Spreadsheet of which key goes where |
| User openness | Friendly, but most pain is outside Meridian |
| Cross-team impact | Medium |

## Interviewer notes

- The loudest pain (partner sandboxes) is **outside what a Meridian platform controls**. Logged, not a path candidate. The book's warning applies: strong emotion does not equal platform-relevant impact.
- The quieter pain (credential rotation, and not knowing who depends on a secret) does recur and is internal.
- High partner variability makes this a weaker first team even though the people are open.
- Referred us to: Patient Messaging.
