---
id: "0243"
title: Give each slice of an epic its own file, so claims, locks and revisits work per slice
type: feature
next: design
status: in-progress
qa_level: unit
close_by: verify
size: l
created: 2026-11-27
source: user
parent:
blocked_by: []
relates: ["0242", "0231", "0234", "0244"]
expects:
  - skills/queue/templates/item.md
  - skills/queue/templates/slice.md  # new — the slice-file template, if design keeps one
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - skills/queue/templates/handoff
  - skills/queue/templates/close
  - skills/queue/templates/reopen
  - skills/queue/templates/capture
  - .tickets/next
  - .tickets/claim
  - .tickets/handoff
  - .tickets/close
  - .tickets/reopen
  - .tickets/capture
  - tests/next.test.sh
  - tests/claim.test.sh
  - tests/handoff.test.sh
  - tests/close.test.sh
  - tests/reopen.test.sh
  - tests/capture.test.sh
  - tests/backlog-scripts-installed.test.sh
  - references/CONCURRENCY.md
  - skills/queue/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/sprint/SKILL.md
  - CHANGELOG.md
claimed_by: "6a4b"
claimed_at: 2026-11-28T00:01:49Z
touches:
slice:
ac_digest: AC1=9ef9cc2a AC2=ac7c8953 AC3=365cc19e AC4=fd0dd04c AC5=5930153d AC6=11fcfb0d
---

## Outcome

In the person's words (answer 2, sprint run-20261127T024025Z, `.tickets/runs/s13-answer.md`):

> "I like having all of the context in one place, but also there's no reason we couldn't update the
> system to have a separate file per slice and then have our sessions pull in each slice file that it
> needs to be effective for its job that would also make it easier here to mark something as needing
> to be revisited because that slice would need to be revisited."

And the recommendation they approved ("Yes, go ahead with all three"):

> "Split each slice into its own file, with the epic file kept as the index (outcome, problem, NFRs,
> the slice list linking each slice file) and each slice file holding its FRs, ACs, digest, claim, QA
> evidence and notes, so claims and locks work per slice and "needs revisiting" is a slice status.
> Sessions load the epic plus the slice files their job needs."

Done means: two sessions can each hold a different slice of one epic at once, a slice can be marked
as needing revisiting without touching its siblings, and a session reads the epic index plus only the
slice files its job needs.

## Problem

The person, answer 2, verbatim:

> "We have essentially changed our build tools from focusing on traditional user stories to Epics and
> are focusing on the larger view and outcome, but because we have built it as Epics are the ticket and
> every story underneath it is part of the same file, our lock system is tricky. If something we find
> actually affects another ticket then we update that ticket and everything works smoothly, but if we
> are updating the same ticket for a different slice, that is where the complication happens."

Observed in this run on 0242, recorded in `.tickets/FINDINGS.md` and absorbed here (each entry marked
`[->0243]`):

- **2026-11-27, supervisor, at the user's request (`c9183cc`)** — "Merging an outcome into one sliced
  ticket serialises its design work behind its develop legs. 0242 absorbed 0217, 0219 and 0235 as its
  unspecified slices S5–S7. While S1's develop holds 0242's claim, a design session on those slices is
  blocked. `./claim` allows one holder per row, and `--drive` dispatches design per row, never per
  slice. When they were separate rows, design could run beside develop under the *Design beside other
  stages* rule. Per the user, designing an unspecified slice does not affect the work a running develop
  leg does on another slice, so it should be able to run in parallel."
- **2026-11-27, verify `e297`** — "A passed leg whose next slice is `unspecified` cannot go straight to
  `design`. … `./handoff` refuses `--slice` on verify → design … So verify must hand back
  `develop --slice S<n>`, and a whole develop session then exists only to forward the ticket to design.
  0242 S4 → S5 hit this."
- **2026-11-27, design `b7a4`** — "`design` Step 3's unattended rule has no correct answer when one
  ticket carries both a fact-decidable slice and an architecture slice. … The rule's only release is
  `./handoff <id> <token> design waiting`, which parks the specified S5 and S6 behind S7's answer, though
  develop could have built them meanwhile."

Cost of the shape, measured on 0242: one item file of 3,041 lines, which every stage session on any
slice reads whole, and one claim for fifteen slices.

0242 S13 (FR68, FR69) has design record a consequence for another slice of the item it holds by writing
that slice itself, and a consequence for another item in the held item's `### Sibling consequences`.
Those rules are stated against one file per ticket and must move with this change.

**Source.** Toolkit work the user asked for in sprint run-20261127T024025Z, so `CLAUDE.md`'s
held-finding rule (*Where toolkit work comes from*) does not apply: this is not a finding from this
repo's own sessions waiting for a consuming project to confirm it.

## Open design question

- **Question:** what is the shape? Specifically: (1) where slice files live and how they are named
  (`items/0243/S1.md`, `items/0243-S1-*.md`, …), and how the epic index links them; (2) what a claim and
  the lock hold — the slice file only, or the slice plus a read lease on the index — and what of the
  index (outcome, NFRs, slice list) a slice session may write; (3) the slice-status vocabulary, including
  "needs revisiting" and `waiting`, and whether a slice carries its own `next:`; (4) what `QUEUE.md`
  shows — one row per epic, or a row per takeable slice — and how `./next` and `--drive` choose a
  slice; (5) migration of sliced items already on disk here and in consuming projects; (6) whether an
  unsliced ticket is unchanged (expected: yes).
- **Why it blocks specification:** every criterion below names a file, a claim or a status, and their
  form depends on (1)–(4). Guessing them is building to a contract nobody agreed to. It is also
  concurrency architecture (`coding-conventions.md`, *What Not to Delegate to AI*), so an unattended
  design pass briefs the person rather than deciding.
- **Settle it with:** `/design`, reading `references/CONCURRENCY.md`, `skills/queue/templates/item.md`
  (`## Progress`, `slice:`), `handoff`'s `--slice` path, `next --drive`'s `dispatch_leg` and
  `leg_state`, and 0242 as the worked example.

## Functional requirements

Fixed whatever the shape; design adds the rest and may sharpen these, never narrow them.

- FR1 — An epic is one file that holds the outcome, the problem, the NFRs and the ordered slice list;
  each slice line links that slice's file. Each slice file holds that slice's FRs, ACs, `ac_digest:`,
  claim, `## QA evidence` and notes.
- FR2 — A claim and the backlog lock are taken per slice: two sessions can hold two different slices of
  one epic at once, and no session writes a slice file it does not hold (`references/CONCURRENCY.md`,
  *A stage writes only the ticket it holds*, restated per slice there, not here).
- FR3 — "Needs revisiting" is a slice status, set on one slice without changing any other slice's
  state, and `./next` / `--drive` route it (to `queue` or `design`, as design decides).
- FR4 — A design session can take an unspecified slice while a develop session holds another slice of
  the same epic, and `--drive` can dispatch it beside that develop leg (the `c9183cc` finding).
- FR5 — A passed leg whose next slice is unspecified reaches `design` in one hand-off, with no develop
  session that exists only to forward it (verify `e297`'s finding).
- FR6 — A slice waiting on a person does not park its specified siblings: they stay takeable
  (design `b7a4`'s finding).
- FR7 — A session loads the epic index plus only the slice files its job names; each stage skill says
  which (`queue`, `design`, `develop`, `verify`, `sprint`).
- FR8 — 0242 S13's rules move to slice files: FR68's own-slice case and `### Sibling consequences`, and
  FR69's fold-in, name the slice file they write. `references/CONCURRENCY.md` and `skills/design/SKILL.md`
  / `skills/queue/SKILL.md` are amended to match.
- FR9 — Every script that reads or writes a sliced item (`next`, `claim`, `handoff`, `close`, `reopen`,
  `capture`) implements FR1–FR6, from `skills/queue/templates/`, byte-synced to `.tickets/` (0242 FR4).
- FR10 — Sliced items already on disk are migrated, or keep reading correctly until they are, per the
  Migration row; an unsliced ticket reads and behaves exactly as before.
- FR11 — `CHANGELOG.md` `## Unreleased` names the new layout and what a consuming project does on
  upgrade.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Migration | The file layout changes under live backlogs here and in consuming projects. The old single-file sliced shape keeps reading (or is migrated by a script, in one commit, with every AC's digest unchanged) — never a flag day where an un-migrated item stops resolving | AC4's fixture: a pre-split sliced item that `./next`, `claim` or `--drift` misreads, or whose migrated ACs re-digest | `migration-conventions.md` |

## Acceptance criteria

Outcome-level and fixed regardless of the shape; design sharpens their fixtures and adds the rest.

- [ ] AC1 — Given a fixture epic whose S1 is held by develop token A and whose S2 is unspecified, when a
  design session claims S2, then the claim succeeds, and S1's slice file and claim are byte-unchanged.
  Red: today's one-holder-per-item refusal (`claim`'s held-row check).
- [ ] AC2 — Given the AC1 fixture, when `./next --drive` runs after S1's develop dispatch, then it
  dispatches design on S2 beside the running develop leg rather than waiting. Red: `--drive` choosing
  design per row only.
- [ ] AC3 — Given a fixture epic with S1 and S2 specified, when S2 is marked as needing revisiting, then
  `./next` routes S2 (to the stage design names) and S1 stays takeable at develop with its digest and
  claim unchanged. Red: a status written to the epic, or to S1.
- [ ] AC4 — Given a fixture sliced item in today's single-file shape, when the migration runs (or, if
  design keeps both shapes, when every script reads it), then every FR and AC lands in exactly one slice
  file and every AC's digest equals its pre-migration value. Red: an AC lost, duplicated or re-digested.
- [ ] AC5 — Given a fixture whose S1 passed verify and whose S2 is unspecified, when verify hands off,
  then the next dispatch is design on S2 with no intervening develop session. Red: `handoff`'s
  verify → design `--slice` refusal.
- [ ] AC6 — Given the tree after the change, when `for t in tests/*.test.sh; do "$t" || exit 1; done`
  runs, then it exits 0. Red: any script or fixture left on the single-file assumption.

## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — the slice-file layout and the readers: `next` and `--drift` read an epic index plus slice files, and an unsliced ticket is unchanged — unspecified
- [ ] S2 — claim and lock per slice; `handoff`, `close` and `reopen` act on a slice — unspecified
- [ ] S3 — slice status (needs revisiting, waiting) and `--drive` choosing a slice, design beside develop — unspecified
- [ ] S4 — migration of the sliced items on disk, and the skills, `CONCURRENCY.md` and 0242 S13's rules moved onto slice files, with the CHANGELOG — unspecified

## QA plan

Fixture backlogs in `tests/*.test.sh`, at `qa_level: unit` (the scripts are the mechanism); the skill
and reference prose is checked by reading, not by a guard (`CLAUDE.md`, *Tests*). Design names the
cases per slice.

## Out of scope

- Changing how an unsliced ticket is stored.
- Sprint's loop judgement and `bounce_max` (0244).
- Any change to 0242's criteria before 0242 closes; 0242's S13 rules move in FR8, after it lands.

## Notes & decisions

- **2026-11-27 (queue `e782`, sprint run-20261127T024025Z).** Captured on the person's approval of the
  supervisor's recommendation on answer 2; the outcome is quoted in their words. Minted, not amended:
  the open outcome nearest it is 0242's (one script call per backlog write, scripts agreeing), and this
  changes the storage those scripts act on, which is an outcome of its own. It is not folded into 0242
  because 0242 is rewriting the same scripts now (the approved recommendation says so).
- **Routed to `design`** on trigger 1: the layout, the claim's unit and the status vocabulary decide every
  criterion's form, and the choice is concurrency architecture. The ACs above are the outcome's, fixed
  regardless; design sharpens them and restamps.
- **Ranked directly below 0242** (tier 2, compounding: every new sliced epic is written in the shape this
  changes, and each must be migrated). Not `blocked_by` 0242, so design can run while 0242 is built;
  develop on it should start after 0242 closes, since both rewrite `next`, `claim` and `handoff`.
- Absorbs three `FINDINGS.md` entries dated 2026-11-27 (`c9183cc`; verify `e297`; design `b7a4`), each
  marked `[->0243]` there and discharged by FR4, FR5 and FR6.

- **2026-11-27 (retro, sprint run-20261127T024025Z tail) — six more `FINDINGS.md` entries absorbed
  here, each a design input for the open question, not yet a criterion; re-verify on claim.** All
  were observed on 0242 in this run except the first (0234 S1, 2026-11-26).
  - *Which leg is under test is not recorded on a path through `queue`.* `slice:` is written only by
    develop → verify `--slice`; 0234 S1 went develop → queue (an AC repair) → verify, arrived with
    `slice:` empty, and the passing `./handoff --slice S<n>` refused until verify set `slice: S1` by
    hand. FR5's in-sprint queue repair makes that path routine. Bears on (2) and (3): a slice file
    that carries its own stage makes the leg under test a fact rather than a field one path forgets.
  - *A slice kind is parsed from free text and defaults silently.* `progress_slices` (`handoff`,
    `next`) takes the kind from the text after the last ` — ` and reads anything unrecognised as `ac`,
    so `— unspecified; waiting on a person` made an undesignable slice look buildable (design `56a2`,
    S13). Bears on (1) and (3): the kind belongs in a field a reader can refuse when unknown.
  - *An answered `waiting` row has no scripted way back to `ready`.* Twice on 0242 in this run
    (design `3708`, design `213b`): `./claim` refused `0242 is 'waiting', not ready`, and each pass
    hand-edited row and item `status:` under the lock (`Resume 0242`). `handoff` takes `waiting` as a
    destination and nothing takes a row out of it. Bears on (3): whatever the slice-status vocabulary
    is, each state needs a scripted exit, and `waiting` is the one observed missing.
  - *Start from the existing `parent:` model, inverted so that only outcomes are ranked* (supervisor,
    at the user's request). `skills/queue/templates/item.md`'s `parent:` comment already gives children
    their own files and derives them by grep, but a project's row leaves `QUEUE.md` and its tasks are
    ranked and claimed; the user wants `QUEUE.md` to show only outcomes, with children reached through
    pointers and never worked as rows of their own. The design should cover: why 0242 chose one file
    over `parent:` (its Notes record the user's instruction to work an outcome as one ticket with
    ordered slices) and what parent/child lacked — slice order, one place to read the context; how
    `QUEUE.md`, `./next`'s take and the gate join change when only parents are ranked; a ticket that is
    both parent and child (rank only the top ancestor, or cap at two levels and refuse a third at
    capture); slice order and a "needs revisiting" status on a child. Bears on (1) and (4).
  - *A ticket with no parent and no children is an outcome* (supervisor, at the user's request): it is
    ranked and worked directly, and stays the same ticket in the same place when it later gains
    children. `item.md`'s `parent:` comment says the opposite ("a ticket with no children is a TASK"),
    and that line inverts with the ranking. Bears on (4) and (6).
