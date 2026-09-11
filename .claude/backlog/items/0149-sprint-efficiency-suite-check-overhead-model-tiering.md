---
id: "0149"
title: Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering
type: chore
next: design
status: ready
qa_level: review
close_by: verify
size: m
created: 2026-09-10
source: user
parent: "0128"
blocked_by: []
relates: ["0135"]
expects:
  - skills/sprint/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/MEASUREMENT.md
claimed_by:
claimed_at:
touches:
---

## Problem

A sprint dispatches develop and verify as sequential sessions, each paying the full per-session
startup cost before doing any work. Three categories of redundancy are worth examining before
the sprint skill is considered finished:

**Suite-check redundancy.** `develop` Step 5 runs the project's whole test suite to leave the tree
green before handing off to verify. In a sprint, verify guarantees the tree is green when it
closes a ticket, so the *next* develop session's pre-handoff suite run is checking a tree whose
greenness is already guaranteed by the previous cycle. A sprint could run the suite once before
dispatching the first develop session and rely on the dev/verify invariant for every subsequent
one — but the mechanism for signalling develop to skip that check (and the risk if the invariant
does not hold) is an open design question.

**Per-agent overhead.** Each develop and verify session independently performs steps that are
either shared-cost across a gate (conventions loading, git fetch, staleness greps) or are
pre-conditions that a sprint could establish once. No catalogue of these steps against sprint's
dispatch model exists, so it is unknown how many are actually skippable without changing the
independence property the two-stage model relies on.

**Model tiering.** The sprint supervisor's own work is routing: read an outcome, call `./next
--drive`, log an event, dispatch the next session. That is qualitatively different from the
thoughtful implementation work develop does. If the supervisor's sessions could run on a cheaper
model (haiku), and if any stage is mechanical enough that haiku handles it without quality loss,
the per-sprint token cost could fall without changing what the run produces. The mechanism
(a `--model` flag on the dispatch) and the cost differential are uncharacterised.

The user asked for this research before work on 0132–0135 finishes, so the findings can
inform whether any of those tickets need adjustment.

## Functional requirements

- FR1 — The design session must produce a documented decision on suite-check dedup: whether a
  sprint can run the suite once before the first dispatch and signal develop sessions to skip the
  baseline check within a sprint, including the mechanism for that signal and any conditions under
  which the guarantee would not hold.

- FR2 — The design session must produce a ranked list of per-agent overhead steps from develop
  and verify that a sprint could absorb or skip, with a token-cost estimate (or qualitative bound)
  for each candidate and a note on whether absorbing it would weaken the two-stage independence
  property.

- FR3 — The design session must produce a recommendation on model tiering: which tasks in the
  sprint supervisor and/or which full stage sessions (develop or verify) are candidates for haiku,
  the dispatch mechanism (`--model` in the `claude -p` call), and an estimated USD saving per
  sprint compared to all-opus, derived from `references/MEASUREMENT.md`'s per-session figures
  rather than invented.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Decisions and recommendations land in *Notes & decisions* before the handoff, in a form a cold session can act on without re-deriving the research | `documentation-conventions.md` |

## Open design question *(only while `next: design`)*

Three questions, any of which could produce a follow-on develop ticket:

- **Question 1 (suite-check):** Can sprint guarantee the tree is green between cycles well enough
  that develop sessions may skip the baseline suite run — and if so, what is the mechanism and
  what are the conditions that would make that guarantee fail?
- **Question 2 (per-agent overhead):** Which steps in develop and verify are genuine per-session
  requirements vs. shared pre-conditions a sprint could establish once, and how much token cost
  does each represent?
- **Question 3 (model tiering):** Which tasks in sprint or its dispatched sessions are suitable
  for haiku without quality loss, and what is the estimated cost saving?
- **Why they block specification:** the answers determine which implement tickets to write and
  what their FRs should say; writing implement tickets now would be building to guesses.
- **Settle it with:** `/design` — read the sprint, develop, and verify skills, check
  `references/MEASUREMENT.md` for per-session figures, and write the answers into *Notes &
  decisions*. Then set `next: develop` and add any unblocked FRs and ACs for the implement
  work, or spawn child tickets if the scope warrants it.

## Acceptance criteria

- [ ] AC1 — Given the design session completed, when `items/0149-*.md` *Notes & decisions* is
  read, then it contains a go/no-go on suite-check dedup with: the mechanism (if go), the
  conditions under which the invariant fails (if any), and the estimated suite-run saving per
  sprint; red = any of those three fields absent, or no explicit go/no-go.

- [ ] AC2 — Given the design session completed, when *Notes & decisions* is read, then it contains
  a ranked list of ≥ 3 per-agent overhead candidates, each with a token-cost estimate or explicit
  "not measurable from current data" and a verdict on whether absorbing it weakens stage
  independence; red = fewer than 3 candidates, or any candidate missing both a cost note and an
  independence verdict.

- [ ] AC3 — Given the design session completed, when *Notes & decisions* is read, then it contains
  a haiku recommendation naming: (a) which tasks or stages are candidates, (b) the `--model` flag
  form needed in the `claude -p` dispatch, and (c) an estimated USD saving per sprint derived from
  `MEASUREMENT.md`; red = recommendation absent, or any of (a), (b), (c) missing, or the saving
  figure is not traceable to `MEASUREMENT.md`.

## QA plan

- **Why review:** the output is documented decisions and recommendations; no runner can check
  whether a recommendation is complete, specific, and derived from current measurement data —
  that is a reading.
- **Specific checks:** per the `review: checklist:` in `config.yml`, applied to the *Notes &
  decisions* section against each AC above.

## Out of scope

- Implementing any of the identified changes (those go in follow-on develop tickets spawned by
  the design session).
- Changing `skills/sprint/SKILL.md`, `skills/develop/SKILL.md`, or `skills/verify/SKILL.md`
  — this ticket only produces decisions.
- Evaluating models other than haiku and opus (the two the user named).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions
