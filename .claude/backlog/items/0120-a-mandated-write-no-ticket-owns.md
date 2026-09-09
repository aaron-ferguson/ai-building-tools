---
id: "0120"
title: Decide how a write no ticket can own appears to the file-scope check
type: bug
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: m
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0106", "0091", "0083"]
expects:
  - skills/queue/SKILL.md
  - .claude/backlog/config.yml
  - .claude/backlog/next
claimed_by:
claimed_at:
touches:
---

## Problem

**Claiming an ID is a mandated write to `config.yml`, so every capture session collides with
whatever ticket holds that file, and `queue` has no rule for it.** `./next develop` reported
`COLLIDES 0105 | .claude/backlog/config.yml — held by 0040 [ef8e]` and the same for `0086`, while
that capture had *already* bumped `next_id` in that file under the lock, because Step 2 requires it.

The collision is one a capture session **structurally cannot avoid and cannot resolve by taking a
different row**: it is not taking a row. Every other collision the file-scope check reports has a
remedy — take something else, or wait. This one has neither, and the check reports it with the same
words, so the only available reading is "stop", which is wrong.

Either `config.yml` is outside the `touches:` regime for the counter specifically, or capture's
write becomes visible to that regime. Today it is neither, and the ambiguity is resolved differently
by each session that meets it.

`0106` and `0091` were both opened and rejected as homes for this: `0106` is what `touches:` *means*
across `claim` and `close`; `0091` is a by-hand write taking the lock and proving its commit. Neither
is "a mandated write no `touches:` can express".

## Functional requirements

- FR1 — `queue` Step 2 states what a capture session does when `./next` reports `config.yml` held.
- FR2 — whichever way it resolves, the rule names `next_id` specifically rather than exempting the
  whole file, since the other keys in `config.yml` are ordinary contended content.
- FR3 — if the answer is that the counter write is visible to the regime, `./next`'s collision
  message distinguishes it from a collision that has a remedy.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule is stated once, in the skill or in `CONCURRENCY.md`, never both | `documentation-conventions.md` |

## Open design question  *(only while `next: design`)*

- **Question:** is the `next_id` counter inside or outside the `touches:` regime — and if outside,
  what stops the exemption being read as "`config.yml` is unowned"?
- **Why it blocks specification:** no AC can be written for FR1 until the answer is chosen; the two
  answers produce opposite prose and opposite changes to `./next`.
- **Settle it with:** `/design`

## Acceptance criteria

Written once the design question is settled.

## QA plan

- **Why that level:** prose plus, on one branch, a message change in `./next` that a grep can check.
- **Specific checks:** to be written with the ACs.

## Out of scope

What `touches:` means elsewhere (`0106`). Whether a by-hand write takes the lock (`0091`).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-07 and deferred once by this same
  retro before being filed properly. The reproduction is verbatim above; both collisions were real.
