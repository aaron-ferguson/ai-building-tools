---
id: "0173"
title: Stop the sprint ledger booking a phantom gate from a stage's self-reported session id
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: s
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0162", "0163"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/outcome.schema.json
claimed_by: "f056"
claimed_at: 2026-09-22T14:53:59Z
touches:
---

## Problem

**A stage's self-reported `session_id` is not always the session it ran in, and the ledger silently
books a phantom gate at USD 0.00 when the two differ.** On `run-20260920T222013Z` the develop gate
was dispatched with a pre-assigned `--session-id 39c7c2e3-bf0a-4112-9c5e-da90275e59f9`; its outcome
object returned a different id, for which no transcript exists. `sprint-ledger.sh record` pins its
harvest to both the dispatch event and the outcome, so it emitted **two GATE lines for one gate** —
the real one at USD 15.21, and a phantom at USD 0.00. A reader summing them under-reports nothing
and over-counts sessions, which is the direction that corrupts a per-session mean.

`skills/sprint/SKILL.md` Step 3 states the pre-assignment exists precisely so the transcript path is
a dispatch-time fact. Nothing reconciles the two ids, and the outcome schema invites a stage to
supply one it cannot know.

Distinct from `0162`, which is about a harvest with no published rate; here the turns do not exist
at all.

## Functional requirements

- FR1 — `record` treats the **dispatch event's** session id as authoritative for a gate, and never
  emits a second GATE line for an outcome id that differs from it.
- FR2 — Where an outcome's `session_id` differs from the dispatch id, `record` reports the mismatch
  by both ids rather than dropping it silently.
- FR3 — An outcome session id with no transcript is never harvested to `0.00`; it is refused or
  labelled, consistent with `0162`'s `unpriced` handling once that lands.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | The mismatch is reported by both ids, never inferred from a zero | A fixture outcome carrying a foreign session id must produce a named mismatch line; removing the report reddens it | `observability-conventions.md` |
| Documentation | `skills/sprint/outcome.schema.json`'s `session_id` description says the field is echoed and is not the ledger's source of truth | A grep for the echoed-not-authoritative wording in the schema description | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a run log whose dispatch event and outcome object carry different session ids, when `record` runs, then exactly one GATE line is written for that gate — reddened by restoring the outcome-keyed harvest.
- [ ] AC2 — Given that same fixture, when `record` runs, then the mismatch is reported naming both ids — reddened by deleting the report line.
- [ ] AC3 — Given an outcome session id with no turns in the store, when `record` runs, then no `0.00` actual is written for it — reddened by re-pointing the harvest at the absent id.

## QA plan

- **Why that level:** the whole defect is in `record`'s harvest keying, which `tests/sprint-ledger.test.sh` already drives from fixtures.
- **Specific checks:** `tests/sprint-ledger.test.sh`, with a fixture whose outcome id differs from its dispatch id.

## Out of scope

- Removing `session_id` from the outcome schema, which would break every stage that fills it.
- The elapsed/active split, which is `0164`.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park on `run-20260920T222013Z`. Kept separate from `0162`
  because the zero has a different cause: no turns rather than no rate.

- **2026-09-22 (develop, f0e0) — the mismatch is intermittent, confirmed live in this session.**
  This develop gate was dispatched with a pre-assigned `--session-id`, and
  `CLAUDE_CODE_SESSION_ID` inside the stage read back **the same** UUID
  (`540d0cb1-…`, run-20260922T031109Z). So the pre-assignment does hold, usually — which is exactly
  why the defect is dangerous rather than obvious: a ledger that trusts the echoed id is right most
  of the time and silently books a phantom the once it is not. Nothing in a passing run would
  reveal it.
- **2026-09-22 (develop, f0e0) — the fix is in what creates a session row, not in the harvest.**
  `sessions_of` built a row from **any** event carrying `session_id`, so an outcome naming a
  foreign id produced a second row that then behaved like a real gate all the way through: it
  carried the outcome's ticket list, passed the `stage == "develop"` test, and got its own GATE
  line. Rows now come from `dispatch` events alone, and the outcome loop matches on the dispatch id
  or does nothing. FR3 then needs no separate mechanism: a phantom that is never a row is never
  harvested, so there is no `0.00` to label.
- **2026-09-22 (develop, f0e0) — AC1 and AC3 mutation-checked against the committed file** by
  deleting the `if e.get("event") != "dispatch"` guard, which is precisely the criteria's
  *"reddened by restoring the outcome-keyed harvest"*: 2 failures, naming the two GATE lines and
  the USD 0.00 booking, then restored and re-run green. AC2 and the Documentation NFR were red
  before the implementation existed. **Run, not reasoned.**
- **2026-09-22 (develop, f0e0) — a guard of mine pinned a presentation order and failed correct
  output.** AC2's first form asserted `*<dispatched>*<returned>*` in one `case` pattern; the
  implementation prints the returned id first, so a line naming both ids failed for saying them in
  the other order. Rewritten to grep each id independently. Which id leads is a presentation
  choice, and a criterion about *naming both* should not be able to fail on it.
- **2026-09-22 (develop, f0e0) — the silent case is guarded too.** A `MISMATCH` line is emitted only
  when an outcome names an id no dispatch assigned; the 0166 fixture, whose ids all agree, is
  asserted to produce none. Without that, every run would grow the line and it would stop meaning
  anything.
