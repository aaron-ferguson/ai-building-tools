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

- 2026-08-30 — **Thinking is ~70.5% of a session's output tokens and its text is not retained in
  the transcript, so the largest output term cannot be measured from the record.** Stored
  `thinking` blocks carry an empty `thinking` field and a ~3,000-character `signature`, so 0074's
  measurement could only get it as a residual — output tokens minus estimated text and tool-input
  tokens. Human-facing narration was 4.6% and tool inputs 24.9% by comparison. This bounds what
  0073 can report and it is not obvious before you look: a turns-and-tokens breakdown that assumes
  the transcript holds what the model wrote will silently attribute 70% of output to nothing
  (pointer: items/0073, items/0074, tools/harvest-usage.sh, MEASUREMENT.md).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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

- 2026-08-30 — **The `set -e` short-circuit trap is recorded in the guard where it was found, so the
  next guard author hits it again.** Writing `[ "$n" -eq 0 ] && echo "FAIL …"` as a statement inside
  an audit function makes the function exit non-zero on the CLEAN path, which `set -e` turns into a
  truncated result for every caller — the guard reports a partial audit exactly when nothing is
  wrong. `tests/reference-size.test.sh` documents this inside one loop body; `tests/reporting.test.sh`
  hit it twice in fresh code before that note was found. Five shell guards now share the pattern and
  the warning lives in one of them (pointer: tests/reference-size.test.sh `offenders`,
  tests/reporting.test.sh `audit`).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-30 — **`references/REPORTING.md` attributes the same requirement numbering to two different
  tickets, three sections apart.** Line 37 cites "0039 FR14" and line 57 cites "0036 FR13"; both FR13
  and FR14 are *defined* only in `items/0039`, which inherited 0036's numbering when 0036 was split
  into children. Neither citation is wrong on its own — 0036 references both numbers — but a reader
  chasing one of them learns the numbering is ticket-ambiguous, and 0074 AC7 pins the 0036 spelling
  while nothing pins the other. This is the citation-drift 0036's split created and is not specific to
  this file: any reference to an FR number in the 0036/0039 pair needs saying which ticket's list it
  means (pointer: references/REPORTING.md:37, references/REPORTING.md:57, items/0036, items/0039).
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

- 2026-08-30 [61a0] **`verify` Step 3 tells you to mutate the working tree, but on this repo the
  files under test are shared prose another live session predicts** — 0051's evidence set was
  `MEASUREMENT.md` and `README.md`, both in 0053's `expects:`. Mutating a scratch copy removes the
  window entirely, and it worked, but `git archive HEAD | tar -x` alone gives 55/1: the suite's
  tracked-file guards use `git ls-files` and fail loudly outside a repo. Correct behaviour, and a
  session could read that 1 as a real red. The copy needs a `git init` + commit first. Step 3 names
  only the in-tree route and its `git checkout -- <that path>` restore.
  — read and triaged 2026-09-05 by retro: no destination exists yet, needs a row.

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

- 2026-09-05 — **a by-hand locked write can release the lock having committed nothing, and the
  sequence reads as success.** Landing two items in one shell invocation, the commit was written as
  `git commit -m … -- $paths` with `paths` accumulated in a loop. **zsh does not word-split an
  unquoted parameter expansion**, so git received one argument of two space-joined paths and refused
  with `pathspec … did not match any file(s)`. The `rm -rf` released the lock on the next line
  regardless, leaving both item files edited and `FINDINGS.md` drained **uncommitted** in a shared
  tree — the *uncommitted claim* failure shape, arriving from a direction the lock cannot see:
  `CONCURRENCY-INCIDENTS.md` names three ways a by-hand lock leaks and all three are about the lock
  outliving the turn, not about the commit inside it failing while the release succeeds. Two cheap
  guards: name every pathspec literally rather than through a variable, and check `git status` is
  clean before releasing rather than after. The scripts are immune because they commit their own
  fixed paths; this bites only the by-hand sequence, which is what `retro` and every withdraw-by-hand
  close use (pointer: `references/CONCURRENCY-INCIDENTS.md` *A busy or stale lock*, `skills/retro/SKILL.md` Step 4).
