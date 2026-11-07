---
id: "0226"
title: Decide whether --drive steps over an out-of-scope waiting or queue row, and which exit wins
type: bug
next: design
status: ready
qa_level: unit
size: m
created: 2026-11-06
source: agent
parent:
blocked_by: []
relates: ["0204"]
expects:
  - skills/queue/templates/next
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

`./next --drive` halts on a row ranked above the confirmed scope even when the person has excluded it
from `--scope`, and the halt hides the findings gate.

1. **`waiting`** (AetherWorks, sprint run-20261101T172121Z): after design 0027 left it `waiting` on the
   author, `--drive` exited 4 with
   `ESCALATE  0027 is waiting on a person and outranks everything below it`, with 0027 in `--scope`
   and with it dropped. The person's answer "continue with 0020 and 0021" could only be carried out by
   the supervisor dispatching off-`--drive`.
2. **`next: queue`** (tools repo, sprint run-20261027T185815Z): a `next: queue` row (0089) ranked above
   scope did the same — exit 4 with 0089 in `--scope` or dropped — while an out-of-scope *design* row
   is already stepped over with a NOTE.
3. **Exit precedence:** after the scope finished in the AetherWorks run, `--drive` still exited 4 rather
   than 5 though the findings gate had crossed (12 entries against 8), so the retro-then-queue tail was
   never routed by `--drive` either.

The walk's comment (`skills/queue/templates/next`, the `--drive` rank walk) says only `blocked` and
`in-progress` are stepped over and "everything else dispatches or stops" — so stopping on `waiting` is
deliberate when the row is *in* scope. What is undecided is what an explicit `--scope` that excludes
the row means.

## Open design question

Does an explicit `--scope` that omits a `waiting` or `next: queue` row mean "the person has answered;
step over it with a NOTE", as for an out-of-scope design row — and when the only escalation lies
outside scope, does exit 5 (findings gate) win over exit 4?

## Functional requirements

- FR1 — `--drive` with `--scope` that omits a `waiting` or `next: queue` row either steps over it with
  a NOTE naming the row, or refuses with a message saying what the person must do — per the decision.
- FR2 — When every escalation `--drive` would raise lies outside `--scope` and the findings gate has
  crossed, the exit code is the one the decision names, and the sprint skill's Step 6 says so.
- FR3 — The behaviour is implemented in `skills/queue/templates/next`, not only described in
  `skills/sprint/SKILL.md`.

## Acceptance criteria

- [ ] AC1 — Given a `waiting` row ranked above a `develop ready` row, with `--scope` naming only the
      latter, `--drive` behaves as FR1's decision says. *Red when:* it exits 4 naming the out-of-scope row
      under a decision to step over.
- [ ] AC2 — Same as AC1 for a `next: queue` row.
- [ ] AC3 — Given scope exhausted, an out-of-scope `waiting` row above it, and the findings count at or
      over `findings_threshold`, the exit code is the decided one. *Red when:* exit 4 under a decision
      that 5 wins.

## QA plan

- **Level:** unit
- **Why this level:** `--drive` is a pure read of fixture backlog files; the existing `next` tests build
  such fixtures.
- **Specific checks:** the repo's `unit` command.

## Out of scope

- 0204 (routing a queue completion that re-specifies a waiting row).
- Changing what happens to a `waiting` row that is inside `--scope`.

## Notes & decisions

- 2026-11-06 — Filed by retro (sprint run-20261101T172121Z tail) from two tools-repo findings entries:
  the 2026-10-27 `next: queue` entry (tools working on themselves, unconfirmed alone) and its
  2026-11-07 `waiting` twin observed in AetherWorks, which confirms it. Routed to `design` because the
  walk's comment shows stopping on `waiting` is deliberate in scope; the scope case is a decision.
