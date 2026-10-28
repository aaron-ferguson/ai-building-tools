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
- 2026-10-27 (design 0050) — `./next develop`'s CLAIMED FILES block tells a reader to "assume held" the `expects:` of a row held at `next: design` (`skills/queue/templates/next:847`, `declared_scope`), though `./claim` says a design hold keeps `touches:` empty because design writes only its item and row; the collision walk ignores it, so the advice contradicts the walk rather than stalling anything. Wants a row: skip predicted scope for a design-held row.
- 2026-10-27 (verify 0065, 0050) — Both tickets in one develop gate reached verify with no clause table in the build notes, though the installed `skills/develop/SKILL.md` (0.9.44) carries *A mutation sweep enumerates from the AC text* and requires the table. Each sweep mutated only its guard's own phrases, reported every case red, and missed 5 + 4 unguarded clause rows (Given conditions, qualifiers, an absence over a whole file), so both bounced. The rule was broken twice in one gate as prose, which makes it an enforcement candidate: `./handoff <id> <token> verify` could refuse a ticket whose Notes & decisions carry no clause table.
- 2026-10-27 (sprint run-20261027T185815Z) — Repair first has no `--drive` route: after the `queue` session minted the repair row 0221, `./next --drive --completed queue:0221 --scope 0221` printed `ESCALATE 0221 is at next: develop / ready after queue, which no routing rule covers`, while the same call without `--completed` dispatched `develop 0221`. The sprint skill says the repair row "runs as its own gate to `next: done`" but names no `--completed` form for the queue session that minted it. Wants a row: `--drive` treats `--completed queue:<id>` on a fresh `develop ready` row as a dispatch, or the skill says to omit `--completed` after the repair-first queue.
- 2026-10-27 — **`queue` has no rule for splitting a ticket whose dependent child needs `design` first.** Splitting 0089, the standing-guard child 0224 needs a design decision now but must be `blocked_by` the three sweeps before `develop` takes it; a `blocked_by` set at capture makes it untakeable at `design` too (`next` treats any open `blocked_by` as not takeable, whatever the stage). Invented: leave `blocked_by` empty and instruct `design`, in the Open design question, to set it on hand-off. Prose instruction, not enforced; `queue` Step 2 / `./next` takeability are where a rule would go.
- 2026-10-27 (verify 0050) — **`verify` Step 3's gap test has no answer for an absence clause.** It defines a green clause mutation as a gap "only if the phrase the AC names no longer occurs", which is presence-shaped: for 0050 AC5 ("neither describes `0050` as an open question") the mutation *adds* the forbidden description, and a version wrapped across a line break (`(0050, still an` / `open question)`) stays green under the line-level whole-file absence the previous verify round itself prescribed. The test cannot say whether that is a gap; I published it as a residual of the rewrap class (`0063`) and passed. Step 3 needs the absence form: a green mutation that introduces the forbidden phrase *on one line* is a gap; one that only wraps it is the line-based limit.
- 2026-10-27 (sprint run-20261027T185815Z) — `./next --drive --completed verify:0065` exited 4 on 0065's verify bounce while 0189 and 0092, built in the same develop gate, sat at `next: verify, status: ready`; the run halted with built work unverified, the outcome `--started` exists to prevent. The escalation also fired though verify's QA evidence already said the build was wrong and listed every gap, so the person's answer was a formality. Wants a row: `--drive` dispatches the remaining verify rows of a started gate before escalating a bounce, and reads a bounce whose QA evidence names the gaps as re-developable.
- 2026-10-27 (sprint run-20261027T185815Z) — A `next: queue` row ranked above confirmed scope (0089) blocks every scope row below it: `./next --drive` exited 4 on it with 0089 dropped from `--scope` as with it, so the person's answer "leave 0089 at queue, continue the open work" could not be carried out without dispatching a queue session. Wants a row: `--drive` steps over an out-of-scope `next: queue` row with a NOTE, as it does an out-of-scope design row.
