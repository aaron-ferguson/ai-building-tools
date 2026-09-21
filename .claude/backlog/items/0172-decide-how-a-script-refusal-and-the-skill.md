---
id: "0172"
title: Decide how a script refusal and the skill that must satisfy it reach a session together
type: debt
next: design
status: ready
qa_level: verify
size: m
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0061", "0064"]
expects:
  - skills/develop/SKILL.md
  - skills/retro/SKILL.md
  - skills/queue/templates/close
claimed_by:
claimed_at:
touches:
---

## Problem

**A committed backlog script and the skill that drives it take effect at different times, so a
refusal can land on a session before the instruction that explains it.** `0160` gave `close` a sixth
refusal — a `close_by: verify` ticket needs a `Conventions: <path>` line in its QA evidence — and
taught `skills/verify/SKILL.md` to write one. `.claude/backlog/close` is a committed file and binds
the very next session; a skill resolves from `~/.claude/plugins/cache/` at session start, so until a
release the next verify session meets a refusal its own instructions never mention.

The window opens for **any ticket whose FRs pair a script refusal with a skill change that satisfies
it**, and nothing in `develop` Step 5 or the release checklist asks which half binds first. `0160`
was survivable only because the refusal text names the missing line and the fix — which was luck, not
design.

## Open design question

**What makes a script-and-skill pair safe to land, given the two halves bind at different times?**

- **Question:** does such a pair have to release atomically — the build session blocked from
  committing the script until the skill is released — or does a new refusal degrade to a warning for
  one release cycle and harden afterwards?
- **Why it blocks specification:** the two answers produce incompatible criteria. Atomic release
  needs a gate in `develop` Step 5 and a way for a build session to trigger a release it is
  otherwise forbidden to run; a degrading refusal needs a version or date stamp in the script and a
  second ticket to harden it, which is a mechanism this repo has never carried.
- **Settle it with:** `/design`

Constraints the decision may not break: an unattended stage cannot run `tools/release` (`sprint`
Step 8), so "release before committing the script" cannot be the whole answer for a driven run.

## Out of scope

- Re-litigating `0160`'s refusal, which is correct.
- Making skills resolve at any time other than session start; that is not this repo's to change.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park made while building `0160`. Routed to `design` because
  both candidate answers are whole mechanisms and neither is obviously right.
