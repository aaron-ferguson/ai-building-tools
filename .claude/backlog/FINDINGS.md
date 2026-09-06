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
  — read and triaged 2026-09-05 by retro: belongs to item 0077, deferred, not yet written.

- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0049, deferred, not yet written.

- 2026-08-25 — **checking "the output is unchanged" needs the HEAD copy of a suite run from inside
  the repo, and nothing says so.** 0053's AC1 is a byte-comparison against today's output, so the
  obvious move is `git show HEAD:tests/x.test.sh > $SCRATCH/x.sh && sh $SCRATCH/x.sh`. Every suite
  resolves `ROOT` from its own location, so the scratch copy exits 2 with "no claim script at
  …/scratchpad/skills/…" — which is not a red, just a different error, and a session in a hurry
  reads it as one. The copy has to land inside the repo tree (`tests/.head-x.sh`, dot-prefixed so
  the `tests/*.test.sh` loop does not pick it up) and be removed in the same turn. Third session in
  a row to hand-build throwaway comparison scaffolding, which is the finding 0053 itself came from
  (pointer: skills/develop/SKILL.md Step 5, items/0053).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-30 — **`design` Step 4 tells an unclaimed ticket's session to write it and never says to
  claim it, and there is no release path once it has.** `CONCURRENCY.md` *A stage writes only the
  ticket it holds* says "claim the row you write", so settling 0074 meant claiming, writing,
  then clearing `claimed_by:` and the `in-progress` row by hand — `./close` is for closing and
  nothing reverses a claim. 0056 already has this step's missing lock (FR3) and `expects:`
  re-check (FR4) but not ownership, so the same edit should decide whether `design` claims at all
  and, if it does, what hands the row back (pointer: skills/design/SKILL.md Step 4, items/0056,
  items/0048, .claude/backlog/claim).
  — read and triaged 2026-09-05 by retro: belongs to item 0056, deferred, not yet written.

- 2026-08-30 — **Thinking is ~70.5% of a session's output tokens and its text is not retained in
  the transcript, so the largest output term cannot be measured from the record.** Stored
  `thinking` blocks carry an empty `thinking` field and a ~3,000-character `signature`, so 0074's
  measurement could only get it as a residual — output tokens minus estimated text and tool-input
  tokens. Human-facing narration was 4.6% and tool inputs 24.9% by comparison. This bounds what
  0073 can report and it is not obvious before you look: a turns-and-tokens breakdown that assumes
  the transcript holds what the model wrote will silently attribute 70% of output to nothing
  (pointer: items/0073, items/0074, tools/harvest-usage.sh, MEASUREMENT.md).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0049, deferred, not yet written.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0058, deferred, not yet written.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0063, deferred, not yet written.

- 2026-08-30 — **The release chain has no re-check step, and a sibling session closed a ticket in the
  middle of one.** A release audit found the install 14 files behind at the *same* version number,
  decided what to ship on the basis that 0042 and 0044 were both unverified, and was about to push
  when the user stopped it because another session had just finished — which had verified and closed
  0042, changing the premise the release decision rested on. `CONCURRENCY.md`'s *Re-read immediately
  before you write* is scoped to `QUEUE.md` rows, so nothing covers the longer read-decide-push gap,
  and the release chain in CLAUDE.md is a four-step sequence with no instruction to re-verify state
  before executing it. Every step is silent when skipped, including this missing one (pointer:
  CLAUDE.md *This project is the tool its sessions are running*, references/CONCURRENCY.md).
  — read and triaged 2026-09-05 by retro: belongs to item 0061, deferred, not yet written.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0052, deferred, not yet written.

- 2026-08-30 — **`verify` Step 3's mutation sweep needs the pre-change suite to compare against, and
  a suite's own `ROOT` resolution makes that awkward in a way each session rediscovers.** Checking
  0053's AC1 ("output unchanged") meant running the pre-0053 and post-0053 copies of three suites
  against today's tree. The obvious base — the commit before the implementation — was wrong, because
  two of the three suites had since been changed by *other* tickets (0044), so the diff showed 0044's
  cases as 0053's noise. The isolating comparison is pre-boundary vs post-boundary, both replayed
  against the current tree, and neither is the working copy. The item's notes record the ROOT gotcha
  (a copy must live inside the repo) but not the base-selection one, which cost the larger detour
  (pointer: items/0053 notes, verify SKILL.md Step 3).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0052, deferred, not yet written.

- 2026-08-30 — **The `set -e` short-circuit trap is recorded in the guard where it was found, so the
  next guard author hits it again.** Writing `[ "$n" -eq 0 ] && echo "FAIL …"` as a statement inside
  an audit function makes the function exit non-zero on the CLEAN path, which `set -e` turns into a
  truncated result for every caller — the guard reports a partial audit exactly when nothing is
  wrong. `tests/reference-size.test.sh` documents this inside one loop body; `tests/reporting.test.sh`
  hit it twice in fresh code before that note was found. Five shell guards now share the pattern and
  the warning lives in one of them (pointer: tests/reference-size.test.sh `offenders`,
  tests/reporting.test.sh `audit`).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-30 — **An acceptance criterion that globs the test directory lets another session rewrite
  its contract mid-verify.** 0044 AC9 is "given the whole suite, when `for t in tests/*.test.sh`
  runs, then every suite passes". During this pass 3895 created `tests/reporting.test.sh` as an
  untracked file, so the set AC9 quantifies over grew by one unfinished guard while the verdict was
  being formed. Nothing red — the run used a pinned clone — but the AC as written is satisfied
  against a moving target, and two sessions can hold contradictory true answers to it at the same
  moment. This is the same class as 0052's requirement that an AC name the input that would make it
  red: a glob names no input. The fix direction is either pinning such an AC to a commit or
  enumerating the suites it means (pointer: items/0044 AC9, items/0052, tests/).
  — read and triaged 2026-09-05 by retro: belongs to item 0052, deferred, not yet written.

- 2026-08-30 — **`./next verify`'s collision warning flagged the two rows that declared *nothing*,
  while the collision that actually cost the close came through a `touches:` that was declared
  properly.** The banner read "0053 [b673] none declared — assume held, ask" and the same for 0074;
  0053 turned out to share no path with 0044 at all, and 0074 — which had just committed a full
  `touches:` list naming `skills/verify/SKILL.md` — was the one that made the verdict advisory. The
  warning keys on absence of a declaration, which is the cheaper signal, and says nothing about a
  declared overlap with the row it is offering. That cross-check is exactly 0045, and this is a
  worked case for it: the useful output would have been "0044's evidence set meets 0074's declared
  touches at skills/verify/SKILL.md" (pointer: items/0045, .claude/backlog/next, items/0074).
  — read and triaged 2026-09-05 by retro: belongs to item 0045, deferred, not yet written.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0064, deferred, not yet written.

- 2026-08-30 — **`references/REPORTING.md` attributes the same requirement numbering to two different
  tickets, three sections apart.** Line 37 cites "0039 FR14" and line 57 cites "0036 FR13"; both FR13
  and FR14 are *defined* only in `items/0039`, which inherited 0036's numbering when 0036 was split
  into children. Neither citation is wrong on its own — 0036 references both numbers — but a reader
  chasing one of them learns the numbering is ticket-ambiguous, and 0074 AC7 pins the 0036 spelling
  while nothing pins the other. This is the citation-drift 0036's split created and is not specific to
  this file: any reference to an FR number in the 0036/0039 pair needs saying which ticket's list it
  means (pointer: references/REPORTING.md:37, references/REPORTING.md:57, items/0036, items/0039).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-30 [0045] `./next --drive` selects develop rows with `takeable_develop`, which skips
  `in-progress` rows but crosses nothing against their `touches:` — so a driver can dispatch a row
  that `./next develop` now refuses as COLLIDES. 0045's ACs all name `./next <stage>`, so this was
  left alone rather than widened mid-ticket. Worth a row, or 0039's to absorb.
  — read and triaged 2026-09-05 by retro: belongs to item 0045, deferred, not yet written.

- 2026-08-30 [0f0a] **`./next verify` correctly offered no row, and `verify` Step 1 has no branch
  for that.** The only `next: verify` row was 0053 and it collided with 0045's live `touches:`, so
  the script printed COLLIDES and "nothing here is safe to take" — the right answer, and not one of
  the cases Step 1 enumerates (a row for you, a row at another stage, no ticket at all). A session
  reading Step 1 literally has to invent whether to wait, take it anyway, or stop. It resolved
  itself here only because 0045 landed mid-session.
  — read and triaged 2026-09-05 by retro: belongs to item 0058, deferred, not yet written.

- 2026-08-30 [61a0] **`verify` Step 3 tells you to mutate the working tree, but on this repo the
  files under test are shared prose another live session predicts** — 0051's evidence set was
  `MEASUREMENT.md` and `README.md`, both in 0053's `expects:`. Mutating a scratch copy removes the
  window entirely, and it worked, but `git archive HEAD | tar -x` alone gives 55/1: the suite's
  tracked-file guards use `git ls-files` and fail loudly outside a repo. Correct behaviour, and a
  session could read that 1 as a real red. The copy needs a `git init` + commit first. Step 3 names
  only the in-tree route and its `git checkout -- <that path>` restore.
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-09-01 [becd] **Falsifiability at phrase level is blocked on a citation marker this repo has not
  decided on.** Resolving a cited *rule phrase* inside a conventions file needs to tell a citation from
  emphasis, and italics carry emphasis throughout: three existing spots (`skills/retro/SKILL.md` x2,
  `skills/verify/SKILL.md` x1) are emphasis directly after a conventions filename. 0052 resolved the
  filename and recorded the gap in the guard's header. The marker is a design question, and it is the
  same question `citations.test.sh`'s anchoring rule already answered for `CONCURRENCY.md` — so the
  precedent exists and only needs extending. Candidate ticket.
  — read and triaged 2026-09-05 by retro: belongs to item 0063, deferred, not yet written.

- 2026-09-02 [6983] **`design` Step 4 has no path for a decision whose deliverable is criteria on
  other people's tickets.** 0085's FR2 required routing removable turns to 0066, 0081, 0047 and
  0048; `CONCURRENCY.md`, *A stage writes only the ticket it holds*, forbids the settling session
  from writing any of them, and that rule says explicitly that naming them in your own notes is not
  filing them. The only legal move I could find was to hand the ticket to `queue` rather than to
  `develop` — but Step 4's three item-scoped outcomes are develop, waiting and hand-back-to-queue-
  because-it-is-claimed, and none of them is this. A design pass that routes work needs a stated
  fourth outcome, or the routing dies in a settled ticket's prose (pointer: `skills/design/SKILL.md`
  Step 4, item 0085).
  — read and triaged 2026-09-05 by retro: belongs to item 0056, deferred, not yet written.

- 2026-09-02 [6983] **A ticket opened by a `develop` session at `next: design` carries no *Open
  design question* section**, which is the section `design` Step 1 names as its contract. 0085 was
  opened by 0073 under its FR5 and put the question under a heading of its own invention ("Why this
  is `next: design` and not `develop`"). It was a better section than the template's — it argued why
  the question was not guessable — but Step 1 read against nothing, and a session following it
  literally would have stopped (pointer: `skills/develop/SKILL.md` Step 3, `templates/item.md`).
  — read and triaged 2026-09-05 by retro: belongs to item 0056, deferred, not yet written.

- 2026-09-01 — **`expects:` can name a path that never matched any file, and nothing catches it.**
  0085's `expects:` listed `.claude/backlog/items/0048-remaining-backlog-write-sites.md` and
  `.claude/backlog/items/0066-three-wrong-answers-in-the-scripts.md` — neither is the real filename
  (`0048-scripts-for-the-remaining-write-sites.md`, `0066-backlog-script-ergonomics.md`), so a
  session opening 0085 and trying to read its `expects:` verbatim gets "file does not exist" for
  both. `expects:` is triage, not protection, so this cost one failed read rather than anything
  worse, but a field whose whole job is pointing a later session at the right files is silently
  wrong the moment a title-guessed slug drifts from the real one (pointer: items/0085 `expects:`,
  items/0048, items/0066).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0061, deferred, not yet written.

- 2026-09-02 — **`RANKING.md` says "current state only" and is accumulating dated sections anyway.**
  Its header splits the standing argument from the narrative the way `CONCURRENCY.md` splits from
  `CONCURRENCY-INCIDENTS.md`, and two dated 2026-09-02 sections sit in it below the table, one of
  which had to be marked superseded the same day it was written. The count in *The shape of this
  backlog* — "twenty-six of the thirty-six rows" — is stale for the same reason: a file that mixes
  current state with history gets read as neither (pointer: `.claude/backlog/RANKING.md`,
  `.claude/backlog/RANKING-HISTORY.md`).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0052, deferred, not yet written.

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
  — read and triaged 2026-09-05 by retro: belongs to item 0066, deferred, not yet written.

- 2026-09-03 — **`0084`'s row and its item disagree: the queue says `develop | in-progress` under
  token `ae35`, the item says `next: verify`, `status: ready`, `claimed_by:` empty.** So `./next
  verify` does not offer it and `./next verify` *does* report its files as claimed — a ticket that is
  ready to QA and invisible to the stage that would take it. It looks like a hand-off that wrote the
  item and not the row, which is the defect `0081` exists to remove. Not written by this pass: not
  its ticket (pointer: `.claude/backlog/QUEUE.md`, item `0084`, item `0081`).
  — read and triaged 2026-09-05 by retro: belongs to item 0081, deferred, not yet written.

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

- 2026-09-03 — **`develop` Step 5 and Step 7 prescribe an order the new hand-off rule forbids, and
  the step numbers are now wrong on purpose.** Step 5 hands the ticket off; Step 7 appends to
  `FINDINGS.md`. Neither `./handoff` nor `./close` commits that file, so the append cannot ride along
  in the boundary commit and must precede it — otherwise the claim is gone and the row is takeable
  while the session is still writing, which is the 29-second window the ticket exists to close. Both
  skills now say so at the findings step, but a numbered sequence whose numbers are not the order is
  a standing trip hazard, and `docs/decisions/001` budgets the findings append as its own turn
  without saying where it sits relative to the boundary (pointer: `skills/develop/SKILL.md` Steps 5
  and 7, `skills/verify/SKILL.md` Steps 5 and 6, `docs/decisions/001-one-command-per-stage-boundary.md`).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-09-03 — **Releasing a claim by hand has four fields and no script, and one session missed the
  same one twice.** `./claim` sets `status: in-progress` in both the row and the item; releasing means
  resetting both plus `claimed_by:` and `claimed_at:`. Two separate by-hand releases in one session
  cleared the token and the row but left the item at `in-progress` — the exact row/item drift this
  same session reported against `0084`, produced twice by the person reporting it. `claim` and `close`
  are scripted and `handoff` now is; the release-without-close path that an advisory verdict or a
  `waiting` outcome needs is the one still by hand (pointer: `.claude/backlog/claim`,
  `skills/verify/SKILL.md` Steps 5 and 7, items `0085`, `0081`).
  — read and triaged 2026-09-05 by retro: belongs to item 0048, deferred, not yet written.

- 2026-09-05 — **All three backlog scripts commit without the `Co-Authored-By` trailer that
  `git-conventions.md` requires of every AI-assisted commit.** Found verifying `0081`, whose own NFR
  table names the trailer, so it is that ticket's red — but `claim` and `close` have the same gap and
  fixing only `handoff` leaves the three inconsistent. What is undecided is the scope: whether a
  script-generated bookkeeping commit counts as AI-assisted (it is made on a session's behalf, so this
  session read it as yes), or whether the convention should exempt them and the NFR row was the error
  (pointer: `skills/queue/templates/{claim,close,handoff}`, `git-conventions.md` *Co-authorship*,
  items `0081`, `0082`).

- 2026-09-05 — **The trailer scope question above is answered by `skills/develop/SKILL.md` Step 1**,
  which says a lifecycle commit is not exempt from `Co-Authored-By`, and by
  `references/CONCURRENCY.md` *The git index is shared*, which requires it of every AI-assisted
  commit. `handoff` now carries it; `claim` and `close` still do not, and **still need a row** — none
  exists. Worth recording for its own sake: the answer was already written down in two files the
  ticket cites, and both a build pass and a QA pass read the question as open. A "scope decision" that
  the repo's own prose already settles is cheaper to look up than to escalate (pointer:
  `skills/queue/templates/{claim,close}`, `git-conventions.md` *Co-authorship*, items `0081`, `0082`).

- 2026-09-05 — **`tests/citations.test.sh` reds on the shipped tree, and the red is the guard's own
  line-wrap blind spot, not a stale citation.** `skills/queue/templates/claim` cites *The working tree
  is shared too* across a line break inside a shell comment, so the guard reads the citation as
  `"The # working tree is shared too"` and reports a rule that does not exist. It predates this
  session (last touched by `3588524`, and nothing here edits that file). The fix is either stripping a
  leading `# ` when the citation continues onto the next comment line, or keeping such a citation on
  one line — the same rewrap hazard `CLAUDE.md` records for every prose guard, now hitting the guard
  rather than the guarded. This **needs a row**; none exists (pointer: `tests/citations.test.sh`,
  `skills/queue/templates/claim:22`).
  — read and triaged 2026-09-05 by retro: belongs to item 0063, deferred, not yet written.

- 2026-09-05 — **The citations red recorded above was introduced by `0082`'s own first commit and is
  now fixed, so it needs no row.** `3588524` is that commit, and the entry above reads it as
  pre-existing because `git log` on the file was the only evidence available to a session that did
  not hold the ticket — which is the correct read of that evidence and still the wrong answer. The
  wrap is unwrapped and `tests/citations.test.sh` is green. What survives as a real finding is the
  guard's blind spot itself: **a rule citation that wraps across a comment break cannot be matched
  and is reported as stale**, so the guard's failure mode on a *correct* citation is a false
  accusation rather than a miss. That half **still needs a row**; none exists (pointer:
  `tests/citations.test.sh`, `skills/queue/templates/claim`).
  — read and triaged 2026-09-05 by retro: belongs to item 0063, deferred, not yet written.

- 2026-09-05 — **A row claimed and then released records no reason, so the next session re-derives
  it.** `0086` was claimed by `f7c0` and handed straight back to `develop | ready` 58 seconds later
  (`bdf2cdc` → `6eba29c`), with no note in the item and nothing in the queue. This session then spent
  the same analysis reaching the same answer — its `expects:` overlaps `0081`'s live claim on
  `skills/develop/SKILL.md` and `skills/verify/SKILL.md`. `./handoff` takes a destination stage and
  no reason, and no step in `develop` requires one when it releases rather than completes, so a row
  put back untouched is indistinguishable from one never taken. This **still needs a row**; none
  exists (pointer: `.claude/backlog/handoff`, `skills/develop/SKILL.md` Step 5, item `0086`).

- 2026-09-05 — **`./claim` writes the row to `QUEUE.md` before it checks that the item file exists**,
  so a row whose item is missing or misnamed leaves `QUEUE.md` edited, uncommitted and unlocked — the
  same fail-open shape `0082` was written to close, on a third path `0082` does not name and so could
  not take. `claim:136` is the `mv`, `claim:140` the refusal. Cheap to fix (resolve the item above the
  row edit), and deliberately left: only the author may widen a contract. This **still needs a row**;
  none exists (pointer: `skills/queue/templates/claim`).

- 2026-09-05 — **`0082` replaced warn-and-carry in `claim`; `close` and `handoff` still have it,
  verbatim.** `close:62` and `handoff:103` both detect that their commit will carry another session's
  uncommitted rows, print a warning, and commit anyway. The argument FR3 makes for refusing is not
  specific to claiming: a pathspec limits a commit to paths and never to authorship, and all three
  scripts hold the lock when they decide. `0082`'s *Out of scope* covers only other files, not other
  scripts, so this is a sibling row rather than a widening. This **still needs a row**; none exists
  (pointer: `skills/queue/templates/{close,handoff}`, item `0082` FR3).

- 2026-09-05 — **`expects:` and `touches:` usually end with the same last entry, so a substring edit
  anchored on that entry silently writes the wrong block.** Widening this ticket's `touches:` with a
  match on `"  - tests/claim.test.sh\nclaimed_by:"` appended to `expects:` instead — `expects:` is the
  block that abuts `claimed_by:`, and both lists held the same three paths, so the anchor was unique
  and wrong. It committed cleanly and read correctly in isolation. Anchor a frontmatter list edit on
  the key that FOLLOWS the block (`---` for `touches:`), never on a shared entry (pointer:
  `skills/queue/templates/item.md`, `develop` Step 1).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-09-05 — **`retro` Step 4 takes the backlog lock for every write inside `.claude/backlog/`, and
  Step 6 tells the same session to append to `FINDINGS.md` without mentioning it.** Both steps are in
  one skill, the file is plainly inside the boundary Step 4 names, and the two disagree only by
  omission — so a session that follows Step 6 literally, after correctly locking in Step 4, appends
  unlocked and reads as having done the whole pass properly. This pass noticed only because it was
  holding the lock already and asked whether it could drop it before parking. `develop` Step 7 and
  `verify` Step 6 append to the same file and are worth checking for the same gap
  (pointer: `skills/retro/SKILL.md` Steps 4 and 6, `references/CONCURRENCY.md` *Lock every write*).
- 2026-09-05 — **Step 1's ranked-slice instruction has a marker for a deferral and none for "no
  destination exists".** Draining an 84-entry buffer at 10.5x the threshold, 40 entries resolved to an
  existing row and 15 did not — and for those 15 the skill's own advice ("*needs a row, none exists*
  is a useful marker and a wrong one is worse than none") is prose in Step 1 rather than a form, so
  the wording was invented here and the next retro will invent a different one. Both markers want to
  be greppable, because the count of each is what says whether retros are keeping up
  (pointer: `skills/retro/SKILL.md` Step 1, `.claude/backlog/FINDINGS.md`).
