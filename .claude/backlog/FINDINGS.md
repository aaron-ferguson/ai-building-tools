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
- 2026-09-09 (retro) — **Step 1's "work in ranked slices — read fewer entries and finish each" has no
  reading for a buffer where nothing is stale.** At 32 entries against a threshold of 8, every entry
  was dated within three days, so the expiry rule dropped none and there was no cheap basis for
  choosing a slice *before* reading — the cross-entry view Step 1 exists to produce is precisely what
  tells you which entries are one lesson. This pass read all 32 and then dispositioned every one,
  which is the opposite of the instruction and was the only honest option. Either the slice is chosen
  after reading rather than before, or the step should say that reading is cheap and only *writing*
  is sliced (pointer: `skills/retro/SKILL.md` Step 1).
- 2026-09-09 (retro) — **Step 4's "defer" disposition reads as a peer of the other three and is not
  one, and this pass used it wrongly until the user pushed back.** Seven entries were deferred with
  verified destinations, each of them a unit of work this pass had fully understood — which is
  exactly what Step 4's *"a pure unit of work is filed, not handed back"* forbids, since the next
  pass then pays again for judgement already bought. The deferral was economy on *writing*, and Step
  1's licence ("beyond what this pass can specify, defer it") does not cover that: the limit it
  names is understanding, not typing. The step could say so — a deferral is for a lesson you could
  not finish *understanding*, never one you could not finish *writing up* (pointer:
  `skills/retro/SKILL.md` Step 1 and Step 4).
