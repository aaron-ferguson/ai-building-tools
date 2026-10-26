---
id: "0190"
title: Re-argue the sprint skill's size exemption against its current size, or relocate
type: bug
next: develop
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
claimed_by: "537f"
claimed_at: 2026-10-26T01:19:52Z
ac_digest: AC1=a4716eef AC2=72ea4e63 AC3=a4efcede AC4=8248d2f4 AC5=5383b1a3 AC6=6874b554
touches:
  - tests/skill-size.test.sh
  - skills/sprint/SKILL.md
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
