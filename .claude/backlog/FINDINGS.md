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
- 2026-10-09 — **sprint Step 1's probe at `--max-budget-usd 0.25` returned `Error: Exceeded USD budget`; it passed at 1.00.** The skill's own text warns a cap below the startup floor fails identically, yet its probe block ships a cap below the floor, so every first probe reads as a broken CLI. (pointer: skills/sprint/SKILL.md step-1-probe, quantum-catan run-20261009T003522Z)
- 2026-10-09 — **The `outcome` event shape is undocumented in sprint Step 5, and a supervisor that nests the stage object under an `outcome` key makes `sprint-ledger.sh record` report `CLOSED none` / `FINDINGS parked 0` silently.** The ledger expects tickets/cost_usd/findings_parked flat at top level; a schema or a loud failure on an outcome event with no `tickets` would catch it. (pointer: skills/sprint/SKILL.md Step 5, tools/sprint-ledger.sh, quantum-catan run-20261009T003522Z)
- 2026-10-09 — **Waiting on a nested stage with `until ! kill -0 <pid>` in a backgrounded Bash returned immediately while the stage was alive; `ps -p` and the dispatch wrapper's own completion notice were reliable.** Step 2's "one backgrounded `until` loop" should name a liveness check that works across the sandbox, or wait on the dispatch wrapper itself. (pointer: skills/sprint/SKILL.md Design beside other stages step 2, quantum-catan run-20261009T003522Z)
- 2026-10-09 — **`tools/cost-by-category.sh` keeps its own `RATES` and `CACHE_READ_MULT`, and they already disagree with `harvest-usage.sh`'s.** It prices `claude-sonnet-5` at 3.00/15.00 where harvest has 2.00/10.00, and it has no `claude-opus-5-5` or that model's 0.05x cache read. That is one concept defined twice, the divergence `sprint-ledger.sh`'s `harvest()` shells out to avoid. Where the single table should live is undecided: shared file, shell-out, or retire the script. Out of 0192's scope by its amend (tools/cost-by-category.sh:96, item 0192).
