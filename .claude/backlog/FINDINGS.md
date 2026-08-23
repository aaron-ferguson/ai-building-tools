# Findings — parked, not yet placed

**One or two lines each, dated, newest at the top.** This is a buffer, not a second backlog: it
holds findings whose home is **not local and not yet decided** — a possible row, a suspected skill
or convention problem, a cost pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in
a comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a
row. Parking those is how a session ends with nothing written down *and* a growing file.

**`retro` empties this file.** Every entry it processes becomes a row, becomes an edit, or is
dropped with a stated reason — so the normal state of this file is empty. Entries older than about
two weeks are dropped rather than processed: a finding nobody acted on in two weeks was not worth
acting on, and saying so is more honest than re-reading it forever.

**If this file has grown, that is itself the finding** — retros are not running, or not emptying.

Format: `- YYYY-MM-DD — what happened, why it might matter (pointer: file, item id)`

---

- 2026-08-23 — `skills/queue/templates/claim` reads status from `$7` and owner from `$8` by fixed
  column index, so the pared five-column table breaks it for any newly scaffolded project. No
  ticket owns `claim`: 0011 and 0006 both name only `next` (pointer: 0010).
- 2026-08-23 — 0006's FR2/AC2 enumerate a seven-column (`Owner`) and eight-column (`Parent`) table
  as the shapes `next` must parse. A five-column shape now exists and neither fixture covers it,
  so 0006 would close green against a table nothing uses (pointer: items/0006, 0010).
- 2026-08-23 — 0006 ("rewrite next to parse by header name") and 0011 ("rewrite next for the new
  fields") both own the same reader under different parents (0002 and 0009). Whichever lands
  second rewrites the first's work (pointer: items/0006, items/0011).
- 2026-08-23 — 0010's Out of scope said removing the `Owner` column was 0007's job "because this
  repo's table already has none", but FR3/AC2 pin a header that excludes it, so the *template*
  lost the column here. An out-of-scope line written from the local table can contradict an FR
  written for the shipped template (pointer: items/0010).
- 2026-08-23 — this repo carries three status values outside the ticket vocabulary — `active`
  (container), `scheduled` (SCHEDULED.md), `done` (terminal). 0010's FR1 enumerated four and none
  of these; the enumeration was false until widened (pointer: templates/item.md, 0010).
