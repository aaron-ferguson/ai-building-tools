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

- 2026-11-18 [->none] — **`tests/sprint.test.sh` AC26 reds on any digit in a comment *after* the `stage_budget_usd:` key in `skills/queue/templates/config.yml`.** Its awk window closes only on a non-`#`, non-space line, so it spans the following sections' comment blocks; a retro adding "(its Step 6)" to the `review:` comment read as "the template ships a cap figure". Reworded to pass; the guard's window, not the edit, was wrong. (pointer: tests/sprint.test.sh, the `tpl_state` awk; retro run-20261118T074205Z)
- 2026-11-18 — **`./next --ac-digest <id>` prints the whole `ac_digest: …` line, and `queue` Step 2 says to "write `ac_digest:` from" it**, which reads as "the value after the key". Substituting the output after `ac_digest: ` doubled the key in 0234 (`69203c8`); `--ac-digest --check` caught it before hand-off, and `52b9888` fixed it. (queue, amend 0234)
- 2026-11-26 — **Merging older tickets into a new outcome ticket reds `tests/item-nfr-red.test.sh`.** Rows from tickets written before the *How it would red* column have three cells. Carried into a ticket created today, they read as a bare file reference, so 0242 and 0240 failed 6 cases after the 32→11 merge until each row was given a red cell (`9765391`). `queue`'s *Merging tickets* says to carry FRs and ACs and is silent on NFR rows written to an older shape. 0242's `./withdraw --into` moves no content, so every future merge meets this.
- 2026-11-26 — **`.tickets/claim` with no token argument dies on a host without `xxd`** (`claim: 102: xxd: not found`): its default token is `head -c2 /dev/urandom | xxd -p`, so the claim refuses before writing anything. Passing a token (`python3 -c 'import secrets;print(secrets.token_hex(2))'`) worked. `od -An -tx1` is POSIX and would not need the dependency. (develop 0234 S1; pointer: skills/queue/templates/claim)
- 2026-11-26 — **A leg that reaches `verify` through a `queue` repair arrives with `slice:` empty, so the passing `handoff --slice S<n>` refuses** (`verify was handed the leg ending at slice: <empty>`). `slice:` is written only by develop → verify `--slice`; 0234's S1 went develop → queue (an AC8 fix to the contract) → verify, and no step records which leg is under test. This verify set `slice: S1` in its own claimed item, citing develop's build notes. Nothing in queue's re-specify-to-verify path, or in `handoff`, carries the leg. The FR5 in-sprint queue repair makes this path routine. (verify 0234 S1; pointer: .tickets/handoff, the `item_next = verify` slice check)
- 2026-11-27 (0234 S6 develop, token 65ef): `skills/queue/templates/claim` line 102 defaults the token to `head -c2 /dev/urandom | xxd -p`, and a host without `xxd` (this Linux cloud container) dies with `claim: 102: xxd: not found` before the lock and writes nothing, so `./claim <id>` with no token fails in a way that reads as a broken script. `od -An -N2 -tx1 /dev/urandom | tr -d ' \n'` is POSIX. Check the other scripts for the same default. Held per CLAUDE.md *Where toolkit work comes from*, pending a consumer confirmation.
- 2026-11-27 (sprint run-20261126T212112Z, supervisor) — **A `queue` capture can commit a red the suite would have caught.** `7229202` (Capture 0242) wrote a literal home-shaped path into AC8's example and reddened `tests/measurement.test.sh`'s Privacy & data NFR guard; the red was first seen by the next sprint's baseline, which then cost a repair session ($0.57, `15bb2bc`). Capture runs no suite, so a guard over tracked files is first run by whichever session comes next.
- 2026-11-27 (consumer project, develop f3e8 on a sliced ticket, dispatched by `sprint`) — **A dispatch's `baseline_red` attribution can contradict the ticket's own record, and nothing makes the supervisor check it.** The prompt gave an e2e red as "possibly the S2 client sign-in; not proven" and carried the owner's ruling "fix it inside S2" as the gate for verify. The item's own QA evidence already showed the same spec failing at a pre-S1 commit, with both halves assigned as named cases of two later slices. A `grep -n '<spec file>' <item>` before writing the attribution would have turned up the record in one call. The ruling rested on the false premise, so the leg ended `waiting` on a decision brief rather than building a stopgap. Candidate: before naming an owner for a baseline red, `sprint` greps the item (and `FINDINGS.md`) for the failing spec, and quotes any prior attribution in the dispatch.
