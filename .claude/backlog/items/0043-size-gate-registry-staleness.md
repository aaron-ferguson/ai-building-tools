---
id: "0043"
title: Make the two size gates fail on a registry entry that no longer resolves
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0028", "0033", "0035"]
expects:
  - tests/skill-size.test.sh
  - tests/reference-size.test.sh
  - MEASUREMENT.md
claimed_by:
claimed_at:
touches:
---

## Problem

Both size gates hold a `justification()` registry mapping a file path to the reason it is over its
byte goal and the ticket that accepted the cost. `offenders()` walks the **tree** and looks the
path up; it never walks the **registry** and checks the path still resolves. So an entry pointing
at a file that no longer exists is never reached, and the gate passes.

Proved on `tests/reference-size.test.sh`: removing `references/CONCURRENCY-INCIDENTS.md` while its
`case` branch stayed left the gate green at 9/0, exit 0 — the pass line simply stops naming it.
`tests/skill-size.test.sh` has the identical shape. This is the staleness the gates' own recorded
reasons exist to prevent, arriving from the one direction they do not look, and it is a live risk
precisely because the gates' first recommendation is **relocation** — the operation most likely to
rename a file out from under its entry.

Two more citations in the same two files that nothing checks resolve:

- **The ticket id in each entry.** The registry's stated contract is "the ticket that accepted the
  cost", and a wrong id is invisible because the reason is the control, not a number — the test
  passes either way. `skills/develop/SKILL.md`'s entry once read `0027`, a ticket that never
  touched that file; 0035 corrected it, but nothing stopped it and nothing would stop the next.
- **`tests/skill-size.test.sh`'s header constant.** The header instructs a reader to RECOMPUTE B0
  whenever the rates move, and says "Every figure is measured and lives in MEASUREMENT.md:
  4.038 bytes/token, $6.25/MTok cache write … $0.1028 per turn, and 1,112 turns across 30
  sessions". Four of the five are there. **`4.038` is not in `MEASUREMENT.md` at all** — confirmed,
  as is the absence of any `bytes/token` figure; `git log -S` puts its origin in 0021's own guard.
  The bad case is not a wrong number today but a session that follows the pointer to recompute,
  finds four inputs, and either invents the fifth or trusts a stale constant — the exact failure
  writing the derivation down was meant to prevent.

## Functional requirements

- FR1 — Both gates iterate the recorded registry and fail when an entry names a path that does not
  exist, reporting the path and the entry.
- FR2 — Both gates fail when an entry's ticket id does not resolve to a file under
  `.claude/backlog/items/`, reporting the id and the entry.
- FR3 — The registry-side sweep of FR1 and FR2 exists **once** and is used by both gates, or each
  gate's copy carries a comment naming the other, so the two cannot drift the way the `offenders`
  copies already have.
- FR4 — `tests/skill-size.test.sh`'s header no longer cites `MEASUREMENT.md` as the source of a
  figure that file does not carry. Either the bytes-per-token ratio and its provenance are landed
  in `MEASUREMENT.md`, or the header's claim is narrowed to the figures that are there and says
  where the ratio came from.
- FR5 — Each new failure path carries a comment naming the mutation that reds it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whichever way FR4 resolves, the provenance of the bytes-per-token ratio is written down where the header points, in the same change | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the repaired `tests/reference-size.test.sh`, when a registry entry is added for a
  path that does not exist, then the gate fails naming that path.
- [ ] AC2 — Given the repaired `tests/skill-size.test.sh`, when a registry entry is added for a
  path that does not exist, then the gate fails naming that path.
- [ ] AC3 — Given either repaired gate, when a registry entry's ticket id is changed to one with no
  item file, then the gate fails naming that id.
- [ ] AC4 — Given either repaired gate on the unmutated tree, when it runs, then every recorded
  entry resolves to an existing file and an existing ticket, and the gate passes.
- [ ] AC5 — Given `tests/skill-size.test.sh`'s header, when every figure it names as living in
  `MEASUREMENT.md` is grepped for in that file, then every one of them is found.
- [ ] AC6 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs on
  an unmutated tree, then every suite passes.

## QA plan

- **Level:** unit — the deliverable is executable guards, and this project's `unit` command runs
  every `tests/*.test.sh`.
- **Why this level:** every AC is a mutation of a registry entry followed by a run; no seam is
  crossed and no build is involved.
- **Specific checks:** drive AC1–AC3 one mutation at a time, confirming each landed by diffing
  against a copy taken before the edit rather than against HEAD, and reverting before the next.
  AC5 is a loop over the header's named figures. Then the full suite clean.

## Out of scope

- **Extracting the shared `offenders`/`pad`/`ok`/`bad` shape into one helper.** That is the DRY
  question `0028` deliberately deferred until a third prose directory earns a goal; FR3 asks only
  that the *new* registry sweep not become a fourth copy. Note the two existing copies have already
  diverged in one way worth keeping — the reference gate carries an AC7 grep the skill gate has no
  equivalent of — so the extraction is not a pure lift.
- Changing either byte goal, or any recorded justification's reasoning.
- `references/TRACKER.md` sitting 35 bytes under its goal. The gate doing its job on the next
  sentence added is not a defect; deciding what happens then is its own ticket.

## Notes & decisions

- Routed to `develop`: the defect, the direction of the fix (walk the registry, not just the tree)
  and the failing mutation are all named, so nothing is left to decide.
- FR2 asserts **membership** — that the cited ticket exists — not that it is the *right* ticket.
  Asserting the latter would need the gate to know which ticket touched which file, which is
  git history, not a test.
