---
id: "0238"
title: Decide whether a ticket-pinned path in the current repo stands in for prototype.root at level 3
type: chore
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-11-18
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/prototype/SKILL.md
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

AetherWorks item 0027 required real-component fidelity on `src/ui/screens/HowToPlay.tsx`. With no
`prototype:` block, `skills/prototype/SKILL.md`'s configuration table says level 3 **stops** — though
nothing would have been invented: the ticket pins the file, and the stack is the repo the skill runs
in. The session proceeded on a throwaway branch instead.

## Open design question

Does a ticket-pinned path in the current repo stand in for `prototype.root` at level 3 — and what
then stands in for `routes_file`, `build_command` and `serve_url`, which the level-3 steps also read?
Or does the stop stay, with the message naming the minimal block to add?

## Functional requirements

- FR1 — The configuration table and the level-3 section agree on the answer, and the case
  (base product = this repo, ticket names the file) is named explicitly.

## Notes & decisions

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.
