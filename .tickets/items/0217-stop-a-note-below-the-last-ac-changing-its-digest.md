---
id: "0217"
title: Stop a note written below the last AC from changing that AC's digest
type: bug
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/next
  - skills/develop/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
`./next --ac-digest` hashes everything from an AC's checkbox to the next one, so a note appended below the last AC is hashed into it. On 0182 a develop stop note after AC10 made `--drift` report AC10 changed with its text untouched; moving the note to *Notes & decisions* restored `d0d0b2b8`. **It recurred 2026-10-26 on the same ticket** (the 7bff build note, a day after e50b7c4 fixed the first) — the prose guidance is not holding it.

## Established, not yet specified

- Either `--ac-digest` ends an AC at a line that is not a `- [ ] ACn` continuation, or `develop`'s re-entry guidance names where a stop note goes. The recurrence argues for the script fix: a note's position is not something a session reliably reads guidance about.

## Notes & decisions
