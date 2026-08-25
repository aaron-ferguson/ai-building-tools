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

- 2026-08-25 — **a ticket that quantifies a file it does not own goes stale, and the stale numbers
  shaped its question.** 0035's Problem statement described `prototype` Step 5 as "three build
  procedures", which is the framing its whole design question rested on; re-measured, level 1 is 969
  bytes, level 2 is 5,859, level 3 is 1,427 — one big branch and two small ones, so "each level
  becomes a reference file" was never the shape of the answer. Its `develop` byte count had also
  drifted 219 bytes since capture. Neither `queue` nor `design` says to re-measure a figure a ticket
  captured about a file it is not changing, and the figure reads as fact. Plausibly the rule is the
  same one this repo already applies to `blocked`: a number about another file is a **cache**, and
  the file is the authority (pointer: skills/queue Step 1, skills/design Step 1, items/0035 FR6).

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

- 2026-08-25 — **`./next <stage>` prints `TAKE` on a row whose `expects:` collides with the files it
  names as held, in the same output.** A `develop` session found 0034 claimed by another window
  (`c2e9`, `touches: skills/verify/SKILL.md references/CONCURRENCY.md`); `./next develop` then
  printed `TAKE 0036` — whose `expects:` names `skills/verify/SKILL.md` — directly above a
  `CLAIMED FILES — another session owns these` block naming that same path. Both facts are correct
  and the intersection is left entirely to the reader, because `--help` defines takeable as stage +
  `blocked_by` only. The skill does require the manual compare (`develop` Step 1 "Check the file
  scope before you claim", `CONCURRENCY.md` *The working tree is shared too*), so this is not a
  script bug — but a row printed under `TAKE` reads as cleared, and the session that trusts the
  header is exactly the one that collides. Worth either filtering the offer or marking the
  overlapping row inline (pointer: .claude/backlog/next, skills/develop Step 1, items/0034,
  items/0036).

- 2026-08-25 — **one claim on two shared prose files stalled the whole `develop` stage, and no rule
  covers it.** 0034's `touches:` is `skills/verify/SKILL.md` + `references/CONCURRENCY.md`. With it
  held, every other takeable `develop` row collided — 0036 on `skills/verify/SKILL.md`, 0007 on
  `references/CONCURRENCY.md` — while 0035 is `next: design` and 0006/0008/0003/0004/0037 are
  genuinely blocked, so the session claimed nothing and stopped with the stage non-empty.
  `CONCURRENCY.md` says "prefer single-writer files", but in a plugin repo the skill and reference
  files *are* the product, so they are structurally multi-writer and the file-scope rule degenerates
  to a stage-wide lock held by whichever row was ranked first. The collisions here are also
  section-level, not line-level (0034 rewrites CONCURRENCY.md's advisory line; 0007 rewrites its
  claim rules), and nothing says whether that is safe — the honest answer today is no, because a
  pathspec commit carries the other session's edits to the same path regardless. Plausibly the same
  root as the batching finding above (pointer: references/CONCURRENCY.md *The working tree is shared
  too*, items/0034, items/0007, items/0036).

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

- 2026-08-25 — **the `Co-Authored-By` trailer collapsed exactly when the skill-driven lifecycle took
  over the commit volume, and nothing noticed.** `git-conventions.md` requires the trailer in *all*
  AI-assisted commits. Every one of the 28 commits through 2026-08-20 carries it; of the 229 since
  2026-08-21 only 36 do (16%), and the ones that do are the hand-driven sessions. The mechanism is
  in the skills themselves: `develop`, `queue` and the rest give commit templates as a single-line
  `git commit -m "Claim 0007 [$CLAIM]" -- <paths>`, and **no skill file mentions the trailer at
  all** — so a rule that lives only in a conventions file is silently dropped by every skill that
  hands the agent a ready-made command instead. Either the templates carry the trailer or the
  convention says lifecycle commits are exempt; what is there now is a rule that 84% of recent
  commits break (pointer: ai-building-conventions/git-conventions.md:21,
  skills/develop/SKILL.md:135, skills/queue/SKILL.md:373).

- 2026-08-25 — **0026's AC5 guard cannot fail, because its verdict grep matches a heading the same
  test file requires to exist.** `tests/measurement.test.sh` asserts the verdict with
  `grep -qE 'materialised|partly|did not'` over `MEASUREMENT.md`. The record's section heading *What
  the two runs did not hold constant* contains "did not", and AC8's own assertion in the same file
  requires that heading to be present — so AC8 passing *guarantees* AC5 passing. Proved by deleting
  the entire `## Verdict` section: `grep -c materialised` went to 0 and the suite still reported "ok
  the record states a verdict", with only the separate `5.09` presence check going red. The test's
  own header comment claims the opposite — "a run that produces figures and no verdict fails ... which
  is why AC5 ... [is] asserted separately from AC1". This is the same family as the 0032 entry below
  and the 0026 entry of 2026-08-24, and it is now three instances: assert the verdict and its subject
  on one line, or anchor to the Verdict section's own body rather than to the document
  (pointer: tests/measurement.test.sh AC5 block, items/0026,
  ai-building-conventions/testing-conventions.md "a guard that is wired and still cannot fail").

- 2026-08-25 — **the same document-wide grep weakness hits 0026's AC1: deleting a whole row from the
  per-skill table leaves the suite green.** AC1 is checked with `present ... "verify"` and friends,
  and the words `queue`, `develop`, `verify`, "cost per turn" and "context tokens per turn" all occur
  in the surrounding prose, so the assertions pin *vocabulary*, not the existence of a breakdown.
  Removing the `| verify | 10 | ... |` row from the isolated table left 40/40 passing. A table-shaped
  claim wants a table-shaped assertion — match the row, not the word (pointer:
  tests/measurement.test.sh AC1 block, MEASUREMENT.md isolated-run table).

- 2026-08-25 — **a measurement can pin its numerator and leave its denominator live, and the ratio
  then rots silently.** `MEASUREMENT.md` pins its token figures with `--exclude` and pins its findings
  count "as at 2026-08-24 06:00Z" — both deliberate, both recorded. But *cost per closed ticket*
  divides that pinned $114.27 by a count of closed tickets read from `DONE.md`, which is as live as
  `FINDINGS.md` was. `DONE.md` now holds **20** rows dated 2026-08-23/24, not the recorded 19 — `0005`
  closed later the same day — so the recorded $6.01 is today $5.71, and `README.md` repeats the 19.
  The lesson the record already learned one section earlier was not carried to the figure beside it:
  **every denominator read from a live file needs the same as-at pin as the numerator**
  (pointer: MEASUREMENT.md "Cost per closed ticket", README.md, items/0026 AC6).

- 2026-08-25 — **the record's own "Re-running this" recipe does not reproduce the record.** It gives
  `harvest-usage.sh <store> --since 2026-08-23 --sessions`, which today returns 45 sessions and
  $174.29 against the recorded 30 and $114.27, because ten more sessions have since landed *inside the
  same UTC date* that the `--until` bound cannot separate. The figures are exactly reproducible — every
  cell of both tables was reproduced in this pass — but only with twelve `--exclude` flags derived by
  sorting sessions on their first timestamp, which the record does not carry. It names two exclusions
  and asserts "pin the exclusions and record them, as this one does"; that sentence is now false, and
  `0037` and `0036` are named as the re-runners. A date window is not a pin on a live store: record
  the session-id set, or give the harvest a timestamp cut rather than a date one (pointer:
  MEASUREMENT.md "Re-running this", tools/harvest-usage.sh --until, items/0026 FR10/AC9).


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

- 2026-08-24 — **two sessions committed under the same claim token, so the audit trail cannot say
  who did what — and nothing in the protocol can detect it.** While `develop` held 0026 as `ebff`,
  a concurrent session committed `267d13f` and `2cfc227` tagged `[ebff]` for an unrelated repo-wide
  rename. Whether that is a 1-in-65536 collision on `head -c2 /dev/urandom` or a token read out of a
  file and reused, the effect is the same: `CONCURRENCY.md`'s *Claim tokens* says ownership is
  memory and an unfamiliar token belongs to the other window, which gives a session no way to
  notice a **familiar** token on work it did not do. The same commit also swept 41 lines of this
  ticket's uncommitted *Notes & decisions* into its own message — the documented hazard, arriving
  from the direction the rule does not cover, since the notes were mid-write rather than a claim.
  Options: widen the token, or have `claim` refuse a token already live in another item's
  `claimed_by:`, or drop the pretence that a commit tag identifies a session.

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
- 2026-08-24 — **a ticket was handed to `verify` with part of its own work uncommitted.** `0026` was
  set to `next: verify` by `e604703`, but the tail of the effort→project rename it depends on —
  two words in `MEASUREMENT.md`, the file that ticket is *about* — is still sitting in the working
  tree. The next `verify` session opens on a dirty tree on the one file its assertions read, which
  by Step 2 makes its verdict advisory before it has run anything, and puts an uncommitted change
  one careless `git add` away from landing under someone else's message. Handing a ticket on is the
  moment to check `git status --porcelain` is clean of your own paths, and no stage says so
  (pointer: skills/develop Step 5, skills/verify Step 2, MEASUREMENT.md).
- 2026-08-24 — **`./close` leaves `next:` set on a ticket it marks `done`.** After closing 0005 the
  item reads `status: done`, `closed: 2026-08-24`, `next: verify`; 0010, closed by hand before the
  script existed, reads `next:` empty. The two close paths disagree about the same field. It is
  currently harmless only because the row leaves `QUEUE.md` and `./next` reads the row — but the
  item file is left saying a closed ticket is still due at a stage, which is exactly the
  field-and-status disagreement the `next`/`status` split was made to prevent (pointer:
  .claude/backlog/close, items/0005 and items/0010 frontmatter, items/0010 FR).
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
- 2026-08-24 — **0031 fixed the comment-blind *list* reader; the *scalar* readers are still
  comment-blind, in both scripts.** `next`'s `fm()` and `close`'s `fm_value()` take everything after
  `key:` and strip only surrounding quotes, so `claimed_by: "f0c3" # mine` returns `f0c3" # mine` —
  and `close` compares that against the token it was given before it will close anything. The same
  instruction that produced 0031 (develop Step 1: annotate the entry inline) invites it on any
  frontmatter field, and there is now an asymmetry a reader will not expect: a comment on `touches:`
  is handled, a comment on `claimed_by:` or `size:` is not. `decomment` in `next:117` is already the
  fix — it needs lifting out of `fm_list` and applying in `fm()`, and giving to `close` along with
  `fm_list` (which the 2026-08-24 block-list finding above already asks for). Out of scope for 0031,
  whose FRs are lists only (pointer: skills/queue/templates/next `fm()`, skills/queue/templates/close
  `fm_value()`, items/0031, develop Step 1).
- 2026-08-24 — **"diff the mutation before believing either colour" silently gives you nothing when
  the implementation is not committed yet.** `testing-conventions.md` says to confirm a mutation
  landed by diffing the file, and the reflex is `git diff -- <path>`. On the TDD path that diff is
  against HEAD, which still holds the *pre-fix* code, so the mutated line never existed there and the
  grep for it comes back empty — an empty diff that looks exactly like a mutation that failed to
  apply, on a run that was in fact correctly red. It happened here and cost a second pass. The fix is
  cheap and worth naming in the rule: copy the file aside before mutating and `diff` against that
  copy, never against HEAD, whenever the code under mutation is uncommitted (pointer:
  ai-building-conventions/testing-conventions.md "Prove a new guard fails", skills/develop Step 5).
- 2026-08-24 — **batching.test.sh's AC4 date check is an adjacent measurement of exactly the kind
  0032 existed to remove, one assertion below the one 0032 fixed.** AC4 asserts the batching
  statement "carries a dated figure" with `grep -qE '20[0-9][0-9]-[0-9][0-9]' "$PARA"` over the whole
  paragraph — so *any* date anywhere in it satisfies it, not the date on the figure. The paragraph
  currently holds two (`**2026-08-22**` on the capture-side figure, and `2026-08-23/24` in the
  sentence about 0026 finding nothing to measure), so stripping the figure's own date leaves the
  guard green. Found by driving 0032's AC4 mutation and watching it *not* red: the first mutation
  removed only the figure's date and the suite still reported 13 passed. The guard is real but it
  pins a weaker property than its label claims, and it gets weaker every time the paragraph gains a
  date — which it will, since 0026 is due to replace that very sentence with a dated develop-side
  figure. Anchor the date to the figure it dates (assert the date and the claim on one line, or
  `grep -qE '\*\*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]\*\*: '`) rather than asserting a date is present
  somewhere nearby. Out of scope for 0032, whose FRs are the extraction window only (pointer:
  tests/batching.test.sh "AC4 — the statement carries a dated figure", items/0032,
  ai-building-conventions/testing-conventions.md "a guard that is wired and still cannot fail").
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

- 2026-08-25 — **`./next develop` verdicts `TAKE` on a row whose *entire* `expects:` set is held, and
  it has both halves on screen to know better.** All five `next: verify` rows were held by one batched
  pass (`1a06c11`); every remaining `next: develop` row overlapped that pass's `touches:` — 0034 on
  2 of 2 expected paths, 0036 on 4 of 11, 0007 on 4 of 6 — so nothing was developable. `./next develop`
  nonetheless printed `TAKE 0034`, then printed the CLAIMED FILES block four lines below showing both
  of 0034's paths held by `0029`/`0026`/`0033`. The take loop (`next:286-304`) filters on stage,
  `blocked_by` and the Status column, and never consults the held set; `show_claimed` runs afterward
  and independently. Two consequences, and the second is the worse one: the verdict word contradicts
  the skill's own rule (`develop` Step 1, *Check the file scope before you claim*) for a reader who
  trusts the first line, and because the loop `break`s on the first stage match it cannot offer the
  next *clear* row either — the thing Step 1 actually asks for. The data to cross is already in the
  same process. Note the asymmetry with the 2026-08-25 verify entry above: `develop` Step 1 *does*
  write down this outcome ("If every row collides, say there is nothing safe to develop"), so the
  prose was correct here and only the tool was wrong (pointer: .claude/backlog/next:286-304 and :204,
  skills/queue/templates/next, skills/develop Step 1, references/CONCURRENCY.md *The working tree is
  shared too*).
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
- 2026-08-25 — **a design pass can source a constant to a file that does not contain it, and every
  downstream number inherits the error silently.** 0035 FR1 cited "~30 turns per session
  (`MEASUREMENT.md`)"; that file's 30 is its *session* count (1,112 turns / 30 sessions ≈ 37) and it
  says at line 24 that a develop session averages 39. The break-even constant is a direct function of
  N, so the misread propagated to the published `B ≈ 20,000` and into two ACs written against it.
  Nothing could catch it: the arithmetic is internally consistent, the citation is real, and the
  conclusions happened to be robust. Rule to draw: **when an FR quotes a figure with a source, the
  build re-reads the source rather than the FR** — a cited number is an assertion about another file,
  and it is the one kind of assertion a ticket cannot test itself (pointer: items/0035 FR1 and its
  build notes, MEASUREMENT.md line 24 and line 52).
- 2026-08-25 — **a whole-file substitution is not a valid red proof for a guard that asserts against
  its own text.** Proving 0035's new AC5 cases could fail, a `sed` across a throwaway copy changed the
  `RELOCATE=` definition *and* the assertion's own literal, so the check compared a string to itself
  and the suite stayed green — a guard that was in fact wired reported as un-provable, which would
  have read as "wired to nothing" to the next session. Re-proved by editing only the definition line.
  This is a class the existing fixture convention does not cover: `skill-size` and `reference-size`
  both generate independent fixtures for the *sizes* they gate, precisely so a red cannot be an
  artefact, but the self-referential *wording* assertions have no equivalent rule. Rule to draw:
  **break the definition, never the expectation** — and where expectation and subject are one string,
  say so where the assertion lives (pointer: tests/skill-size.test.sh's 0035 block,
  tests/reference-size.test.sh's fixture-base comment).
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
- 2026-08-25 — **`queue` Step 6's own commit example fails on the file it is committing.** The step
  shows `git commit -m "Capture 0007: …" -- .claude/backlog/QUEUE.md .claude/backlog/items/0007-*.md`,
  and `items/0007-*.md` is the brand-new file that capture just wrote — so git rejects the pathspec
  with *"did not match any file(s) known to git"* and the whole commit fails, queue rows included.
  `CONCURRENCY.md` states the fix (*"A file git does not know yet needs `git add -N` first, or the
  pathspec fails"*), so the skill contradicts the reference it cites, in the one snippet a session is
  most likely to copy verbatim. It costs a retry rather than a corruption, but the retry happens while
  the lock is held and `QUEUE.md` is dirty, which is the worst moment to be improvising. `./claim` and
  `./close` never hit it because they only ever commit files git already knows (pointer:
  skills/queue/SKILL.md Step 6, references/CONCURRENCY.md *The git index is shared*).
- 2026-08-25 — **the payback test's own bytes/token constant is cited to a file that does not carry
  it.** `tests/skill-size.test.sh`'s header says "Every figure is measured and lives in
  MEASUREMENT.md: 4.038 bytes/token, $6.25/MTok cache write … $0.1028 per turn, and 1,112 turns
  across 30 sessions". Four of the five are there; **`4.038` is not in `MEASUREMENT.md` at all** —
  `git log -S` puts its origin in 0021's own guard, and that file's line 101 says the transcripts
  carry no field it could be derived from. 0035's AC1 asks only for "a citation of MEASUREMENT.md as
  their source", so the AC passes on a citation that is wrong for the one input the header instructs
  you to RECOMPUTE from. The bad case is not a wrong number today but a session that follows the
  pointer to recompute B0 when the rates move, finds four inputs, and either invents the fifth or
  trusts the stale constant — the exact failure the derivation was written down to prevent. Fix is
  one of: land the ratio and its provenance in `MEASUREMENT.md`, or narrow the header's claim to the
  four figures that are there and say where 4.038 came from (pointer: tests/skill-size.test.sh
  header lines 26-36, MEASUREMENT.md, items/0035 AC1).
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
- 2026-08-25 — **`./close` ticks nothing when the ACs carry no checkbox, and closes anyway.** 0035's
  acceptance criteria are written `- **AC1** — Given …`, with no `- [ ]`; 0034's are written
  `- [ ] AC1 — …`. `close` ticked 0034's seven and silently ticked none of 0035's eight, then closed
  the ticket, moved the row and reported success identically in both cases. `verify` Step 5 step 1
  says a close ticks the ACs and the skill states outright that **`verify` closes on ticked ACs** —
  so on the second format the one durable record that each criterion was checked is simply absent,
  and `DONE.md` cannot distinguish a ticket verified AC-by-AC from one waved through. The script is
  documented to refuse rather than guess on three grounds (unreadable table shape, wrong `next:`,
  wrong token); an AC block it cannot tick is a fourth and is not among them. Both templates are in
  live use, so this is not a one-off malformed ticket — `templates/item.md` should settle one form
  and `close` should refuse, or report, when it ticks zero of a non-empty AC list (pointer:
  .claude/backlog/close, skills/verify/SKILL.md Step 5, items/0035 vs items/0034, templates/item.md).
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
- 2026-08-25 — **Where a routing ladder ends in a catch-all `else`, asserting rc plus the outcome
  keyword asserts the `else`, not the branch.** Mutating `--drive`'s verify-bounce branch to
  `elif false` left all three of its pre-existing assertions green — rc 4, `ESCALATE`, the ticket
  id — because the final `else` escalates too. An FR8 row can be deleted outright while its own
  test case prints `ok` three times. This is the generative rule behind the previous entry's
  three mutation-silent branches rather than a fourth instance of it, and it belongs wherever the
  suite's assertion shape is described: for a ladder, the branch is pinned by its *wording*, and
  only the ladder's last arm is pinned by its outcome (pointer: tests/next.test.sh AC9 block,
  skills/queue/templates/next `--drive` phase A, testing-conventions.md).

- 2026-08-25 — **A collision with a *live `verify` claim* corrupts that session's verdict, which is a
  strictly worse failure than the commit conflict the file-scope rule is written against — and
  nothing says so.** `./next develop` offered `TAKE 0007` (the only takeable `develop` row: 0006,
  0008, 0039, 0040, 0003, 0004 all genuinely blocked, 0037 held) against `0038 [e1cb]
  touches: skills/queue/templates/next tests/next.test.sh`, claimed ninety seconds earlier. Three of
  0007's `expects:` are that same scope — both those paths plus `.claude/backlog/next`, which
  `tests/backlog-scripts-installed.test.sh` AC2 forces byte-identical to the template. The existing
  stall entries above name the hazard as the pathspec commit carrying the other session's edits;
  here the held ticket is at **`verify`**, so the hazard lands earlier and harder — a QA pass runs
  the suite, and edits to `tests/next.test.sh` or the script under it make e1cb's verdict a
  statement about a tree that was never a commit, with nothing in either session's output revealing
  it. `CONCURRENCY.md` says `verify` "marks its verdict advisory on changes outside the ticket",
  which is the reverse case (verify noticing develop's work) and offers develop no rule for this
  one. Also the second whole-stage stall in a single day on a different file pair, which makes the
  degenerate stage-wide lock this repo's normal operating mode rather than an incident (pointer:
  references/CONCURRENCY.md *The working tree is shared too* and *A stage writes only the ticket it
  holds*, skills/develop Step 1, items/0007, items/0038).
