---
id: "0089"
title: Sweep the guards for assertions that cannot fail
type: bug
next: develop
status: ready
qa_level: unit
size: l
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0052", "0063"]
expects:
  - tests/backlog-scripts-installed.test.sh
  - tests/batching.test.sh
  - tests/citations.test.sh
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/cost-by-category.test.sh
  - tests/external-feedback.test.sh
  - tests/falsifiable-acs.test.sh
  - tests/floor-probe.test.sh
  - tests/graph-fields.test.sh
  - tests/handoff.test.sh
  - tests/last-line.test.sh
  - tests/measurement.test.sh
  - tests/money-in-skill-prose.test.sh
  - tests/next.test.sh
  - tests/qa-level-once.test.sh
  - tests/reference-size.test.sh
  - tests/release.test.sh
  - tests/reporting.test.sh
  - tests/retro-tool-edit.test.sh
  - tests/skill-size.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Three of `0085`'s acceptance criteria shared one defect shape and all three closed the ticket
green. AC8 (`*"work"*`), AC9 (`*protocol*`, `*git*`) and AC10 (`*10000*`) were substring `case`
matches over a tool's **whole output**, satisfied by text the tool prints unconditionally; every
one stayed green under mutations that provably landed. AC10 cannot fail at all — `10000` is a
substring of the `ctx/turn` figures `100000`, `110000`, `115000` and `125000` that the same output
carries.

`testing-conventions.md` names the shape twice — *anchor an assertion to the claim, not the
document that contains it*, and *a number present where the contract is that it is formatted* — and
says a suite with a **known systematic weakness of this shape is swept from a loop, not by reading
for the next instance**.

Every guard in this repo greps prose, and there is no test runner behind them
(`.claude/backlog/config.yml`, `commands.unit`). The suite is the only safety net the repo has, so
the exposure is all 21 files in `tests/`, not the one where it was found. A guard that cannot fail
reads exactly like a guard that passes, and it closed a ticket.

Found while verifying `0085` (pointer: `tests/cost-by-category.test.sh`, item `0063`).

## Functional requirements

- FR1 — Every assertion in `tests/*.test.sh` that matches against a command's **whole captured
  output** or a **whole file** is re-anchored to the specific line, element or claim it is about,
  or is deleted with its reason recorded in this item's *Notes & decisions*.
- FR2 — Every assertion whose needle is a **substring of another value the same output carries** is
  re-anchored so the two cannot be confused. `10000` inside `100000` is the worked instance; the
  sweep looks for the class.
- FR3 — Each re-anchored assertion is **mutation-proved**: the sweep records, per file, the change
  applied to the subject under test that turned the assertion red, and that it went green again on
  revert. An assertion for which no such mutation can be found is not re-anchored — it is deleted.
- FR4 — The sweep is driven **from a loop over all 21 files**, not by reading for the next
  instance, and the list of files examined is recorded so a later reader can tell an examined-clean
  file from an unexamined one.
- FR5 — A guard implements FR1 and FR2 as a standing rule: a new test file added to `tests/` is
  checked for whole-output and whole-file matching, so the class cannot return silently.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The per-file mutation evidence from FR3 is written into this item as the sweep runs, not reconstructed at the end | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the sweep is complete, when `grep -n 'case "\$out"' tests/*.test.sh` is run, then
  every remaining hit is against a variable holding a **single extracted line or field**, not a
  whole command's output. Red if any hit matches a variable assigned from an unfiltered command
  substitution.
- [ ] AC2 — Given `tests/cost-by-category.test.sh`, when the figure the AC10-shaped assertion tests
  is changed in the subject from `10000` to `9999`, then that assertion goes **red**. Red-making
  input: today's code, where the assertion passes with the figure absent because `100000` contains
  it.
- [ ] AC3 — Given each file the sweep re-anchored, when this item's *Notes & decisions* is read,
  then it names for that file the mutation applied and the assertion that went red under it. Red if
  any re-anchored file has no such entry.
- [ ] AC4 — Given a new file `tests/zz-whole-output.test.sh` that matches a substring against a
  whole command's output, when the suite is run, then FR5's guard **fails and names that file**.
  Red if the guard passes, or if it fails without naming the file.
- [ ] AC5 — Given the whole suite after the sweep, when `for t in tests/*.test.sh; do "$t" || true;
  done` is run against an unmodified tree, then every file reports `0 failed`. Red if any assertion
  was re-anchored onto a claim the code does not actually make.

## QA plan

- **Why that level:** the change is to the test files themselves and the assertions are the
  deliverable, so the runner that exercises them is the suite. `unit` is this project's whole
  suite (`config.yml`).
- **Specific checks:** run the suite file-by-file (`for t in tests/*.test.sh; do "$t" || true;
  done`) rather than through `config.yml`'s fail-fast `unit` line, so one red does not mask the
  twenty behind it. Then re-apply two of the FR3 mutations at random and confirm the named
  assertion reddens.

## Out of scope

- The rewrap-survival matcher — that is `0063`, and an assertion re-anchored here still breaks on a
  reflow until `0063` lands. Where the two touch the same line, leave the reflow problem alone.
- Writing new coverage. This sweep fixes assertions that cannot fail; it does not add assertions
  for behaviour nothing checks.
- `skills/**` prose. The defect is in the guards, not in the rules they guard.

## Notes & decisions

- Routed to `develop` rather than `design`: the corrective shape is already named by
  `testing-conventions.md` and demonstrated in this repo, so no decision blocks the criteria.
- `size: l` because it is 21 files and FR3 requires a mutation per re-anchored assertion. It is a
  sweep, and the batching rule applies inside it: one session, one loop.
- 2026-09-07 — `retro` absorbed five `FINDINGS.md` entries into this row rather than filing a
  second ticket; the sweep this row already scopes is where they belong. Established, so a claiming
  session need not re-derive it:
  - **The `grep -c` pre-filter has three known blind spots and cannot be the only net.** (1) It is
    line-based, so a phrase wrapping across a line break counts as 1 and reads as safely unique —
    which is exactly the phrase most likely to be duplicated in flowing prose. Count on flattened
    text (`tr '\n' ' ' | tr -s ' '`), as `tests/orchestrate.test.sh`'s `section()` helper does.
    (2) A guard over a *filtered stream* (`fenced "$SKILL" | grep -qF`) is semantically whole-file
    and matches no pattern looking for `grep … "$FILE"`; a filter selecting **every** block of a
    kind is not a scope, only a different whole. (3) A file-level count answers the wrong question
    for a **section-scoped** guard: `0039`'s Dependencies guard greps the flattened `## Requirements`
    section for `orchestrate`, which occurs twice *within that section*, so generalising the one
    sentence carrying the attribution left the suite at 105 passed, 0 failed. **Count within the
    guard's own subject, whatever narrowing it applies.**
  - **`case "$out" in "TAKE      0001"*)` is a prefix match on a multi-line capture, not a line
    match.** Any `COLLIDES`, `SKIP`, `DRIFT` or warning line printed ahead of the regression hides
    it. `printf '%s' "$out" | grep -q '^TAKE      0001'` costs the same and says what was meant.
    Worth a sweep for `case "$out" in` across `tests/`.
  - **Where a behaviour is defended by two independent mechanisms, a mutation removing one proves
    nothing.** `0039`'s AC16 fixture needed *both* the status filter and the `touches:` collision
    check broken before the guard would red; single-mutation verified it against the stronger of
    the two only.
  - **An `assert_contains` on a flag name is matched by the prose explaining the flag.** `next`'s
    `usage()` could drop `--drive` from its synopsis *and* delete its five-line description block
    and stay green, because a later paragraph mentions the flag. Pin the mode's own line.
  - **The enumerated-subjects defect is live in this repo's own guards.** `tests/last-line.test.sh`
    and `tests/reporting.test.sh` carried hardcoded `SKILLS=` lists (now derived);
    `grep -n '^[A-Z_]*=\"[a-z ]*\"' tests/*.test.sh` finds the rest and nobody has run it.
  The generalisable half of all of this landed in `testing-conventions.md` on 2026-09-07; what stays
  here is the repo-specific sweep.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **three more instances for the sweep, each
  verified by mutation at the time it was parked.**
  1. **A guard anchored to a literal that the guarded prose does not use.**
     `tests/orchestrate.test.sh`'s AC25 greps `(rm|rmdir|unlink)[^|]*\.lock` over the fenced blocks,
     but the block it guards opens `LOCK=.claude/backlog/.lock` and says `"$LOCK"` everywhere after.
     A fenced `rm -rf "$LOCK"` leaves the suite at 130 passed while doing exactly what FR15 forbids.
     The delivered prose is clean either way, so this is coverage of the one clause whose whole point
     is that a future edit must not slip it in.
  2. **A guard that checks a citation and not the number beneath it.** AC26 asserts
     `MEASUREMENT.md`'s per-stage means appear in the comment above `stage_budget_usd:`; nothing
     relates that comment to the value. Setting `retro: 99.00` with its `2.51` citation intact
     leaves the suite green. Two things for whoever takes it: the arithmetic could be asserted from
     the cited mean, and the **rounding granularity is unstated** — all three shipped caps are mean
     x 1.5 rounded to the nearest five cents (6.05, 5.45, 3.75), which is self-consistent, but the
     comment says only "times 1.5", so an honest recompute yields 6.04 and 3.76 and reads as drift.
  3. **A guard whose file scope includes `tests/` also covers its own source, and its fixture
     literals become real citations.** `0105`'s item-ID check reported `tests/citations.test.sh` on
     its first run, correctly: the unresolvable id its fixtures need was spelled in an anchored form
     inside a covered file. Fixed there with a variable; the shape generalises to any guard that
     scans the directory it lives in.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Twelve findings-buffer entries (2026-09-10..12) are more instances of this ticket's class, each found by a mutation that did not redden: `tests/orchestrate.test.sh` (now `sprint.test.sh`) `section()` matching a heading as a prefix, so an absence assertion over an empty extraction is green forever; a `says` token satisfied by a code fence in the same section; `tests/batching.test.sh` `binds()` spanning a sentence break; `tests/falsifiable-acs.test.sh` `window()` whose `!first` clause can never fire (`first = 1` is the fix); `tests/sprint-ledger.test.sh` AC6 awk reporting only inside its last branch, so a missing denominator is invisible (needs an `END` block); `assert_contains "DISPATCH  verify 0102"` passing on a batch (a list assertion is an equality); `paired()` satisfied by a default estimate the tool forges (anchor on the source, not the figure); an error message too shredded to assert on inviting a loosened assertion; `qa-level-once` not seeing a stale *Why that level* rationale; `add_item_blank_scope` silently setting `claimed_by`; fixture titles describing a state their bytes do not build; and low fixture ids colliding with real ids in `develop` Step 2's own-id grep. The general forms are `testing-conventions.md` material; the instances are this sweep's.
