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

- 2026-11-27 — **`./drain` cannot remove an entry from `FINDINGS-HELD.md`, so filing a held finding at a person's request still needs a by-hand lock and edit.** queue (sprint run-20261127T024025Z) absorbed 8 held `xxd` entries into 0245 and removed them with mkdir `.tickets/.lock` and a python3 filter, the path 0242 exists to remove. The dispatch also named 3 of the 8, so a sweep that matched only the named entries would have left 5 behind (pointer: `skills/queue/templates/drain`, item 0245).
- 2026-11-27 — **`./next --drive --scope` names an out-of-scope `verify` row as the next dispatch instead of stepping over it.** sprint run-20261127T205235Z, scope 0245 and 0064: after 0245 closed, `--drive --scope 0245 --scope 0064` printed `DISPATCH  verify 0192`, while it stepped over out-of-scope design rows 0243 and 0244 with a NOTE. The person added 0192 to the scope; unattended, the supervisor would have dispatched work nobody confirmed (pointer: `skills/queue/templates/next`, the `--scope` filter; `skills/sprint/SKILL.md` Step 2).
- 2026-11-27 — **The `--scope` gap in `./next --drive` covers `develop` rows too, not only `verify`.** sprint run-20261127T205235Z: once closing 0192 unblocked 0240, `--drive --scope 0245 --scope 0064 --scope 0192` printed `DISPATCH  develop 0240` (out of scope, rank above 0064). The person chose 0064, and the supervisor dispatched it against `--drive`, which Step 2 forbids, so the run had no compliant path to its own scope (pointer: `skills/queue/templates/next`, rank walk under `--scope`).
- 2026-11-27 — (develop 0064) tests/sprint.test.sh pins bare '/sprint' in README's skill table and '/sprint resume <run-id>' in sprint Step 1, so qualifying the sprint skill's own invocation (as 0064 did for the six stages) would red two prose guards on a correct rewording; per CLAUDE.md such guards are deleted, not re-anchored — sprint was left bare.
- 2026-11-28 — **A sprint-dispatched queue session started on a harness branch (claude/*), so ./capture refused off main**; the fix was git switch main plus a cherry-pick of a backlog commit already made on the branch. Separately, capture's --ranking text cannot name the id it is about to mint, so the entry said NNNN until a hand edit (2dccb2c).
