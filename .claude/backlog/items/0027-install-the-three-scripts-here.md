---
id: "0027"
title: Instantiate next, claim and close in this repo's own backlog
type: chore
next: verify
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - .claude/backlog/next
  - .claude/backlog/claim
  - .claude/backlog/close
  - .claude/backlog/QUEUE.md
claimed_by: "b8d3"
claimed_at: 2026-08-24T04:27:07Z
touches:
---

## Problem

This repo ships `next`, `claim` and `close` as `skills/queue/templates/` and instantiates them
into a *new* project's backlog at `queue` Step 0. This backlog predates that step, so the one
project developing the scripts is the only project without them.

Six separate sessions hit it on 2026-08-23, which is why it is a ticket rather than a nuisance:

- `develop` Step 1 opens *"Run `./next develop` rather than reading `QUEUE.md`"* — the largest
  avoidable context cost the step names, unavoidable here.
- `verify` Step 1 has the identical gap: `./next verify` and `./claim <id>` are both absent.
- The documented fallback was taken and went wrong in the way the scripts exist to prevent: a
  session read 0026 as `blocked`, skipped it, and the template reader run afterwards offered
  `TAKE 0026`.
- `.claude/backlog/QUEUE.md`'s header documents `./next --drift` as the gate on a backlog where
  that command does not run.
- `close` landed as a template while this backlog had none of the three installed, so the `verify`
  session closing the ticket that *built* `close` could not use it.
- Claims here are made by hand under `.lock`, against precisely the rules the scripts exist to
  remember — and a by-hand lock has three silent failure modes now recorded in
  `CONCURRENCY-INCIDENTS.md`.

Instantiating one script alone would be worse than none: it would hide the asymmetry rather than
remove it. All three land together or none do.

## Functional requirements

- FR1 — `.claude/backlog/` contains `next`, `claim` and `close`, copied from
  `skills/queue/templates/`, each executable (`chmod +x`).
- FR2 — the copies are byte-identical to the templates at the commit that installs them. Any
  divergence this backlog needs is a defect in the template, fixed there and re-copied — a local
  edit is the two-conventions defect 0024 exists to forbid.
- FR3 — `./next develop`, `./next verify`, `./next --waiting` and `./next --drift` all run against
  this backlog's real table and produce output consistent with reading it by hand.
- FR4 — `./next --drift` exits zero, or every disagreement it reports is fixed in this ticket and
  named in the notes. Installing a drift gate on a drifted table is how the gate gets ignored.
- FR5 — `.gitignore` excludes `.claude/backlog/.lock/` so a transient lock cannot be committed
  (`CONCURRENCY.md`, *Lock every write to `QUEUE.md`*). Confirm rather than assume; this backlog
  has been locked by hand repeatedly.
- FR6 — the install is recorded where the next reader of the templates will see it: `queue` Step 0
  instantiates into a *new* backlog, and nothing instantiates into one that predates the scripts.
  Give Step 0 that second case so the next project in this position is not a sixth finding.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Record that the templates and this backlog's copies must stay identical, and which direction a fix flows | `documentation-conventions.md` |
| Dependencies | The scripts must run on this machine's `/bin/sh` with no new dependency — they already declare `sh`, `awk`, `wc` | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `.claude/backlog/`, when `ls -l next claim close` runs, then all three exist and
  all three are executable.
- [ ] AC2 — Given the installed copies, when each is diffed against its template
  (`diff .claude/backlog/next skills/queue/templates/next`, and the same for `claim` and `close`),
  then every diff is empty.
- [ ] AC3 — Given this backlog's table, when `.claude/backlog/next develop` runs, then it names the
  topmost takeable `next: develop` row, and that row is the same one a by-hand read of the table
  selects under the `blocked_by`-not-`Status` rule.
- [ ] AC4 — Given this backlog, when `.claude/backlog/next --drift` runs, then it exits zero.
- [ ] AC5 — Given a claim taken with `.claude/backlog/claim <id>` on a scratch row, when
  `git log -1 --name-only` is read, then the claim is already committed, and `.lock/` is gone.
- [ ] AC6 — Given `.gitignore`, when it is read, then `.claude/backlog/.lock/` is ignored, and
  `git status --porcelain` shows nothing for it while a lock is held.
- [ ] AC7 — Given `queue` Step 0, when it is read, then it covers instantiating the scripts into an
  existing backlog that lacks them, not only scaffolding a new one.

## QA plan

- **Level:** verify — shell scripts with no runner, plus documentation.
- **Why this level:** the scripts have their own suites already (`tests/claim.test.sh`,
  `tests/close.test.sh`, `tests/next.test.sh`); what this ticket adds is *installation*, which is a
  file-presence and file-identity check plus one live run of each mode.
- **Specific checks:** the three `diff`s from AC2; `./next develop`, `./next verify`, `./next
  --waiting`, `./next --drift` executed with output shown; a claim and release on a scratch row
  with `git log` inspected; `tests/*.test.sh` still green afterwards.

## Out of scope

- Changing what the scripts *do*. 0006 rewrites `next`'s parsing and 0007 replaces the ownership
  mechanism; this ticket installs what exists today.
- Fixing `fm_list`'s YAML comment handling — that is 0031, and installing the current behaviour
  first is what makes 0031 testable here.
- Reconciling `close`'s definition of *held* with `CONCURRENCY.md` — that is 0029.

## Notes & decisions

- Why not simply symlink the templates: the templates are the shipped artifact and a symlink would
  make this backlog's behaviour change silently whenever a template edit lands mid-session. Copies
  plus AC2's identity check makes the coupling explicit and auditable.

### Develop pass, 2026-08-23 (claim 8e08)

- **FR2 needed a permanent guard, not a one-time check.** AC2's three `diff`s are true at the
  install commit and say nothing the day after: the next template edit diverges the copies silently,
  in the one direction no failure ever points at. `tests/backlog-scripts-installed.test.sh` holds
  AC1, AC2, AC6, AC7 and the `/bin/sh` NFR, so the identity is asserted on every suite run. Written
  first, confirmed red on all twelve install assertions, then green.
- **Table drift is deliberately *not* asserted in that suite.** `./next --drift` is the gate FR4
  names, and it reads live backlog state — a suite assertion over it would go red on any unrelated
  ticket's close, and this ticket is not the place to adopt a fragile check.
- **FR4 needed no fixing: `--drift` exited zero on the first run.** All four modes agree with a
  by-hand read — `develop` skipped 0026 (`waiting`) and this row (`in-progress`) and offered 0028;
  `verify` correctly found nothing takeable; `--waiting` printed 0026's question.
- **`claim` and `close` were exercised only on their refusal paths here.** No-args, unknown id,
  a `waiting` row, a missing token, and a `develop`-stage close all refused with the right exit code
  and leaked no `.lock/`. AC5's live claim on a scratch row is left to `verify` rather than
  manufactured against the real table; the identity guard is what carries `tests/claim.test.sh`'s
  and `tests/close.test.sh`'s coverage onto the installed copies.
- **TDD order was clean for FR1/FR2/FR5 and inverted for FR6.** The Step 0 prose was written before
  its AC7 assertion; the assertion was then proved red against `git show HEAD:skills/queue/SKILL.md`
  rather than assumed. Recorded because the diff cannot show it.
- **An inline YAML comment in `touches:` would have poisoned `./next`'s own overlap report.** The
  develop skill says to mark a file you are about to create as new, inline; `fm_list` does not strip
  `#` comments (0031), so doing that here would feed the comment text to the very reader this ticket
  installs. The three new files are named in prose instead. 0031 owns the fix.
- **The `skills/queue/SKILL.md` overlap resolved itself mid-session.** 0030 held that file in
  `touches:` when this row was claimed, so FR1–FR5 were built first and FR6 deferred; 0030 closed at
  22:18 and released it. Ordering a ticket's FRs around another session's file scope, rather than
  stepping over the row, is what made the whole ticket deliverable in one pass.

### Verify pass, 2026-08-24 (claim b8d3) — PASS

- **Every green check was proved capable of red.** Five mutations, each restored by the single path
  mutated: a line appended to `.claude/backlog/next` (AC2 red), `chmod -x` on `close` (AC1 red), the
  `.gitignore` line removed (AC6 red), the Step 0 paragraph deleted (AC7 red on both assertions).
- **The fifth mutation is the one worth keeping.** AC7's assertion greps *inside* an `awk`-extracted
  Step 0 range, so the paragraph was **moved out of Step 0 to the end of the file** rather than deleted:
  still present file-wide, still red. That distinguishes a scoped check from a file-wide grep that would
  have passed on the neighbouring scaffold prose — the adjacent-measurement failure mode.
- **AC5 was exercised in a clone, not the live table.** A `develop` session claimed 0028 (token 3882)
  ninety seconds after this claim, so inserting and removing a scratch row in the shared `QUEUE.md` was
  not safe. `git clone` to the scratchpad, scratch row 0099, then `./claim` → committed as one commit over
  both paths with `.lock/` gone and nothing uncommitted; `./close` refused on a wrong stage, then on a
  wrong token, then closed cleanly. Same bytes, no live table touched. Parked as a finding: AC5's wording
  asks for something the concurrency rules can forbid.
- **AC6's silence was controlled for.** A lock was held while `git status --porcelain` printed nothing,
  then an *unignored* file in the same directory was shown to appear — so the silence is the ignore rule
  working, not git being blind to the path.
- **`--drift`'s zero was re-derived by hand, and the first attempt was wrong.** A block-list `awk`
  extraction read five `blocked` items as having empty `blocked_by`, which looked like drift; they use the
  inline `blocked_by: ["0002"]` form. Every `blocked` row does name an open dependency. The lesson is
  about the frontmatter carrying two list syntaxes, which 0031's `fm_list` work will meet again.
- **Newly-reachable pass:** the install makes `close`'s destructive path — deleting a row from `QUEUE.md`
  — runnable in this repo for the first time. Nothing auto-invokes it (no hook or setting references the
  three scripts), and both write-scripts commit by pathspec (`git commit -q -m … -- <paths>`, no `add`,
  no `stash`, no `-a`) and never remove `.git/index.lock`.
- **The verifying session was not running the code under test**, as `verify` Step 2 predicts: the
  installed plugin is two merged tickets behind this repo. The repo copy was taken as authority and the
  cache confirmed to hold no local edits of its own.
