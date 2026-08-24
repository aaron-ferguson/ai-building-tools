# Findings — parked, not yet placed

**One or two lines each, dated, newest at the top.** This is a buffer, not a second backlog: it
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

Format: `- YYYY-MM-DD — what happened, why it might matter (pointer: file, item id)`

---

- 2026-08-24 — **a verify verdict that quotes the string it is failing the ticket for re-publishes
  it, and the fix then reads as complete while the repo is still dirty.** 0026 failed on its privacy
  NFR for two transcript-store slugs at named lines; explaining the failure quoted both again, so the
  leak was four occurrences and the two the verdict itself added were in the section a reader trusts
  most. Redacting only the lines it named would have left the repo failing its own guard. `verify`
  should say it: describe a leaked value, never quote it — "one for this repository, one for the
  parent workspace" identified the defect exactly as precisely. Possible one-line rule in the verify
  skill's verdict step.

- 2026-08-24 — **this file's own entries are formatted two ways, so every count taken from it is
  low.** Most read `- <date> — **lead.**` but at least two read `- **<date> — lead.**`, and the
  obvious `^- 2026-` grep misses exactly those. `MEASUREMENT.md` published 26 in one sentence and 28
  in the next off that grep; the format-tolerant count was 42, and 45 an hour later. Both sweepers
  read this file by line shape, so the same undercount is available to `queue` and `retro` — an entry
  whose date sits inside the bold marker can be skipped by a sweep and never noticed. Either the
  header pins one format and a guard enforces it, or every reader has to match `^- (\*\*)?`.

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
- 2026-08-23 — **the term the repo argued itself into was the one nobody used.** 0001 rejected
  "project" on a collision argument — repo, Jira project key — and coined "effort" instead. The
  collision was real and the reasoning sound, and it was still the wrong trade: a coined term is
  misread by every reader who did not read the decision, while an overloaded real term is
  disambiguated by context for free. Worth a rule somewhere: prefer the real-world word and qualify
  it at the collision points, rather than inventing a word to avoid qualifying (pointer: items/0001
  *Notes & decisions* 2026-08-18 and 2026-08-23).
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

- 2026-08-24 — **`./next` tells you a row is held but never what it holds, so "avoid the collision"
  costs an item file read anyway.** `develop` Step 1 says to compare the candidate's `expects:`
  against every in-progress row's `touches:`, and `./next develop` does print the claimed-files
  block — but for a row with an empty `touches:` it prints `0026 [b7f1] none declared — assume
  held, ask` and stops. `assume held` is the right instruction and an unusable one on its own: the
  only description of that row's scope is its `expects:`, which the script already parses for the
  row it offers and does not print for the rows it warns about. Deciding 0005 was safe meant opening
  0026's item file, which is the read Step 1 exists to avoid. Distinct from the stage-blind `claim`
  message below — that one is about how the empty field arises, this is that the reader is given
  nothing to put in its place. Candidate: fall back to `expects:` in the claimed-files block, labelled
  as the weaker field (pointer: .claude/backlog/next claimed-files output, skills/develop/SKILL.md
  Step 1 *Check the file scope before you claim*).


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

- 2026-08-24 — **a verdict assertion that greps for "did not" cannot tell a verdict from prose.**
  Deleting `MEASUREMENT.md`'s verdict sentence outright left "the record states a verdict" green —
  "did not" occurs elsewhere in the file — and only the `5.09` assertion reddened. The QA plan
  asserted AC5 separately because figures-with-no-verdict is the likely failure; that is the one
  shape the assertion does not catch.

- 2026-08-24 — **a harvest pinned by exclusions is re-runnable only if the exclusions are recorded by
  id.** `MEASUREMENT.md` names them in prose — "the session that produced this measurement, and one
  still in flight" — so reproducing its table meant deriving the three session ids by differencing a
  live store against the published per-skill rows. The `--exclude` flags belong in the *Re-running
  this* block, which is where FR10's re-runnability actually lands.

- 2026-08-24 — **`/verify` in this repo resolves to the bundled verify skill, not
  `ai-building-tools:verify`.** The session that verified 0026 loaded the built-in evidence-capture
  skill; this repo's stage protocol had to be read out of `skills/verify/SKILL.md` by hand. A stage
  whose name collides with a built-in is a stage that can silently not run.

- 2026-08-24 — **`FINDINGS.md`'s entry format has drifted, and a count of the file disagrees with
  itself because of it.** Two entries lead with `- **2026-08-24 —` rather than `- 2026-08-24 — **`,
  so a date-anchored count returns 26 where the file holds 28 — exactly the gap between
  `MEASUREMENT.md`'s "26 findings parked" and its "grown to 28 entries" two paragraphs later.

- 2026-08-24 — **handing a ticket from one stage to the next is the one backlog operation with no
  script, and it half-applied.** `./claim` takes a row and `./close` finishes one, but the handoff —
  set `next:`, set `status:`, clear `claimed_by:`/`claimed_at:`, edit the row, commit, release — is a
  by-hand lock operation in `design` Step 4 and `develop` Step 5 both. Settling 0036 it *did* half
  apply: the `QUEUE.md` row reached `develop | ready` while the item frontmatter was still
  `design | in-progress`, and the lock had already been released by the trap, so for a moment the row
  and its item disagreed with nobody holding either. `CONCURRENCY.md`'s own argument for why `claim`
  and `close` are scripts — "a script cannot forget" — applies unchanged to the handoff, which is the
  one that mutates four fields across two files instead of two. (pointer: `references/CONCURRENCY.md`
  *The three scripts*, `skills/design/SKILL.md` Step 4, `skills/develop/SKILL.md` Step 5)

- 2026-08-24 — **`claim` writes `claimed_by:` quoted and the template shows it bare, so a matcher
  written against either form silently misses the other.** The template has `claimed_by:`, `./claim`
  wrote `claimed_by: "09e4"`, and an edit anchored on the unquoted spelling matched nothing — which is
  what caused the half-applied handoff above. It fails silently rather than loudly: a
  find-and-replace that matches zero times looks identical to one already in the desired state. Same
  family as 0031's comment-blind `fm_list` but a different cause — quoting, not comments — so the
  fix there will not cover it. (pointer: `.claude/backlog/claim`, `skills/queue/templates/item.md`,
  item 0031)

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
- 2026-08-24 — **The skill and `CONCURRENCY.md` disagree about whether a `QUEUE.md` row edit needs the
  lock.** Step 2 says *"Release in the same turn; the item file, ranking and the row are all
  unlocked"*, and Step 3 has the insert as a bare single `Edit`. `CONCURRENCY.md`'s *Lock every write
  to `QUEUE.md`* says **"Every write, no exemptions"** and lists only three write sites, none of them
  a capture-time insert. Resolved this session by taking the lock, which satisfies both, but a reader
  following the skill alone inserts unlocked. One of the two is wrong and it is not obvious which:
  `Edit`'s fail-on-mismatch may be the intended substitute for the lock on a single row, in which case
  `CONCURRENCY.md`'s "no exemptions" is what needs the caveat (pointer: skills/queue/SKILL.md Step 2
  and Step 3, references/CONCURRENCY.md *Lock every write to `QUEUE.md`* and *Never rewrite `QUEUE.md`
  by hand*).
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

- 2026-08-24 — **the lock protocol cannot be satisfied by hand, because a lock cannot be held across
  tool calls.** `CONCURRENCY.md` *Lock every write to `QUEUE.md`* requires the lock to be held "for the
  read, the write and the commit". A shell `trap` releases it when the Bash call exits, so a by-hand
  insert is two separate acquisitions with an **uncommitted `QUEUE.md` edit sitting unlocked between
  them**; omitting the trap instead leaks the lock on any failure path. `claim` and `close` satisfy the
  rule because each is one process — but **`queue` has no script for the row insert**, so the one
  operation this skill performs on `QUEUE.md` is the one with no compliant path. Either the insert
  earns a fourth script or the rule needs a documented by-hand form (pointer: references/CONCURRENCY.md
  *Lock every write*, skills/queue Step 3, items/0027).
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
- 2026-08-23 — **"one skill per session" has no correct answer for a user who deliberately runs two.**
  `/queue` was invoked inside a live `retro` session, with approval of the retro's proposals as its
  argument. Both skills open by asserting isolation, neither says what to do when the human overrides
  it, and the two have different commit disciplines (`queue` commits only under `.claude/backlog/`,
  `retro` commits across several repos) — so the combined session's commits had to be split by hand
  against two rules that each assume they own the session. It worked, but nothing said it should
  (pointer: skills/queue Step 6, skills/retro Step 5, this session).

- **2026-08-24 — removing a preference from the base suite leaves a follow-up nothing owns.** 0030
  took Notion out of the base tool suite and documented the `external_feedback:` extension point a
  profile plugs into, but *wiring Aaron's own solo projects back up* is named in that ticket's *Out
  of scope* and therefore has no ticket at all. Any solo project with `notion.enabled: true` in a
  live `config.yml` now has a stated wiring path and no one carrying it out. The general shape is
  worth a rule: a ticket that moves a preference behind a profile creates a second, smaller ticket
  by construction — the port — and *Out of scope* is where it silently goes to die
  (pointer: items/0030, references/EXTERNAL-FEEDBACK.md "If you had `notion:` configured").
- **2026-08-24 — the base suite has no home for a solo profile, only a company one.**
  `CONVENTIONS_CORE.md` resolves preferences through `companies/<name>/`, and the conventions repo is
  public, so a *solo* preference (which feedback product, which personal tooling) has nowhere to live
  that is both private and discoverable. 0030 hit this deciding where `NOTION.md` should move to and
  could only answer "not here"; it deleted the file and pointed at git history instead. Every future
  "move X behind a profile" ticket hits the same wall (pointer: items/0030 FR4, CONVENTIONS_CORE.md
  "Profiles & How Overrides Work").
- 2026-08-24 — **`verify` Step 2's advisory trigger has no answer when the only dirty paths are the
  backlog's own coordination files.** Step 2 says any change outside the ticket makes the verdict
  advisory, and Step 7 says an advisory PASS does not close. But a concurrent `queue` session leaves
  `QUEUE.md` modified and an item file untracked — dirt that provably cannot influence a verdict
  (0030's own guard excludes `.claude/` by design), while the literal rule would forbid closing
  whenever another window is queueing, which is the concurrency the suite is built for. The
  distinction the rule wants is "dirty *under test*", not "dirty anywhere" (pointer: skills/verify
  Steps 2 and 7, items/0034).
- 2026-08-24 — **the busy-lock procedure is written for a claim and strands a close.**
  `CONCURRENCY-INCIDENTS.md` says a lock under 5 minutes old means "report it to the user and stop,
  do not break it". At claim time stopping costs nothing. At *close* time the verdict already exists
  and lives only in the session holding it, so stopping leaves the row `in-progress` under a token
  whose session is ending — the failure `verify` owns closing to prevent. Hit live this session: the
  lock was held by another window at close time, and the only safe move (wait, then retry) is
  nowhere in the procedure (pointer: references/CONCURRENCY-INCIDENTS.md *A busy or stale lock*,
  skills/verify Step 5, items/0034).
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
- 2026-08-24 — **`tests/skill-size.test.sh`'s exception registry cites a ticket that never accepted
  the cost.** `skills/develop/SKILL.md`'s entry reads `0027 — carries the re-entry and staleness
  rules`, but 0027 is the script install and never touched that file; the described work ("its
  anecdotes are the relocation candidates") is 0035's question. The registry's own contract is "the
  ticket that accepted the cost", and a wrong ID there is invisible because the test passes either
  way — the reason is the control, not a number, so nothing ever checks the citation resolves. Same
  failure class as 0033 but for ticket IDs rather than rule names (pointer:
  tests/skill-size.test.sh:39, items/0033, items/0035).
- 2026-08-24 — **this project has no `CLAUDE.md`, so no session reads its Profile.**
  `CONVENTIONS_CORE.md` requires every project to declare `collaboration`, `company` and `release` in
  its own `CLAUDE.md`, and the precedence chain names it as the top override. There is none at the
  repo root, so a session inherits `~/Documents/AI/CLAUDE.md` — a personal memory file for a
  different purpose — and `release:` is absent, which the conventions say resolves to `released`. Both
  `queue` Step 0 and `develop` Step 3 tell a session to read the project's `CLAUDE.md`; here that
  read silently finds a parent (pointer: CONVENTIONS_CORE.md *Profiles & How Overrides Work*,
  skills/develop Step 3).
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
- 2026-08-24 — **`tests/backlog-scripts-installed.test.sh` is not in README's guard list**, so the
  block README offers as "run every guard" runs seven of eight. Noticed from 0028 while adding the
  eighth line beside it; left for whoever owns 0027's tail rather than fixed, since that file landed
  in a session running concurrently with this one (pointer: README.md *Testing*, items/0027).
- 2026-08-24 — **a justification entry whose file no longer exists passes silently, in both size
  gates.** Removing `references/CONCURRENCY-INCIDENTS.md` while its `case` branch stayed left the
  gate green at 9/0, exit 0 — the pass line just stops naming it. This is the staleness AC4 exists to
  catch, from the other direction, and it is a live risk precisely because the gate's own first
  recommendation is *relocation*, the operation most likely to rename a file out from under its
  entry. `tests/skill-size.test.sh` has the identical shape (iterate the tree, look up a reason;
  never the reverse), so a fix wants to land in both — which is the third-instance DRY question the
  entry above already parks. A `[ -f ]` sweep over the recorded paths closes it in about three lines
  (pointer: tests/reference-size.test.sh, tests/skill-size.test.sh, items/0028 verify notes).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
- 2026-08-24 — **`close`'s reconcile silently skips a dependent whose `blocked_by` is a YAML block
  list, and closing 0028 hit it.** `close` reads the field with `fm_value`, which returns only what
  sits after the colon on the key's own line, so `blocked_by:` followed by `  - "0028"` parses as
  empty, the `case "$blockers" in *"$ID"*)` test misses, and the loop `continue`s. 0028 closed
  reporting no reconcile at all; 0029 stayed `blocked` in both the item and the row, and
  `./next --drift` exited 1 — the stale-cache failure `close`'s own header calls the reason the
  reconcile is part of the close. Reconciled by hand under the lock afterwards. `next` already
  handles both forms via `fm_list` (next:100, used at next:118); `close` never got that parser.
  Blast radius today is one ticket — 24 of 25 items use the inline `blocked_by: ["0002"]` form that
  `fm_value` reads correctly, and 0029 is the only block-list one — but the form is unstandardised
  because the shipped template carries no `blocked_by` field at all (that is 0005, still open), so
  both forms will keep appearing. Two fixes, and the second is the load-bearing one: give `close`
  `fm_list`, and standardise the field in the template (pointer: .claude/backlog/close `fm_value`
  and `other_blockers_all_done`, .claude/backlog/next:100, skills/queue/templates/item.md,
  items/0005, items/0029, items/0028 verify notes).
- 2026-08-24 — **`tests/close.test.sh` passes 62 assertions over the reconcile and could not have
  caught the bug above: every one of its `blocked_by` fixtures is the inline flow form.** `mkitem` is
  called as `mkitem 0008 develop blocked '' '["0007"]'`, so the block-list shape the parser cannot
  read is never fed to it. The guard is green against a shape the tree also mostly holds, which is
  why this reads as covered rather than untested — the same fixture-realism trap 0028's own FR4 was
  written about, one level up: not a fixture copied from the tree, but a fixture that encodes only
  one of the two shapes the tree actually contains. A reconcile case in the block-list form is the
  missing assertion (pointer: tests/close.test.sh:61-72 `mkitem`, :238-262, items/0028 FR4).
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
- 2026-08-24 — **a `done` ticket can keep a live-looking claim token.** 0010 is `status: done`,
  `closed: 2026-08-23`, and still carries `claimed_by: "1b2e"`. `./close` clears both claim fields,
  so this is a by-hand close predating the script — but `CONCURRENCY.md` defines *held* as a
  non-empty `claimed_by:`, and the close-reconcile rule refuses to write a held dependent. A stale
  token on a closed ticket is therefore a row a future reconcile will silently skip and report as
  someone else's (pointer: items/0010 frontmatter, references/CONCURRENCY.md *Claim tokens*).
