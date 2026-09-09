---
id: "0115"
title: Make --drift see a row and its item disagreeing, as three files say it does
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-09-08
source: agent
parent:
blocked_by: []
relates: ["0081", "0096", "0029", "0049"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
  - tests/handoff.test.sh
  - references/CONCURRENCY.md
  - docs/decisions/001-one-command-per-stage-boundary.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`./next --drift` compares the `Status` column against `blocked_by` and nothing else, while three
files tell sessions it also catches a row and its item disagreeing.** It is the repo's only drift
instrument, `orchestrate` routes on its exit code, and on the class it is pointed at most often it
prints `no drift` and exits zero.

The code is `next:473-494`. Two branches, both on one axis:

```sh
if   [ "$written" = "blocked" ] && [ "$derived" = "ready" ];   then …
elif [ "$written" != "blocked" ] && [ "$derived" = "blocked" ]; then …
```

`written` is the row's `Status` cell, `derived` comes from `blocked_by`. The item's own `next:`,
`status:` and `claimed_by:` are never read.

**Measured, deliberately, on 2026-09-08** (item `0081`, verify `[9840]`). Mutating
`mv "$queue_tmp" "$QUEUE"` out of `./handoff` — the mutation confirmed landed first — produced the
exact `0087` failure: an item at `next: verify, status: ready, claimed_by:` empty over a row still
reading `develop | in-progress`. **`--drift` printed `no drift` and exited 0.** That is `0081`'s AC4
driven against deliberately broken code and still green, which is why `0081` came back to `queue`
rather than closing.

**And it is not hypothetical, because the drift arrives from directions no script guards.** From
`FINDINGS.md` 2026-09-03, in this repo: `0084`'s row read `develop | in-progress` under token
`ae35` while its item read `next: verify, status: ready, claimed_by:` empty. The pair of symptoms is
the cost — **`./next verify` did not offer it, and `./next develop` reported its files as claimed**,
so a ticket ready to QA was invisible to the stage that would take it while still reserving scope
against the stage that would not. `--drift` was run and said nothing. `./handoff` now makes the
scripted hand-off atomic, but the by-hand fallbacks in `develop` Step 5 and `verify` Step 5, `retro`'s
appends, a `queue` re-specification and any session that dies mid-edit all still write this pair by
hand.

**Three prose sites assert the missing behaviour, so a session is right to rely on it:**

1. `references/CONCURRENCY.md:82`, *A stage writes only the ticket it holds* — *"A row reading
   `in-progress` over a tokenless item is drift, not ownership — `./next --drift` reports it, and no
   reader treats it as a claim."* It does not report it: `written` is `in-progress`, `derived` is
   `ready`, and neither branch fires.
2. `docs/decisions/001-one-command-per-stage-boundary.md:220` — *"`./next --drift` should read zero
   more often, because the two sites that have half-applied in the field (`0081`, `0048`) stop being
   hand edits."* A half-applied hand-off is not a thing `--drift` reads at all, in either direction.
3. `0081`'s own problem statement calls the row/item disagreement *"precisely the drift
   `./next --drift` exists to catch"*, and its AC4 was written on that belief.

`develop` Step 5's *"`./next --drift` lists every disagreement between column and graph"* and
`QUEUE.md`'s header are both accurate as written, and stay.

**One guard in the suite cannot fail because of this.** `tests/handoff.test.sh:461-472` asserts
`--drift` exits zero and names no DRIFT line after a hand-off. Both assertions hold against a
`handoff` with its queue write removed, which is `testing-conventions.md`'s assertion-that-cannot-fail
in the one suite whose subject is atomicity.

## Functional requirements

- **FR1 — `--drift` reports a row whose `Next` cell disagrees with its item's `next:`**, naming the
  id and both values.
- **FR2 — `--drift` reports a row whose `Status` cell disagrees with its item's `status:`**, naming
  the id and both values.
- **FR3 — `--drift` reports a row reading `in-progress` over an item whose `claimed_by:` is empty**,
  which is the class `CONCURRENCY.md:82` already names. It is distinct from FR2: `0029` settled
  *held* as a non-empty `claimed_by:` **and nothing else**, so a row and an item can agree on
  `in-progress` with nobody holding the ticket.
- **FR4 — every drift class exits non-zero, and a row is reported once.** The existing
  `blocked`-vs-`blocked_by` check keeps precedence over FR2 where both would fire on the same row,
  so a stale `blocked` cache produces one line and not two.
- **FR5 — a row whose item cannot be resolved is named as its own condition**, not silently skipped
  and not read as agreement. `item_for` returns empty for a missing or misnamed item file and every
  `fm` read on it returns empty, which would otherwise present as a `next:`/`status:` disagreement
  against empty strings.
- **FR6 — `references/CONCURRENCY.md:82` and
  `docs/decisions/001-one-command-per-stage-boundary.md:220` become true of the shipped `next`**,
  each stating which classes the report covers. Neither gains a copy of the rule the other holds.
- **FR7 — `tests/handoff.test.sh`'s AC4 case becomes a guard that can fail**: with the new check in
  place, removing `handoff`'s `mv "$queue_tmp" "$QUEUE"` must red it. That is the mutation which
  proved the assertion inert, and it is the one that must now bite.
- **FR8 — the edit lands in both copies**, `skills/queue/templates/next` (the shipped artifact) and
  `.claude/backlog/next` (this repo's instance), leaving `tests/backlog-scripts-installed.test.sh`
  green — it forces the two byte-identical.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Observability | Every new drift line names the id, the two disagreeing values and which side is which, on the pattern the existing two branches set. A drift report that says only *which* row is wrong sends the reader to open the ticket, which is the cost the mode exists to remove. Would red if a line printed the id alone. | `observability-conventions.md` |
| Testing | Each of FR1–FR5 gets a case in `tests/next.test.sh` asserting on the printed line **and** the exit code, and each is mutation-proved: neuter the branch, confirm the mutation landed, confirm the suite reds, restore. Would red if a branch could be removed with the suite still green. | `testing-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk`, and the `fm`, `fm_list`, `field`, `row_for`, `item_for` helpers `next` already carries. Nothing new. Would red on any added binary. | `dependency-conventions.md` |
| Documentation | The `--drift` line in `usage()` and the section comment at `next:467` state the classes the mode covers, in one place each. FR6's two prose sites cite that contract rather than restating it. Would red on a second copy of the class list. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a backlog whose row for `0001` reads `develop` and whose item reads
  `next: verify`, when `./next --drift` runs, then it prints a line naming `0001`, `develop` and
  `verify`, and exits non-zero. Red-making input: today's `next`, which prints `no drift` and exits 0.
- [ ] AC2 — Given a backlog whose row for `0001` reads `in-progress` and whose item reads
  `status: ready`, when `./next --drift` runs, then it prints a line naming `0001`, `in-progress` and
  `ready`, and exits non-zero. Red-making input: today's `next`, which prints `no drift`.
- [ ] AC3 — Given a backlog whose row for `0001` reads `in-progress` and whose item reads
  `status: in-progress` with an empty `claimed_by:`, when `./next --drift` runs, then it reports that
  row as tokenless and exits non-zero. Red-making mutation: dropping the `claimed_by:` read, which
  leaves the row silent because the two statuses agree.
- [ ] AC4 — Given a backlog whose row for `0001` reads `blocked` while every `blocked_by` entry is
  `done` **and** whose item reads `status: ready`, when `./next --drift` runs, then `0001` is named
  on exactly one line. Red-making mutation: reporting FR2 independently of the existing branch,
  which prints two lines for one row.
- [ ] AC5 — Given a row in `QUEUE.md` for which no `items/0001-*.md` exists, when `./next --drift`
  runs, then it names that row as having no item file and does not report it as a `next:` or
  `status:` disagreement. Red-making mutation: comparing against `fm`'s empty return, which reports
  it as `develop` versus the empty string.
- [ ] AC6 — Given a backlog with no disagreement of any class, when `./next --drift` runs, then it
  prints its no-drift line and exits 0. Red-making mutation: inverting any new comparison, which
  reports every clean row.
- [ ] AC7 — Given `./handoff` with `mv "$queue_tmp" "$QUEUE"` removed and the mutation diffed to
  confirm it landed, when `tests/handoff.test.sh` runs, then it reports at least one failure. Red
  before this ticket: that suite reports `0 failed` under the same mutation.
- [ ] AC8 — Given `references/CONCURRENCY.md:82` and
  `docs/decisions/001-one-command-per-stage-boundary.md:220`, when each is read against the shipped
  `next`, then each claim is true of the code and names the classes the report covers. Red-making
  input: today's text, whose claims the mutation in the Problem section falsifies.
- [ ] AC9 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`, and `tests/backlog-scripts-installed.test.sh` is among them. Red-making change:
  editing `skills/queue/templates/next` and not `.claude/backlog/next`.

## QA plan

- **Why this level:** `next` is a shell script with an existing suite, and every requirement here is
  an ordinary case in `tests/next.test.sh` over a scaffolded fixture backlog.
- **Specific checks:**
  - Run `tests/next.test.sh`, `tests/handoff.test.sh` and
    `tests/backlog-scripts-installed.test.sh` individually first, then the whole suite
    file-by-file with `|| true` per `config.yml`'s note, so another window's red does not mask these.
  - **Drive AC7 rather than reading it**: apply the `mv` mutation to a copy of `handoff` in the
    fixture, `diff` to confirm it landed, run `tests/handoff.test.sh`, restore. This is the one check
    that proves the inert guard became live, and it is the check `0081`'s AC4 could not make.
  - Mutate each new branch away one at a time, confirming the mutation landed before reading the
    result, with a no-op control run before and after the sweep.
  - AC4 needs a fixture with an open-then-closed `blocked_by` **and** a status disagreement in the
    same row; assert on the line count for that id, not merely on its presence.

## Out of scope

- **`claim`, `close` and `handoff`'s own contracts.** The four gaps `0081` and `0082` left in them
  are `0090`, and `handoff` itself is correct — `0081`'s verify pass established that its five fields
  and both cells move atomically. This ticket changes only what the *reader* can see.
- **Reconciling the drift it finds.** `--drift` reports and never writes (`next:472`), and
  reconciling belongs to whatever closed the blocker (`CONCURRENCY.md`, *A stage writes only the
  ticket it holds*).
- **The unresolvable-path class in `expects:` and `touches:`.** That is `0096` FR1–FR2, landing in
  the same mode and the same loop. Either order works; whoever is second edits a block the first
  moved, which `./next`'s own `expects:` collision check is there to hold apart.
- **Whether a tokenless `in-progress` row should be *honoured* by other readers.** `0029` settled
  that (*held* is `claimed_by:` alone) and `0049` holds the open half. This ticket only makes the
  report `0029` promised exist.

## Notes & decisions

- **Routed to `develop`, not `design`.** No surface, and nothing is undecided: the drift vocabulary
  is already settled in `CONCURRENCY.md`, the classes come from two recorded incidents, and every
  helper the check needs is already in `next` — `fm`, `field`, `row_for`, `item_for` (`next:215`,
  `226`, `410`). Unfamiliar is not undecided.
- **Exiting non-zero on the new classes will stop a driver run, and that is intended.**
  `orchestrate` spends `1` on drift and stops (`skills/orchestrate/SKILL.md:117`). A queue whose rows
  and items disagree is exactly the state a driver must not work through — the `0084` symptom pair is
  a row invisible to one stage and blocking another. No new decision, and no exit code changes.
- **`relates:` not `blocked_by:` against `0096`.** Both edit `--drift`'s loop, neither needs the
  other, and both are `ready` and unclaimed, so the file-scope collision check in `./next` is the
  right instrument rather than a graph edge — unlike `0090`, which took `blocked_by: 0082` because
  `0082` was mid-flight in `verify` at the time.
- **Filed from `0081`'s verify verdict of 2026-09-08 `[9840]`**, which found the gap by mutation,
  declined to pass or fail AC4 on it, and correctly did not widen its own scope into `next`.
  `0081` AC4 and FR5 are now the recorded observation that this ticket is the fix.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **reproduced directly, and the provenance is
  older than it looks.** Driven on the exact shape the sentence describes, `./next --drift` prints
  `no drift` and exits 0. `--drift` is a Status-column-vs-`blocked_by` cache check (`next:88`,
  `next:467-493`) and reads neither `claimed_by:` nor the item's `next:`. The `0084` incident this
  repo already recorded — row `develop | in-progress` over item `next: verify, status: ready`,
  `claimed_by:` empty — reproduces with `--drift` silent while `./next verify` declines to offer the
  row and `./next develop` reports its files held under `[no token]`. The sentence is pre-existing:
  written 2026-08-24 at `953ce51` (`0029`), long before `0081` touched the file, which is also why
  `0081` AC4 was unverifiable and went to `queue`. **The two halves may be one fix or two** — correct
  the sentence, or give `--drift` the row/item agreement check the sentence promises — and this row
  should say which before it is built.
