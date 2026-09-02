---
id: "0073"
title: Measure where a stage session's turns and tokens actually go
type: chore
next:
status: done
qa_level: verify
size: m
created: 2026-08-30
source: user
parent:
blocked_by: ["0051"]
relates: ["0026", "0036", "0037", "0041", "0074"]
expects:
  - MEASUREMENT.md
  - tools/harvest-usage.sh
  - tests/measurement.test.sh
  - README.md
claimed_by:
claimed_at:
touches:
closed: 2026-09-02
---

## Problem

**Isolation cut the floor a session starts from and did nothing to the climb inside it, and nothing
in this backlog says where that climb goes.** `MEASUREMENT.md` names the mechanism in its own
words: *"Isolation resets context per session, not per turn, and a develop session still averages
39 turns, so context still climbs inside each one."* Its per-skill table is the evidence, and the
turn counts are the part nobody has divided:

| Stage | Sessions | Turns | Turns per session | Cost per session |
|---|---|---|---|---|
| develop | 12 | 463 | 38.6 | $4.03 |
| verify | 10 | 384 | 38.4 | $3.63 |
| queue | 5 | 181 | 36.2 | $4.24 |
| design | 1 | 27 | 27.0 | $2.32 |
| retro | 2 | 46 | 23.0 | $2.51 |

So the remaining lever is **turns per session**, and no open ticket targets it. `0026` measured the
history and closed. `0037` will measure a fresh project's cost and context *per turn*, which holds
the turn count in the denominator rather than examining it. `0041` reports what a run cost after
it happened. None of the three says what the 39 turns were spent on.

**Without that, every efficiency change is a guess, and this project has already paid for one.**
`0009` modelled a 66% saving from a 60k-context premise, shipped the change, and observed 14.5% —
because the premise was wrong in a way no one could see until it was measured. Repeating that with
"trim the skills" or "cut the narration" is the same move with a different premise.

Aaron's request, verbatim, 2026-08-30:

> We have a lot of open tickets, but I want to focus on context management first. Right now, each
> session where I run any skill, whether that be Q or Develop or Verify or Retro, is taking a lot of
> turns and therefore a lot of context. While I don't want to neuter the power of these tools, I do
> want to find a way to help them run in a more streamlined way. The eventual goal is to create an
> agent that orchestrates those other isolated context windows.

**Why this is blocked by `0051` rather than merely related to it.** `0051` is the ticket that pins
`MEASUREMENT.md`'s denominators and makes *Re-running this* reproduce the published tables. This
ticket publishes a new set of figures from the same live store with the same script. Run first, it
adds a second unreproducible figure over a live denominator — the exact defect `0051` exists to
remove — and `0051` then has two records to fix instead of one.

## Functional requirements

- FR1 — Report **turns per session, per stage**, for the recorded sessions. This is the denominator
  every other figure in this ticket divides by and `MEASUREMENT.md` does not currently carry it.
- FR2 — Classify **every turn** into a set of categories fixed and named in the record, by committed
  code reading the transcripts rather than by a session reading them. The classifier is the turn's
  tool calls, which are on disk and unambiguous. At minimum the set separates **mechanism** (claim,
  close, lock, commit, and reads of `QUEUE.md`, `next`, `config.yml`), **orientation** (reading the
  skill file, the conventions, a template, the ticket), **work** (edits and test runs on the change
  itself) and **narration** (a turn that called no tool).
- FR3 — Report, per stage, an estimate of **how much of a session's context growth is its own prior
  turns** versus files it read, and **state the estimator** — the transcripts carry usage totals,
  not a breakdown, so this is a computed estimate and must be published as one. This is the figure
  that says whether the thing to cut is what a session says or what it reads.
- FR4 — Declare a **turn budget per stage — a number and a date** (`measurement-conventions.md`),
  and state the current figure against it.
- FR5 — Name **which category from FR2 is the largest** and therefore where a reduction should aim,
  and **open the reduction ticket** rather than making the reduction here.
- FR6 — Pin the session set the way `0051` requires — an explicit id set or a timestamp cut, not a
  date window — so the published figure reproduces from the printed command.
- FR7 — Publish beside `MEASUREMENT.md`'s existing tables rather than replacing them, and extend
  `tests/measurement.test.sh` rather than adding a second measurement test.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The transcripts read are this repo's own sessions, and this repo is public. Published figures are aggregate usage; no transcript content is quoted beyond this project's own material, and no path outside this repo is named. | `data-privacy-conventions.md` |
| Documentation | Every figure carries its as-at pin and the command that reproduces it, and the verdict is recorded whether or not it is the hoped-for one. | `measurement-conventions.md` |
| Dependencies | Uses the committed `tools/harvest-usage.sh` and the project's existing `python3`. A measurement is not an occasion to add a tokenizer or a dependency. | `dependency-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `MEASUREMENT.md`, when read, then it reports turns per session broken down by
      stage, for a pinned set of sessions.
- [x] AC2 — Given `MEASUREMENT.md`, when read, then it names the turn categories it classified into,
      reports each category's share per stage, and names the committed code that produced the
      classification.
- [x] AC3 — Given that committed code, when run against the pinned session set, then it reproduces
      the category shares published in AC2.
- [x] AC4 — Given `MEASUREMENT.md`, when read, then it reports the estimated share of context growth
      attributable to a session's own prior turns, per stage, and states the estimator used and that
      the figure is an estimate.
- [x] AC5 — Given `MEASUREMENT.md`, when read, then it states a turn budget per stage as a number
      with a date, and the current figure against each.
- [x] AC6 — Given `MEASUREMENT.md`, when read, then it names the largest category and the backlog id
      of the reduction ticket opened against it.
- [x] AC7 — Given the *Re-running this* recipe as printed, when executed, then it reproduces the
      tables this ticket published, without a hand-derived exclusion list assembled at read time.

## QA plan

- **Level:** verify — the deliverable is figures, a record, and a classifier script. No runner
  applies to the record; the classifier is checked by AC3 re-running it.
- **Why this level:** matches `0026` and `0037`, the two tickets this one sits between.
- **Specific checks:** extend `tests/measurement.test.sh`. Assert, each on its own line so a reflow
  cannot red it: a `turns per session` heading or column; each FR2 category name; the word
  `estimate` in the same section as the FR3 figure; a `20[0-9][0-9]-` date on the turn budget; and a
  four-digit ticket id in the FR6 sentence.

## Out of scope

- **Making the reduction.** FR5 opens that ticket; this one produces the number it aims at. Deciding
  what a stage still tells the human is `0074`, which is deliberately not blocked on this.
- **The fresh-project run.** That is `0037`, a different denominator and a different data source.
- **Per-run reporting.** That is `0041`, which reads a supervised run's log rather than history.
- **Changing any skill file.** A measurement run is not an occasion to edit the thing measured.

## Notes & decisions

- **Routed to `develop`, not `design`.** There is no decision blocking acceptance criteria and no
  surface a person looks at: the categories are discoverable by reading the transcripts, exactly as
  `0026` was. Unfamiliar is not undecided.

## Verify verdict — PASS, 2026-09-02 (token 344f)

Runtime observation, not a test run: the classifier was driven at its CLI and the *Re-running this*
recipe executed exactly as printed. **All four published tables reproduced cell for cell** — 30
sessions, 1,112 turns, 41.9%/15.7%/34.0%/3.8%/4.6%, mixed 7.6%, mechanism composition over 466
turns, floor 58,060 / end 130,807 / climb 72,747, own share 45.4%. AC1–AC7 hold.

**Three defects found by running it, all fixed under this token in `045465d`** — every one invisible
to a reader of the diff, which is the argument for the stage:

1. **A run that matched no session printed a table of zeros and exited 0.** An empty store, a
   mistyped window and `--exclude ''` all landed there, and `--exclude ''` excluded every session
   because a prefix match accepts the empty string. On a pinned command carrying twelve `--exclude`
   flags, one shell-quoting slip reproduced as a clean zero table. Now exits non-zero on both.
2. **AC5's budget could never come due.** *The turn budget* said to re-read it on 2026-10-31
   "against the sessions run by then" and pointed at a command pinned to `--until 2026-08-24`, which
   returns the August figures by construction. The budget now prints its own unpinned command.
3. **Three of the four tables dropped the `unmarked` row while their totals counted it** — 28
   sessions against 30, 2,169,772 growth tokens against 2,182,427, 465 mechanism turns against 466.
   No headline figure was wrong, which is why nothing caught it.

**What the guard learned.** The AC-shaped assertions were greps for a word and stayed green through
all three defects. The replacement sums each published table's rows against its own total row and
drives the CLI for its exit code — the arithmetic-against-known-numbers shape this file's own header
already argued for. Confirmed red against all three before the fix.

**Noted, not fixed here** — `0074`'s territory or a queue item, not this ticket's:

- The re-measure window recorded 57 sessions at **39.8 turns per session** against the 37.1 the
  budget was set from. The figure the reduction aims at is drifting up, not holding still.
- `tools/harvest-usage.sh` shares this classifier's `--exclude` prefix matching and was not examined
  for the same empty-value defect; it is the reproducer for the cost tables above this section.
- The `## What a turn of each category costs` tables that `0085` added to this record were not
  covered by the new row-sum guard, which is scoped to this ticket's section.
