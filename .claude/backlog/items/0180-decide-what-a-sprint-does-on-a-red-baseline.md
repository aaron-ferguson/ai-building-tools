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
claimed_by: "9c22"
claimed_at: 2026-09-24T15:08:30Z
touches:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
  - skills/develop/SKILL.md
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

## QA evidence

Conventions: ../ai-building-conventions
Level: `qa_level: unit`. The command run was `commands.unit_by_file`, verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`. It is the reporting form of `commands.unit`,
used so that every file reports. HEAD at Step 2 was 6e39cc8, and the dirty set was
`?? .claude/backlog/runs/`.

| Check | How | Result |
|---|---|---|
| AC1 | 8 cases in `tests/sprint.test.sh`, 0180 block. Each guarded phrase in `skills/sprint/SKILL.md` Step 1 was replaced in a worktree at 6e39cc8 (case-insensitive and whitespace-tolerant, matching `says_ci`). | PASS. 8/8 mutations turned their named case red. |
| AC2 | 8 cases on the proposal section, mutated the same way. The unguarded clause was also mutated. | **FAIL.** 8/8 guarded phrases turn red. Removing amend/decline from the red-baseline list leaves 303 passed, 0 failed. |
| AC3 | Case `baseline red at <sha>, not yours`, Step 3. | PASS. The mutation turns it red. |
| AC4 | 5 cases: proposal section ×4 and Step 8 `one exception`. | PASS. 5/5 turn red. |
| AC5 | 2 cases: `belongs to an open ticket` and `mints no row`. The unguarded clause was also mutated. | **FAIL.** 2/2 turn red. Removing "the proposal names that ticket" leaves 303 passed, 0 failed. |
| AC6 | 4 cases on `skills/develop/SKILL.md` Step 5. | PASS. 4/4 turn red. |
| AC7 | 3 cases on `.claude/backlog/config.yml` and `skills/verify/SKILL.md`. | PASS. 3/3 turn red. `commands.unit` is unchanged (read). |
| AC8 | The whole suite, per file, at 6e39cc8. | PASS. 31 files and every tally reads `0 failed`: `tests/sprint.test.sh` 303 passed, 0 failed, 0 skipped; `tests/skill-size.test.sh` 50 passed, 0 failed; `tests/citations.test.sh` 46 passed, 0 failed. |
| Sweep control | Unmutated `tests/sprint.test.sh` in the worktree, after all mutations. | 303 passed, 0 failed, 0 skipped |
| Mutation side-effect | Each mutation also turns the 0165 self-copy case red, because that case re-runs this file. That is expected. | 2 failed per mutation: the named case plus the 0165 case. |
| NFRs | The ticket has no NFR table. Always-on pass from `CONVENTIONS_CORE.md`: the change is prose and presence guards, with no secrets, company material or absolute paths. What it newly makes reachable is one automated `queue` dispatch, and only after a person picks repair first. The text bounds it to one session. | PASS. |

Evidence set: `skills/sprint/SKILL.md`, `skills/develop/SKILL.md`, `skills/verify/SKILL.md`,
`.claude/backlog/config.yml`, `tests/sprint.test.sh`, `tests/skill-size.test.sh`, and `tests/*.test.sh`
(AC8). The dirty set was `.claude/backlog/runs/`, which is untracked, so the intersection is
empty. HEAD moved mid-pass to e9f5533 (0178's claim, design and hand-off, plus a FINDINGS line).
None of those commits touched the evidence set. The copy that executed was the repo copy. The
change is skill prose, and the guards read the repo files.
