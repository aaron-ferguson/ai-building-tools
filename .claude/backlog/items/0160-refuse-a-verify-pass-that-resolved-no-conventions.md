---
id: "0160"
title: Refuse a verify pass that resolved no conventions, names another session, or skips the unit command
type: bug
next: verify
status: in-progress
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
claimed_by: "7e9e"
claimed_at: 2026-09-21T14:24:49Z
touches:
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

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 4 contains a
  sentence comparing the outcome's `session_id` with the dispatched one (asserted by the phrase `not
  the dispatched`). Red: the sentence absent, as today.
- [ ] AC2 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 4's section
  contains `re-verification`. Red: absent, as today.
- [ ] AC3 — Given a fixture `close_by: verify` ticket with every AC line in checkbox form and a `## QA
  evidence` section with no `Conventions: ` line, when `./close <id> <token>` runs, then it exits
  non-zero, the output names `Conventions:`, and `QUEUE.md`, `DONE.md` and the item are unchanged.
  Red: today's `close`, which closes it.
- [ ] AC4 — Given the AC3 fixture with `Conventions: ../conventions` added, when `./close` runs, then
  it closes. Given the AC3 fixture as `close_by: develop` with committed-guard ACs, `./close` does
  not refuse on the missing line. Red: a refusal applied to both tiers, or one that also refuses
  when the line is present.
- [ ] AC5 — Given `skills/verify/SKILL.md`, when the suite runs, then a guard asserts the `unit` row
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
