---
id: "0140"
title: Decide whether a held item under a ready row is drift, and stop offering it twice
type: bug
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-09-10
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

- [x] AC1 — Given a row reading `develop | ready` whose item carries `claimed_by: tok9`, when
  `./next develop` runs, then it does not print `TAKE 0001`. Red-making input: today's `next`, which
  prints exactly that, captured in *Problem*.
- [x] AC2 — Given that same row, when `./next develop` runs, then it prints a skip line naming both
  the id and `tok9`, and exits 0. Red-making input: a line naming the id alone (the NFR's own red).
- [x] AC3 — Given a held row ranked above a clear one at the same stage, when `./next develop` runs,
  then it prints the skip line for the held row **and** `TAKE` for the clear one. Red-making input:
  `break` in place of `continue` — the clear row goes unoffered.
- [x] AC4 — Given a row that is both held and has an open `blocked_by` entry, when `./next develop`
  runs, then exactly one line is printed for it, the `SKIP … blocked_by still open` one. Red-making
  input: moving the held check above the blocker check, which prints two.
- [x] AC5 — Given a row reading `ready` over an item with `claimed_by: tok9` and `status: ready`,
  when `./next --drift` runs, then it prints one line naming the id and `tok9`, and exits 1.
  Red-making input: today's `next`, which prints `no drift` and exits 0, captured in *Problem*.
- [x] AC6 — Given that same row, when `./next --drift` runs, then it prints exactly one line for it.
  Red-making input: a sixth branch appended as a separate `if` rather than into the `elif` chain,
  where a row disagreeing on `status:` as well reports twice.
- [x] AC7 — Given the held row is the top takeable `next: develop` row, when `./next --drive` runs,
  then it does not dispatch it and the `DEPTH` count does not include it. Red-making input:
  `takeable_develop` left filtering on the column alone.
- [x] AC8 — Given a row reading `ready` over an item with `claimed_by: tok9`, when `./next develop`
  runs, then `CLAIMED FILES` lists `0001 [tok9]`. Red-making input: `show_claimed` left filtering on
  `status == in-progress`, which omits it.
- [x] AC9 — Given a row reading `in-progress` over an item with an empty `claimed_by:`, when
  `./next develop` runs, then it appears in no `CLAIMED FILES` line and produces no `COLLIDES`
  against a candidate sharing its `touches:`. Red-making input: FR3 implemented as a union of the
  column and the token rather than a replacement.
- [x] AC10 — Given `references/CONCURRENCY.md` and both copies of `next`, when the suite runs, then
  the *held* definition appears once, in `CONCURRENCY.md`, and `next` cites it. Red-making input: a
  comment in `next` restating "a non-empty `claimed_by:` and nothing else".
- [x] AC11 — Given the change, when `tests/backlog-scripts-installed.test.sh` runs, then it is
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

Verified 2026-09-09 `[b59a]` at `qa_level: unit` against `7f54025`, tree clean at Step 2 and at
verdict. `config.yml` configures no `lint` or `typecheck`, so `unit` is the whole gate: every
`tests/*.test.sh` run individually rather than through the fail-fast one-liner (`config.yml` says
why). All 27 files green; `tests/next.test.sh` **266 passed, 0 failed**,
`tests/backlog-scripts-installed.test.sh` **37 passed, 0 failed** — tallies pasted from the runs.

**Which copy was executed.** `tests/next.test.sh` copies `skills/queue/templates/next` into its
fixture (`NEXT_SRC`, line 23), so every behavioural case exercises the TEMPLATE. Behavioural
mutations were therefore applied there; `.claude/backlog/next` is byte-identical to it (`diff`), and
AC10/AC11 read both. The repo copies are the authority here — this session's own skills resolved
from the 0.9.22 install, which predates this change.

| # | Criterion | How checked | Mutation that reddens it | Result |
|---|---|---|---|---|
| AC1 | held row not offered | `0140 AC1/AC2` case, `TAKE 0001` absent | M1 take-loop skip removed → 5 red | PASS |
| AC2 | skip line names id and token, exit 0 | same case, `SKIP 0001` matched for `0001` and `tok9` | M1 → *names the id on a skip line*, *and names the token* red | PASS |
| AC3 | held row above a clear one does not stop the walk | `0140 AC3` case, `SKIP 0001` + `TAKE 0002` | M2 `continue`→`break` → *and still offers the clear one* red | PASS |
| AC4 | held **and** blocked reports once, the blocker | `0140 AC4` case, `lines_naming ^SKIP      0001 ` = 1 | M3 held check moved above the blocker check → *reports the open blocker* red | PASS |
| AC5 | `--drift` names id and token, exits 1 | `0140 AC5/AC6` case | M4 class 6 removed → 4 red | PASS |
| AC6 | exactly one `DRIFT` line, incl. a row also disagreeing on `status:` | both `0140 AC6` cases | M5 class 6 as a separate `if` → *one DRIFT line for the row* red | PASS |
| AC7 | `--drive` neither dispatches nor counts it | `0140 AC7` case, `DEPTH 0 develop gate(s)`, rc 3 | M6 `takeable_develop` check removed → *counts no takeable gate* red; M7 rank-walk NOTE removed → *dispatches nothing* red | PASS |
| AC8 | `CLAIMED FILES` lists `0001 [tok9]` under a `ready` column | `0140 AC8` case | M8 `show_claimed` keyed back on the column → 2 red | PASS |
| AC9 | tokenless `in-progress` is not a claim | `0140 AC9` case, no `COLLIDES`, no `CLAIMED FILES` line | M9 `collision_report` keyed back on the column → 2 red | PASS |
| AC10 | *held* defined once, in `CONCURRENCY.md`; `next` cites it | `0140 AC10` case; both copies `grep -c 'non-empty'` = 0 | appending a restating comment to `.claude/backlog/next` → 265/1 red | PASS |
| AC11 | `tests/backlog-scripts-installed.test.sh` green | run directly, 37/0 | editing the template only → 36/1 red | PASS |

Control: unmutated template, **266 passed, 0 failed**. Eleven mutations, every one red, each with a
non-empty `git diff --stat` confirming it landed. The build notes' sweep was re-run rather than
trusted.

| NFR | How checked | Result |
|---|---|---|
| Observability | Every ownership line names id **and** token: `SKIP … held by tok9`, `DRIFT … claimed_by: tok9`, `NOTE … is held by tok9`, `CLAIMED FILES … 0001 [tok9]`. The NFR's own red — a line naming the id alone — is AC2's second assertion, red under M1. | PASS |
| Documentation | The six drift classes are enumerated only in `next`'s `--drift` header; *held* is defined only in `CONCURRENCY.md`, which gains the consequence sentence, and both copies of `next` cite *A stage writes only the ticket it holds* rather than restating it. AC10 guards the second copy. | PASS |
| Dependencies | The diff adds `held_by`, built from `item_for`/`fm` and `printf`. No binary beyond `/bin/sh`, `git`, `awk`. | PASS |

Always-on pass (`CONVENTIONS_CORE.md`): one predicate doing one thing with its inputs guarded at the
top (`held_by` returns 1 on a missing item and on an empty token); comments give the why and cite
rather than restate; no magic strings; no secrets; no new nesting beyond two levels. The change adds
no log field, analytics event or egress destination, and touches no auth, credential or
data-visibility path, so `data-privacy-conventions.md` and `security-conventions.md` have no
surface here; no UI, so no accessibility surface. Newly reachable states: the change only *narrows*
what `./next` offers — it creates no new route to a destructive or privileged action.

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

- **Built 2026-09-09 `[4cbb]`.** Candidate (c) as designed, one commit (`7f54025`). `0136` had landed
  by claim time so the `expects:` collision its *Sequencing* note predicted never arose, and
  `gate_from`'s rewrite there does not meet any site this ticket changes.

- **FR3 and *Out of scope* disagree about the take loop, and the resolution is deliberate.** FR3 says
  "no site keys ownership off the Status column"; read literally that condemns the take loop's
  `case "$written" in ready|blocked)` filter and `--drive`'s `in-progress` skips, which would make a
  tokenless `in-progress` row TAKEable. *Out of scope* defers exactly that direction to `0115` FR3,
  and AC9 constrains only `show_claimed` and `collision_report`. So those two sites were rewritten to
  read the token and nothing else, and the `in-progress` column skips were LEFT: `in-progress` there
  is a status a stage wrote about itself, not an ownership read, and `--drift` class 5 reports the
  tokenless case for a person to reconcile rather than silently promoting it to takeable. If that is
  the wrong call it is a row of its own, not a widening of this one.

- **AC10's first red was a pre-existing restatement, not one this change introduced.** The AC's
  red-making input is "a comment in `next` restating 'a non-empty `claimed_by:` and nothing else'" —
  which `next:483`, the `--drift` class 5 comment, had said verbatim since `0115`. So satisfying AC10
  meant *removing* existing prose, and a session reading the AC as a constraint on its own new
  comments would have left the guard red with nothing it wrote to blame. Worth knowing because the
  same shape will recur: a single-source AC is a claim about the whole file, not about the diff.

- **The `--drift` class 6 branch is an assignment used as a condition** — `elif [ … ] && dtok="$(held_by "$id")"; then` — which is POSIX (a bare assignment's status is the last command
  substitution's) and is what lets one call both test and capture the token. The same shape is in
  the take loop and the `--drive` walk. It reads as a typo for `==`; it is not.

- **Mutation sweep, 2026-09-09, against the committed tree.** Ten mutations plus a no-op control, the
  control green at 266/266 and every mutation red: take-loop skip removed (5 red), `continue`→`break`
  (1), held check moved above the blocker check (1), class 6 removed (4), class 6 as a separate `if`
  (1), `takeable_develop` check removed (1), rank-walk NOTE removed (2), `show_claimed` keyed back on
  the column (2), `collision_report` keyed back on the column (2). AC4 and the second AC6 case pass
  vacuously on today's code and only their mutations prove them, which is why both are in the list.
