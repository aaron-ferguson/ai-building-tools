# Why the order is what it is

Standing reasoning. Read on a re-rank, not on every claim.

## Current shape

Everything in the queue is phase 1 of the nested-work design (effort 0002), plus the two later
phases sitting undecomposed as `l` tasks. That is the model working as intended: **decompose
lazily.** Phases 2 and 3 have no children yet, so they are tasks and they are rankable. They will
become efforts the day someone splits them, and their rows will leave this file.

## The order

1. **0005** — the only unblocked row, and everything else in phase 1 depends on it. The template
   and the table header define the fields the other three tickets read or write. Tier 3, blocking.
2. **0007** — claim directories. Ahead of 0006 because it *removes* a column that 0006 would
   otherwise have to parse and then stop parsing. Doing them in this order means the reader is
   written once against the final shape.
3. **0006** — the `next` rewrite. Larger than either above and reads the shape both of them settle.
4. **0008** — the skill rule changes. Last in phase 1 because it is the one that cites the other
   three, and writing it against a moving target is how the citations go stale.
5. **0003, 0004** — later phases, blocked on 0002 completing. They keep their rank rather than
   sinking; when the blocker clears, why they mattered is already written down.

## Notes on tie-breakers used

- **0007 above 0006** is tie-breaker 4, smaller and more certain, reinforced by the prerequisite
  rule: doing them the other way means writing parsing code twice.
- **0003 above 0004** is dependency order — phase 3's bridge writes tickets that must pass the
  readiness gate phase 2 builds. Building the bridge first would mean pushing tickets to Jira
  against a gate that does not exist yet.
