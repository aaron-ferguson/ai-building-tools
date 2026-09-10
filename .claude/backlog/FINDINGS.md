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
  **Filed as item `0126` on 2026-09-09; the lesson half is open** — the general rule, that a
  skill restating a reference's rule drifts invisibly because an *incomplete* restatement still
  reads as correct, is broader than that one paragraph and has no home yet.
- 2026-09-09 (queue) — **`queue` Step 5 has no disposition for a swept entry whose work half an
  existing row already carries, so this sweep invented one from `retro`'s vocabulary.** Step 5
  offers exactly two outcomes: specify and rank it, or write an unranked `next: queue` stub. One of
  three entries belonged wholly to `0060`, which already reserves that half for whoever claims it —
  so a new row would have split one decision across two, and a stub would have been a row `develop`
  must refuse. What the entry needed is `retro` Step 4's *absorbed*: name the row, append one dated
  line to its *Notes & decisions*, remove the entry. Both sweepers empty the same file and only one
  of them can say "this already has a home", which is also why the marker rule beside it covers only
  the work-and-lesson case and not this one (pointer: `skills/queue/SKILL.md` Step 5,
  `skills/retro/SKILL.md` Step 4, item `0057` — which lists four other missing `queue` operations
  and not this one).
- 2026-09-09 (queue) — **No step in `queue` checks whether the work already exists before a ticket is
  written, and this capture came within one step of shipping three duplicates.** Step 2 says how to
  write a ticket well and Step 5 says to check a *parked finding* is still true, but nothing tells a
  capture session to read the queue for overlap first. Writing nine rows for the sprint project, the
  overlap was found only because the ranking walk in Step 3 required reading `QUEUE.md` end to end:
  `0041` already specified the session review this was about to re-file, and `0060` and `0067` own
  the design questions two of the new rows depend on — so two children would have shipped
  unblocked against decisions that are explicitly still open. The check that saved it was
  incidental to a different step, and on a backlog too long to skim, or a capture of one ticket
  where no ranking walk is needed, it would not have happened (pointer: `skills/queue/SKILL.md`
  Steps 2 and 3, items `0128`, `0041`, `0059`, `0060`, `0067`).
- 2026-09-09 (queue) — **Step 3 ranks one row against a queue and says nothing about inserting a
  related cluster.** Nine rows went in as a contiguous block below the operational fixes and above
  the design tail, and every part of that shape was invented: that the cluster stays contiguous at
  all, that prerequisites lead it, and that a blocked child keeps its place inside it rather than
  sinking below its siblings. The pairwise regret operator is defined for two rows, and applying it
  nine times pairwise would have interleaved the cluster through the queue, which is defensible by
  the letter of the rule and would have made the project unreadable as a unit. `0060` records the
  same gap from the other end — no sweeper has a procedure for a buffer far past its threshold —
  which suggests the missing rule is about batch operations generally rather than about ranking
  (pointer: `skills/queue/SKILL.md` Step 3, `.claude/backlog/RANKING.md`, items `0128`, `0060`).
- 2026-09-09 (queue) — **Step 1's re-specify row says a `next: queue` ticket "already has a rank
  and keeps it," which is true only for one bounced back from a later stage.** A ticket parked at
  capture time by Step 5 — Problem section only, no FRs, deliberately left out of `QUEUE.md` — has
  never been ranked at all, so re-specifying it needs Step 3's ranking walk to run for the first
  time, not be skipped. Surfaced while specifying `0138`, a design ticket about giving idea capture
  its own lightweight front door — any such front door produces exactly this never-ranked case on
  promotion (pointer: `skills/queue/SKILL.md` Step 1, item `0138`).

- 2026-09-09 — **A guarded phrase can be satisfied by an unrelated sentence that differs only in
  markdown emphasis.** `0111`'s AC5 asserts `resolved, never discovered` in `retro` Step 1, where
  `0078` had already written *`*resolved*, never discovered`* about a different rule; the literal
  reds only because the asterisks break it. Confirming red first caught it, and a later reflow
  that drops the emphasis would rewire the assertion with no guard noticing. Worth a rule in
  `testing-conventions.md`'s grep-guard section, or a check that no two rules in one window share
  an asserted phrase modulo emphasis.
- 2026-09-09 — **`skill-size.test.sh` checks that a justification exists, never that it still
  describes the file.** `retro` grew from 22,343 to 24,698 bytes under `0111` while its
  justification — keyed to `b9a5ee0`, naming Step 4's dispositions and Step 1's two modes — went
  stale without reddening: the block now furthest over the goal is not mentioned in it. A
  justification is a cached claim about the file it justifies and ages like any other.
- 2026-09-09 — **A backlog item in this public repo names an internal repository path.** Item
  `0111`'s Problem and Decision sections carry `neumo_repos/Probation`, against `CLAUDE.md`'s "no
  internal names". Written by the capture and design passes; a build session holding the row can
  neither redact pushed history nor decide that it should. Needs a row of its own, and a check on
  the intake side — nothing between `queue` and `develop` reads an item against the repo's own
  privacy rule.
- 2026-09-09 — **A guard case named for a rule can be held green by a second, unrelated occurrence
  of its phrase in the same window.** `0111`'s case *"AC2 — the refusal is cited, never restated"*
  asserts `rung 3` in `retro` Step 1. Verifying it: replacing rung 3's citation with a full
  restatement — the exact thing the NFR forbids — left the suite at **38 passed, 0 failed**, because
  the upward-only paragraph two lines below also says `rung 3`. Distinct from the emphasis finding
  above: there the collision needed a reflow, here it is live today. A guarded phrase needs to be
  unique *within its window*, not merely present, and nothing checks that
  (pointer: `tests/retro-tool-edit.test.sh`, the 0111 block).
- 2026-09-09 — **[for ai-building-conventions] A negative assertion anchored to a step NUMBER is
  re-aimed by renumbering, not broken — it keeps passing and stops testing anything.**
  `tests/release.test.sh` asserted the version-gate refusal never prints `step 7`, meaning the push
  step. `0114` inserted a step ahead of it, so the push became step 8 and the guard silently began
  asserting about a step that no longer exists — green either way. Same family as the
  cannot-fail-guard rules in `testing-conventions.md`, and the fix is the same shape as the phrase
  rules: anchor to something the edit must also change. Parked locally because the conventions
  repo declares no root `FINDINGS.md` to route it to (pointer: `tests/release.test.sh`, 0084 AC3).
- 2026-09-09 — **A guard matched a word the run prints unconditionally, so the clause it was
  written for could be deleted with the suite still green.** `tests/release.test.sh`'s AC4 block
  asserts `*authoris*` to prove FR5 — that the push line names where the release was authorised.
  Removing `-- authorised at step 5 ($AUTH_VIA)` from `tools/release` step 8 left the file at
  **45 passed, 0 failed**, because step 5's own banner reads `step 5/9 authorise the release` and
  prints on every run. Third variant of the same family in two days: the 0111 finding above is a
  phrase colliding with a *second occurrence of itself*, this one is a **substring collision with
  a step banner the tool emits regardless**. A matcher short enough to be robust against a rewrap
  is also short enough to be satisfied by prose the tool prints anyway, and nothing weighs those
  two pressures against each other (pointer: `tests/release.test.sh`, the 0114 AC4 block).
- 2026-09-09 — **A test seam added to satisfy an FR became a second production route past the
  gate the ticket was protecting, and the item's own trade-off note went stale in the same
  commit.** `0114` FR8 required the confirm device to be injectable, so `tools/release` grew
  `--confirm-device`. A file containing `y` at that path now authorises a real push with no
  terminal — verified, the FR2 case reaches step 6 and pushes — which makes it a second flag
  meaning "already asked" while *Notes & decisions* still says `--yes` "remains the single flag"
  that does. Nothing in `develop` or `verify` asks whether a seam added for the suite widens the
  surface the ticket exists to narrow, and the stale sentence was written by the same pass that
  falsified it (pointer: `tools/release`, `--confirm-device`).
- 2026-09-09 — **A sibling had already implemented two of the ticket's FRs and cited the ticket by
  number while doing it, and nothing in selection or Step 2 says to grep for your own id.**
  `0075` FR3 asks that the version bump derive from the remote; `tools/release` has done exactly
  that since `0084`, in a comment reading "the next version it names has to be derived from the
  REMOTE's plugin.json (0075: a hand-picked version collided)", with `tests/release.test.sh`
  guarding it. `develop` Step 2 prescribes grepping the *symbol* an FR names for a sibling item
  number — the reverse grep, `grep -rn '0075' --exclude-dir=.claude`, is one call, resolves at the
  site rather than through `DONE.md`, and would have re-scoped the ticket before a line was read
  (pointer: `skills/develop/SKILL.md` Step 2, *the cheap form of that check is a grep*).
- 2026-09-09 — **A ticket's `expects:` named a test file that has never existed, and `./next`
  prints it as if it were a path.** `0075` expected `tests/skill-prose.test.sh`; there is no such
  file in the tree or in the history. `./next develop`'s `EXPECTS` line is the first thing a
  claiming session reads about scope, and `./claim` seeds `touches:` from it verbatim — so a
  fictional path is reserved as held scope until the session narrows it by hand. `./claim` already
  warns to narrow; what it cannot say is which of the paths do not exist, which it could
  (pointer: `.claude/backlog/claim`, the `touches: is set provisionally` warning).
- 2026-09-09 (verify, `f5d0`) — **`0075`'s Git NFR — read-only, "no automatic pull, merge or
  rebase" — is unguarded in both skills it was delivered in, and the whole suite stays green when
  it is broken.** Measured: replacing `` `git fetch` then `git status -sb`, read-only `` with
  `` `git fetch` then `git pull --rebase` `` in `skills/develop/SKILL.md`, and the equivalent line
  in `skills/retro/SKILL.md`, left all 26 test files at 0 failed in both cases.
  `tests/remote-anchor.test.sh` asserts `the pull is the user` on retro's *other* line, so the
  sentence carrying the actual command is free to instruct a rebase while the paragraph beside it
  still says the pull is the user's call. The four ACs are met and this is not one of them — an
  NFR row is a requirement no AC restates, and nothing in `verify` Step 4 asks whether a checked
  NFR is *guarded* as opposed to merely true today (pointer: `tests/remote-anchor.test.sh`, the
  FR1 cases; `0107` is the queued ticket for NFR rows naming how they would red).
- 2026-09-09 (verify, `f5d0`) — **A rule whose content is "do this before X" was placed after X in
  the reading order, and no guard can see the difference.** `retro` Step 3's fetch paragraph sits
  below the *"Grep the destination before writing anything"* bullet it must precede, and Step 5's
  *"That chain begins with a fetch"* is the last bullet of the chain it opens. Both windows are
  step-scoped, which is the right altitude for the rule's *home* and blind to its position inside
  the step; a session reading top-to-bottom meets the instruction before the precondition
  (pointer: `skills/retro/SKILL.md`, Steps 3 and 5).
- 2026-09-09 (develop, `24af`) — **A mutation aimed at the comment *explaining* a quoting hazard
  proves nothing, because that comment is outside the quotes.** Proving the `sh -n` guard on the
  backlog scripts, the obvious target was the `` `"\047"` is an apostrophe `` comment — which sits
  above `DECOMMENT='...'`, not inside it, so the mutated template parsed fine and only the
  byte-identical check reddened. Read as "the guard does not work", that is exactly backwards. The
  hazard lives strictly between the opening `'` of an embedded `awk` program and its close; a
  falsifiability proof for any of `next`, `close` or `handoff` has to land there (pointer:
  `skills/queue/templates/close`, the `DECOMMENT` assignment).
- 2026-09-09 (verify, `6387`) — **`sh -n` proves the file parses under the shell you invoked, which
  on macOS is not the shell a stricter parser would reject.** `/bin/sh` here is bash 3.2.57 and
  `bash` on PATH is 5.3.9. An apostrophe inside `close`'s `ac_counts` `awk` program is a syntax
  error to `bash -n` and *valid* to `sh -n`; the script then runs and hands `awk` a mangled
  program, so `close.test.sh` fails 83 cases while `backlog-scripts-installed.test.sh` reports 29
  passed, 0 failed. A parse check is structurally blind to any breakage its own parser accepts, and
  a guard built on one inherits that blindness silently — the same guard is expected to be stronger
  on a Linux CI whose `/bin/sh` is a different parser, which is itself a reason not to trust a
  green here (pointer: `tests/backlog-scripts-installed.test.sh`, the AC5 block; `0077`).
- 2026-09-09 (verify, `6387`) — **A `grep -qF` prose guard passes on the phrase it is asserting
  *plus a suffix*, so rewording through it is invisible.** `takes no apostrophe` still matches
  after the rule is reworded to `takes no apostrophe-mark`, which inverts nothing but shows the
  window is a substring test, not a claim test. Deleting the rule does redden it, so the guard is
  not vacuous — but every prose guard in this repo has this property and none of them say so, and
  a mutation that only appends is the cheap way to make one look load-bearing when it is not
  (pointer: `tests/backlog-scripts-installed.test.sh`, the AC4 block).
- 2026-09-09 (verify, `2ea3`) — **A guard that is a scanner has positions, not one behaviour, and a
  mutation proves only the position it lands on.** `0077`'s AC2 has now bounced twice on the *same*
  script and the same prose shape, differing only in where the apostrophe sat: first inside an
  `awk` program's body (which `sh -n` accepts), now on the program's **opening line**, which the
  new scanner exempts by construction — its `NR != sq_line` rule has to exempt single-line
  programs, and exempts the first line of multi-line ones with it. Both mutations are the same
  sentence to a reader of the AC. The lesson is that where the artifact under test is a state
  machine, "prove the guard can fail" means enumerating the states *it* distinguishes — opening
  line vs body, inside `$( )` vs bare, before vs after a heredoc, one copy vs both — and mutating
  once per state. Five mutations in the build notes all landed in one state and read as thorough
  (pointer: `tests/backlog-scripts-installed.test.sh`, the AC8 `early_close` scanner; `0077`).
- 2026-09-09 (develop, `6b93`) — **A guard can reach a point where two shapes are genuinely
  indistinguishable, and the skills have no vocabulary for recording that.** `0077`'s scanner
  cannot tell `awk '/^x/ {  # it's the row` (broken) from `awk '{ print }  # a note'` (legal) at
  the moment the quote closes; the distinguishing fact — whether program text follows on later
  lines — needs lookahead the check does not have. Both `develop` Step 4 and `verify` are written
  as though every check either holds or has a hole to close, so the honest third answer, *this one
  over-reports a shape nobody writes and here is why that trade is right*, has no home but prose a
  future session may read as an unfixed defect. It went into the test's own comment block and the
  item notes. A named form for it — an acknowledged over-strictness, with the rejected alternative
  and the corpus evidence that nothing trips it — would stop the next session "fixing" it back
  into a hole (pointer: `tests/backlog-scripts-installed.test.sh`, the AC8 `early_close` scanner;
  `0077`).

- 2026-09-09 [0077] **A guard that has already been bounced twice on named mutations should be
  re-checked by sweep, not by more named mutations.** Two `verify` passes each found one more
  uncaught apostrophe shape by hand, and each hand-back cost a whole `develop` session for a
  one-clause change. This pass enumerated the scripts' 37 embedded `awk` regions mechanically and
  inserted an apostrophe at every column of every comment inside them — 1,978 insertions across
  three sweeps, about four minutes of wall clock — which settled AC2 in one pass and, as a
  by-product, gave the coverage number (1,288 of 1,298 caught by the new clause rather than by
  `sh -n`) that a named mutation cannot produce. Where an AC is a *quantifier* — "an apostrophe
  anywhere inside" — named mutations sample it and a sweep decides it, and the sweep is cheaper
  than the second bounce it replaces.

- 2026-09-09 — **four "change one, change all" duplications now live in these scripts and exactly
  one of them has a drift guard.** The `saw`/`saw_on_pass` pair is copied across four test suites,
  the `DECOMMENT` awk block across three scripts, the `fm_value` reader across three, and 0106 added
  a fourth: the ~70-line scope-comparison block in `close` and `handoff`. Each carries a comment
  saying to change them together, which is a rule with nothing enforcing it; 0106 wrote a byte-for-
  byte comparison for its own copy, and the other three have none. The install contract makes a copy
  the only option (a backlog script sources nothing), so the question is not how to stop duplicating
  but when a copy earns a guard — a rule worth stating once rather than deciding per ticket
  (pointer: tests/close.test.sh's "close and handoff carry the same scope block").

- 2026-09-09 [0106] **The scope report's commit range is anchored by a bare token grep, unscoped to
  the ticket, so a token collision silently attributes another ticket's files to this one.** `close`
  and `handoff` find the claim commit with `git log --format='%H %s' | grep -F "[$TOKEN]" | tail -1`
  — the whole history, any subject, oldest match wins. Tokens are four hex characters and are not
  checked for reuse, so once one repeats, the older ticket's claim commit anchors the range.
  Reproduced in a throwaway repo: an ancient `Claim 0001 [abcd]` commit ahead of `Claim 0700 [abcd]`
  made the close report `ancient/unrelated-a.ts ancient/unrelated-b.ts` as `0700`'s
  touched-but-undeclared paths. No collision exists in this repo's history yet (no token has claimed
  two tickets), which is why nothing is red. The scripts already know the id, so the exact anchor is
  available: `grep -E "^Claim $ID \[$TOKEN\]"`. NEEDS A ROW — the failure it produces, a report
  naming files the ticket never touched, is the same one 0106's own Problem section is about.

- 2026-09-09 [0106] **An empty `touches:` suppresses the whole scope report, and which of the two
  readings that encodes was never written down.** `scope_note()` returns early on
  `[ -n "$declared" ] || return 0`, with no comment and no test in either direction. Under
  `CONCURRENCY.md`'s *The working tree is shared too* — "read an empty `touches:` on an
  `in-progress` row as *its files are held*" — empty means EVERYTHING, so nothing is undeclared and
  suppressing is correct. Read as FR3 words it, empty declared nothing and every touched path is
  undeclared. Observed: a ticket with empty `touches:` whose commits changed `src/undeclared.ts`
  closed with no scope line at all. This matters more than it looks, because 0106's own FR2 is what
  makes an empty `touches:` the NORMAL shape for a `verify` claim — so the report FR3 added is
  structurally silent on the stage that does most of the closing, unless the session hand-populates
  the field. Worth deciding and recording, in a ticket whose whole subject is the field meaning one
  thing.

- 2026-09-09 [0115] **Two scripts describe `--drift` by its old contract, in a comment beside code
  that reasons from it.** `skills/queue/templates/close:224` and `.../handoff:250` both read "an
  unused reservation is invisible by construction — `./next --drift` compares Status against
  `blocked_by`, and until this nothing compared the declared scope against the diff." The claim they
  are actually making is still true (`--drift` reads no `touches:`), but the characterisation of the
  mode is now partial: since 0115 it also compares a row against its own item. Left alone because
  0115's *Out of scope* names those two files. It is the cache-beside-the-code shape `develop` Step 2
  ends on — the sentence reads correctly on its own, and only the mode it describes moved.

- 2026-09-09 (verify, 0115) — **`orchestrate` routes on a `--drive` exit code that `--drive` cannot
  produce.** `skills/orchestrate/SKILL.md:117` says "`1` and `2` are drift and usage errors, and both
  stop the run", but `--drive`'s body contains no drift check and the skill invokes `./next --drift`
  nowhere in its loop (only `:233`, a precondition, and `:271`, in passing). Driven on the `0084`
  drift shape: `./next --drift` exits 1 while `./next --drive` prints `COMPLETE nothing takeable` and
  exits 3. So 0115's new drift classes stop a human reader and not a driver — and 0115's own *Notes*
  justify their non-zero exit by that routing. Bears on the 0128 sprint slice (0131 especially), which
  is why it is parked rather than filed as a row by a session holding neither (pointer:
  `skills/orchestrate/SKILL.md:117`, item 0115).

- 2026-09-09 (develop, 0090) — **A ticket that hardens the lifecycle scripts hardens them under
  itself, and no step warns you.** 0090 FR3 makes `close` and `handoff` REFUSE where they used to warn
  and carry on, and `.claude/backlog/handoff` is the script this very session then calls to hand the
  ticket over — so from the moment FR3 landed, an uncommitted `QUEUE.md` in the tree would have
  refused my own hand-off, correctly, on a rule I had just written. It happened to be clean. The
  general shape is CLAUDE.md's *This project is the tool its sessions are running*, but that section
  is about the **installed copy being stale**, which is the opposite direction: here `.claude/backlog/`
  is edited in place, so the new behaviour is live for the editing session immediately, mid-ticket, on
  a half-finished implementation. A ticket whose FRs make a lifecycle script refuse more should say so
  in *Notes* and keep the shared files committed as it goes; a bug introduced in `close` or `handoff`
  between Step 4 and Step 5 strands the ticket in the one script that could release it. Nothing in
  `develop` Step 4 or Step 5, and nothing in `CONCURRENCY.md`, names this class.

- 2026-09-09 (verify, 0090) — **Nothing surprised me that the skills do not already name.** Recorded
  as an explicit nothing rather than left blank. The one thing worth a line is that `verify` Step 3's
  *Confirm the break landed* earned its place this pass: a mutation targeting the first line matching
  a phrase hit that phrase's own **explanatory comment** instead of the code, wrote nothing, and the
  suite then ran fully green — a result identical in every visible respect to a guard that holds. The
  rule caught it because the mutation script asserted the line it was about to overwrite. Selecting a
  mutation site by a phrase that the script also *documents itself with* is the specific trap, and it
  is likelier here than elsewhere because these scripts carry long rationale comments quoting their
  own output strings.

- 2026-09-09 (design, 0140) — **`design` Step 4 prescribes a by-hand backlog write that
  `CONCURRENCY.md` forbids and `handoff` exists to replace.** Its item-scoped path says "set
  `next: develop` / `status: ready`, and commit by pathspec in the same turn" — which is an edit to
  `QUEUE.md` and the item, unlocked and untokened, and `.claude/backlog/handoff` refuses to perform
  it that way for six documented reasons (`handoff:37-41`). It also has no correct answer for an
  **unclaimed** ticket, because `handoff` requires the token the item records and `design` never
  tells the session to mint one. Resolved here by claiming first (`./claim 0140` → `e1ec`), writing,
  then handing off — the same shape `develop` uses — and `./claim` itself prompted the missing half,
  printing that `touches:` is not seeded for `design` and must be set to what the design pass will
  write. Neither `touches:` nor the claim appears anywhere in `design`'s SKILL.md. Bears on 0091
  (by-hand writes take the lock) and 0048 (which write sites become scripts); parked rather than
  filed as a row by a session holding neither.
- 2026-09-09 (develop, 0136) — **Nothing surprised me.** `develop`'s steps had a correct answer at
  every point: `./next develop` offered the row, `./claim` seeded and explained `touches:`, the
  staleness grep confirmed `gate_from` still read as the ticket described it, and the ticket's own
  AC4 turned out to be already guarded by `tests/backlog-scripts-installed.test.sh`. Recorded as an
  explicit nil rather than left blank.
- 2026-09-09 (verify, 0136) — **Nothing surprised me.** Every step had a correct answer: `qa_level:
  verify` resolved to the one script the QA plan names, the mutation sequence ran against a
  committed tree so no restore was ambiguous, and `./claim` again printed the `touches:` note.
  One structural fact noted in the verdict rather than parked as a defect:
  `tests/next.test.sh` sets `NEXT_SRC="$ROOT/skills/queue/templates/next"`, so every behavioural
  guard exercises the template and `.claude/backlog/next` — the copy this repo actually runs — is
  covered only transitively, by `tests/backlog-scripts-installed.test.sh`. That is the intended
  "fix the template, never the copy" direction, and this ticket's AC4 is what closes the loop.
- 2026-09-09 (develop, 0140) — **A mutation sweep outgrows a foreground tool call, and the obvious
  way to wait for it is refused.** `develop` Step 5 and several QA plans now prescribe neutering each
  new branch and re-running the suite; eleven runs of `tests/next.test.sh` (266 cases) took about
  four minutes, past the Bash tool's 120s default, so the call was moved to the background — and the
  natural follow-up, `sleep 150 && cat <output>`, is blocked by the harness with an instruction to
  use an `until` loop instead. The shape that works is to make the sweep script print a sentinel line
  last and then `until grep -q '<sentinel>' <output file>; do sleep 5; done` with a raised timeout,
  which means the sentinel has to be planned before the sweep starts rather than discovered after it
  backgrounds. Nothing in `develop`, `verify` or `testing-conventions.md` says a sweep is a
  long-running job or how to wait on one. Bears on the sweep prose in both skills and on
  `testing-conventions.md`'s "prove a new guard fails"; parked rather than filed, by a session
  holding neither.
