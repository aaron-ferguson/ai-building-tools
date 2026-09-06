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

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---

- 2026-09-03 — **Three of one ticket's acceptance criteria shared a single defect shape: a
  substring `case` over a tool's whole output, satisfied by text the tool prints unconditionally.**
  `0085`'s AC8 (`*"work"*`), AC9 (`*protocol*`, `*git*`) and AC10 (`*10000*`) all stayed green under
  mutations that provably landed — AC10's is unfalsifiable outright, because `10000` is a substring
  of the `ctx/turn` figures `100000`/`110000`/`115000`/`125000`. `testing-conventions.md` already
  names the shape twice (*anchor an assertion to the claim, not the document that contains it*; *a
  number present where the contract is that it is formatted*) and says that a suite with a known
  systematic weakness of this shape should be swept **from a loop, not by reading for the next
  instance**. Every guard in this repo greps prose, so the exposure is the whole suite, not one
  file — a unit of work for `queue`, sized as a sweep of all 15 `tests/*.test.sh` for whole-output
  and whole-file matches (pointer: `tests/cost-by-category.test.sh`, `tests/*.test.sh`, item `0063`).
  — filed as item 0089 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-03 — **`./close` clears `touches:` with a skiplist that a legal YAML list evades, so a
  closed ticket can go on reserving files.** YAML allows a block sequence at the *same* indentation
  as its key, so `touches:\n- src/a.ts` is valid; `close`'s `if (skiplist && $0 ~ /^[ \t]+-/)`
  requires leading whitespace and leaves those entries in the item. The row moves to `DONE.md` and
  the item still names two files, which `CONCURRENCY.md` (*The working tree is shared too*) obliges
  the other window to read as held — an invisible narrowing of what anyone else may take. Found by
  the mutation sweep on `./handoff`, which had copied the same line; fixed there (`^[ \t]*- `) and
  deliberately **not** fixed in `close`, whose contract and guard belong to another ticket
  (pointer: `skills/queue/templates/close`, `tests/close.test.sh`, `skills/queue/templates/handoff`).
  — filed as item 0090 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-03 — **No backlog script is proven to hold the lock through its commit, and no ordinary
  assertion can prove it.** `CONCURRENCY.md` (*Lock every write to `QUEUE.md`*) requires the lock to
  cover the read, the write **and** the commit, but releasing it after the edit and before the commit
  leaves every observable identical: correct files, a landed commit, a released lock. Mutating the
  release earlier in `./handoff` kept its whole suite green until a `pre-commit` hook was added to the
  fixture to witness the lock at commit time — one hook, four lines. `claim.test.sh` and
  `close.test.sh` have the same blind spot on scripts whose commit-inside-the-lock is their entire
  reason for existing (pointer: `tests/handoff.test.sh` "the lock is still held at the moment the
  commit runs", `tests/claim.test.sh`, `tests/close.test.sh`).
  — filed as item 0092 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **All three backlog scripts commit without the `Co-Authored-By` trailer that
  `git-conventions.md` requires of every AI-assisted commit.** Found verifying `0081`, whose own NFR
  table names the trailer, so it is that ticket's red — but `claim` and `close` have the same gap and
  fixing only `handoff` leaves the three inconsistent. What is undecided is the scope: whether a
  script-generated bookkeeping commit counts as AI-assisted (it is made on a session's behalf, so this
  session read it as yes), or whether the convention should exempt them and the NFR row was the error
  (pointer: `skills/queue/templates/{claim,close,handoff}`, `git-conventions.md` *Co-authorship*,
  items `0081`, `0082`).
  — filed as item 0090 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **A row claimed and then released records no reason, so the next session re-derives
  it.** `0086` was claimed by `f7c0` and handed straight back to `develop | ready` 58 seconds later
  (`bdf2cdc` → `6eba29c`), with no note in the item and nothing in the queue. This session then spent
  the same analysis reaching the same answer — its `expects:` overlaps `0081`'s live claim on
  `skills/develop/SKILL.md` and `skills/verify/SKILL.md`. `./handoff` takes a destination stage and
  no reason, and no step in `develop` requires one when it releases rather than completes, so a row
  put back untouched is indistinguishable from one never taken. This **still needs a row**; none
  exists (pointer: `.claude/backlog/handoff`, `skills/develop/SKILL.md` Step 5, item `0086`).
  — filed as item 0094 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **`./claim` writes the row to `QUEUE.md` before it checks that the item file exists**,
  so a row whose item is missing or misnamed leaves `QUEUE.md` edited, uncommitted and unlocked — the
  same fail-open shape `0082` was written to close, on a third path `0082` does not name and so could
  not take. `claim:136` is the `mv`, `claim:140` the refusal. Cheap to fix (resolve the item above the
  row edit), and deliberately left: only the author may widen a contract. This **still needs a row**;
  none exists (pointer: `skills/queue/templates/claim`).
  — filed as item 0090 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **`0082` replaced warn-and-carry in `claim`; `close` and `handoff` still have it,
  verbatim.** `close:62` and `handoff:103` both detect that their commit will carry another session's
  uncommitted rows, print a warning, and commit anyway. The argument FR3 makes for refusing is not
  specific to claiming: a pathspec limits a commit to paths and never to authorship, and all three
  scripts hold the lock when they decide. `0082`'s *Out of scope* covers only other files, not other
  scripts, so this is a sibling row rather than a widening. This **still needs a row**; none exists
  (pointer: `skills/queue/templates/{close,handoff}`, item `0082` FR3).
  — filed as item 0090 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **Step 1's ranked-slice instruction has a marker for a deferral and none for "no
  destination exists".** Draining an 84-entry buffer at 10.5x the threshold, 40 entries resolved to an
  existing row and 15 did not — and for those 15 the skill's own advice ("*needs a row, none exists*
  is a useful marker and a wrong one is worse than none") is prose in Step 1 rather than a form, so
  the wording was invented here and the next retro will invent a different one. Both markers want to
  be greppable, because the count of each is what says whether retros are keeping up
  (pointer: `skills/retro/SKILL.md` Step 1, `.claude/backlog/FINDINGS.md`).
  — filed as item 0100 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **zsh aborts an unmatched glob before the command runs, so `>/dev/null 2>&1` does
  not silence it.** A by-hand id-collision check written as `ls "$B/items/$id-"*.md >/dev/null 2>&1`
  printed fifteen `no matches found:` lines to the terminal while the `if` around it still evaluated
  correctly — the redirection belongs to a command zsh never executed, so the noise reads as fifteen
  failures in the middle of an otherwise successful locked write. Harmless there; the same construct
  with `set -e` and no `if` wrapper aborts the run instead, and its error names a path rather than a
  cause. The backlog scripts are `sh`, where an unmatched glob falls through literally and this
  cannot happen — it bites only the by-hand sequence, which is what a sweep uses (pointer:
  `skills/queue/SKILL.md` Step 2 *Mint from the disk*, `references/CONCURRENCY-INCIDENTS.md`).

- 2026-09-05 — **`queue`'s *"kept for the lesson, do not re-file"* marker has no correct reading when
  the lesson and the work are the same edit.** Three entries carried it into this retro; for two, the
  whole lesson was prose that `0091` FR1 and FR3 already specify, so *take the lesson* and *do not
  re-open the work* name one act and contradict each other. Landing the prose by hand would have
  half-stranded a `ready` row, and the entries were instead drained with nothing written — which the
  marker does not describe either. In a repo whose product **is** prose, most retro destinations are
  also `develop` rows, so this is the normal case here rather than an edge (pointer:
  `skills/retro/SKILL.md` Step 1, `skills/queue/SKILL.md` Step 5, item `0100`).
