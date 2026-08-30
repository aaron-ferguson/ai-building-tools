---
id: "0051"
title: Pin the measurement record's denominator and make its recipe reproduce
type: bug
next: verify
status: in-progress
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: ["0042"]
relates: ["0026", "0037"]
expects:
  - MEASUREMENT.md
  - README.md
  - tests/measurement.test.sh
  - tools/harvest-usage.sh
claimed_by: "61a0"
claimed_at: 2026-08-30T17:14:00Z
touches:
---

## Problem

`MEASUREMENT.md` is the record README and both size gates cite. Two of its published figures are
wrong today, by the same mechanism, and the guards that should have caught it cannot.

**A pinned numerator over a live denominator.** The record pins its token figures with `--exclude`
and pins its findings count "as at 2026-08-24 06:00Z" — both deliberate, both recorded. But *cost
per closed ticket* divides that pinned `$114.27` by a count of closed tickets read from `DONE.md`,
which is as live as `FINDINGS.md` was. The record says "19 tickets closed on 2026-08-23 and
2026-08-24 … **$6.01 per closed ticket**"; `DONE.md` now holds **27** rows. `README.md` line 48
repeats the 19. The lesson the record itself learned one section earlier was not carried to the
figure beside it.

**A recipe that does not reproduce the record.** *Re-running this* gives
`tools/harvest-usage.sh <store> --since 2026-08-23 --sessions`, which returns far more than the
recorded 30 sessions and $114.27, because more sessions have since landed *inside the same UTC
date* that a `--until` bound cannot separate. The figures are exactly reproducible — every cell of
both tables was reproduced in one pass — but only with twelve `--exclude` flags derived by sorting
sessions on their first timestamp, which the record does not carry. It names two exclusions in
prose ("the session that produced this measurement, and one still in flight") and then asserts
"pin the exclusions and record them, as this one does". That sentence is now false, and `0037` and
`0036` are both named as the re-runners who will follow it.

A date window is not a pin on a live store.

## Functional requirements

- FR1 — Every figure in `MEASUREMENT.md` derived from a live file carries an as-at pin, on both
  sides of the division — the denominator as much as the numerator.
- FR2 — *Cost per closed ticket* states the count of closed tickets it divided by, the date bound
  that produced that count, and is recomputed against the pinned set so the published figure is
  correct as at its own stamp.
- FR3 — `README.md`'s repetition of that figure and its denominator is corrected in the same
  change, so the two files cannot disagree.
- FR4 — *Re-running this* carries the **session-id set** the record was computed from — the
  `--exclude` list in full, or the included ids — rather than a date window and a prose
  description, so the command as printed reproduces the published tables.
- FR5 — Where FR4 is impractical as a flag list, `tools/harvest-usage.sh` gains a timestamp cut
  rather than a date one, and the recipe uses it. Either satisfies FR4; the record must not be left
  asserting a pin it does not carry.
- FR6 — The sentence "pin the exclusions and record them, as this one does" is true when this
  ticket closes, or it is gone.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | Session ids may be published; the transcript-store paths they sit under may not. 0026 failed its own privacy NFR on exactly this and its verdict then republished the leaked slugs while explaining the failure. The check is one `git grep` over the whole change, not over the deliverable alone — a ticket's own prose sits outside every guard the ticket writes | `data-privacy-conventions.md` |
| Documentation | The as-at convention FR1 states is written once, where the next figure added will be read, rather than repeated per figure | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `MEASUREMENT.md`, when *Cost per closed ticket* is read, then it names the
  closed-ticket count, the date bound producing it, and an as-at stamp.
- [ ] AC2 — Given that section's figure, when recomputed from the pinned numerator and the stated
  denominator, then the arithmetic agrees with the published number.
- [ ] AC3 — Given `README.md`, when its closed-ticket figure and denominator are read, then they
  match `MEASUREMENT.md`'s.
- [ ] AC4 — Given *Re-running this*, when the command it prints is run against the store, then it
  reproduces the session count and total the record publishes.
- [ ] AC5 — Given the whole change, when `git grep` is run for the transcript-store path segments
  across every file it touches — the item file included — then none is present.
- [ ] AC6 — Given `tests/measurement.test.sh`, when it runs, then the assertions repaired by 0042
  pass against the corrected record.
- [ ] AC7 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.

## QA plan

- **Level:** unit — the record's arithmetic is already guarded by `tests/measurement.test.sh`, and
  this project's `unit` command runs every `tests/*.test.sh`.
- **Why this level:** AC2 and AC4 are arithmetic and a command re-run, both of which that suite
  already performs; nothing crosses a seam.
- **Specific checks:** `tests/measurement.test.sh` in full, the AC4 re-run against the live store,
  and the AC5 `git grep` over every path in the change. The harvest reads a live store, so pin the
  snapshot before running and record which one — a run taken while another window opens a session
  moves the count under you, which is how the recorded 30 became 31 mid-run once already.

## Out of scope

- **The fresh-project run and its figures.** That is 0037, which produces a *new* measurement and
  by its FR7 keeps 0026's figure as the intermediate data point — so the defect repaired here stays
  published unless it is repaired here.
- Re-running the 2026-08-22 baseline. It stays the published control.
- Repairing the guards themselves. That is 0042, which this ticket is blocked on: correcting the
  record while its assertions cannot fail would leave no evidence the correction held.

## Notes & decisions

- Routed to `develop`: the defect is arithmetic over a stated denominator and a command that does
  not reproduce its own output. FR5 offers two ways to satisfy FR4 because which is practical
  depends on how many exclusions the pinned set needs — a build-time judgement, not a design
  decision, since both land the same observable property.
- `blocked_by: ["0042"]` is a real dependency, not a scheduling convenience: AC6 asserts the
  corrected record against repaired assertions, and those do not exist until 0042 closes.

### From the build (2026-08-30, token 9910)

- **The ticket's own quoted figures were stale caches, both of them.** `DONE.md` holds **30** rows,
  not the 27 the problem statement quotes, and the count that matters — closed on 2026-08-23 or
  2026-08-24 — is **20**, not 19. So the published denominator was wrong on a date-bounded read as
  well, which the problem statement did not claim. Re-read the source before trusting an FR's
  arithmetic about a file the ticket does not own.
- **FR4 and FR5 are not the equal alternatives the ticket presents.** FR5's timestamp cut does not
  work here and cannot be made to: a cut at the harvest moment (2026-08-24T06:00Z) still returns
  **38 sessions / $152.32** against the published 30 / $114.27, because sessions in flight during
  the harvest kept adding turns *inside* the window afterwards. No cut on turn timestamps separates
  a session that was excluded from one that merely grew. Only the id set pins it, so FR4's flag
  list is the only route that lands and the timestamp cut was not built (YAGNI).
- **How the pinned set was recovered, since the record did not carry it.** The per-skill table is
  itself the constraint system: sessions, turns and cost per skill fix how many of each to drop and
  what they must sum to. `develop` had a unique 5-session solution; `verify` had three candidates
  on turns and cost, resolved by which one leaves the published 97,965 context per turn. `queue`
  and `retro` were untouched by later sessions and confirmed the frame. The result reproduces
  **every cell of both tables**, which is what makes it the right set rather than a plausible one.
- **A second live-file claim had already gone false and was not in any FR.** The record said
  "`FINDINGS.md` still holds all 42 — retros are not emptying it". It holds 29 entries as at
  2026-08-30, only 2 of them from those two days: later retros did sweep it. Pinned rather than
  restated, under the same convention as the denominator.
- **Two of the new guards were green against the very mutation they name**, and were only caught by
  running the mutations rather than trusting them. The date-bound assertion passed on the dates
  recurring in the section's closing prose — the 0042 defect reproduced inside the fix for it, at
  section scope instead of document scope. And `grep` read the asserted `--until` as its own
  option, so three flag assertions errored instead of running; the helpers now pass `--` first.
- **Left deliberately: `$6.01` / `$4.45` still appear in `0036`, `0040` and `0041`.** They are stale
  caches of this figure now. Not edited here — `CONCURRENCY.md`'s *A stage writes only the ticket it
  holds* — and parked in `FINDINGS.md` instead.
- `expects:` named `tools/harvest-usage.sh` and it was not touched, because the FR5 branch that
  needed it turned out to be unbuildable. The prediction was reasonable; the ticket offered it
  conditionally and the condition did not fire.
