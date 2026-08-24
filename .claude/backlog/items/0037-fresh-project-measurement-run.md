---
id: "0037"
title: Run the fresh-project end-to-end exercise against the settled configuration
type: chore
next: develop
status: blocked
qa_level: verify
size: l
created: 2026-08-24
source: user
parent: "0009"
blocked_by: ["0028", "0035"]
relates: ["0026", "0036"]
expects:
  - README.md
  - .claude/backlog/items/0009-one-skill-per-session.md
  - tests/measurement.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`0026` opened as effort 0009's closing commitment: *"re-run the same end-to-end exercise against a
fresh project and compare cost per turn and context per turn."* On 2026-08-24 it was amended to
measure the sessions that **already ran**, because both sides of that comparison were already on
disk and because a fresh run measured that day would have measured a configuration this repo is
part-way through replacing. This ticket is the half that was taken out of it.

**What `0026` cannot answer.** Its figures come from this repo's own history, so they carry two
limits that no amount of analysis removes:

1. **It is not a fresh project.** Every session it measures had this repo's `CLAUDE.md`, this
   backlog and 30-odd tickets of accumulated context available. The 2026-08-22 baseline was a
   greenfield run. Some of the per-turn context it measures is this project, not the suite.
2. **It measures the suite as it stood on 2026-08-23/24.** `0028` — retiring the reference files'
   hard token ceiling for a soft goal and a gate — closed on 2026-08-24, after the sessions `0026`
   measures. `0035` — whether conditionally-needed skill detail moves behind pointers — is still
   open, and `prototype` and `develop` are both over the size goal today. Both tickets change how
   much context a session loads on every run of every project, which is the number the whole effort
   is justified by, and neither change is inside `0026`'s figures.

So the observed figure `0026` produces is real and is the right thing to publish today, and it is
still not a measurement of what this suite costs a new project once the size work lands. That is
what this ticket is for, and it is why it is deliberately sequenced behind those two tickets rather
than run as soon as someone has an afternoon.

## Functional requirements

- FR1 — Take a **fresh project** — synthetic or non-sensitive, wired to the conventions — from
  nothing through `queue → develop → verify` to at least one closed ticket, with **each skill in its
  own session**.
- FR2 — Measure it with **`0026`'s committed harvest script**, unmodified where possible, so the
  figures are comparable by construction rather than by argument. Any change the script needs is a
  change to the script in the repo, not a local variant.
- FR3 — Report **cost per turn, context tokens per turn, and cost per closed ticket, per skill**, and
  compare all three against both `0026`'s isolated-run figures and the 2026-08-22 baseline. Three-way,
  because the interesting question is how much of `0026`'s number was the suite and how much was this
  repo.
- FR4 — State the **effect of `0028` and `0035`** on context per turn: the reference and skill files'
  sizes before and after, and whether the per-turn context moved in the direction those tickets
  predicted. This is the outcome review those two tickets do not carry themselves.
- FR5 — **Record the verdict even when it is "it didn't work",** against the modelled ~$5.09 and
  against whatever `0026` observed.
- FR6 — Report **effectiveness alongside cost**, per 0009's commitment that it must not be traded:
  what the fresh run caught, and what it missed that either earlier run caught.
- FR7 — Update `README.md` and `0009` with the fresh-project figure, replacing `0026`'s repo-history
  figure as the headline and keeping it as the intermediate data point rather than deleting it.
- FR8 — Note what this run did **not** hold constant against either comparison — skill versions,
  conventions, model, project domain, and whether the run was hand-driven or supervised.
- FR9 — If `0036` has landed by the time this runs, drive the sessions with the supervisor and say so;
  the driving mechanism is one of the things FR8 must not leave unstated.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The fresh project is synthetic or non-sensitive. A measurement run must not put real customer or case data through a model to produce a cost figure. Published figures are aggregate usage only, as in `0026`. | `data-privacy-conventions.md` |
| Documentation | Every figure carries its date and what was not held constant, and the verdict is recorded whether or not it is the hoped-for one. | `documentation-conventions.md` |
| Dependencies | Uses `0026`'s script and the project's existing `python3`; a measurement run is not an occasion to add tooling. | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the recorded result, when read, then it reports cost per turn, context tokens per
      turn and cost per closed ticket, broken down by skill, for a fresh project taken end to end to
      at least one closed ticket with each skill in its own session.
- [ ] AC2 — Given the recorded result, when read, then it compares all three figures against both
      `0026`'s observed figures and the 2026-08-22 baseline.
- [ ] AC3 — Given the recorded result, when read, then it states the before-and-after sizes of the
      reference and skill files changed by `0028` and `0035`, and whether per-turn context moved as
      those tickets predicted.
- [ ] AC4 — Given the recorded result, when read, then it states the verdict explicitly against
      ~$5.09 and against `0026`'s figure, and says what the run caught and what it missed.
- [ ] AC5 — Given `README.md` and `0009`, when read, then the fresh-project figure is the headline and
      `0026`'s figure is retained and labelled as the repo-history measurement.
- [ ] AC6 — Given the recorded result, when read, then it names at least two things this run did not
      hold constant, and states whether the sessions were hand-driven or supervised.
- [ ] AC7 — Given the harvest, when performed, then it used the committed script from `0026` and any
      change to it is committed to the repo.

## QA plan

- **Level:** verify — a measurement and a written record; no runner applies.
- **Why this level:** the deliverable is figures and prose. The script's correctness is `0026`'s
  problem and is already tested there.
- **Specific checks:** extend `tests/measurement.test.sh` rather than adding a second measurement
  test. Assert, each on its own line so a reflow cannot red it: a three-way comparison naming both
  prior figures; a `20[0-9][0-9]-` date; the string `5.09`; an explicit verdict word; the words
  `hand-driven` or `supervised`; and that `README.md`'s headline figure is no longer `0026`'s.

## Out of scope

- Changing the suite in response to the result. A saving that did not materialise is a finding and a
  new ticket.
- Re-running the 2026-08-22 baseline. It stays the published control, with its limits recorded.
- Deciding **how** the sessions are driven. That is `0036`. This ticket uses whatever exists when it
  runs and records which it was.

## Notes & decisions

- **Created 2026-08-24 by splitting `0026`.** Aaron's decision, after the observation that `0026` sat
  `waiting` at row 1 asking a person to sit three sessions while `0028` and `0035` were still open —
  so the run it was asking for would have measured a configuration about to change. The full
  reasoning is in `RANKING.md` and in `0026`'s *Notes & decisions*.
- **`blocked_by: ["0028", "0035"]` is the point of the ticket, not caution.** Both change context per
  turn, which is the metric. Running before they land produces a number that is stale on the day it
  is published — the specific failure this split exists to avoid.
- **`0028` closed on 2026-08-24, while this ticket was being written**, by another session. It stays
  in `blocked_by` as the record of the sequencing decision; `blocked_by` is only read for entries
  that are *not* `done`, so the derived status is unaffected and **`0035` is the sole open blocker.**
- **`relates: 0036`, deliberately not `blocked_by`.** 0036 would let a supervisor drive these sessions
  instead of a person sitting three windows, which is the constraint that made `0026`'s original FR1
  unexecutable. But 0036 is `size: l` with an open design question, and the precedent in `RANKING.md`
  — from 0025 and then 0026 itself — is that blocking work on an unscheduled large ticket is how it
  waits forever. FR9 handles both cases instead.
- **When the blockers clear, expect this to become `waiting`, not `ready`,** unless 0036 has landed.
  FR1 needs three sessions sat in sequence and no stage can execute that. That is a known future
  state rather than a defect, recorded here so the next reader does not treat it as drift.
- **Ranked last, and this is deliberate.** Nothing in the queue depends on it, so tie-breaker 2
  favours every graph ticket above it, and the knowledge-freshness argument that put `0026` at row 1
  is spent — `0026` now delivers the observed figure that the decaying baseline was needed for. This
  ticket's value comes from being run *late*, which is the opposite of urgency.
