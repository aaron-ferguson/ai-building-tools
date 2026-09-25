---
id: "0180"
title: Decide what a sprint does on a red baseline, and which stage may fix a red no ticket owns
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-23
source: retro
parent:
blocked_by: []
relates: ["0176", "0178", "0054", "0093"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
  - skills/develop/SKILL.md
claimed_by: "bb92"
claimed_at: 2026-09-25T19:01:48Z
touches:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
---

## Problem

**`/sprint` Step 1 has no "is the suite green" check.** It runs three checks before the first
dispatch — the CLI probe, the supervisor marker, the depth read — and none looks at the tests. Run
run-20260922T031109Z proposed, confirmed and dispatched a six-ticket develop gate while
`tests/item-ac-form.test.sh` AC1 was already red on `0178` (introduced by `68c132a` the day before).
For the whole run a new red was indistinguishable from the old one without a by-hand comparison, and
the develop stage spent reasoning separating them.

**The author's objection is the requirement:** *"if there is a pre-existing red, then we shouldn't
have started work and should have started with making sure that the suite is green."*

**Underneath it is a question no skill answers: which stage may fix a red owned by no ticket?**
Today none may — *A stage writes only the ticket it holds* forbids touching another item, and the
detector is out of every ticket's scope. So it either deadlocks or is done off the books. It was done
off the books this time: the author decided the fix inline and it landed as `da524ce` under `0176`'s
claim with no row, so `0176`'s diff carries an unrelated test file and nothing in the backlog records
the defect existed.

## Requirements

- **FR1** — `sprint` Step 1 gains a fourth check, **the baseline**: run the unit suite **at `HEAD` in a
  throwaway worktree** (`git worktree add --detach`, removed in the same turn), never on the shared
  working tree. It reports the tally — files and cases red, or `green` — **on the same line as the
  depth**, and the proposal quotes it.
  - Use `commands.unit_by_file` when `config.yml` sets it; otherwise `commands.unit`, and say that a
    fail-fast command stops at its first red, so the tally may be a lower bound.
  - Set `commands.unit_by_file` in this repo's `config.yml` to the per-file form its comment already
    records: `for t in tests/*.test.sh; do "$t" || true; done`. Point `verify`'s
    "where `config.yml` records the reporting form" at that key, so the concept has one definition.
  - Redirect the run's output to a file and poll it. Do not pipe it, because a timed-out pipe
    delivers nothing (`config.yml`, *A mutation rerun of tests/next.test.sh*).
- **FR2** — **A red baseline blocks the proposal. It does not end the run.** The proposal then leads
  with the red: each red file and case, and **who owns it**, found with `git log -1 -- <path>` and the
  in-progress rows. It offers four answers:
  - **repair first** — recommended, and the default the proposal states;
  - **waive** — go ahead over the red;
  - **amend**;
  - **decline**.
  A waiver goes into the `scope_confirmed` event as `baseline_red` (the case list and the `HEAD` SHA).
  Every stage dispatch prompt in that run quotes the list as "baseline red at <sha>, not yours".
- **FR3** — **A red no open ticket owns gets a row, minted on the spot and led first.** It is never
  repaired out of scope.
  - On **repair first**, the supervisor dispatches one `queue` session. Its prompt gives the red
    cases, the introducing commit, and "rank first". That session mints a `type: bug` row. The row's
    `relates:` names the ticket whose commit introduced the red.
  - The repair row runs **as its own gate** to `next: done`. The baseline check then runs again.
    Nothing else in the confirmed scope is dispatched until that re-check is green.
  - The person choosing repair first at the proposal **is** the escalation's answer. So this
    dispatch is the one exception to "Queuing new work … escalations, not automation", and the
    sprint states it as that.
  - A red whose introducing commit belongs to an **open** ticket is owned. The run mints no row for
    it, and the proposal names that ticket; the choices left are waive or decline.
- **FR4** — `develop` states that a red no ticket owns, met mid-work, **is never fixed under the
  claim you hold**. `da524ce` under `0176` is the named failure: an unrelated test file in `0176`'s
  diff, and no backlog record of the defect. Instead the session parks a `FINDINGS.md` entry that
  says the red **still needs a row** (`CONCURRENCY.md`, *A stage may record what still needs filing*),
  reports it in the outcome's `escalation`, and carries on if its own ACs can still be attributed.
  A red listed in the dispatch's `baseline_red` is not the session's own.

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when Step 1 is read, then it names a baseline check that runs the unit suite at `HEAD` in a throwaway worktree, prefers `commands.unit_by_file`, and reports the tally on the depth line; `tests/sprint.test.sh` asserts each phrase, and removing any one of them turns it red.
- [ ] AC2 — Given a red baseline, when the proposal section is read, then it says the red blocks the proposal rather than ending the run, lists repair first (recommended), waive, amend and decline, and says a waiver is recorded as `baseline_red` in `scope_confirmed`; guarded in `tests/sprint.test.sh`.
- [ ] AC3 — Given a waived red, when a stage dispatch is read in `skills/sprint/SKILL.md`, then the prompt carries the `baseline_red` list and SHA as not the stage's own; guarded in `tests/sprint.test.sh`.
- [ ] AC4 — Given a red no open ticket owns and the answer repair first, when the sprint text is read, then it dispatches one `queue` session to mint a row ranked first, runs that row alone to `next: done`, and re-runs the baseline before any other dispatch; and the *never writes a ticket* rule names this as its one exception; guarded in `tests/sprint.test.sh`.
- [ ] AC5 — Given a red whose introducing commit belongs to an open ticket, when the proposal section is read, then it names that ticket and mints no row; guarded in `tests/sprint.test.sh`.
- [ ] AC6 — Given `skills/develop/SKILL.md`, when its red-attribution section is read, then it forbids fixing a red no ticket owns under the held claim, cites `da524ce`, and routes the red to a `FINDINGS.md` "still needs a row" entry and the outcome's `escalation`; guarded by a new case in `tests/sprint.test.sh` or the develop guard that already covers that section.
- [ ] AC7 — Given `.claude/backlog/config.yml`, when read, then `commands.unit_by_file` holds the per-file form and `commands.unit` is unchanged (the release gate keeps its fail-fast form); and `skills/verify/SKILL.md` names the key where it now says "the reporting form".
- [ ] AC8 — Given the change, when `for t in tests/*.test.sh; do "$t" || true; done` runs, then every file is green, including `tests/skill-size.test.sh` against `skills/sprint/SKILL.md` and `skills/develop/SKILL.md`.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from two FINDINGS
  entries (sprint supervisor, run-20260922T031109Z; develop 0176, token db06), merged because FR3 is
  the question FR2 cannot be answered without.
- 2026-09-24 — design (token 8254). The ticket had no *Open design question* section. FR2 and FR3
  were the open decisions, and FR1 was already specified. What this pass did to the three FRs:
  - **FR1** is confirmed and made more specific: the check runs at `HEAD` in a worktree, and it
    reads a new `commands.unit_by_file` key.
  - **FR2** is answered: a red blocks the proposal, and repair first is the default.
  - **FR3** is answered: the repair gets a minted row.
  - **FR4** is new. It is the develop half that `expects:` already named.
  - AC1–AC8 are all new. The ticket had none.
- **Why the check runs at `HEAD` in a worktree, not on the working tree.** Several sessions work
  this backlog at once. An untracked file another window is still writing turns the working tree
  red, and that is not the baseline (`develop`, *An untracked file is the cheap case*). The stages
  build on the committed state, so the committed state is what gets checked.
- **Rejected: a red ends the run.** Ending the run sends the person to fix the red by hand, and a
  hand fix is exactly how `da524ce` landed with no row. The proposal is already the point where a
  person decides, so the red belongs there.
- **Rejected: no waiver at all.** The author's objection makes repair first the default and the
  recommendation. But some reds are real and still cannot be fixed inside a run, such as an external
  outage or a red that belongs to an open ticket. For those, "no waiver" collapses into "decline",
  and the person loses the work they could otherwise have done. A waiver is allowed only if it is
  recorded, and the recorded list is the fix for the actual harm: a new red could not be told apart
  from the old one without a by-hand comparison.
- **Rejected: a permitted out-of-scope repair, recorded somewhere durable.** This is what `da524ce`
  already was, and it put an unrelated file into `0176`'s diff for verify to explain. Every past
  attempt to carve an exception into *A stage writes only the ticket it holds* is in
  `CONCURRENCY-INCIDENTS.md`. A minted row is also the only kind of trace a reader looks for.
- **Rejected: the supervisor mints the row itself.** The sprint's "never writes a ticket" rule
  forbids it, and the right answer is to route the write through `queue`, not to weaken that rule.
- **The cost accepted.** A one-line detector fix costs up to three sessions: queue, develop and
  verify. `stage_budget_usd` gives means of 4.24, 4.03 and 3.63 USD, re-read 2026-09-24, so about 12
  USD before `queue` picks `close_by`. This pass leaves `close_by` to `queue`'s own rules rather than
  mandating `develop`. The repair is usually a change to a guard, and guards that cannot fail are
  the risk verify is there to catch.
- **What the answer depends on.** The `baseline_red` hand-off assumes the supervisor writes each
  dispatch prompt, and it does (Step 3). It also assumes a stage reads its prompt, which every stage
  does. Nothing here depends on a fact nobody has.
- **Size.** `tests/skill-size.test.sh` already carries a recorded exemption for
  `skills/sprint/SKILL.md` (0040). The build has to fit inside that file's current budget or
  re-argue the exemption. It must not raise the cap silently.
- 2026-09-24 — develop (token 30db). Built in 8878ba3. What each AC rests on:
  - AC1–AC7 are 31 new presence cases in `tests/sprint.test.sh` (block `0180`), one phrase per case,
    each scoped to its section with `section`/`says_ci`: Step 1, the proposal section, Step 3 and
    Step 8 of `skills/sprint/SKILL.md`; Step 5 of `skills/develop/SKILL.md`. AC7 greps
    `config.yml` and `skills/verify/SKILL.md` whole-file, since each phrase occurs once there.
  - Proven red first: before the prose existed, all 30 cases asserting new text failed; the one
    that passed asserts `commands.unit` is unchanged, which is correct.
  - Mutation sweep (run, not reasoned): each guarded phrase was replaced in a throwaway worktree
    at 8878ba3, and the whole `tests/sprint.test.sh` was run once per mutation. The results are
    below under *Sweep result*.
  - AC8: the whole suite was run per file (`unit_by_file` form). The result is below.
- **Size, not raised silently.** `skills/sprint/SKILL.md` went from 49,675 to 52,288 bytes (+2,613),
  and `skills/develop/SKILL.md` from 47,203 to 47,787. Both files already carry recorded exemptions,
  and `tests/skill-size.test.sh` puts no upper bound on a recorded file, so there was no cap to
  fit inside. The exemption itself was not re-argued here. Its reason still cites "~2,100 bytes
  over", which was already about 29k stale before this ticket, so that is parked in `FINDINGS.md`
  (a9ba508) for a retro or queue decision rather than decided under this claim.
- **An enumeration this widened.** Step 1's "three checks" became four, and the proposal's
  answers went from three to four when the baseline is red. A grep for sibling ids found one stale
  comment: `tests/sprint.test.sh`, 0130's AC1 block ("AFTER the three checks"). It is a comment,
  not an assertion, and it belongs to 0130, so it was left alone and is reported here.
- **A design-note claim checked against the source.** The Step 3 dispatch prompt is written by
  the supervisor, and that is where the `baseline_red` line now lives. The design note said so, and
  it holds: Step 3 already carries prompt-content bullets such as the write channel.
- **Sweep result (run).** 31 of 31 mutations turned their own named case red. In each one, the
  guarded phrase was replaced by `ZZMUTATEDZZ` in a worktree at 8878ba3, and the whole
  `tests/sprint.test.sh` was run. Two of the phrases ("as its own gate" and "belongs to an open
  ticket") wrap across a line in the raw file, so a literal replace missed them on the first pass.
  They were re-run with a whitespace-tolerant replace and went red too. That the guard matches
  across line breaks is the `section` flattening at work. The worktree was removed in the same turn.
- **AC8 (run).** The first whole-suite run (31 files, per-file form) had exactly one red, and it
  was mine. `tests/citations.test.sh` failed because develop's new paragraph cited the bold bullet
  "A stage may record what still needs filing". A citation must name a CONCURRENCY.md *heading*,
  and that bullet sits under *A stage writes only the ticket it holds*. Fixed in c537d1a, after which
  `tests/citations.test.sh` ran 46 passed, 0 failed, and the other 30 files were green on that run.
  FR4's own citation of the bullet cannot be written as a resolvable citation in skill prose.
- Review checklist: the change is prose plus presence guards. There is no code path, secret or
  input boundary. Each new rule states its failure in one clause (da524ce, run-20260922T031109Z).
- 2026-09-24 — verify (token 1b52): **FAIL on AC2 and AC5. Every other AC passes.** Both ACs say
  "guarded in `tests/sprint.test.sh`", and each has a clause that no case guards. Deleting that
  clause from `skills/sprint/SKILL.md` leaves the file at `303 passed, 0 failed, 0 skipped`:
  - **AC5 "names that ticket".** Replace `the proposal names that ticket` (in the proposal
    section's owned-red sentence) with ZZMUT: 303 passed, 0 failed. `belongs to an open ticket`
    and `mints no row` are guarded. The naming is not.
  - **AC2 "amend and decline".** Replace the red-baseline list's third bullet
    (`**amend** or **decline**, as above.`) with ZZMUT: 303 passed, 0 failed. `repair first`,
    recommended and `**waive**` are guarded. A guard on `**decline**` alone would not fire, because
    the earlier three-answer list in the same section already contains `**decline**`.
  - **The constraint for develop.** Add presence cases scoped to the proposal section, and prove
    each one by mutation: removing only that clause must turn only that case red. One case covers
    the owned red naming its ticket (AC5). One covers the red-baseline answer list offering amend
    and decline (AC2), and it must go red when that bullet alone is removed. The prose is correct
    and stays as it is. This is guard work only.
  - The mechanism was cleared: the prose for all eight ACs is present and says what the ACs say.
    The failure is in the guards alone.
- 2026-09-24 — develop (token 9c22), re-entry on verify 1b52's FAIL. Guard work only; the prose
  is unchanged. Two presence cases were added to `tests/sprint.test.sh` in da2c1c7, each scoped to
  the proposal section:
  - **AC2** asserts the whole bullet `**amend** or **decline**, as above`, not `**decline**` alone.
    The three-answer list earlier in the section already offers decline, so a guard on the word
    alone would stay green (verify's point).
  - **AC5** asserts `the proposal names that ticket`.
  - **Mutation (run).** In a throwaway worktree at da2c1c7, each clause was replaced with `ZZMUT`
    (checked to occur exactly once first), and `tests/sprint.test.sh` was run whole. Each mutation
    turned its own named case red and no other 0180 case. The 0165 self-copy case also went red,
    as expected, so each run read 303 passed, 2 failed. The control run was 305 passed, 0 failed.
    The worktree was removed in the same turn.
  - **Whole suite (run).** The per-file form ran on the working tree at da2c1c7. All 31 files
    reported `0 failed`, and `tests/sprint.test.sh` read 305 passed, 0 failed.
- 2026-09-25 — verify (token eb65): **FAIL on AC3, AC4 and AC6. AC1, AC2, AC5, AC7 and AC8 pass.**
  This pass enumerated mutations from the **AC text, clause by clause**, as well as from the guard
  block. All 36 guard mutations turned their own case red. Six clause mutations left
  `tests/sprint.test.sh` at `305 passed, 0 failed, 0 skipped`. Each clause below was replaced with
  ZZMUT in a worktree at 9f0cf0c, using whole-file, case-insensitive, whitespace-tolerant matching:
  - **AC3, "carries the `baseline_red` list".** Step 3 of `skills/sprint/SKILL.md`: replacing
    `with the `baseline_red` case list from `scope_confirmed`` stays green. So does replacing just
    `` `baseline_red` case list ``. The only Step 3 guard is `baseline red at <sha>, not yours`.
    That covers the SHA, not the list.
  - **AC4, "to mint a row".** Proposal section: removing both `gets a row, never` and
    `it mints a `type: bug` row whose `relates:` names the ticket that introduced the red` stays
    green.
  - **AC4, "runs that row alone to `next: done`".** Replacing `to `next: done`` stays green.
    `as its own gate` guards "alone" and nothing else.
  - **AC4, "re-runs the baseline before any other dispatch".** Replacing
    `nothing else in the confirmed scope is dispatched until it is green` stays green.
    `runs the baseline again` guards the re-run, not the ordering.
  - **AC6, "routes the red to a `FINDINGS.md` … entry".** Step 5 of `skills/develop/SKILL.md`:
    replacing `` `FINDINGS.md` `` (both occurrences) stays green. `still needs a row` guards the
    wording of the entry, not where it goes.
  - **The constraint for develop.** Add one presence case per clause above: five cases, each scoped
    to the section it lives in (Step 3; the proposal section ×3; develop Step 5). Prove each by
    removing only that clause, which must turn only that case red. The prose is correct and stays
    as it is. This is guard work only, and the mechanism was cleared.
  - **The list is exhaustive.** This pass walked every clause of AC1–AC8 against a guard. The
    clauses listed above are the only unguarded ones, so a re-entry that covers them should not
    produce a fourth round. Rounds 1 and 2 each fixed only the clauses the previous verify named,
    because the send-back listed only those.
  - Not ACs, recorded for completeness: FR4's `A red your dispatch prompt lists as `baseline_red`
    is not yours.` (develop Step 5) is also unguarded. No AC names it.
- 2026-09-25 — develop (token 3d16), re-entry on verify eb65's FAIL. Guard work only, with the
  prose unchanged. In 6282974, five presence cases were added to `tests/sprint.test.sh`, one for
  each clause verify listed. Each case is scoped to the section the clause lives in, and each
  phrase was checked to occur exactly once in its flattened section:
  - **AC3** (Step 3): `with the `baseline_red` case list from `scope_confirmed``.
  - **AC4** (the proposal section): `mints a `type: bug` row`; `to `next: done``;
    `nothing else in the confirmed scope is dispatched until it is green`. The existing
    `runs the baseline again` case was relabelled to "and the baseline is re-run", because the
    ordering half of its old label now belongs to the new case.
  - **AC6** (develop Step 5): `Park a `FINDINGS.md` entry`.
  - **Mutation (run).** The sweep ran in a throwaway worktree at 6282974. Each clause was replaced
    with `ZZMUT` using a case-insensitive, whitespace-tolerant match that first had to find exactly
    one occurrence in the whole file. The AC4 mint mutation removed the whole
    `mints a `type: bug` row whose `relates:` names the ticket that introduced the red`. Each of
    the five runs read `308 passed, 2 failed`: that clause's own new case, plus the expected 0165
    AC2 self-copy case. No other 0180 case went red. The control ran before and after the sweep,
    and both runs read `310 passed, 0 failed, 0 skipped`. The worktree was removed in the same
    turn.
  - **Not guarded, and deliberately so:** FR4's `A red your dispatch prompt lists as
    `baseline_red` is not yours.` No AC names it (verify eb65), and a guard on it would widen the
    contract this re-entry was scoped to.
  - **Whole suite (run).** The per-file form ran on the working tree at 6282974. All 31 files read
    `0 failed`, and `tests/sprint.test.sh` read `310 passed, 0 failed, 0 skipped`.
- 2026-09-25 — verify (token 391b): **FAIL on AC4 and AC6. AC1, AC2, AC3, AC5, AC7 and AC8 pass.**
  The sweep ran in a sibling worktree at 2cb26e4. It covered 38 guard mutations (every
  `guard_says` phrase in the 0180 block, plus the three AC7 greps) and 19 clause mutations taken
  from the AC text. Each clause was replaced with ZZMUT using a case-insensitive, whitespace-tolerant
  match, and the diff was checked non-empty; then `tests/sprint.test.sh` ran whole. All 38 guard
  mutations turned their own named case red, and no other 0180 case. The two gaps below are AC
  *qualifiers*: the phrase that scopes a guarded predicate. Deleting one leaves the qualifier absent
  from the whole section and the file at `310 passed, 0 failed, 0 skipped`:
  - **AC6, "forbids fixing a red no ticket owns".** In Step 5 of `skills/develop/SKILL.md`, replace
    `A red no ticket owns` (the bold rule's subject) with ZZMUT, leaving `**ZZMUT is never fixed
    under the claim you hold**`: 310 passed, 0 failed. The phrase occurs once in that section, and
    `unowned` occurs nowhere, so the rule no longer says what it forbids. A red the session *owns*
    must be fixed under its claim, so this qualifier is the rule. The guard
    `never fixed under the claim you hold` pins only the predicate.
  - **AC4, "Given a red no open ticket owns".** In the proposal section of `skills/sprint/SKILL.md`,
    replace `A red no open ticket owns gets` with ZZMUT: 310 passed, 0 failed. The phrase occurs once
    in that section. AC5's owned side (`belongs to an open ticket`) is guarded. The unowned condition
    that triggers the mint is not.
  - **The constraint for develop.** Add two presence cases, each scoped like its neighbours: one
    asserting `a red no ticket owns is never fixed` in develop Step 5 (AC6), and one asserting
    `a red no open ticket owns` in the proposal section (AC4). Both are case-insensitive through
    `guard_says`. Prove each by removing only that qualifier: that must turn only that case red,
    apart from the expected 0165 self-copy case. The prose is correct and stays as it is. This is
    guard work only, and the mechanism was cleared.
  - **The test this pass applied, so a re-entry can check it is finished.** A clause mutation that
    stays green counts as a gap only if the qualifier the AC names no longer occurs anywhere in its
    section. The other 15 clause mutations stayed green and pass that test. What remains in each
    section still states what the AC names:
    - AC1 "unit suite": `commands.unit_by_file` is still named.
    - AC1 "throwaway": `git worktree add --detach` and `removed in the same turn` are still there.
    - AC1's fallback: the `lower bound` sentence is still there.
    - AC1 "Report the tally": `each red file and case, or green — on the depth line`.
    - AC2 "A red baseline": `baseline` and `the red` are still in the section.
    - AC2 "The waiver is recorded": the waive bullet still says `in scope_confirmed as baseline_red`.
    - AC3's bullet subject: two separate deletions, and the quoted line plus the list are guarded.
    - AC4 "dispatch": `one queue session` is still there.
    - AC4 Step 8: the exception names repair first in two places, and each mutation removed only one.
    - AC5 "introducing commit": it occurs twice more.
    - AC6 "the outcome's": `escalation` is guarded.
    - AC7 "the reporting form": the key is still named in that sentence.
    Nothing else in AC1–AC8 is unguarded under that test.

- 2026-09-25 — develop (token 9849), re-entry on verify 391b's FAIL, round 5. Guard work only; the
  prose is unchanged. Per develop Step 5 / verify Step 3, this pass built a **clause table over all
  of AC1–AC8**, not only 391b's two gaps. Each row was mutated in a sibling worktree: every
  occurrence of the prose phrase inside that section only (case-insensitive, whitespace-tolerant)
  became ZZMUT. Then `tests/sprint.test.sh` ran with `SPRINT_TEST_CHILD=1 SPRINT_SKIP_PROBE=1`, so
  the 0165 self-copy and the paid probe were out of the tally. Gap test: green, and the phrase is
  absent from the section afterwards. **Run, not reasoned** — both sweeps below were executed.
  - **The gap test was applied to the phrase verbatim.** 391b let a row pass where a *different*
    phrase in the section said the same thing, e.g. "`commands.unit_by_file` still named" for "unit
    suite". Under the verbatim reading, 11 more rows were gaps, besides 391b's two. Parked in
    `FINDINGS.md` as an ambiguity in the gap test.
  - Sweep 1 at 74638be (the claim commit; tests unchanged since 2cb26e4): 51 rows, control `306 passed, 0 failed, 1 skipped`
    before and after. 13 gaps (marked **gap** below), all now guarded in ca4c530 (14 new cases:
    the 13, plus Step 8's rule `or writes a ticket` split from its exception).
  - Sweep 2 at ca4c530: every row red except AC4.given-answer, which is not a gap (`repair first`
    survives in the section). Control `320 passed, 0 failed, 1 skipped` before and after. The
    worktree read clean, and it was removed in the same turn.

  | Row | Section | Phrase mutated | Sweep 1 (pre) | Sweep 2 (ca4c530) |
  |---|---|---|---|---|
  | AC1 predicate: baseline check | sprint Step 1 | `the baseline` | red | red |
  | AC1 object: unit suite | sprint Step 1 | `unit suite` | **gap** | red |
  | AC1 qualifier: at HEAD | sprint Step 1 | ``at `HEAD` `` | red | red |
  | AC1 qualifier: throwaway worktree | sprint Step 1 | `throwaway worktree` | **gap** | red |
  | AC1 qualifier: detached worktree | sprint Step 1 | `git worktree add --detach` | red | red |
  | AC1 object: unit_by_file | sprint Step 1 | `commands.unit_by_file` | red | red |
  | AC1 qualifier: prefers | sprint Step 1 | `where it is unset` | **gap** | red |
  | AC1 predicate: reports the tally | sprint Step 1 | `the tally` | **gap** | red |
  | AC1 destination: depth line | sprint Step 1 | `on the depth line` | red | red |
  | AC2 Given: a red baseline | proposal | `a red baseline` | **gap** | red |
  | AC2 predicate: blocks the proposal | proposal | `blocks the proposal` | red | red |
  | AC2 qualifier: not ending the run | proposal | `does not end the run` | red | red |
  | AC2 object: repair first | proposal | `repair first` | red | red |
  | AC2 qualifier: recommended | proposal | `— recommended` | red | red |
  | AC2 object: waive | proposal | `**waive**` | red | red |
  | AC2 object: amend and decline | proposal | `**amend** or **decline**, as above` | red | red |
  | AC2 predicate: waiver is recorded | proposal | `The waiver is recorded` | **gap** | red |
  | AC2 object: baseline_red | proposal | `` `baseline_red` `` | red | red |
  | AC2 destination: scope_confirmed | proposal | ``in `scope_confirmed` `` | red | red |
  | AC3 qualifier: whose baseline red was waived (round 6: was the Given row, but restates it) | sprint Step 3 | `baseline red was waived` | **gap** | red |
  | AC3 Given: a waived red (round 6, verbatim) | sprint Step 3 | `a waived red` | not in the table | red (62b4b3d) |
  | AC3 predicate: the prompt carries | sprint Step 3 | `every stage prompt quotes it` | **gap** | red |
  | AC3 object: the list | sprint Step 3 | `` `baseline_red` case list `` | red | red |
  | AC3 object: the SHA | sprint Step 3 | `baseline red at <sha>` | red | red |
  | AC3 qualifier: not the stage's own | sprint Step 3 | `not yours` | red | red |
  | AC4 Given: a red no open ticket owns | proposal | `a red no open ticket owns` | **gap** (391b) | red |
  | AC4 Given: the answer repair first (round 6, verbatim; was `On repair first`, which the prose no longer says) | proposal | `the answer repair first` | green, survives: not a gap (under the old reading) | red (62b4b3d) |
  | AC4 predicate: dispatches one queue session | proposal | ``one `queue` session`` | red | red |
  | AC4 predicate: mint a row | proposal | ``mints a `type: bug` row`` | red | red |
  | AC4 qualifier: ranked first | proposal | `rank first` | red | red |
  | AC4 qualifier: alone | proposal | `as its own gate` | red | red |
  | AC4 destination: next: done | proposal | ``to `next: done` `` | red | red |
  | AC4 predicate: re-runs the baseline | proposal | `runs the baseline again` | red | red |
  | AC4 qualifier: before any other dispatch | proposal | `nothing else in the confirmed scope is dispatched until it is green` | red | red |
  | AC4 object: the never-writes-a-ticket rule | sprint Step 8 | `writes a ticket` | **gap** | red |
  | AC4 predicate: its one exception | sprint Step 8 | `one exception` | red | red |
  | AC4 object: the exception is repair first | sprint Step 8 | `repair first` | **gap** | red |
  | AC5 Given: a red whose introducing commit belongs to an open ticket (round 6, the whole clause) | proposal | `a red whose introducing commit belongs to an open ticket` | not in the table | red (62b4b3d) |
  | AC5 qualifier: introducing commit (verify 3d48) | proposal | `introducing commit` | not in the table | red (62b4b3d) |
  | AC5 part of Given: belongs to an open ticket | proposal | `belongs to an open ticket` | red | red |
  | AC5 predicate: names that ticket | proposal | `the proposal names that ticket` | red | red |
  | AC5 predicate: mints no row | proposal | `mints no row` | red | red |
  | AC6 Given: a red no ticket owns | develop Step 5 | `a red no ticket owns` | **gap** (391b) | red |
  | AC6 predicate: forbids fixing under the held claim | develop Step 5 | `never fixed under the claim you hold` | red | red |
  | AC6 object: da524ce | develop Step 5 | `da524ce` | red | red |
  | AC6 destination: FINDINGS.md | develop Step 5 | `` `FINDINGS.md` entry `` | red | red |
  | AC6 object: still needs a row | develop Step 5 | `still needs a row` | red | red |
  | AC6 qualifier: the outcome's | develop Step 5 | `the outcome's` | **gap** | red |
  | AC6 destination: escalation | develop Step 5 | `` `escalation` `` | red | red |
  | AC7 object: unit_by_file per-file form | config.yml | `do "$t" \|\| true; done` | red | red |
  | AC7 qualifier: commands.unit unchanged | config.yml | `do "$t" \|\| exit 1; done` | red | red |
  | AC7 object: verify names the key | skills/verify/SKILL.md | `` `commands.unit_by_file` `` | red | red |
  | AC7 qualifier: where it says the reporting form | skills/verify/SKILL.md | `the reporting form` | **gap** | red |

  AC1's meta clause ("removing any one of them turns it red") is what these sweeps are. AC8 is a
  suite run, not a phrase, and is not in the table.
  - **Whole suite (run).** The per-file form ran on the working tree at ca4c530. All 31 files read
    `0 failed`. `tests/sprint.test.sh` read `324 passed, 0 failed, 0 skipped`, and
    `tests/skill-size.test.sh` read `27 passed, 0 failed`.
  - FR4's `baseline_red` sentence in develop Step 5 is still unguarded. No AC names it (eb65), so
    it is not a row in the table.

- 2026-09-25 — verify (token 3d48), round 5: **FAIL on AC5 alone, from a table omission. AC1–AC4 and AC6–AC8 pass.**
  This pass reused develop 9849's clause table and re-ran every row itself in a sibling worktree
  at f655dc3. It did not divide the sentences a new way. Method: every occurrence of the row's
  phrase inside its section became ZZMUT (case-insensitive, whitespace-tolerant). The diff was
  checked non-empty, with `left=0` occurrences. Then `tests/sprint.test.sh` ran with
  `SPRINT_TEST_CHILD=1 SPRINT_SKIP_PROBE=1`.
  - **The table as written: 49 of 50 rows red.** The 50th is `AC4 Given: the answer repair first`
    (`On repair first`). It stays at `320 passed, 0 failed, 1 skipped`, but `repair first` still
    occurs in the section, so under the gap test it is not a gap. Develop's result reproduces.
    The notes say "51 rows", but the table has 50. That is a count drift, not a missing row.
  - **Table omission, and a gap: AC5 "whose introducing commit belongs to an open ticket".** The
    table's AC5 Given row pins `belongs to an open ticket` only. The qualifier in front of it,
    `introducing commit`, has no row. Replacing both occurrences of `introducing commit` in the
    proposal section of `skills/sprint/SKILL.md` (replaced=2, left=0) leaves the file at
    `320 passed, 0 failed, 1 skipped`. After the mutation the owned-red sentence reads "A red
    whose ZZMUT belongs to an open ticket is owned", so it no longer says what makes the red owned.
  - **Table omission, not a gap: AC1 predicate "runs" (the unit suite).** Replacing
    `Run the baseline:` in Step 1 stays green, but `run` (`Run `commands.unit_by_file``) and
    `unit suite` both survive in the section.
  - No other AC phrase lacks a row. The When clauses ("when Step 1 is read", "when a stage dispatch
    is read", "its red-attribution section") are locators, not clauses.
  - **The constraint for develop.** Add one presence case, scoped to the proposal section through
    `guard_says`, asserting `whose introducing commit belongs to an open ticket`. Prove it by
    replacing `introducing commit` in the proposal section alone: that case must turn red, and no
    other 0180 case. The prose is correct and stays as it is. This is guard work only, and the
    mechanism was cleared. The exhaustive list under the gap test is that one clause.

- 2026-09-25 — develop (token bb92), re-entry on verify 3d48's FAIL, round 6. The table above is
  corrected in place. Rows marked *round 6* were added or rewritten in this pass. The count is now 53
  rows: 50 as verify counted them, then AC3 +1 and AC5 +2.
  - **Rule applied.** develop Step 5, as of the a3b1a3e skill: the gap test is verbatim, and a Given
    row is the whole Given clause, qualifier included, with a guard that asserts all of it.
    Every Given clause in AC1–AC8 was re-checked against it:
    - AC1 `skills/sprint/SKILL.md`, AC6 `skills/develop/SKILL.md`, AC7 `.claude/backlog/config.yml`
      and AC8 "the change" name a file or the diff, not a condition. Each is the file its cases read,
      so it has no prose phrase to mutate. These are locators, not rows, as verify 3d48 ruled for the
      When clauses.
    - AC2 "a red baseline": verbatim and already guarded. No change.
    - AC3 "a waived red": **failed the rule.** The row pinned `baseline red was waived`, which
      restates the Given. The AC's own words appeared nowhere in Step 3, so no guard could assert
      them. The prose `re-separates the old red` is now `re-separates a waived red`, and a guard was
      added. The old row stays as a qualifier row, still guarded.
    - AC4 "a red no open ticket owns and the answer repair first": two conjuncts, one row each.
      "a red no open ticket owns" was already verbatim and guarded. **"the answer repair first"
      failed the rule**: the row pinned `On repair first`, and round 5 passed it only because
      `repair first` survives elsewhere in the section. The prose `On repair first, dispatch` is now
      `On the answer repair first, dispatch`, and a guard was added.
    - AC5 "a red whose introducing commit belongs to an open ticket": **verify 3d48's omission.**
      The row pinned only `belongs to an open ticket`. A guard now asserts the whole clause.
  - **Two prose edits, not guard work only.** Verify 3d48 said the prose stays, but that was about
    AC5. Under the verbatim rule, a Given the prose only paraphrases cannot be guarded until the
    prose uses the AC's words. Both edits are rewordings with the same meaning. They are in 62b4b3d
    beside the three new cases in `tests/sprint.test.sh`.
  - **Given-row sweep (run).** A sibling worktree at 62b4b3d. Each phrase was replaced with ZZMUT
    inside its section only (case-insensitive, whitespace-tolerant), then
    `SPRINT_TEST_CHILD=1 SPRINT_SKIP_PROBE=1 tests/sprint.test.sh` ran. Control:
    `323 passed, 0 failed, 1 skipped`, before and after. Every row is red:
    - `a waived red` (1, left=0): only the new AC3 case fails.
    - `baseline red was waived`: only its own AC3 case fails.
    - `a red baseline`: only its own AC2 case fails.
    - `a red no open ticket owns`: only its own AC4 case fails.
    - `the answer repair first`: only the new AC4 case fails.
    - `introducing commit` (2, left=0): only the new AC5 case fails. This is verify 3d48's proof.
    - The whole AC5 clause, and `belongs to an open ticket`: both AC5 Given cases fail.
    The worktree was removed in the same turn.
  - **The other rows are reasoned, not rerun.** Their phrases are untouched in 62b4b3d. The one row
    whose phrase went, `On repair first`, is replaced above.
  - **Whole suite (run).** The per-file form ran on the working tree before 62b4b3d was committed,
    with the same bytes. All 31 files read `0 failed`: `tests/sprint.test.sh`
    `327 passed, 0 failed, 0 skipped`, and `tests/skill-size.test.sh` `27 passed, 0 failed`.

## QA evidence

Conventions: ../ai-building-conventions
Level: `qa_level: unit`. The command run was `commands.unit_by_file`, verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`. It ran in a sibling worktree at f655dc3. The
Step 2 dirty set was `?? .claude/backlog/runs/`. The repo copy executed, because the guards read
the repo files. The mutation sweep ran in a second sibling worktree at f655dc3, and both worktrees
were removed before the verdict.

| Check | How | Result |
|---|---|---|
| AC1 | 9 table rows in Step 1, all red (`319 passed, 1 failed, 1 skipped` each). Omitted row "runs": green, but `run` and `unit suite` survive in the section. | PASS |
| AC2 | 10 table rows in the proposal section, all red. | PASS |
| AC3 | 5 table rows in Step 3, all red. | PASS |
| AC4 | 11 of 12 table rows red. `On repair first` is green, but `repair first` survives in the section, so it is not a gap. | PASS |
| AC5 | 3 table rows, all red. **Omitted row `introducing commit` (both occurrences in the proposal section, left=0): green, and the phrase is gone from the section.** | **FAIL.** `320 passed, 0 failed, 1 skipped` |
| AC6 | 7 table rows in develop Step 5, all red. | PASS |
| AC7 | 4 table rows (`.claude/backlog/config.yml` ×2, `skills/verify/SKILL.md` ×2), all red. | PASS |
| AC8 | The whole suite, per file, at f655dc3. | PASS. 31 files, and every tally reads `0 failed`: `tests/sprint.test.sh` `324 passed, 0 failed, 0 skipped`, `tests/skill-size.test.sh` `27 passed, 0 failed`, `tests/citations.test.sh` `46 passed, 0 failed` |
| Sweep control | Unmutated `tests/sprint.test.sh` (child mode, probe skipped) before and after the 52-mutation sweep. The mutation worktree read clean afterwards. | `320 passed, 0 failed, 1 skipped` both times |
| NFRs | There is no NFR table. Always-on pass from `CONVENTIONS_CORE.md`: prose and presence guards only, with no secrets, company material or absolute paths. | PASS |

Evidence set: `skills/sprint/SKILL.md`, `skills/develop/SKILL.md`, `skills/verify/SKILL.md`,
`.claude/backlog/config.yml`, `tests/sprint.test.sh`, `tests/*.test.sh`. The dirty set at Step 2
and at the verdict was `.claude/backlog/runs/` (untracked). The intersection is empty.
