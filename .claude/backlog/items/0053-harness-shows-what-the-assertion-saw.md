---
id: "0053"
title: Let the test harness print the line an assertion actually saw
type: feature
next: develop
status: in-progress
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0038", "0042", "0052"]
expects:
  - tests/next.test.sh
  - tests/close.test.sh
  - tests/claim.test.sh
  - README.md
claimed_by: "064e"
claimed_at: 2026-08-25T22:16:17Z
touches:
  - tests/next.test.sh
  - tests/close.test.sh
  - tests/claim.test.sh
  - README.md
---

## Problem

`tests/next.test.sh` prints `ok` or `FAIL` and nothing else. It never shows the line the assertion
matched against, so a mutation sweep — the thing `verify` Step 3 requires on every AC resting on an
automated check — cannot tell *why* a case passed.

Verifying 0038 meant deleting each branch of `./next --drive`'s ladder and asking which cases went
red. Where one stayed green the harness could not say what it had matched instead, and the only way
to see it was to hand-build a fixture outside the suite and diff the real output against the
mutant's. That scaffolding gets invented per session and thrown away; 0038 was the third session in
a row to pay for it.

The cost lands on exactly the work this repo is now committing to. 0042 repairs three guards by
mutation, 0052 makes "name the input that would make this red" a requirement of every acceptance
criterion, and 0044 and 0045 each carry mutation-driven ACs. Every one of those passes will rebuild
the same throwaway fixture, and each rebuild is a session of work that a readable failure line would
turn into a read.

## Functional requirements

- FR1 — A test suite's assertion helpers can print the captured output they matched against, on
  demand rather than always, so a passing run stays lean per `testing-conventions.md`'s rule on
  default test verbosity.
- FR2 — The captured output is printed automatically on `FAIL`, since a failure with no evidence is
  the case the current output already handles worst.
- FR3 — The on-demand mode is reachable without editing the suite — an environment variable or a
  flag — so a mutation sweep turns it on for one run and off again.
- FR4 — The helpers changed are shared across `tests/next.test.sh`, `tests/close.test.sh` and
  `tests/claim.test.sh` rather than fixed in one, or each names the others, so the three do not
  drift into three different debugging interfaces.
- FR5 — `README.md`'s *Testing* section documents how to turn it on, since that block is where a
  contributor is told how the suite works.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | Default output stays summary-plus-failures; the verbose mode is opt-in and reverted after use | `testing-conventions.md` |
| Documentation | The flag is documented where the suite is documented, in the same change | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a suite run with no flag set, when it passes, then its output is unchanged from
  today — one line per case plus the tally.
- [ ] AC2 — Given a suite run with the verbose mode enabled, when a case passes, then the output
  includes the text the assertion matched against.
- [ ] AC3 — Given any suite run, when a case fails, then the output includes the text the assertion
  saw, with the verbose mode off.
- [ ] AC4 — Given `tests/next.test.sh`, `tests/close.test.sh` and `tests/claim.test.sh`, when each
  is run with the verbose mode enabled, then all three honour it.
- [ ] AC5 — Given `README.md`'s *Testing* section, when read, then it names the flag and what it
  does.
- [ ] AC6 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs
  with no flag set, then every suite passes and the tallies are unchanged.

## QA plan

- **Level:** unit — the deliverable is the suites' own helpers, and this project's `unit` command
  runs every `tests/*.test.sh`.
- **Why this level:** each AC is a run of an existing suite with and without the flag.
- **Specific checks:** run each of the three suites both ways; drive AC3 by mutating one fixture so
  a case genuinely fails, confirming the mutation landed by diffing against a copy taken before the
  edit, and reverting. Confirm the mutation reached **the file the harness runs** — `tests/next.test.sh`
  resolves its subject through `NEXT_SRC` at line 23, and mutating `.claude/backlog/next` instead
  returns a clean pass, which is what a check that cannot fail also returns.

## Out of scope

- Adding a test runner or framework. `CLAUDE.md` states the suite is a shell loop with no runner
  and this ticket does not change that.
- Changing any existing assertion's *subject*. This is about what the harness reports, not what it
  checks.
- The remaining five suites. FR4 names the three with assertion helpers of this shape; extending it
  is cheap once the shape exists and is not required to close this.

## Notes & decisions

- Routed to `develop`: the mechanism is named in the finding (an env flag, or on `FAIL` plus a
  `--show` mode) and the trade-off is settled by `testing-conventions.md`'s existing rule that test
  output is lean by default and verbose temporarily.
- Ranked directly below 0052 rather than as a nicety. It is the tool that makes 0052's requirement
  and 0042's repairs affordable, and three consecutive sessions have each paid to build it by hand
  and thrown it away.
