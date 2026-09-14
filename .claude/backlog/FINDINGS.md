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
- 2026-09-13 — **A control run of `tests/sprint.test.sh` on a clean tree at 0dd303f printed `231 passed, 1 failed` and was green on the next run**, with no mutation live and only untracked `.claude/backlog/runs/` dirty while a sprint run (`run-20260913T151122Z`) was writing there. The FAIL line was lost because the verify pass filtered the output to its tally; unattributed. (tests/sprint.test.sh; verify Step 3 control run)
- 2026-09-13 — **`tools/sprint-ledger.sh estimate` may now count tail cost twice on a ledger with history.** Since 0152 it adds retro/queue sessions from MEASUREMENT.md on top of the ledger per-ticket mean, but `record` sums a recorded sprint's tokens and usd over *every* session id in its run log, tail included, so a sprint that ran a tail already folds tail cost into that mean. Separating tail sessions out of the recorded actuals would need its own row. (tools/sprint-ledger.sh estimate/record)
- 2026-09-13 — **No guard reds when `estimate` stops pricing `--retro`.** Mutation `tail = []` in place of the retro entry left `tests/sprint-ledger.test.sh` at 106 passed, 0 failed: 0152's re-verification guards compare retro+queue against retro alone, so a missing retro cancels out on both sides. Retro pricing predates 0152 (a3f5a7a, 0135), which is why this is parked rather than failing 0152. (tools/sprint-ledger.sh estimate; tests/sprint-ledger.test.sh)
- 2026-09-13 — **`tools/sprint-ledger.sh tail-cap --findings abc` still dies with a Python `ValueError` traceback**; 0152 turned only the zero and negative `--threshold` into a named refusal. The supervisor reads these numbers out of `./next --findings` and `config.yml` by text, so a malformed value reaches the parser. (tools/sprint-ledger.sh tail-cap)
- 2026-09-14 — **`sprint-ledger.sh estimate` labels its source "LEDGER.md 2 recorded sprint(s) over 4 ticket(s)" when one of the two blocks is excluded from the per-ticket means.** `read_ledger` counts every block with any numeric figure as a sprint, while the means use only blocks whose `tickets` is numeric, so the label overstates what the figure rests on. (tools/sprint-ledger.sh read_ledger and estimate; LEDGER.md run-20260913T151122Z block)
- 2026-09-14 — **The findings gate stops in-scope work, but the user requires the retro and queue tail at the very end of the working session, whatever the count.** `./next --drive` spent exit 5 at 8 of 8 while 0153 still needed develop and verify; sprint Step 6 says to start no further stage. The user's rule: "Retro and queue should always be at the very end of the working session, regardless of how many findings are ready. Finish the work, then once everything passes verify we will do the retro." The gate should defer the tail until confirmed scope is finished, not stop it. (skills/queue/templates/next findings_gate; skills/sprint/SKILL.md Step 6; run-20260913T222409Z gate_decision) (retro 2026-09-13: no skill-only lesson — `findings_gate` in skills/queue/templates/next fires wherever a new develop gate forms, so Step 6 prose cannot honour the rule until the script defers it; left for queue)
- 2026-09-13 — **Under `set -eu`, a guard that captures `grep` into a variable without `|| true` aborts the test file on the exact input it exists to catch — no FAIL line, no tally.** A mutation run that greps for FAIL reads nothing, which looks neither red nor green. `tests/*.test.sh` share this shape; a guard should print its tally or exit loudly when it dies mid-file. (0153 develop eac85fd6; tests/sprint.test.sh) (retro 2026-09-13: lesson landed in ai-building-conventions testing-conventions.md, Prove a new guard fails; work half — tests/*.test.sh exiting loudly — left for queue)
- 2026-09-14 — **The supervisor's hand-rolled marker heartbeat, stopped with `kill $BEAT`, left its `sleep 60` child orphaned under launchd.** Killing the backgrounded subshell does not kill the `sleep` it is waiting on; `pkill -P $BEAT` before `kill $BEAT` stopped it cleanly on later dispatches. 0153's Step 3 snippet should be checked for the same orphan, since the executed guard asserts the loop stops but not that no child survives. (run-20260913T222409Z verify 091e8968; skills/sprint/SKILL.md Step 3) (retro 2026-09-13: checked — skills/sprint/SKILL.md Step 3 snippet stops with `kill "$BEAT"` alone, the same orphan shape; left for queue)
- 2026-09-13 — **`tests/citations.test.sh` read an italic-quoted CLI message in skills/sprint/SKILL.md Step 4 as a citation of a CONCURRENCY.md rule and redded.** Quoting an observed error string in the `*"…"*` form this repo uses for quoted messages collides with the citation shape; the retro reworded rather than changed the guard, and the next author will hit it too. (tests/citations.test.sh; 220ce64)
