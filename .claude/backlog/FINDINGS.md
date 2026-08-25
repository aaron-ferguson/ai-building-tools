# Findings — parked, not yet placed

**One or two lines each, dated.** This is a buffer, not a second backlog: it
holds findings whose home is **not local and not yet decided** — a possible row, a suspected skill
or convention problem, a cost pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in
a comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a
row. Parking those is how a session ends with nothing written down *and* a growing file.

**Two sweepers empty this file, and they take different things.** `queue` takes the entries that
are **units of work** and specifies and ranks each one properly. `retro` takes the **lessons** and
lands them where they will be read again. **An entry that is both is taken by both** — classifying
at write time would put friction exactly where it is least wanted, at the moment of noticing, so
nothing here is tagged and neither sweeper waits for the other.

**Each sweeper removes only the entries it processed, and commits in the same turn.** Leaving a
processed entry is how the next sweep pays to read it again; removing an unprocessed one is how the
other sweeper's half disappears silently.

Every entry ends as a row, an edit, or a drop with a stated reason — so the normal state of this
file is empty. Entries older than about two weeks are dropped rather than processed: a finding
nobody acted on in two weeks was not worth acting on, and saying so is more honest than re-reading
it forever.

**If this file has grown, that is itself the finding** — retros are not running, or not emptying.

Format: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`

**The date goes outside the bold, and this is load-bearing.** Both sweepers find entries by line
shape, so an entry whose date sits inside the `**` is skipped by a sweep and nobody ever notices.
Two such entries once made `MEASUREMENT.md` publish 26 findings in one sentence and 28 two
paragraphs later, and a retro undercount its own buffer by exactly the same two. Readers match
`^- (\*\*)?20[0-9]{2}-` to stay tolerant of the drift; writers use the canonical form so they
do not add to it.

**Entry order is not guaranteed and nothing should depend on it.** Sessions have appended at both
ends — the dates in this file currently change direction nine times — so a sweeper reads to the
end rather than stopping at the first entry older than its window.

---

- 2026-08-25 — **`next.test.sh` prints only `ok`/`FAIL`, never the line the assertion saw, so a
  mutation sweep cannot tell why a case passed.** Verifying 0038 meant deleting each branch of
  `--drive`'s ladder and asking which cases red; where one stayed green the harness could not say
  what it had matched instead, and the only way to see it was to hand-build a fixture outside the
  suite and diff the real line against the mutant's. That scaffolding is invented per session and
  thrown away — the third session in a row on this ticket to pay for it. A harness that printed the
  captured output on demand (an env flag, or on `FAIL` plus a `--show` mode) would have turned a
  session of work into a read (pointer: tests/next.test.sh assert helpers ~line 222, items/0038).

- 2026-08-25 — **`design` Step 2 is written entirely for UI questions, but `next: design` also
  catches mechanism decisions, and then the step points at nothing.** Its three ordered lookups are
  prior art, the design system, and "the files the core's index names for design, UI and
  accessibility". 0007 is a concurrency-protocol question — does claiming write `QUEUE.md` — and
  followed literally, Step 2 sends the session to `design-conventions.md` and the `neumo-ds` MCP,
  neither of which has anything to say. What actually decided it was `migration-conventions.md`
  (*Expand, Migrate, Contract*) and the project's own `CONCURRENCY-INCIDENTS.md`. The step has a
  clause for "if the question touches user-facing UI" and none for the other case, so a
  non-UI design session either invents its own reading list or cites nothing. Cheap fix: make
  lookup 3 "the convention files this question turns on, per the core's index" and keep the design
  system as a *conditional* lookup rather than an ordered one (pointer: skills/design/SKILL.md
  Step 2).
- 2026-08-25 — **`design` Step 4 has no route for an answer whose consequence is a second ticket.**
  Its four cases are item-scoped-unclaimed (write it here), item-scoped-claimed (hand to `queue`),
  has-to-be-seen (`waiting`), and standing (a decision record). 0007's answer implied an
  expand/contract split, and the honest shape of that is arguably two rows — but minting an ID is a
  `queue` write against `config.yml`, and Step 4 neither authorises it nor names the handoff. It
  was resolvable here by keeping both phases in one ticket with an ordering FR, so nothing was lost;
  the gap is that the resolution was forced by the skill's silence rather than chosen. A fifth case
  — "the answer splits the work: write the FRs here, and say in the report that `queue` should
  consider a split" — would cost two lines (pointer: skills/design/SKILL.md Step 4).
- 2026-08-25 — **`develop` Step 5.4 tells a session to clear `touches:`, which is where Step 1 told
  it to record that `expects:` under-predicted.** Building 0038 turned up one file `expects:` had
  not named (`README.md`); Step 1 says to declare it in `touches:` and say inline that it is new,
  and Step 5.4 says to clear `touches:` on handoff — so following both deletes the only durable
  record that the prediction was short, which is the signal Step 1 says "the next capture calibrates
  on". Nothing in the skill says where it goes instead. This session moved the entry into `expects:`
  with a `# not predicted` comment; if that is right, Step 5.4 should say so, because the default
  reading loses it silently and no reader ever notices.

- 2026-08-25 — **a review-checklist fix can change documented behaviour, which re-enters the TDD
  cycle, and `develop` Step 5 puts the checklist after the tests are green with nothing said about
  that.** Step 5.1's checklist caught three things 134 green assertions could not on 0038: exit codes
  spelled at nine call sites, two functions nested three deep, and a flag that accepted a list while
  reading one element. The first two were pure refactors and stayed green; the third *changed the
  interface* (a second `--completed` is now a usage error) and therefore needed its own red-first
  test, written after the "confirm green" step had already passed. Worth one clause in Step 5 saying
  a checklist finding that changes behaviour goes back through red rather than shipping on the
  strength of the earlier green.

- 2026-08-25 — **`design` Step 4 moves a ticket's stage but never says to re-check `expects:`, and a
  decision can move the file scope entirely.** Settling 0035, the answer changed the work from
  editing `skills/prototype/SKILL.md` + `skills/develop/SKILL.md` to editing two files under
  `tests/` — a completely disjoint scope. Step 4 lists *Notes & decisions*, the FRs and ACs, the
  stage fields and the commit, and stops there, so a session that follows it literally hands
  `develop` an `expects:` describing the work the decision rejected. That is not cosmetic: the
  2026-08-25 finding below ("one claim on two shared prose files stalled the whole `develop`
  stage") records exactly that, and this decision's real scope collides with nothing.
  A design answer is exactly the event that can narrow a scope, and nothing asks for it
  (pointer: skills/design Step 4, items/0035
  `expects:`, references/CONCURRENCY.md *The working tree is shared too*).

- 2026-08-25 — **the batching rule's constraint and its rationale point in opposite directions, and a
  stage queue is a chain, so "shares a file scope" ends up licensing a sweep of the whole stage.** One
  session took all five `next: verify` rows in a single pass (`1a06c11`, one token per row — the
  individual claiming the skill does require). That is *licensed*: `verify` opens with "one gate per
  session, not one ticket per session", so this is a finding about the rule, not about that session.
  But check the batch against the constraint the rule actually states — "tickets that share a file
  scope or a parent slice". By the declared `touches:`, **no two of the five share a parent** (only
  0026 has one at all), and by exact file the batch is a *chain* rather than a set: 0032–0026 via
  `skills/develop/SKILL.md`, 0026–0029 via `skills/verify/SKILL.md`, 0029–0033 via
  `references/CONCURRENCY.md`, and **0031 attached only at directory level**
  (`skills/queue/templates/`), sharing no file with any of them. 0026 and 0033 share nothing; 0026
  and 0031 share nothing. So the constraint is satisfied pairwise and transitively but never
  set-wide — and because overlap chains, any starting row reaches the entire stage. The rationale
  pushes the same way instead of checking it: what is amortised is conventions + skill + suite
  startup, "paid once however many verdicts come out of it", which argues for the *largest* batch
  available. Constraint says small, rationale says big, nothing reconciles them, and `./next <stage>`
  — the only row-selection tool — selects by stage regardless. **The hazard the rule does not name is
  Step 3**, which requires deliberately breaking each AC's guard to prove it can go red: in a batch
  those mutations land in the working tree the other four tickets' passes share, with no ordering or
  isolation rule given, so a suite run for ticket B while ticket A's mutation is live reads as B's
  red. 0026's notes already record the *inter*-session form of exactly this — "a full-suite run taken
  while another window is mid-edit is a verdict about a tree that never existed as a commit" — and
  settle on a throwaway worktree as the remedy; a batch reproduces it *intra*-session, where there is
  no other window and that note does not reach (pointer: skills/verify "One gate per invocation, not
  one ticket", commit 1a06c11, items/0026 *Redacted 2026-08-24*, references/CONCURRENCY.md *The
  working tree is shared too*).

- 2026-08-25 — **`verify` Step 1 has no outcome for "every row at my stage is already held", and
  batching makes that a designed-for case rather than a rare one.** `./next verify` offered
  `TAKE 0026`; about ninety seconds later all five `next: verify` rows were held by a single batched
  pass that minted one token per row (`1a06c11`, five tokens in one commit subject). Nothing was at
  risk: `./next` degraded well, printing `nothing is takeable at stage verify` above the CLAIMED
  FILES block, and `./claim` re-reads under the lock and refuses an `in-progress` row. But Step 1
  reads as though a row is always waiting — it covers refusing a row at the *wrong stage*, and
  having *no backlog at all*, and this is neither. Stopping and reporting is the only correct move
  and it is inferred, not written. Distinct from the 2026-08-24 `develop` entry at the foot of this
  file, which is the *race* between offer and claim; this is the *empty stage* a correctly-batched
  neighbour produces by design, and the harder the suite pushes batching the more often a second
  verify session opens onto nothing (pointer: skills/verify Step 1, .claude/backlog/next,
  references/CONCURRENCY.md *A stage writes only the ticket it holds*).

- 2026-08-24 — **a `/design` pass confirmed its load-bearing flags by running them, and that is not
  the same as reading what they do.** 0036's design decision rested on `claude -p --bare` and cited
  `--bare`'s docs for "skills still resolve via `/skill-name`" — true, and the same paragraph also
  skips **CLAUDE.md auto-discovery** and refuses OAuth. So the settled mechanism was a stage session
  building with no conventions loaded, on a second billing path, and it would have passed every test
  in `tests/` because nothing greps a subprocess's context. The pass's own *"no prototype is needed —
  every input was a checkable fact and was checked"* paragraph is what made it invisible. Possible
  rule for `design`: a fact taken from a tool's own help text is quoted whole, not summarised to the
  clause you needed (pointer: 0036 *Review amendment*).

- 2026-08-24 — **an acceptance criterion can be structurally unable to fail, and nothing in the suite
  looks for that.** 0036's AC13 read "the last cycle's cost is within the stated tolerance of the
  first" — with ~800 tokens of per-cycle growth against a ~20k per-turn floor, no tolerance anyone
  would write could catch a regression, so the criterion was a green light dressed as a measurement.
  It survived a `queue` pass and a `design` pass. `verify` checks whether an AC is *met*; nothing
  checks whether it *could have failed*. Possible one-line rule in `queue`'s AC step, or a `verify`
  question: for each AC, name the input that would make it red (pointer: 0036 AC13).

- 2026-08-24 — **a verify verdict that quotes the string it is failing the ticket for re-publishes
  it, and the fix then reads as complete while the repo is still dirty.** 0026 failed on its privacy
  NFR for two transcript-store slugs at named lines; explaining the failure quoted both again, so the
  leak was four occurrences and the two the verdict itself added were in the section a reader trusts
  most. Redacting only the lines it named would have left the repo failing its own guard. `verify`
  should say it: describe a leaked value, never quote it — "one for this repository, one for the
  parent workspace" identified the defect exactly as precisely. Possible one-line rule in the verify
  skill's verdict step.

- 2026-08-24 — **`develop` Step 5 has no answer for a full-suite run taken while another session has
  the shared tree dirty, and its "whose red is it" fork silently assumes the other window's work is
  committed.** Two runners red in one loop and green on three immediate re-runs; the cause was
  neither mine nor flake but ~30 files mid-rename in the shared working tree. Step 5's fork —
  falsified versus exposed, settled by a worktree at the commit before mine — cannot classify a red
  whose cause is uncommitted and someone else's, and the repeat-both-sides advice for a re-rolling
  check points at the wrong diagnosis here. What worked: `git status` first, then the suite in a
  worktree at *my last commit*, which is a verdict about a tree that actually exists. The skill
  could say to check the tree is clean before believing any full-suite result.

- 2026-08-23 — **a vocabulary rename has no shape the backlog can hold.** Renaming the container
  ticket type effort→project touched 27 files across `QUEUE.md`, the item template, two skills, three
  test suites and 21 closed tickets. No `touches:` list can usefully declare that, no single ticket
  owns it, and `claim` protects one row at a time — so a cross-cutting rename is invisible to every
  concurrency mechanism the repo has, which is how it reddened `0005`'s held guard mid-pass. Either
  such a change needs its own convention (announce, land in one commit, re-run the whole suite) or
  the repo should accept that vocabulary is changed only when nothing is claimed (pointer:
  references/CONCURRENCY.md, items/0001 *Notes & decisions* 2026-08-23).
- 2026-08-24 — **every guard in this repo greps prose, and prose wraps — so a phrase that straddles
  a line break cannot be asserted at all.** Writing 0005's guard, `never its dependents` red against
  a template that plainly contained it: the sentence wrapped, so the phrase existed only as
  `never its` + `# dependents` on two lines and `grep` is line-based. The red is indistinguishable
  from a missing rule, and the tempting fix is loosening the assertion to a shorter fragment —
  which is exactly how these checks go vacuous. This project has no other kind of test: ten suites,
  all of them fixed-string greps over markdown that a later editor will rewrap for width. Nothing in
  the tests, the skills or `testing-conventions.md` warns that assertion phrases must fit one source
  line, or that rewrapping a paragraph is a breaking change to whatever asserts on it. Candidates: a
  helper that unwraps comment blocks before matching, or a stated rule that guarded sentences are not
  rewrapped (pointer: tests/graph-fields.test.sh `in_block`, skills/queue/templates/item.md
  `blocked_by:` comment, items/0005 *Notes & decisions*).

- 2026-08-24 — **a ticket's own prose is outside every guard the ticket writes.** 0026's privacy NFR
  forbade publishing paths outside the repo. Its test asserts the harvest *output* and the *record*
  stay clean, and both do — the two store slugs that breached it sat in the ticket's own Problem
  section, which no AC and no test reads. A privacy NFR wants one `git grep` assertion over the whole
  change, not one over the deliverable.

- 2026-08-24 — **an absence assertion built on an estimated wrong answer is unreachable.**
  `tests/measurement.test.sh` names `163.25` as the per-line total that would prove the message-id
  dedup gone; removing the dedup two different ways produces `165.25`. The guard still reddens, via
  the generic branch, but the message that would have named the cause can never fire. Compute the
  wrong answer from the fixture rather than by hand.

- 2026-08-24 — **`/verify` in this repo resolves to the bundled verify skill, not
  `ai-building-tools:verify`.** The session that verified 0026 loaded the built-in evidence-capture
  skill; this repo's stage protocol had to be read out of `skills/verify/SKILL.md` by hand. A stage
  whose name collides with a built-in is a stage that can silently not run.

- 2026-08-24 — **`./claim --help` and `./close --help` treat the flag as a ticket id.** `./claim
  --help` answers `no row for --help in QUEUE.md`. `./next --help` works and documents every mode, so
  the inconsistency reads as "this script has no help" rather than "you passed a bad id", and the
  scripts are the interface the skills tell every session to use. (pointer: `.claude/backlog/claim`,
  `.claude/backlog/close`)

- 2026-08-24 — **`develop` Step 5 tells a session to run the whole suite, but nothing tells it the
  suite may be measuring a moving target.** 0026's harvest reads a live transcript store, and the
  session count moved 30 -> 31 mid-run because another window opened a session. Any ticket whose
  output is a measurement of the machine it runs on needs its snapshot pinned and recorded, and no
  skill step says so (pointer: skills/develop/SKILL.md Step 5, tools/harvest-usage.sh, items/0026).
- 2026-08-24 — **A ticket's QA plan can contradict a guard another ticket already shipped.** 0026's
  plan asserted `grep -c 0026` is zero in develop's SKILL.md; `tests/batching.test.sh` (0025) asserts
  `0026` is *present* in the same paragraph. Both are satisfiable at once only because the QA plan
  qualified itself with "for the pending-placeholder sentences" — an unqualified one would have
  forced a session to edit another ticket's guard to close its own. Worth a `queue` check that a new
  QA plan's absence assertions do not collide with a shipped guard (pointer: items/0026 QA plan,
  tests/batching.test.sh).
- 2026-08-24 — **`develop` Step 5's red-triage is written for tests and has no advice for a figure
  that will not reconcile.** The published $15.11 baseline could not be reproduced from its own
  transcript (78% of published, by every variant tried). The falsified/exposed distinction the step
  offers does not apply, and what saved the ticket was the FR having been written with an explicit
  "or say you could not" fallback. That fallback is a ticket-writing habit worth naming somewhere
  (pointer: skills/develop/SKILL.md Step 5, items/0026 FR2, MEASUREMENT.md).

- 2026-08-24 — **`queue` has no procedure for splitting a ticket, and splitting is neither of its two
  no-new-ID cases.** Step 1 offers *re-specify* (a bounce-back at `next: queue`, keeps its rank, skips
  Step 3) and *amend* (a new FR on an unclaimed ticket, re-check size/ACs/scope). Narrowing a ticket
  and moving the removed scope to a new one is **both at once**: an amend on the original with no ID
  claim and its rank kept, plus a full Step 2 + Step 3 Add for the remainder — and the two halves have
  opposite rules about the ID claim and the rank. Composed by hand for 0026 → 0037; the risk in
  getting it wrong is re-ranking the original, which is the thing both existing cases are careful not
  to do (pointer: skills/queue/SKILL.md Step 1 table, items/0026, items/0037).
- 2026-08-24 — **A non-takeable row 1 reads as an instruction, and bare `./next` is what makes it
  read that way.** 0026 sat at row 1 as `waiting` for a day and was read as "the next thing to do" —
  the user asked why we would run that test now. The rank was correct (a waiting ticket keeps its
  rank, deliberately) and `./next develop` correctly stepped over it, but bare `./next` prints
  `ROW 1: … | waiting` with no indication that nothing can take it, right beside the counts. It cost
  a session to explain rather than a script to answer. Candidate: have bare `./next` print the
  topmost *takeable* row alongside row 1 when they differ, which is the question a reader is actually
  asking (pointer: .claude/backlog/next, QUEUE.md's *a blocked or waiting ticket keeps its rank*,
  RANKING.md 2026-08-24 section).

- 2026-08-24 — **`claim`'s success message is stage-blind: it tells every claimant to set `touches:`,
  which is `develop`'s field.** A `verify` claim holds no `touches:` — it reads and runs, it does not
  open a file scope — but the script prints "now set touches: ... before you open anything" regardless.
  The consequence is not cosmetic: `./next` then reports the row to every other session as
  `0027 [b8d3] none declared — assume held, ask`, so a correct `verify` claim is indistinguishable from
  an under-specified `develop` one, and CONCURRENCY's *read an empty `touches:` as held* makes that the
  safe-but-wrong reading (pointer: .claude/backlog/claim success path, references/CONCURRENCY.md
  *The working tree is shared too*, items/0027 AC5).

- 2026-08-24 — **`verify` has no correct answer for exercising a write-script when another session
  holds the backlog.** 0027 AC5 asks for a live `./claim` on "a scratch row", which means inserting and
  then removing a row in the shared `QUEUE.md` — while a `develop` session was mid-ticket on 0028 in the
  same table. Neither Step 2 (which forbids tidying another session's tree) nor Step 5 covers the case.
  Resolved by cloning the repo to the scratchpad and exercising `claim` and `close` there, which tests
  the same bytes without touching a live table; the skill should either name that as the method or AC5s
  should stop asking for a live row (pointer: skills/verify Step 2/Step 3, items/0027 AC5).

- 2026-08-24 — **the templates↔copies identity now has a permanent guard; repo↔installed-plugin
  identity still has none.** 0027 added `tests/backlog-scripts-installed.test.sh` so a drifted copy
  fails a suite run. The same failure one level up is unreported: the installed plugin at
  `~/.claude/plugins/cache/.../0.9.3/` is behind this repo by two merged tickets (0030's
  `notion`→`external_feedback` rename and 0027's own Step 0 edit), so the sessions running these skills
  are executing prose the repo no longer contains, and nothing points at it. `SOURCE` explains why the
  cache is disposable but gates nothing (pointer: SOURCE, skills/verify Step 2 *check which copy*).

- 2026-08-24 — **dates in the backlog have no stated timezone, and this file's stated order is not the
  order it is in.** `claimed_at:` is specified as ISO-8601 UTC but `created:` and these entries are bare
  dates: at 2026-08-23 local / 2026-08-24 UTC, two sessions working the same hour wrote different dates,
  and both are defensible. Separately, the header here says "newest at the top" while every entry so far
  was appended at the bottom — which matters because `retro` Step 1 expires "anything older than about
  two weeks" and reads the file in order (pointer: skills/queue/templates/item.md `created:`, this
  file's header, skills/retro Step 1).
- 2026-08-23 — **the installed plugin and the source tree can differ at the same version number, and
  nothing says so.** `0.9.2`'s installed `prototype/SKILL.md` is 26,262 bytes; source is 23,394 — the
  pre-0021 copy, so that trim was committed and never released. The installed `references/` is also
  missing `NOTION.md`. A session therefore resolves skills from a copy it cannot date, and `retro`'s
  Step 3 trap ("you may be running an older copy") has no check behind it: comparing the two needs the
  source checkout, which most sessions do not have. Bumping the version on a skill edit is already the
  rule; what is missing is anything that *fails* when the install and the source disagree, or any
  version marker a session can read from the installed side alone (pointer: SOURCE, skills/retro
  Step 5, .claude-plugin/plugin.json).
- 2026-08-24 — **removing a preference from the base suite leaves a follow-up nothing owns.** 0030
  took Notion out of the base tool suite and documented the `external_feedback:` extension point a
  profile plugs into, but *wiring Aaron's own solo projects back up* is named in that ticket's *Out
  of scope* and therefore has no ticket at all. Any solo project with `notion.enabled: true` in a
  live `config.yml` now has a stated wiring path and no one carrying it out. The general shape is
  worth a rule: a ticket that moves a preference behind a profile creates a second, smaller ticket
  by construction — the port — and *Out of scope* is where it silently goes to die
  (pointer: items/0030, references/EXTERNAL-FEEDBACK.md "If you had `notion:` configured").
- 2026-08-24 — **the base suite has no home for a solo profile, only a company one.**
  `CONVENTIONS_CORE.md` resolves preferences through `companies/<name>/`, and the conventions repo is
  public, so a *solo* preference (which feedback product, which personal tooling) has nowhere to live
  that is both private and discoverable. 0030 hit this deciding where `NOTION.md` should move to and
  could only answer "not here"; it deleted the file and pointed at git history instead. Every future
  "move X behind a profile" ticket hits the same wall (pointer: items/0030 FR4, CONVENTIONS_CORE.md
  "Profiles & How Overrides Work").
- 2026-08-24 — **"never rewrite `QUEUE.md` by hand" needs to name stream editors, not just `Write`.**
  Closing 0030 without the scripts, a stray `perl -i -ne` invocation left in the script with an
  unset variable expanded its match to `"\n"` and deleted **every blank line in the file** — the row
  removal itself was correct, so the commit's diffstat (14 deletions for a one-row close) was the
  only signal. `Edit`'s uniqueness check cannot produce this class of damage; an in-place regex over
  the whole file can, and the rule as written reads as being about `Write` and read-rebuild-write.
  Repaired in the next commit. This is the strongest argument yet for 0027 (pointer:
  references/CONCURRENCY.md *Never rewrite `QUEUE.md` by hand*, items/0027, commits 7d5ce6f/1850ef2).
- 2026-08-24 — **`develop`'s "say inline that it is new" instruction poisons the reader it installs.**
  Step 1 says to declare a file you will create in `touches:` and mark it new inline. `fm_list` in
  `next` and `claim` does not strip YAML `#` comments (0031), so an inline comment there is emitted
  verbatim in `./next`'s CLAIMED FILES block as though it were a path. The two instructions are
  individually right and jointly wrong, and nothing in either flags the other. Either the skill says
  where the "it is new" note goes instead, or 0031 lands first (pointer: skills/develop Step 1,
  items/0031).
- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
- 2026-08-24 — **`develop` Step 1 tells a session to run `./next develop`, and the run leaves the
  Bash tool's working directory inside `.claude/backlog/`** for the rest of the session, because the
  natural way to reach the scripts is `cd .claude/backlog && ./next`. Every later repo-root path then
  fails with `no such file or directory` — including `.claude/backlog/claim`, which reads as the
  script being absent rather than the cwd having moved. Two calls were lost to it here. The step
  could show the invocation from the repo root (pointer: skills/develop Step 1).
- 2026-08-24 — **`develop` Step 5's mutation rule is stated for the *result* but not for the
  *mutation's own validity*, and the cheap mutation is the invalid one.** Deleting a `case` branch
  from a `sh` guard to prove it can fail left a dangling `echo` and red on a syntax error — a red
  that looks like the guard biting. `testing-conventions.md` names this ("a malformed one reds for
  the wrong reason"); the skill cites the diff-the-mutation half but not the read-the-red half, and
  the diff was non-empty in both the valid and the invalid attempt, so the diff alone does not
  separate them (pointer: skills/develop Step 5, testing-conventions.md *Prove a new guard fails*,
  items/0028 develop-pass notes).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
- 2026-08-23 — **`design` writes `QUEUE.md` but never mentions the lock.** Step 4 tells a session
  holding an unclaimed ticket to set `next: develop` / `status: ready` and "commit by pathspec in
  the same turn" — that row edit is a `QUEUE.md` write, and `CONCURRENCY.md` says every write to it
  is locked, "every write, no exemptions". `verify` Step 5 and `develop` both spell the lock out;
  `design` is the one writing stage whose instructions omit it, so a session that has not
  independently read `CONCURRENCY.md` writes the row unlocked and nothing tells it otherwise.
  Settling 0034 this session, the lock was taken only because that file had been read for the
  decision itself (pointer: skills/design Step 4, references/CONCURRENCY.md *Lock every write to
  `QUEUE.md`*).
- 2026-08-23 — **a ticket's `## Out of scope` can foreclose the only answer to its own `## Open
  design question`, and `design` has no procedure for it.** 0034 asked whether an advisory PASS
  closes or banks a verdict, while its out-of-scope line said "Step 2's trigger is not in question"
  — but no answer to the question exists without moving where the advisory label is decided, so the
  contract Step 1 says to answer and the fence Step 3 must respect disagreed. The skill says answer
  *that* question and not a broader one, which reads as "obey the fence"; taken literally it makes
  the ticket unanswerable. Resolved here by narrowing the out-of-scope line in the same edit and
  saying so explicitly, but that move is invented rather than instructed — `design` should say
  whether a design answer may narrow a scope line written at queue time, and how to record it
  (pointer: skills/design Steps 1 and 3, items/0034 *Out of scope*).
- 2026-08-24 — **`verify` Step 3 tells you to mutate files the ticket does not hold, and
  `CONCURRENCY.md` forbids exactly that.** Step 3 requires breaking the check behind each AC and
  confirming it reds. 0005's AC4 asserts on `README.md`, which is not in 0005's `touches:` — so
  proving that AC meant editing and `git checkout --`-ing a file another live session (`ebff`)
  listed in its `expects:`. No work was lost here, but only by luck of timing. The two rules give
  no way to satisfy both, and the cheap fix is a rule: an AC that asserts on a file outside the
  ticket's scope must have that file added to `touches:` before the mutation, or be verified by
  direct observation instead of by mutation (pointer: skills/verify Step 3, references/CONCURRENCY.md
  *A stage writes only the ticket it holds*, items/0005 AC4).
- 2026-08-24 — **a committed `touches:` did not stop another session writing the file.** 0005
  declared and committed `tests/graph-fields.test.sh` in `touches:` at the start of the verify pass;
  forty minutes later session `ebff` rewrote that same file as part of an effort→project rename,
  turning the held ticket's own guard red against a contract the ticket never agreed to. `touches:`
  is advisory by design, but nothing warns either side, and the collision only surfaced because the
  verifier happened to re-run the suite at the end. A verify pass that had closed on its earlier
  green would have ticked ACs against a file set that no longer existed (pointer:
  references/CONCURRENCY.md *The working tree is shared too*, items/0005).
- 2026-08-24 — **a ticket was handed to `verify` with part of its own work uncommitted.** `0026` was
  set to `next: verify` by `e604703`, but the tail of the effort→project rename it depends on —
  two words in `MEASUREMENT.md`, the file that ticket is *about* — is still sitting in the working
  tree. The next `verify` session opens on a dirty tree on the one file its assertions read, which
  by Step 2 makes its verdict advisory before it has run anything, and puts an uncommitted change
  one careless `git add` away from landing under someone else's message. Handing a ticket on is the
  moment to check `git status --porcelain` is clean of your own paths, and no stage says so
  (pointer: skills/develop Step 5, skills/verify Step 2, MEASUREMENT.md).
- 2026-08-24 — **a template fix is two files, and nothing at claim time says so.** 0029's `expects:`
  named `skills/queue/templates/close`; 0027 also instantiated that script into this repo's own
  `.claude/backlog/close`, and `tests/backlog-scripts-installed.test.sh` asserts the copy is
  byte-identical. Fixing the template alone turns the suite red in a file the ticket never named,
  and only a `develop` session that happens to read that suite's header learns this before Step 5.
  Every ticket touching `skills/queue/templates/*` has the same hidden second path — a `touches:`
  rule, or a step in the size-and-scope check, would catch it once instead of per ticket (pointer:
  tests/backlog-scripts-installed.test.sh, skills/queue/templates/, develop Step 1 `touches:`).
- 2026-08-24 — **the green-tree gate has no wording for a concurrent session's red-first TDD.**
  develop Step 5 says run the whole suite and never hand a red tree to QA. Another window was
  mid-TDD on 0031 with its failing tests written and its implementation not yet, so
  `tests/next.test.sh` was *correctly* red and could not be made green by anyone but them. Step 5's
  attribution procedure resolves it (throwaway worktree, red is theirs, report it) — but the gate
  reads as a blocker until you get there, and what the next `verify` session needs is the proof
  carried into the handoff, not just the sentence "not mine". Worth a named case: a red the tree is
  *supposed* to have right now (pointer: skills/develop Step 5, skills/verify Step 2, items/0029
  notes).
- 2026-08-24 — **"diff the mutation before believing either colour" silently gives you nothing when
  the implementation is not committed yet.** `testing-conventions.md` says to confirm a mutation
  landed by diffing the file, and the reflex is `git diff -- <path>`. On the TDD path that diff is
  against HEAD, which still holds the *pre-fix* code, so the mutated line never existed there and the
  grep for it comes back empty — an empty diff that looks exactly like a mutation that failed to
  apply, on a run that was in fact correctly red. It happened here and cost a second pass. The fix is
  cheap and worth naming in the rule: copy the file aside before mutating and `diff` against that
  copy, never against HEAD, whenever the code under mutation is uncommitted (pointer:
  ai-building-conventions/testing-conventions.md "Prove a new guard fails", skills/develop Step 5).
- 2026-08-24 — **A row can be claimed between `./next develop` printing it and you claiming it, and
  `develop` Step 1 has no line for that case.** `./next develop` offered `TAKE 0032`; by the time I
  had read `items/0032-*.md` and started restating its contract, another session held it
  (`claimed_by: "5864"`, committed). Nothing broke — `./claim` re-reads the row under the lock, which
  is exactly *Re-read immediately before you write* doing its job — but I only noticed because the
  harness happened to send a "QUEUE.md changed on disk" reminder. Without that I would have spent
  Step 2 restating the contract for a ticket I did not hold, and discovered it at `./claim`. Step 1
  reads as though the row `./next` prints is still there when you get to it; the ordering it should
  state is **claim first, read the item file second** — the claim is two seconds and the item file is
  the expensive read. Two sessions were live on this backlog at once when it happened, which is the
  condition `CONCURRENCY.md` is written for, not an unusual one (pointer: skills/develop Step 1
  "Select and claim the item", references/CONCURRENCY.md *Re-read immediately before you write*).

- 2026-08-25 — **0032's own AC5 prescribes a mutation that passes under both the bug and the fix, so
  following it literally proves nothing — on the one ticket whose whole subject is adjacent
  measurement.** AC5 reads "given a phrase the suite asserts is absent, when that phrase is added to
  the paragraph *following* the batching paragraph, then the suite still passes — proving the window no
  longer reaches it." It does not prove that. Adding a phrase to the next paragraph leaves every
  `present` assertion satisfied by the real paragraph, so the suite is green with the 15-line window
  *and* with the blank-line window; and the only `absent` assertion in the suite is scoped to `$DEV`,
  the whole file, where the window is irrelevant by construction. The item's notes record doing
  exactly this (sentinel `parent slice 2026-08-22 0026 expects:` appended to the following paragraph,
  "still green (AC5), which is the regression the ticket exists for") — a green that was never
  reachable as a red. The discriminating mutation is to **move** a pinned phrase out of the batching
  paragraph into the next one: verified here, the old window reports `ok   the shared-slice half of
  the test, in the paragraph` for a phrase no longer in that paragraph, while the blank-line window
  reds. Stated as a rule: **a window-scoping guard is proved by moving the pinned string across the
  boundary, never by adding a string on the far side of it** — addition tests reachability of the
  assertion, movement tests the boundary. The fix shipped in 0032 is correct and this changes none of
  its results; what is wrong is the recipe an AC hands the next verifier (pointer: items/0032 AC5 and
  its *Notes & decisions*, tests/batching.test.sh:60, ai-building-conventions/testing-conventions.md
  "a guard that is wired and still cannot fail").
- 2026-08-25 — **a ticket's FRs enumerate what to add; a required *deletion* can live only in an AC,
  and *Out of scope* can read as though it forbids it.** 0034's five FRs describe the new derived
  rule and none says `verify` Step 2 must stop applying the advisory label — only AC2 ("no other
  trigger for the label remains anywhere in the file") requires that bullet to change. Worse, *Out of
  scope* opens "Changing what Step 2 *does*" and lists three things it keeps doing, which on a first
  read looks like Step 2 is untouched; the paragraph does go on to say the label moves, but a session
  working FR-by-FR per develop Step 4 reaches the ACs only after implementing, and the diff it would
  have written leaves two triggers in the file and fails QA. Rule to draw: **when a change relocates
  a decision, one FR should name the site it is relocated *from*, not only the site it moves to** —
  an addition-only FR list cannot express a move, and the AC that catches it fires after the work is
  done (pointer: items/0034 FR2 and its *Out of scope*, skills/verify Step 2, skills/develop Step 2).
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
- 2026-08-25 — **`queue` has no step and no template for turning a task into a project, which is one
  of the four things its own Step 1 table routes to it.** Slicing 0036, the operations table sends a
  row at `next: queue` to *re-specify*, whose instructions assume the output is still a task that
  keeps its rank — and `templates/item.md` describes a project only as a clause inside the `status:`
  comment ("a container ticket is `active` … its `next:` stays empty"). There is no template for the
  Outcome / Why `ships:` / Slices / Cross-cutting commitments shape, no statement that the FRs and ACs
  **move** rather than copy, and no statement that the parent's row leaves `QUEUE.md`. All of it was
  reconstructed by reading 0009 and 0002. `develop` and `verify` both refuse a project by stage, and
  0036's FR8 table already routes "ticket becomes a project; row leaves `QUEUE.md`" as a real
  transition — so the shape is load-bearing in three places and specified in none. Rule to draw: the
  conversion is its own operation with its own template, and the two facts a reconstruction is most
  likely to get wrong are **move, do not copy** and **do not renumber** (pointer: skills/queue
  SKILL.md Step 1 table and Step 2, templates/item.md `status:` comment, items/0009 and items/0002).
- 2026-08-25 — **`verify`'s batching rule licenses a batch by file scope or parent slice, and its own
  reason licenses a wider one.** The rule reads "tickets that share a file scope or a parent slice
  are checked in one session", justified by the conventions, the skill and the suite's startup being
  "a shared cost paid once however many verdicts come out of it". 0034 (`skills/verify/SKILL.md`,
  `references/CONCURRENCY.md`) and 0035 (`tests/*.test.sh`) share neither scope nor parent, yet the
  stated reason applies to them in full — the startup is paid once either way. So the enumerated
  condition is narrower than the rationale it is derived from, and a session reading it literally
  splits two `next: verify` rows across two sessions to no benefit. Taken as one gate here, each
  closed on its own ACs. Worth deciding whether the condition is meant to be the gate itself
  (any rows at `next: verify`) with scope-sharing merely the common case (pointer: skills/verify
  SKILL.md preamble, *One gate per invocation, not one ticket*).
- 2026-08-25 — **a ticket that edits a template silently owns its installed copy, and no `expects:`
  ever says so.** `tests/backlog-scripts-installed.test.sh` AC2 requires `.claude/backlog/{next,claim,
  close}` to be byte-identical to `skills/queue/templates/`, fixed one-way (template → copy). So any
  ticket touching one of those three templates also owns a second file, or the suite goes red at Step
  5 in a file the ticket never named. 0007's `expects:` named both templates and neither copy; the
  session found it only by reading the suite before claiming. This is not 0007-specific — it applies
  to every future ticket touching the three scripts, and the coupling lives in a test file that
  `queue` has no reason to open at capture time. Either `expects:` should be derived through that
  coupling, or the templates should carry a pointer to it (pointer:
  tests/backlog-scripts-installed.test.sh, skills/queue Step 0, items/0007).
- 2026-08-25 — **an AC that asserts a *count* of things in a shared reference file goes stale
  silently whenever any sibling adds one.** 0007 AC2 reads "names exactly one operation that takes
  the lock", written 2026-08-18 when `CONCURRENCY.md` listed two. 0023 added a third on 2026-08-23
  (`60ebd36`), so a literal build now strips the lock from `./close` — automating away the atomicity
  0023 and 0024 exist to provide. Nothing flags it: every path 0007 names was untouched, and the
  cardinality is correct-looking prose in a ticket that reads fresh. 0033 guards stale rule
  *citations* (named rules that no longer resolve); a stale *count* still resolves and still reads
  fine, so it slips through. The general rule worth landing: assert membership ("closing a row still
  takes the lock"), never cardinality (pointer: items/0007 AC2, items/0033, references/CONCURRENCY.md
  *Lock every write to `QUEUE.md`*).
- 2026-08-25 — **a mutation that leaves the suite green and a mutation applied to the wrong copy of
  the file produce the same evidence, and `verify` Step 3 has no step that tells them apart.** The
  test harness runs `skills/queue/templates/next`; this repo's own backlog runs
  `.claude/backlog/next`, kept byte-identical by `tests/backlog-scripts-installed.test.sh`. Mutating
  the copy the backlog runs — the obvious one, since it is what `./next` invokes and what the QA
  session has been reading — returns `134 passed, 0 failed`, which is exactly what a check-that-cannot-fail
  returns. One reads "this AC is unverified" and the other reads "I tested nothing", and nothing in
  the run distinguishes them. Step 2 warns about the *installed* copy under `plugins/cache/`; it does
  not cover a second in-repo copy that the harness prefers over the live one. Cheap fix: Step 3 should
  say to confirm the mutation reached the file under test — `grep` the mutated line, or read the
  harness's source variable first (here `NEXT_SRC`, `tests/next.test.sh:23`) (pointer:
  skills/verify/SKILL.md Step 3, tests/next.test.sh, tests/backlog-scripts-installed.test.sh).
- 2026-08-25 — **"a check that cannot be made to fail leaves its AC unverified" over-condemns a
  branch whose removal a later `else` absorbs.** Three branches in `--drive`'s phase-A ladder are
  mutation-silent — `queue`, `in-progress`, and the verify bounce — because deleting any of them
  drops through to a final `else` that escalates with the same exit code and a vaguer message. The
  outcome the AC names is still pinned; only the *reason* is not. Taken literally, Step 3 fails all
  three, which would push a QA session toward asserting message wording everywhere and make every
  future rewording a red. The distinction Step 3 is missing: mutate, then ask whether the AC's
  named outcome changed. If it did, the AC is unverified; if only the message did, that is a
  message assertion worth adding, not a red. Both cases were live in one ticket, which is what makes
  the missing distinction expensive rather than academic (pointer: skills/verify/SKILL.md Step 3,
  items/0038, skills/queue/templates/next `--drive` phase A).
- 2026-08-25 — **`develop` Step 4 has no correct answer for a re-entry whose verdict is "the code
  is right, only the evidence is missing".** The cycle it cites is write the test → confirm red →
  implement → confirm green, and on a QA bounce of this shape there is nothing to implement: the
  red can only come from *deliberately mutating correct production code*, running, and reverting.
  That is `testing-conventions.md`'s "prove a new guard fails", but Step 4 does not point at it, so
  the honest paths are to skip the red — leaving exactly the untrustworthy assertion the bounce
  existed to remove — or to invent the technique. The rule that fits: on a re-entry, confirm red by
  the mutation the verdict names, diff the file to prove it landed, and revert before committing.
  Two of this session's three findings came out of that pass rather than out of reading (pointer:
  skills/develop/SKILL.md Step 4, items/0038 *Re-entry 2026-08-25*).
- 2026-08-25 — **`queue` requires `qa_level` at capture time, but a `next: design` ticket does not
  yet know what artefact it produces — so the one field the skill calls "the decision that stops QA
  rigour quietly sliding" is set against an unknown deliverable.** Capturing 0041, the open design
  question is *skill, `retro` mode, `orchestrate` step, or `tools/` script* — and those do not share
  a level: a script is `unit` with fixtures (the `tests/measurement.test.sh` precedent), skill prose
  is `verify` with a named scripted assertion. The skill's own instruction is emphatic that the level
  is chosen "at queue time, not at develop time", and its routing section is equally emphatic that
  design tickets are "ranked normally" — but it never says what a design ticket does about the field,
  and `templates/item.md` offers no way to mark it provisional. I resolved it by arguing the level
  from what is certain *across* all four candidate placements (computed metrics mean code either
  way, and this project's `unit` command runs every `tests/*.test.sh`, so `unit` subsumes a
  `verify`-level grep) and writing that argument into the QA plan — which works here only because
  `unit` happened to dominate. Where the candidates straddle levels in the other direction there is
  no answer at all. Rule to draw: **a `design` ticket sets the level its candidate placements
  share, or records that design must set it** — and either way the skill should say which, because a
  cold session will otherwise guess and the guess is invisible (pointer: skills/queue Step 2 *Set
  `qa_level` now*, skills/queue/templates/item.md `qa_level:`, items/0041 QA plan).

- 2026-08-25 — **the retro gate counts a number retro cannot reduce.** `findings_threshold: 8` is
  read by `./next --findings` and gated on by `--drive` (exit 5), and it counts *every* entry in
  this file. But the two sweepers are not symmetrical: this retro processed 16 of 100 and left 84,
  almost all of them units of work that only `queue` can take. So the gate will keep diverting
  drivers into a retro that reads all 84 again and correctly finds nothing new, and no number of
  retros can ever clear it — only a `queue` sweep can, and nothing gates on *that*. The count the
  retro gate wants is entries a retro could act on, or the gate belongs on both sweepers
  (pointer: .claude/backlog/config.yml `findings_threshold`, .claude/backlog/next `--drive`
  phase A, skills/retro Step 1, skills/queue's sweep).

- 2026-08-25 — **an entry that is "taken by both" sweepers has no way to record that one half is
  done.** The header says a finding that is both a lesson and a unit of work is taken by both, and
  retro Step 4 says to leave the work entries — so an entry whose *lesson* I landed this session
  stays in the file, unmarked, and the next retro pays full price to read it and re-derive that
  there is nothing left to do. Five of the entries I kept are in exactly that state (the 0026 AC1/AC5
  grep defects, the `4.038` citation, the stale skill-size ticket id, 0007's AC2 cardinality): the
  rule is now in `testing-conventions.md`, only the test fix remains. Either an entry gets a marker
  the other sweeper writes, or the lesson half should be removable independently
  (pointer: .claude/backlog/FINDINGS.md header *Two sweepers empty this file*, skills/retro Step 4).

- 2026-08-25 — **`queue` Step 5 has no procedure for a sweep that is an order of magnitude past the
  threshold, and the per-entry instruction it does give does not scale.** The buffer held 86
  entries; the step says "for each entry that is a unit of work, do the Step 2 work properly", which
  is right per entry and silent on everything that matters at this size. Nothing says to cluster
  first, nothing says an entry and a ticket are not one-to-one, and nothing says what to do when the
  honest answer is ~32 tickets — several sessions of Step 2 rigour, which no single sweep can
  deliver. I clustered by root cause, asked the user to scope, took Tier 1 and Tier 2 only, and left
  ~22 clusters parked; every one of those decisions was invented. The bundling question is the sharp
  one: eight of the ten tickets written here each came from two to five entries, and bundling by
  root cause versus splitting by file has an actual trade-off in this repo — narrower `touches:`
  collides less, which is the live failure mode, while one rule landed three times drifts. Worth a
  paragraph in Step 5 on clustering, and one on what a sweep does when it cannot finish
  (pointer: skills/queue/SKILL.md Step 5, .claude/backlog/FINDINGS.md, items/0042-0051).

- 2026-08-25 — **entries in this file cross-reference each other by quoted phrase, so a sweep that
  removes one breaks the other's pointer with nothing to report it.** The surviving `design` Step 4
  entry says *"the 2026-08-25 finding below ('one claim on two shared prose files stalled the whole
  `develop` stage') records exactly that"* — an entry this sweep processed into 0050 and removed.
  The reference now resolves to nothing, and it is worse than a dead link because the sentence still
  reads as though the evidence is at hand. Neither sweeper is told to look, and the phrase is quoted
  rather than keyed, so nothing could look automatically. The cheap version is a rule that a
  cross-referencing entry names the ticket or the file rather than quoting a sibling; the honest
  version is that entries which cite each other are one entry (pointer: .claude/backlog/FINDINGS.md
  header *Entry order is not guaranteed*, items/0050).
