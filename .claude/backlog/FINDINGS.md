# Findings — parked, not yet placed

**One or two lines each, dated.** A buffer, not a second backlog: it holds findings whose home is
**not local and not yet decided** — a possible row, a suspected skill or convention problem, a cost
pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in a
comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a row.
Parking those is how a session ends with nothing written down *and* a growing file.

Format: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`

**The date goes outside the bold, and this is load-bearing.** Every sweeper and `./next --findings`
find entries by line shape, so an entry whose date sits inside the `**` is skipped and nobody ever
notices — two such entries once made `MEASUREMENT.md` publish 26 findings in one sentence and 28 two
paragraphs later. Readers match `^- (\*\*)?20[0-9]{2}-` to tolerate the drift; writers use the
canonical form so as not to add to it. **Entry order is not guaranteed** — sessions have appended at
both ends — so a sweep reads to the end rather than stopping at the first entry outside its window.

**The date is UTC**, like `claimed_at:` in an item's frontmatter. Two sessions working the same hour
either side of midnight otherwise write different dates and both are defensible — and `retro` Step 1
expires entries on age, so the ambiguity lands on the one decision the date is actually read for.

**Refer to a sibling entry by item id or file path, and never by quoting it.** A sweeper removes the
entry it processed and cannot know another entry quoted it, so the quote resolves to nothing while
still reading as though the evidence is at hand — worse than a dead link, which at least announces
itself. An id or a path survives the removal, and a quoted phrase is not a key anything could check.

**A sweeper marks an entry on the way out with a head token, immediately after the date:**

```
- 2026-09-05 [->0060] — **what happened.** why it might matter (pointer: file, item id)
```

`[->NNNN]` means a row now carries this entry's work half; `[->none]` means a pass read the entry and
established that no destination exists yet. It sits at the head so a large buffer partitions with one
`grep` on `\[->`, and after the date so both line shapes above still match — trailing prose was tried
and bought the next sweeper nothing, because partitioning still meant reading every entry to its end.

**The noticer never writes the token.** It means *a sweeper dispositioned this*, and classifying an
entry at the moment of noticing is exactly the friction this buffer exists to avoid. The cheap hint —
the row the parking session was already holding — goes in the `(pointer: …, item NNNN)` clause, which
is not a classification.

**The token does not change what the gate counts.**
`./next --findings` counts every entry, marked or not: a count that fell as markers accumulated
would go quiet precisely when deferred and handed-over entries pile up, which is when the gate's
whole job is to be loud. The old trailing-prose form
stays readable — nothing rewrites an entry it is not processing.

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---

- 2026-10-18 — **`./claim` and `./next` read only a YAML-array or block-list `expects:`, and silently treat a bare comma list (`expects: a.ts, b.ts`) as no prediction.** In one consumer backlog, an item written that way was offered as "EXPECTS not predicted", and `./claim` reported "declares no expects:" and left `touches:` unset. Several of that backlog's items use the comma form, so file-scope triage is blind for all of them. Either the parsers accept it, or `queue`/the item template refuses to write it (`claim`'s `expects:` awk, `next`'s EXPECTS line).
- 2026-10-17 — **`develop` resolved a contradiction inside an item's own contract and recorded it as a "deliberate asymmetry", instead of routing the item to `design`.** In one consumer backlog, an item's Problem section called a behaviour correct that its AC5/FR5 forbid: a palm ignored during one gesture kind may let the next gesture start before it lifts. The build notes saw the conflict, built half to each side, and sent the item to `verify`, which can only fail it and send it to `design`. That cost a whole verify session. `develop` Step 2 has no explicit "the item disagrees with itself → hand to design" exit. It should have one, at the same weight as `verify`'s *"the ticket owes a decision rather than a choice"*.
- 2026-10-18 — **`sprint-ledger.sh record` counts an account session-limit pause as sprint wall-clock.** In one consumer's run-20261018T011502Z, a verify stage stopped on "You've hit your session limit", and the run logged `limit_hit` at 02:09Z and `resumed` about 12h later. The ledger then recorded `wall_clock_min` 901 against an estimate of 147, from first and last event timestamps. Working time was roughly 170 minutes. That actual is now the prior for the next estimate, which will be inflated about 5x. `record` should subtract each `limit_hit`→`resumed` window (and `stage_killed`→`resumed`) from wall-clock, or report it beside the actual (pointer: tools/sprint-ledger.sh wall-clock derivation; skills/sprint Step 7).
