---
id: "0185"
title: Decide whether the sprint's run logs are committed, and what may appear in them if they are
type: bug
next: design
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
  - tests/measurement.test.sh
claimed_by: "974f"
claimed_at: 2026-09-24T13:36:24Z
touches:
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

## Open design question

**Is `runs/` history the project records, or machine-local scratch?** Three shapes, none yet chosen:

1. **Tracked** — the `.jsonl` logs committed at run end (as the ledger already is), which makes the
   `findings_max_sprints` count reproducible; then decide whether the `.out`/`.err.txt` captures are
   committed too, and what screens them against the privacy guard before a public commit.
2. **Ignored** — `runs/` added to `.gitignore` whole; then the `.gitignore` comment is rewritten, and
   the `findings_max_sprints` count is stated as per-machine, since a clone starts at zero.
3. **Split** — `.jsonl` tracked, captures ignored.

The answer also decides what the plugin **ships**: the sprint skill runs in other projects, which
need the same answer without reading this repo's `.gitignore`.

## Requirements for design to carry through

- **FR1** — One recorded answer for which files under `runs/` are tracked, stated in
  `skills/sprint/SKILL.md` where the run log is first written, not only in this repo's `.gitignore`.
- **FR2** — This repo's `.gitignore` and its comment agree with FR1.
- **FR3** — If any capture is committed, name what screens it for the privacy rule before the
  commit (`tests/measurement.test.sh` holds the private-names check today).
- **FR4** — State what `findings_max_sprints` counts on a fresh clone under the chosen answer.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Privacy | No committed file under `runs/` carries anything the repo's privacy rule forbids | prose only — no artifact yet | `data-privacy-conventions.md` |

## Out of scope

- The supervisor's uncommitted park — that is `0184`.
- Deleting or rewriting the 39 existing local run files; the decision says what happens next, and
  the author disposes of the history.

## Notes & decisions

- 2026-09-23 — Swept from `FINDINGS.md` (the retro's park of 2026-09-23), the entry's second half.
  Routed to `design` on trigger 1: the ACs cannot be written until tracked-versus-ignored is chosen,
  and the choice is a publication decision on a public repo. `size: m`.
