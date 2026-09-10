---
id: "0131"
title: Dispatch no new develop gate while a started ticket is still awaiting verify
type: feature
next: design
status: ready
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0038", "0132"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
  - skills/orchestrate/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`--drive` walks the rank, and the rank does not know a ticket was just built.** Its final loop
takes rows in `QUEUE.md` line order and dispatches the first actionable one:

```
verify)  decide "$DISPATCH" "DISPATCH  verify $id" ;;
develop) gate="$(gate_from "$id" "$(takeable_develop)")" ; findings_gate
         decide "$DISPATCH" "DISPATCH  develop $gate" ;;
```

There is no stage priority — only rank position. So a ticket at `next: verify` sitting at rank 40
loses to a **new** develop gate led by rank 12, and a run can keep opening work while built,
unverified tickets accumulate below it. Aaron, 2026-09-08: *"we should always verify the work that
we've started so that it gets closed."*

**This is the failure mode that survives having no sprint budget.** `0128` deliberately declines a
dollar budget, on the ground that an interrupted sprint resumes from the backlog. That holds — but
it holds *better* the fewer tickets are left half-finished when the interruption lands. A ticket
built and not verified is the one state that costs a second session's startup floor to pick up, and
`develop`'s re-entry guidance has to re-derive whether the diff in the tree is another window's
mid-work.

**The existing `findings_gate` already encodes this principle, in one place only.** Its comment:
*"Checked where a NEW gate would be dispatched, and not before a verify: a ticket already built is
finished rather than abandoned for a retro."* The rule is right and its scope is too narrow — it
protects a built ticket from the findings gate, and not from the next develop gate.

## Functional requirements

- FR1 — `--drive` dispatches `verify` for any row at `next: verify, status: ready` **before** it
  dispatches a new develop gate, regardless of the two rows' rank positions.
- FR2 — The rule is stated where it is executed, in `.claude/backlog/next`, and the same change
  lands in the shipped template `skills/queue/templates/next`. This repo ships that template; a fix
  applied only to this project's copy leaves every other backlog running the old rule
  (`queue` Step 2, and `Step 0`'s one-way flow from template to copy).
- FR3 — Rank still decides **among** verify rows, and among develop gates. The change is a stage
  preference, not a re-ranking.
- FR4 — `sprint` states the rule in its own prose as a property it relies on, citing `--drive` as
  the thing that enforces it, and does not restate the routing rule itself — the skill states no
  routing rules of its own.
- FR5 — The rule is scoped to rows the run **started**. A ticket left at `next: verify` by a
  hand-driven session before the sprint began is not the sprint's to hold, and jumping the rank for
  it would let unrelated stale work reorder every run.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reason lives beside the code, as `findings_gate`'s already does; a rule whose reason is only in a ticket is a rule the next reader deletes | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog holding a row at rank 12 at `next: develop` and a row at rank 40
      at `next: verify, status: ready` which this run built, when `./next --drive --completed
      develop:<id>` runs, then it dispatches `verify` for the rank-40 row. **Red if** it dispatches
      the rank-12 develop gate — which is today's behaviour and what this ticket changes.
- [ ] AC2 — Given the same fixture with the rank-40 verify row **not** built by this run, when
      `--drive` runs, then it dispatches the rank-12 develop gate. **Red if** the rule is written
      without FR5's scoping, which would make every stale verify row outrank all new work.
- [ ] AC3 — Given two rows both at `next: verify, status: ready`, when `--drive` runs, then it
      dispatches the higher-ranked one. **Red if** the change replaces rank with arrival order among
      verify rows.
- [ ] AC4 — Given the repo after this ticket, when `diff .claude/backlog/next
      skills/queue/templates/next` runs, then the files are identical. **Red if** the fix lands in
      one copy only — the drift `queue` Step 0 checks for on every open.
- [ ] AC5 — Given `tests/next.test.sh`, when the suite runs, then it holds a case for AC1 and a case
      for AC2, and each fails when the rule is reverted. **Red if** only the positive case is
      guarded: a rule with no negative case passes trivially by dispatching verify always.

## QA plan

- **Why that level:** `next` is a shell script with no runner configured in this project, and
  `tests/next.test.sh` is the existing self-contained guard for it.
- **Specific checks:** `tests/next.test.sh` against a purpose-built fixture backlog, not the live
  one — a guard reading the real `QUEUE.md` changes meaning every time a ticket closes. Run the
  suite file-by-file per `config.yml`'s note on fail-fast attribution.

## Out of scope

- Batching verify across a gate — that is `0132`.
- Any change to how develop gates are formed.
- Reordering `QUEUE.md`. This changes dispatch preference, never the rank.

## Open design question

**FR5 asks `--drive` to know which verify rows *this run* started, and the CLI carries no input
that says so. Two answers exist, they are opposite products, and one of them contradicts a
committed guard — so `develop` will not pick between them.**

What was established by probing the script on a throwaway fixture (2026-09-09):

- **AC1 as written is already green.** With a rank-1 `next: develop` row and a lower `next: verify,
  status: ready` row, `./next --drive --completed develop:<the verify row>` dispatches
  `verify <id>` today, not the develop gate — the completed-outcome branch
  (`.claude/backlog/next`, `lstage = develop && lnext = verify && lstatus = ready`) fires long
  before the rank walk is reached. AC1's *Red if* clause states the opposite about today's
  behaviour and is mistaken.
- **The real defect is a gate of more than one ticket.** `--drive` dispatches a *gate* — a lead plus
  every takeable develop row sharing its parent or `expects:` scope — to one `develop` session, and
  `--completed` accepts **at most one** `<stage>:<id>`. So after a two-ticket gate, only the lead's
  id comes back; the other built ticket sits at `next: verify, status: ready` and loses the rank
  walk to any higher-ranked develop row. That is the state Aaron's rule is about, and no invocation
  of the current CLI can express it.

The decision, therefore:

- **(a) Widen `--completed` to accept a run log** — several outcomes per call. This is what
  `.claude/backlog/next` itself defers to `0039` in as many words (*"0039 widens it if its run log
  ever needs to pass more"*), and `tests/next.test.sh` currently **guards the opposite**: a second
  `--completed` is asserted to be a usage error. Choosing (a) means retiring that guard.
- **(b) Add a distinct input naming the rows the run has started** — e.g. `--started <id> ...` —
  leaving `--completed` singular and its guard intact.

A third option, **deriving** the set (treat a verify row sharing the completed ticket's parent or
`expects:` scope as run-started), needs no CLI change but re-admits exactly what FR5 forbids: a
stale verify row that happens to share a file scope would reorder the run.

Each answer also decides who else changes — (a) and (b) both put a new obligation on
`skills/orchestrate/SKILL.md`, which today tells the driver to *"give it at most once per call"*.

Nothing else in the ticket is unsettled: FR1-FR4 are buildable as written once the input exists,
and AC1/AC2's fixtures need rewriting against whichever input is chosen.

## Notes & decisions

- **2026-09-09 — routed to `develop`, not `design`.** The rule was decided with Aaron on
  2026-09-08 and its implementation site is a `case` in a script that already encodes the same
  principle one branch away. Nothing is undecided; FR5's scoping was the only open question and it
  is settled here.
- **2026-09-09 — bounced to `design` by `develop` [9776] before writing code.** See *Open design
  question*: FR5 needs an input the CLI does not have, and the two candidate inputs are opposite
  contracts, one of which retires a committed guard. Also recorded there: AC1 is green today, so
  the ticket's stated "today's behaviour" is wrong and the fixture that would be red is a
  multi-ticket gate, which the current `--completed` cannot express. No code was written.
