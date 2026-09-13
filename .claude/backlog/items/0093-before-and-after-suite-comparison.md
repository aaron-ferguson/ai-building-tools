---
id: "0093"
title: Give develop and verify a working recipe for a before-and-after suite comparison
type: debt
next: develop
status: ready
qa_level: verify
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0054"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
---

## Problem

Both skills tell a session to compare a check before and after a change — `develop`'s throwaway
worktree for *"is this red mine?"*, `verify` Step 3's mutation sweep, and any AC of the shape *"the
output is unchanged"*. On this repo that comparison has three gotchas, none of them recorded, and
**three sessions in a row hand-built throwaway comparison scaffolding** to rediscover them.

1. **A suite copied out of the repo cannot run.** Every suite resolves `ROOT` from its own location,
   so the obvious move — `git show HEAD:tests/x.test.sh > $SCRATCH/x.sh && sh $SCRATCH/x.sh` — exits
   2 with *"no claim script at …/scratchpad/skills/…"*. That is not a red, it is a different error,
   and a session in a hurry reads it as one. The copy has to land inside the repo tree
   (`tests/.head-x.sh`, dot-prefixed so the `tests/*.test.sh` loop does not pick it up) and be
   removed in the same turn.

2. **`git archive HEAD | tar -x` alone gives a directory that is not a repository.** Extracting the
   tree to compare against gives 55 passed / 1 failed: the suite's tracked-file guards use
   `git ls-files` and fail loudly outside a repo. That is correct behaviour, and a session can read
   the 1 as a real red. The copy needs a `git init` plus a commit before the suite will run.
   `verify` Step 3 names only the in-tree route and its `git checkout -- <path>` restore, which is
   the route that is unsafe here: the files under test are shared prose another live session
   predicts — `0051`'s evidence set was `MEASUREMENT.md` and `README.md`, both in `0053`'s
   `expects:`.

3. **The obvious base commit is the wrong one.** Checking `0053`'s AC1 (*output unchanged*) meant
   running the pre-`0053` and post-`0053` copies of three suites against today's tree. The commit
   before the implementation was wrong, because two of the three suites had since been changed by
   **another ticket** (`0044`), so the diff showed `0044`'s cases as `0053`'s noise. The isolating
   comparison is **pre-boundary against post-boundary, both replayed against the current tree** —
   and neither of them is the working copy.

4. **A worktree outside the parent directory cannot resolve the conventions.** `config.yml`'s
   `conventions.path: ../ai-building-conventions` resolves relative to the repo root, so a worktree
   placed anywhere but beside the real checkout makes `tests/citations.test.sh` report *"no
   conventions directory resolved from config.yml"* — one failure in twenty, on a guard that is
   correct to fail. Observed 2026-09-05 pre-flighting a findings sweep in a scratchpad worktree,
   where it read as a red caused by the change under test. The fix is a symlink beside the
   worktree, or placing the worktree as a sibling of the real checkout.

`develop` already covers the interleaved-commits case with a cherry-pick replay, and `verify`
already covers the e2e worktree. Neither covers a shell suite that resolves its own root, and
neither covers base selection for an *output-unchanged* comparison as distinct from a
*whose-red-is-this* one.

## Functional requirements

- FR1 — `develop` and `verify` state the ROOT-resolution constraint: a suite copy used for
  comparison lives **inside the repo tree**, dot-prefixed so the `tests/*.test.sh` loop skips it,
  and is removed in the same turn it is created.
- FR2 — Both state that an extracted tree used for comparison needs `git init` plus a commit before
  the suite will run, and why — the tracked-file guards use `git ls-files` and fail loudly outside a
  repository, which is correct behaviour and reads as a red.
- FR3 — Both distinguish the two comparisons and name the base for each: *whose red is this* takes
  the commit before your first (already covered), and *is the output unchanged* takes
  **pre-boundary against post-boundary, both replayed against the current tree**.
- FR4 — The rule is written once and cited from the second skill rather than copied, per
  `CONVENTIONS_CORE.md`'s context-rent rule; the two skills must not carry two copies that can
  drift.
- FR6 — Both state that a worktree or extracted tree used for comparison must be able to resolve
  `conventions.path`, and how — the path is relative to the repo root and every conventions-citing
  guard fails loudly without it.
- FR5 — A guard asserts that both skills reach the rule — the code that keeps FR1–FR3 from
  surviving in only one of them.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The three gotchas are recorded as mechanisms with the error text each produces, since each was misread as a red rather than as a setup fault | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/develop/SKILL.md` and `skills/verify/SKILL.md`, when each is searched for
  the dot-prefixed in-repo copy rule, then exactly one of them states it and the other cites it. Red
  if both state it in full, which is the drift FR4 forbids, or if neither does.
- [ ] AC2 — Given a session following the written recipe, when a suite copy is placed at
  `tests/.head-x.sh` and `for t in tests/*.test.sh; do echo "$t"; done` is run, then `.head-x.sh` is
  not listed. Red-making change: dropping the dot prefix from the rule, after which the loop picks
  the copy up and the comparison runs the copy twice.
- [ ] AC3 — Given the written recipe, when the `git archive` clause is read, then it names
  `git ls-files` as the reason the extracted tree needs a repository. Red-making mutation: removing
  the `git ls-files` mention, leaving a rule with no way to recognise the symptom it prevents.
- [ ] AC4 — Given the written recipe, when the base-selection clause is read, then it names
  pre-boundary and post-boundary as the two commits and the current tree as what both are replayed
  against. Red-making mutation: replacing "post-boundary" with "the working copy" — the guard
  asserting all three terms reddens.
- [ ] AC5 — Given FR5's guard, when `skills/verify/SKILL.md`'s citation of the rule is deleted, then
  the guard fails and names `verify`. Red if it passes.
- [ ] AC7 — Given the written recipe, when the worktree clause is read, then it states that
  `conventions.path` is relative to the repo root and names the symlink or sibling placement as the
  fix. Red-making mutation: deleting the word `relative`, which leaves a rule that does not say why
  the location matters and reddens the guard asserting the term.
- [ ] AC6 — Given both skills after the change, when `tests/skill-size.test.sh` and
  `tests/citations.test.sh` run, then each reports `0 failed`.

## QA plan

- **Why that level:** no runner applies — the deliverable is prose in two skills plus one guard. The
  scripted assertions are FR5's guard and the greps in AC1, AC3 and AC4.
- **Specific checks:** the new guard, `tests/skill-size.test.sh`, `tests/citations.test.sh`. Then
  actually run the recipe once end to end on a real suite, since a recipe that is merely written
  down is the failure this item exists to fix. For AC7, actually place a worktree outside the parent
  directory and confirm `tests/citations.test.sh` reds, then apply the documented fix and confirm it
  greens — the recipe is only worth having if it clears a red a session would otherwise misread.

## Out of scope

- The cherry-pick replay for interleaved commits, and the flake-rate rule — both already in
  `develop` Step 5 and correct.
- The `e2e` worktree prescription in `verify`, which `0083` is deciding.
- Automating the comparison. This item writes the recipe; whether it becomes a script is `0048`'s
  decision surface.

## Notes & decisions

- Routed to `develop`: all three answers were reached and recorded by the sessions that hit them. No
  decision blocks the criteria; what is missing is that the answers live in three `FINDINGS.md`
  entries rather than in the two steps that send sessions there.
- **Amended 2026-09-05, before any claim.** A fourth gotcha was found pre-flighting the sweep that
  filed this item, in the worktree that pre-flight used. Re-checked against the wider scope, per
  `queue` Step 1: `size` stays `m` — it is one more clause in a list the item already writes, not a
  new surface; the QA plan's named checks gain the AC7 run; *Out of scope* is unchanged, since the
  conventions path is part of making a comparison copy run and not part of automating it.
- Which skill holds the rule and which cites it is FR4's constraint but not a design question — the
  comparison is run by both, and `develop` Step 5 already carries the neighbouring worktree
  guidance, so it is the natural home.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Three more gotchas: a scratchpad worktree has no sibling `../ai-building-conventions`, so `tests/citations.test.sh` fails environmentally until one `ln -s` is made (verify 0052); piping `config.yml`'s fail-fast `unit` line into `tail` reports tail's exit code and discards the verdict (verify 0052); and the file-by-file run exceeds the 120s tool timeout, whose recovery (background plus sentinel) `verify` names only in Step 3 (0132 FR4). Also: relocating a suite to point it at another copy fails because `ROOT` derives from `$0` (develop 2026-09-10).
