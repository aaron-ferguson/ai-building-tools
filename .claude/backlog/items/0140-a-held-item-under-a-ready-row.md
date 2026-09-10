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

## Open design question

- **Question:** Which record is authoritative for **takeability** — the Status column, or the item's
  `claimed_by:`? Three candidates, and they are not equivalent: **(a)** it is drift, so `--drift`
  gains a sixth class and nothing else changes, leaving `./next <stage>` still offering the row until
  a human reconciles it; **(b)** it is a takeability bug, so `./next <stage>` skips a row whose item
  is held regardless of what the column says, and `--drift` need not grow at all; **(c)** both, on
  the reasoning that a reader must not offer it *and* the disagreement is still worth naming.
- **Why it blocks specification:** the acceptance criteria have no overlap. (a) is an AC about a new
  `--drift` line and its exit code. (b) is an AC about what `./next develop` prints for a held row,
  and it changes the meaning of the Status column for every reader at once. (c) has to say which
  fires first so one state does not produce two reports, which is the precedence problem `0115` FR4
  already had to settle for a different pair.
- **Settle it with:** `/design` — the inputs are `CONCURRENCY.md`'s *A stage writes only the ticket
  it holds*, `0029`'s definition of *held*, and `next`'s existing reader. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What holds regardless:

- **FR1 — a ticket with a non-empty `claimed_by:` is not silently offered to a second session.**
  Whichever mechanism the decision picks, the driven state above must stop ending in `TAKE`.
- **FR2 — the answer lands in both copies of the script**, `skills/queue/templates/next` and
  `.claude/backlog/next`, leaving `tests/backlog-scripts-installed.test.sh` green.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Observability | Whatever is printed names the id and the token holding it, on the pattern the existing `COLLIDES` and `DRIFT` lines set. A line that says only that a row is unavailable sends the reader to open the ticket. Would red on a line naming the id alone. | `observability-conventions.md` |
| Documentation | The class list in `next`'s `--drift` header and the takeability rule in `CONCURRENCY.md` stay single-sourced — whichever gains the rule, the other cites it. Would red on a second copy. | `documentation-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk` and the helpers `next` already carries. Nothing new. Would red on any added binary. | `dependency-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. This one holds regardless:

- [ ] AC1 — Given a row reading `develop | ready` whose item carries `claimed_by: tok9`, when
  `./next develop` runs, then it does not print `TAKE 0001`. Red-making input: today's `next`, which
  prints exactly that, captured in the Problem section above.

## QA plan

- **Why this level:** `unit` — `next` is a shell script with an existing suite, and every candidate
  remedy is an ordinary case in `tests/next.test.sh` over a scaffolded fixture backlog. The level is
  the same across all three candidates, so it is set now.
- **Specific checks:** settled by the design pass. `tests/next.test.sh` and
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
