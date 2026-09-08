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

- 2026-09-07 — **`queue` Step 0 has the same missing resolution order this sweep just filed against
  `retro` Step 1, and its failure mode is worse.** Step 0 says "Find `.claude/backlog/` at the
  project root. If it doesn't exist, scaffold it" — invoked from `/Documents/AI`, which is not a
  repo and holds no backlog, the literal instruction is to **create one there**, in a directory
  `git` does not track, while four real backlogs sit beneath it. `retro`'s version of this gap
  sweeps the wrong buffer; this one manufactures a fifth. Not folded into 0111, whose design
  question is about which buffers a *sweep* reads: this is a create-or-refuse decision at scaffold
  time, and the answer to one does not settle the other. Nearest live row is 0111 (pointer:
  `skills/queue/SKILL.md` Step 0, item 0111, item 0101 for the conventions half of the same shape).
- 2026-09-07 — **`queue` Step 2 and `CONCURRENCY.md` disagree about what the lock covers, in one
  sentence each, and a session has to pick.** Step 2: *"Release in the same turn; the item file,
  ranking and the row are all unlocked."* `CONCURRENCY.md`, *Lock every write to the backlog
  directory*: *"Every write, no exemptions … `config.yml`, `FINDINGS.md`, `RANKING.md` and the item
  files are all inside the boundary."* Followed `CONCURRENCY.md` as the named authority — the queue
  skill's own preamble sends you there before writing anything — and held the lock across the
  `QUEUE.md` edits, the 0060 amendment and `RANKING.md`. That is the stricter reading and it cost a
  lock held for minutes, which `CONCURRENCY-INCIDENTS.md` sanctions but also advises against
  ("keep every edit that is not to `QUEUE.md` outside it"), so all three documents are pulling
  slightly differently. Worth noting 0091 is the row for making a by-hand write take the lock at
  all — it will have to resolve this to be specifiable (pointer: `skills/queue/SKILL.md` Step 2,
  `references/CONCURRENCY.md` *Lock every write to the backlog directory*, item 0091).
- 2026-09-07 — **Claiming an ID is a mandated write to `config.yml`, so every capture session
  collides with whatever ticket holds that file — and `queue` has no rule for it.** `./next develop`
  reported `COLLIDES 0105 | .claude/backlog/config.yml — held by 0040 [ef8e]` and the same for 0086,
  while this capture had *already* bumped `next_id` in that file under the lock, because Step 2
  requires it. So the collision the scripts report is one a capture session structurally cannot
  avoid and cannot resolve by taking a different row: it is not taking a row. Distinct from 0106,
  whose four defects are about `claim` seeding, a non-building stage reserving a build scope, an
  unused reservation, and a re-claim discarding a narrowing — none is "a write no ticket owns".
  Either `config.yml` is outside the `touches:` regime for the counter specifically, or capture's
  write needs to be visible to it; today it is neither (pointer: `skills/queue/SKILL.md` Step 2,
  item 0106, item 0083 for the second-checkout half).
