---
id: "0231"
title: Drive one outcome ticket across slice sessions unattended
type: feature
next: design
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0071", "0149", "0220", "0226", "0212", "0137", "0128"]
expects: [skills/sprint/SKILL.md, skills/sprint/outcome.schema.json, skills/develop/SKILL.md, skills/verify/SKILL.md, skills/queue/SKILL.md, skills/queue/templates/item.md, skills/queue/templates/next, skills/queue/templates/handoff, skills/queue/templates/claim, skills/queue/templates/close, skills/queue/templates/config.yml, references/CONCURRENCY.md, tests/next.test.sh, tests/handoff.test.sh, tests/batching.test.sh, CHANGELOG.md]
ac_digest: AC1=16d514b5 AC2=2b8c9086 AC3=6dd5577b AC4=5519976d AC5=9d8b6a77 AC6=54f704e7
claimed_by: "e4ad"
claimed_at: 2026-11-18T05:55:57Z
touches:
---

## Problem

**The convention changed under the suite.** `ai-building-conventions` `a325686` (2026-11-17) replaced
*"if it can't be finished in a few days, it isn't a slice yet"* with: **size a unit of work by its
outcome and the context its parts share, not by calendar time — one outcome is one ticket even across
many sessions, its slices worked in order with a handoff; split only where a part has an outcome of
its own** (`product-definition-conventions.md` → "Slice Vertically and Thinly", and the core). Aaron,
2026-11-17: *"AI is much better at handling large projects and understanding context than it used to
be… merge them into as few tickets as would still be effective and efficient at achieving the long
term outcome, rather than splitting into little parts."* The first consumer to apply it, Traitors and
Allies, went from 47 rows to 5; its 0060 has eight requirement groups (S1–S8) and will take many
sessions.

**The goal of `/sprint`** (Aaron, 2026-11-17): *"spin up an agent that will orchestrate whole project
or long sessions so that my work progresses without me needing to be present at my computer the
entire time."* Big tickets make that more valuable — someone otherwise restarts every session — but
the suite assumes a ticket fits in one stage session, in five places:

1. **No partial-progress outcome.** `skills/sprint/outcome.schema.json`'s verdicts are `queued,
   re-specified, parked, decided, handed-to-queue, prototyped, built, red, blocked, closed, pass,
   fail, advisory`. Nothing means "slice 3 of 8 done, tree green, continue". `handoff`'s usage is
   `<id> <token> <stage>` between stages; develop cannot hand to develop.
2. **So a multi-session ticket can only end by cap kill**, which sprint Step 7 rightly treats as the
   worst case — claim held, tree dirty, lock possibly taken — escalating and starting nothing further.
3. **`stage_budget_usd` is one cap per stage session, derived from per-session cost history on small
   tickets** (sprint Step 7), so it cannot be met by a ticket sized to an outcome.
4. **The dispatch unit is a gate of rows** sharing `expects:` scope (Step 2, `gate_max_rows`). With a
   handful of outcome tickets there is nothing to batch; the saving moves to giving each *slice* a
   fresh session, which bounds context growth instead of amortising startup.
5. **Verify runs once per ticket**, so an eight-slice ticket meets its independent check only after
   all eight — the longest possible distance between a defect and its detection.

And two gaps in capture, both seen in the 2026-11-17 Traitors and Allies session:

6. **`queue` mints first.** Step 2 always claims a new id; nothing asks *which existing outcome does
   this serve?* — the question the new convention makes the default. There is no merge operation;
   the consolidation invented one (withdraw each merged ticket with a pointer, quote reported
   evidence verbatim in the absorbing ticket, burn ids).
7. **`queue` must never amend a claimed ticket** (Step 1, *Amend*). With long-lived tickets the one a
   new finding belongs to will often be claimed, so amend-first collides with that rule.

And one in decisions: architecture and security choices are a person's (`coding-conventions.md` →
*What Not to Delegate to AI*), so an unattended run reaching a `design` row escalates and stops
(Step 8), even though most of a decision's cost — spikes, options, a recommendation — needs no person.

## Open design question

- **Question:** Settle these, each with a recorded choice:
  - **Q1 Where slice progress lives.** Recommended: a `## Progress` section of ordered slice
    checkboxes in `templates/item.md`, distinct from ACs, each slice naming the ACs it discharges;
    `close` still ticks only ACs.
  - **Q2 Verify cadence.** Recommended: verify each slice's ACs when the slice lands (an independent
    pass, `pass` / `fail` per slice), plus one final verify of the outcome ACs that closes the ticket.
    Alternative: final verify only.
  - **Q3 Amending a claimed ticket.** Recommended: claims are released at every slice boundary
    (develop → develop handoff), so `queue` amends between legs; a `## Pending amendments` section
    that develop folds in at its next start is the fallback for a ticket held across a long leg.
  - **Q4 Run scope — how many tickets one sprint run drives.** Recommended: the person confirms the
    scope at the proposal (Step 1), as today; the proposal **defaults to one outcome ticket** and
    adds others only when they are takeable and touch disjoint files (e.g. one develop outcome plus a
    design ticket's preparation beside it). Within the scope, the next slice is the ticket's order and
    when to end a leg is develop's call (slice boundary or budget). Continuing past the confirmed
    scope to the next ranked outcome happens only when the person said so at the proposal.
  - **Q5 Decisions unattended.** Recommended: a design session may *prepare* a person's decision —
    run spikes, write the options and a recommendation, reduce it to specific questions — and leave
    the row `waiting` with a `## Waiting on` section, notifying the person; the run continues on any
    scope work that does not depend on the answer. It never records the decision itself.
- **Why it blocks specification:** FR2–FR7's exact shapes (schema fields, item sections, script
  arguments, verify verdict semantics) follow from Q1–Q5.
- **Settle it with:** `/design`.

## Functional requirements

Recommended shape; `design` confirms or amends.

- FR1 — `templates/item.md` gains the slice structure Q1 chooses, and `queue` Step 2 tells authors to
  write one outcome ticket with ordered slices rather than one ticket per slice — citing the
  convention, not restating it.
- FR2 — `outcome.schema.json` gains a `progressed` verdict carrying the slice completed and the next
  slice, and `develop` returns it when it ends at a slice boundary with the tree green and committed.
- FR3 — `handoff` accepts a develop → develop transition that releases the claim at a slice boundary
  and records the slice ticked, refusing unless the tree is clean.
- FR4 — `develop` budgets its own leg: it stops at the last slice boundary it can finish within the
  leg cap rather than running into `--max-budget-usd`. `config.yml` gains a per-leg cap
  (`leg_budget_usd` or a redefinition of `stage_budget_usd`), derived and recorded as Step 7 requires.
- FR5 — `next --drive` routes `progressed` to the next develop leg of the same ticket (or to the slice
  verify Q2 chooses) and treats a ticket mid-slices as in-scope work the run must finish before
  opening another.
- FR6 — `sprint`'s proposal implements Q4's scope rule, and Step 8's escalation on a `design` row is
  replaced by Q5's prepare-and-wait behaviour, with a notification to the person.
- FR7 — `queue` gains **amend-first**: before minting an id it searches open tickets' outcomes and,
  where one is served, amends it (re-checking size, ACs, QA plan and out-of-scope, restamping
  `ac_digest`). It mints a new ticket only for work with an outcome of its own, and records which
  test was applied in *Notes & decisions*.
- FR8 — `queue` gains a **Merge** operation in its Step 1 table: absorbing tickets into one outcome
  ticket withdraws each with a pointer to the requirement that now carries it, quotes user-reported
  evidence verbatim in the absorbing ticket, and burns ids — the procedure Traitors and Allies used.
- FR9 — Q3's rule for amending a claimed ticket replaces Step 1's flat prohibition, and
  `CONCURRENCY.md` says how it stays safe.
- FR10 — The gate machinery (`gate_max_rows`, expects-scope batching) is kept for backlogs of small
  rows but no longer assumed; 0220 and 0212 are re-checked against the new dispatch unit and
  withdrawn or amended.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | Unattended runs still never push, bump, install or restart without per-action approval (sprint Step 8 unchanged), and never record a person's decision | a `tests/` case asserting sprint's Step 8 list and Q5's "never records the decision" clause survive in `skills/sprint/SKILL.md` — prose only if no script owns them | `security-conventions.md` |
| Documentation | `CHANGELOG.md` `## Unreleased` entry; README skill descriptions updated where sprint, develop and queue change behaviour | `tests/changelog-entry-guards.test.sh` | `documentation-conventions.md` |

## Acceptance criteria

Draft — `design` confirms these against Q1–Q5 and restamps `ac_digest`.

- [ ] AC1 — Given a fixture backlog with one ticket of three slices, when `develop` finishes slice 1 and
  runs the FR3 handoff, then the item shows slice 1 ticked, `claimed_by:` empty, `next: develop`,
  `status: ready`, and `next --drive --completed develop:<id>` names a develop leg on the same ticket
  (`tests/handoff.test.sh`, `tests/next.test.sh`). Reds if the handoff refuses develop → develop.
- [ ] AC2 — Given the same handoff on a dirty tree, then it refuses naming the dirty paths and changes
  nothing.
- [ ] AC3 — Given `outcome.schema.json`, then a `progressed` outcome naming the completed and next
  slice validates, and one missing the next slice does not.
- [ ] AC4 — Given a fixture with slices one and two done and a `progressed` outcome, then
  `next --drive` does not offer a different ticket's develop row while slices remain (FR5).
- [ ] AC5 — Given a capture whose outcome matches an open ticket in a fixture backlog, then `queue`'s
  instructions direct an amendment, and the merge procedure of FR8 is in its Step 1 table — checked by
  the test that owns `queue`'s operation table, or prose only if none exists.
- [ ] AC6 — Given a `design` row in a sprint's confirmed scope that needs a person, then the design
  outcome is `waiting` with a `## Waiting on` section and the run's next `--drive` dispatches other
  scope work rather than exiting `4` (`tests/next.test.sh`).

## QA plan

- **Why that level:** the suite's tests are shell scripts under `tests/`; every mechanical change here
  lands in a template script, the schema or a skill file they already exercise.
- **Specific checks:** the full `tests/*.test.sh` run; a dry `/sprint` against a scratch backlog with
  one three-slice ticket to confirm the leg loop end to end.

## Out of scope

- Running two develop sessions at once — 0137.
- The release of these changes — `tools/release`, on Aaron's say-so.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-11-18 — captured at Aaron's direction from the Traitors and Allies session of 2026-11-17, which
  consolidated that backlog to five outcome tickets and asked whether `/sprint` still fits. Routed to
  `design`: Q1–Q5 are open and change the FRs' shapes. Ranked row 1: it is Aaron's stated goal for the
  suite (unattended progress), every project now writes tickets in the shape this fixes, and until it
  lands a sprint over a consolidated backlog can only end each leg by cap kill.
- 2026-11-18 — **amend-first applied to this capture** (FR7 eating its own cooking): 0071 (decision map
  for oversized work), 0149 (sprint efficiency), 0220 (one verify session per develop gate), 0226 and
  0212 (`--drive` routing) all touch this outcome. They are left as rows for now and named in
  `relates:`; the `design` pass decides which are absorbed here — likely 0220 and 0212 (their gate
  premise changes), possibly 0071 — and withdraws them with pointers per FR8.
- 2026-11-18 — absorbs the FINDINGS entry of 2026-11-17 *"queue's guidance pushes toward many small
  tickets…"* (FR7, FR8).
