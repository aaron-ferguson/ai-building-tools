---
id: "0118"
title: Run the privacy guard where a sweep commits, not only where a suite runs
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0100"]
expects:
  - skills/queue/SKILL.md
  - skills/retro/SKILL.md
  - tests/findings-routing.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**This repo is public, it has a guard against publishing a real home path, and nothing in the
steps that commit to it runs that guard.** `2a69aa9` redacted two published home paths and fixed
the guard that could not tell a redaction from a leak — but the defect it fixed was *introduced*
by `b9d11af`, a sweep session committing tracked files with no cue to check. A `queue` or `retro`
pass that parks or lands prose can commit a file that reds the privacy guard and never find out;
the suite is what discovers it, and neither skill's steps run the suite for a prose park.

`CLAUDE.md` states the rule — this repo is public, no company material reaches it — and the guard
exists to enforce it. The gap is entirely one of *reach*: the rule is written and the check is
committed, and the sessions most likely to violate it are the ones that run neither.

## Functional requirements

- FR1 — the step in which `queue` commits a parked finding names the privacy guard and requires it
  to have run over the paths being committed.
- FR2 — `retro` Step 6 does the same for its own park, which is committed by pathspec in the same
  turn it is written.
- FR3 — the requirement names the command, not the concept, so a session can run it without
  deriving which guard is meant.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The rule being enforced is `CLAUDE.md`'s public-repo constraint; cite it, do not restate it | `data-privacy-conventions.md` |
| Documentation | Both skills state the same requirement once each, in their own voice | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given `skills/queue/SKILL.md`, when grepped for the privacy guard's command, then it
  appears in the step that commits a park; red by deleting that sentence.
- [ ] AC2 — the same for `skills/retro/SKILL.md` Step 6.
- [ ] AC3 — given a tracked file carrying a real home path, when the named command is run as the
  skills instruct, then it exits non-zero and names the file — the control that the instruction
  points at a check that actually fires.

## QA plan

- **Why that level:** prose assertions plus one live run of the guard; no runner above unit applies.
- **Specific checks:** `tests/findings-routing.test.sh`, and a scratch tracked file carrying a real
  path to prove AC3 reddens, removed in the same turn.

## Out of scope

Whether a *mention of the rule* is exempt from the guard, and the company and product names still
in item prose — that is a separate decision and has its own deferred finding. Widening the guard's
pattern at all.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from the remaining half of the `FINDINGS.md` entry that recorded the
  landed fix at `2a69aa9`. The landed half is dropped from the buffer; this is what was left
  needing a row.
