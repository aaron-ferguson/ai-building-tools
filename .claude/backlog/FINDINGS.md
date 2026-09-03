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

- 2026-09-01 — **a prose comment inside a single-quoted `awk` program breaks the shell quoting, and
  the failure names nothing about quotes.** Editing `close`'s DONE-row builder, a comment reading
  `other projects' spellings` closed the `'...'` wrapping the whole awk script; `close.test.sh` then
  failed 20 of 63 cases reporting an empty reconcile list and a commit carrying six extra files — a
  signature that reads as broken reconcile logic. `close`, `claim` and `next` all embed awk this way
  and their comments carry the reasoning, so the scripts actively invite the hazard. Cheap guard:
  `sh -n` per script in `backlog-scripts-installed.test.sh`, which would have caught it before the
  behavioural suite did (pointer: `skills/queue/templates/close`, `tests/close.test.sh`).
- 2026-09-01 — **`retro` edits skills, scripts and conventions and never runs a test, so the session
  that changes a tool is the least likely to learn it broke it.** Step 5 covers committing and
  releasing; nothing says to run the target repo's suite. This pass committed the awk defect above
  and found it only because I ran `tests/*.test.sh` unprompted. Two adjacent traps cost time in the
  same pass: this repo's suite **commits inside the live repo**, so running it over uncommitted edits
  yields failures that look like logic errors and are tree pollution — the worktree-at-HEAD
  comparison `develop` Step 5 already prescribes is what separates them, and `retro` never mentions
  it; and `skill-size.test.sh` rejected the first draft 1,387 bytes over goal, forcing a relocation
  that produced a better destination than the one proposed. The guard improved the edit, which is an
  argument for running them (pointer: `skills/retro` Steps 4-5, `tests/skill-size.test.sh`).
- 2026-09-01 — **an entry that is both a lesson and a unit of work cannot have its lesson half
  removed, so a processed lesson is re-read at full price by every later sweep.** Recorded here once
  before and swept without being fixed. Measured this pass against AetherWorks' 44-entry buffer: 15
  were pure lessons and removable; of the 29 left, at least six have had their lesson landed (the
  fold-into-NNNN mechanism, three guards-that-cannot-fail, the `qa_level` half of two UI items) and
  survive only because deleting them would lose `queue`'s half. Second occurrence, in a second repo,
  which argues for building the marker rather than noting it again: either a sweeper writes one the
  other reads, or the halves become independently removable
  (pointer: `skills/retro` Step 4, `skills/queue` findings sweep).
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
- 2026-08-30 — **A comment shared byte-identically across three files cannot be improved by the
  session that holds two of them.** The note above the suites' shared helpers reads "each carry this
  pair" and now covers two pairs (`saw`/`saw_on_pass` and `assert_rc`/`assert_rc_nonzero`) — the
  exact imprecision that let `assert_rc` reach `next.test.sh` and `close.test.sh` and miss
  `claim.test.sh`, which is what bounced 0053 from verify. Tightening it in 0053 meant editing
  `tests/next.test.sh`, held by 0045 [296c], so it was written and then backed out: half-changing it
  leaves the three disagreeing, which is worse than the imprecision. There is no "shared prose" unit
  a claim can hold, so this class of fix is only ever available to a session holding every copy at
  once (pointer: tests/claim.test.sh:74, tests/close.test.sh:153, tests/next.test.sh:255, items/0053).
- 2026-08-30 — **`develop` reads the held file set once at claim and never again, but Step 5 runs the
  full suite an hour later.** 0053's `./next develop` reported no claimed files; 0045 [296c] then
  claimed and began editing `skills/queue/templates/next` and `tests/next.test.sh` mid-session, so the
  Step 5 run came back with 11 `next.test.sh` failures and a red `backlog-scripts-installed.test.sh`
  in files 0053 never touched. Step 5 has the worktree recipe for telling whose red it is, but it is
  framed as diagnosis after the fact; a `./next --claimed` re-read costs one line and answers it
  before the suite is even run. The snapshot-vs-subscription gap is structural — any session long
  enough to build something can be overtaken (pointer: skills/develop/SKILL.md Step 5,
  references/CONCURRENCY.md Rule 6, .claude/backlog/next, items/0053).
- 2026-08-30 — **`touches:` has no way to say "named in an AC but not edited", so an untouched
  declared file blocks other rows for the life of the claim.** 0053 declared `README.md` because AC5
  names it; AC5 needed no change, and until the claim was released `./next develop` reported 0051,
  0038 and 0046 as COLLIDES against a file nobody had open. The skill tells a session to *widen*
  `touches:` the moment work reaches further and says nothing about narrowing it the moment work
  turns out not to; the cost of the over-declaration is visible to every other session and invisible
  to the one holding it (pointer: skills/develop/SKILL.md Step 1, references/CONCURRENCY.md Rule 6,
  items/0053).
- 2026-08-30 [0045] `./next --drive` selects develop rows with `takeable_develop`, which skips
  `in-progress` rows but crosses nothing against their `touches:` — so a driver can dispatch a row
  that `./next develop` now refuses as COLLIDES. 0045's ACs all name `./next <stage>`, so this was
  left alone rather than widened mid-ticket. Worth a row, or 0039's to absorb.
- 2026-08-30 [0051] `$6.01` / `$4.45` per closed ticket are now stale caches of a figure this
  ticket corrected to `$5.71` / `$4.23`, and they sit in three open tickets — `0036` (its
  Performance NFR measures against it), `0040` and `0041`. Not edited from here: `CONCURRENCY.md`,
  *A stage writes only the ticket it holds*. Whoever takes those rows re-reads MEASUREMENT.md
  rather than the FR. The general shape is worth a rule — a figure quoted about a file the ticket
  does not own has no guard that can fail, and this is the third time it has bitten (0026, 0051's
  own problem statement, now these three).
- 2026-08-30 [0051] A published figure can decay with every one of its inputs still correct and
  every citation still resolving: pinned numerator, live denominator, self-consistent arithmetic.
  The record had learned this lesson one section earlier for `FINDINGS.md` and had not carried it
  to the figure beside it — so "we pinned it once" is not evidence the next figure is pinned.
- 2026-08-30 [0051] Mutation-testing the new guards was not ceremony: two of six were green
  against the exact mutation their comment named. One reproduced 0042's defect at *section* scope
  after 0042 fixed it at document scope — a narrower grep is not automatically an anchored one.
  The other was `grep` reading an asserted `--until` as its own option, which errors rather than
  fails, so three assertions had never run. A guard that names its mutation and is not run against
  it is worth about as much as no guard.
- 2026-08-30 [0f0a] **The dirty set that decides `verify`'s advisory label changed three times
  inside one session**, and the label flipped with it: `tests/next.test.sh` held by 0045, then
  `tests/measurement.test.sh` held by 0051, then nothing. Step 2 takes the tree snapshot once at
  the start and Step 7 intersects it, but the label describes the state the verdict *closes
  against* — which is the state at close time, not at claim time. 0053's own notes had already
  reached "re-check the held file set before a full-suite run"; this session says the check has to
  be re-taken immediately before `./close`, and the AC run re-done when a path in the evidence set
  moved. Possibly a Step 5 line rather than a Step 2 one.
- 2026-08-30 [0f0a] **`./next verify` correctly offered no row, and `verify` Step 1 has no branch
  for that.** The only `next: verify` row was 0053 and it collided with 0045's live `touches:`, so
  the script printed COLLIDES and "nothing here is safe to take" — the right answer, and not one of
  the cases Step 1 enumerates (a row for you, a row at another stage, no ticket at all). A session
  reading Step 1 literally has to invent whether to wait, take it anyway, or stop. It resolved
  itself here only because 0045 landed mid-session.
- 2026-08-30 [61a0] **`verify` Step 3 tells you to mutate the working tree, but on this repo the
  files under test are shared prose another live session predicts** — 0051's evidence set was
  `MEASUREMENT.md` and `README.md`, both in 0053's `expects:`. Mutating a scratch copy removes the
  window entirely, and it worked, but `git archive HEAD | tar -x` alone gives 55/1: the suite's
  tracked-file guards use `git ls-files` and fail loudly outside a repo. Correct behaviour, and a
  session could read that 1 as a real red. The copy needs a `git init` + commit first. Step 3 names
  only the in-tree route and its `git checkout -- <that path>` restore.
- 2026-08-30 [61a0] **An `absent` guard is only as strong as its casing.** Re-adding 0051's deleted
  false claim capitalised at the start of a sentence left the suite green; verbatim and lowercase
  it went red. The mutation was mine to get wrong, but the property is the suite's — `absent`
  helpers grep case-sensitively, and prose that returns at a sentence boundary returns capitalised.
- 2026-09-01 [becd] **A ticket's own AC named the guard that would prove it, and that guard could not
  see it.** 0052 FR7/AC6 said each added `testing-conventions.md` citation "resolves under
  `tests/citations.test.sh`"; that guard anchors on `CONCURRENCY.md`/`CONCURRENCY-INCIDENTS.md`/`rule:`
  and validates against `CONCURRENCY.md`'s headings only, so a conventions citation matches no anchor
  and the AC passed either way. `develop` Step 2's rule about a quoted figure covers the *number* case;
  this is the same failure over a *mechanism* — "guard X checks this" is equally a claim about a file
  the ticket does not own, and equally worth re-reading at the source. Worth a sentence in that rule.
- 2026-09-01 [becd] **A mutation run by hand is not covered by the discipline the suite applies to its
  own.** `citations.test.sh`'s `mutate()` refuses a mutation whose diff is empty, precisely because a
  `sed` that matched nothing reads exactly like a guard that holds. Mutating the real tree by hand has
  no such check: substituting `ui-conventions.md`, which appears in no covered file, left the suite
  green and "the guard is wired to nothing" was the available and wrong reading. `verify` Step 3 tells
  a session to break the behaviour and confirm red; it does not tell it to confirm the break landed.
- 2026-09-01 [becd] **Falsifiability at phrase level is blocked on a citation marker this repo has not
  decided on.** Resolving a cited *rule phrase* inside a conventions file needs to tell a citation from
  emphasis, and italics carry emphasis throughout: three existing spots (`skills/retro/SKILL.md` x2,
  `skills/verify/SKILL.md` x1) are emphasis directly after a conventions filename. 0052 resolved the
  filename and recorded the gap in the guard's header. The marker is a design question, and it is the
  same question `citations.test.sh`'s anchoring rule already answered for `CONCURRENCY.md` — so the
  precedent exists and only needs extending. Candidate ticket.
- 2026-09-01 [c80d] **`queue` has no operation for "this request is an existing `design` ticket's
  undecided answer."** Aaron asked for two scripts, a `release` and a `doctor`. The first is a clean
  Add. The second is one of the four candidate mechanisms 0061 exists to choose between, so
  capturing it as a `develop` ticket would have pre-empted the design pass — exactly what Step 2's
  *"guessing acceptance criteria to avoid the stage"* warns against — while capturing it as a
  second `design` ticket would have duplicated 0061 outright. Step 1's table has no row for it.
  **Amend** was the closest fit and is what I used, but it is described as *"add an FR to X"* and
  its whole procedure is about widening an already-specified ticket's scope: re-check `size`, the
  ACs, the QA plan, *Out of scope*. Folding new evidence into an unsettled design question is a
  different operation — it can *narrow* the question rather than widen the scope, and here it
  eliminated two of four candidate shapes. Nothing told me to report to the user that their request
  had landed as an amendment to an existing row rather than as the ticket they asked for, which is
  the part they would notice. Candidate ticket, and it is close to 0057's territory (queue
  operations that exist in practice and not in the skill).
- 2026-09-01 [c80d] **Step 3 says to assert a new ticket's placement, and is silent on the re-rank
  it can imply for an existing row.** The evidence that placed 0084 is also an argument for
  promoting 0061 out of the Tier 2 lower band. Step 3 covers the case where the new ticket makes
  row 1 look wrong ("say so and propose the rerank"); it does not cover a promotion argument for a
  row in the middle, and Step 4 assumes the user asked for a move. I recorded the argument in
  `RANKING.md` and left the move unmade, because rows 1-10 sit under a standing instruction of
  Aaron's — but that reasoning was mine to invent, not the skill's to supply.
- 2026-09-02 [6983] **`design` Step 4 has no path for a decision whose deliverable is criteria on
  other people's tickets.** 0085's FR2 required routing removable turns to 0066, 0081, 0047 and
  0048; `CONCURRENCY.md`, *A stage writes only the ticket it holds*, forbids the settling session
  from writing any of them, and that rule says explicitly that naming them in your own notes is not
  filing them. The only legal move I could find was to hand the ticket to `queue` rather than to
  `develop` — but Step 4's three item-scoped outcomes are develop, waiting and hand-back-to-queue-
  because-it-is-claimed, and none of them is this. A design pass that routes work needs a stated
  fourth outcome, or the routing dies in a settled ticket's prose (pointer: `skills/design/SKILL.md`
  Step 4, item 0085).
- 2026-09-02 [6983] **A ticket opened by a `develop` session at `next: design` carries no *Open
  design question* section**, which is the section `design` Step 1 names as its contract. 0085 was
  opened by 0073 under its FR5 and put the question under a heading of its own invention ("Why this
  is `next: design` and not `develop`"). It was a better section than the template's — it argued why
  the question was not guessable — but Step 1 read against nothing, and a session following it
  literally would have stopped (pointer: `skills/develop/SKILL.md` Step 3, `templates/item.md`).
- 2026-09-02 [b00a] **`design` Step 2 tells a session to look at prior art, the design system and
  the conventions, and never to check the measurement the ticket rests on.** 0085 was a
  fully-specified ticket whose every FR was denominated in a share of *turns* that no one had
  priced in *tokens*, and a `/design` pass settled it, wrote a decision record and handed it on
  without the gap being visible — it took Aaron to send it back. `develop` Step 2 has the rule this
  needs in a narrower form ("a figure is a cached claim about a file it does not own; re-verify it
  against the source"), and `design` has no equivalent even though a design pass is the stage most
  likely to build a whole argument on one. Candidate: extend Step 2 with a fourth thing to look at
  — the evidence the ticket cites — with the same date-stamp-and-re-verify discipline. Verified
  worth having: the re-run reproduced all four tables, but the attack on the rules found the
  published "mechanism > work" headline flips under two defensible rule changes (pointer:
  `skills/design/SKILL.md` Step 2, `skills/develop/SKILL.md` Step 2, item 0085, `MEASUREMENT.md`).
- 2026-09-01 — **`expects:` can name a path that never matched any file, and nothing catches it.**
  0085's `expects:` listed `.claude/backlog/items/0048-remaining-backlog-write-sites.md` and
  `.claude/backlog/items/0066-three-wrong-answers-in-the-scripts.md` — neither is the real filename
  (`0048-scripts-for-the-remaining-write-sites.md`, `0066-backlog-script-ergonomics.md`), so a
  session opening 0085 and trying to read its `expects:` verbatim gets "file does not exist" for
  both. `expects:` is triage, not protection, so this cost one failed read rather than anything
  worse, but a field whose whole job is pointing a later session at the right files is silently
  wrong the moment a title-guessed slug drifts from the real one (pointer: items/0085 `expects:`,
  items/0048, items/0066).
- 2026-09-02 — **The installed plugin and the checkout differ at the same version number, live.**
  `diff -rq skills/ ~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.8/skills/` found
  `verify/SKILL.md` differs — the checkout carries 0085's FR6 fix (the single-git-status-call rule)
  and the installed copy at the identical `0.9.8` does not. This is the exact hazard the project's
  own `CLAUDE.md` names ("the version number does not prove it matches") and 0061/0084 already
  measured from the other side (a version bump can print success and re-extract nothing); this is
  the same failure mode caught from a live session rather than a designed test. Any `/verify` run
  against the installed plugin right now is running the pre-0085 git-status behaviour. Not queued as
  its own ticket since 0061/0084 already own this mechanism (pointer: `.claude-plugin/plugin.json`,
  0061, 0084, 0085 FR6).
- 2026-09-02 — **the backlog has no way to close a ticket that will not be built, so three withdrawals
  were performed by hand under the lock.** `.claude/backlog/close` refuses any row not at
  `next: verify` (*"verify owns closing"*), which is correct for a *verified* close and leaves
  withdraw, supersede and merge with no path at all — `0037` and `0087` were closed not built and
  `0079` was merged into `0086`, each by a by-hand lock, row delete, `DONE.md` prepend and commit
  that duplicates `close`'s body without its guards. Two conventions were invented at the point of
  use and nothing enforces either: the QA column carries `not built` / `merged` instead of a
  `qa_level`, and the acceptance criteria are deliberately left **unticked** so a withdrawal cannot
  be read as a pass. Both belong in the skill and in the script, not in one session's judgement
  (pointer: `.claude/backlog/close`, `skills/queue/SKILL.md`, item `0057`).
- 2026-09-02 — **`RANKING.md` says "current state only" and is accumulating dated sections anyway.**
  Its header splits the standing argument from the narrative the way `CONCURRENCY.md` splits from
  `CONCURRENCY-INCIDENTS.md`, and two dated 2026-09-02 sections sit in it below the table, one of
  which had to be marked superseded the same day it was written. The count in *The shape of this
  backlog* — "twenty-six of the thirty-six rows" — is stale for the same reason: a file that mixes
  current state with history gets read as neither (pointer: `.claude/backlog/RANKING.md`,
  `.claude/backlog/RANKING-HISTORY.md`).

- 2026-09-03 — **A `$0` in a skill's prose is replaced by the skill's invocation argument, silently
  corrupting the text the session is given.** `/verify 0085` delivered `skills/verify/SKILL.md`
  line 19 as *"a `verify` turn is the suite's cheapest at 0085.0946 and 97,965 context tokens,
  against a baseline 0085.1203"*, where the file on disk reads `$0.0946` and `$0.1203`. Two measured
  figures in the one paragraph that justifies this stage's rigour arrived as nonsense, and nothing
  in the delivered text marks the substitution. Every dollar figure in every skill file in this repo
  is exposed, and `MEASUREMENT.md` is full of them; the fix in this repo's control is to write money
  as `USD 0.0946` or to escape it, and the sweep is a grep for `\$[0-9]` across `skills/`
  (pointer: `skills/*/SKILL.md`, `references/*.md`).
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
- 2026-09-03 — **`verify` Step 3's mutation rule has no answer for a project that keeps two copies of
  the code under test, and this pass got it wrong first.** `0085` AC8 names `WRITES` being tested
  before `ORIENT`; that ordering exists in **both** `tools/classify-turns.sh` and
  `tools/cost-by-category.sh`, and the guard runs only the second. The first mutation was a no-op
  that read exactly like a guard holding. `testing-conventions.md` carries the rule
  (*confirm the mutation reached the copy the harness runs*) but `skills/verify/SKILL.md` Step 3 does
  not point at it, and a session that has just been told to break-and-restore is the one who needs
  it. Step 3 should require confirming the mutation changed the tool's **observable output**, not
  only that the substitution applied (pointer: `skills/verify/SKILL.md` Step 3,
  `../ai-building-conventions/testing-conventions.md`).
- 2026-09-03 — **A fixture comment is a cache of the fixture, and it ages exactly like a figure a
  ticket quotes about a file it does not own.** `tests/cost-by-category.test.sh`'s comment block
  read `turn 4  Read .../SKILL.md  orient` where the code has always constructed an `Edit` — and
  the AC that fixture exists for is precisely *"an Edit of a skill file is `work`, not
  `orientation`"*. Read beside a comment asserting the opposite of the behaviour under test,
  `case "$OUT" in *"work"*` looks like a reasonable question, which is plausibly how that
  unfalsifiable guard came to be written. `develop` Step 2 already carries this rule for a
  **ticket's** cached figures ("re-read the source, never the FR") and `testing-conventions.md`
  carries it for assertions, but neither reaches a comment inside the guard file: it reads
  correctly on its own, the arithmetic around it stays consistent, and nothing in a diff looks
  wrong. Candidate rule for `develop` Step 4 / `verify` Step 3: before trusting a fixture, read the
  fixture's construction, not its comment (pointer: `tests/cost-by-category.test.sh` fixture block,
  `skills/develop/SKILL.md` Step 2, item `0085` AC8).
- 2026-09-03 — **An acceptance criterion can be unfalsifiable *structurally*, because two ACs share
  a fixture whose construction they need to differ on — and no amount of re-anchoring fixes it.**
  `0085` AC7 needs contexts whose sums reconcile to an exact published decimal; AC10 needs contexts
  whose **rises are unequal**, because where they climb uniformly, crediting a rise to the turn that
  appended it and crediting it to the turn that followed both yield 10,000 and differ only in which
  bucket carries it. Every anchoring over the shared fixture is green under the off-by-one. The fix
  was a **second fixture in its own directory and a second tool run**, not a compromise fixture —
  two cheap fixtures beat one that serves neither AC's discriminating case. Nothing in `verify`
  Step 3 or `queue`'s falsifiability rules asks whether the fixture an AC will be checked against
  *can* separate the defect from the correct behaviour, which is a cheaper question at capture time
  than at verdict time (pointer: `tests/cost-by-category.test.sh`, `skills/queue/SKILL.md`
  falsifiability rules, items `0052`, `0085`).
- 2026-09-03 — **Anchoring an assertion to a table row makes a single-line mutation red several
  ACs at once, and the resulting tally reads like a broken harness.** Collapsing `mechanism_split`
  to one bucket reds five assertions across AC7, AC9 and AC10, because merging two rows moves every
  figure derived from either. That is the anchoring working as intended, but
  `testing-conventions.md` also warns that "an implausibly large [failure count] is usually a
  script that stopped parsing" — so a mutation sweep over row-anchored guards needs its expected
  **blast radius** written down beside each mutation, not just its expected colour, or the sweep's
  own control cannot be read (pointer: `tests/cost-by-category.test.sh` AC9 comment,
  `../ai-building-conventions/testing-conventions.md`).
- 2026-09-03 — **A malformed `touches:` makes an in-progress row's file scope invisible to `./next`,
  and the claiming session cannot fix it.** `0085`'s frontmatter reads `touches: []` with a YAML
  list item on the following line, so `./next develop` printed `CLAIMED FILES — another session
  owns these` with the id `0085 [0bd8]` and **no paths at all**. Deciding whether the top row was
  takeable therefore cost a full read of the other session's item file — the same defect `0066`
  FR4 names for `./next` warnings, one file over. Two halves worth separating: the scripts could
  refuse to *print an empty holder* without saying the frontmatter is unparseable, and nothing
  validates `touches:` at write time even though `./claim` writes the surrounding block.
  `CONCURRENCY.md` (*A stage writes only the ticket it holds*) correctly forbids the session that
  finds it from repairing it, so it can only be parked (pointer: `.claude/backlog/next`,
  `.claude/backlog/claim`, items `0066`, `0085`).
- 2026-09-03 — **`expects:` and a ticket's own *Notes* can disagree about who owns a file, and
  `develop` Step 1 checks `expects:` against the *code* rather than against the notes.** `0084`
  listed `skills/retro/SKILL.md` in `expects:` while its Notes assigned that same prose to `0075`
  ("whichever lands second implements against the other rather than restating it"). Both readings
  are internally consistent and the file plainly exists, so the grep Step 1 asks for cannot
  separate them; only reading the notes does. A `touches:` copied from `expects:` would have
  reserved — and rewritten — a paragraph a sibling ticket exists to rewrite (pointer:
  `skills/develop/SKILL.md` Step 1, items `0084`, `0075`).
- 2026-09-03 — **Asserting the *absence* of a word reds a correct implementation, and it is the
  mirror of the rule that sent me there.** `testing-conventions.md` says assert the message, never
  the status — so AC3's "nothing was pushed" case grepped for `[Pp]ushed` being absent. The correct
  refusal message ends "nothing has been committed or pushed", so the guard failed a passing
  script on its first green run. A negative assertion has to be anchored to a *state* (the step
  that did not run, `HEAD` unmoved), never to vocabulary, because correct prose is free to mention
  the thing it did not do. The positive rule is written down; this inverse is not (pointer:
  `tests/release.test.sh` AC3 comment, `../ai-building-conventions/testing-conventions.md`).
- 2026-09-03 — **`0085`'s own FR7 removed the turn that catches a second session starting mid-pass.**
  `verify` Step 7 now reads "the tree is either clean throughout or Step 2 already said so", which is
  what licenses issuing no git command at verdict time. Verifying `0085` falsified it: Step 2 saw a
  clean tree, and `0081` then dirtied six files including `skills/verify/SKILL.md` — inside this run's
  evidence set — while the pass was running. Followed literally the pass would have closed on a plain
  PASS. `CONCURRENCY.md`, *The working tree is shared too*, says that is the normal case here, so the
  saved turn and the advisory label are in direct tension and only one can be right (pointer:
  `skills/verify/SKILL.md` Steps 2 and 7, `docs/decisions/001-one-command-per-stage-boundary.md` FR6,
  item `0085`).
- 2026-09-03 — **A guard anchored to an alternation is only as strong as its weakest branch, and a
  percentage is a weak branch.** `0085` AC11 asserts `grep -qE '87%|0\.0983|0\.1132'` over the whole
  of `MEASUREMENT.md`; both per-turn dollar figures can be mutated to nonsense and the guard stays
  green on `87%` alone. Anchoring to a row rather than the document — the fix AC8–AC10 already got —
  does not help while the assertion is an OR over three tokens any one of which suffices. The
  question to ask of an alternation is which single branch keeps it green (pointer:
  `tests/cost-by-category.test.sh` AC11, `../ai-building-conventions/testing-conventions.md`).
- 2026-09-03 — **`0084`'s row and its item disagree: the queue says `develop | in-progress` under
  token `ae35`, the item says `next: verify`, `status: ready`, `claimed_by:` empty.** So `./next
  verify` does not offer it and `./next verify` *does* report its files as claimed — a ticket that is
  ready to QA and invisible to the stage that would take it. It looks like a hand-off that wrote the
  item and not the row, which is the defect `0081` exists to remove. Not written by this pass: not
  its ticket (pointer: `.claude/backlog/QUEUE.md`, item `0084`, item `0081`).
- 2026-09-03 — **`config.yml`'s `unit` command hides most of the suite the moment anything is red,
  and the ticket's own guard is what gets hidden.** The command is
  `for t in tests/*.test.sh; do "$t" || exit 1; done`, so the first red file ends the loop. Verifying
  `0084` at its declared `unit` level, `tests/backlog-scripts-installed.test.sh` failed on `0081`'s
  in-flight work — alphabetically first of seventeen — and the run stopped there, so
  `tests/release.test.sh`, the guard the verdict actually rests on, never executed. Running the files
  individually then showed sixteen green and one red. Fail-fast is right for a release gate, where
  `tools/release` step 5 uses the same line deliberately, and wrong for a QA pass, which needs the
  whole picture to attribute a red to a ticket. A verify session that trusted the level command's
  first failure would report BLOCKED or FAIL on someone else's red. The two uses want opposite
  behaviour from one config key (pointer: `.claude/backlog/config.yml` `commands.unit`,
  `tools/release` step 5, `skills/verify/SKILL.md` Step 2).
- 2026-09-03 — **The alphabetical accident above is load-bearing and will not repeat reliably.**
  `backlog-scripts-installed` sorts first, so it masked everything; had the red been `next.test.sh`
  the pass would have seen most of the suite and might never have noticed the truncation. The same
  run also showed the file passing 23/23 ninety seconds after failing, because `0081`'s session
  re-copied `close` from its template in between — so a level command that stops at the first red can
  report a different suite on two runs a minute apart, with no local change (pointer:
  `.claude/backlog/config.yml`, `references/CONCURRENCY.md`).
- 2026-09-03 — **`./close` clears `touches:` with a skiplist that a legal YAML list evades, so a
  closed ticket can go on reserving files.** YAML allows a block sequence at the *same* indentation
  as its key, so `touches:\n- src/a.ts` is valid; `close`'s `if (skiplist && $0 ~ /^[ \t]+-/)`
  requires leading whitespace and leaves those entries in the item. The row moves to `DONE.md` and
  the item still names two files, which `CONCURRENCY.md` (*The working tree is shared too*) obliges
  the other window to read as held — an invisible narrowing of what anyone else may take. Found by
  the mutation sweep on `./handoff`, which had copied the same line; fixed there (`^[ \t]*- `) and
  deliberately **not** fixed in `close`, whose contract and guard belong to another ticket
  (pointer: `skills/queue/templates/close`, `tests/close.test.sh`, `skills/queue/templates/handoff`).
- 2026-09-03 — **No backlog script is proven to hold the lock through its commit, and no ordinary
  assertion can prove it.** `CONCURRENCY.md` (*Lock every write to `QUEUE.md`*) requires the lock to
  cover the read, the write **and** the commit, but releasing it after the edit and before the commit
  leaves every observable identical: correct files, a landed commit, a released lock. Mutating the
  release earlier in `./handoff` kept its whole suite green until a `pre-commit` hook was added to the
  fixture to witness the lock at commit time — one hook, four lines. `claim.test.sh` and
  `close.test.sh` have the same blind spot on scripts whose commit-inside-the-lock is their entire
  reason for existing (pointer: `tests/handoff.test.sh` "the lock is still held at the moment the
  commit runs", `tests/claim.test.sh`, `tests/close.test.sh`).
- 2026-09-03 — **A guard placed before the guard it protects can make it unfalsifiable, and the
  sweep reads as coverage.** `./handoff` verifies all five frontmatter fields after editing — the
  whole point of the ticket — and an up-front presence check, added to improve one error message,
  caught every fixture first. Deleting the read-back entirely left the suite green: the
  filter-then-assert failure `testing-conventions.md` names, arriving from ordering rather than from
  the filter. The general shape: **when a cheap precondition check is added in front of an expensive
  verification, the verification's mutation coverage is silently transferred to it.** Reaching it
  needed a case that breaks the *implementation* in the copy the harness runs, not a case that feeds
  it bad input (pointer: `skills/queue/templates/handoff`, `tests/handoff.test.sh`).
- 2026-09-03 — **`develop` Step 5 and Step 7 prescribe an order the new hand-off rule forbids, and
  the step numbers are now wrong on purpose.** Step 5 hands the ticket off; Step 7 appends to
  `FINDINGS.md`. Neither `./handoff` nor `./close` commits that file, so the append cannot ride along
  in the boundary commit and must precede it — otherwise the claim is gone and the row is takeable
  while the session is still writing, which is the 29-second window the ticket exists to close. Both
  skills now say so at the findings step, but a numbered sequence whose numbers are not the order is
  a standing trip hazard, and `docs/decisions/001` budgets the findings append as its own turn
  without saying where it sits relative to the boundary (pointer: `skills/develop/SKILL.md` Steps 5
  and 7, `skills/verify/SKILL.md` Steps 5 and 6, `docs/decisions/001-one-command-per-stage-boundary.md`).
- 2026-09-03 — **Releasing a claim by hand has four fields and no script, and one session missed the
  same one twice.** `./claim` sets `status: in-progress` in both the row and the item; releasing means
  resetting both plus `claimed_by:` and `claimed_at:`. Two separate by-hand releases in one session
  cleared the token and the row but left the item at `in-progress` — the exact row/item drift this
  same session reported against `0084`, produced twice by the person reporting it. `claim` and `close`
  are scripted and `handoff` now is; the release-without-close path that an advisory verdict or a
  `waiting` outcome needs is the one still by hand (pointer: `.claude/backlog/claim`,
  `skills/verify/SKILL.md` Steps 5 and 7, items `0085`, `0081`).
