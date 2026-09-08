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

- 2026-09-08 — **`claim` writes `held-by` without the timestamp `CONCURRENCY.md` mandates, and
  `close` and `handoff` both write one.** *Lock every write to the backlog directory* says to put
  `$CLAIM` **and a UTC timestamp** in `.lock/held-by`; `claim:81` writes `claim <id> by <token>` and
  stops, where `close:71` and `handoff:112` both `printf` a date. So the lock's commonest holder is
  the one holder whose `held-by` cannot be dated, and any reader written against the protocol —
  0040's driver was the first — works perfectly in testing against a close-held lock and silently
  treats every claim-held lock as ageless. 0040 sidestepped it by reading the lock **directory's**
  mtime, which `mkdir` sets on every path, but that is the driver declining to depend on the field
  rather than the field being fixed. **This still needs a row and does not have one**; `claim` was
  *Out of scope* for 0040, and only `queue` may file it. Adjacent to 0047, which is about the
  busy-lock *procedure* rather than about what `held-by` records (pointer: `.claude/backlog/claim`
  line 81, `references/CONCURRENCY.md` *Lock every write*, item 0040 *Notes & decisions*).


- 2026-09-08 — **`develop` Step 1 tells you to check `expects:` against in-progress `touches:`, and
  the obvious way to find in-progress items returns closed ones.** `grep -l "claimed_by: [^ ]"
  items/*.md` matched five items, all of them `status: done` with a stale token still in the
  frontmatter — `close` and `handoff` clear the row but at least five closed items carry a token
  they were never stripped of. The real answer was `./next develop`, which prints the held file set
  and showed none. Cheap to get wrong in the direction that *stops* work: a session reading those
  five as live scope collisions concludes there is nothing safe to develop (pointer: `develop`
  SKILL.md Step 1, `items/0010`, `0023`, `0044`, `0048`, `0049`).

- 2026-09-08 — **The AC25 guard forbidding a lock removal matches only the literal `.lock`, and the
  skill's own idiom evades it.** `tests/orchestrate.test.sh` extracts the fenced blocks and greps
  `(rm|rmdir|unlink)[^|]*\.lock`, which is anchored to state exactly as its comment claims — but the
  block it guards opens `LOCK=.claude/backlog/.lock` and then says `"$LOCK"` everywhere after. A
  fenced block containing `rm -rf "$LOCK"`, or a path built through a variable, leaves the suite at
  130 passed while doing precisely the thing FR15 exists to forbid; only the literal spelling reds.
  Verified both ways during 0040's verification. The delivered prose is clean in either form, so
  this is coverage and not a live defect — but it is coverage of the one clause whose whole point is
  that a future edit must not slip it in (pointer: `tests/orchestrate.test.sh` *AC25*, the
  `removers` loop; `skills/orchestrate/SKILL.md` Step 7).

- 2026-09-08 — **The spend cap's figure is unguarded; only its citation is.** AC26's derivation
  check reads MEASUREMENT.md's per-stage means and asserts they appear in the comment above
  `stage_budget_usd:`. Nothing relates the comment to the number beneath it, so setting
  `retro: 99.00` with its `2.51` citation intact leaves the suite at 130 passed, 0 failed. Left
  uncovered rather than papered over, per `verify` Step 3. Two things for whoever takes it: the
  arithmetic could be asserted directly from the cited mean, and the **rounding granularity is
  unstated** — all three shipped caps are mean x 1.5 rounded to the nearest five cents (6.05, 5.45,
  3.75), which is self-consistent, but the comment says only "times 1.5", so an honest RECOMPUTE
  yields 6.04 and 3.76 and reads as drift (pointer: `.claude/backlog/config.yml`
  `stage_budget_usd`, `tests/orchestrate.test.sh` *AC26*).

- 2026-09-08 — **`skills/queue/templates/config.yml` still names skills that were renamed.** Line 1
  reads "Read by the capture, develop, and qa skills"; the suite ships `queue`, `develop` and
  `verify`. Every project scaffolded from this template inherits the wrong names. Left alone as
  adjacent to 0105, which rewrote only the `next_id` comment two lines below it. This still needs a row.
- 2026-09-08 — **A ticket asserting an id's history cannot be checked by `develop` Step 2's grep.**
  0105's Problem statement said an id had been issued to work that in fact never claimed it; only
  `git log --all --diff-filter=A -- 'items/<id>-*'` could tell. Step 2 prescribes grepping the symbol
  an FR names, which answers "does this still exist" and not "did this ever". Worth a sentence in
  the skill — a claim about the past needs a history check, not a file check.
- 2026-09-08 — **A guard whose file scope includes `tests/` also covers its own source, and its
  fixture literals become real citations.** 0105's new item-ID check reported `tests/citations.test.sh`
  on its first run, correctly: the unresolvable id its fixtures need was spelled in an anchored form
  in a covered file. Fixed locally with a variable, but the shape generalises to any guard that
  scans the directory it lives in.

- 2026-09-08 — **0105's item-ID matcher reads any zero-padded four-digit number in an anchored form
  as a citation, so a file mode or a clock time reds the guard.** Appending `# chmod 0644 — the mode
  the lock file gets.` and `# The nightly driver starts at (0900).` to a covered file produces two
  `cites item …, which is in no table` failures. The leading-`0` requirement is what correctly keeps
  years like `(2026)` out; it is also what lets modes and times in. No live instance — the shipped
  tree is green at 59 citations — so this is latent, and the bad shape is that the cheapest fix looks
  like rewording innocent prose rather than fixing a citation. `references/CONCURRENCY.md` is about
  lock files, where `0644 —` is a plausible edit. Still needs a row.
- 2026-09-08 — **The same matcher covers `QUEUE.md` but not `DONE.md`, `FINDINGS.md` or `items/`.**
  Verified by appending an unresolvable anchored citation to `items/0105-*.md` and to `FINDINGS.md`:
  both pass. FR3 asked for `tests/` and got that plus `cited_files()`, so this is within spec — but
  item files are where ids are cited most, and the `QUEUE.md`-in / `DONE.md`-out seam means a
  citation checked today stops being checked the moment its row is closed. Still needs a row.
- 2026-09-08 — **An AC written as the outcome of an agent-performed operation has no runner here, and
  nothing in the ticket says so.** 0105 AC1 reads "given a withdrawal, `next_id` is unchanged or
  higher"; no script withdraws a ticket and none mints an id — both are `queue` prose — so the
  outcome is unobservable at every level and the guard necessarily asserts the *sentence* instead.
  That is the altitude gap `verify` Step 3 warns about, arriving structurally rather than by
  oversight. `qa_manual:` was empty, so the split was never declared at queue time. The general
  question — how a prose-executed repo verifies a behavioural AC — is bigger than one row.
- 2026-09-08 — **LANDED at `2a69aa9`: the published home paths are redacted, and the privacy guard
  no longer calls a redaction a leak.** Both halves were one defect. `items/0060:81` and
  `items/0111:29` published a real username in a public repo; the username was load-bearing in
  neither sentence, so both are now the placeholder form. The guard's bare `[-/](Users|home)[-/]`
  could not tell that form from a real path — at its worst six flagged lines, four of them redacted
  prose *about* the defect, including the entry that recorded it — so it now requires a literal name
  character after the separator, and carries a both-directions control whose samples are assembled
  rather than written. Falsified three ways: widening the exemption reds the three real-path cases,
  restoring the old pattern reds the three redaction cases, and a fresh real path in a tracked file
  still reds the live check. Suite green, 23 files. **The remaining half needs a row:** nothing in
  `queue`'s or `capture`'s own steps runs this guard, so a sweep session can commit a tracked file
  that reds it and not find out — which is exactly how `b9d11af` introduced these two.
- 2026-09-08 — **`references/CONCURRENCY.md:81` states a behaviour `./next --drift` does not have.**
  *A stage writes only the ticket it holds* says "A row reading `in-progress` over a tokenless item
  is drift, not ownership — `./next --drift` reports it, and no reader treats it as a claim." It
  does not report it: driven directly on that exact shape, `--drift` prints `no drift` and exits 0.
  `--drift` is a Status-column-vs-`blocked_by` cache check (`next:88`, `next:467–493`) and reads
  neither `claimed_by:` nor the item's `next:`. So the protocol tells a reader to rely on a check
  that cannot see the thing, and the 0084 incident this repo already recorded — row `develop |
  in-progress` over item `next: verify, status: ready`, `claimed_by:` empty — reproduces with
  `--drift` silent while `./next verify` declines to offer the row and `./next develop` reports its
  files held under `[no token]`. Pre-existing: written 2026-08-24 at `953ce51` (0029), long before
  `0081` touched the file. This is also why `0081` AC4 is unverifiable and went to `queue`. Still
  needs a row — and the two halves may be one fix or two: correct the sentence, or give `--drift`
  the row/item agreement check the sentence promises.
- 2026-09-08 — **`tests/handoff.test.sh` returns rc=0 and *no tally* when the template is mutated
  externally on a line the harness also mutates.** The harness rewrites its own copy of `handoff`
  for the read-back cases; an external mutation to the `touches:` skiplist collides, and the case
  prints `FAIL — the mutation did not apply — the case below proves nothing`, then the script exits
  **0** with no `N passed, M failed` line at all. `verify` Step 3 names the missing tally as the
  tell, and it is right — but rc=0 is the dangerous half, because a QA session running the suite in
  a `|| true` loop and reading tallies sees a file that simply produced no output and reads it as
  noise rather than as a red. The mutation did in fact redden (the read-back fired with
  `did not apply to: touches.entries`), which is only discoverable by reading the full output.
  Still needs a row: a collided self-mutating guard should exit non-zero, or print a tally of 0/1.
- 2026-09-08 — **Company and product names sit in item prose in this public repo, and the
  2026-09-08 privacy sweep did not cover them.** `2a69aa9` redacted published *home paths* and
  fixed the guard; the tracked tree still carries `Neumo`/`neumo-ds` in `items/0003:69`,
  `items/0004:29`, `items/0056:30,131`, `items/0070:71`, `items/0111:31` and `items/0113:43`.
  Several are references to the constraint itself ("a company tool this public repo must not depend
  on"), which is arguably fine; `items/0003` and `items/0004` are not — they describe a
  court-tenanted rollout and "Neumo's Jira" story rubric. `CLAUDE.md` says "no internal names".
  Outside both tickets under test, so not their red. Still needs a row, and the decision it needs
  is whether a *mention of the rule* is exempt, since a guard that cannot tell those apart is the
  same trap the home-path guard just fell into.
- 2026-09-08 — **The findings buffer is at 14 against `findings_threshold: 8`** and this pass added
  to it. `verify` has no gate on that count — only `./next --drive` does — so a hand-driven session
  can keep filling it indefinitely. Noted rather than acted on; `0060` owns how the buffer is
  emptied and gated.
- 2026-09-08 — **`queue`'s re-specify has no rule for withdrawing a *criterion*, and the obvious
  move breaks citations.** `0081` came back with AC4's instrument broken and its subject correct;
  deleting AC4 renumbers AC5–AC7, which `tests/handoff.test.sh` cites by number in four section
  comments and which two QA verdicts cite in evidence tables. The skill's *Withdrawing a ticket*
  section has exactly this reasoning for ids ("a citation silently re-pointed at unrelated work is
  one nobody can see") and it is stated only of `next_id`. Resolved here by marking FR5 and AC4
  withdrawn in place and keeping the numbers, but that was invented, not read. Still needs a row:
  either `queue` Step 2's re-specify case states the rule for FR/AC numbering, or it says why a
  criterion differs from an id.
