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
- 2026-09-26 — `verify` Step 3's sweep recipe ("print a sentinel line last and wait with an `until grep -q` over its output file") and `config.yml`'s `commands` comment (`tests/next.test.sh > /tmp/out.txt`) both point the output at `/tmp`, but in a driven session the `Monitor` tool refuses to `grep` any path outside the session's working directories, so the recommended wait cannot be armed on the recommended file; a bounded foreground `for … sleep 10` poll worked instead. Under host load (load avg ~11) one mutation run of a 34-case slice of `tests/next.test.sh` took ~40 min where the control took 14 s, so an unbounded wait was not hypothetical (verify 0178).
- 2026-09-26 — `config.yml` `stage_budget_usd` carries no `design` cap, yet sprint's *Design alongside develop* dispatches design sessions with a `--max-budget-usd`; run-20260925T203345Z derived 3.48 by hand (MEASUREMENT.md design mean 2.32 × 1.5, the file's own rule), a figure chosen in the supervisor that Step 7 says belongs in config.yml with its derivation (sprint run-20260925T203345Z)
- 2026-09-26 — Step 7's session-limit resume caps the resumed leg at "stage cap less what a harvest of that session id already shows spent", but every turn of the paused verify 0178 ran on a model with no RATES entry, so the harvest priced it at 0.00 with 8 unpriced turns and the rule could not be applied; the supervisor subtracted a 1.00 allowance by hand. The resume cap needs a stated fallback for an unpriced session, or RATES needs the current model (sprint run-20260925T203345Z)
- 2026-09-26 — `tools/sprint-ledger.sh record`: with every turn of run-20260925T203345Z on a model missing from RATES (301 unpriced turns), the summary rows correctly print `unpriced`, but every GATE, RATIO and DESIGN line prints `observed USD 0.00` — an unpriced session reads as a free one, the silent-zero 0186 removed from harvest-usage.sh's session rows. Those lines want `unpriced` too; and RATES likely wants the current Opus rate (LEDGER.md, run-20260925T203345Z)
- 2026-10-04 — Since `0041`, `tools/release --bump` refuses at step 4 on an empty `## Unreleased` in `CHANGELOG.md` unless given `--no-behaviour-change`, but `CLAUDE.md` and retro Step 5 still name `tools/release --bump --yes` as the standing invocation. The installed verify skill (0.9.36) also predates the `--note` instruction, so every ticket verified before the next release, including 0187, 0188, 0174 and 0041, records no note, and that release meets an empty `## Unreleased`. The retro wording and the first post-0041 release still need a decision, which is not this develop session's to make (develop 9b67).
- 2026-10-04 — `tests/backlog-scripts-installed.test.sh`'s awk-quote scanner reports "closed early by a quote" for any single-quoted shell string that starts with `#`, such as `printf '# Changelog\n'` outside every awk program. It takes the `#` for an awk comment. 0041 worked around it by double-quoting the printf, so the false positive still needs a row (develop 9b67).
- 2026-10-04 — A mutation rerun of `tests/next.test.sh` for one ticket need not run all 572 cases (~10 min a run): its preamble (fixture and assertion helpers, lines 1–389) plus the ticket's own sections, copied verbatim to a scratch file with `ROOT=` pinned to the checkout, ran 0188's and 0174's 53 cases in 15 s, and each mutation landed and reddened the same way it would in the whole file. `config.yml` only says to redirect rather than pipe. A section-selecting runner (`tests/next.test.sh --only <id>`) would make Step 3's per-mutation rerun cheap on every router ticket. The whole file still runs as the control (verify 0187/0188/0174/0041).
- 2026-10-07 — Striking an acceptance criterion by turning `- [ ] ACn` into `- ~~ACn …~~` reds `tests/item-ac-form.test.sh`, because a plain bullet in the AC section is exactly the non-checkbox shape `./close` misreads. `580b434` (0041's AC2 split to 0191) landed that way, and the suite stayed red until develop 9f96 removed the marker. Neither `queue` nor the split path says how to strike a criterion. The shape that passes is a non-list `~~ACn …~~` line. Nothing ran the suite on a backlog-only commit.
- 2026-10-07 — `tools/sprint-ledger.sh` `record` assigns `log_src = "<run log> event timestamps"` and never writes it. So no ledger line says that the sprint's wall-clock and the heading's `ended` stamp come from the run log's event stamps, and AC8's "how the boundary was derived" rests on the `run.jsonl outcome events` lines alone. The variable is dead since `a3f5a7a` (0135). Either cite it on the `wall_clock_min` row or delete it. This needs a row, and 0041's guard-only re-entry did not take it (develop 6ed0).
- 2026-10-07 — verify 4c6e's AC1 gap was one of five quantifier or plural clauses in 0041, each served by a one-item fixture. "Every ticket closed", "those entries", "per dispatched session id", "the closed-ticket list" and "cost per closed ticket" were all green under a mutation keeping only the first item. With one closed ticket the per-ticket figure *equals* the total, so even a missing division passes. A plural in an AC calls for a fixture with at least two items, and `develop` Step 5's clause table could add a "plural/quantifier → fixture has ≥2" row (develop 6ed0).
- 2026-10-07 — `sprint` Step 1 check 4 says `git worktree add --detach` for the baseline but not *where*. Placed in the session scratchpad, the worktree cannot resolve `config.yml`'s relative `conventions.path: ../ai-building-conventions`, so `tests/citations.test.sh` 0052 AC6 reads red ("no conventions directory resolved") on a green HEAD. The same 32 files from a sibling worktree (`../ai-building-tools-baseline`) were 32/32 green. The person was shown a red baseline and asked to repair it before the run. The step should require a sibling of the checkout, or any path where the relative paths in `config.yml` resolve (sprint run-20261004T232135Z).
- 2026-10-07 — A `verify` outcome reporting `fail` carries no reason for the failure. `escalation` held a *separate* open question (0041 AC2 cannot be judged before a release), and the supervisor relayed that to the person as the cause. The actual fail was AC1, and it was only in the item's Notes behind the `detail` pointer. The person then made a decision based on the wrong cause and had to be corrected. Step 4 should say that before a `fail` is presented to a person, the supervisor opens that ticket's `detail` pointer, or the schema should carry a one-line fail reason per ticket (sprint run-20261004T232135Z).
