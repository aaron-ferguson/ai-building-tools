---
id: "0111"
title: Give retro a resolution order for a workspace holding more than one backlog
type: bug
next: design
status: ready
qa_level: unit
size: m
created: 2026-09-07
source: retro
parent:
blocked_by: []
relates: ["0060", "0078", "0101"]
expects:
  - skills/retro/SKILL.md
  - references/CONVENTIONS.md
  - tests/retro-tool-edit.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` Step 1 names its input as a bare relative path and a singular, and says nothing about
what that path resolves against or what happens when it resolves to nothing.** The opening
sentence is *"`.claude/backlog/FINDINGS.md` is the input, and the only one"*.

**Measured 2026-09-07.** `/retro` was invoked from `/Users/aaronferguson/Documents/AI`, which is
not a git repository and holds no backlog, with four beneath it: `ai-building-tools` (22 entries,
2.75x this project's `findings_threshold: 8`), `ai-building-conventions` (3), `neumo_repos/Probation`
(4, all invalidated by that backlog's retirement on 2026-09-04) and `tools/jury-config` (0). The
pass swept all four, selecting them on freshness and threshold. **That was defensible and it was
invention** — no step licensed it, and a retro standing in the same place tomorrow has nothing to
reproduce the choice from, so the next pass either re-derives it or picks differently.

**The shape this lacks already exists one file away.** `references/CONVENTIONS.md` resolves the
conventions directory by a numbered ladder and **stops rather than guessing** when nothing
resolves. Step 1 has neither the ladder nor the refusal, and it is the same class of question:
*which instance of a per-project file does this session act on.*

The invocation directory being a workspace root rather than a project root is not exotic here — it
is where this user starts sessions, and it is where `queue` landed too on the same day.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — Step 1 states where `.claude/backlog/FINDINGS.md` resolves from, as a numbered order rather
  than a bare relative path.
- FR2 — The order covers the invocation directory being neither a repo nor a backlog root, which is
  the case that produced this and the one a bare relative path silently fails on.
- FR3 — Nothing resolving stops the session with a report naming what was searched — the same
  refusal `CONVENTIONS.md` already makes, **cited rather than restated**, so the two cannot drift.
- FR4 — A retired backlog is not swept as though it were live. `Probation`'s `QUEUE.md` opens with a
  retirement banner and its four entries were all invalidated by it; the order says how a session
  tells, or says explicitly that it does not and why that is acceptable.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The order must not license carrying a finding from a company-tracked project into this repo, which is public. `Probation` routes to Jira under company policy and `ai-building-tools` is public; a rule that sweeps both in one pass is one step from writing one into the other. Say so where the order is stated. | `data-privacy-conventions.md` |
| Documentation | `CONVENTIONS.md`'s ladder and refusal are cited, never copied. Two ladders that must agree is the drift this repo has already paid for. | `documentation-conventions.md` |

## Open design question

- **Question:** When more than one backlog is in reach of an invocation, does a retro sweep exactly
  one — and if so, which — or all of them?
- **Why it blocks specification:** the acceptance criteria differ entirely and are mutually
  exclusive. *Exactly one* makes the ladder a resolution and the ACs assert a single chosen buffer
  and a refusal when the choice is ambiguous. *All of them* makes it a discovery and the ACs assert
  a per-buffer disposition, an ordering across buffers, and a report that names every one visited —
  and it drags in `findings_threshold`, which is per-project. Nothing can be written about which
  buffer was swept until this is answered.
- **Settle it with:** `/design` — the inputs are Step 1, `references/CONVENTIONS.md`'s ladder,
  `config.yml`'s `findings_threshold`, and `0078`'s subject-routing rule. Nothing needs to be seen.

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 1, when read, then it states a numbered resolution
  order for locating the buffer. Red when the order is deleted or reduced back to the bare relative
  path.
- [ ] AC2 — Given Step 1, when read, then it states that a session which resolves nothing stops and
  reports what it searched. Red when the refusal sentence is removed — and note the discriminating
  case: a rule saying only *"read the buffer"* satisfies no assertion here while reading as correct.
- [ ] AC3 — Given a guard anchored to Step 1 rather than to the file, when the resolution order is
  moved out of Step 1 into any other step, then the guard reds. This is the house rule in
  `tests/retro-tool-edit.test.sh` — a file-wide grep stays green on a rule moved out of the step
  that has to obey it.
- [ ] AC4 — Given the privacy clause under NFR *Privacy & data*, when it is deleted, then a guard
  reds on its own, separately from AC1's.

## QA plan

- **Why that level:** the deliverable is prose in one skill, and every guard in this repo greps
  prose; `unit` runs `tests/*.test.sh`, which is the only runner here.
- **Specific checks:** extend `tests/retro-tool-edit.test.sh`, whose cases are already section-scoped
  to `retro`'s steps and whose header states the anchoring rule AC3 depends on. One assertion per AC,
  each anchored to Step 1's window. Prove each can fail by deleting the sentence it matches and
  reverting. **Match a phrase short enough to sit on one source line** — `grep` is line-based and
  this file is wrapped prose.

## Out of scope

- **What the findings gate counts when a workspace holds several buffers.** `findings_threshold` is
  per-project, so four buffers at 6 entries each never trip a gate while the workspace holds 24
  unswept findings. That is a real defect and it belongs to **0060**, which owns the decision about
  what the gate counts; this sweep recorded it in 0060's open design question rather than here.
- **Routing a finding to the repo it is about** — 0078. That decides where a finding is *written*;
  this decides which buffers a retro *reads*. They meet at 0078's FR5 and neither subsumes the other.
- Changing `CONVENTIONS.md`'s own ladder.

## Notes & decisions

- **Routed to `design`, not `develop`.** The FR-level shape is clear and the precedent file is
  named, but the one thing every AC turns on — one buffer or all — is a decision, not a fact
  discoverable by reading the code. Guessing it is how a ticket gets built to a contract nobody
  agreed to.
- **No sibling FR naming implementing code, deliberately.** Step 1 is executed by the agent reading
  it; nothing in `./next` or the backlog scripts discovers buffers, so there is no code that
  implements this rule and the guard is the only executable artefact. Saying so here so a reviewer
  applying `queue`'s *an FR describing a rule needs an FR naming what executes it* does not read the
  absence as an oversight.
- Captured from `FINDINGS.md` 2026-09-07, parked by the retro pass that hit it.
