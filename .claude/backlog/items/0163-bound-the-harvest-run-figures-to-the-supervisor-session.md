---
id: "0163"
title: Bound harvest-usage's --run figures to the supervisor's own session
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: s
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0039", "0135", "0162"]
expects:
  - tools/harvest-usage.sh
  - tests/measurement.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-22
---

## Problem

**`harvest-usage.sh <dir> --run <log>` computes the supervisor's floor, growth and turns over every
transcript in the directory**, so the figures describe the whole project's history, not the run.

Parked from run-20260913T034946Z:

> `harvest-usage.sh --run` reported 4249 turns because the bound spans the whole transcript
> directory, not the supervisor's session.

In `report_run_bound`, the only narrowing is `--session`, when it is given. `skills/sprint/SKILL.md`
Step 9 invokes the bound without one. The run log does not record the supervisor's session id
either, although the supervising process has it as `CLAUDE_CODE_SESSION_ID`.

The same entry's other half, a rerun supervised from an earlier run's conversation, was discharged by
commit `a666012` (`supervisor_context` on `scope_confirmed`).

## Functional requirements

- FR1 — `skills/sprint/SKILL.md` Step 5: the `scope_confirmed` event carries `supervisor_session`,
  the supervising process's `CLAUDE_CODE_SESSION_ID`.
- FR2 — `report_run_bound` in `tools/harvest-usage.sh` reads `supervisor_session` from the run log
  and computes floor, growth and turns over that session's transcript only. An explicit `--session`
  still narrows as today and takes precedence.
- FR3 — Where the run log names no `supervisor_session` and no `--session` is given, it prints
  `RUN … no supervisor session named; no bound reported` and reports no bound, the way it already
  reports no bound for a log with no dispatch.
- FR4 — Step 9's bound invocation and the `--run` usage comment match FR2–FR3.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | A bound is either over the supervisor's session or not printed | AC2 | `measurement-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a fixture directory with two session transcripts and a run log recording one
  dispatch, where session `aaaa…` has 3 turns, session `bbbb…` has 50, and `scope_confirmed` names
  `supervisor_session` `aaaa…`: when `harvest-usage.sh <dir> --run <log>` runs, then it prints
  `RUN BOUND over 1 cycles and 3 turns`. Red: today's script prints 53 turns.
- [x] AC2 — Given the same fixture with no `supervisor_session` and no `--session`, when it runs, then
  the output contains `no supervisor session named` and no `RUN BOUND` line. Red: today's
  whole-directory bound.
- [x] AC3 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 5 contains
  `supervisor_session` and `CLAUDE_CODE_SESSION_ID`. Red: either absent.

## QA plan

- **Why that level:** `harvest-usage.sh` is fixture-tested by the suite; the skill change is a prose
  guard.
- **Specific checks:** AC1–AC2 wherever the existing `--run` cases live (confirm on claim; recorded
  in the notes); AC3 in `tests/sprint.test.sh`.

## Out of scope

- Stage-session figures and the per-skill table.
- Retro-fitting `supervisor_session` into existing run logs.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

Conventions: `../ai-building-conventions`
Level: `unit` — command run verbatim: `for t in tests/*.test.sh; do "$t" || true; done`
(`config.yml`'s reporting form of `commands.unit`.)

Baseline, clean tree: 31 test files, every one `0 failed`. `tests/measurement.test.sh`
`135 passed, 0 failed`; `tests/sprint.test.sh` `268 passed, 0 failed, 0 skipped`.

| AC / NFR | How it was checked | Result |
|---|---|---|
| AC1 | `tests/measurement.test.sh:1163` — a fixture store of two transcripts (`aaaa…` 3 turns, `bbbb…` 50) and a run log whose `scope_confirmed` names `aaaa…`. Mutation, exactly the AC's stated red: `report_run_bound`'s supervisor lookup deleted and the narrowing made conditional, i.e. the pre-0163 whole-directory bound restored. | PASS — `FAIL 0163 AC1 — the bound still spans the whole transcript directory (53 turns)…`, `132 passed, 3 failed`. Restored by path; control `135 passed, 0 failed`. |
| AC2 | Same fixture with `scope_confirmed` naming no session and no `--session`. Same mutation. | PASS — two cases red: `expected 'no supervisor session named'` and `a bound was printed anyway, over the whole directory`. Both are the AC's stated red. Restored; control green. |
| AC3 | `tests/sprint.test.sh:2227`. Mutation: `supervisor_session` → `sup_sess_X` and `CLAUDE_CODE_SESSION_ID` → `CC_SESSION_X` throughout `skills/sprint/SKILL.md`. | PASS — both cases red: `Step 5 names no supervisor_session…` and `Step 5 does not name CLAUDE_CODE_SESSION_ID as the source…`. Restored; control green. |
| FR4 — Step 9 and the `--run` usage comment match FR2–FR3 | Read both: `skills/sprint/SKILL.md:711-719` states the bound is over the `supervisor_session` the log names, that no flag is needed, that a log naming none prints `no supervisor session named` and reports no bound, and that `--session` still overrides. `tools/harvest-usage.sh:35-44` says the same. | PASS — **unguarded**: no case asserts the usage comment, so it can go stale silently. |
| NFR Observability — a bound is either over the supervisor's session or not printed | The row names AC2, which is a real executing guard and was reddened above, twice. | PASS — guarded. |

Copy executed: the **repo** copy of `skills/sprint/SKILL.md` is the subject and is what the guards
read. Worth recording beside the verdict: the installed plugin at `0.9.31` — the version this
session resolved from — contains no `supervisor_session` at all (`grep -c` → 0 for every cached
version `0.9.25`–`0.9.31`), so the supervisor driving this very sprint had no instruction to write
the field, and its run log does not carry it. That is why the real-surface run above exercises FR3's
refusal rather than AC1's bound, and it is the ticket working rather than failing.

Evidence set: `tools/harvest-usage.sh`, `tests/measurement.test.sh`, `skills/sprint/SKILL.md`,
`tests/sprint.test.sh`, and the whole of `tests/`. Dirty set at Step 2: untracked
`.claude/backlog/runs/` and `.claude/backlog/FINDINGS.md`, committed at `5ff9dbb` before any
evidence was taken. Intersection: **empty** — every criterion above is discharged by a fixture case
that reads no repository path, and the one thing this session ran against a file under
`.claude/backlog/runs/` is the observation below, which no criterion rests on.

**Observation, outside the evidence set.** Run for interest, not as an AC check:
`tools/harvest-usage.sh ~/.claude/projects/<this repo> --run .claude/backlog/runs/run-20260922T031109Z.jsonl`
— this sprint's own run log, which names no `supervisor_session` because the supervisor driving it
is running the installed `0.9.31` copy, where the field does not exist. Last line:
`RUN LOG …: no supervisor session named; no bound reported`, with no `RUN BOUND` anywhere. FR3's
refusal behaving on live input rather than a fixture. The pre-fix behaviour here would have been a
bound over 575,474,789 tokens of whole-store history printed under one run's heading.

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`.
- **The id comes from the run log, not a flag.** The log is where the ledger already pins every other
  session id. A bound that depends on a person remembering a flag goes back to spanning the directory
  the first time they forget. `CLAUDE_CODE_SESSION_ID` was observed set in a Claude Code Bash
  environment on 2026-09-13.

- **2026-09-21 (develop, 7101)** — **The QA plan's "wherever the existing
  `--run` cases live" resolved to nowhere.** It asks that AC1–AC2 go where the existing `--run`
  cases are, and directs the claiming session to confirm that on claim and record it:
  `tests/measurement.test.sh` had **no `--run` coverage at all** — no `RUN BOUND`, no `--run`, no
  `no bound` string anywhere in the file. The `--run` path was exercised only by AC13 in
  `tests/sprint.test.sh`. AC1–AC2 are therefore **new** cases in `measurement.test.sh`, placed
  there because that is where `harvest-usage.sh`'s arithmetic is fixture-tested and where the
  ticket's `expects:` put them, and a third case was added beside them pinning FR2's
  `--session`-takes-precedence rule, which no criterion covers but the implementation now depends on.
- **2026-09-21 (develop, 7101)** — **`CLAUDE_CODE_SESSION_ID` re-probed rather than trusted.** The item's
  note dates the observation to 2026-09-13; a claim about a tool's interface ages like a quoted
  figure, so it was re-run in this session's own Bash environment and is set
  (a v4 UUID). FR1's premise holds as written.
- **2026-09-21 (develop, 7101)** — **This change falsified AC13's fixture, and rewriting it was part of
  the work rather than collateral.** AC13 (0039) builds a run log with `run_started`, three
  `dispatch` and two `outcome` events, and asserts a floor of 20000, growth of 1500 and 2.0 turns
  per cycle. FR3 makes a log that names no `supervisor_session` report **no bound at all**, so all
  three assertions lost their input and went red on a correct implementation. The fixture now emits
  a `scope_confirmed` event naming `supervisor_session: "run"` — the stem of its own
  `transcripts/run.jsonl`, which is what `harvest-usage.sh` derives a session id from. No assertion
  of AC13's was weakened: the dispatch-versus-outcome count case is untouched and the three figures
  are unchanged.
- **2026-09-21 (develop, 7101)** — **`tools/sprint-ledger.sh` is unaffected, checked rather than assumed.**
  It shells out to `harvest-usage.sh` in `harvest()` with `--session` arguments only and never
  passes `--run`, so the new refusal path cannot reach it. Its own `record --run` flag is a
  different parser's flag of the same name.
- **2026-09-21 (develop, 7101)** — **A limit of 0165 AC1, seen while this ticket was mid-build and worth
  knowing before it is read as a defect.** `0165` AC1 asserts a forced FAIL line appears within the
  last 5 lines of a run. While `sprint.test.sh` was legitimately red with four other failures, the
  injected line was pushed out of that window and AC1 reddened — correctly, in the sense that five
  failures cannot fit in five lines. AC1 presumes an otherwise-green file, which is the state the
  gate requires anyway. It self-resolved the moment AC13's fixture was repaired.
