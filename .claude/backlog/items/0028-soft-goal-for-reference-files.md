---
id: "0028"
title: Replace the reference files' hard token ceiling with a soft goal and a gate
type: debt
next: develop
status: in-progress
qa_level: verify
size: m
created: 2026-08-23
source: user
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - tests/reference-size.test.sh
  - .claude/backlog/items/0020-split-concurrency-rules-from-incidents.md
claimed_by: "3882"
claimed_at: 2026-08-24T04:28:00Z
touches:
---

## Problem

`references/CONCURRENCY.md` carries a hard ceiling of 1,500 tokens, set by 0020 FR4 and re-asserted
as 0023 AC7. Three findings converged on it in one day:

1. **The ceiling was already breached before the ticket required to hold it.** 0024 and a retro
   pushed the file to ~1,637 tokens; 0023 discovered it only by being the next ticket that had to
   measure. A ceiling with no gate is enforced by whichever ticket happens to cite it, which is
   arbitrary.
2. **The margin reached ~2 tokens**, so the next edit breaches it.
3. **The two ways it has been paid are spent.** Both previous payments came from prose the file's
   own split assigns elsewhere — restated justifications, then moving an incident to
   `CONCURRENCY-INCIDENTS.md`. The incidents are out. The next rule that has to change can only buy
   its words from another rule.

A fourth finding is blocked behind it: `close` and `CONCURRENCY.md` disagree about what *held*
means (0029), and correcting the rule costs words the ceiling does not have.

Aaron's decision, 2026-08-23: *"A hard character or token ceiling does not make sense because if
there are more principles than fit, then we need to hold those principles. What I do want to hold a
line here is that we should have a ceiling goal: a soft ceiling, so that we don't accidentally
write less important anecdotes or examples or niche situations into a generic tool. We should build
in a way that heavily leverages pointers so that extra context can be held in other files and
pulled in as needed, and not always pulled into context."*

`tests/skill-size.test.sh` already implements exactly this shape for `skills/*/SKILL.md` as of
2026-08-23 — a goal, a recorded reason with no upper bound, a stale-entry failure, and a message
naming relocation-to-a-pointer as the first move. This ticket brings the reference files under the
same mechanism and retires the hard number.

## Functional requirements

- FR1 — a scripted gate covers `references/*.md`, so the goal is enforced by a run rather than by
  whichever ticket cites it. It follows `tests/skill-size.test.sh`'s semantics: over the goal is
  allowed **with a recorded reason**, unrecorded-and-over fails, and a reason on a file back under
  the goal fails so the stale entry is removed.
- FR2 — the gate measures in **bytes**, absolutely, for the reason 0021 recorded: a percentage of a
  moving baseline is un-auditable, and a decoded character count undercounts multi-byte em-dashes.
  It states the bytes-per-token ratio it used to convert any prior token figure.
- FR3 — the hard 1,500-token ceiling is retired at every place that asserts it: 0020 FR4 and 0023
  AC7 are both closed tickets, so the retirement is recorded rather than edited into them, and any
  *live* prose stating the ceiling is corrected.
- FR4 — the gate's own fixtures are generated at a fixed, stated size and never copied from a file
  under test (`testing-conventions.md`, the fixture rule) — the coupling that made an unrelated
  file's growth able to red an unrelated case.
- FR5 — the gate proves it can fail, and the mutation used to prove it is confirmed to have landed
  by diffing it (`testing-conventions.md`, *Prove a new guard fails*).
- FR6 — the relocation guidance is stated once where an author over the goal will read it: detail
  only some runs need moves to a conditionally-read file, and the reason recorded names what was
  considered for relocation. This is the half of Aaron's decision that a bare number loses.
- FR7 — the gate is wired into the project's `unit` command in `.claude/backlog/config.yml`, which
  now runs `tests/*.test.sh`, so a new test file is picked up with no further wiring. Confirm this
  rather than assuming it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The change from hard ceiling to soft goal is a reversal of a rule two closed tickets asserted; record that it was reversed, on whose call, and when, so a later reader can tell a decision from an erosion | `documentation-conventions.md` |
| Dependencies | `sh`, `wc`, `awk` only — this project has no runner and adding one is not this ticket's job | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the shipped tree, when the new gate runs, then it passes, and its pass line names
  every reference file recorded as over the goal together with that file's size and reason.
- [ ] AC2 — Given a reference file padded past the goal with no recorded reason, when the gate runs,
  then it fails, names that file, and reports its overage in bytes.
- [ ] AC3 — Given a reference file recorded as over the goal, when it is padded far beyond that
  point, then the gate still passes — the recorded reason carries no upper bound.
- [ ] AC4 — Given a reference file with a recorded reason that is now under the goal, when the gate
  runs, then it fails and says the entry is stale.
- [ ] AC5 — Given the mutation used to prove AC2, when it is diffed before the gate is run, then the
  diff is non-empty; a green from an unapplied mutation is reported as a defect, not a pass.
- [ ] AC6 — Given the gate's fixtures, when they are read, then their base file is generated at a
  stated fixed size and no fixture is copied from `references/`.
- [ ] AC7 — Given `grep -rn "1,500\|1500 token" references/ skills/`, when it runs, then it returns
  no live assertion of the retired hard ceiling.
- [ ] AC8 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then every
  suite passes, the new gate included.

## QA plan

- **Level:** verify — a shell gate with no runner, plus prose.
- **Why this level:** every requirement is a scripted assertion the gate itself makes, or a grep
  over prose. There is no logic here a unit level would reach.
- **Specific checks:** the gate executed with output shown; the four fixture paths from AC2–AC4
  driven deliberately; the AC5 mutation diffed then run; AC7's grep; the full `tests/*.test.sh`
  sweep.

## Out of scope

- Changing `tests/skill-size.test.sh`, which already implements this shape. If the two gates want
  shared code, say so and queue it — duplicating ~40 lines of `sh` across two guards is acceptable
  here and factoring it is a separate decision.
- Deciding *which* rule in `CONCURRENCY.md` to cut. The point of this ticket is that no rule has to
  be cut; the goal becomes a prompt to relocate rather than a mandate to delete.
- Fixing the `close`-versus-rule mismatch this unblocks. That is 0029.
- Relocating `develop`'s or `prototype`'s conditionally-needed detail. That is 0035.

## Notes & decisions

- Reversal recorded: 0020 FR4's and 0023 AC7's hard 1,500-token ceiling on `CONCURRENCY.md` is
  **superseded** by Aaron's decision of 2026-08-23. Both tickets are closed and stay closed; the
  ceiling they asserted is no longer the standard. The equivalent reversal for `skills/*/SKILL.md`
  landed the same day in `tests/skill-size.test.sh`.
- The goal's real job is to force a justification, not a deletion. That is why an over-goal file
  passes with a reason and fails without one, and why the failure message names relocation first.
