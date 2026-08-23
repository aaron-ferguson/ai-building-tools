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
- 2026-08-23 — effort 0009 added ~20,300 bytes of AC-mandated content to the six skills, then 0021 asked
  for 30% off the result. Two independently-written requirements that were never checked against each
  other, and 0021 cannot close because of it. A ticket that sets a size target on a file other tickets in
  the same effort will grow needs the target expressed absolutely, not as a percentage (pointer:
  items/0021).
- 2026-08-23 — every `verify`-level assertion in this effort greps single lines, so compressing a
  paragraph breaks it by moving a phrase across a line break. It fired on 0012, 0015, 0016 and 0019
  during 0021's trim, each time a false red on prose that still said the right thing. Either match a
  phrase short enough to survive reflow, or read the file with newlines collapsed (pointer:
  items/0012, items/0021).
- 2026-08-23 — four of 0009's twelve tasks sat `blocked` on 0010 for the whole session after 0010 closed;
  nothing clears a `blocked_by` when its blocker closes. `./next <stage>` now derives takeability from the
  graph rather than the column, so the stale status no longer hides work — but the column still lies to
  anyone reading `QUEUE.md` directly (pointer: templates/next, 0011).
- 2026-08-23 — 0016's FR5 carried a kill criterion ("drop it if an isolated batch retro measures under
  $1.50") that could not be evaluated, because no isolated batch retro has ever been run. Implemented as
  written since reordering two headings is free, but a kill criterion whose measurement does not exist yet
  is a decision deferred, not a decision made (pointer: items/0016).
- 2026-08-23 — word-shaving moved ~1,100 bytes of `CONCURRENCY.md` across five passes; naming a category
  to move out moved 11,000 in one. Five passes of tighter prose were wasted effort of a predictable kind,
  and the same pattern repeated in the skills. A compression task should start by naming what leaves
  (pointer: items/0020, items/0021).

- 2026-08-23 — `skills/queue/templates/claim` reads status from `$7` and owner from `$8` by fixed
  column index, so the pared five-column table breaks it for any newly scaffolded project. No
  ticket owns `claim`: 0011 and 0006 both name only `next` (pointer: 0010).
- 2026-08-23 — 0006's FR2/AC2 enumerate a seven-column (`Owner`) and eight-column (`Parent`) table
  as the shapes `next` must parse. A five-column shape now exists and neither fixture covers it,
  so 0006 would close green against a table nothing uses (pointer: items/0006, 0010).
- 2026-08-23 — 0010's Out of scope said removing the `Owner` column was 0007's job "because this
  repo's table already has none", but FR3/AC2 pin a header that excludes it, so the *template*
  lost the column here. An out-of-scope line written from the local table can contradict an FR
  written for the shipped template (pointer: items/0010).
- 2026-08-23 — this repo carries three status values outside the ticket vocabulary — `active`
  (container), `scheduled` (SCHEDULED.md), `done` (terminal). 0010's FR1 enumerated four and none
  of these; the enumeration was false until widened (pointer: templates/item.md, 0010).
- 2026-08-23 — the pared table's silent failure is now loud in `next` (it refuses a shape it cannot
  parse) but **still silent in `claim`**, which refuses every row without erroring. Half-fixed by 0011;
  the other half is 0022 (pointer: templates/claim, 0022).
- 2026-08-23 — this repo's own backlog has **neither `next` nor `claim` installed**, so `/develop`'s
  Step 1 ("run `./next develop` rather than reading `QUEUE.md`") had no correct answer and the whole
  queue had to be read. The skill treats the scripts as present; the repo that ships them is the one
  place they are not (pointer: skills/develop Step 1, .claude/backlog/).
- 2026-08-23 — `/develop` Step 1 tells a session to claim with `./claim` and a minted token under
  `.lock`, but this repo's `QUEUE.md` prose now says ownership is the directory `claims/<id>/` and
  needs no lock. Two live protocols, and the item frontmatter still carries `claimed_by:`. Worse:
  **an empty `claims/<id>/` is invisible to git**, so it cannot be "durable the moment it is made"
  per CONCURRENCY.md — it needs a file in it. Input to 0007 (pointer: QUEUE.md prose, 0007).
- 2026-08-23 — a test harness that re-derives what it is testing passes and fails with it: 0022's
  `assert_row` looked the ID up at a fixed column while testing a fix for exactly that, and reported
  a correct claim as a missing row. Assert on whole lines, not on parsed cells. Worth a line in
  `testing-conventions.md` — the file warns about fixtures encoding domain assumptions, not about
  helpers reimplementing the parser (pointer: tests/claim.test.sh, testing-conventions.md).
