---
id: "0031"
title: Strip YAML comments in next and claim's fm_list
type: bug
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - tests/next.test.sh
claimed_by: "f0c3"
claimed_at: 2026-08-24T14:42:17Z
touches:
---

## Problem

`fm_list` in `skills/queue/templates/next` (and the same helper in `claim`) reads a YAML
frontmatter list without stripping `#` comments. An inline comment on a `touches:` entry is
returned as part of the list, so `./next`'s CLAIMED FILES block prints comment text as though it
were a claimed file.

Annotating a frontmatter list is a natural thing to do — `develop` Step 1 explicitly tells a session
to *"declare a file you will create the same way and say inline that it is new"*, which invites
exactly this — and there is nothing to warn you. The consequence is a scope-overlap check run
against a file list containing prose, which is the check that decides whether two sessions collide.

Found on 0024.

## Functional requirements

- FR1 — `fm_list` strips a `#` comment from each entry it returns, in both `next` and `claim`.
- FR2 — a `#` inside a quoted value is **not** treated as a comment start. YAML allows
  `- "docs/a#b.md"`, and a naive `sed 's/#.*//'` silently truncates a legitimate path.
- FR3 — an entry that is *only* a comment yields no list element rather than an empty string, so
  the CLAIMED FILES block does not print blank rows.
- FR4 — trailing whitespace left behind by stripping a comment is removed, so a comparison against
  another item's `touches:` matches on the path rather than on the path plus spaces. A silently
  failing overlap comparison is the actual damage here.
- FR5 — the same treatment applies to every frontmatter list `fm_list` serves — `expects:`,
  `touches:`, `blocked_by:` — not only to `touches:`. A comment on a `blocked_by:` entry would
  otherwise produce a ticket id that matches nothing and reads as an unsatisfied blocker.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Dependencies | `sh`, `awk`, `sed` only; no new dependency for a parsing fix | `dependency-conventions.md` |
| Documentation | If quoted-`#` handling makes the parser non-trivial, say in a comment why the simple form is wrong — the next reader will otherwise simplify it back | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an item whose `touches:` entry carries an inline `# new file` comment, when
  `./next develop` runs, then the CLAIMED FILES block shows the path alone, with no comment text.
- [ ] AC2 — Given an item whose `touches:` entry is a quoted path containing a `#`, when `./next`
  reads it, then the whole path is returned unmodified.
- [ ] AC3 — Given a frontmatter list containing a line that is only a comment, when `fm_list` reads
  it, then that line produces no element and no blank row appears in the output.
- [ ] AC4 — Given a `touches:` entry with a comment stripped, when it is compared against another
  item's `expects:` entry for the same path, then the two compare equal — no trailing whitespace
  defeats the match.
- [ ] AC5 — Given an item whose `blocked_by:` entry carries an inline comment, when `./next --drift`
  runs, then the blocker id is parsed correctly and no phantom open blocker is reported.
- [ ] AC6 — Given `tests/next.test.sh`, when the comment-stripping logic is mutated away, then the
  suite goes red; the mutation is diffed first to confirm it landed.
- [ ] AC7 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then all
  suites pass.

## QA plan

- **Level:** verify — shell parsing with an existing scripted suite.
- **Why this level:** `tests/next.test.sh` already drives `./next` against fixture backlogs; these
  are new fixture cases in that suite, and the fixtures are authored rather than copied from the
  real tree.
- **Specific checks:** new cases in `tests/next.test.sh` covering AC1–AC5; the AC6 mutation diffed
  and run; the full sweep.

## Out of scope

- Any other `fm_list` behaviour — multi-line values, nested lists, anchors. This ticket fixes
  comment handling only; YAML is not being implemented here.
- Rewriting `next`'s parsing to walk ancestors, which is 0006.

## Notes & decisions

- The overlap check is the reason this is a bug rather than cosmetic: `develop` Step 1 compares
  `expects:` against every `in-progress` `touches:`, and a trailing space or an appended comment
  makes a real collision compare unequal. It fails open — the session takes the row and both
  windows land in one file.
