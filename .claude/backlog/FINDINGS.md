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
- 2026-09-25 — `tools/harvest-usage.sh`: after 0186 a wholly unpriced session has a SESSION row, but the per-SKILL table still lists only priced turns, so a skill whose every turn is unpriced (the `queue` sweep of run-20260922T031109Z) still has no skill row and its turns show only in the global UNPRICED line. 0186's FRs scope the fix to session rows and the header; the skill table needs its own row if wanted. (develop 0186, fd62)
- 2026-09-25 — `tests/sprint-ledger.test.sh` 0186 AC2: the unpriced-turn-count guard's fixture has exactly one unpriced turn in one unpriced session, so it cannot tell a per-session count from a constant or from the harvest's running total — mutations `% r["unpriced"]` → `% 1` and `merged["unpriced"] = unpriced` → `= unpriced_total` both stay 137/0. Behaviour is correct (a four-session store printed 2/3/4/4 against UNPRICED 13); the guard wants a fixture with two unpriced sessions of different counts. (verify 0186, 1bee)
- 2026-09-25 — `tests/handoff.test.sh` FR2 "touches: entries written at column 0 are cleared too" (from b680b855): `assert_no_item_line … '- src/two.ts'` hands grep a pattern beginning with `-`, so BSD grep prints `invalid option --` and the case reports `ok` regardless — a guard that cannot fail. Needs `grep -e`/`--` (or a fixed-string compare) and a mutation proving it reddens. Seen in every full-suite run's output; unrelated to 0161. (verify 0161, 4cdc)
- 2026-09-25 — `tests/backlog-scripts-installed.test.sh`: removing `reopen` from `SCRIPTS=` stays green (45→37 passed, 0 failed); `handoff.test.sh` now pins only the prefix `SCRIPTS="next claim close handoff`, so no guard notices a script dropping out of the install check. 0161 FR5 holds today but is unguarded; no AC asked for a guard, so none was invented. (verify 0161, 4cdc)
- 2026-09-26 — `./claim` on a design row prints "Set [touches:] to what design will write", but `skills/design/SKILL.md` never tells a design session to set `touches:`, and `CONCURRENCY.md` reads an empty `touches:` on an in-progress row as *all files held*. Read literally, every design claim in a sprint blocks every other claim's files; 0188 sidesteps it by checking a design row's `expects:` instead, but the claim message, the design skill and the empty-means-held rule still disagree about what a design claim holds. (design 0188, a16a)
