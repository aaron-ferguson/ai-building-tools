---
id: "0131"
title: Dispatch no new develop gate while a started ticket is still awaiting verify
type: feature
next: verify
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
  - tests/orchestrate.test.sh   # AC11's guard, added by design 2026-09-10
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
  routing rules of its own. It also states how the driver composes FR5's input from its run log.
- FR5 — The rule is scoped to rows the run **started**, and the run says which by naming them: the
  set is an input (FR6), never derived from `parent:` or `expects:`. A ticket left at `next: verify`
  by a hand-driven session before the sprint began is not the sprint's to hold, and jumping the rank
  for it would let unrelated stale work reorder every run.
- FR6 — `--drive` accepts `--started <id>`, repeatable and optional, each value a four-digit id.
  Its values are the tickets the run has dispatched work on, **cumulative over the whole run** and
  not just the last call — the gate whose non-lead ticket goes unverified is two calls old by the
  time the rank walk would step over it. `--completed`'s id, where it carries one, is unioned into
  that set, so a run whose gates are all single tickets needs no `--started` at all.
- FR7 — `--started` handles an id with no row without stopping the run: a started ticket that
  closed, or that became a project, has legitimately left `QUEUE.md`. An id with **neither** a row
  nor an item file prints a `NOTE` naming it and the run continues — that one is a driver bug, and
  a rule that silently stops applying is the failure mode `references/CONVENTIONS.md` names in the
  fail-open ladder. A value that is not four digits is a usage error, exit 2.
- FR8 — `--completed` stays singular and its guard stays. The comment deferring the widening to
  `0039` is stale — `0039` closed 2026-09-08 without needing it — and is replaced by a pointer to
  `--started` and the reason the two are different inputs.
- FR9 — The preference applies where a **new gate** would be formed, alongside `findings_gate` and
  ahead of it. So it does not preempt an escalation that outranks it — a `waiting`, `design` or
  `queue` row above the develop row still stops the run — and it does not change what happens when
  a `verify` row already outranks the develop row.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reason lives beside the code, as `findings_gate`'s already does; a rule whose reason is only in a ticket is a rule the next reader deletes | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog whose rank order is `0103 | develop | ready` then
      `0102 | verify | ready`, when `./next --drive --started 0102` runs, then it dispatches
      `verify 0102`. **Red if** it dispatches `develop 0103` — the behaviour observed on this
      fixture on 2026-09-09, and what this ticket changes.
- [ ] AC2 — Given the same fixture, when `./next --drive` runs with no `--started`, then it
      dispatches `develop 0103`. **Red if** the rule is written without FR5's scoping, which would
      make every stale verify row outrank all new work.
- [ ] AC3 — Given a fixture whose rank order is `0103 | develop | ready`, `0102 | verify | ready`,
      `0104 | verify | ready`, when `./next --drive --started 0104 --started 0102` runs, then it
      dispatches `verify 0102`. **Red if** it dispatches `0104` — the change would have replaced
      rank with the order the ids arrived in.
- [ ] AC4 — Given the repo after this ticket, when `diff .claude/backlog/next
      skills/queue/templates/next` runs, then the files are identical. **Red if** the fix lands in
      one copy only — the drift `queue` Step 0 checks for on every open.
- [ ] AC5 — Given a fixture holding `0103 | develop | ready` and no row for `0102`, but an item file
      for `0102`, when `./next --drive --started 0102` runs, then it dispatches `develop 0103` and
      exits 0. **Red if** a started ticket that has since closed stops the run.
- [ ] AC6 — Given the same fixture with **no** item file for `0102` either, when
      `./next --drive --started 0102` runs, then it dispatches `develop 0103` and prints a line
      naming `0102`. **Red if** an id nothing recognises is swallowed — the rule then stops applying
      with no output that says so.
- [ ] AC7 — Given any fixture, when `./next --drive --started 12` runs, then it exits 2. **Red if**
      a malformed id is accepted, where it matches no row and disables the rule in silence.
- [ ] AC8 — Given a fixture whose rank order is `0105 | design | ready`, `0103 | develop | ready`,
      `0102 | verify | ready`, when `./next --drive --started 0102` runs, then it escalates on
      `0105` and exits 4. **Red if** the preference is applied before the rank walk rather than at
      the gate, which would let a started verify row jump a decision only a person can make.
- [ ] AC9 — Given any fixture, when
      `./next --drive --completed develop:0101 --completed verify:0101` runs, then it exits 2.
      **Red if** the widening was applied to `--completed` instead of adding `--started` — the
      rejected option, whose guard this pins.
- [ ] AC10 — Given `tests/next.test.sh`, when the suite runs, then it holds a case for AC1 and a
      case for AC2, and each fails when the rule is reverted. **Red if** only the positive case is
      guarded: a rule with no negative case passes trivially by dispatching verify always.
- [ ] AC11 — Given `skills/orchestrate/SKILL.md`, when `tests/orchestrate.test.sh` runs, then it
      asserts the file names `--started` and describes it as cumulative over the run. **Red if** the
      skill gains the routing rule itself in prose — a restated rule drifts
      (`references/CONVENTIONS.md`), and `--drive` is the only place it may live.

## QA plan

- **Why that level:** `next` is a shell script with no runner configured in this project, and
  `tests/next.test.sh` is the existing self-contained guard for it.
- **Specific checks:** `tests/next.test.sh` against a purpose-built fixture backlog, not the live
  one — a guard reading the real `QUEUE.md` changes meaning every time a ticket closes, and AC1's
  whole point is a fixture whose rank order is fixed. `tests/orchestrate.test.sh` carries AC11.
  Run the suite file-by-file per `config.yml`'s note on fail-fast attribution.

## Out of scope

- Batching verify across a gate — that is `0132`. An input carrying several *verdicts* from one
  batched verify session is that ticket's, and is a third input, not this one (see the notes).
- Widening `--completed`. Decided against on 2026-09-10 and pinned by AC9.
- Any change to how develop gates are formed.
- Reordering `QUEUE.md`. This changes dispatch preference, never the rank.

## Notes & decisions

- **2026-09-09 — routed to `develop`, not `design`.** The rule was decided with Aaron on
  2026-09-08 and its implementation site is a `case` in a script that already encodes the same
  principle one branch away. Nothing is undecided; FR5's scoping was the only open question and it
  is settled here.
- **2026-09-09 — bounced to `design` by `develop` [9776] before writing code.** FR5 needed an input the CLI does not have, and the two candidate inputs are opposite
  contracts, one of which retires a committed guard. Also recorded: AC1 as first written was green
  already, so the ticket's stated "today's behaviour" was wrong and the fixture that would be red
  is a multi-ticket gate, which the current `--completed` cannot express. No code was written.
  The *Open design question* section that carried this is deleted — it is answered below.
- **2026-09-10 — DECIDED: a new `--started <id>` input, option (b). `--completed` stays singular.**
  Rejected (a), widening `--completed` to a run log, on four grounds. **First, it contradicts its
  own documented reason**: the comment at the guard says the same-stage check needs *an* intervening
  outcome, *not a history*, and a caller who must accumulate every outcome forever to feed a reader
  that consumes one element is the trap that comment names, inverted. **Second, it makes position
  load-bearing** — the last entry routes the escalation ladder, the rest only widen a set — and a
  driver that reorders its run log then changes routing with nothing to catch it. **Third, the two
  facts have different lifetimes**: "what just finished" is per-call and transient, "what this run
  has opened" is cumulative and monotonic; different lifetimes want different inputs. **Fourth, it is the additive change**:
  `api-conventions.md`, *Versioning and Compatibility* — a new optional flag is safe where
  re-meaning an existing one is not — and `next` ships as a template into other
  projects' backlogs, so `--completed` has consumers this repo does not control.
- **2026-09-10 — the consolidation argument for (a) was tested and does not hold.** (a)'s best case
  is that `0132` (batched verify) will need several outcomes per call anyway, so widen once. It
  would not help: `0132` needs *this call's* verdicts routed individually, while FR5 needs *the
  run's* ids as a set, so a single widened `--completed` would have to distinguish the two by
  grouping — two levels of structure in one flag. If `0132` needs an input, it is a third one.
- **2026-09-10 — the rejected third option, deriving the set** from a shared `parent:` or `expects:`
  scope, needs no CLI change and is still wrong: it re-admits exactly what FR5 forbids, a stale
  verify row reordering the run because it happens to name one of the same files.
- **2026-09-10 — trade-off accepted: two inputs the driver must keep in step, and `--started` fails
  open in silence when omitted.** A driver that forgets it gets today's behaviour with no error.
  Two things hold that down and both are requirements above: `--completed`'s id is unioned in
  (FR6), so the single-ticket case is right with no `--started` at all, and an unrecognised id is
  reported rather than swallowed (FR7). Neither makes an omitted flag loud; that residue is the
  cost of the decision.
- **2026-09-10 — re-verified on a throwaway fixture, not carried from the bounce note.** With rank
  order `0103 develop` / `0102 verify ready`, `--completed verify:<a closed id>` dispatches
  `develop 0103` while `0102` sits built and unverified — the defect, reproduced. A two-ticket
  gate is real and its members need not be rank-adjacent: rank `0101(a.md)`, `0103(b.md)`,
  `0102(a.md)` dispatches `develop 0101 0102`. AC1 as previously written is green today, confirmed
  again; `--completed` twice exits 2, confirmed again. The ACs above are rewritten against these.
- **2026-09-10 — the plural fact the run already holds.** `skills/orchestrate/outcome.schema.json`
  is already an envelope over an ARRAY of tickets, and says why: "a develop or verify gate handles
  several tickets in one session: singular, it reports one verdict and silently drops the rest."
  The driver therefore needs no new bookkeeping for FR6 — `--started` is the union of `tickets[].id`
  over the run log it already keeps. That is what makes (b) cheap for the caller.
- **2026-09-10 — built [bea1]. FR6's union of `--completed`'s id is implemented and is not
  observable through behaviour, so no AC guards it.** Every path on which `--completed` names a
  ticket still sitting at `verify | ready` is already taken by the direct
  `develop → verify/ready → DISPATCH verify` branch, which decides and exits before the rank walk
  the preference lives in. The routes that *do* fall through to the walk all leave that ticket
  un-dispatchable for another reason — closed, a project, or blocked. The union is therefore a
  consistency property rather than a behaviour: it is what makes FR6's "a run whose gates are all
  single tickets needs no `--started`" true by construction rather than by coincidence of the two
  branches agreeing. A guard written for it would assert on a state no fixture can reach.
- **2026-09-10 — AC10's two mutations were run and both red, at
  `8fd3141`, the commit that carries them.** Reverting the gate hook (`if false` in place of `if sv="$(started_verify)"`) reds
  AC1 and AC3, 3 of 326; dropping FR5's scoping (deleting the `contains_word` line, so every verify
  row counts as started) reds AC2, 2 of 326. The control run is green at 326.
- **2026-09-10 — the AC11 guard is keyed on `Step 2`, not on `The cycle`.** The harness's
  `section()` matches the heading as a PREFIX, and the subject-only form extracts an empty string —
  which reds a correct file for a presence assertion and, for an absence one, could never fail. See
  the dated entry in `FINDINGS.md`.
