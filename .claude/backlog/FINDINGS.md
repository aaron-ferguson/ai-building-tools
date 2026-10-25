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

- 2026-10-25 — develop 0195 (7871): **`CHANGELOG.md`'s header says every entry is written by `verify` through `./close --note`, yet `queue` writes tickets whose FRs/ACs require the `## Unreleased` note to exist before the close (0195's Documentation NFR, 0216 FR7/AC9).** An AC verify must check before closing cannot be satisfied by a note the close itself writes, so develop wrote the notes and told verify not to pass `--note` — a per-ticket workaround. Either `queue` Step 2 stops writing CHANGELOG ACs (the note is verify's), or the header admits develop-written notes; today the two contradict.
- 2026-10-25 — verify 0195/0216/0110 (9eba/60da/daba): **a dispatch named three tickets from three separate develop gates (7871, 3c97, 844a) as one verify batch, and verify's batch rule ("nothing licenses widening the batch past the membership a develop gate already fixed") has no line for a user-named set that is not a gate.** Handled as three sequential single-ticket passes, one claim, one evidence table and one close each, mutations in a per-ticket worktree. Separately: `.git/` is a sensitive path for Write, so a sweep script cannot live beside a worktree under `.git/`; a repo-root `*.log` (gitignored) worked as the in-directory sweep output file that config.yml asks for.
- 2026-10-25 — develop 0169 (9fa0): **`./close`'s scope report reads each `touches:` entry as a literal path, so a glob entry reports itself as "declared but untouched" and every file it matched as "touched but undeclared"** — 0169 declared `"tests/*.test.sh"` for a change to all 34 suites and the close listed all 34 as undeclared. Neither `develop` Step 1 nor `CONCURRENCY.md` says whether a glob is a valid `touches:` entry (only the exclusive claim's `"*"` is named), and `./next`'s held-file comparison presumably has the same literal reading, so a glob reservation may reserve nothing. Decide: expand globs in `claim`/`next`/`close`, or forbid them in `touches:` and say so. This still needs a row.
