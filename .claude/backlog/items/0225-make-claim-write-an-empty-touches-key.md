---
id: "0225"
title: Make claim write an empty touches key when it has nothing to seed
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-11-06
source: agent
parent:
blocked_by: []
relates: ["0215", "0106"]
expects:
  - skills/queue/templates/claim
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`./claim` and `./handoff` disagree about an item whose frontmatter has no `touches:` key.
Observed in AetherWorks item 0027 (develop, sprint run-20261101T172121Z): the item had no
`expects:`, so `claim` seeded nothing and — because its awk adds the key only under
`!tou && n && seed` (`skills/queue/templates/claim`, the frontmatter-close rule) — wrote no
`touches:` key at all, telling the session to set it by hand. `./handoff` then refused outright:

```
<id>'s frontmatter has no: touches
```

(`skills/queue/templates/handoff`, the absent-keys check). The ticket was going back to `design`
before any scope existed, so the session had to commit an empty `touches:` key by hand only so the
hand-off could run. `claim` already backfills the other missing ownership keys
(`note: item predated some of the claim keys; added them`); `touches:` is the one it skips.

## Functional requirements

- FR1 — When an item's frontmatter has no `touches:` key, `claim` adds one, whether or not it seeds
  entries: with the seeded entries when it seeds, empty when it does not (no `expects:`, or a
  non-develop stage).
- FR2 — A populated `touches:` is still left exactly as it is (0106's rule is unchanged).
- FR3 — The added key is reported through the existing backfill note, not a new message.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | FR1 starts as a failing test that runs `claim` then `handoff` on an item with neither `expects:` nor `touches:`. *Red when:* the key is not added and `handoff` refuses. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an item with no `expects:` and no `touches:` key, when `./claim <id>` runs, then the
      item's frontmatter carries a `touches:` key with no entries and `./handoff <id> <token> design`
      succeeds without a hand edit. *Red when:* `handoff` prints `has no: touches`.
- [ ] AC2 — Given an item with `expects:` entries and no `touches:` key, claimed at `develop`, then
      `touches:` holds those entries exactly once. *Red when:* the key is duplicated or empty.
- [ ] AC3 — Given an item whose `touches:` already has entries, `claim` leaves them byte-identical.
      *Red when:* any entry is added, removed or reordered.

## QA plan

- **Level:** unit
- **Why this level:** both scripts are shell over a fixture item; `tests/claim.test.sh` already builds
  such fixtures.
- **Specific checks:** the repo's `unit` command.

## Out of scope

- Relaxing `handoff`'s refusal — a missing key is still a malformed item; the fix is that `claim` stops
  producing one.
- 0215's comma-form parser.

## Notes & decisions

- 2026-11-06 — Filed by retro (sprint run-20261101T172121Z tail) from the tools-repo findings entry of
  2026-11-01 observed in AetherWorks 0027. Confirmed by a real project, so filed rather than held.
