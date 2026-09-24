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
- 2026-09-23 — **`--model opus` resolved to TWO different models inside one sprint, and `harvest-usage.sh` has no rate for the second, so this run's tail cost is unknowable rather than merely wrong.** `skills/sprint/SKILL.md` Step 3 requires `--model opus` on every dispatch, which pins an ALIAS and not a model. Measured across run-20260922T031109Z's transcripts: the develop and verify gates ran `claude-opus-5`, while the retro's resumed legs ran 50 turns of `claude-opus-5-5` beside 29 of `claude-opus-5`, and the queue sweep ran `claude-opus-5-5` for all 42 of its turns. The rate table knows only the former, so the queue session **disappeared from the harvest altogether** — `HARVEST of 4 sessions` from five transcript files, with no `queue` row — and the retro priced at USD 1.22 for 12 of its 91 turns. The ledger row for this run therefore records `tail_usd 1.22` against a true figure nobody can compute, which is the one number the ledger exists to carry forward. **Two distinct rows' worth of problem.** (1) A dispatch should pin a concrete model, or record which one answered, because an alias is resolved server-side and can move between two dispatches of one run — every per-session cost comparison in `MEASUREMENT.md` silently assumes it does not. (2) The rate table needs a story for an unknown model id that is not "omit the session": a missing rate currently costs a whole session's turns, and omission is worse than a wrong rate because nothing downstream can see that anything is missing. **What worked, and is worth recording as a success:** `0162` shipped in THIS sprint to stop the ledger recording an unpriced harvest as a measured USD 0.00, and it is the only reason this was visible at all — the harvest said `UNPRICED turns on a model with no published rate: 50` instead of quietly reporting zero. The fix caught its own defect's next occurrence within hours. (`tools/harvest-usage.sh` rate table; `skills/sprint/SKILL.md` Step 3; `.claude/backlog/LEDGER.md` run-20260922T031109Z; related 0162, 0164; sprint supervisor run-20260922T031109Z tail)
