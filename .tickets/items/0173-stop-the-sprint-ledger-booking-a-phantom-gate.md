---
id: "0173"
title: Stop the sprint ledger booking a phantom gate from a stage's self-reported session id
type: bug
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-09-22
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

- [x] AC1 — Given a run log whose dispatch event and outcome object carry different session ids, when `record` runs, then exactly one GATE line is written for that gate — reddened by restoring the outcome-keyed harvest.
- [x] AC2 — Given that same fixture, when `record` runs, then the mismatch is reported naming both ids — reddened by deleting the report line.
- [x] AC3 — Given an outcome session id with no turns in the store, when `record` runs, then no `0.00` actual is written for it — reddened by re-pointing the harvest at the absent id.

## QA plan

- **Why that level:** the whole defect is in `record`'s harvest keying, which `tests/sprint-ledger.test.sh` already drives from fixtures.
- **Specific checks:** `tests/sprint-ledger.test.sh`, with a fixture whose outcome id differs from its dispatch id.

## Out of scope

- Removing `session_id` from the outcome schema, which would break every stage that fills it.
- The elapsed/active split, which is `0164`.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

Conventions: `../ai-building-conventions`
Level: `unit` — command run verbatim: `for t in tests/*.test.sh; do "$t" || true; done`
(`config.yml`'s reporting form of `commands.unit`.)

Baseline, clean tree: 31 test files, every one `0 failed`. `tests/sprint-ledger.test.sh`
`129 passed, 0 failed`.

| AC / NFR | How it was checked | Result |
|---|---|---|
| AC1 / FR1 | `tests/sprint-ledger.test.sh:1195` — a run log whose dispatch and outcome carry different session ids. Mutation, verbatim from the AC ("reddened by restoring the outcome-keyed harvest"): the `if e.get("event") != "dispatch": continue` guard deleted from `sessions_of`. | PASS — `FAIL 0173 AC1 — 2 GATE lines for one gate: the outcome's self-reported id booked a phantom beside the dispatched session`. `127 passed, 2 failed`. Restored by path; control `129 passed, 0 failed`. |
| AC3 / FR3 | Same fixture, same mutation. | PASS — the phantom's booking is visible in the failure output: `a GATE line was booked at observed USD 0.00 for a session with no transcript: GATE develop 2 ticket(s) session aaaaaaaa … observed USD 0.00`. Restored; control green. |
| AC2 / FR2 | Same fixture. Mutation, verbatim from the AC ("reddened by deleting the report line"): the whole `for stage, dispatched_sid, returned_sid in session_mismatches(events)` block removed. | PASS — `FAIL 0173 AC2 — no MISMATCH line: the outcome named a session the dispatch did not, and the ledger says nothing about it`, one case, `128 passed, 1 failed`. Restored; control green. **A first attempt at this mutation edited the format string and left its arity broken**, which crashed `record` and reddened AC1 as well; that run was discarded and redone, because a red from a traceback is not evidence about the guard. |
| FR2's silent case — **`develop` claims this is guarded; confirmed, not accepted** | Mutation: `if not isinstance(sid, str) or sid in known:` → `if not isinstance(sid, str):`, so every agreeing outcome reports a mismatch. | PASS — `FAIL 0173 FR2 — a run whose ids all agree still reports a mismatch: MISMATCH develop outcome returned session aaaaaaaa but was dispatched as aaaaaaaa`. Two further guards caught the same line (`AC5` and `0134 privacy`, the aggregate-figures character set), which is the new output line being covered by the privacy gate as well. Restored; control green. |
| NFR Observability — the mismatch is reported by both ids, never inferred from a zero | The row names a fixture outcome carrying a foreign session id producing a named mismatch line; reddened by removing the report. That is the AC2 mutation above. | PASS — guarded. The line names both ids independently rather than in a fixed order, which is `develop`'s own correction to a guard that had pinned presentation order. |
| NFR Documentation — the schema says `session_id` is echoed and is not the ledger's source of truth | `tests/sprint-ledger.test.sh:1251`. **First mutation replaced `echoed` and the guard stayed green** — the guarded clause is `Echoed, never authoritative`, capitalised, so the substitution applied without reaching it. Redone against the real clause: `Echoed, never authoritative: the ledger takes its source of truth from the dispatch event, because` → `The id the stage ran under, because`. | PASS — `FAIL 0173 Documentation NFR — outcome.schema.json does not say session_id is echoed rather than authoritative`. Schema re-parsed as valid JSON under the mutation, so the red is the wording and not a broken file. Restored; control green. |
| Newly reachable path (Step 4) | `record` now emits a `MISMATCH` line that did not exist before. Checked what it carries: 8-character id prefixes via `sid.split("-")[0]`, never a full UUID, and the line is inside the `0134` privacy character-set guard — which reddened on it under the FR2 mutation above, so it is covered rather than merely acceptable. | PASS |

Noted, not a defect against any criterion: the `FINDINGS.md` entry of 2026-09-22 argues that the
supervisor's own Step 4 trust check is a **second** consumer of the self-reported id, so a
dispatched-id-only rule would cover both while this ticket's fix covers the ledger alone. Every FR
here names `record`, and *Out of scope* does not exclude it either way, so it is a widening for the
author rather than a red.

Evidence set: `tools/sprint-ledger.sh`, `tests/sprint-ledger.test.sh`,
`skills/sprint/outcome.schema.json`, and the whole of `tests/`. Dirty set at Step 2: untracked
`.claude/backlog/runs/` and `.claude/backlog/FINDINGS.md`, committed at `5ff9dbb` before any
evidence was taken. Intersection: **empty** — every case above drives `mktemp` fixtures and reads no
repository path. `FINDINGS.md` was appended to again by the supervisor mid-pass, after the last
evidence run for this ticket and outside its evidence set; it was left alone rather than tidied.

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
