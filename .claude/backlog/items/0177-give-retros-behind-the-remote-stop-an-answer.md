---
id: "0177"
title: Give retro's behind-the-remote stop an answer for a pass with nobody to ask
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0113"]
expects:
  - skills/retro/SKILL.md
  - tests/remote-anchor.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` Step 3 stops the pass when a repo it would edit is behind the remote and leaves the pull to
the user — and a `sprint`-dispatched pass has no user to ask, so a whole rung of the destination
ladder silently goes unavailable.**

Observed on 2026-09-21. The dispatched retro resolved two repos: the conventions repo at
`ahead 5, behind 30` and the tools repo at `ahead 11, behind 0`. Nothing could be landed in the
conventions repo, so Step 3's rungs 4 and 5 — *the convention that was cited* and *an always-loaded
file* — were unavailable for the entire pass, and all six edits went to the tools repo instead.

Step 5 already has the matching clause for the other half of the same problem: *Nobody to ask — an
`sprint`-dispatched run — does not invoke the chain*, and reports every remaining step outstanding.
So a dispatched pass has an explicit answer for the push and none at all for the pull, on a step
whose own instruction is to stop.

The two honest fallbacks are not the same, and which one is right turns on routing. Where no
surviving finding is destined for the stale repo, skipping it and reporting costs nothing. Where one
is, continuing quietly is the expensive case: the lesson either lands nowhere or gets re-routed onto
a rung it does not belong on, in a repo that merely happens to be current — and Step 3's own
*generalising early* and *generalising late* test is exactly what that re-route breaks.

## Functional requirements

- FR1 — Step 3 says what a pass with nobody to ask does when a resolved repo is behind: the pass
  continues over the repos that are current, and the stale repo is **unavailable**, never pulled.
- FR2 — A surviving finding whose destination is an unavailable repo is left in `FINDINGS.md`
  undispositioned, and is never re-routed down the ladder to a repo that happens to be current.
- FR3 — The report names every repo skipped, its divergence, and every finding left in the buffer
  because of it, and the outstanding pull appears on the same run checklist Step 5 already uses for
  the outstanding release chain.
- FR4 — The attended behaviour is unchanged: being behind still stops an attended pass, and the pull
  is still the user's call.
- FR5 — `tests/remote-anchor.test.sh` carries guards for FR1, FR2 and FR3's clauses in Step 3's
  window, alongside the AC1 check it already makes there.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | Step 5's nobody-to-ask clause is cited from Step 3, never copied into it; the two must not be able to disagree | `tests/citations.test.sh` | `documentation-conventions.md` |
| Observability | An unavailable destination is loud — named with its divergence and with what was left unlanded — rather than a pass that reads as complete | A guard asserting Step 3 requires the skipped repo and the left findings in the report; reddened by deleting that clause | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 3, when `tests/remote-anchor.test.sh` runs, then a guard asserts the pass with nobody to ask continues over the current repos and treats the stale one as unavailable — reddened by deleting that clause.
- [ ] AC2 — Given the same file, when `tests/remote-anchor.test.sh` runs, then a guard asserts a finding destined for an unavailable repo stays in the buffer — reddened by changing that clause to re-route the finding down the ladder.
- [ ] AC3 — Given the same file, when `tests/remote-anchor.test.sh` runs, then its existing AC1 check for `Behind the remote stops the pass` in Step 3's window still passes — reddened by removing that phrase while adding the unattended clause.
- [ ] AC4 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it is green — reddened by leaving `skills/retro/SKILL.md` over its size budget after the addition.

## QA plan

- **Why that level:** a prose rule in a shipped skill, guarded by this repo's shell suite, which is
  the only runner the project has.
- **Specific checks:** `tests/remote-anchor.test.sh`, `tests/citations.test.sh`,
  `tests/skill-size.test.sh`.

## Out of scope

- Letting any session pull on the user's behalf. The pull stays the user's call
  (`git-conventions.md`); this item only says what happens when nobody can make it.
- `tools/release`'s own behind-the-remote refusal, which is correct and guarded by
  `tests/release.test.sh` (`0075`, `0084`).
- Step 5's release chain for a dispatched run, which already has its clause.
- `0113`'s question of what the one-line release report looks like across several repos.

## Notes & decisions

- **2026-09-21 (queue sweep)** — Filed from a `FINDINGS.md` entry parked by the 2026-09-21 retro.
  Routed to `develop`, not `design`: the entry reads as an open choice between "skip and report" and
  "stop the pass", but Step 5's nobody-to-ask clause already settles that shape for the push in the
  same file, and FR2 is what makes skipping safe. No surface and no undecided pattern, so it is a
  `develop` row.
- **2026-09-21 (queue sweep)** — `tests/remote-anchor.test.sh` asserts the literal phrase
  `Behind the remote stops the pass` inside Step 3's window (AC1, and again at its fixture). The
  change is an **addition** beside that sentence, never a rewrite of it, and AC3 is the guard on
  that constraint — `queue`'s rule that a QA plan's absence assertions are checked against the
  guards already shipped.
