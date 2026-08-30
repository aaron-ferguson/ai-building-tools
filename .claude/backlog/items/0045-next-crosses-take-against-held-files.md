---
id: "0045"
title: Cross the take loop against the held file set in next
type: bug
next: verify
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0034", "0036", "0007", "0038", "0050"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`./next <stage>` prints `TAKE` on a row whose `expects:` set is held by another session, and it
prints the proof four lines below in the same output. The take loop (`next:680-700`) filters on
stage, `blocked_by` and the Status column; `show_claimed` (`next:344`) runs afterward and
independently. Neither consults the other, though the loop already resolves and prints the
candidate's `expects:` on the very next line.

Three observed instances, all on 2026-08-25:

- Every `next: verify` row was held by one batched pass (`1a06c11`); every remaining `next: develop`
  row overlapped that pass's `touches:` — 0034 on 2 of 2 expected paths, 0036 on 4 of 11, 0007 on 4
  of 6. Nothing was developable. `./next develop` printed `TAKE 0034`, then printed the CLAIMED
  FILES block showing both of 0034's paths held by `0029`/`0026`/`0033`.
- `./next develop` printed `TAKE 0036` — whose `expects:` names `skills/verify/SKILL.md` — directly
  above a CLAIMED FILES block naming that same path, held by `c2e9`.
- `./next develop` offered `TAKE 0007` against `0038 [e1cb] touches: skills/queue/templates/next
  tests/next.test.sh`, claimed ninety seconds earlier; three of 0007's `expects:` are that same
  scope. **0038 was at `verify`**, which makes this the worse case: a QA pass runs the suite, and a
  develop session editing the files under it makes that verdict a statement about a tree that was
  never a commit, with nothing in either session's output revealing it.

Two consequences, and the second is worse. The verdict word contradicts the skill's own rule
(`develop` Step 1, *Check the file scope before you claim*) for a reader who trusts the first line.
And because the loop `break`s on the first stage match it cannot offer the next *clear* row either
— which is the thing Step 1 actually asks for. The prose is correct here; only the tool is wrong.

A fourth, smaller defect in the same output. For a held row with an empty `touches:` the block
prints `0026 [b7f1] none declared — assume held, ask` and stops. `assume held` is the right
instruction and an unusable one alone: the only description of that row's scope is its `expects:`,
which the script already parses for the row it offers and does not print for the rows it warns
about. Deciding 0005 was safe meant opening 0026's item file — the read Step 1 exists to avoid.

## Functional requirements

- FR1 — The take loop resolves the held file set (every `in-progress` row's `touches:`) **before**
  it selects, and does not print `TAKE` on a row whose `expects:` intersects it.
- FR2 — Where the topmost stage-matching row collides, the loop continues to the next stage-
  matching row rather than breaking, and offers the first one that is clear.
- FR3 — A row stepped over for collision is reported by id, naming the intersecting paths and the
  row that holds them, so the reader can see the judgement rather than only its result.
- FR4 — Where every stage-matching row collides, the output says so distinctly from "nothing is
  takeable at stage X", since the two mean different things to the reader and only one of them
  means the stage is empty.
- FR5 — The CLAIMED FILES block falls back to a held row's `expects:` when its `touches:` is empty,
  labelled as the weaker, predicted field, and keeps the existing `assume held, ask` instruction.
- FR6 — A held row at **any** stage is counted in the held set, not only `develop` — the 0007/0038
  instance was a collision with a live `verify` claim.
- FR7 — `.claude/backlog/next` is updated from the template in the same change, per
  `tests/backlog-scripts-installed.test.sh` AC2.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The new selection rule is stated where `./next --help` documents takeability, since `--help` currently defines it as stage + `blocked_by` only | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a queue where the topmost row at a stage has an `expects:` intersecting an
  `in-progress` row's `touches:`, when `./next <stage>` runs, then it does not print `TAKE` for
  that row.
- [ ] AC2 — Given that same queue with a lower row at the same stage whose `expects:` intersects
  nothing held, when `./next <stage>` runs, then it prints `TAKE` for that lower row.
- [ ] AC3 — Given a row stepped over for collision, when `./next <stage>` runs, then the output
  names that row's id, the intersecting path, and the id holding it.
- [ ] AC4 — Given a queue where every row at a stage collides, when `./next <stage>` runs, then the
  output distinguishes that case in words from an empty stage.
- [ ] AC5 — Given an `in-progress` row with an empty `touches:` and a non-empty `expects:`, when
  `./next <stage>` runs, then the CLAIMED FILES block prints that `expects:` labelled as predicted,
  and still says to assume held and ask.
- [ ] AC6 — Given an `in-progress` row at `verify`, when a `develop` row's `expects:` intersects
  it, then AC1 holds — the held set is not filtered by stage.
- [ ] AC7 — Given `.claude/backlog/next` compared against `skills/queue/templates/next`, when
  `tests/backlog-scripts-installed.test.sh` runs, then it passes.
- [ ] AC8 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.

## QA plan

- **Level:** unit — the deliverable is a shell script, and this project's `unit` command runs every
  `tests/*.test.sh`.
- **Why this level:** every AC is a fixture queue plus one invocation, which is exactly what
  `tests/next.test.sh` already does.
- **Specific checks:** `tests/next.test.sh` in full, then the whole suite. Each AC needs its own
  fixture rather than the live backlog. Confirm every mutation reached **the copy the harness
  runs** — `tests/next.test.sh` resolves it through `NEXT_SRC` at line 23, and mutating
  `.claude/backlog/next` instead returns a clean pass, which is what a check that cannot fail also
  returns.

## Out of scope

- **Deciding what to do when the collision is unavoidable.** This ticket makes the tool report what
  the reader must already work out by hand; it does not change the file-scope rule itself, and in a
  repo whose skill and reference files are structurally multi-writer the honest fix may be a
  different rule entirely. That is 0050.
- Bare `./next` printing the topmost *takeable* row alongside row 1 when they differ. Real, and a
  readability defect rather than a correctness one.
- Filtering on anything finer than whole-file intersection. Section-level overlap is not something
  `touches:` can express and a pathspec commit carries the whole file regardless.
- Changing `develop` Step 1's prose. It already states this outcome correctly.

## Notes & decisions

- Routed to `develop`: the data needed is already resolved inside the same process on the same
  pass, `develop` Step 1 already states the rule the tool must implement, and every FR names an
  observable output. Nothing is undecided — only unwritten.
- FR2's "continue rather than break" is the load-bearing half. Suppressing the wrong `TAKE` without
  it would leave a session correctly warned and still with nothing to do, which is the current
  outcome by a slower route.

### Built 2026-08-30 — what the implementation turned up

- **`contains_word` and `paths_overlap` already existed, inside the `--drive` block.** 0038 wrote
  them for gate batching, which asks the same question this ticket asks — do two path lists meet —
  from the other end. They are now shared readers, and `paths_shared` sits beside them because the
  two callers want different answers from one comparison: `--drive` needs *whether* the lists meet,
  the take loop needs *which paths did*, since a collision stated without its path is a verdict the
  reader cannot check.

- **FR1 says `touches:` and the CLAIMED FILES fallback says `expects:`, and that asymmetry is the
  design, not an oversight.** A row is refused only on a claim a session checked against the code;
  a *prediction* by a held row is surfaced for the reader to judge and never spends a rank. The
  first version of the AC5 fixture did not pin this — its free row shared no path with the held row
  under either field, so widening the held set to `touches: + expects:` left the whole suite green.
  That is the conventions' "wired and still cannot fail", and only the mutation sweep found it: the
  extra case (`0045 FR1`) gives the candidate a path the held row *predicts* and has not claimed.

- **The mutation sweep needs the branch and the plausible-wrong version, and here they red
  differently.** Deleting the collision check reds 9 assertions across five cases; turning
  `continue` back into `break` reds exactly 2, both in AC2 — so FR2's load-bearing half is pinned
  independently of FR1, which is what the ticket's own note asked for. Filtering the held set to
  the candidate's stage — the mistake a reader of `show_claimed` would make — reds only AC6.

- **A malformed mutation reds for the wrong reason and looks like thoroughness.** One attempt at
  the FR5 mutation left an unterminated quote: 124 of 172 assertions failed, across every mode in
  the script, including modes the change never touches. A sweep's failure count is evidence about
  the mutation before it is evidence about the test — `sh -n` the mutant before believing either
  colour, and re-diff after a refactor moves the code a mutation targeted (M1 and M5 were re-run
  against the flattened version, not assumed).

- **Not done, deliberately: `--drive` still selects without this check.** `takeable_develop` skips
  `in-progress` rows but crosses nothing against `touches:`, so a driver can dispatch `develop` on
  a row the take loop would now refuse. Every AC here names `./next <stage>`, and *Out of scope*
  keeps the file-scope rule itself with 0050 — parked in `FINDINGS.md` rather than widened here.

- **The live backlog demonstrated FR5 within a minute of the change landing.** `./next develop`
  reported 0038 colliding with this very ticket's `touches:`, and printed 0051 — claimed by another
  session that had not yet written `touches:` — as `none declared; predicted by expects: …`. Both
  paths of the change exercised against real rows, not only fixtures.

