---
id: "0076"
title: Make a tool edit run the target repo's suite before it commits
type: bug
next:
status: done
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
closed: 2026-09-08
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

- [x] AC1 — `skills/retro/SKILL.md` requires the target repo's suite to run before the commit that
  carries a tool edit.
- [x] AC2 — It names the live-repo-commit pollution and the worktree-at-`HEAD` comparison as the
  discriminator.
- [x] AC3 — It says a rejecting guard is answered by relocating first, exempting second.
- [x] AC4 — Deleting the suite-run sentence turns the new guard red.

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

- **Built 2026-09-05. The guard is `tests/retro-tool-edit.test.sh`, not the predicted
  `tests/skill-prose.test.sh`.** Every guard in this repo is named for the claim it makes —
  `qa-level-once`, `falsifiable-acs`, `citations`, `batching` — and a name for a *category* of prose
  is the one shape that invites accretion, since nothing in it says what does not belong. `0075`
  writes its QA plan as *"extend `tests/skill-prose.test.sh` (or add a case where the retro guards
  live)"*, so this file is that home and 0075 needs no new one.

- **One assertion passed before the rule existed, and that is the finding.** FR4's check was first
  written as the phrase `in the same turn`, which Step 5's pre-existing *Commit by pathspec* bullet
  already satisfies — so it was green over a file with no worktree rule in it at all, the
  guard-that-cannot-fail shape `testing-conventions.md` names. Caught only because the red run was
  read case by case rather than by its tally. Anchored to `worktree in the same turn`, which nothing
  but the new rule can satisfy.

- **`skills/retro/SKILL.md` is now 19,619 bytes against `skill-size.test.sh`'s 20,190 goal** — 571
  bytes of headroom, and `0075` adds to this same step. It is the next edit here that has to answer
  the payback test, not this one.

- **The live tree carries one red that is not this ticket's.** `citations.test.sh` AC1 reports
  ``skills/queue/templates/claim`` citing *"The # working tree is shared too"*, which entered with
  commit `3588524` (item `0082`, another session) — a new comment paragraph wraps a `CONCURRENCY.md`
  citation across a comment line, so the guard reads the `#` as part of the rule name. It is the
  *"rewrapping a guarded paragraph is a breaking change"* hazard in `CLAUDE.md`, arriving from the
  other direction. **The whole suite is green at `28e48f6`, this ticket's tip** — 19 files, 800
  assertions, 0 failed, run in a worktree sited beside a symlinked conventions directory.

- **Taken out of rank order, deliberately.** `0086`, `0078` and `0075` all rank above this row and
  all three collide with the file scope held by `0081`'s live `verify` session (`skills/develop/SKILL.md`,
  `skills/verify/SKILL.md`, with `touches:` empty, so held). `0086` was claimed and released
  (token `f7c0`) on discovering the overlap; nothing was edited under it.
