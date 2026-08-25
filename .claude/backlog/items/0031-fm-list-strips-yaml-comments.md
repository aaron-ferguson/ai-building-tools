---
id: "0031"
title: Strip YAML comments in next and claim's fm_list
type: bug
next: verify
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - tests/next.test.sh
claimed_by: "3e26"
claimed_at: 2026-08-25T02:13:10Z
touches:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - tests/next.test.sh
  - .claude/backlog/items/0031-fm-list-strips-yaml-comments.md
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

### Built 2026-08-24 [f0c3]

- **FR1's `claim` half is vacuous — `claim` has no `fm_list` and parses no frontmatter list at
  all.** It reads three scalars (`status`, `claimed_by`, `claimed_at`) with its own inline `awk`
  and writes them back; `fm_list` exists only in `next` (and its installed copy). Nothing was
  changed in `claim`, and `expects:` naming it was the prediction, not the code. The helper the FR
  was probably reaching for is `close`'s `fm_value`, which is a different function with a different
  defect — see the parked finding below.
- **A second defect in the same helper, not named by the ticket: a comment on its own line inside a
  block *truncated* the list.** `inside { exit }` ended the block at the first line that was not a
  `- ` entry, so `touches:` with a note between two paths returned only the first. That is worse
  than the reported symptom — the reported one prints noise, this one silently drops a claimed
  file, which is the fail-open the ticket is about. Fixed here because it is the same one-line
  reading of the same block; covered by AC3b.
- **Behaviour change worth knowing at review: block entries no longer have *every* double quote
  stripped.** The old line ran `gsub(/"/, "")` over the whole entry, so `- foo"bar` yielded
  `foobar`. `decomment` consumes only a quote that opens the entry and its partner, so that entry
  now yields `foo"bar`. More correct, and nothing in the tree relies on the old form.
- **AC6's mutation, run twice and diffed both times.** Deleting the `#` cut reds 8 of 39
  assertions (AC1 ×2, AC3 ×1, AC4 ×1, AC5 ×4). Deleting the quote-mode line instead reds 4 — all of
  them AC5's, because `blocked_by: - "0002"` then parses as `"0002"` and matches no item file — so
  the quote handling is load-bearing well beyond AC2.
- **AC2 does not red against a *partially* naive implementation, and a verify session should not
  expect it to.** With quote-mode removed but the whitespace rule kept, `docs/a#b.md` still
  survives: in YAML a `#` mid-token is not a comment, so the whitespace rule alone protects the
  unquoted case. AC2 only reds against the fully naive `sub(/#.*/, "")` form FR2 actually names —
  both the quote-mode line and the whitespace guard removed, which was the third mutation run here
  and gave `"docs/a`. Mutate both, or the guard reads as unwired.
