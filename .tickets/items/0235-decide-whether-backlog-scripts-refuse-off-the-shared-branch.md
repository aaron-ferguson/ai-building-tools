---
id: "0235"
title: Decide whether claim, handoff and close refuse off the branch the backlog is shared on
type: bug
next: design
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-11-18
source: agent
parent:
blocked_by: []
relates: ["0050"]
expects:
  - skills/queue/templates/claim
  - skills/queue/templates/handoff
  - skills/queue/templates/close
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

In a consuming project (AetherWorks, item 0136) a design pass began on a `prototype/` branch one
commit ahead of `main`; `./claim`, the decision and `./handoff` all committed there. On `main` the row
still read unclaimed at `next: design`, so a second session working from `main` could claim it —
the single-holder guarantee does not reach across branches. `references/CONCURRENCY.md` refuses a
linked worktree (*A second checkout never writes the backlog*) and says nothing about a non-default
branch in the primary checkout.

## Open design question

Refuse or warn when the checked-out branch is not the one the backlog is shared on — and how does a
script know which branch that is (a `config.yml` key, the remote's HEAD, or `main` by default)?

## Functional requirements

- FR1 — `claim`, `handoff` and `close` refuse (or warn, per the decision) when run off the shared
  branch, naming both branches.
- FR2 — `references/CONCURRENCY.md` states the rule beside *A second checkout never writes the backlog*.

## Notes & decisions

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.
