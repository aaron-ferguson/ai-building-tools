---
id: "0150"
title: Make design hold its row with claim from Step 1, and release it with handoff
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: s
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0134", "0056", "0048"]
expects:
  - skills/design/SKILL.md
  - tests/design-hold.test.sh       # new; not claim.test.sh or handoff.test.sh, which 0083 holds
claimed_by:
claimed_at:
touches:
closed: 2026-09-12
---

## Problem

**`design` reasons over a row nobody holds, and only discovers who else is on it when it goes to
write.** `skills/design/SKILL.md` names no claim anywhere: Step 4's unclaimed path says "you write
it, here, now … commit by pathspec", and its intro decides between writing and handing off by
reading `claimed_by:` at the *end* of the pass. Observed 2026-09-12 (FINDINGS, token `d08c`, commit
`8d38048`): `./next design` offered 0134 as `TAKE`, the session spent its whole Step 2–3 pass on
it, and found the row `in-progress` under another session only at Step 4 — so the decision could
only be handed back. Two sessions reasoning over one ticket is the failure `develop`'s claim step
exists to prevent, in the one stage that spends before it claims.

**It also blocks `0134`.** A sprint that dispatches design alongside develop re-calls
`./next --drive` after the dispatch; unless the design session's row reads held, `--drive` returns
exit 4 on the same row and the supervisor starts a second design session on the one ticket (0134
FR5, AC8). The supervisor may not claim for it (`skills/sprint/SKILL.md`, *It never claims a row
and never mints a claim token*).

**No script needs to change — this was run, not read.** In a scratch copy of the backlog on
2026-09-12 (0134's design pass, token `7a94`): `./claim` takes a `next: design` row (rc 0, and
declines to seed `touches:` because design does not build); `./next --drive` then prints
`NOTE 0134 is in-progress — another session holds it; stepping over it`; `./handoff <id> <token>
develop` and `./handoff <id> <token> design waiting` both release it; a second `./claim` on the held
row refuses with `is 'in-progress', not ready`.

## Functional requirements

- FR1 — `design` Step 1, for a ticket at `next: design`, takes the row with `./claim <id>` before
  any Step 2 reading. A refusal means another session holds it: stop and report, having spent
  nothing on the question.
- FR2 — Step 4's write path is the **held** path: the session writes under the token it minted and
  releases the row with `./handoff`, to `develop` when the decision unblocks criteria and to
  `design waiting` when the answer has to be seen. It no longer says to commit a stage change by
  pathspec by hand.
- FR3 — A pass that stops without deciding releases with `./handoff <id> <token> design ready`
  rather than walking away with the claim held.
- FR4 — Step 4's *claimed by someone else* path stays, and applies to a ticket another token
  holds; the intro's *How to tell* paragraph distinguishes "held by you" from "held by another"
  rather than "unclaimed" from "claimed".
- FR5 — An ad-hoc question with no ticket takes no claim.
- FR6 — The code that executes FR1–FR3 is the existing `.claude/backlog/claim`, `./handoff` and
  `./next`, and a new `tests/design-hold.test.sh` pins that they do so on a `next: design` row: the
  claim, the step-over, the second-claim refusal, and all three releases. No script changes.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Step 1 and Step 4 cite `CONCURRENCY.md` *Claim tokens* and the lock rule rather than restating them | `documentation-conventions.md` |
| Progressive delivery | The skill ships to every install; `0134` stays blocked until this is released and the installed copy verified with `tools/release verify` | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/design/SKILL.md`, when `tests/design-hold.test.sh` greps the Step 1 section
      only, then it names `./claim`. **Red if** the claim is named in Step 4 alone, or not at all —
      today's text.
- [x] AC2 — Given a fixture backlog whose row 1 is `next: design, status: ready` above a
      `next: develop` row, when `./claim` takes the design row and `./next --drive` runs, then drive
      names the develop row and prints the `stepping over it` note for the design row. **Red if** the
      claim leaves the row `ready`, so drive exits 4 on it.
- [x] AC3 — Given that held design row, when a second `./claim` runs on it, then it refuses and the
      row's `claimed_by:` is unchanged. **Red if** a design row is exempt from the ready check.
- [x] AC4 — Given that held design row, when `./handoff <id> <token>` runs with each of `develop`,
      `design waiting` and `design ready` (three fixtures), then each exits 0, clears `claimed_by:`,
      and leaves the row at the named stage and status. **Red if** handoff refuses a row whose
      current stage is `design`.
- [x] AC5 — Given the Step 4 section, when grepped, then it names `./handoff` and no longer contains
      the phrase `commit by` on the unclaimed path. **Red if** the old by-hand stage write survives
      beside the new one.
- [x] AC6 — Given the skill, when grepped, then it states an ad-hoc question takes no claim. **Red
      if** the sentence is absent.
- [x] AC7 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then every
      file reports `0 failed`, including `tests/citations.test.sh` and `tests/skill-size.test.sh`.
      **Red if** the new citations do not resolve or the skill exceeds its size guard.

## QA plan

- **Why that level:** `unit` — the behaviour is three existing scripts on a fixture backlog, which
  the suite already scaffolds; the prose half is scoped greps in the same test file.
- **Specific checks:** `tests/design-hold.test.sh` run alone, then the whole suite. Each grep scoped
  to its step's section and matching a phrase short enough to sit on one line (CLAUDE.md, *rewrapping
  a guarded paragraph is a breaking change*). Prove AC2 and AC4 red by running them against a fixture
  whose row is not claimed first.

## Out of scope

- The rest of `0056` — Step 2's reading list, Step 4's lock citation, the split-work and
  foreclosing-scope cases. That ticket stays whole.
- Any change to `claim`, `handoff` or `next`; FR6 records that none is needed, and all three are
  held by `0083` today.
- `./next design` skipping a row another design session was *offered* but has not claimed — once
  Step 1 claims, the window is one command.
- `0134` itself.

## Notes & decisions

- **2026-09-12 (queue) — filed as its own row rather than as an FR on `0056`.** 0134's design pass
  (`7a94`) settled the mechanism and left the choice to `queue`. `0056`'s notes assign it *"whether
  design claims"*, but its eight FRs are about Step 2's reading list and Step 4's other cases, sized
  `m`; blocking `0134` behind all of them would hold a sprint capability on prose work it does not
  need. A dated line in `0056`'s notes points here.
- **Routed to `develop`:** the mechanism was decided in 0134's notes and proved by running each
  script path. Nothing is open.
- **`tests/design-hold.test.sh` rather than extending `claim.test.sh` / `handoff.test.sh`**, because
  `0083` [`7bf5`] holds both; a new file keeps this row takeable now.
- **Closes the FINDINGS entries of 2026-09-10 (two, the claim half) and 2026-09-12** about design
  working an unheld row; marked `[->0150]`. The lock half of the 2026-09-10 pair is `0056` FR3's.
- **2026-09-12 (develop, `373f`) — built in `670ad93`; no script touched.** The behavioural half
  (AC2–AC4) was green before any prose changed, as FR6 predicted, so its falsifiability rests on two
  controls rather than on a red-first run: the file's own *AC2 control* case (an unclaimed design row
  makes `--drive` exit 4, no step-over) and a throwaway probe where `./handoff 0001 tok0 develop` on an
  unclaimed design row exits 1 with `records no claimed_by:` and leaves `next: design` — so every AC4
  assertion reds without the claim. The prose half (AC1, AC5, AC6, FR4) was red 7/7 before the edit.
- Added beyond the ACs: an FR4 case (`held by you` / `held by another` in the intro) and a
  `design ready` grep on Step 4 for FR3, both scoped and single-line.
- Step 4's held-by-you path now cites *The release is the final act*: `./handoff` is the last write,
  so Notes & decisions and FRs go in before it. Whole suite 31 files, 0 failed — run over `0083`'s
  uncommitted working-tree edits to claim/close/handoff, which were green too.
- Progressive-delivery NFR stands: `0134` stays blocked until a release carries this and
  `tools/release verify` confirms the install.
- **2026-09-12 (verify, `79f4`) — green on all seven ACs; closed only after a release.** The NFR and
  `./close` pull in opposite directions: `close` reconciles `0134` to ready, and `0134`'s blocker is
  exactly "released and verified". The installed 0.9.25 `skills/design/SKILL.md` differed from the
  repo and lacked the Step 1 claim, so a plain close would have unblocked `0134` against an install
  that cannot hold its row. The user chose release-then-close over a `verify waiting` hand-off.

## QA evidence

Verified at `qa_level: unit`, checkout at `5edd97e` (tree clean at Step 2); mutations run in a detached
worktree at `670ad93`, restored by path, control run green (`design-hold: 34 passed, 0 failed`).

| AC / NFR | How checked | Result |
|---|---|---|
| AC1 | `tests/design-hold.test.sh` Step 1 scoped grep. Mutation: drop `./claim` from Step 1 → `FAIL — Step 1 names ./claim`, `33 passed, 1 failed` | PASS |
| AC2 | Fixture claim + `--drive`, plus the file's unclaimed control (exit 4). Mutation: `claim` template stubbed to `exit 0` without writing → `the row reads in-progress`, `drive dispatches`, `drive steps over the design row` all FAIL, `19 passed, 15 failed` | PASS |
| AC3 | Second `./claim` refuses, `claimed_by:` unchanged. Same stub → `the second claim refuses`, `because the row is not ready` FAIL | PASS |
| AC4 | Three fixtures, `develop` / `design waiting` / `design ready`. Mutation: `handoff` template refuses any `next: design` item → every `exits 0` and `claimed_by: is cleared` FAIL, `21 passed, 13 failed` | PASS |
| AC5 | Step 4 scoped grep. Mutation: re-add `commit by pathspec` beside handoff → FAIL; drop `./handoff` from Step 4 → FAIL (each `33 passed, 1 failed`) | PASS |
| AC6 | Whole-skill grep. Mutation: delete the sentence → `FAIL — the sentence is present` | PASS |
| AC7 | Whole suite, run per-file: 31 files, every one `0 failed` (second run). First run showed `item-ac-form.test.sh :: 4 passed, 1 failed`, caused by 0041's in-flight item, fixed by its own session at `19649ec` mid-run; not in this evidence set. `citations` 46/0, `skill-size` 27/0 | PASS |
| NFR Documentation | Step 1 cites `CONCURRENCY.md` *Claim tokens* and *Lock every write to the backlog directory*; Step 4 cites *The release is the final act*; `citations.test.sh` resolves them | PASS |
| NFR Progressive delivery | Installed 0.9.25 copy differs from repo (`diff -q`), lacks the claim sentence (grep count 0); release run before close so `0134` unblocks only against a verified install | PASS after release |

Evidence set: `skills/design/SKILL.md`, `tests/design-hold.test.sh`, `skills/queue/templates/{claim,next,handoff}`, `tests/*.test.sh`. Dirty set at Step 2: empty → not advisory.
