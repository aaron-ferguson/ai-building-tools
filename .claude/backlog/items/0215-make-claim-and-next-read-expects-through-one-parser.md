---
id: "0215"
title: Make claim and next read expects and touches through one parser that refuses or accepts the comma form
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-10-24
source: retro
parent:
blocked_by: []
relates: ["0096", "0155", "0103"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/reopen
  - skills/queue/templates/item.md
  - tests/next.test.sh
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**Two readers of the same frontmatter field disagree, and both fail open.** Parked five times in one
week from AetherWorks (2026-10-18 ×3, 2026-10-24 ×2), each from a different session:

- `fm_list` in `skills/queue/templates/next` (line ~551, copied into `close` and `reopen`) reads
  `expects:` only as an inline `[a, b]` list or a `- ` block. A bare scalar `expects: a.ts, b.ts`
  reads as **empty**: `./next develop` prints `EXPECTS not predicted — check this one by hand`, and
  `collision_report` compares nothing, so two windows can land in one file. AetherWorks 0113 carried
  four real paths in that form; 11 open AetherWorks items did on 2026-10-24 (0104, 0109, 0117, …).
- `claim`'s `touches:` seeder (line ~315, `fm && inexp && /^[ \t]+-/`) reads **only** the `- ` block.
  AetherWorks 0130 was rewritten from block to inline at `8b8da81` *"so ./next reads it"*; within the
  same minute `./next develop` printed all four paths and `./claim 0130` printed *"touches: is unset:
  0130 declares no expects:"* and seeded nothing. A claimant who trusts that message reserves no files.

`templates/item.md` gives `blocked_by:` a ONE-form note (0044 hit the same two-shape defect there) and
gives `expects:`/`touches:` none, so the writers — `queue` and `design` hand-offs — produce all three.

## Functional requirements

- FR1 — `claim`'s seeder and `next`'s `fm_list` read `expects:` through one definition, so for any
  item both report the same path list.
- FR2 — A scalar comma-separated `expects:` or `touches:` is either parsed as its paths by that one
  definition, or reported by `./next --drift` by item id and field; never read silently as empty.
  Which of the two is `develop`'s choice, recorded in *Notes & decisions*.
- FR3 — `templates/item.md` gives `expects:` and `touches:` a ONE-form note in the shape `blocked_by:`'s.

## Acceptance criteria

- AC1 — Given an item whose `expects:` is an inline `["a", "b"]` list, `./claim <id>` seeds
  `touches:` with `a` and `b`, asserted in `tests/claim.test.sh`.
- AC2 — Given the same item in block form and in inline form, `./next develop`'s EXPECTS line and
  `./claim`'s seeded `touches:` name the same paths, asserted in one test over both forms.
- AC3 — Given an item whose `expects:` is `a.ts, b.ts`, either `./next develop` prints both paths or
  `./next --drift` names that item and `expects:`; `EXPECTS not predicted` is not printed for it.
  Asserted in `tests/next.test.sh`.
- AC4 — `templates/item.md`'s `expects:` comment states one written form.

## Notes & decisions

- 2026-10-24 — Filed by retro (second leg of AetherWorks run-20261024T195310Z's tail) from five tools-buffer
  entries naming the same defect. 0096 covers two other defects in these fields (unresolved paths, a
  wrong-block edit anchor) and is not this; 0103 asks whether the scripts may share a sourced file, which
  FR1 may want — check its state before choosing how to share the parser.
