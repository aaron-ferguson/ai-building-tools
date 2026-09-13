---
id: "0154"
title: Let sprint park its own tooling findings, and propose the gate below a design row
type: feature
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0134"]
expects:
  - skills/sprint/SKILL.md
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/sprint.test.sh
  - tests/next.test.sh
claimed_by: "5290"
claimed_at: 2026-09-13T22:30:25Z
touches:
  - skills/sprint/SKILL.md
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/sprint.test.sh
  - tests/next.test.sh
---

## Problem

**What a sprint learns about its own tooling is lost when the supervising conversation ends.** Every
other stage parks what surprised it; `sprint` has no such step, and its sections on not writing the
backlog read as forbidding it, so four tooling defects found on `run-20260913T021045Z` reached only the
report until the user asked. Separately, `./next --drive --propose` describes nothing below an unheld
design row: the rank walk escalates on the design row before a gate is formed, so the confirmed scope
holds the next develop gate's ids only by way of `./next develop`'s lead row (develop 2026-09-12, 0134).

## Functional requirements

- FR1 — `sprint` parks findings under the backlog lock like any other writer, at the end of a run and whenever an escalation is about its own tooling rather than a stage's work, routed per `references/CONVENTIONS.md`.
- FR2 — the prohibitions in Steps 8 and 9 name findings parking as permitted, so the two cannot be read as contradicting.
- FR3 — `--propose` with an unheld design row in scope also prints the develop gate beneath it, in both copies of `next`.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | FR3 is a case in `tests/next.test.sh` asserting the whole PROPOSE line by equality. | Containment assertion passing under over-batching. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when the suite runs, then a step instructs parking findings under the lock. Red-making change: today's skill.
- [ ] AC2 — Given a fixture with an unheld design row above a develop gate, when `./next --drive --propose` runs, then the output names the gate's ids. Red-making input: today's template.

## QA plan

- **Why that level:** `unit` — prose guard plus a fixture case in the existing suites.
- **Specific checks:** `tests/sprint.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`.

## Out of scope

- 0151, 0152, 0153.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**Suite:** `tests/sprint.test.sh` — 225 passed, 0 failed; `tests/next.test.sh` — all passed (exit 0)

| AC | Guard | Outcome |
|---|---|---|
| AC1 | `0154 AC1 — SKILL.md has a step instructing findings parking under the backlog lock` | ✅ pass |
| AC2 | `0154 FR2 — Steps 8 and 9 prohibitions name findings parking as permitted` | ✅ pass |

🔍 Probe (AC2/FR3): `./next --drive --propose` with unheld design row above develop gate → exits 4 (escalate on design row), PROPOSE line reads `develop | 1 ticket(s)` — gate below design row is named.

### Re-verification 2026-09-13 — session 33d2edfe, token 0b0a — **FAIL**

**Suite — `config.yml` `commands.unit`, whole suite, run twice at 0dd303f (before and after the session-limit pause), exit 0 both times.** Per-file tallies, second run, pasted:
`backlog-scripts-installed 37/0 · batching 39/0 · citations 46/0 · claim 98/0 · close-by 67/0 · close 246/0 · cost-by-category 29/0 · cross-cutting-change 21/0 · design-hold 34/0 · external-feedback 9/0 · falsifiable-acs 34/0 · findings-buffer 46/0 · findings-routing 41/0 · floor-probe 12/0 · graph-fields 36/0 · handoff 132/0 · item-ac-form 4/0 · last-line 17/0 · measurement 131/0 · money-in-skill-prose 12/0 · next 431/0 · qa-level-once 11/0 · reference-size 15/0 · release 45/0 · remote-anchor 20/0 · reporting 23/0 · retro-tool-edit 50/0 · skill-size 27/0 · sprint-ledger 95/0 · sprint 231/0/0 skipped · transient-mutation 6/0` (passed/failed, each file's own tally line).
Conventions resolved: `/Users/aaronferguson/AI/ai-building-conventions` (config.yml `conventions.path`). Copy under test: the repo copy; the installed 0.9.28 cache differs from it (pre-fix `outcome.schema.json` and `SKILL.md`). Dirty set at both captures: `?? .claude/backlog/runs/` only. Written through Bash, not the Write tool (Write was not attempted). Every mutation below was applied to a committed file, confirmed by a non-empty `git diff --stat`, and restored by its own path; each cycle ended on a green control run.

| Row | How checked | Result |
|---|---|---|
| AC1 | guard `0154 AC1`; Step 9 paragraph *"The supervisor parks findings about its own tooling under the backlog lock"*. Mutation M3 (delete it) → `FAIL 0154 AC1`, 230 passed 2 failed | ✅ |
| FR2 | guard `0154 FR2`; Step 8 *"It never writes to the backlog except to park findings"*. Mutation M4 (bare prohibition) → `FAIL 0154 FR2`, 230 passed 2 failed | ✅ |
| AC2 | live fixture (ids 9901 design, 9902 develop `src/a.ts`, 9903 develop `src/b.ts`) through **both** copies at HEAD: `PROPOSE   develop \| 1 ticket(s)` / `TICKET    9902 \| size s \| Fixture 9902` / `ESCALATE  9901 …`, exit 4; without `--propose` no PROPOSE line. Guard `0154 AC2`. Mutation M1 (delete the FR3 block from `skills/queue/templates/next`) → `FAIL — PROPOSE line names the develop gate below the design row`, next 430/1, plus backlog-scripts-installed `FAIL next has diverged`, 36/1. Mutation M2 (delete it from `.claude/backlog/next` only) → next 431/0, backlog-scripts-installed 36/1 | ✅ ids named in output; the installed copy is guarded by identity |
| 🔍 probes | overlapping rows (9902, 9903 both `src/a.ts`) → `PROPOSE   develop \| 2 ticket(s)`, TICKET 9902, TICKET 9903, `JOIN src/a.ts`; design row with nothing below → no PROPOSE, exit 4 | ✅ |
| AC2 guard note | the equality assertion is on the count line, not the ids; ids are asserted by nothing | ⚠️ |
| NFR Testing | whole-PROPOSE-line equality assertion present | ✅ |
| **FR1** | Step 9 says *"Take the lock, append to `FINDINGS.md`, release it"*. `grep 'CONVENTIONS.md\|Routing a finding' skills/sprint/SKILL.md` finds only line 31 (conventions resolution); every other stage skill (design, develop, prototype, queue, retro, verify) cites *Routing a finding to the repo it is about* | ❌ FR1 requires routing per `references/CONVENTIONS.md`; a sprint's findings about its own tooling are about the tools repo, so on any other project this instruction parks them in the wrong buffer. No guard |
| Always-on (CONVENTIONS_CORE.md) | no secrets/data; both `next` copies identical at HEAD (`diff` clean) | ✅ |

Evidence set: `skills/sprint/SKILL.md`, `.claude/backlog/next`, `skills/queue/templates/next`, `tests/sprint.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`, `references/CONVENTIONS.md`. Intersection with the dirty set: empty.

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Two buffer entries about what a sprint run can see and keep.
- **2026-09-13 — reopened for re-verification, by the user's request.** The verify session that closed this ticket (433a37e3) ran on claude-sonnet-4-6, returned `conventions_resolved: null` and a placeholder `session_id`, and ran per-ticket test files instead of `config.yml` `commands.unit`. Composed by hand under the backlog lock by a `queue` session, since no operation reopens a closed ticket (that path is 0161): row moved from `DONE.md` back to the top of `QUEUE.md`, `next: verify`, `status: ready`, `closed:` removed, and the acceptance criteria UNTICKED — a tick is evidence of the pass being distrusted, and `close` re-ticks what the new pass checks. The QA evidence above is kept as the record of that pass; the next `verify` writes its own beside it and does not rely on it.
- **2026-09-13 — re-verification (session 33d2edfe) FAILED; sent back to `develop`.** FR1 is unmet: Step 9's parking instruction appends to `FINDINGS.md` without routing per `references/CONVENTIONS.md` *Routing a finding to the repo it is about*, which FR1 names and every other stage skill cites. The constraint: sprint's parking step routes by that section, with a guard that reds when the citation is removed. AC1, FR2 and AC2 were cleared (live fixture through both copies of `next`; each guard reddens under mutation) and are owed no work; AC2's guard asserts the ticket count rather than the ids, which is worth tightening while there.
