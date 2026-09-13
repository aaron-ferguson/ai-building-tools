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

- 2026-09-13 — **`--drive --propose` selects a gate by file join, not by queue rank.** From rank-1 0151 it pulled rank 94–97 rows 0152–0154 (they share `skills/sprint/SKILL.md` and `tests/sprint.test.sh`) plus 41 others, while ranks 2–93 (0110, and design rows 0145/0146/0139) were jumped; the supervisor then offered a theme subset. A join should decide batching, never selection over rank. (`skills/queue/templates/next` gate_from; run-20260913T034946Z)
- 2026-09-13 — **`next: design, status: ready` routes as "a person decides" (exit 4), but a person is needed only at `status: waiting`.** Design is autonomous work; `--drive` should dispatch `design` on a ready row and escalate only `waiting`, and the depth line should not report a ready design row as where the run runs dry. (`skills/queue/templates/next` design cases in the completed-stage and ranked walks; `skills/design/SKILL.md` `design waiting` hand-off; sprint *Design alongside develop* and Step 8)
- 2026-09-13 — **Stage dispatch names no model, so every stage of run-20260913T034946Z ran on claude-sonnet-4-6.** queue, design, develop, verify and retro are thinking work and dispatch `--model opus` (verified to resolve to claude-opus-5); a plan-then-haiku split is allowed only where quality is unchanged. (`skills/sprint/SKILL.md` Step 3; commit d7f4b72 co-author line; relates 0149)
- 2026-09-13 — **`harvest-usage.sh` has no rate for claude-sonnet-4-6, and `sprint-ledger.sh record` wrote USD 0.00 and 0 tokens for two sessions that committed real work.** An all-unpriced harvest is read as a measured zero; it should refuse or label the figure unpriced. Run-20260913T034946Z's ledger block was left uncommitted for this reason, and its run log is the only source to re-record it from. (`tools/harvest-usage.sh` RATES; `tools/sprint-ledger.sh` harvest(); `.claude/backlog/LEDGER.md`)
- 2026-09-13 — **An account session limit stopped the develop stage mid-gate (0154 claimed, 64 lines uncommitted), and `claude -p --resume <session-id>` with the same schema finished it with a valid outcome.** Step 7 makes any mid-work stop a human's recovery; on local unpushed work with no other session running, a limit stop is routine and should resume the same session after the reset, with the resume cap set to what that session has left rather than a fresh base cap. A `--max-budget-usd` kill stays an escalation. (`skills/sprint/SKILL.md` Step 7; run log escalation at 04:27Z)
- 2026-09-13 — **A resumed stage's outcome `cost_usd` covers only the resumed leg (USD 1.06); the stopped leg's spend appears in no outcome.** Only a transcript harvest by session id sees both legs, so stage outcomes cannot be the cost source for an interrupted session. (run-20260913T034946Z outcome events)
- 2026-09-13 — **Ledger wall-clock is first-to-last run-log event, so a session-limit wait counts as work: 646 min recorded.** The run log needs limit-hit and resumed events, and the ledger needs active and elapsed time as separate figures. (`tools/sprint-ledger.sh` wall_clock_minutes)
- 2026-09-13 — **The sprint estimate has no term for a mid-session stop, which re-pays a session's context on resume.** Stops will be routine here, so the estimate should price expected interruptions and the ledger should record how many occurred. (`tools/sprint-ledger.sh` estimate and record)
- 2026-09-13 — **Verify closed 0151–0154 as pass while returning `conventions_resolved: null`, a placeholder `session_id` (00000000-0000-4000-8000-000000000000), and running per-ticket test files instead of config's `unit` command.** Step 4 calls a null conventions field an escalation, but the closes had already been committed; nothing gives a closed ticket a path back to verify. (items 0151–0154 QA evidence; `skills/verify/SKILL.md`; run log escalation at 14:37Z)
- 2026-09-13 — **Any rerun supervised from the conversation that drove run-20260913T034946Z carries that run and its post-run discussion in context.** Its supervisor floor, growth and turn figures are inflated and not comparable; its stage sessions are fresh processes and are. Separately, `harvest-usage.sh --run` reported 4249 turns because the bound spans the whole transcript directory, not the supervisor's session. (`tools/harvest-usage.sh` RUN BOUND; `.claude/backlog/LEDGER.md`)
