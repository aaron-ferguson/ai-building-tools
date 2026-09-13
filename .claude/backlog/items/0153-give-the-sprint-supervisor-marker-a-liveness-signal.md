---
id: "0153"
title: Give the sprint supervisor marker a liveness signal that outlives one tool call
type: bug
next: verify
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0121"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The supervisor marker's `held-by` pid is dead as soon as it is written.** `sprint` Step 1 check 2
records a pid and treats a marker whose pid is not alive as stale and takeable. A supervisor's Bash
calls each run in a fresh shell, so `$$` names a process that already exited, and a second supervisor
following the rule would take over a live run (`.claude/backlog/runs/.active/held-by`,
`run-20260913T021045Z`).

## Functional requirements

- FR1 — staleness of `.active/` is decided by a signal a live supervisor keeps fresh across tool calls (for example a timestamp it rewrites on every dispatch, with a stated age), never by a pid.
- FR2 — the skill names the signal and the age once, and the takeover rule reads it.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | Step 1 says why a pid cannot serve, in one clause. | Guard on the clause. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when the suite runs, then Step 1's staleness rule does not key on a pid being alive. Red-making change: today's wording.
- [ ] AC2 — Given the rule, when the suite runs, then Step 3's dispatch refreshes the signal the staleness rule reads. Red-making change: a rule naming a signal nothing refreshes.

## QA plan

- **Why that level:** `unit` — prose guards in `tests/sprint.test.sh`.
- **Specific checks:** `tests/sprint.test.sh`; mutate each asserted clause.

## Out of scope

- 0121's timestamp in the backlog lock's `held-by`, a different file.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**Suite:** `tests/sprint.test.sh` — 225 passed, 0 failed

| AC | Guard | Outcome |
|---|---|---|
| AC1 | `0153 AC1 — Step 1 staleness rule does not key on a pid being alive` | ✅ pass |
| AC2 | `0153 AC2 — Step 3 refreshes the liveness signal named by the staleness rule` | ✅ pass |
| NFR | `0153 NFR — Step 1 says why a pid cannot serve, in one clause` | ✅ pass |

🔍 Probe: Confirmed `held-by` file no longer referenced in staleness rule — timestamp-based signal used instead.

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry, filed because it would let two supervisors drive one backlog.
- **2026-09-13 — reopened for re-verification, by the user's request.** The verify session that closed this ticket (433a37e3) ran on claude-sonnet-4-6, returned `conventions_resolved: null` and a placeholder `session_id`, and ran per-ticket test files instead of `config.yml` `commands.unit`. Composed by hand under the backlog lock by a `queue` session, since no operation reopens a closed ticket (that path is 0161): row moved from `DONE.md` back to the top of `QUEUE.md`, `next: verify`, `status: ready`, `closed:` removed, and the acceptance criteria UNTICKED — a tick is evidence of the pass being distrusted, and `close` re-ticks what the new pass checks. The QA evidence above is kept as the record of that pass; the next `verify` writes its own beside it and does not rely on it.
