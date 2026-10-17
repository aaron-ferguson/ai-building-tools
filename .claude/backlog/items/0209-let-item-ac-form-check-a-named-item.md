---
id: "0209"
title: Let item-ac-form check a named item, whatever its stage and wherever it lives
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-17
source: agent
parent:
blocked_by: []
relates: ["0150"]
expects:
  - tests/item-ac-form.test.sh
  - skills/design/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

`design` Step 4 tells a session to run `tests/item-ac-form.test.sh` before the handoff. Two sessions
showed that green is about other items:

- **quantum-catan 0034 (2026-10-11):** the script resolves `ROOT` from its own location
  (`ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"`, line 30), so run from a project it checks
  the tools repo's items. Checking the project's own items meant copying the script beside a copy of them.
- **AetherWorks 0110 (2026-10-17):** its AC3 skips items still at `next: design`, and the handoff is
  what moves the row to develop — so run before `./handoff` it reported `8 passed` over other items
  and never read the new criteria.

Retro 2026-10-17 corrected Step 4's prose to say so and to check the form by eye meanwhile; this row
makes the check runnable as the step intends.

## Functional requirements

- FR1 — `tests/item-ac-form.test.sh <item-path>...` checks exactly the named item files, regardless
  of their `next:`, and reports each by path.
- FR2 — With no argument it behaves as today (the repo's own backlog, design rows skipped).
- FR3 — `design` Step 4 names the path form, run on the item before `./handoff`, and drops the
  eyeball fallback the retro wrote.

## Acceptance criteria

- [ ] AC1 — Given an item at `next: design` with a numbered-list criterion, when the test runs with that item's path from a directory outside the tools repo, then it fails naming that path.
- [ ] AC2 — Given the same item rewritten to `- [ ] ACn — ` lines, when the test runs with its path, then it passes and reports one item checked.
- [ ] AC3 — Given no argument, when the test runs, then its output and exit status match HEAD's on the tools backlog.
- [ ] AC4 — `skills/design/SKILL.md` Step 4 names `tests/item-ac-form.test.sh <item>` and no longer carries the by-eye fallback — checked by grep.

## Notes & decisions

- Filed by retro 2026-10-17 (AetherWorks run-20261017T193821Z) from two findings entries, one per buffer.
