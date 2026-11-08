---
id: "0177"
title: Give retro's behind-the-remote stop an answer for a pass with nobody to ask
type: bug
next:
status: done
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
closed: 2026-10-26
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
| Documentation | Step 5's nobody-to-ask clause is cited from Step 3, never copied into it; the two must not be able to disagree | `tests/remote-anchor.test.sh`, case *0177 NFR — Step 5's clause is cited, not copied*, reds on deleting the citation; a copy of the clause written beside the citation: prose only — no artifact yet | `documentation-conventions.md` |
| Observability | An unavailable destination is loud — named with its divergence and with what was left unlanded — rather than a pass that reads as complete | A guard asserting Step 3 requires the skipped repo and the left findings in the report; reddened by deleting that clause | `observability-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/retro/SKILL.md` Step 3, when `tests/remote-anchor.test.sh` runs, then a guard asserts the pass with nobody to ask continues over the current repos and treats the stale one as unavailable — reddened by deleting that clause.
- [x] AC2 — Given the same file, when `tests/remote-anchor.test.sh` runs, then a guard asserts a finding destined for an unavailable repo stays in the buffer — reddened by changing that clause to re-route the finding down the ladder.
- [x] AC3 — Given the same file, when `tests/remote-anchor.test.sh` runs, then its existing AC1 check for `Behind the remote stops the pass` in Step 3's window still passes — reddened by removing that phrase while adding the unattended clause.
- [x] AC4 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it is green — reddened by leaving `skills/retro/SKILL.md` over its size budget after the addition.

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
- **2026-10-25 (queue sweep)** — A second observation of this defect, on the tools repo at
  `behind 1` (a concurrent capture moving `next_id`), cost a full second pass over a 16-entry buffer
  under this ticket's own FR2 answer. Its proposed alternative — fast-forward a clean, behind-only
  checkout — is this ticket's *Out of scope* line and is now `0216`, ranked directly above. This
  ticket's FRs stand whatever `0216` decides.
- **2026-10-25 (develop, b472)** — Built in `c8606bc`. Step 3 gains one paragraph *beside* the
  stop, never replacing it (AC3's `Behind the remote stops the pass` untouched). Step 5's clause is
  cited by name (`Step 5's *Nobody to ask* clause`), not restated. The prose uses the ACs' own
  words verbatim so the guards assert them, not a paraphrase.

  Clause table (AC → guard phrase in Step 3's window, all in `tests/remote-anchor.test.sh`):

  | AC clause | Guard phrase | Mutation (run) |
  |---|---|---|
  | AC1 Given `skills/retro/SKILL.md` Step 3 | window `## Step 3 — Check the destination` → `## Step 4` | existing empty-window case |
  | AC1 continues over the current repos and treats the stale one as unavailable | `pass with nobody to ask continues over the current repos and treats the stale one as unavailable` | line deleted → 1 FAIL; fixture case also in-file |
  | FR1 never pulled | `stale repo is never pulled` | deleted → 1 FAIL |
  | AC2 a finding destined for an unavailable repo stays in the buffer | same phrase | deleted → 1 FAIL; re-route sed fixture red in-file |
  | AC2 re-route down the ladder | `never re-routed down the ladder` | deleted → 1 FAIL |
  | FR3 skipped repo + divergence | `names each repo skipped with its divergence` | deleted → 1 FAIL |
  | FR3 findings left | `every finding left in the buffer because of it` | deleted → 2 FAIL (line also holds the checklist phrase) |
  | FR3 run checklist | `the pull is outstanding on that run's checklist` | deleted → 2 FAIL |
  | NFR cite, never copy | `Step 5's *Nobody to ask* clause` | deleted → 2 FAIL |
  | FR4 attended stops | `An attended pass still stops` | deleted → 2 FAIL |
  | AC3 stop kept | `Behind the remote stops the pass` (pre-existing) | deleted → 1 FAIL |

  All mutations **run** against the committed file, restored from a copy; control run 46/0 after.
  AC4: whole suite green. `skills/retro/SKILL.md` is over the 20,190-byte goal under its existing
  `b9a5ee0` justification, which carries no upper bound, so the addition cannot red the size guard.
  One whole-suite loop saw `tests/sprint.test.sh` exit non-zero once; an immediate rerun was 368/0
  and it did not reproduce (parked in `FINDINGS.md`).
- **2026-10-25 (0183's build, token 48b5)** — The Documentation row's *How it would red* cell was
  `tests/citations.test.sh` alone, a file with no duplication check, and `tests/item-nfr-red.test.sh`
  (0183) reds on a bare file reference. Re-specified under 0183 FR4 to name the case that does red,
  deleting the citation, and to say plainly that a *copy* written beside the citation is unguarded
  (`prose only — no artifact yet`). Nothing else in this item changed; verify should treat that
  half as prose under Step 4.

## QA evidence

**2026-10-25 (verify, token dc3b)** — PASS at `qa_level: unit`, against `HEAD` 325cf94 (build `c8606bc`).

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`, so every file reports); 37 files, every one exit 0.
Tree: `git status --porcelain` empty at Step 2; at the verdict it showed only this pass's own scratch dir `.qa-0177/` (since removed), so the intersection with the evidence set is empty and the verdict is not advisory.
Executed copy: the repo copy of `skills/retro/SKILL.md` and `tests/` (the subject under test). This session's verify skill ran from the 0.9.43 install.
`ac_digest absent — unverifiable`: no stamp to compare the criteria against, so the ACs were checked literally as they read on disk.

Clause table: reused develop's (Notes & decisions, b472). Every mutation below was **re-run by this pass** against the committed file and restored from a scratch copy. Each diff was confirmed non-empty, and a control run followed.

| AC / NFR | Check | Mutation (run by verify) | Result |
|---|---|---|---|
| AC1: continues over the current repos, stale one unavailable | `tests/remote-anchor.test.sh` case *0177 AC1* in Step 3's window | deleted the bold AC1 sentence | red: 45 passed, 1 failed (0177 AC1) |
| FR1: never pulled | case *0177 FR1* | `never pulled` → `pulled` | red: 1 failed (0177 FR1) |
| AC2: finding stays in the buffer, not re-routed | cases *0177 AC2* and *FR2* | rewrote the clause to "is re-routed down the ladder" | red: 44 passed, 2 failed |
| AC3: `Behind the remote stops the pass` kept | existing case *AC1 — being behind stops the pass* | phrase → "Behind the remote warns" | red: 45 passed, 1 failed |
| AC1–3 window scoping | in-window matcher | moved the whole unattended paragraph under `## Step 4` | red: 37 passed, 9 failed |
| AC4: whole suite green, size budget | `tests/skill-size.test.sh` | appended 5,100 bytes to the retro skill (35135 bytes) | red: "5101 past the 30034 bytes its reason was argued at, over the 5000 margin". Develop's note that the size guard "cannot red" no longer holds: 0190 has since bounded it, so AC4 is now guarded |
| NFR Documentation: cited, not copied | case *0177 NFR — Step 5's clause is cited* | replaced the citation with "the one the release chain is on" | red: 1 failed. The *copy* half is `prose only — no artifact yet`. On reading, Step 3 names Step 5's *Nobody to ask* clause and does not restate it, so it holds, unguarded |
| NFR Observability: loud report | cases *0177 FR3* ×3 | collapsed the report sentence to "The pull is outstanding," | red: 43 passed, 3 failed |
| FR4: attended pass still stops | case *0177 FR4* | deleted the sentence | red: 1 failed |

Controls after restore: `tests/remote-anchor.test.sh` 46 passed, 0 failed; `tests/skill-size.test.sh` 45 passed, 0 failed; `tests/citations.test.sh` 51 passed, 0 failed.

Step 4: the change is prose in a shipped skill. It makes no new action reachable: it narrows a dispatched pass to *not* pulling. It adds no log field, egress, auth or UI, and holds no company material. Read against CONVENTIONS_CORE always-on rules: no conflict.
