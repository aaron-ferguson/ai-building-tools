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

- 2026-09-07 (deferred by retro 2026-09-09) — **Claiming an ID is a mandated write to `config.yml`,
  so every capture session collides with whatever ticket holds that file, and `queue` has no rule
  for it.** `./next develop` reported `COLLIDES 0105 | .claude/backlog/config.yml — held by 0040
  [ef8e]` and the same for `0086`, while that capture had *already* bumped `next_id` under the lock,
  because Step 2 requires it. The collision is one a capture session structurally cannot avoid and
  cannot resolve by taking a different row: it is not taking a row. Either `config.yml` is outside
  the `touches:` regime for the counter specifically, or capture's write becomes visible to it;
  today it is neither. **Destination: no row exists.** `0106` and `0091` were both opened and
  rejected — `0106` is what `touches:` *means* across claim and close, `0091` is a by-hand write
  taking the lock and proving its commit; neither is "a mandated write no `touches:` can express".
  Needs a new row (pointer: `skills/queue/SKILL.md` Step 2, `.claude/backlog/config.yml` `next_id`).
- 2026-09-08 (deferred by retro 2026-09-09) — **`claim` writes `held-by` without the timestamp
  `CONCURRENCY.md` mandates, and `close` and `handoff` both write one.** *Lock every write to the
  backlog directory* says to put `$CLAIM` **and a UTC timestamp** in `.lock/held-by`; `claim:81`
  writes `claim <id> by <token>` and stops, where `close:71` and `handoff:112` both `printf` a date.
  The lock's commonest holder is the one holder whose `held-by` cannot be dated, so any reader
  written against the protocol works perfectly against a close-held lock and silently treats every
  claim-held lock as ageless. `0040`'s driver sidestepped it by reading the lock **directory's**
  mtime, which `mkdir` sets on every path — the driver declining to depend on the field rather than
  the field being fixed. **Destination: no row exists.** `0092` (the lock covering the commit) and
  `0047` (the busy-lock procedure) were both opened and are about different properties; `claim` was
  *Out of scope* for `0040`. Needs a new row (pointer: `.claude/backlog/claim` line 81,
  `references/CONCURRENCY.md` *Lock every write*, item `0040` *Notes & decisions*).
- 2026-09-08 (deferred by retro 2026-09-09) — **Company and product names sit in item prose in this
  public repo, and the 2026-09-08 privacy sweep did not cover them.** `2a69aa9` redacted published
  *home paths* and fixed the guard; the tracked tree still carries the company and design-system
  names in `items/0003:69`, `items/0004:29`, `items/0056:30,131`, `items/0070:71`, `items/0111:31`
  and `items/0113:43`. Several are references to the constraint itself ("a company tool this public
  repo must not depend on"), which is arguably fine; `items/0003` and `items/0004` are not — they
  describe a court-tenanted rollout and a company Jira story rubric, and `CLAUDE.md` says "no
  internal names". **Destination: no row exists, and it needs a decision before it can have
  criteria** — whether a *mention of the rule* is exempt, since a guard that cannot tell those apart
  is the same trap the home-path guard just fell into. Needs a `next: design` row. Distinct from
  `0118`, filed 2026-09-09, which is only about *running* the existing guard where a sweep commits.
- 2026-09-08 (deferred by retro 2026-09-09) — **`queue`'s re-specify has no rule for withdrawing a
  *criterion*, and the obvious move breaks citations.** `0081` came back with AC4's instrument
  broken and its subject correct; deleting AC4 renumbers AC5-AC7, which `tests/handoff.test.sh`
  cites by number in four section comments and which two QA verdicts cite in evidence tables. The
  skill's *Withdrawing a ticket* section carries exactly this reasoning for ids ("a citation
  silently re-pointed at unrelated work is one nobody can see") and states it only of `next_id`.
  Resolved on `0081` by marking FR5 and AC4 withdrawn in place and keeping the numbers — invented,
  not read. **Destination: `skills/queue/SKILL.md` Step 2's re-specify case.** `0062` was opened and
  is adjacent but not it: `0062` is about an FR list that cannot express a *removal of behaviour*,
  not about criterion renumbering and citation stability. Needs a new row, or one sentence in Step 2
  saying why a criterion differs from an id.
- 2026-09-08 (deferred by retro 2026-09-09) — **`CONVENTIONS.md` rung 3's "do not search the
  filesystem for a directory that looks right" now has three call sites, and the file it lives in is
  scoped to conventions only.** `0111` settled by citing it for the findings buffer, `0078` FR2
  cites it for the tool repo, and it was written for the conventions directory. The prohibition and
  the stop-rather-than-guess refusal are the general rule; the conventions ladder is one instance of
  it. Both citing tickets put "changing `CONVENTIONS.md`'s own ladder" out of scope, so nothing owns
  the generalisation, and the fourth per-project file to need it will cite a conventions file for a
  reason unrelated to conventions. `0116`, filed 2026-09-09, is the fourth call site and puts the
  same change out of scope. **Destination: a new row to split the refusal into a resolution
  reference that the conventions ladder itself cites** — no existing row owns it (pointer:
  `references/CONVENTIONS.md`, items `0111`, `0078`, `0116`).
- 2026-09-09 (deferred by retro 2026-09-09) — **The citation enumeration is authored in two places
  and nothing pins them together.** `close`'s `path_is_conventional_guard` and
  `docs/decisions/003`'s *A citation has to name an assertion* both spell out the same list —
  `tests`/`spec`/`__tests__` directories, `*.test.*` / `*_test.*` / `*.spec.*` / `*_spec.*` /
  `test_*`, or mode `100755`. `003` is right to record what shipped (FR14 asked for exactly that),
  so this is not a restatement to delete; the gap is that `tests/close-by.test.sh` asserts `003`
  mentions `close_by` and the eligibility *rule*, and never that its enumeration still matches the
  script's. Widening the `case` in `close` leaves `003` stale and green. The fix shape already
  exists in this repo: `tests/cost-by-category.test.sh` was reanchored to assert a *relationship*
  between two figures rather than either literal. **Destination: a new row** — `0089` was opened and
  is a sweep for assertions that cannot fail, which this is not: the assertion can fail, it just
  asserts the wrong thing (pointer: `skills/queue/templates/close`, `path_is_conventional_guard`;
  `docs/decisions/003-who-may-close-a-ticket.md:45-52`).
- 2026-09-09 (deferred by retro 2026-09-09) — **A falsifiability probe reports the wrong reason when
  the file is already mutated, and the wrong reason is the one a session would act on.** Verifying
  `0078`, deleting `falls back to a marked local park` from the real `references/CONVENTIONS.md`
  reddened AC3 as it should, and `findings-routing.test.sh`'s independence probe alongside it
  announced *"deleting the privacy clause also removed the fallback; one guard is covering two
  claims"* — a claim about guard design that was simply untrue. The probe deletes its phrase from a
  copy of whatever is on disk, so with the fallback already gone its `elif` fell to the wrong
  branch. The outcome was right (red) and only the message was wrong, which is the case `verify`
  Step 3 says to fix by asserting the message rather than the status. **Destination: the two
  `no-fallback` / `no-privacy` blocks in `tests/findings-routing.test.sh`, opened and confirmed** —
  have the independence probes assert the phrase is present in the real file first, exactly as the
  AC5 deletion loop already does for the skills. A small fix, left for a pass with the suite in
  front of it rather than landed half.

- 2026-09-09 (retro) — **`retro` Step 4 requires the lock be taken and released "in one shell
  invocation", and a pass with real absorption work cannot honour that literally.** This pass
  appended dated notes to eight items, created four item files, edited `config.yml` and `QUEUE.md`,
  drained this file and committed — one invocation carrying all of it is a blob nobody can review
  before approving, and it is exactly the shape the conventions warn against elsewhere. The lock was
  instead taken with a plain `mkdir` and held across three calls, which is safe *because* no `trap`
  was used: the rule's stated reason is that `trap ... EXIT` releases on the call's return, and that
  reason does not extend to the invocation count. The rule and its reason disagree, and a session
  reading the rule literally either writes an unreviewable blob or believes it must skip absorptions
  (pointer: `skills/retro/SKILL.md` Step 4, `references/CONCURRENCY.md` *Lock every write*).
- 2026-09-09 (retro) — **Step 1's "work in ranked slices — read fewer entries and finish each" has no
  reading for a buffer where nothing is stale.** At 32 entries against a threshold of 8, every entry
  was dated within three days, so the expiry rule dropped none and there was no cheap basis for
  choosing a slice *before* reading — the cross-entry view Step 1 exists to produce is what tells you
  which entries are one lesson. This pass read all 32 and then dispositioned every one, which is the
  opposite of the instruction and was the only honest option. Either the slice is chosen after
  reading rather than before, or the step should say that reading is cheap and only *writing* is
  sliced (pointer: `skills/retro/SKILL.md` Step 1).
