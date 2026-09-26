---
id: "0185"
title: Decide whether the sprint's run logs are committed, and what may appear in them if they are
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-23
source: agent
parent:
blocked_by: []
relates: ["0184", "0163", "0179"]
expects:
  - .gitignore
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by: "04ad"
claimed_at: 2026-09-26T05:20:06Z
touches:
  - .gitignore
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
---

## Problem

**`.claude/backlog/runs/` has never been tracked, nothing says whether it should be, and the one
line that speaks to it implies the opposite of what happens.** Every sprint dispatches its stages
onto a tree showing `?? .claude/backlog/runs/`, so no stage can start on a clean tree however
carefully the previous one committed.

Evidence, checked 2026-09-23:

- `.gitignore` ignores only `.claude/backlog/runs/.active/`, commented *"The single-instance marker,
  never the run logs beside it. Committed, a marker makes every clone of this repo report that a
  supervisor is already driving the backlog."* That reads as the logs being meant for commit.
- `git ls-files .claude/backlog/runs` is empty and `git log -- .claude/backlog/runs` has no commits:
  39 files, 196K, never committed.
- `skills/sprint/SKILL.md` Step 5 writes `runs/<run-id>.jsonl` and says `findings_max_sprints`
  counts `sprint_ended` events *across the whole of `runs/`* — a count a fresh clone cannot
  reproduce if the logs are machine-local. Each stage's stdout and stderr are captured beside the
  log as `runs/<run-id>.<session-id>.out` and `.err.txt`.
- Parked by retro session edf44941-de11-48ca-92b8-093a50099f9b: nothing it found said whether
  `runs/` is meant to be tracked.

**This repo is public** (`CLAUDE.md`, `company: none`). The stdout and stderr captures are
unfiltered stage output, so committing `runs/` wholesale is a publication decision, not a tidy-up.

## Functional requirements

- **FR1** — `runs/` is machine-local, all of it: the `.jsonl` logs, the stage stdout/stderr
  captures, and any hand-written file a run leaves there. Stated in `skills/sprint/SKILL.md` Step 5,
  where the run log is first described, and not only in this repo's `.gitignore`.
- **FR2** — This repo's `.gitignore` ignores `.claude/backlog/runs/` whole, and its comment says why
  (machine-local provenance; the ledger is the committed record) instead of implying the logs beside
  `.active/` are meant for commit.
- **FR3** — Nothing under `runs/` is committed, so no capture needs a privacy screen; the skill says
  the captures are never committed because they are unfiltered stage output.
- **FR4** — Step 5 states that `findings_max_sprints` counts completed sprints **on this machine**:
  a fresh clone counts zero, so the age half of the gate cannot cross until a sprint ends there, and
  the count half is unaffected.
- **FR5** — What ships: Step 1's marker block writes a self-ignoring `.claude/backlog/runs/.gitignore`
  (contents `*`) when it creates `runs/`, idempotently, so every project the plugin drives gets the
  same answer without editing its own root `.gitignore`.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Privacy | No file under `runs/` is committed in this public repo | AC3's guard: `git ls-files .claude/backlog/runs` non-empty, or a sample path not ignored | `data-privacy-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md` Step 5, when it describes the run log, then one line states `runs/` is machine-local and never committed — logs, captures and hand-written files alike — and that `LEDGER.md` is the committed record; a guard in `tests/sprint.test.sh` asserts the phrase and goes red when it is removed.
- [ ] AC2 — Given a fresh git repository fixture with no `runs/`, when `tests/sprint.test.sh` extracts Step 1's marker fenced block from the skill and runs it, then `.claude/backlog/runs/.gitignore` exists containing `*`, a `.jsonl` file written into `runs/` afterwards does not appear in `git status --porcelain`, and running the block a second time leaves the file unchanged; the existing AC18 marker guards stay green.
- [ ] AC3 — Given this repo, when the guard runs, then `git check-ignore -q .claude/backlog/runs/run-X.jsonl` exits 0, `git ls-files .claude/backlog/runs` is empty, and `.gitignore` no longer carries the `.active/`-only line or the comment calling the rest "the run logs beside it".
- [ ] AC4 — Given Step 5's "One fact crosses runs" paragraph, when it names `findings_max_sprints`, then it states the count is per machine and that a fresh clone starts at zero completed sprints, so the age half fires later, never earlier; the existing `One fact crosses runs` guard stays green.
- [ ] AC5 — Given the full suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it is green, with no guarded phrase straddling a line break.

## QA plan

`unit`: the new guards in `tests/sprint.test.sh` (AC1–AC4), each shown red against the unchanged
skill or `.gitignore` before the change, then the full suite (AC5).

## Out of scope

- The supervisor's uncommitted park — that is `0184`.
- Deleting or rewriting the 39 existing local run files; the decision says what happens next, and
  the author disposes of the history.
- `tests/measurement.test.sh`: with nothing under `runs/` committed there is nothing for its
  private-names check to screen (FR3).

## Notes & decisions

- 2026-09-23 — Swept from `FINDINGS.md` (the retro's park of 2026-09-23), the entry's second half.
  Routed to `design` on trigger 1: the ACs cannot be written until tracked-versus-ignored is chosen,
  and the choice is a publication decision on a public repo. `size: m`.
- 2026-09-24 — **Decided (design, session under /sprint): `runs/` is ignored whole — shape 2.**
  Prior art settled most of it: `skills/sprint/SKILL.md` Step 5 already calls the log "per-run,
  uncommitted and deletable" against a committed `LEDGER.md`, and already reasons through deleting
  the history (the age half of the gate resets and fires *later*, never earlier). The ticket's
  evidence missed that line; the only contradiction is the `.gitignore` comment, so the fix aligns
  the comment with the skill rather than the skill with the comment.
  **Rejected — tracked (1) and split (3):** committing the `.jsonl` at run end is a git write by a
  supervisor that Step 7 keeps off the backlog lock, on an index other sessions share; the log
  carries escalation text and stage `detail` strings, which are LLM output bound for a public repo;
  and the only private-names screen (`tests/measurement.test.sh`) skips when `.private-names` is
  absent, so it cannot be a publication gate on any other machine. All that buys is a reproducible
  age count on a fresh clone, which the product already accepted losing. Tracking would win if the
  project became multi-machine and the age gate's reset were observed to leave a buffer unswept.
  **Trade-off accepted:** a fresh clone's age half starts at zero (FR4); the run history lives on
  one machine, and its committed residue is the ledger row.
  **What ships (FR5):** a self-ignoring `runs/.gitignore` written beside `mkdir -p`, so other
  projects need no root `.gitignore` edit — chosen over telling the user to add a line, which is an
  instruction a session must remember rather than a check.
  **Accounting against the drafted requirements:** FR1, FR2, FR4 confirmed and made concrete; FR3
  confirmed as vacuous (nothing committed, nothing screened), so `tests/measurement.test.sh` left
  `expects:`; FR5 added. ACs authored — the ticket arrived with none. Observed 2026-09-24: 8 local
  `.jsonl` logs, 9 `sprint_ended` events between them; they stay in place and become ignored.
