---
id: "0243"
title: Give each slice of an epic its own file, so claims, locks and revisits work per slice
type: feature
next: develop
status: ready
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
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=17efa2a3 AC2=8fc3064d AC3=b068c01f AC4=5a85d7be AC5=38c21a6e AC6=11fcfb0d AC7=8c9edf6a AC8=32c3d92f AC9=4f596816 AC10=5a668450 AC11=c2ead87f AC12=bea9eaca AC13=63945aa0 AC14=5baec811
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

Added by design `5945` (Option A, 2026-11-28). In FR1–FR10, a "slice file" is the slice's own item
file: a slice is a child ticket.

**S1 — layout and readers**
- FR12 — A slice is a child ticket: its own four-digit id and item file `items/NNNN-<slug>.md`, with
  `parent: "<epic>"`. It carries its own `next:`, `status:`, claim, FRs, ACs, `ac_digest:`,
  `## QA evidence` and `## Notes & decisions`. AC numbers stay unique across the epic, so an AC keeps
  its number, and therefore its digest, when it moves between the epic and a child.
- FR13 — The epic's `## Progress` is the only record of slice order. Each line is
  `- [ ] S<n> — <child id> — <what lands>`. A child stores no ordinal, so there is no second place
  for the order to go stale (the same reasoning as `item.md`'s derived children). The epic carries
  `status: active` and an empty `next:`. It holds the outcome, the problem, the NFRs and any FR that
  several slices share, and no AC of its own.
- FR14 — The hierarchy is inverted so that only outcomes are ranked. A ticket with no `parent:` is
  an outcome. It has a `QUEUE.md` row, and it stays the same ticket in the same place when it gains
  children. A ticket with a `parent:` is a slice. It has no row, and it is reached only through its
  parent. The depth is two levels: `capture` refuses a draft whose parent itself has a parent.
  `item.md`'s `parent:` comment and `QUEUE.md`'s header say this. Their current wording (children
  ranked, the project's row leaves) is the task-oriented system the person rejected.
- FR15 — An epic's `QUEUE.md` row shows, in its Next and Status cells, the `next:`/`status:` of its
  first open child in `## Progress` order. Every script that writes a child's state rewrites that
  row in the same locked commit.
- FR16 — `./next` and `./next <stage>` take from a ranked outcome as follows. For an epic, the
  candidate is its first child in `## Progress` order that is `ready`, unclaimed, at the asked stage
  (if one was given), and not excluded by FR23. An unsliced outcome is taken exactly as today.
- FR17 — `./next --drift` reports these cases: a child whose `parent:` names an epic that does not
  list it in `## Progress`; a `## Progress` id whose item is missing or names another parent; a child
  that holds a `QUEUE.md` row; and a third level. It reports nothing on a well-formed epic.

**S2 — claim, lock and release per child**
- FR18 — `claim`, `handoff`, `close` and `reopen` act on a child by its id, exactly as on a ticket.
  The claim on one child never refuses a claim on a sibling or on the epic. Where a script writes a
  row, a child's row is its epic's (FR15).
- FR19 — Only `queue` writes an epic file (its outcome, NFRs and `## Progress`). It does so under
  `./claim <epic>`, which accepts `status: active` and holds the epic file only. A hand-off releases
  that claim, restoring `status: active` and an empty `next:`. No child's session writes the epic.
  `capture` and `close` (FR20, FR29) are the exceptions: they are scripts writing the epic under the
  lock, in the way `close` already reconciles every ticket that names a closed one in `blocked_by:`.
- FR20 — `close <child>` ticks the child's `## Progress` line in the same commit. When it ticks the
  last open line, it also closes the epic and moves the epic's row to `DONE.md`.
- FR29 — For a draft with a `parent:`, `capture` takes no rank position and refuses one. It appends
  `- [ ] S<n> — <id> — <title>` to the epic's `## Progress` in the minting commit and writes no row.
- FR21 — "Needs revisiting" is a hand-off, not a new status. `./reopen <child> <queue|design> <reason>`
  sends one child, open or done, to the stage the reopener names. It takes no rank position. It
  unticks that child's line, and if the epic is `done` it reopens the epic too. No sibling's file
  changes.

**S3 — waiting, and `--drive` per child in slice order**
- FR22 — A `waiting` item has a scripted exit: `./reopen <id> --resume [<stage>]` sets it `ready`
  at its current `next:`, or at the stage given, under the lock in one commit. It refuses an item
  that is not `waiting`. This applies to any ticket, not only a child.
- FR23 — One outcome builds one slice at a time. A child at `next: develop` or `verify` is not
  takeable while a sibling is at `develop` or `verify` with status `ready` or `in-progress`. A child
  at `design` or `queue` is takeable beside one. A `waiting` or `blocked` child is skipped and parks
  no sibling (FR6). Order is a preference, not a gate: one slice that depends on another says so in
  `blocked_by:`, as any ticket does.
- FR24 — `--drive` dispatches per child, never per epic. Beside a running develop or verify leg it
  may dispatch design or queue on a sibling (FR4). Its next build leg for an outcome is always FR16's
  first takeable child, so legs advance the outcome in slice order and never alternate between
  siblings. A `parent:`-joined gate batch is one session, so it stays within FR23.
- FR25 — A child's stage is its own `next:`. A child that is not yet specified sits at
  `next: design`, so no slice kind is parsed from free text. When verify passes a child, the next
  dispatch for that outcome is the next child by its own `next:`, and that is design if it is
  unspecified (FR5). For a child, `handoff --slice` is refused as meaningless.

**S4 — migration, prose and changelog**
- FR26 — `./capture --split <id>` migrates one open single-file sliced item in one commit. It mints a
  child per `## Progress` line, in order. Each child gets the ACs its line's `discharges` list names,
  with their digest entries copied from the epic's stamp. An FR moves to the one child whose moved ACs
  cite it. An FR cited by several children, or by none, stays in the epic. A ticked slice becomes a
  `done` child with a `DONE.md` row. An unticked `unspecified` slice becomes `next: design`, and an
  unticked specified one becomes `next: develop`, `ready`. The epic's `## Progress` is rewritten to
  FR13's form, it becomes `status: active` with an empty `next:`, and its `ac_digest:` is cleared.
  Notes and QA evidence stay in the epic as its history, and each child's Notes open with
  `Split from <epic> on <date>`. It refuses, changing nothing, in these cases: the item or the
  backlog lock is held; `./next --ac-digest <id> --check` fails; or a stamped AC sits on no slice
  line or on two.
- FR27 — The legacy shape keeps reading. An item whose `## Progress` lines carry no child id is read,
  and handed off with `--slice`, exactly as today until it is split. A closed sliced item is never
  split: it is a record. S4 splits the open sliced items on disk, except 0243 itself, which finishes
  in the shape it was built in. It runs only when nothing is held (`CONCURRENCY.md`, *A change that
  touches every file takes an exclusive claim*).
- FR28 — The prose states the child model. `CONCURRENCY.md` and the `queue`, `design`, `develop`,
  `verify` and `sprint` SKILL.md files say a session loads the epic plus the one child it holds, and
  any sibling a `### Sibling consequences` entry names (FR7). Under that model 0242 S13's FR68
  "own-slice" case becomes the sibling case, because another slice is another item. `### Sibling
  consequences` entries name child ids, and `queue`'s FR69 fold-in writes those children (FR8).
  `sprint` states the person's constraint: a sprint is outcome-oriented, ranks and drives only
  outcomes, and never returns to a task-ranked queue.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Migration | The file layout changes under live backlogs here and in consuming projects. The old single-file sliced shape keeps reading (or is migrated by a script, in one commit, with every AC's digest unchanged) — never a flag day where an un-migrated item stops resolving | AC4's fixture: a pre-split sliced item that `./next`, `claim` or `--drift` misreads, or whose migrated ACs re-digest | `migration-conventions.md` |

## Acceptance criteria

Outcome-level and fixed regardless of the shape; design sharpens their fixtures and adds the rest.

- [ ] AC1 — Given a fixture outcome 0010 whose `## Progress` lists `S1 — 0011` and `S2 — 0012`,
  with 0011 claimed at develop by token A and 0012 at `next: design`, `ready`, when `./claim 0012`
  runs, then it succeeds, and 0011's item file and claim are byte-unchanged. Red: a claim refused
  because a sibling or the epic is held, or 0011's file changed.
- [ ] AC2 — Given the AC1 fixture, when `./next --drive` runs after 0011's develop dispatch, then it
  dispatches design on 0012 beside the running develop leg rather than waiting. Red: `--drive`
  dispatching per epic, or waiting on 0011.
- [ ] AC3 — Given a fixture outcome 0010 with children 0011 and 0012, both at develop and `ready`,
  when `./reopen 0012 design "<reason>"` runs, then 0012 is at `next: design` and its `## Progress`
  line is unticked, and 0011's item file is byte-unchanged and `./next develop` offers 0011. Red: a
  status written to the epic or to 0011, or reopen demanding a rank position for a child.
- [ ] AC4 — Given a fixture single-file sliced item with three slices (one ticked, one specified,
  one `unspecified`) and a matching `ac_digest:`, when `./capture --split <id>` runs, then the
  following hold. Every stamped AC lands in exactly one child, and each child's `./next --ac-digest
  <child>` entries equal the item's pre-split entries for those ACs. The children are done, at
  develop `ready`, and at design, in that order. The epic's `## Progress` lists their ids in FR13's
  form. It is all one commit. Red: an AC lost, duplicated or re-digested, or more than one commit.
- [ ] AC5 — Given a fixture outcome whose child 0011 is claimed at verify and whose next child 0012
  is at `next: design`, when verify passes 0011 (`close_by: verify`), then the next `./next --drive`
  dispatch for that outcome is design on 0012, with no develop session between. Red: a develop
  dispatch that only forwards, or `handoff`'s verify → design `--slice` refusal.
- [ ] AC6 — Given the tree after the change, when `for t in tests/*.test.sh; do "$t" || exit 1; done`
  runs, then it exits 0. Red: any script or fixture left on the single-file assumption.
- [ ] AC7 — Given the AC3 fixture with 0011 at develop `ready` and 0012 at design `ready`, and
  `QUEUE.md` holding only 0010's row, when `./next` runs, then it prints 0011, and `./next design`
  prints 0012. Red: no candidate, because neither child has a row, or 0010 itself offered.
- [ ] AC8 — Given the AC7 fixture plus a child 0013 with `parent: "0010"` that is absent from
  0010's `## Progress`, when `./next --drift` runs, then it names 0013 and exits non-zero. On the
  AC7 fixture alone it reports nothing about 0010–0012. Red: an unlisted child that goes unreported,
  or a false report on a well-formed epic.
- [ ] AC9 — Given the AC7 fixture, when `./capture` runs on a draft with `parent: "0011"`, then it
  exits non-zero, names the two-level cap, and mints no id. When it runs on a draft with
  `parent: "0010"` and no rank position, it mints the child, appends its `S3` line to 0010's
  `## Progress`, and adds no `QUEUE.md` row, all in one commit. Red: a grandchild minted, or a child
  ranked.
- [ ] AC10 — Given the AC1 fixture with 0011 held, when `./claim 0010` runs, then it succeeds and
  holds only 0010, and `./claim 0012` still succeeds after it. Red: an `active` epic refused as
  "not ready", or the epic's claim refusing a child's.
- [ ] AC11 — Given an outcome whose children are all `done` except 0012, held at verify, when
  `./close 0012 <token>` runs, then 0012's line is ticked, the epic is `done`, and the epic's row
  has moved to `DONE.md`, all in one commit. With a second child still open, the epic stays
  `active`. Red: an epic left open with every child done, or closed early.
- [ ] AC12 — Given an outcome whose child 0011 is `waiting` at design and whose child 0012 is at
  develop `ready`, when `./next develop` runs, then it offers 0012. When `./reopen 0011 --resume`
  runs, 0011 is at `next: design`, `ready`, in one commit. The same command on a `ready` item exits
  non-zero and changes nothing. Red: a waiting child parking its sibling, or a `waiting` row that
  only a hand edit can clear.
- [ ] AC13 — Given an outcome whose child 0011 is at `next: verify`, `ready`, and whose child 0012
  is at develop `ready`, when `./next develop` and `./next --drive --propose` run, then neither offers
  0012 until 0011 is `done`, or is at `queue` or `design`. Red: two build legs of one outcome open at
  once.
- [ ] AC14 — Given AC4's fixture, when `./capture --split <id>` runs with the item claimed, or with
  its `ac_digest:` not matching `./next --ac-digest <id>`, or with a stamped AC named on no slice
  line, then it exits non-zero, names the cause, and leaves the backlog's tree and history unchanged.
  Red: a partial split, or a split that re-digests silently.

## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — a slice is a child ticket, and the readers: `next` takes an outcome's first takeable child, `QUEUE.md` ranks only outcomes, `--drift` and `capture` know the two-level shape, and an unsliced ticket is unchanged (FR12–FR17, FR29) — discharges AC7, AC8, AC9
- [ ] S2 — claim, lock and release per child, an epic claim for `queue`, `close` ticking and closing the epic, and reopen as the revisit (FR18–FR21) — discharges AC1, AC3, AC10, AC11
- [ ] S3 — the waiting exit, one build leg per outcome, and `--drive` per child in slice order with design beside develop (FR22–FR25) — discharges AC2, AC5, AC12, AC13
- [ ] S4 — `capture --split` and the migration of the open sliced items, the legacy shape still reading, the skills, `CONCURRENCY.md` and 0242 S13's rules on the child model, and the CHANGELOG (FR26–FR28, FR8, FR11) — discharges AC4, AC6, AC14

## QA plan

Fixture backlogs in `tests/*.test.sh`, at `qa_level: unit` (the scripts are the mechanism); the skill
and reference prose is checked by reading, not by a guard (`CLAUDE.md`, *Tests*). Design names the
cases per slice: they are the ACs named on each `## Progress` line, each a fixture backlog in the
script's own `tests/<script>.test.sh`.

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
- **2026-11-28 (queue, dispatched after sprint run-20261127T234238Z) — the person answered the
  `## Waiting on` brief: Option A.** Verbatim:
  > "Option A. We had a system like this before but it was oriented to tasks (children) instead of
  > projects (parents). We just need to make sure that we stay outcome oriented with our sprints so
  > we don't keep going back and forth."

  Resumed to `next: design`, `status: ready` by hand under the lock (no script takes a row out of
  `waiting`: the gap the Notes above record). **For the design pass:** record Option A as the decision,
  write the slice FRs/ACs and the `## Progress` slices, and delete `## Waiting on` and
  `## Open design question`. **Carry the person's constraint as a design input, not a criterion yet:**
  sprints stay outcome-oriented. Only outcomes (parents) are ranked and driven. A child slice is
  reached through its parent and never worked as a free-standing row, and the design must not swing
  back to a task-ranked queue, which is the earlier system this answer rejects. "No back and forth"
  also bears on `--drive`: legs of one outcome advance it in slice order, they do not bounce between
  siblings or stages (see 0244, answered the same day). No FR or AC was changed in this pass and
  `ac_digest` was not restamped. The design pass restamps when it writes criteria.

- **2026-11-28 (design `5945`, dispatched by a sprint supervisor) — decided: Option A, slices are
  child tickets, and only outcomes are ranked.** The decision is the person's (the answer quoted
  above). This pass worked out what that answer implies and wrote it as FR12–FR28 and AC7–AC14.
  - *Rejected:* B, slice files under `items/<id>/` with a `<id>/S<n>` address. It would add a second
    addressing scheme to all six scripts. C, a claim per `## Progress` line, fails FR1 and FR7.
  - *Departed from the brief, on fact:* the brief gave a child an ordinal `slice: S<n>`. This design
    stores none, and the epic's `## Progress` line order is the only order (FR13). An ordinal stored
    in the child is a second place to update, the reason `item.md` derives children rather than
    storing them. `slice:` keeps its leg meaning on legacy items. The brief's "`waiting` gets a
    scripted exit" is FR22, `reopen --resume`.
  - *The person's constraint, carried:* "stay outcome oriented with our sprints so we don't keep
    going back and forth". Only outcomes are ranked or driven (FR14, FR24). The build legs of one
    outcome run one at a time, in slice order (FR23, FR24). Design or queue on a sibling may run
    beside them, which is what FR4 asked for. That stops the alternation between siblings. 0244 owns
    the loop judgement and `bounce_max`.
  - *Accounting against the criteria queue wrote:* FR1–FR11 are confirmed. FR1's "slice file" reads
    as the child's item file. FR3 is settled as FR21 (revisit is a reopen to a named stage, not a new
    status). FR8 changes in substance, not in wording: under A, another slice is another item, so
    0242 S13's own-slice case folds into `### Sibling consequences` (FR28). AC1, AC3, AC4 and AC5
    are re-fixtured in the child form, with their outcomes unchanged. AC2 and AC6 are unchanged in
    substance. AC7–AC14 are added.
  - *Facts re-read today (2026-11-28) in `skills/queue/templates/`:*
    - `item_for` globs `items/<id>-*.md` (`next:729`). A child has its own id, so nothing collides.
    - `claim` holds one claim per id and refuses a status that is not `ready` (`claim:287`). That
      is why FR19 opens `active` for an epic.
    - The `--ac-digest` entries are keyed by AC number over the AC's text (`next:546`), so a moved
      AC keeps its digest (AC4).
    - `gate_from` joins a batch on a shared `parent:` (`next:1557`). Every sibling now shares one,
      so FR24 bounds that batch to one session.
    - `handoff`'s `--slice` path (`handoff:709`) stays for legacy items (FR27).
  - *`qa_level: unit` and `close_by: verify` re-read against these criteria, and both are kept:*
    every AC is a fixture-backlog script test, and the prose (FR28) is checked by reading.
    `size: l` stands at four slices.
  - *No sibling consequence.* 0242 is not written. FR8 and FR28 move its S13 rules in this item's
    own S4, after 0242 closes (Out of scope).
