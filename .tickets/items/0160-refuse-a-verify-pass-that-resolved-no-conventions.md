---
id: "0160"
title: Refuse a verify pass that resolved no conventions, names another session, or skips the unit command
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0149", "0161", "0151"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
  - skills/verify/SKILL.md
  - skills/queue/templates/close
  - .claude/backlog/close
  - tests/close.test.sh
  - tests/close-by.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-21
---

## Problem

**A verify session closed four tickets on a pass nobody can trust, and nothing stopped it.**

Parked from run-20260913T034946Z, verbatim:

> Verify closed 0151–0154 as pass while returning `conventions_resolved: null`, a placeholder
> `session_id` (00000000-0000-4000-8000-000000000000), and running per-ticket test files instead of
> config's `unit` command. Step 4 calls a null conventions field an escalation, but the closes had
> already been committed; nothing gives a closed ticket a path back to verify.

The session (433a37e3) ran on claude-sonnet-4-6. The user had the four reopened by hand on
2026-09-13 (commit `ecc6a60`).

Three gaps, each independently sufficient:

1. **Detection comes after the damage.** `skills/sprint/SKILL.md` Step 4 escalates on
   `conventions_resolved: null`, but `./close` has already committed inside the stage session. Step 4
   also never compares the outcome's `session_id` with the `--session-id` it dispatched, so a
   placeholder reads as valid.
2. **`close` has no mechanical tie to the standard.** `skills/verify/SKILL.md` Step 1 says stop if
   no conventions resolve. Nothing records that they did, though, so `close` cannot refuse a close
   made against none.
3. **The `unit` level reads as permission to narrow.** `skills/verify/SKILL.md`'s level table says
   `unit` runs *"lint, typecheck, unit suite scoped to the change"*, while this repo's
   `config.yml` `commands.unit` is the whole suite. The session ran per-ticket files.

## Functional requirements

- FR1 — `skills/sprint/SKILL.md` Step 4: an outcome whose `session_id` is not the UUID dispatched for
  that stage (logged in its `dispatch` event) fails Step 4 exactly as a malformed outcome does:
  escalation, nothing further dispatched.
- FR2 — Step 4: take an outcome that fails on `conventions_resolved: null` or on FR1. If it reports
  any ticket as `closed`, `pass` or `next: done`, the escalation names each of those ids as closed
  on an untrusted pass and due for re-verification.
- FR3 — `skills/verify/SKILL.md` requires, before `./close`, a line `Conventions: <resolved path>` in
  the ticket's `## QA evidence`, written from the resolution Step 1 performed.
- FR4 — `close` (`skills/queue/templates/close` and its byte-identical `.claude/backlog/close`)
  refuses a `close_by: verify` ticket whose `## QA evidence` has no `Conventions: ` line, naming that
  line in the refusal. A `close_by: develop` ticket is not subject to it.
- FR5 — `skills/verify/SKILL.md`'s level table: `unit` runs the project's `config.yml` `commands.unit`
  as configured, and never a substitute set of files; the QA evidence records the command line that
  ran, verbatim. The words "scoped to the change" leave the `unit` row.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | `verify`'s own level table and the project's `commands.unit` cannot be read as disagreeing | AC5 | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 4 contains a
  sentence comparing the outcome's `session_id` with the dispatched one (asserted by the phrase `not
  the dispatched`). Red: the sentence absent, as today.
- [x] AC2 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 4's section
  contains `re-verification`. Red: absent, as today.
- [x] AC3 — Given a fixture `close_by: verify` ticket with every AC line in checkbox form and a `## QA
  evidence` section with no `Conventions: ` line, when `./close <id> <token>` runs, then it exits
  non-zero, the output names `Conventions:`, and `QUEUE.md`, `DONE.md` and the item are unchanged.
  Red: today's `close`, which closes it.
- [x] AC4 — Given the AC3 fixture with `Conventions: ../conventions` added, when `./close` runs, then
  it closes. Given the AC3 fixture as `close_by: develop` with committed-guard ACs, `./close` does
  not refuse on the missing line. Red: a refusal applied to both tiers, or one that also refuses
  when the line is present.
- [x] AC5 — Given `skills/verify/SKILL.md`, when the suite runs, then a guard asserts the `unit` row
  of the level table contains `commands.unit` and does not contain `scoped to the change`. Red:
  today's row.

## QA plan

- **Why that level:** `close` is a fixture-tested script; the skill changes are pinned by prose
  guards the same suite runs.
- **Specific checks:** AC3–AC4 in `tests/close.test.sh` / `tests/close-by.test.sh`; AC1, AC2, AC5
  as prose guards; `tests/backlog-scripts-installed.test.sh` for the copy. Existing `close`
  fixtures for `close_by: verify` gain the line.

## Out of scope

- Reopening a closed ticket — 0161.
- Which model a stage runs on. Dispatch already passes `--model opus` (commit `a666012`); whether any
  stage may drop below it is 0149's question.
- Validating that the `Conventions:` path resolves: `close` checks the line exists, not what it names.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**Verdict: PASS** — verify session 2026-09-21, token 7e9e.

Conventions: `../ai-building-conventions` (`config.yml` `conventions.path`; `CONVENTIONS_CORE.md`
plus `documentation-conventions.md`, `testing-conventions.md`).
Level `unit`, run as `config.yml`'s `commands.unit` in the reporting form that file prescribes:
`for t in tests/*.test.sh; do "$t" || true; done` — 31 files, every tally `0 failed`
(`tests/close.test.sh` 256 passed, `tests/close-by.test.sh` 67 passed,
`tests/sprint.test.sh` 257 passed, `tests/backlog-scripts-installed.test.sh` 37 passed).
Copy executed: the repo copy `skills/queue/templates/close`, which the fixtures below ran; `cmp`
reports it identical to `.claude/backlog/close`. **This session met the refusal for real** — every
ticket it closed carried the `Conventions:` line its own evidence records.

| Criterion | How it was checked | Result |
|---|---|---|
| AC1 | `tests/sprint.test.sh` guard on Step 4; `skills/sprint/SKILL.md:417` reads *An outcome whose `session_id` is not the dispatched one fails exactly as a malformed outcome* | pass |
| AC2 | Same suite; Step 4 names ids closed on an untrusted pass as due for `re-verification` (`skills/sprint/SKILL.md:425`) | pass |
| AC3 | Fresh fixture repo, `close_by: verify` ticket at `next: verify, status: in-progress`, one checkbox AC, a `## QA evidence` section with no `Conventions:` line. `./close 9905 ab12` → exit 1, output names `Conventions:` and the four tickets reopened by hand; `QUEUE.md`, `DONE.md` and the item all byte-identical afterwards (md5 compared before and after) | pass |
| AC4 | Same fixture with `Conventions: ../conventions` added → `closed 9905`, exit 0, item `status: done`. The `close_by: develop` fixture with no `Conventions:` line and a committed guard cited in its AC → `closed 9905`, exit 0, `status: done` | pass |
| AC5 | `tests/sprint.test.sh` guards bound to the `unit` ROW of `skills/verify/SKILL.md`'s level table, which reads *lint, typecheck, and `config.yml`'s `commands.unit` **as configured** — never a substitute set of files chosen to match the change* | pass |
| FR3 | `skills/verify/SKILL.md` Step 7 instructs the `Conventions: <resolved path>` line and says `close` refuses without it; guarded by `0160 FR3` in `tests/sprint.test.sh` | pass |
| NFR Documentation | The `unit` row and `config.yml`'s `commands.unit` now say the same thing; AC5 is its check. Read against `documentation-conventions.md` | pass |

**Mutations run** (committed tree, mutated, red confirmed, restored by path, control green):

1. `close`'s sixth refusal disabled (`[ "$close_by" = verify ]` → `= never`). The AC3 fixture then
   printed `closed 9905` at exit 0 and all three files changed — today's-`close` behaviour, exactly
   the red AC3 names.
2. Three prose edits in one pass: Step 4's sentence reworded to *differs from the one logged at
   dispatch*; `re-verification` → `a second QA pass`; the `unit` row replaced by *lint, typecheck,
   and the unit suite scoped to the change*. `tests/sprint.test.sh` 253 passed, 4 failed — one red
   per assertion, AC1, AC2 and both halves of AC5. Restored; controls `tests/sprint.test.sh` 257,
   `tests/close.test.sh` 256, `tests/close-by.test.sh` 67,
   `tests/backlog-scripts-installed.test.sh` 37, all 0 failed.

**Probes** (`🔍`):
- A `close_by: develop` ticket with no committed guard cited in its AC is refused by the *fifth*
  refusal, not this ticket's sixth — so the light tier's exemption is real rather than an untested
  branch: two different refusals fire on two different fixtures.
- The refusal is computed before anything is written; the md5 comparison above is the evidence,
  not the script's own claim.
- **The build note's justification for binding the AC5 guard to the row is not true of the file as
  it now stands**: `grep -c 'commands.unit' skills/verify/SKILL.md` is 1, so a file-wide presence
  grep would have reddened too. The row binding is still the right shape and nothing rests on the
  note; recorded because the next pass should not cite that reasoning as observed.
- The refusal's `awk` is scoped to the `## QA evidence` section, so a `Conventions:` line in
  *Notes & decisions* does not satisfy it — the shape the ticket's notes name.

Dirty set at Step 2 and at verdict: `.claude/backlog/runs/` (untracked). Intersection with this
run's evidence set (`skills/queue/templates/close`, `.claude/backlog/close`,
`skills/sprint/SKILL.md`, `skills/verify/SKILL.md`, `tests/close.test.sh`,
`tests/close-by.test.sh`, `tests/sprint.test.sh`) is empty — not advisory.

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`: every part has a right answer readable from the code and the user's statement that the
  unit level runs `commands.unit`.
- **Why a `close` refusal and not only a supervisor check (FR4).** The supervisor reads the outcome
  only after the stage has committed its closes, so it can detect but not prevent. `close` is the
  one mechanical point before the commit, and a written `Conventions:` line is the smallest record
  it can demand. It is restricted to `close_by: verify` because the light tier's evidence is its
  committed guards.
- **Relates 0149 (model tiering).** This pass is the one recorded instance of a cheaper model
  dropping the outcome contract on a verify stage.

- **2026-09-20 (develop, eeb0) — THE LIVE SCRIPT NOW REFUSES WHAT THE INSTALLED SKILL DOES NOT YET
  ASK FOR, and the three tickets this session handed to verify are the first to meet it.**
  `.claude/backlog/close` is a committed file and takes effect immediately; `skills/verify/SKILL.md`
  is resolved from `~/.claude/plugins/cache/` at session start, so until a release the next verify
  session is told nothing about the `Conventions:` line and will meet the refusal with no instruction
  explaining it. The refusal message names the line and the fix, which is what makes that recoverable
  rather than a stop — but **this is the release-shaped half of the ticket and it is the author's
  call** (`CLAUDE.md`, *the installed copy is what runs*; `tools/release`). Parked in `FINDINGS.md`
  too, because it outlives this ticket.
- **AC4's two halves are two cases, not one.** The positive (the line present closes) and the
  exemption (`close_by: develop` is not subject to it) exercise different branches, and a single
  case asserting "does not refuse" would pass on either one alone.
- **The check is an `awk` over the `## QA evidence` section, not a file-wide grep.** A `Conventions:`
  line anywhere else in the item — a notes paragraph quoting the rule, say — would satisfy a
  file-wide grep while the evidence section stayed empty, which is the ticket's whole subject.
- **`close.test.sh` needed six fixture helpers amended, not one**, and `close-by.test.sh` needed
  none: every `close_by: verify` fixture had no `## QA evidence` section at all, which is why 79 of
  256 cases redded at once. `close-by.test.sh` is dropped from `touches:` — it was in `expects:` and
  the work never reached it.
- **AC3's refusal is proved red-then-green by its own case** (the fixture closed before the refusal
  existed, refuses after), so it needed no separate mutation. **Run, not reasoned.**
- **The `unit`-row guard is bound to the ROW, not the file.** `commands.unit` appears elsewhere in
  `skills/verify/SKILL.md` in its own right, so a file-wide presence grep would have been green with
  the table row untouched — the same unfalsifiable shape caught on 0168 AC7 earlier in this session.
