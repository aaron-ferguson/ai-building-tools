---
id: "0072"
title: Archive an escalated prototype on its own branch instead of leaving it only in the working tree
type: feature
next: develop
status: ready
qa_level: verify
size: s
created: 2026-08-26
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/prototype/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

`/prototype`'s Step 5 writes a level 2 or level 3 prototype into `prototypes/[slug]/` in the
working tree and never commits it anywhere distinct from the rest of the project's history. This
toolkit's own product conventions already treat a prototype as disposable ("a prototype is built
to be thrown away... promoting one means rewriting it under these conventions") — but disposable
code that answered a real design question is exactly the kind of thing a later `/design` or
`/develop` session benefits from being able to point back to, and today the only way to find it
again is knowing it's still sitting in the working tree, or in `git log`, undated and unlabeled as
what it was for.

A comparable external skill (`prototype`, surveyed 2026-08-26, in a third-party skills repo) keeps
every throwaway prototype on a `prototype/<name>` branch off the base branch specifically so it
survives as a **primary source** — referenced from the ticket whose design question it settled —
rather than being deleted or left to rot in an unrelated commit.

## Functional requirements

- FR1 — After a level 2 or level 3 prototype is built (Step 5) and confirmed working, the skill
  commits the `prototypes/[slug]/` directory to a dedicated branch named `prototype/[slug]`, cut
  from the project's base branch, rather than relying on the prototype surviving only in the
  working tree or the current feature branch.
- FR2 — The skill's final report names the branch, so the field-reference doc and the ticket
  comment (Steps 6 and 7 as they exist today) can point back to it as a primary source, matching
  this toolkit's existing pattern of citing sources rather than restating them.
- FR3 — Escalating a prototype from level 2 to level 3 (Step 5's existing "one document across
  levels" rule) updates the same `prototype/[slug]` branch rather than creating a second one.
- FR4 — The commit onto the `prototype/<slug>` branch follows this project's own git-conventions
  citation rule (pathspec commit, `Co-Authored-By` trailer) — cited, not restated, per this
  toolkit's own discipline.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The branch-per-prototype rule and its naming convention are stated once, in `skills/prototype/SKILL.md` Step 5 | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a level 2 or level 3 prototype confirmed working, when Step 5 finishes, then a
  `prototype/[slug]` branch exists containing the `prototypes/[slug]/` directory.
- [ ] AC2 — Given a prototype escalated from level 2 to level 3, when the level 3 build lands, then
  the same `prototype/[slug]` branch is updated rather than a new branch being created.
- [ ] AC3 — Given the skill's final report, when a prototype was built at level 2 or 3, then the
  report names the `prototype/[slug]` branch.
- [ ] AC4 — Given `skills/prototype/SKILL.md`, when read, then the commit onto the branch is
  described as following `git-conventions.md` by citation, not restated inline.

## QA plan

- **Level:** verify — the change is skill-file prose plus a scripted assertion.
- **Why this level:** no test runner applies to a markdown-only change; the assertion is a real
  git operation, checkable by a scripted assertion rather than a unit test.
- **Specific checks:** a scoped grep for the `prototype/[slug]` branch rule in Step 5; a
  scripted run of `/prototype` at level 2 against a throwaway feature, confirming
  `git branch --list 'prototype/*'` shows the expected branch afterward.

## Out of scope

- Deciding whether a prototype ever gets deleted once its branch exists — a retention question for
  whoever owns this toolkit's git housekeeping, not this ticket.
- Level 1 (diagram-only) prototypes — cheapest to produce and cheapest to throw away by design; no
  branch.

## Notes & decisions

- Captured 2026-08-26 from a comparison against a third-party skills repo's `prototype` skill
  (github.com/mattpocock/skills). This toolkit's own `/prototype` already implements "prototype as
  primary source, not a demo to delete" in spirit (the field-reference doc, the one-document-
  across-levels rule) — this ticket just gives that principle a place to physically live once the
  working tree moves on.
