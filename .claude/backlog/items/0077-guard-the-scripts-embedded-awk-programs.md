---
id: "0077"
title: Guard the backlog scripts against a broken embedded awk program
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0076"]
expects:
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/templates/close
  - skills/queue/templates/claim
  - skills/queue/templates/next
claimed_by:
claimed_at:
touches:
---

## Problem

**`close`, `claim` and `next` embed `awk` programs inside single quotes, and their comments carry the
reasoning — so a prose comment inside one is a live shell-quoting hazard.** An apostrophe closes the
`'...'` wrapping the whole program.

Measured 2026-09-01: a comment reading ``other projects' spellings`` was added inside `close`'s
DONE-row builder. The result was not a syntax error at edit time. `close.test.sh` failed **20 of 63**
cases, reporting an **empty reconcile list** and a **commit carrying six extra files** — a signature
that reads as broken reconcile logic, and which named nothing about quoting. The cause was found by
reading the diff, not by any diagnostic.

The hazard is structural rather than careless: these scripts are deliberately comment-heavy, because
each comment carries the incident behind a rule, and the natural English for such a comment contains
apostrophes. **`sh -n` on each script would have caught it in under a second**, before the behavioural
suite ran at all.

## Functional requirements

1. **`tests/backlog-scripts-installed.test.sh` runs `sh -n` on every script it already checks** —
   `next`, `claim`, `close`, in both the template and the installed copy — and fails naming the
   script whose syntax is broken.
2. **The check runs before the byte-identical comparison**, so a syntax error is reported as one
   rather than as a divergence.
3. **State the convention where the scripts are documented**: prose inside a single-quoted `awk`
   program takes no apostrophe, and the reason is the quoting, not style.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | The new guard is proved able to fail by introducing an apostrophe into a template's `awk` comment and confirming it reds, then restoring by the path mutated. | `testing-conventions.md` |
| Dependencies | `sh -n` is POSIX and already required by these tests. Adds nothing. | `dependency-conventions.md` |

## Acceptance criteria

1. `tests/backlog-scripts-installed.test.sh` runs `sh -n` on each of the three templates and each
   installed copy.
2. Introducing an apostrophe inside a template's `awk` comment turns that test red, naming the script.
3. The failure message says the script's syntax is broken, not that it diverged from its template.
4. The convention against apostrophes in embedded `awk` comments is stated where the scripts are
   documented, with the quoting as its reason.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** the deliverable is a shell test guarding shell scripts.
- **Specific checks:** run the new case; then mutate — insert `# it's` into `templates/close`'s awk
  block, confirm red and that the message names `close`, restore with `git checkout -- <that path>`
  and confirm green. A no-op control run per `testing-conventions.md`.

## Out of scope

- Rewriting the scripts to avoid embedded `awk`. The programs are correct; the guard is the cheap fix.
- `shellcheck`. A dependency this repo does not have, for a defect `sh -n` already catches.

## Notes & decisions

- The defect that prompted this was introduced and fixed inside the AetherWorks retro of 2026-09-01;
  the fix shipped in `e3514b4`/`e5ad319`. This item is the guard, not the fix.
