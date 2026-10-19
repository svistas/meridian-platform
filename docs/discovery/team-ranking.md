# Choosing the first team

> Based on the five **simulated** discovery interviews. Signals from *Thinking in Platforms*, "Choosing the first team".

The first team shapes the first paths, the platform's early reputation and the internal narrative. We force-rank at least three candidates, build with the first in mind, and keep the next two warm.

## Signals per candidate

| Signal | Appointments | Patient Messaging | Lab Results | Care Notes | Pharmacy Connect |
|---|---|---|---|---|---|
| Clear, recurring friction | Strong: all three paths | Strong: paths 01 and 02 | Medium: paths 02 and 03 | Strong: paths 01 and 03 | Weak: main pain is external |
| Representative setup | Yes: Node.js, Postgres, EKS | Yes: Node.js, Postgres, S3 | Yes | Yes | No: high partner variability |
| Moderate maturity | Yes | Yes | Yes | Yes | Yes |
| Important, not existential | Yes: patients can still book by phone | Yes, but sensitive (PHI attachments) | Yes | High stakes: clinical notes | Yes |
| Openness and stability | Open; offered to show tickets | Open, uneasy about the review | Very open; two new hires | Skeptical of tooling initiatives | Open |

## Force-ranked

1. **Appointments.** Feels all three MVP frictions, has the most typical stack, and was the most open. Booking matters but has a manual fallback, so there's room to iterate.
2. **Patient Messaging.** Same stack and strong friction on paths 01 and 02. Handle with care: the datastore path should *relieve* them, and their "metadata" admission must never be used to blame them.
3. **Lab Results.** Very open, and new joiners give honest feedback on path 02. Weaker on path 01.

**Not now:** Care Notes (high-stakes clinical data and visible skepticism make it a better second wave than a first experiment); Pharmacy Connect (its main pain is outside Meridian's control).

## The ask to Appointments

Almost nothing up front: no budget, no migration commitment. We build against the friction they described; their only investment is feedback in a few short sessions. If it helps, they choose to adopt it.
