---
id: "0076"
title: Make a tool edit run the target repo's suite before it commits
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0075", "0077"]
expects:
  - skills/retro/SKILL.md
  - tests/skill-prose.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` edits skills, scripts and conventions, and no step in it runs a test.** Step 4 writes the
edits, Step 5 commits and releases them. The session that changes a tool is therefore the one least
likely to learn it broke that tool — and the break is invisible until another session trips on it.

Measured in the AetherWorks retro of 2026-09-01, which ran this repo's suite unprompted and found
two things it would otherwise have released:

1. **A shell-quoting defect already committed.** A prose comment added inside `close`'s
   single-quoted `awk` program contained an apostrophe, closing the quote. `close.test.sh` failed
   **20 of 63** cases, reporting an empty reconcile list and a commit carrying six extra files — a
   signature that reads as broken reconcile logic and names nothing about quotes. (The guard for
   that class is item **0077**; this item is about the step that runs it at all.)
2. **`skill-size.test.sh` rejected the draft twice**, at 1,387 and then 293 bytes over goal, and both
   rejections forced a rule into a **better** home than the one proposed — the `e2e` worktree rule to
   `CONCURRENCY.md` beside the rule it qualifies, and the probe rule to `testing-conventions.md`,
   which it passes the *would this be true with no backlog?* test for. The guard improved the edit.

**Two traps make "just run the suite" insufficient as advice, and both cost time in that pass:**

- **This repo's suite commits inside the live repo.** Running it over uncommitted edits produces
  failures that look like logic errors and are tree pollution — `close.test.sh` reported extra files
  in its commit assertion purely because the session's own edits were uncommitted.
- **Telling that apart from a real red needs the worktree-at-`HEAD` comparison `develop` Step 5
  already prescribes**, and `retro` never mentions it. In that pass the same suite was green at
  `HEAD` in a clean worktree and red in the working tree, which is what separated pollution from the
  genuine defect.

## Functional requirements

1. **Before committing an edit to a tool repo, run that repo's configured suite** — the `unit`
   command in its `config.yml`, which for this repo is `for t in tests/*.test.sh; do "$t" || exit 1;
   done`. A repo with no configured command is stated as such, not silently skipped.
2. **A red is the edit's until proven otherwise.** Name the worktree-at-`HEAD` comparison as the way
   to tell a real red from tree pollution, and say that this repo's suite commits in the live repo,
   which is what produces the pollution.
3. **Say the guards are editors, not gates.** A size or prose guard that rejects an edit is
   information about where the rule belongs; record the relocation it forced rather than recording
   an exemption.
4. **Remove any worktree created for the comparison in the same turn**, per `testing-conventions.md`
   *Stop what you started*.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | The rule must not license an exemption as the first response to a failing guard; relocation is the first response and a recorded justification the second. | `testing-conventions.md` |
| Documentation | States the failure prevented — a released tool that its own suite would have caught. | `documentation-conventions.md` |

## Acceptance criteria

1. `skills/retro/SKILL.md` requires the target repo's suite to run before the commit that carries a
   tool edit.
2. It names the live-repo-commit pollution and the worktree-at-`HEAD` comparison as the discriminator.
3. It says a rejecting guard is answered by relocating first, exempting second.
4. Deleting the suite-run sentence turns the new guard red.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** prose in a skill; every guard here greps prose.
- **Specific checks:** assert, each on its own line, the presence of the suite-run instruction in
  `retro` Step 4 or 5 and of `worktree` in the same step. Prove each can fail by deleting its line.

## Out of scope

- Running the suite automatically via a hook. The session has to read the result and decide, which
  is the whole point of FR2.
- Fixing the live-repo-commit behaviour of `tests/close.test.sh`. Worth its own row if it recurs;
  this item only names it so a session is not misled by it.

## Notes & decisions

- Captured by the AetherWorks retro of 2026-09-01.
