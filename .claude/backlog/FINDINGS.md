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
- 2026-10-10 — **quantum-catan's buffer carried head tokens outside the documented vocabulary: `[->queue]` on an entry still needing a row and `[->ai-building-tools]` on a tool finding left in the local buffer.** `templates/FINDINGS.md` defines only `[->NNNN]` and `[->none]`, so a sweeper invented two more; a forwarded entry sitting locally means the routing in `references/CONVENTIONS.md` was not followed, and a `grep '\[->'` partition now counts these as dispositioned. (pointer: quantum-catan commit ec13509, retro run-20261010T011031Z)
- 2026-10-10 — **A `waiting` owner-decision ticket ruled "nothing to build" has no scripted close: `./close` needs `next: verify`, a claim token and tickable ACs, and the ruled row has none of them.** quantum-catan 0031 was closed by hand under the lock (QUEUE.md row out, DONE.md row in, dependent 0008 reconciled), against DONE.md's "never edited by hand"; neither `queue` nor `design` names this exit. (pointer: quantum-catan commit 89d71a9, items 0031 and 0008)
- 2026-10-10 [->queue] — sprint-ledger.sh record counts an account session-limit pause as run time: quantum-catan run-20261010T011031Z logged `limit_hit` then `resumed` around queue session 1419ed92, and the ledger reported wall_clock 311 min (estimate 178) and that window's elapsed as 283.4 min, nearly all of it the wait for the reset. Neither figure subtracts the limit_hit→resumed interval, so the next wall-clock estimate learns from a pause rather than from work. Candidate: subtract each limit_hit→resumed span from the run's wall-clock and the resumed window's elapsed, and print the subtracted minutes. (pointer: quantum-catan .claude/backlog/LEDGER.md, run-20261010T011031Z block)
- 2026-10-10 — **The owner stated a general rule that no skill states: a declared success threshold is a goal to iterate toward, and develop may never change one.** quantum-catan 0008 failed its pre-written criterion 5 (too-bad <= 0.25) on the engine. The develop session correctly held, but on the strength of a ticket note, not a skill rule. The owner then ruled to reduce chaos until the cap holds, never to move the cap. Neither `develop` nor `verify` names this, and nothing mechanical enforces it. queue re-specified 0008 with an FR pinning each threshold in a test. Candidate: `develop` says a failing declared threshold means iterate on the inputs or escalate, never edit the threshold; `queue` says a ticket carrying a success threshold pins it in a test. (pointer: quantum-catan .claude/backlog/items/0008-run-balance-harness-on-the-engine.md, FR12 and Notes 2026-10-10)
- 2026-10-10 — **`./next --drive --completed queue:<id>` exits 4, "at next: develop / ready after queue, which no routing rule covers", when a queue session re-specified an owner-ruled `waiting` row back to `develop ready`.** Re-calling with no `--completed` routed it normally. The rule set has no queue-completion case, so the supervisor has to drop the flag by hand. (pointer: quantum-catan run-20261010T144315Z, 0008 after queue session 15061e8a)
- 2026-10-10 — **`--drive` named the develop gate while a design row the proposal labelled "related to this gate" was still running, so the related row could not join that gate.** quantum-catan 0030 (design, s, USD 0.75) finished minutes after develop 0008/0007/0006 was dispatched. It then needed its own develop gate. The owner wanted it batched with the gate. Exit 6 waits only on file overlap. Candidate: an in-scope design row tagged `related to this gate` holds that gate (exit 6) until its outcome. (pointer: quantum-catan run-20261010T144315Z)
- 2026-10-10 — **Gates join on a shared doc file or the parent slice alone, which batched unrelated work.** quantum-catan 0008 (balance-harness sweep) joined 0007/0006 through `packages/engine/README.md` plus parent 0001. The owner's rule (2026-10-10): batch only tickets that share code files; a shared README or parent slice does not join. The ledger's evidence for develop batching is thin: a 4-ticket gate cost USD 1.55/ticket against USD 1.43 for a single ticket. The supervisor overrode the gate by hand. (pointer: quantum-catan run-20261010T144315Z override events)
- 2026-10-10 — **`--drive` exits 4 on every verify bounce, even when verify recorded a precise, test-only constraint.** quantum-catan 0007 failed one AC1 clause; verify 43c3 named the exact fix. The owner has authorised the supervisor to send develop back toward the declared criteria. A re-develop with verify's constraint in the prompt cost USD 1.02 and passed (USD 0.97). Candidate: route a bounce whose item carries a verify constraint to develop, and escalate only a contract question. Related to the owner's threshold-as-goal rule parked by queue the same day. (pointer: quantum-catan run-20261010T144315Z, item 0007 Notes)
- 2026-10-10 — **develop Step 5's "mutate only what is committed" does not cover a file git has never seen.** quantum-catan develop 0007: `git commit -m … -- <new file>` refuses an untracked path ("pathspec did not match"), so the commit silently did not happen, the follow-up `git checkout --` failed too, and mutations stacked. The rule needs `git add` for new files first and the mutation run chained on the commit's success (`&&`). Forwarded by quantum-catan retro. (pointer: skills/develop/SKILL.md "mutate only what is committed")
- 2026-10-10 — **A backlog heredoc append was refused as a "sensitive file" while `./handoff` in the same parallel tool batch went through, so the hand-off committed before the notes it should have carried.** quantum-catan develop 0007. develop already says to commit the notes *before* the hand-off (SKILL.md "Write and commit it before Step 5's hand-off"), so this is reach, not a missing rule: it does not say never to batch `./handoff` with the writes that must precede it, and a parallel batch defeats the ordering. Forwarded by quantum-catan retro. (pointer: skills/develop/SKILL.md)
