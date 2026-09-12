---
id: "0045"
title: Cross the take loop against the held file set in next
type: bug
next: develop
status: in-progress
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
claimed_by: "8f62"
claimed_at: 2026-09-12T04:12:43Z
touches:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
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
  keeps the file-scope rule itself with 0050 — parked rather than widened here. The buffer entry
  was drained 2026-09-05 and this bullet is now its only record, so it wants a row of its own or
  0039's to absorb it.

- **The live backlog demonstrated FR5 within a minute of the change landing.** `./next develop`
  reported 0038 colliding with this very ticket's `touches:`, and printed 0051 — claimed by another
  session that had not yet written `touches:` — as `none declared; predicted by expects: …`. Both
  paths of the change exercised against real rows, not only fixtures.


### From `FINDINGS.md`, landed 2026-09-05

- **A worked case for FR3, and it is the case the old output got backwards** (FINDINGS 2026-08-30).
  Verifying 0044, the collision warning flagged the two rows that declared **nothing** — "0053
  [b673] none declared — assume held, ask", and the same for 0074 — while the collision that
  actually cost the close came through a `touches:` that had been declared properly: 0053 shared no
  path with 0044 at all, and 0074, which had just committed a full `touches:` list naming
  `skills/verify/SKILL.md`, was the one that made the verdict advisory. The old warning keyed on the
  **absence** of a declaration, which is the cheaper signal, and said nothing about a declared
  overlap with the row it was offering. The output this ticket's FR3 asks for is exactly the missing
  line: *"0044's evidence set meets 0074's declared `touches:` at `skills/verify/SKILL.md`"*. Worth
  the QA pass confirming that the built behaviour names the intersecting path and the holding id in
  that direction too, not only for the row it steps over.

### Verify 2026-09-11 [7564] — FAIL on AC8 only, and the mechanism is cleared (SUPERSEDED)

Handed back to `develop` for **one line**, not for a rebuild. AC1-AC7 are green and each is pinned
by a mutation that reddened it; the full evidence is in `## QA evidence` below and does not need
re-deriving. The only red is AC8's whole-suite clause, and its cause is `7fdd367` (2026-09-11), a
home-directory path in **item `0052`'s** QA-evidence table — a file this ticket never touched,
committed twelve days after `0045` reached verify.

**The constraint, not a menu:** redact the absolute path at
`.claude/backlog/items/0052-acceptance-criteria-must-be-falsifiable.md:294` so the quoted tool
output keeps its meaning without publishing a home directory, then re-run `commands.unit` and tick
AC8. `0052` is closed and unheld, so nothing stands over that file. Do **not** touch
`skills/queue/templates/next`, `.claude/backlog/next` or `tests/next.test.sh` — they are verified.

The red is already parked in `FINDINGS.md` (2026-09-11, verify `0135`) and still owes a row; do not
park it again. It also means `tools/release` step 5 is currently red for the whole repo.

### Verify 2026-09-11 [8f62] — AC8 cleared, PASS, closed

The hand-back above was answered in the same session on the user's instruction rather than by a
`develop` pass. The redaction landed at **`4d22471`** — `…/ai-building-conventions` in place of the
absolute path, which leaves the quoted failure message meaning what it meant — and the whole suite
was re-run file-by-file: **30 files, all green**, `tests/measurement.test.sh` `129 passed, 0 failed`.
AC1-AC7's evidence stands unchanged from the `7564` pass and was not re-derived; only AC8 was re-run.
`tools/release` step 5 is unblocked for the repo as a side effect.

The `0045` mechanism itself was never touched by any of this — `skills/queue/templates/next`,
`.claude/backlog/next` and `tests/next.test.sh` are byte-identical to what `7564` verified.


## QA evidence

Verified 2026-09-11, session token `7564`, at `qa_level: unit` (`config.yml` `commands.unit` —
every `tests/*.test.sh`). Run file-by-file rather than fail-fast, per `config.yml`'s own note.
Tree was **clean** at Step 2 (`git status --porcelain` empty), so the dirty∩evidence intersection
is empty by construction and this verdict is not advisory. `HEAD` advanced mid-pass (`c158138`,
another session) and two files were briefly dirty during it; both were committed by their own
session and the tree read clean again at the verdict.

Mutations were applied to `skills/queue/templates/next` — the copy `tests/next.test.sh` runs via
`NEXT_SRC` (line 23) — never to `.claude/backlog/next`, which the harness does not execute.
Every mutant was `sh -n` checked and its diff confirmed non-empty before its colour was believed.
Control after every restore: `413 passed, 0 failed`.

| Row | How it was checked | Result |
|---|---|---|
| AC1 — a row whose `expects:` meets a held `touches:` is not offered | `tests/next.test.sh`, case *0045 AC1*. **M1**: delete the take loop's collision branch (`next:1376-1380`) → `395 passed, 18 failed`, including *"no TAKE on the colliding top row"* | PASS |
| AC2 — the walk continues to the first clear row | Same suite, case *0045 AC2*. **M2**: `continue` → `break` in that branch (`next:1379`) → `411 passed, 2 failed`, exactly *"offers the lower clear row"* and *"with its own expects"* — FR2's load-bearing half pinned independently of FR1 | PASS |
| AC3 — the stepped-over row is named with the path and the holder | Same suite, case *0045 AC3*, asserting the whole `COLLIDES` line rather than three substrings. M1 reddens all three assertions. The case also asserts the holder's *non*-intersecting path is absent, so a report naming every declared path would fail | PASS |
| AC4 — every row colliding reads differently from an empty stage | Same suite, case *0045 AC4*. M1 reddens *"says the stage is held, not empty"*. Live wording: `every takeable develop row collides with files another session holds — nothing here is safe to take` | PASS |
| AC5 — empty `touches:` falls back to `expects:`, labelled predicted | Same suite, both *0045 AC5* cases. **M4**: `declared_scope` (`next:678`) always prints the bare wording → `410 passed, 3 failed`. The second case pins that a row declaring *neither* field keeps `none declared — assume held, ask` verbatim | PASS |
| AC6 — the held set is not filtered by stage | Same suite, case *0045 AC6*. **M3**: add a stage filter to `collision_report`'s loop → `411 passed, 2 failed`, exactly the two AC6 assertions. This is the 0007/0038 instance — a `develop` candidate against a live `verify` claim | PASS |
| AC7 — `.claude/backlog/next` matches the template | `tests/backlog-scripts-installed.test.sh`: `37 passed, 0 failed`; `diff -q` on the two paths reports identical. **M5**: append a comment line to `.claude/backlog/next` → `36 passed, 1 failed`, *"next has diverged from skills/queue/templates/next — fix the template and re-copy, never the copy"* | PASS |
| AC8 — the whole suite passes | 30 files run individually. First run: 29 green, `tests/measurement.test.sh` at **`128 passed, 1 failed`** on a home-directory path at `.claude/backlog/items/0052-…md:294` — a foreign red, see below. Redacted at `4d22471` and the suite re-run in full: **all 30 files green**, `tests/measurement.test.sh` now `129 passed, 0 failed`, `tests/next.test.sh` `413 passed, 0 failed`, `tests/backlog-scripts-installed.test.sh` `37 passed, 0 failed` | PASS |
| FR1 (not an AC, but the design decision AC5 does not pin) | Case *0045 FR1*: a candidate colliding with a held row's **predicted** `expects:` and with nothing it has claimed is still offered. M4 reddens *"the prediction is still surfaced"*. Confirms the filter reads `touches:` while the display falls back to `expects:` | PASS |
| NFR Documentation — the rule is stated where `--help` defines takeability | `./next --help` lines 36-43: takeability is now four tests including *"no file the row `expects:` is already held by a held row's `touches:`"*, followed by the `COLLIDES` report, the continue-don't-break behaviour, the cross-stage held set, and the distinct all-collide wording. `documentation-conventions.md` satisfied | PASS |

**Step 4, newly reachable states:** the change can now *refuse* rows, which is a new way for the
stage to be empty. The two shapes that could freeze it are both closed in the code: `held_by`
gates the whole loop so a stale `touches:` on an unheld row collides with nothing, and the
exclusive-claim short-circuit is tested before `paths_shared` for the same reason. No routing,
permission, credential, log field, egress or UI surface is touched, so no Security, Privacy or
Accessibility row is owed beyond the always-on pass, which is clean for this change's own files.

### Why AC8 is a FAIL and what clears it

The red is **not this ticket's**. It is a `grep` hit on line 294 of item `0052`'s QA-evidence
table — a verdict that quoted a tool's output verbatim, where the tool prints an absolute path.
It landed at **`7fdd367`, 2026-09-11 15:59**, twelve days after `0045` was handed to verify at
`4871751` (2026-08-30 11:06), in a file `0045` does not touch and no `0045` guard reads. The
mechanism this ticket built is **cleared** — every one of AC1-AC7 is green and mutation-pinned
above, and none needs re-deriving.

The remedy is one line: redact the absolute path in `.claude/backlog/items/0052-…md:294`
(`/Users/<user>/AI/ai-building-conventions` → a relative or placeholder form) so the quoted tool
output keeps its meaning without publishing a home directory. `0052` is **closed and unheld**, so
no claim stands over it. Then re-run `commands.unit` and tick AC8. Nothing else in `0045` is owed.

The same red is **already parked** in `FINDINGS.md` (2026-09-11, verify `0135`) and still owes a
row; do not park it a third time. Note the disagreement in precedent honestly: `0135`'s verdict
recorded it as *"PASS for this ticket"* because `0135` carried no whole-suite AC. `0045`'s **AC8
is a whole-suite AC in as many words**, so the same red is a literal fail here, and softening it
would tick a criterion that is false. This asymmetry — one repo defect, two opposite verdicts a
day apart, decided by whether the ticket happened to write AC8 — is itself parked as a finding.
