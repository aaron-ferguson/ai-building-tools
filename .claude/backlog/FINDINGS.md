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

**The date is UTC**, like `claimed_at:` in an item's frontmatter. Two sessions working the same hour
either side of midnight otherwise write different dates and both are defensible — and `retro` Step 1
expires entries on age, so the ambiguity lands on the one decision the date is actually read for.

**Refer to a sibling entry by item id or file path, and never by quoting it.** A sweeper removes the
entry it processed and cannot know another entry quoted it, so the quote resolves to nothing while
still reading as though the evidence is at hand — worse than a dead link, which at least announces
itself. An id or a path survives the removal, and a quoted phrase is not a key anything could check.

**A sweeper marks an entry on the way out with a head token, immediately after the date:**

```
- 2026-09-05 [->0060] — **what happened.** why it might matter (pointer: file, item id)
```

`[->NNNN]` means a row now carries this entry's work half; `[->none]` means a pass read the entry and
established that no destination exists yet. It sits at the head so a large buffer partitions with one
`grep` on `\[->`, and after the date so both line shapes above still match — trailing prose was tried
and bought the next sweeper nothing, because partitioning still meant reading every entry to its end.

**The noticer never writes the token.** It means *a sweeper dispositioned this*, and classifying an
entry at the moment of noticing is exactly the friction this buffer exists to avoid. The cheap hint —
the row the parking session was already holding — goes in the `(pointer: …, item NNNN)` clause, which
is not a classification.

**The token does not change what the gate counts.**
`./next --findings` counts every entry, marked or not: a count that fell as markers accumulated
would go quiet precisely when deferred and handed-over entries pile up, which is when the gate's
whole job is to be loud. The old trailing-prose form
stays readable — nothing rewrites an entry it is not processing.

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---
- 2026-09-23 — **`--model opus` resolved to TWO different models inside one sprint, and `harvest-usage.sh` has no rate for the second, so this run's tail cost is unknowable rather than merely wrong.** `skills/sprint/SKILL.md` Step 3 requires `--model opus` on every dispatch, which pins an ALIAS and not a model. Measured across run-20260922T031109Z's transcripts: the develop and verify gates ran `claude-opus-5`, while the retro's resumed legs ran 50 turns of `claude-opus-5-5` beside 29 of `claude-opus-5`, and the queue sweep ran `claude-opus-5-5` for all 42 of its turns. The rate table knows only the former, so the queue session **disappeared from the harvest altogether** — `HARVEST of 4 sessions` from five transcript files, with no `queue` row — and the retro priced at USD 1.22 for 12 of its 91 turns. The ledger row for this run therefore records `tail_usd 1.22` against a true figure nobody can compute, which is the one number the ledger exists to carry forward. **Two distinct rows' worth of problem.** (1) A dispatch should pin a concrete model, or record which one answered, because an alias is resolved server-side and can move between two dispatches of one run — every per-session cost comparison in `MEASUREMENT.md` silently assumes it does not. (2) The rate table needs a story for an unknown model id that is not "omit the session": a missing rate currently costs a whole session's turns, and omission is worse than a wrong rate because nothing downstream can see that anything is missing. **What worked, and is worth recording as a success:** `0162` shipped in THIS sprint to stop the ledger recording an unpriced harvest as a measured USD 0.00, and it is the only reason this was visible at all — the harvest said `UNPRICED turns on a model with no published rate: 50` instead of quietly reporting zero. The fix caught its own defect's next occurrence within hours. (`tools/harvest-usage.sh` rate table; `skills/sprint/SKILL.md` Step 3; `.claude/backlog/LEDGER.md` run-20260922T031109Z; related 0162, 0164; sprint supervisor run-20260922T031109Z tail)
- 2026-09-24 — **A sprint dispatched `/design 0179` and the host's built-in `/design` command (Claude Design consent/revoke) took it instead of the plugin skill; the stage escalated having done nothing (USD 0.29).** Every stage dispatch must use the plugin-qualified name `/ai-building-tools:<stage>`, and the sprint skill's Step 3 example and its design section use bare names, so the next supervisor copies the bug (skills/sprint/SKILL.md, run-20260924T050130Z)
- 2026-09-24 — design 0180 (token 8254): the ticket arrived at `next: design` with no *Open design question* section — retro filed the open decisions as FR2/FR3 under "Requirements for design to carry through". design Step 1 names that section as the contract and has no instruction for its absence; this pass treated the undecided FRs as the question. Either retro/queue must always write the section on a `next: design` row, or design Step 1 should say what stands in for it.
- 2026-09-24 — **Sprint planning let the queue's top row sit at `next: design`, so the run opened on design work and `--propose` offered a one-ticket design gate (run-20260924T050130Z).** The user's rule: a sprint is planned from the top row, which should be `develop ready`; the gate takes every related ticket, and related tickets still needing design are designed in parallel within the same sprint and then built; the plan also looks at where the queue lands after the sprint and designs the ticket(s) that will head the *next* sprint, so design stays ahead of develop. Not all design rows, just the next sprint's head (skills/sprint/SKILL.md proposal section, `./next --drive --propose`)
- 2026-09-24 — develop 0180 (token 30db): `tests/skill-size.test.sh`'s justification for `skills/sprint/SKILL.md` still argues from "the ~2,100 bytes that put this file over" (0040), but the file was 49,675 bytes before 0180 (29,485 over the 20,190 goal) and is 52,288 after it. The guard has no upper bound on a recorded file, so every ticket growing sprint passes against a reason that no longer describes the file; 0180's design note asked the build not to raise the cap silently, and there is no cap to raise. Needs a retro or queue decision: re-argue the exemption against today's size, or relocate (the payback test in that file's header).
- 2026-09-24 — **The sprint skill lets design run only beside develop; the user's rule is wider: design is research, so it may run beside develop, verify, or another design session, provided its files do not conflict with what the running sessions touch.** The supervisor checks the design ticket's scope against the running sessions' files (and the implications of accepting its outcome) before dispatching; retro and queue always run alone (skills/sprint/SKILL.md, *Design alongside develop* and Step 8; run-20260924T050130Z)
- 2026-09-24 — verify 0180 (token 1b52): develop's mutation sweep reported "31 of 31" and was true, but it enumerated the **guard's phrases**, not the **AC's clauses** — so a clause with no guard (AC5 "the proposal names that ticket"; AC2's amend/decline in the red-baseline list) could never appear in it, and both deleted leave `tests/sprint.test.sh` at 303/0. `develop`'s sweep guidance should enumerate from the AC text (one mutation per clause) rather than from the guard block, which by construction only covers what it already covers. Subject: `skills/develop/SKILL.md`.
- 2026-09-25 — verify 0180 (token eb65): **`tests/citations.test.sh` goes red in a worktree that is not a sibling of the checkout**, because `config.yml`'s `conventions.path: ../ai-building-conventions` is resolved from the worktree root. At 9f0cf0c, a `git worktree add --detach` under a temp directory gave `45 passed, 1 failed` (`FAIL no conventions directory resolved from config.yml`). The checkout and a sibling worktree (`../<name>`) both gave `46 passed, 0 failed`. 0180's new sprint Step 1 baseline says to run the suite "in a throwaway worktree" but not where. A baseline placed in a temp directory therefore reports a red that no ticket owns, and repair first then mints a row for it. There are two possible fixes: the baseline names a sibling location, or the test resolves the conventions path against the main worktree (`git rev-parse --git-common-dir`). The fix still needs a row.
- 2026-09-25 — verify 0180 (token 391b): **verify Step 3 says to mutate "at the altitude the AC is written at", but it never says what counts as one AC clause, so each round draws a different boundary.** Round 3 (eb65) said its list of clauses was complete. This round deleted AC-named *qualifiers*, the subject that scopes a guarded predicate: AC6's "A red no ticket owns" is gone from develop Step 5 and `tests/sprint.test.sh` stays at 310/0, because the only guard pins `never fixed under the claim you hold`. The test that separated gap from noise across 19 clause mutations was: *does the AC's named qualifier still occur anywhere in the section after the mutation?* Where it does, the outcome holds (C05, C06, C15). Where it does not, the outcome is gone (C11, C17). No skill text states that test, and each verify pass re-derives it. A candidate rule for verify Step 3, left for a retro to decide.
- 2026-09-25 — develop 0180 (token 9849): **the gap test in verify Step 3 / develop Step 5 ("the phrase the AC names no longer occurs anywhere in that section") reads two ways, and the two readings disagree on 11 of 51 rows.** Verify 391b read it as *the concept*: a row passed when a different phrase still stated it (e.g. `commands.unit_by_file` for AC1's "unit suite", `git worktree add --detach` for "throwaway worktree", `baseline` + `the red` for AC2's "a red baseline"). This round read it *verbatim*, with the AC's words deleted from the section, and found 13 gaps where 391b found 2. All 13 are now guarded (ca4c530), so 0180 is safe under either reading. But the next ticket's develop and verify can still divide it differently. Candidate: the skill text says "verbatim, case-insensitive, whitespace-tolerant", or names what may stand in for the AC's words. Subject: `skills/verify/SKILL.md`, `skills/develop/SKILL.md`.
