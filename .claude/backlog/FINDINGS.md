# Findings — parked, not yet placed

**One or two lines each, dated, newest at the top.** This is a buffer, not a second backlog: it
holds findings whose home is **not local and not yet decided** — a possible row, a suspected skill
or convention problem, a cost pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in
a comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a
row. Parking those is how a session ends with nothing written down *and* a growing file.

**Two sweepers empty this file, and they take different things.** `queue` takes the entries that
are **units of work** and specifies and ranks each one properly. `retro` takes the **lessons** and
lands them where they will be read again. **An entry that is both is taken by both** — classifying
at write time would put friction exactly where it is least wanted, at the moment of noticing, so
nothing here is tagged and neither sweeper waits for the other.

**Each sweeper removes only the entries it processed, and commits in the same turn.** Leaving a
processed entry is how the next sweep pays to read it again; removing an unprocessed one is how the
other sweeper's half disappears silently.

Every entry ends as a row, an edit, or a drop with a stated reason — so the normal state of this
file is empty. Entries older than about two weeks are dropped rather than processed: a finding
nobody acted on in two weeks was not worth acting on, and saying so is more honest than re-reading
it forever.

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
- 2026-08-23 — verify's Step 3 mutation pass ("break the check, confirm it goes red") has no stated
  restore discipline, and the obvious `git checkout -- .` would destroy another window's
  uncommitted work in the shared tree the same skill's Step 2 just warned about. Scope the restore
  to the mutated path (pointer: skills/verify Step 3, 0010).
- 2026-08-23 — the pared table's failure mode in the shipped scripts is *safe* but silent: `next`
  prints "0 ready of 2 rows" against a five-column table and `claim` refuses every row, both
  without erroring. A reader would conclude the backlog was empty rather than that the parser was
  wrong (pointer: templates/next, templates/claim, 0010).
