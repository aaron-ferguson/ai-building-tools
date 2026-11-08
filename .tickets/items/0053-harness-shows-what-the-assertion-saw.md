---
id: "0053"
title: Let the test harness print the line an assertion actually saw
type: feature
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-08-30
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

- [x] AC1 — Given a suite run with no flag set, when it passes, then its output is unchanged from
  today — one line per case plus the tally.
- [x] AC2 — Given a suite run with the verbose mode enabled, when a case passes, then the output
  includes the text the assertion matched against.
- [x] AC3 — Given any suite run, when a case fails, then the output includes the text the assertion
  saw, with the verbose mode off.
- [x] AC4 — Given `tests/next.test.sh`, `tests/close.test.sh` and `tests/claim.test.sh`, when each
  is run with the verbose mode enabled, then all three honour it.
- [x] AC5 — Given `README.md`'s *Testing* section, when read, then it names the flag and what it
  does.
- [x] AC6 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs
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

- **FR4 resolved as three copies that name each other, not a shared file.** `CLAUDE.md` states the
  suite is `tests/*.test.sh`, "each self-contained and printing its own tally", so sourcing a
  `tests/lib/` helper would change the shape of the suite to satisfy a sub-clause of one FR. Each of
  the three carries the same `saw` / `saw_on_pass` pair under a comment naming the other two.
- **`close.test.sh` had no rc helper at all** — eight inline `[ "$rc" -eq 0 ] && ok … || bad …`
  lines, four of which also dumped `$out`. Routed through `assert_rc` / `assert_rc_nonzero`, and both
  suites' helpers took an optional trailing captured-output argument so the two do not drift into
  different signatures. No assertion's subject changed; the pass lines are byte-identical.
- **`saw_on_pass` ends in an explicit `return 0`, and must.** Under `set -eu` a body of
  `[ -n "${SHOW_MATCHED:-}" ] && saw "$1"` returns 1 whenever the flag is off, and a function whose
  last command returns non-zero aborts the suite at the first passing assertion.
- **AC1 was checked by diff, not by eye**: `git show HEAD:tests/<suite> > tests/.head-<x>.sh` and
  diffing the two runs. The copy has to live inside the repo — every suite resolves `ROOT` from its
  own location, so a copy in a scratch directory exits 2 looking for `skills/queue/templates/` under
  the scratch path. Dot-prefixed so the `tests/*.test.sh` loop skips it, removed the same turn.
  Parked in `FINDINGS.md`, since the next mutation sweep will want it too.
- **AC3 was driven by a real failure with the flag off** — `'blocked'` mutated to `'NOT-A-STATUS'` in
  `tests/claim.test.sh`, mutation confirmed by diffing against a copy taken before the edit, output
  observed, mutation reverted. The failing line printed `saw: 0002 is 'blocked', not ready — pick
  another row`, which is the evidence the old `FAIL` line withheld.
- **Not done here:** the other five suites (`citations`, `graph-fields`, `measurement`, `batching`,
  the two size gates) still have their own `ok`/`bad` pairs and no flag. *Out of scope* says so; the
  block is eleven lines and copies cleanly when one of them next needs a sweep.

- Routed to `develop`: the mechanism is named in the finding (an env flag, or on `FAIL` plus a
  `--show` mode) and the trade-off is settled by `testing-conventions.md`'s existing rule that test
  output is lean by default and verbose temporarily.
- Ranked directly below 0052 rather than as a nicety. It is the tool that makes 0052's requirement
  and 0042's repairs affordable, and three consecutive sessions have each paid to build it by hand
  and thrown it away.

- **Verify 2026-08-30 [b673]: FAIL on AC2 and AC3 — `tests/claim.test.sh` never got the rc
  helpers.** It carries the `saw` / `saw_on_pass` pair and routes `assert_contains`,
  `assert_not_contains` and `assert_row` through it, but its five exit-code assertions were left as
  the inline `[ "$rc" -eq 0 ] && ok … || bad …` form — the exact shape the notes record having
  routed through `assert_rc` / `assert_rc_nonzero` in `close.test.sh`. There is no `assert_rc` in
  `claim.test.sh` at all (lines 120, 130, 140, 147, 158).
  - **AC2** — with `SHOW_MATCHED=1`, 5 of 18 passing cases print no matched text: `claim.test.sh`
    emits 13 `saw:` lines for 18 passes. `close.test.sh` emits 92 for 93 — line 402's
    `commits only the row it closed and the rows it freed` is the twin of line ~193's
    `commits exactly the three paths`, same shape in the same file; one was converted and one
    was missed.
  - **AC3** — the two `exits non-zero` assertions (lines 130, 147) print nothing at all on
    failure, flag on or off. Driven by mutation: `exit 1` → `exit 0` at
    `skills/queue/templates/claim:94`, mutation confirmed by diff against a copy taken before
    the edit, reverted by that path alone (sha `1952d7ec` before and after). Observed:

    ```
    AC2 — a blocked row is refused by its actual status
      FAIL — exits non-zero (got 0)
      ok   — names the actual status
    ```

    That failing line is precisely the "why did this case go red with no evidence" the ticket
    exists to remove. `next.test.sh`'s `assert_rc_nonzero` would have printed
    `saw: wanted any exit but 0 / exit 0 / <output>`.
  - The other three (120, 140, 158) do print evidence on failure, but as `got:` rather than
    `saw:` — the third debugging interface FR4 exists to prevent.
  - `README.md`'s new block claims "every ok line followed by what that assertion saw", which is
    false while those six assertions stand.
  - **Not in scope's exemption:** *Out of scope* excludes the other five suites, not
    `claim.test.sh` — it is named in `expects:` and in FR4. The fix is the eleven-line block
    already written twice.
  - **Passing:** AC1 (pre-0053 vs post-0053 default output byte-identical for all three suites,
    verified by running both historical copies against today's tree), AC4 (all three do honour the
    flag), AC5 (`README.md` *Testing* names `SHOW_MATCHED` and what it does), AC6 (11 committed
    suites, 0 failed, loop exit 0). Both NFR rows hold.

- **Re-entry 2026-08-30 [626a]: the verdict's six assertions fixed.** `assert_rc` /
  `assert_rc_nonzero` added to `tests/claim.test.sh` byte-identical to the pair in `next.test.sh`
  and `close.test.sh`, and the five inline `[ "$rc" … ] && ok … || bad …` lines routed through them
  with `"$out"` as the trailing argument. `close.test.sh:402` converted to the `if`/`saw_on_pass`
  shape of its twin at line 253. Counts under `SHOW_MATCHED=1`: claim 18 passes / 18 `saw:` lines
  (was 18/13), close 93/93 (was 93/92), next 154/154 unchanged.
- **AC3 re-driven by mutation with the flag off.** `exit 1` → `exit 0` at
  `skills/queue/templates/claim:94` — the file `CLAIM_SRC` resolves, per the QA plan's warning
  about mutating the copy rather than the subject. Mutation confirmed by diff against a copy taken
  first, and reverted to a clean diff. The failure now prints `saw: wanted any exit but 0 / exit 0 /
  0002 is 'blocked', not ready — pick another row`, where before it printed nothing at all.
- **AC1 checked by diff, not by eye**, using the `tests/.head-<x>.sh` trick these notes already
  record: default output byte-identical to HEAD for both suites, copies removed the same turn.

- **The comment above the shared helpers still says "this pair" and now covers two pairs.** That
  imprecision is not cosmetic — it is the exact reading that let `assert_rc` reach two suites and
  miss the third, which is what bounced this ticket. Tightening it was attempted and **backed out**:
  the line is identical in all three suites so it cannot be half-changed, and `tests/next.test.sh`
  is held by 0045 [296c]. Parked in `FINDINGS.md` for whoever holds all three at once.
- **A file declared in `touches:` but never edited is a live cost, not a harmless over-declaration.**
  This ticket declared `README.md` because AC5 names it; AC5 needed no change, and while the
  declaration stood `./next develop` reported 0051, 0038 and 0046 as COLLIDES against it. An
  over-wide scope is visible to every other session and invisible to the one holding it.
- **0045 [296c] claimed and began editing the tree mid-session**, after this ticket's `./next` run
  had reported no claimed files. A file scope read at claim time is a snapshot, not a subscription:
  the tree acquired `skills/queue/templates/next` and `tests/next.test.sh` changes, and 11
  `next.test.sh` assertions plus `backlog-scripts-installed.test.sh` went red — none of it this
  ticket's. Proved by running the full suite in a throwaway worktree at HEAD: 12 suites, 0 failures,
  worktree removed the same turn. **Re-check the held file set before a full-suite run, not only
  before the claim.**
