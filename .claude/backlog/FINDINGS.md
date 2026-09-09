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
