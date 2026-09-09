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
- 2026-09-09 (queue) — **No step in `queue` checks whether the work already exists before a ticket is
  written, and this capture came within one step of shipping three duplicates.** Step 2 says how to
  write a ticket well and Step 5 says to check a *parked finding* is still true, but nothing tells a
  capture session to read the queue for overlap first. Writing nine rows for the sprint project, the
  overlap was found only because the ranking walk in Step 3 required reading `QUEUE.md` end to end:
  `0041` already specified the session review this was about to re-file, and `0060` and `0067` own
  the design questions two of the new rows depend on — so two children would have shipped
  unblocked against decisions that are explicitly still open. The check that saved it was
  incidental to a different step, and on a backlog too long to skim, or a capture of one ticket
  where no ranking walk is needed, it would not have happened (pointer: `skills/queue/SKILL.md`
  Steps 2 and 3, items `0128`, `0041`, `0059`, `0060`, `0067`).
- 2026-09-09 (queue) — **Step 3 ranks one row against a queue and says nothing about inserting a
  related cluster.** Nine rows went in as a contiguous block below the operational fixes and above
  the design tail, and every part of that shape was invented: that the cluster stays contiguous at
  all, that prerequisites lead it, and that a blocked child keeps its place inside it rather than
  sinking below its siblings. The pairwise regret operator is defined for two rows, and applying it
  nine times pairwise would have interleaved the cluster through the queue, which is defensible by
  the letter of the rule and would have made the project unreadable as a unit. `0060` records the
  same gap from the other end — no sweeper has a procedure for a buffer far past its threshold —
  which suggests the missing rule is about batch operations generally rather than about ranking
  (pointer: `skills/queue/SKILL.md` Step 3, `.claude/backlog/RANKING.md`, items `0128`, `0060`).
- 2026-09-09 (queue) — **Step 1's re-specify row says a `next: queue` ticket "already has a rank
  and keeps it," which is true only for one bounced back from a later stage.** A ticket parked at
  capture time by Step 5 — Problem section only, no FRs, deliberately left out of `QUEUE.md` — has
  never been ranked at all, so re-specifying it needs Step 3's ranking walk to run for the first
  time, not be skipped. Surfaced while specifying `0138`, a design ticket about giving idea capture
  its own lightweight front door — any such front door produces exactly this never-ranked case on
  promotion (pointer: `skills/queue/SKILL.md` Step 1, item `0138`).

- 2026-09-09 — **A guarded phrase can be satisfied by an unrelated sentence that differs only in
  markdown emphasis.** `0111`'s AC5 asserts `resolved, never discovered` in `retro` Step 1, where
  `0078` had already written *`*resolved*, never discovered`* about a different rule; the literal
  reds only because the asterisks break it. Confirming red first caught it, and a later reflow
  that drops the emphasis would rewire the assertion with no guard noticing. Worth a rule in
  `testing-conventions.md`'s grep-guard section, or a check that no two rules in one window share
  an asserted phrase modulo emphasis.
- 2026-09-09 — **`skill-size.test.sh` checks that a justification exists, never that it still
  describes the file.** `retro` grew from 22,343 to 24,698 bytes under `0111` while its
  justification — keyed to `b9a5ee0`, naming Step 4's dispositions and Step 1's two modes — went
  stale without reddening: the block now furthest over the goal is not mentioned in it. A
  justification is a cached claim about the file it justifies and ages like any other.
- 2026-09-09 — **A backlog item in this public repo names an internal repository path.** Item
  `0111`'s Problem and Decision sections carry `neumo_repos/Probation`, against `CLAUDE.md`'s "no
  internal names". Written by the capture and design passes; a build session holding the row can
  neither redact pushed history nor decide that it should. Needs a row of its own, and a check on
  the intake side — nothing between `queue` and `develop` reads an item against the repo's own
  privacy rule.
