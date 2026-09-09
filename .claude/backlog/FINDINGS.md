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

- 2026-09-09 (retro) — **`retro` Step 4 requires the lock be taken and released "in one shell
  invocation", and a pass with real absorption work cannot honour that literally.** This pass
  appended dated notes to eight items, created ten item files, edited `config.yml` and `QUEUE.md`,
  drained this file and committed — one invocation carrying all of it is a blob nobody can review
  before approving, which is the shape the conventions warn against elsewhere. The lock was instead
  taken with a plain `mkdir` and held across several calls, which is safe *because* no `trap` was
  used: the rule's stated reason is that `trap ... EXIT` releases on the call's return, and that
  reason does not extend to the invocation count. The rule and its reason disagree, and a session
  reading the rule literally either writes an unreviewable blob or believes it must skip the
  absorptions (pointer: `skills/retro/SKILL.md` Step 4, `references/CONCURRENCY.md` *Lock every
  write to the backlog directory*).
  **Filed as item `0126` on 2026-09-09; the lesson half is open** — the general rule, that a
  skill restating a reference's rule drifts invisibly because an *incomplete* restatement still
  reads as correct, is broader than that one paragraph and has no home yet.
- 2026-09-09 (queue) — **`queue` Step 5 has no disposition for a swept entry whose work half an
  existing row already carries, so this sweep invented one from `retro`'s vocabulary.** Step 5
  offers exactly two outcomes: specify and rank it, or write an unranked `next: queue` stub. One of
  three entries belonged wholly to `0060`, which already reserves that half for whoever claims it —
  so a new row would have split one decision across two, and a stub would have been a row `develop`
  must refuse. What the entry needed is `retro` Step 4's *absorbed*: name the row, append one dated
  line to its *Notes & decisions*, remove the entry. Both sweepers empty the same file and only one
  of them can say "this already has a home", which is also why the marker rule beside it covers only
  the work-and-lesson case and not this one (pointer: `skills/queue/SKILL.md` Step 5,
  `skills/retro/SKILL.md` Step 4, item `0057` — which lists four other missing `queue` operations
  and not this one).
