---
id: "0190"
title: Re-argue the sprint skill's size exemption against its current size, or relocate
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0040", "0035", "0180"]
expects:
  - tests/skill-size.test.sh
  - skills/sprint/SKILL.md
claimed_by: "6d2e"
claimed_at: 2026-10-26T01:55:37Z
ac_digest: AC1=a4716eef AC2=72ea4e63 AC3=a4efcede AC4=8248d2f4 AC5=5383b1a3 AC6=6874b554
touches:
---

## Problem

**`tests/skill-size.test.sh` records `skills/sprint/SKILL.md` as over the goal with a reason argued
from "the ~2,100 bytes that put this file over" (0040), but the file is now about 32,000 bytes
over, and the guard has no upper bound on a recorded file.**

Measured by develop 0180 (token 30db): 49,675 bytes before 0180 (29,485 over the 20,190 goal), and
52,288 after. Checked 2026-09-25: 52,300 bytes, and the retro that filed this row added about 700
more. Every ticket that grows the sprint skill passes against a reason that no longer describes the
file. 0180's design note asked the build not to raise the cap silently, and there is no cap to
raise.

## Functional requirements

- **FR1** — The sprint skill's recorded reason is argued against its current size, or the file is
  brought under that reason by relocation.
- **FR2** — Whatever design decides about a size bound, the decision is stated in the test's header
  beside the payback test, so the next over-goal file inherits it.
- **FR3** — Every recorded exemption carries the byte size it was argued at, as a field the guard
  reads and never inside the reason's prose (0035 FR6 keeps the prose number-free). The guard reds a
  recorded file that has grown more than `MARGIN` bytes past that size, naming the file, its size,
  the argued-at size, and asking to re-argue its reason or relocate.
- **FR4** — `MARGIN` is one absolute constant, 5,000 bytes, with its derivation in the header beside
  the payback test. Absolute, never a share of the argued-at size: rent is paid per byte, and a
  proportional margin gives the largest files the most slack.
- **FR5** — The other recorded files are seeded at their size on the build commit, and the header
  says so as a dated grandfathering by 0190, not as a re-argument of their reasons.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | A recorded exemption describes the file it exempts | the sprint skill grown past the size its reason names, with the guard still green | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `tests/skill-size.test.sh`, when the `skills/sprint/SKILL.md` entry is read, then it cites 0190, names Step 7's lock and cap-kill recovery and the design-beside rule as what was considered relocating, says why each was rejected, and carries no number of four or more digits after its ticket id; and the "0035 AC4/FR6" loop includes `skills/sprint/SKILL.md`.
- [ ] AC2 — Given a recorded fixture file with no argued-at size, when the guard runs, then it reds and names the file as missing its argued-at size.
- [ ] AC3 — Given a fixture recorded at argued-at size S (generated, independent of the real tree), when the file is exactly S + `MARGIN` bytes then the guard passes, and when it is S + `MARGIN` + 1 bytes then it reds with a line naming the file, its size, S, and the words "re-argue its reason or relocate".
- [ ] AC4 — Given the FR7 fixture that today asserts a recorded file far over the goal passes, when this ships, then that case asserts the opposite: a recorded file 30,000 bytes past its argued-at size reds; the cases that a recorded file just over the goal passes and a recorded file under the goal goes stale still pass.
- [ ] AC5 — Given the header above `set -eu`, when it is read, then it states `MARGIN`, its value, its derivation, that the argued-at size is a separate field never written into a reason, and the 0190 grandfathering of the other recorded files; header-grep cases in the same file red when any of `MARGIN`, `argued at`, or `0190` is missing.
- [ ] AC6 — Given the real tree, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then every file passes, and `skills/sprint/SKILL.md` passes because its argued-at size is its size on the build commit.

## QA plan

Unit, in `tests/skill-size.test.sh`.

## Out of scope

- The other over-goal skills, except as the rule FR2 states reaches them.

## Notes & decisions

- 2026-09-25 — filed by retro from develop 0180's finding (token 30db).
- 2026-10-25 — **design (token a309): re-argue, do not relocate; and give every recorded reason
  an argued-at size with a 5,000-byte margin.** Measured on 2026-10-25 at 6054c59: the sprint skill is 60,813 bytes (40,623
  over the 20,190 goal), not the ~52,300 the problem quotes. Section sizes: cost header 1,229;
  Step 1 5,998; proposal 7,002; Step 2 4,803; design beside 3,958; Step 3 9,192; Step 4 3,554;
  Step 5 5,683; Step 6 6,811; Step 7 3,839; Step 8 1,786; Step 9 4,573.
  - **Payback test, section by section.** Ten of the twelve sections are on every run's main path
    — the checks, the proposal (once per run, mandatory before any dispatch), the cycle, dispatch,
    outcome read, run log, findings gate, never-list, report — so the share skipping them is zero
    and they fail (a). The only two branches a run can skip are Step 7 (a lock met or a stage killed
    by its cap) and *Design beside other stages*. Both fail (b): Step 7 is mandatory the moment a
    lock is met (failure: a driver stealing a working stage's lock), and the design-beside rule is
    what tells the supervisor not to override `--drive`'s step-over or exit 6 (failure: design
    citing files a running develop is editing). Neither clears (a) either: since 0188 keeps design
    one sprint ahead, design-beside is taken on most runs. **No section relocates.** The B0 of
    ~17,000 is computed for a 37-turn session; a supervisor session runs longer, which lowers B0
    and makes relocation pay *more* readily — and still changes nothing, because (b) outranks the
    arithmetic. Supervisor turns per session are unmeasured; the conclusion does not depend on them.
  - **Rejected: compress the story out of the sections** (the 0035 KEEP RULE + FAILURE, MOVE THE
    STORY rule). That is a cut across a multi-writer file, not a relocation, and it is a ticket of
    its own sized against which sentences are story; it does not belong inside a guard fix.
  - **Bound: yes.** The alternative the question names — a reason that stays silently true forever
    — is what happened: 0040 argued at ~22,300 bytes, and the file tripled under it. 0035 FR6 kept
    byte counts out of the prose because a number in prose goes stale silently; a number the guard
    *reads* reds instead, which is the opposite. So the size lives in a separate field, never in the
    reason.
  - **Margin 5,000 bytes, absolute.** A quarter of the goal, ~1,240 tokens. Below it, the growth is
    a block whose relocation needs ~77% or more of runs to skip it (p = 1/(1 + 5,000/17,000)), so a
    re-argument would rarely find anything. At the observed growth (0180 alone added ~2,600) it asks
    every two or three growing tickets rather than every one. **Rejected:** a proportional margin
    (gives the biggest files the most slack, backwards for per-byte rent); a margin of B0 (17,000 —
    nearly the whole goal, so it would have let the sprint skill grow most of the way to where it is
    unexamined); no margin (every growing ticket re-argues, which trains sessions to rubber-stamp).
  - **Trade-off accepted:** the sprint skill keeps ~15,000 tokens of rent on every supervisor turn,
    and the guard will interrupt a ticket that grows a recorded file past its margin with a
    re-argument it did not ask for. That interruption is the point.
  - **Grandfathering.** The other five recorded files would red the moment the bound lands if seeded
    at the sizes their reasons were argued at, which nobody recorded. Seeding them at their size on
    the build commit is a re-blessing, and FR5 makes the header say so rather than let it pass as a
    re-argument; a finding asks for their re-argument as separate rows.
  - **Criteria accounting.** FR1 and FR2 confirmed (FR1 by re-argument). Added FR3–FR5 and AC1–AC6.
    `qa_level: unit` and `close_by: verify` re-read and kept — every criterion is a case in one test
    file. `touches:` set to the one file the build edits; `skills/sprint/SKILL.md` is read, not
    written.
- **2026-10-25 (develop, 537f)** — Built in `cf8eb22` and `cb01eec`, all in
  `tests/skill-size.test.sh`; `skills/sprint/SKILL.md` was read, not edited.
  - **Mechanism.** `argued_at()` is a second case table beside `justification()`. `offenders` takes
    it as a third lookup and reports a recorded file in three ways: under the goal (stale reason), missing
    its argued-at size, or more than `MARGIN` past it. The seeds are the sizes at the build
    commit: sprint 60813 (argued by 0190), and develop 50862, queue 48538, verify 45522,
    retro 30034 and prototype 25361 (grandfathered). Retro's figure includes 0177's addition
    from earlier in this session (`c8606bc`).
  - **Beyond the letter, recorded so verify can judge it.** The 0035 AC4/FR6 loop now reads its
    files from the `justification` table instead of a hand-kept list. That brings retro in as well
    as sprint, the gap design 0190's finding named. Retro's reason passes both checks.
  - **A gap the sweep found and this build fixed.** The FR6 regex `[0-9]{4,}` cannot see a
    comma-grouped number. The old sprint reason's `~2,100` is exactly such a number, so adding
    sprint to the loop alone would never have reddened it. Commas are now stripped before the
    match (`cb01eec`).
  - **Clause table, every mutation run against the committed file, with a control of 45/0 after.**
    The first pass's greens were artefacts. A file-wide `sed` also rewrote the test's own expected
    phrases, and one phrase occurs twice in the sprint reason. Those were re-run with line-scoped
    mutations, and all went red.

    | AC clause | Guard | Mutation → result |
    |---|---|---|
    | AC1 cites 0190 / names Step 7's lock and cap-kill recovery / the design-beside rule / why rejected | `0190 AC1 — the sprint reason names …` (4 cases) | design-beside removed → 1 FAIL |
    | AC1 no number of four or more digits | 0035 FR6 check, commas stripped | `~2,100` reinserted → 1 FAIL |
    | AC1 loop includes sprint | `0190 AC1 — the loop includes skills/sprint/SKILL.md` | sprint unrecorded → 6 FAIL |
    | AC2 missing argued-at size reds, named | `0190 AC2` | branch deleted → 1 FAIL |
    | AC3 exactly S+MARGIN passes | `0190 AC3` pass case | `-gt` → `-ge` → 1 FAIL |
    | AC3 S+MARGIN+1 reds naming file, size, S, "re-argue its reason or relocate" | `0190 AC3` fail case | bound +1 → 1 FAIL; remedy words dropped → 2 FAIL |
    | AC4 30,000 past reds; just-over passes; under goes stale | FR7 cases | no upper bound → 2 FAIL |
    | AC5 `MARGIN`, value, derivation, separate field, 0190 grandfathering | `0190 AC5` (6 header phrases) | value → 1, grandfathering → 1, field → 1 FAIL |
    | AC6 sprint passes at its build-commit size | real-tree AC1 | sprint argued-at deleted → 1 FAIL |
    | FR4 the constant itself | `MARGIN=5000` feeds AC3 | 50000 → 1 FAIL |
  - AC6: the whole suite is green at `cb01eec`.

## QA evidence

**2026-10-25 — verify (token 6d2e), at `3fbaff7` (build `cf8eb22`, `cb01eec`).** PASS.

Conventions: ../ai-building-conventions
Command (`commands.unit_by_file`, verbatim): `for t in tests/*.test.sh; do "$t" || true; done`, with each file's last line captured. 37 files, every one `N passed, 0 failed`; `tests/skill-size.test.sh: 45 passed, 0 failed`.
`ac_digest`: `./next --ac-digest 0190 --check` → `0190: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2. Its only dirt afterwards was this pass's own scratch directory, since removed. Dirty set ∩ evidence set = ∅, so not advisory.
Copy executed: the repo's `tests/skill-size.test.sh`. No skill file changed.
Evidence set: `tests/skill-size.test.sh`, `skills/*/SKILL.md` (sizes read), `skills/sprint/SKILL.md` (60813 bytes).

Clause table. I re-ran every mutation myself against the committed file. Each one was applied to a single line or to the header only, its diff checked non-empty, and the file restored by path afterwards. Control after the set: 45 passed, 0 failed.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | Given the sprint entry, it cites 0190 | `0190 —` → `0040 —` in the reason | 1 FAIL |
| AC1 | names Step 7's lock and cap-kill recovery | phrase cut to `Step 7` | 1 FAIL |
| AC1 | names the design-beside rule | first of 2 occurrences removed | green: the phrase survives in the same reason, so this is not a gap by the gap test. Both removed → 1 FAIL |
| AC1 | says why each was rejected | `rejected on both conditions:` → `dropped:` | 1 FAIL. The guard checks for the phrase. I read each per-branch reason myself: Step 7 → lock stolen; design-beside → step-over overridden |
| AC1 | no number of 4+ digits after the ticket id | `~2,100 bytes` inserted | 1 FAIL (0035 FR6, commas stripped) |
| AC1 | the 0035 AC4/FR6 loop includes sprint | sprint entry renamed out of the table | 6 FAIL |
| AC2 | recorded, no argued-at size → reds, named | missing-size branch disabled | 1 FAIL |
| AC3 | exactly S+MARGIN passes | `-gt` → `-ge` | 1 FAIL |
| AC3 | S+MARGIN+1 reds | bound moved +1 | 1 FAIL |
| AC3 | the line names its size | size dropped from the message | 1 FAIL |
| AC3 | the line names S | argued-at size dropped from the message | 1 FAIL |
| AC3 | the line says "re-argue its reason or relocate" | remedy words dropped | 2 FAIL |
| AC4 | 30,000 past the argued-at size reds | upper-bound branch disabled | 2 FAIL |
| AC4 | just over the goal still passes | stale threshold moved to GOAL+1 | 2 FAIL |
| AC4 | under the goal still goes stale | stale branch disabled | 1 FAIL |
| AC5 | header states `MARGIN` | header-only `MARGIN` → `MRGN` | 2 FAIL |
| AC5 | its value | `5,000 bytes` reworded | 1 FAIL |
| AC5 | its derivation | `Derivation:` → `Basis:` | 1 FAIL |
| AC5 | `argued at` | header-only → `reasoned at` | 1 FAIL |
| AC5 | separate field, never written into a reason | phrase reworded | 1 FAIL |
| AC5 | 0190 grandfathering | header-only `0190` → `0x90` | 1 FAIL |
| AC6 | sprint passes at its build-commit size | argued-at 60813 → 50000 | 1 FAIL (`10813 past the 50000`) |
| FR4 | `MARGIN` is 5,000 | `MARGIN=50000` | 1 FAIL |

| NFR | Check | Result |
|---|---|---|
| Documentation — a recorded exemption describes the file it exempts | AC4/AC6 mutations: a recorded file grown past its argued-at size + MARGIN reds | holds, guarded |
| Always-on (CONVENTIONS_CORE) | diff confined to one test file; no secrets, no company material, no magic number without a named constant (`MARGIN`, `GOAL`) | holds |

Beyond the letter, accepted: the FR6 loop now reads its files from the `justification` table, which also brings retro in. Retro's reason passes both checks.
