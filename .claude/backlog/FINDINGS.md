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

- 2026-09-05 — **The trailer scope question above is answered by `skills/develop/SKILL.md` Step 1**,
  which says a lifecycle commit is not exempt from `Co-Authored-By`, and by
  `references/CONCURRENCY.md` *The git index is shared*, which requires it of every AI-assisted
  commit. `handoff` now carries it; `claim` and `close` still do not, and **still need a row** — none
  exists. Worth recording for its own sake: the answer was already written down in two files the
  ticket cites, and both a build pass and a QA pass read the question as open. A "scope decision" that
  the repo's own prose already settles is cheaper to look up than to escalate (pointer:
  `skills/queue/templates/{claim,close}`, `git-conventions.md` *Co-authorship*, items `0081`, `0082`).
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

- 2026-09-05 — **`retro` Step 4 takes the backlog lock for every write inside `.claude/backlog/`, and
  Step 6 tells the same session to append to `FINDINGS.md` without mentioning it.** Both steps are in
  one skill, the file is plainly inside the boundary Step 4 names, and the two disagree only by
  omission — so a session that follows Step 6 literally, after correctly locking in Step 4, appends
  unlocked and reads as having done the whole pass properly. This pass noticed only because it was
  holding the lock already and asked whether it could drop it before parking. `develop` Step 7 and
  `verify` Step 6 append to the same file and are worth checking for the same gap
  (pointer: `skills/retro/SKILL.md` Steps 4 and 6, `references/CONCURRENCY.md` *Lock every write*).
  — filed as item 0091 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **Step 1's ranked-slice instruction has a marker for a deferral and none for "no
  destination exists".** Draining an 84-entry buffer at 10.5x the threshold, 40 entries resolved to an
  existing row and 15 did not — and for those 15 the skill's own advice ("*needs a row, none exists*
  is a useful marker and a wrong one is worse than none") is prose in Step 1 rather than a form, so
  the wording was invented here and the next retro will invent a different one. Both markers want to
  be greppable, because the count of each is what says whether retros are keeping up
  (pointer: `skills/retro/SKILL.md` Step 1, `.claude/backlog/FINDINGS.md`).
  — filed as item 0100 on 2026-09-05 by queue; kept for the lesson, do not re-file.

- 2026-09-05 — **a by-hand locked write can release the lock having committed nothing, and the
  sequence reads as success.** Landing two items in one shell invocation, the commit was written as
  `git commit -m … -- $paths` with `paths` accumulated in a loop. **zsh does not word-split an
  unquoted parameter expansion**, so git received one argument of two space-joined paths and refused
  with `pathspec … did not match any file(s)`. The `rm -rf` released the lock on the next line
  regardless, leaving both item files edited and `FINDINGS.md` drained **uncommitted** in a shared
  tree — the *uncommitted claim* failure shape, arriving from a direction the lock cannot see:
  `CONCURRENCY-INCIDENTS.md` names three ways a by-hand lock leaks and all three are about the lock
  outliving the turn, not about the commit inside it failing while the release succeeds. Two cheap
  guards: name every pathspec literally rather than through a variable, and check `git status` is
  clean before releasing rather than after. The scripts are immune because they commit their own
  fixed paths; this bites only the by-hand sequence, which is what `retro` and every withdraw-by-hand
  close use (pointer: `references/CONCURRENCY-INCIDENTS.md` *A busy or stale lock*, `skills/retro/SKILL.md` Step 4).
  — filed as item 0091 on 2026-09-05 by queue; kept for the lesson, do not re-file.
