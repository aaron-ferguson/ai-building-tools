---
id: "0130"
title: Propose a sprint scope and dispatch nothing until a person confirms it
type: feature
next: develop
status: ready
qa_level: verify
close_by: verify
size: l
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0038", "0135"]
expects:
  - skills/orchestrate/SKILL.md
  - tests/orchestrate.test.sh
  - .claude/backlog/next
  - skills/queue/templates/next
claimed_by:
claimed_at:
touches:
---

## Problem

**The skill dispatches on `--drive`'s first decision line, and a person sees the shape of the run
only afterwards.** Step 1 prints a depth line — *"Nine develop gates takeable; runs dry at 0080"* —
and Step 2 dispatches. Nothing between them asks whether that is the work anyone wanted.

**The gate is the wrong unit to show a person, and this is measurable rather than theoretical.** Run
on 2026-09-09, `./next --drive` returned:

```
DEPTH     10 develop gate(s) takeable; runs dry at 0080 (next: design — a person decides)
DISPATCH  develop 0111 0114 0075 0089 0126 0091 0127 0064 0112 0100 0101 0113 0118
```

Thirteen tickets. Their `expects:` lists show what actually binds them:

| joins the gate via | tickets |
|---|---|
| `skills/retro/SKILL.md` | 0114, 0075, 0126, 0091, 0127, 0064, 0112, 0100, 0113, 0118 |
| `references/CONVENTIONS.md` | 0101 |
| `tests/retro-tool-edit.test.sh`, one of the 21 files it names | 0089 |

Every one joins through the **lead's** `expects:`, and the lead is 0111. So the gate is held together
by a hub file, which is the sweep `gate_from`'s own comment warns about. 0064 is a README and
CLAUDE.md sweep, 0089 is a guard audit, 0114 is retro's release chain: three unrelated efforts, one
gate. The grouping is right — those tickets genuinely cannot run concurrently — but presenting it as
a coherent slice is how a person approves thirteen tickets meaning to approve four.

**A count alone would not have shown it.** "13 tickets" reads as a large sprint; "13 tickets, ten of
which are here because they all edit `skills/retro/SKILL.md`" reads as a grouping artefact, and only
the second is actionable.

**Taking part of a gate has a real and payable cost that nobody is currently told.** Selecting four
of the thirteen leaves the other nine un-takeable while the four are in progress — their `expects:`
overlaps the in-progress `touches:`. They were un-takeable anyway; the cost is re-paying one session
startup floor later, about **$4.03** at the develop mean. That is a fine price for not doing nine
tickets nobody chose, and it is a decision a person can only make if they are shown it.

## Functional requirements

- FR1 — `sprint` dispatches no stage session until a person has confirmed a proposal. The probe, the
  supervisor marker and the depth read all still happen first; what is gated is the first *stage*.
- FR2 — The proposal states **how many tickets** the sprint expects to work.
- FR3 — The proposal names **which tickets**, by id and title.
- FR4 — The proposal says **what the work is** for each, in one line drawn from the ticket rather
  than invented.
- FR5 — The proposal says **why these tickets** — and where a gate is held together by a shared
  file, it names that file and how many rows join through it, so a grouping artefact is visible as
  one rather than presented as a theme.
- FR6 — The proposal carries an **estimate in real-world time, tokens and dollars**, sourced per
  `0135`. Where no prior exists for a figure it is labelled an estimate with no prior rather than
  presented as derived — `MEASUREMENT.md` records no wall-clock data at all, so the time figure has
  no basis until `0135` accumulates one.
- FR7 — Where the proposal takes **part** of a gate, it names the rows left behind and states the
  cost of resuming them later as one additional session floor.
- FR8 — The confirmed scope is written to the run log before the first dispatch, so a resuming
  supervisor reads what was agreed rather than re-deriving a scope the person never saw.
- FR9 — A person may confirm, amend the scope, or decline. Declining ends the run without a stage
  session and releases the supervisor marker.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The proposal is built from the `--drive` call and the item frontmatter the skill reads anyway; it adds no per-cycle turn, and the supervisor's turn budget in the skill's own bound section still holds | `observability-conventions.md` |
| Documentation | The confirmed scope is recorded in the run log, which is provenance and not state — the backlog stays the authority for what to do next | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a backlog with takeable work, when `sprint` runs, then no `claude -p` stage
      process is started before a confirmation is received. **Red if** the skill dispatches on
      `--drive`'s exit 0 as it does today.
- [ ] AC2 — Given the 2026-09-09 backlog state, when the proposal is produced, then it names
      `skills/retro/SKILL.md` and the count of rows joining through it. **Red if** the proposal
      lists thirteen ids with no grouping reason, which is the current depth line plus a count.
- [ ] AC3 — Given a proposal, when it is printed, then it carries all five of count, ids, per-ticket
      work, reason, and a three-part estimate. **Red if** any one is absent — checked as five
      separate assertions, not one, so a proposal missing only the estimate still fails.
- [ ] AC4 — Given a proposal taking part of a gate, when it is printed, then it names the rows left
      behind. **Red if** a partial gate is proposed with no mention of the remainder, which reads as
      though nothing was displaced.
- [ ] AC5 — Given a person declining, when the run ends, then no stage ran and
      `.claude/backlog/runs/.active` is removed. **Red if** the marker is left behind, which makes
      the next sprint report the backlog as held by another supervisor.
- [ ] AC6 — Given a confirmed proposal, when the first stage is dispatched, then the run log already
      contains the confirmed scope. **Red if** the scope is written after the dispatch, which is the
      ordering that loses it when the first stage is what kills the supervisor.

## QA plan

- **Why that level:** no runner applies to a skill's prose contract, but each criterion is a
  mechanical check — a `grep` over the skill for the required proposal elements, and a scripted
  reading of a run log fixture for AC5 and AC6.
- **Specific checks:** `tests/sprint.test.sh` asserts FR2–FR7 are each stated in the skill; a run-log
  fixture exercises AC5 and AC6; the AC2 assertion runs the real `./next --drive` against a fixture
  backlog rather than the live one, so the guard does not change meaning as the queue drains.

## Out of scope

- Changing `gate_from`'s grouping. The gate is correct as a conflict unit; this ticket makes its
  composition legible. Whether two gates can overlap each other is `0136`.
- The estimate's accuracy or its learning loop — that is `0135`. This ticket consumes whatever
  `0135` provides and labels what has no prior.
- Any interactive UI. The proposal is printed and confirmed in the conversation.

## Notes & decisions

- **2026-09-09 — the proposal is what makes a hub-file gate survivable.** The alternative considered
  and rejected was tightening `gate_from` to exclude hub files. Rejected because the gate's job is
  conflict avoidance and it is doing that correctly: those thirteen rows genuinely collide. The
  defect is presenting a conflict group as a plan, which is a reporting problem, not a grouping one.
