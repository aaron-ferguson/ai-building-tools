---
id: "0026"
title: Re-run the measured end-to-end exercise and record the verdict
type: chore
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0009"
blocked_by: ["0022"]
relates: ["0025"]
expects:
  - .claude/backlog/items/0009-one-skill-per-session.md
  - README.md
claimed_by:
claimed_at:
touches:
---

## Problem

Effort 0009 opened with a measurement and committed to closing with one: *"re-run the same end-to-end
exercise against a fresh project and compare cost per turn and context per turn, not just the total."*
Eleven of its twelve tasks closed on 2026-08-23. **The run has not happened.**

So the number the whole effort was justified by — **~$5.09 against $15.11** — is still modelled, not
observed. Every ticket in the effort cited it. Nothing has tested it. Until it is run, the honest status
of the effort is "the workflow changed as designed" and not "the workflow is cheaper", and those are
different claims.

There is a second reason this cannot wait long: the comparison is against a specific run on **2026-08-22**
against a specific project. Every week of drift in the skills, the conventions and the model makes that
baseline a weaker control, and the comparison is the entire deliverable.

## Functional requirements

- FR1 — Run the same end-to-end exercise the 2026-08-22 baseline used: a fresh project, wired to the
  conventions, taken from nothing through `queue → develop → verify` to at least one closed ticket, under
  one-skill-per-session with each skill in its own session.
- FR2 — Record **cost per turn** and **context tokens per turn**, per skill, not just the totals. The
  baseline's finding was a *shape* — the price of a turn doubled across the run while the work stayed the
  same kind — and a total cannot show that.
- FR3 — Record it where the claim is made: the figures land in `0009`'s outcome section and in the
  `README.md` paragraph that currently states the modelled figure, replacing "modelled" with what was
  observed.
- FR4 — **Record the verdict even when it is "it didn't work."** State plainly whether the saving
  materialised, partly materialised, or did not, and by how much against the modelled ~$5.09.
- FR5 — Report **effectiveness alongside cost**, because 0009's own commitment was that effectiveness must
  not be traded for it. The baseline run caught a zip-bomb vulnerability every acceptance criterion passed
  over, and a test that stayed green with the guard it existed for deleted. Note what this run caught, and
  what it missed that the baseline caught.
- FR6 — Produce the per-gate figure `0025` needs: the cost of a session taking several related tickets
  against the modelled cost of taking them one per session.
- FR7 — Note what the two runs did **not** hold constant — skill versions, conventions, model, project
  domain — so a later reader can weigh the comparison rather than trusting it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The verdict is recorded whether or not it is the hoped-for one, and the figures carry their date and what was not held constant. | `documentation-conventions.md` |
| Privacy & data | The fresh project is synthetic or non-sensitive. A measurement run must not put real customer or case data through a model to produce a cost figure. | `data-privacy-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the recorded result, when read, then it reports cost per turn and context tokens per
      turn broken down by skill, for a run of at least one ticket taken end to end.
- [ ] AC2 — Given `0009`'s outcome section, when read, then the observed figure has replaced the modelled
      one and the word "modelled" no longer describes it.
- [ ] AC3 — Given `README.md`, when read, then its one-skill-per-session paragraph cites the observed
      figure with its date.
- [ ] AC4 — Given the recorded result, when read, then it states the verdict explicitly — materialised,
      partly, or not — against ~$5.09, and says what was caught and what was missed.
- [ ] AC5 — Given the recorded result, when read, then it names at least two things the two runs did not
      hold constant.
- [ ] AC6 — Given the recorded result, when read, then it carries the per-gate batching figure 0025's FR4
      cites.

## QA plan

- **Level:** verify — a measurement and a written record; no runner applies.
- **Scripted assertion:** `grep` the recorded result for a per-skill breakdown, a `20[0-9][0-9]-` date, the
  string `5.09`, and an explicit verdict word; `grep -c 'modelled' README.md` against the count before the
  change, so a stale claim left in place fails rather than passing quietly. AC4 and AC5 are asserted
  separately from AC1 because a run that produces figures and no verdict is the likely outcome, and it is
  the one this ticket exists to prevent.

## Out of scope

- Changing anything in response to the result. If the saving did not materialise, that is a finding and a
  new ticket, not a scope extension of this one.
- Re-measuring the pre-isolation baseline. The 2026-08-22 run is the control, with FR7 recording its
  limits.

## Notes & decisions

- **Blocked on 0022, and it is a real dependency rather than an ordering preference.** This run scaffolds
  a fresh backlog, and `queue` Step 0 copies `claim` into it — which currently refuses every row against
  the pared five-column table. The run would fail at its first claim, and the failure would look like the
  workflow rather than the script.
- **The kill criterion this ticket also settles.** 0016's FR5 carried one — drop the approval-gate reorder
  if an isolated batch retro measures under $1.50 — that could not be evaluated because no isolated batch
  retro had ever been run. If this exercise includes a retro session, record its cost and settle that
  criterion here rather than leaving it deferred a second time.
- FR4 exists because a measurement whose verdict is only recorded when favourable is not a measurement.
  `measurement-conventions.md` already requires the verdict be recorded even when it is "it didn't work";
  this FR is the citation, not a new rule.
