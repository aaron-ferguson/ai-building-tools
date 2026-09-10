---
id: "0140"
title: Decide whether a held item under a ready row is drift, and stop offering it twice
type: bug
next: design
status: in-progress
qa_level: unit
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0115", "0049", "0029", "0096"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
  - references/CONCURRENCY.md
claimed_by: "e1ec"
claimed_at: 2026-09-10T01:32:16Z
touches:
  - .claude/backlog/items/0140-a-held-item-under-a-ready-row.md
---

## Problem

**A ticket that is genuinely held can be handed to a second session, and nothing reports it.**
`0115` gave `--drift` the row-against-item classes, and one of them is asymmetric: a row reading
`in-progress` over an empty `claimed_by:` is reported, but the mirror image — a row reading `ready`
over an item whose `claimed_by:` is **not** empty — is silent.

Driven at the CLI during `0115`'s QA pass on 2026-09-09, token `2390`, on a scaffolded fixture:

```
row:   | 0001 | Fixture | develop | ready |  |
item:  next: develop, status: ready, claimed_by: tok9, claimed_at: 2026-09-09

$ ./next --drift
no drift: every row agrees with its blocked_by and with its item
$ echo $?
0
$ ./next develop
TAKE      0001 | Fixture | size s | qa unit | close verify
EXPECTS   some/file.md
```

`0029` settled *held* as **a non-empty `claimed_by:` and nothing else**, and `CONCURRENCY.md`'s
*A stage writes only the ticket it holds* is written on that definition. By it, `0001` above is
held — and `./next develop` offers it anyway, because takeability is read off the Status column
(`next:412` reads `claimed_by` only for the collision report, never for the offer itself).

**This is the `0084` symptom pair running the other way.** There, a row invisible to the stage that
would take it blocked the stage that would not. Here, a ticket somebody is actively building is
handed to a second session as takeable, and `./claim` will grant it — the two windows then work the
same files with no merge protocol behind them, which is the exact outcome the whole concurrency
design exists to prevent.

The gap is pre-existing — `--drift` never read `claimed_by:` before `0115` — but `0115` is what made
`--drift` a row-against-item instrument, so the asymmetry is now a hole in a stated class list
rather than an absence nobody had promised to fill.

## Functional requirements

Settled by `/design` on 2026-09-09 `[e1ec]` — candidate **(c)**, with the item authoritative. See
*Notes & decisions*.

- **FR1 — a ticket with a non-empty `claimed_by:` is not silently offered to a second session.**
  The driven state in *Problem* must stop ending in `TAKE`.
- **FR2 — the answer lands in both copies of the script**, `skills/queue/templates/next` and
  `.claude/backlog/next`, leaving `tests/backlog-scripts-installed.test.sh` green.
- **FR3 — one predicate for *held*, and every ownership question in `next` routes through it.**
  A single helper reading a non-empty `claimed_by:` off the item; no site re-implements it and no
  site keys ownership off the Status column. **This changes behaviour and is not a refactor:** the
  two sites that filter on `status == in-progress` today — `show_claimed` and `collision_report` —
  stop treating a tokenless `in-progress` row as a claim, which is what `CONCURRENCY.md` already
  requires ("no reader treats such a row as a claim") and what `--drift` class 5 already reports.
- **FR4 — `./next <stage>` skips a held row and keeps going.** One line naming the id and the
  token, then `continue` to the next candidate — never `break`, for the reason the collision branch
  already carries: a session correctly warned and still with nothing to do is the same outcome by a
  slower route. Precedence inside the loop is one line per row, the open blocker first.
- **FR5 — `--drive` applies the same predicate**, in `takeable_develop` and `depth_stopper`. Its
  own comment already promises "the same predicate `./next develop` applies", and unfixed here the
  driver dispatches an unattended second session onto a held ticket — the worse instance of the
  same defect.
- **FR6 — `--drift` gains a sixth class**: a row not reading `in-progress` over a non-empty
  `claimed_by:`. Added to the header's class list, which is the one place they are enumerated
  (0115 FR6), and to the elif chain after class 5 so one row still produces one line.
- **FR7 — the definition stays in `CONCURRENCY.md` and the consequence goes with it.** *A stage
  writes only the ticket it holds* already owns *held*; it gains one sentence saying no reader
  offers a held row and that `./next` enforces it. `next`'s comments cite that section rather than
  restating the definition, and the drift class list stays in `next`'s header
  (`documentation-conventions.md`, *Separate the Rule From the Reasoning* — a rule an agent could
  violate before opening another file is operative, and the enumeration belongs to the mode whose
  contract it is).

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Observability | Whatever is printed names the id and the token holding it, on the pattern the existing `COLLIDES` and `DRIFT` lines set. A line that says only that a row is unavailable sends the reader to open the ticket. Would red on a line naming the id alone. | `observability-conventions.md` |
| Documentation | The class list in `next`'s `--drift` header and the takeability rule in `CONCURRENCY.md` stay single-sourced — whichever gains the rule, the other cites it. Would red on a second copy. | `documentation-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk` and the helpers `next` already carries. Nothing new. Would red on any added binary. | `dependency-conventions.md` |

## Acceptance criteria

Fixtures are `tests/next.test.sh`'s scaffolded backlog; `0001` below is its fixture row.

- [ ] AC1 — Given a row reading `develop | ready` whose item carries `claimed_by: tok9`, when
  `./next develop` runs, then it does not print `TAKE 0001`. Red-making input: today's `next`, which
  prints exactly that, captured in *Problem*.
- [ ] AC2 — Given that same row, when `./next develop` runs, then it prints a skip line naming both
  the id and `tok9`, and exits 0. Red-making input: a line naming the id alone (the NFR's own red).
- [ ] AC3 — Given a held row ranked above a clear one at the same stage, when `./next develop` runs,
  then it prints the skip line for the held row **and** `TAKE` for the clear one. Red-making input:
  `break` in place of `continue` — the clear row goes unoffered.
- [ ] AC4 — Given a row that is both held and has an open `blocked_by` entry, when `./next develop`
  runs, then exactly one line is printed for it, the `SKIP … blocked_by still open` one. Red-making
  input: moving the held check above the blocker check, which prints two.
- [ ] AC5 — Given a row reading `ready` over an item with `claimed_by: tok9` and `status: ready`,
  when `./next --drift` runs, then it prints one line naming the id and `tok9`, and exits 1.
  Red-making input: today's `next`, which prints `no drift` and exits 0, captured in *Problem*.
- [ ] AC6 — Given that same row, when `./next --drift` runs, then it prints exactly one line for it.
  Red-making input: a sixth branch appended as a separate `if` rather than into the `elif` chain,
  where a row disagreeing on `status:` as well reports twice.
- [ ] AC7 — Given the held row is the top takeable `next: develop` row, when `./next --drive` runs,
  then it does not dispatch it and the `DEPTH` count does not include it. Red-making input:
  `takeable_develop` left filtering on the column alone.
- [ ] AC8 — Given a row reading `ready` over an item with `claimed_by: tok9`, when `./next develop`
  runs, then `CLAIMED FILES` lists `0001 [tok9]`. Red-making input: `show_claimed` left filtering on
  `status == in-progress`, which omits it.
- [ ] AC9 — Given a row reading `in-progress` over an item with an empty `claimed_by:`, when
  `./next develop` runs, then it appears in no `CLAIMED FILES` line and produces no `COLLIDES`
  against a candidate sharing its `touches:`. Red-making input: FR3 implemented as a union of the
  column and the token rather than a replacement.
- [ ] AC10 — Given `references/CONCURRENCY.md` and both copies of `next`, when the suite runs, then
  the *held* definition appears once, in `CONCURRENCY.md`, and `next` cites it. Red-making input: a
  comment in `next` restating "a non-empty `claimed_by:` and nothing else".
- [ ] AC11 — Given the change, when `tests/backlog-scripts-installed.test.sh` runs, then it is
  green. Red-making input: editing one copy of `next` and not the other.

## QA plan

- **Why this level:** `unit` — `next` is a shell script with an existing suite, and every candidate
  remedy is an ordinary case in `tests/next.test.sh` over a scaffolded fixture backlog. The level is
  the same across all three candidates, so it is set now.
- **Specific checks:** AC1–AC9 are cases in `tests/next.test.sh` over the scaffolded fixture;
  AC10 is a `grep` guard for a second copy of the definition; AC11 is the existing installed-scripts
  guard. `tests/next.test.sh` and
  `tests/backlog-scripts-installed.test.sh` run in every case, and any new branch is mutation-proved
  the way `0115`'s were — neuter it, confirm the mutation landed, confirm the suite reds, restore.

## Out of scope

- **What a claim token *is*.** Uniqueness, liveness and attribution are `0049`, which is a different
  question: this ticket takes `claimed_by:` at face value and asks only who honours it.
- **The tokenless `in-progress` direction.** `0115` FR3 ships that, and `CONCURRENCY.md` already says
  no reader treats such a row as a claim.
- **Reconciling the disagreement.** `--drift` reports and never writes, and a held ticket is the one
  thing a stage must not write (`CONCURRENCY.md`, *A stage writes only the ticket it holds*).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed from `0115`'s verify pass, 2026-09-09 `[2390]`**, as a probe finding rather than a criterion
  of that ticket. `0115`'s FRs name only the tokenless direction and its *Out of scope* defers the
  honouring question to `0049`, whose framing does not reach this direction — so this is a new row and
  not a widening of either.
- **Routed to `design`, not `develop`.** The three candidates assert incompatible things, and (b)
  changes what the Status column means for every reader of `next`. Unfamiliar would not be enough to
  route here; incompatible acceptance criteria are.

- **Settled 2026-09-09 `[e1ec]` — candidate (c), and the item's `claimed_by:` is authoritative for
  takeability.** The Status column caches ownership exactly as it caches `blocked`: `CONCURRENCY.md`
  *Claim tokens* says the token's home is the item and "the pared `QUEUE.md` has no ownership
  column", and `QUEUE.md`'s own header already says the cache loses to the record it caches. So this
  is not a new precedent — it is the treatment the take loop **already applies to the other derived
  pair**, whose comment at `next:780` says trusting the cache is "the asymmetric half of the
  defect". A row written `blocked` over a clear graph is offered anyway with a `DRIFT` line; a row
  written `ready` over an open blocker is skipped with a `SKIP` line. Ownership gets the same two
  lines in the same two places, for the same reason.
- **What (c) had to settle — which report fires first — turns out not to arise.** `--drift` is its
  own mode and exits at `next:526` before the stage loop is reached, so no invocation can produce
  both. The precedence that does need stating is inside the stage loop, between the held line and
  the existing blocker line, and FR4 fixes it at one line per row.
- **Rejected (a), drift-only.** It wins only if the column is authoritative for ownership, and
  `CONCURRENCY.md` says it is not. It also leaves the race live: `--drift` reports, a human
  reconciles later, and in between `./next` offers the row and `./claim` grants it — which is the
  outcome in *Problem*.
- **Rejected (b), takeability-only.** Silence would be defensible if anything else named the state,
  but nothing does, and `--drift`'s header enumerates the row-against-item classes as that mode's
  published contract — an unlisted class is a hole in it.
- **Trade-off accepted: the Status column stops being sufficient to read takeability by eye.** A
  reader of `QUEUE.md` alone can see `ready` on a row nobody may take. That is the cost of the same
  bargain `blocked` already struck, it is bounded by `--drift` naming every instance, and the header
  already tells readers to use `./next` rather than their eyes.
- **The correction FR3 carries.** `next:783` reads "`waiting` and `in-progress` are NOT derived — a
  person and a claim clear those". True of `waiting`; of `in-progress` it asserts the column tracks
  the claim, which is the assumption this ticket disproves. That comment is part of the change.
- **Sequencing, not a blocker.** `0136` holds `.claude/backlog/next`, `skills/queue/templates/next`
  and `tests/next.test.sh` as of 2026-09-10T01:30:50Z `[601e]` — verified by reading its item, not
  the row. `./next develop` will report the collision on `expects:` when this reaches build; no
  ordering constraint is written into `blocked_by`, because the two changes touch different
  functions and either order works once the other has landed.
