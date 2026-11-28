---
id: "0247"
title: Name the child copy's failing case in sprint.test.sh's 0165 AC2 red, and remove the nondeterminism behind it
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: m
created: 2026-11-27
source: agent
parent:
blocked_by: []
relates: ["0165"]
expects:
- tests/sprint.test.sh
claimed_by: "57c0"
claimed_at: 2026-11-28T00:02:32Z
touches:
- tests/sprint.test.sh
slice:
ac_digest: AC1=216fd3dc AC2=8a78151d AC3=0092c022 AC4=c37c7984
---

## Problem

The unit baseline is intermittently red, and the red does not say why. Filed repair-first by
`/sprint run-20261127T234238Z`, which found it at HEAD `8c2d838` running the full unit loop
(`config.yml` `test_commands.unit_by_file`: `for t in tests/*.test.sh; do "$t" || true; done`):

```
tests/sprint.test.sh — 386 passed, 1 failed
FAIL 0165 AC2 — the clean copy was not green (380 passed, 1 failed, 2 skipped), so 'a green run prints no block' went untested; this file is red for a reason named above, not by 0165
```

Run alone, the same file passed **387 / 0**. So it is nondeterministic: the child copy that 0165's
block runs (`SPRINT_TEST_CHILD=1 SPRINT_SKIP_PROBE=1 "$CHILD" > "$FIX/clean.out"`,
`tests/sprint.test.sh` around line 3087) hit a red the parent run did not, and the parent's message
(around line 3100) prints only the child's tally line. The message says the file "is red for a reason
named above" — but no case above it failed in the parent; the child's own FAIL line exists only in
`$FIX/clean.out` (the child prints its `--- N FAIL lines, re-printed ---` block, around line 3364),
which the parent never surfaces and the fixture cleanup discards. Every sprint gate and `verify` pass
that runs the unit level can therefore go red on a case nobody can name, which is the exact failure
mode 0165 was filed to end (a red waved off as "the flake").

Who is hurt: every session whose gate is the unit level — a sprint run escalates or files a repair
row on it, and a verify pass cannot tell this red from a real regression.

Unconfirmed leads, for `develop` to confirm or discard (none is established): the child copies the
**live working tree** (`cp -R "$ROOT"/*`, pruning only `.tickets/runs/`), so anything another session
or an earlier test file has half-written under the repo is in the child's tree and not in the
parent's view at the moment the parent's own case ran; and the child runs later than the parent's
cases, so a time- or load-sensitive case can land differently. Last commit touching the file:
`2f5a00a` (0242 S15).

## Functional requirements

- FR1 — When 0165 AC2's not-green branch fires, the parent's FAIL output carries the child copy's
  own FAIL line(s) (from its `clean.out`), so the case that made the child red is named in the
  parent's run output, and within the re-print block the parent prints at its end.
- FR2 — The not-green branch stays a failure (`bad`), never a `skip` or a pass: a child that is red
  still reds the parent. The check is not deleted, skipped or weakened.
- FR3 — The mechanism that lets the child copy go red when the parent is green is identified, with
  the child's failing case named, and recorded in this ticket's *Notes & decisions* and in the
  comment block above 0165's block in `tests/sprint.test.sh`.
- FR4 — That mechanism is removed at its cause — in the fixture's construction or in the case that
  behaves differently in the child — so the child and the parent run the same cases against the same
  inputs. Where the cause is a case outside 0165's block, the fix is to that case.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Performance | The file still spawns exactly the two child runs it spawns today (AC1's injected copy and AC2's clean copy); naming the case reads the existing `clean.out` rather than running a third generation | A third `"$CHILD"` invocation in 0165's block roughly adds the file's whole runtime again; `verify` times the file before and after | `testing-conventions.md` |
| Documentation | The comment block above 0165's block names the cause found and why the fixture or case now avoids it — prose, unguarded, per this repo's `CLAUDE.md` *Tests* | `verify` reads the comment and finds no mechanism named (AC2) | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a child output fixture whose tally is not green and which holds a FAIL line naming a
  case `X` (built by the test itself, e.g. a `clean.out` written with `1 failed` and `FAIL X`), when
  0165 AC2's not-green reporting runs over it, then the parent records a FAIL whose text contains `X`,
  and the parent's tally counts it as failed. Red: reverting the message to print only the tally line
  (the code at `8c2d838`), or turning the branch into a `skip`, reds it.
- [ ] AC2 — Given the reproduction the build session establishes (a command, recorded in *Notes &
  decisions*, that makes the child red while the parent is green — forced deterministically if the
  natural rate is low), when it is run against the code at `8c2d838`, then the child's failing case
  is named in *Notes & decisions* along with the mechanism, and the comment above 0165's block
  names the same mechanism. Red: *Notes & decisions* naming no case, or naming a mechanism the
  recorded reproduction does not exercise.
- [ ] AC3 — Given a committed case in `tests/sprint.test.sh` that forces the mechanism AC2 named,
  when it runs against the fixed code, then it passes, and with the fix reverted it reds. Red:
  reverting FR4's fix.
- [ ] AC4 — Given the fixed tree, when `tests/sprint.test.sh` runs in the full unit loop
  (`unit_by_file`) 5 times, then no run prints `0165 AC2 — the clean copy was not green`. Phrased
  as no named failure in 5 runs, not 5/5 green, so an unrelated red elsewhere does not decide it.

## QA plan

- **Why that level:** every change is inside a test file and its fixture; the suite is the runner.
- **Specific checks:** run `tests/sprint.test.sh` alone and in the full loop; revert FR4's fix and
  see AC3 red; revert FR1's message change and see AC1 red; run AC2's recorded reproduction against
  `8c2d838` and see it name the case; AC4's 5 loop runs; time the file before and after for the
  Performance row.

## Out of scope

- Deleting, skipping or loosening 0165 AC2's green-run check, or treating a red child as a pass.
- Any new guard that greps prose (this repo's `CLAUDE.md`, *Tests*).
- A third child run, or running the AC22 probe in the child.
- Fixing an unrelated red the investigation turns up in another file: park it (`./park`) with its
  evidence instead.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-11-27 queue — Minted rather than amended: 0165 is `done`, and no open ticket's outcome
  covers this red (grep of open items for `0165` and `clean copy`: none). Routed `next: develop`:
  no surface and no open decision — the cause is discoverable by reading and running the code, and
  the fix's shape follows from it. `close_by: verify` because AC2 and AC4 are observations a second
  pass should read, not single committed assertions.
- 2026-11-28 develop [57c0] — **The child's failing case was `0234 AC25`**, not anything in 0165's
  fixture: `FAIL 0234 AC25 — after the Step 3 stop, heartbeat children survived (seen: 1, alive:
  13259)`, tally `380 passed, 1 failed, 2 skipped` — the exact shape of the sprint's red. (run)
- **Mechanism (FR3).** The Step 3 stop is `pkill -P "$BEAT"; kill "$BEAT"`: the pkill kills the
  loop's `sleep 9`, then the kill takes the loop before it reaps that sleep, so the sleep is left a
  **zombie**, re-parented to PID 1. AC25's check asked `kill -0`, which succeeds on a zombie, so a
  correctly stopped heartbeat read as an orphan until PID 1 reaped it. In this container PID 1 is
  `process_api`, which reaps late; under load the race lands more often. Not child-specific — the
  child lost it more because it runs last, under whatever else is running. The "copies the live
  tree" lead is discarded: the files involved (`tests/sprint.test.sh`, `skills/sprint/SKILL.md`)
  are byte-identical between `8c2d838` and the reproduction tree (`git diff 8c2d838 a3af103`: empty).
- **Reproduction (AC2), run against the `8c2d838` content:** build the child copy as 0165's block
  does (whole repo minus `.git`, `tests/`, `.tickets/runs/`, `.claude` beyond `settings*.json`) with
  `tests/sprint.test.sh` as `tests/child.test.sh`, then three loops in parallel, each 4×
  `SPRINT_TEST_CHILD=1 SPRINT_SKIP_PROBE=1 <copy>/tests/child.test.sh`: **1 of 12 red, on 0234
  AC25.** Isolating the stop (the extracted heartbeat with the AC25 stand-in, 4 loops × 15 under
  4 CPU burners): **12 of 60 recorded kids were still `kill -0`-alive, every one `ps` stat `Z`,
  ppid 1, and still `Z` 0.5 s later.** (run) Deterministic form: 0247 AC3 forces a zombie (a shell
  that backgrounds `sleep 0` then execs into `sleep 8`, so it never reaps it).
- **Fix (FR4)** at the case: `heartbeat_survivors` counts a pid only if `ps -o stat=` finds it and it
  is not `Z`, after a settle of up to 2 s for a pending SIGTERM; a real orphan sleeps 9 s, so it still
  reds. After the fix the same 3×4 loaded reproduction: **12 of 12 green.** (run)
- **FR1**: `report_clean_copy` carries the copy's re-print-block FAIL lines (or its last 3 lines if it
  died before printing one) into the parent's `bad`, so they are re-printed at the parent's end too.
  The old message's "red for a reason named above" was false and is gone.
- **Mutations (all run, each restored and the file green after):** `running_pid` → `kill -0` reds
  0247 AC3 (`reported ' 27114 27112' for a zombie 27114 and a running 27112`); the message reverted to
  the `8c2d838` tally-only text reds 0247 AC1; the not-green branch turned into a `skip` reds 0247 AC1
  (`counted 0 failure(s)`).
- **Performance row:** still exactly two `"$CHILD"` runs. The file went 33 s → 38.5 s, wall-clock,
  one sample each: AC3's live control spends the 2 s settle once per generation (parent and two
  children). No third child.
- Whole suite (`unit_by_file` form) once at `37459a5`: every file green, `git status` clean.
  AC4's five full-loop runs are verify's observation.
