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

- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
- 2026-08-25 — **`develop` Step 5.4 says to clear the claim and take the lock, but the lock helper
  pattern in the docs releases on shell exit — and every Bash call is a new shell.** Routing 0036,
  `mkdir .lock` + `trap 'rm -rf' EXIT` in one tool call released the lock the instant that call
  returned, so the read, the write and the commit spanned three unlocked windows rather than one held
  one. `CONCURRENCY.md` says "hold it for the read, the write and the commit, then release in the same
  turn" and `./claim` gets this right by being a single process; a session doing it by hand cannot,
  unless the whole sequence is one command. Rule to draw: **a by-hand lock must be one tool call from
  `mkdir` to `git commit`, or it is not a lock** — which is a fourth silent leak to add to the three
  `CONCURRENCY-INCIDENTS.md` already lists (pointer: references/CONCURRENCY.md *Lock every write*,
  skills/develop Step 5.4).

- 2026-08-25 — **a parked finding's factual claims decay while it waits, and `queue` Step 5 has no
  re-verification step — it says specify the entry, not check it.** Two of twelve in this batch had
  moved by the time they were swept, in opposite directions. The prose-wrapping entry offered two
  candidate fixes, "a helper that unwraps" or "a stated rule that guarded sentences are not
  rewrapped"; the rule *looked* landed because this repo's `CLAUDE.md` carries it, and a grep showed
  `testing-conventions.md` contains no rewrap rule at all and no suite has an unwrapping helper — so
  the whole defence was one project's own documentation, and both candidates were still open. The
  `/verify`-collides-with-a-built-in entry went the other way: its named instance could not be
  confirmed from inside the session, while the identical collision was live on `design`, which
  nothing had reported. Both tickets came out different for the check — 0063 kept both candidates,
  0064 was written against the class and explicitly does not rest on the reported instance. Nothing
  asked for either check. The sharp version: an entry states a fact about the tree, the tree moves,
  and a sweep that specifies faithfully ships a ticket built on a stale premise — which reads
  exactly like a well-specified one (pointer: skills/queue/SKILL.md Step 5, items/0063, items/0064).

- 2026-08-25 — **a claim released in the working tree but not committed reads as neither held nor
  free, and no mode reports it.** `0037`'s row says `in-progress` in the committed `QUEUE.md` while
  its item file, dirty and uncommitted, has `claimed_by:` cleared and `status: waiting`.
  `CONCURRENCY.md`'s *A stage writes only the ticket it holds* defines held as "a non-empty
  `claimed_by:` in the item, and nothing else", so the item reads free; the row reads taken;
  `./next develop` printed `0037 [no token] none declared — assume held, ask`; and `./next --drift`
  said "no drift" because it only compares the Status column against `blocked_by`. The rule that
  makes a claim durable is stated for the *claim* and not for the *release*, so a release is
  invisible in exactly the same way a claim would be (pointer: references/CONCURRENCY.md, items/0049,
  items/0066).
- 2026-08-25 — **checking "the output is unchanged" needs the HEAD copy of a suite run from inside
  the repo, and nothing says so.** 0053's AC1 is a byte-comparison against today's output, so the
  obvious move is `git show HEAD:tests/x.test.sh > $SCRATCH/x.sh && sh $SCRATCH/x.sh`. Every suite
  resolves `ROOT` from its own location, so the scratch copy exits 2 with "no claim script at
  …/scratchpad/skills/…" — which is not a red, just a different error, and a session in a hurry
  reads it as one. The copy has to land inside the repo tree (`tests/.head-x.sh`, dot-prefixed so
  the `tests/*.test.sh` loop does not pick it up) and be removed in the same turn. Third session in
  a row to hand-build throwaway comparison scaffolding, which is the finding 0053 itself came from
  (pointer: skills/develop/SKILL.md Step 5, items/0053).

- 2026-08-26 — **the install contract caps how DRY the three backlog scripts can be, and nothing
  says so.** 0044 FR2 asked for one `decomment`, "shared rather than copied a third time"; the
  answer had to be its fallback clause instead. `queue` Step 0 scaffolds a backlog by copying each
  template into `.claude/backlog/`, and `tests/backlog-scripts-installed.test.sh` names exactly
  three (`next claim close`) and forces each byte-identical to its template — so a fourth file the
  scripts *source* is possible but is a change to the install contract, the scaffold step and that
  guard's `SCRIPTS` list, not a refactor. The result is one copy per script rather than one copy
  per reader, held in step by a comment in each saying "change one, change both". That is fine at
  two and is the third-instance trigger `coding-conventions.md` fires on the day a fourth reader
  appears (pointer: skills/queue/SKILL.md Step 0, tests/backlog-scripts-installed.test.sh,
  items/0048).

- 2026-08-26 — **`references/CONVENTIONS.md`'s stop-and-report path has no answer for a single
  capture session asked to queue related work across several repos when only some resolve
  conventions.** This session was asked to turn one comparison's findings into tickets across four
  repos; one (this one) already had `conventions.path` set, three others (a PM-tooling repo, a
  Jira-ticket-drafting repo, and a general skills repo) had no conventions wiring at all. The
  skill file's instruction is unambiguous per-repo ("stop, do not scaffold, do not guess"), but
  says nothing about the batch case: whether to proceed with the repos that resolve and report the
  rest, or hold the whole batch for the user to decide how the unwired repos should be wired
  first. Handled it here by doing the resolvable repo and stopping to ask about the other three,
  which seems like the right default but isn't written anywhere (pointer:
  references/CONVENTIONS.md "Resolution order").

- 2026-08-30 — **`queue` has no operation for a re-rank against a stated priority, and Step 4's
  mechanics do not scale to one.** Step 4 describes a move as two single-line edits each preceded by
  a fresh read, which is right for one row. This session moved ten and inserted two; twenty
  sequential edits across twenty tool calls is slower *and* less safe than one locked rebuild that
  asserts the row set is preserved modulo the additions. `./claim` and `./close` are granted the
  rebuild exemption by *Never rewrite `QUEUE.md` by hand* for exactly that reason — holding the lock
  while they rebuild — and a re-rank does the same thing with no named permission, so it is either
  a fourth script or a stated exemption (pointer: skills/queue/SKILL.md Step 4,
  references/CONCURRENCY.md, items/0048, items/0065).
- 2026-08-30 — **Step 4 assumes the rows the user wants promoted already exist, and here none of
  them did.** Asked to make token efficiency the top priority, the honest answer was that the
  backlog held no ticket aimed at turns-per-session — the lever `MEASUREMENT.md` itself names — so
  the re-rank had to run Step 2 and Step 3 inside Step 4 before it had anything to order, and rank
  the results by the instruction rather than by the tiers. Nothing in the skill says to check that
  the theme being promoted is represented before reordering; a session that skipped the check would
  have produced a confident re-rank of rows that do not serve the stated priority (pointer:
  skills/queue/SKILL.md Steps 2–4, items/0073, items/0074).
- 2026-08-30 — **`design` Step 4 tells an unclaimed ticket's session to write it and never says to
  claim it, and there is no release path once it has.** `CONCURRENCY.md` *A stage writes only the
  ticket it holds* says "claim the row you write", so settling 0074 meant claiming, writing,
  then clearing `claimed_by:` and the `in-progress` row by hand — `./close` is for closing and
  nothing reverses a claim. 0056 already has this step's missing lock (FR3) and `expects:`
  re-check (FR4) but not ownership, so the same edit should decide whether `design` claims at all
  and, if it does, what hands the row back (pointer: skills/design/SKILL.md Step 4, items/0056,
  items/0048, .claude/backlog/claim).
- 2026-08-30 — **Thinking is ~70.5% of a session's output tokens and its text is not retained in
  the transcript, so the largest output term cannot be measured from the record.** Stored
  `thinking` blocks carry an empty `thinking` field and a ~3,000-character `signature`, so 0074's
  measurement could only get it as a residual — output tokens minus estimated text and tool-input
  tokens. Human-facing narration was 4.6% and tool inputs 24.9% by comparison. This bounds what
  0073 can report and it is not obvious before you look: a turns-and-tokens breakdown that assumes
  the transcript holds what the model wrote will silently attribute 70% of output to nothing
  (pointer: items/0073, items/0074, tools/harvest-usage.sh, MEASUREMENT.md).
- 2026-08-30 — **A stale claim whose release is sitting uncommitted in the shared tree has no rule
  in `develop` Step 1, and the two rules that apply give opposite answers.** 0037 reads
  `in-progress` with an empty `touches:` and an `expects:` overlapping this ticket's, so *The
  working tree is shared too* says its files are held and the candidate must be stepped over. But
  its `claimed_at` is five days old and the working tree holds an uncommitted edit setting it to
  `waiting` with the token cleared, which *Claim tokens* calls a dead session to report and offer
  to release. Nothing says which wins, and the deadlock is self-sustaining: the release edit
  cannot be committed by any session but 0037's own (*A stage writes only the ticket it holds*),
  so it stays uncommitted and every later session re-derives the same ambiguity from scratch. The
  narrow question — may a session step over a *stale* in-progress row's file scope, and who may
  land an abandoned release — belongs with 0049 (what a claim token guarantees) or 0050 (file
  scope where the prose files are the product) (pointer: skills/develop/SKILL.md Step 1,
  references/CONCURRENCY.md, items/0037, items/0049, items/0050).
- 2026-08-30 — **`verify` Step 1 gives no argument-less default a session actually reaches for, and
  "most recently handed off" is the wrong one.** This session opened `/verify` with no ID, derived
  the candidates by grepping item frontmatter for `next: verify`, and took the ticket whose handoff
  commit was newest — 0042, ranked *third* of the three ready rows. `./next verify` prints `TAKE
  0053`, which is what Step 1 says to use, but the instruction sits in a subordinate clause ("With
  no argument, `./next verify` prints the topmost row") in a step whose headline is about refusing
  and claiming. Handoff recency is a plausible-looking substitute for rank because the newest
  handoff is the freshest in a session's context, and nothing reds when it is used: the ticket
  verifies fine, it is just the wrong one, so the queue's ranking silently stops governing the
  order work is checked in. The user caught it; nothing in the skill or the scripts would have
  (pointer: skills/verify/SKILL.md Step 1, .claude/backlog/next).
- 2026-08-30 — **`measurement.test.sh`'s privacy assertion greps the whole repo through `git grep`,
  which reads the *working tree*, so every tracked file lands in the evidence set of any verdict
  resting on that suite.** Confirmed empirically in a throwaway repo: `git grep` with no flags
  matches uncommitted content in tracked files. `verify` Step 7 derives *advisory* by intersecting
  the dirty set with the evidence set, so on this repo that intersection is non-empty whenever
  *any* tracked file is dirty, however unrelated — and 0042's AC6 ("the whole suite passes") pulls
  the privacy check into every close. Taken literally this means no ticket whose ACs run the full
  suite can ever close over a dirty tree. It did not bite here only because the one dirty file was
  committed by its owning session mid-run. Either Step 7 needs a notion of evidence narrower than
  "every path the assertion touched", or a repo-wide guard needs to be excluded from the evidence
  set by name (pointer: tests/measurement.test.sh privacy NFR block, skills/verify/SKILL.md Step 7).
- 2026-08-30 — **0042's batching AC4 binds the date to the literal word `dated`, so a reword that
  keeps the date bound to its figure still reds the guard.** Rewriting "capture-side and dated
  **2026-08-22**" to "capture-side, from **2026-08-22**" leaves the figure carrying its own date in
  exactly the position the assertion exists to require, and `tests/batching.test.sh` reports 12
  passed, 1 failed. The regex `dated[^0-9]{0,4}20[0-9][0-9]-...` is a good binding and the fix is
  a real one — this is the residual cost of it, not an argument against it. But
  `testing-conventions.md` warns in the same rule that a guard whose reds can be artefacts of
  unrelated correct work teaches everyone to discount its reds, and the comment beside the
  assertion, which is careful to disclaim rewrap-proofness, does not mention that the anchor word
  itself is now load-bearing prose (pointer: tests/batching.test.sh AC4, skills/develop/SKILL.md
  batching paragraph, items/0063).
- 2026-08-30 — **The release chain has no re-check step, and a sibling session closed a ticket in the
  middle of one.** A release audit found the install 14 files behind at the *same* version number,
  decided what to ship on the basis that 0042 and 0044 were both unverified, and was about to push
  when the user stopped it because another session had just finished — which had verified and closed
  0042, changing the premise the release decision rested on. `CONCURRENCY.md`'s *Re-read immediately
  before you write* is scoped to `QUEUE.md` rows, so nothing covers the longer read-decide-push gap,
  and the release chain in CLAUDE.md is a four-step sequence with no instruction to re-verify state
  before executing it. Every step is silent when skipped, including this missing one (pointer:
  CLAUDE.md *This project is the tool its sessions are running*, references/CONCURRENCY.md).
- 2026-08-30 — **A "convert the helpers" ticket has no way to state which call sites it converted, so
  a partial conversion reads as a complete one.** 0053 routed `close.test.sh`'s eight inline
  `[ "$rc" -eq 0 ] && ok … || bad …` lines through new `assert_rc` helpers and recorded that in the
  notes, but left `claim.test.sh`'s five identical lines untouched and `close.test.sh`'s own line 402
  unconverted — the twin of the line it *did* convert at 193, same shape, same file. Nothing failed:
  the suites are green, the flag works, and AC4's "all three honour it" is satisfied by three suites
  that honour it to three different depths. The gap is only visible by counting `saw:` lines against
  `ok` lines (13 of 18 in claim, 92 of 93 in close), which no AC asked for and no guard measures.
  A ticket that changes an interface at N call sites wants the call-site count as an acceptance
  criterion, not a prose note listing the ones that were done (pointer:
  tests/claim.test.sh:120,130,140,147,158, tests/close.test.sh:402, items/0053).
- 2026-08-30 — **`verify` Step 3's mutation sweep needs the pre-change suite to compare against, and
  a suite's own `ROOT` resolution makes that awkward in a way each session rediscovers.** Checking
  0053's AC1 ("output unchanged") meant running the pre-0053 and post-0053 copies of three suites
  against today's tree. The obvious base — the commit before the implementation — was wrong, because
  two of the three suites had since been changed by *other* tickets (0044), so the diff showed 0044's
  cases as 0053's noise. The isolating comparison is pre-boundary vs post-boundary, both replayed
  against the current tree, and neither is the working copy. The item's notes record the ROOT gotcha
  (a copy must live inside the repo) but not the base-selection one, which cost the larger detour
  (pointer: items/0053 notes, verify SKILL.md Step 3).
- 2026-08-30 — **A ticket's AC can require exactly the assertion `testing-conventions.md` warns
  against, and nothing in `develop` says which wins.** 0074's AC1 asks a guard to check each skill
  cites the rule "exactly once"; `testing-conventions.md` says *assert membership, never
  cardinality*, because "names exactly one X" goes quietly false the day a sibling adds a second.
  Here the count IS the contract — FR1 is "stated in one place, cited never restated", so a second
  copy is the defect — and the guard was written to the AC with the reasoning recorded in its header.
  But that judgement was made silently by the implementing session. Step 2 tells `develop` to restate
  the contract and Step 3 to load the conventions; neither says what to do when they collide, and the
  cheap answer (follow the AC, so `verify` passes) is not obviously the right one (pointer:
  tests/reporting.test.sh header, items/0074 AC1).
- 2026-08-30 — **The `set -e` short-circuit trap is recorded in the guard where it was found, so the
  next guard author hits it again.** Writing `[ "$n" -eq 0 ] && echo "FAIL …"` as a statement inside
  an audit function makes the function exit non-zero on the CLEAN path, which `set -e` turns into a
  truncated result for every caller — the guard reports a partial audit exactly when nothing is
  wrong. `tests/reference-size.test.sh` documents this inside one loop body; `tests/reporting.test.sh`
  hit it twice in fresh code before that note was found. Five shell guards now share the pattern and
  the warning lives in one of them (pointer: tests/reference-size.test.sh `offenders`,
  tests/reporting.test.sh `audit`).
- 2026-08-30 — **A Documentation NFR row that cites a skill file makes *advisory* near-certain in
  this repo, and the mechanism is not the repo-wide-grep one already parked above.** 0044's
  Documentation row requires its fourth refusal ground to land in `skills/verify/SKILL.md` Step 5,
  so that path is in the evidence set by the row's own wording — and `skills/**/SKILL.md` is the
  one surface every suite-wide ticket edits, so it is dirty whenever any of them is in flight. It
  was: 0074 holds it in `touches:` and had it uncommitted, and 0044 verified green on all nine ACs
  and all three NFRs yet could not close. The general shape is that this plugin's tickets are
  *about* the prose files, so documentation NFRs routinely name a file another ticket is legitimately
  rewriting, and Step 7's intersection reads a scheduling collision as evidence contamination. Worth
  noting the substance agreed — the fourth-refusal text was intact in both the committed and working
  copies — and Step 7 explicitly refuses that as grounds to close, correctly, since 3895's edit is
  unfinished. The narrow question is whether an evidence set should carry a path a row cites for
  *documentation* on the same terms as one an assertion executed (pointer: items/0044 Documentation
  NFR, skills/verify/SKILL.md Step 7, items/0074, items/0050).
- 2026-08-30 — **An acceptance criterion that globs the test directory lets another session rewrite
  its contract mid-verify.** 0044 AC9 is "given the whole suite, when `for t in tests/*.test.sh`
  runs, then every suite passes". During this pass 3895 created `tests/reporting.test.sh` as an
  untracked file, so the set AC9 quantifies over grew by one unfinished guard while the verdict was
  being formed. Nothing red — the run used a pinned clone — but the AC as written is satisfied
  against a moving target, and two sessions can hold contradictory true answers to it at the same
  moment. This is the same class as 0052's requirement that an AC name the input that would make it
  red: a glob names no input. The fix direction is either pinning such an AC to a commit or
  enumerating the suites it means (pointer: items/0044 AC9, items/0052, tests/).
- 2026-08-30 — **`./next verify`'s collision warning flagged the two rows that declared *nothing*,
  while the collision that actually cost the close came through a `touches:` that was declared
  properly.** The banner read "0053 [b673] none declared — assume held, ask" and the same for 0074;
  0053 turned out to share no path with 0044 at all, and 0074 — which had just committed a full
  `touches:` list naming `skills/verify/SKILL.md` — was the one that made the verdict advisory. The
  warning keys on absence of a declaration, which is the cheaper signal, and says nothing about a
  declared overlap with the row it is offering. That cross-check is exactly 0045, and this is a
  worked case for it: the useful output would have been "0044's evidence set meets 0074's declared
  touches at skills/verify/SKILL.md" (pointer: items/0045, .claude/backlog/next, items/0074).
- 2026-08-30 — **A bundled Claude Code skill named `verify` shadows this plugin's `/verify`, and its
  first instruction is the inverse of ours.** Typing `/verify` in this repo loaded
  `bundled-skills/…/verify` — a runtime-observation skill whose opening rules are "Don't run tests.
  Don't typecheck" and "the scope is a diff" — rather than `ai-building-tools:verify`, which reads a
  ticket's acceptance criteria and whose declared `qa_level` for almost every ticket in this backlog
  *is* a scripted assertion. A session that followed the loaded skill would have refused to run
  `tests/reporting.test.sh`, reported SKIP for "no runtime surface", and closed nothing, because the
  bundled skill has no concept of a backlog row. It was caught only because the operator noticed the
  base directory in the skill header. The same collision is available for `design` and `run`. The fix
  direction is either a distinguishing name or a line in this repo's `CLAUDE.md` telling a session to
  invoke the plugin-qualified `ai-building-tools:verify` explicitly (pointer: CLAUDE.md,
  skills/verify/SKILL.md, items/0064).
- 2026-08-30 — **`references/REPORTING.md` attributes the same requirement numbering to two different
  tickets, three sections apart.** Line 37 cites "0039 FR14" and line 57 cites "0036 FR13"; both FR13
  and FR14 are *defined* only in `items/0039`, which inherited 0036's numbering when 0036 was split
  into children. Neither citation is wrong on its own — 0036 references both numbers — but a reader
  chasing one of them learns the numbering is ticket-ambiguous, and 0074 AC7 pins the 0036 spelling
  while nothing pins the other. This is the citation-drift 0036's split created and is not specific to
  this file: any reference to an FR number in the 0036/0039 pair needs saying which ticket's list it
  means (pointer: references/REPORTING.md:37, references/REPORTING.md:57, items/0036, items/0039).
