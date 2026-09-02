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
