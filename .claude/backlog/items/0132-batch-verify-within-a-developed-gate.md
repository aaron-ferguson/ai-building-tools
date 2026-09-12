---
id: "0132"
title: Let verify batch within a gate that was developed together, with per-ticket evidence
type: feature
next: develop
status: in-progress
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: ["0059"]
relates: ["0131", "0054"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - skills/verify/SKILL.md
  - skills/orchestrate/SKILL.md
  - .claude/backlog/config.yml
  - tests/next.test.sh
claimed_by: "0a54"
claimed_at: 2026-09-12T14:41:10Z
touches:
  - .claude/backlog/next
  - skills/queue/templates/next
  - skills/verify/SKILL.md
  - skills/orchestrate/SKILL.md
  - .claude/backlog/config.yml
  - tests/next.test.sh
---

## Problem

**The tool and the cost model disagree about whether verify batches, and neither is documented as
the answer.** `--drive` dispatches one ticket at a time — `decide "$DISPATCH" "DISPATCH verify
$id"` — while `config.yml` carries `stage_budget_usd.per_extra_ticket.verify: 3.63`, a figure that
only means anything if a verify session can hold more than one ticket. The skill's prose sides with
the tool: *"A ticket left at `next: verify, status: ready` gets a **new** process running `verify`
on it."*

**On a thirteen-ticket gate that difference is thirteen session floors.** A stage pays roughly 20k
tokens before it writes a line, and the whole justification for gating develop is that those
tickets share it. The tickets that shared a develop session share exactly the same files at verify —
they were grouped on `expects:` overlap in the first place — so the re-read is the same re-read.
Aaron, 2026-09-08: *"Verify should batch when it is token-efficient to do so."*

**But verify's independence is the property being spent, and this project's priority order is
quality first.** Two risks, both concrete:

- **Halo.** Several verdicts in one context, where the first is green, is how the second gets read as
  green. The two recorded times the independent gate bit in this repo, it bit on AC quality rather
  than on code — exactly the judgement a shared context erodes.
- **Misattributed red.** `config.yml`'s own note records this happening: verifying `0084`, the
  fail-fast `unit` command stopped at `backlog-scripts-installed.test.sh` — alphabetically first of
  seventeen — which was red from *another session's* in-flight work, so `tests/release.test.sh`, the
  guard that verdict actually rested on, never ran. Sixteen were green. A batched verify multiplies
  the number of tickets one such red can wrongly condemn.

`0059` is the design question that governs this — it asks what the batching rule's condition is, and
separately *"what isolates one ticket's Step 3 mutation from another ticket's suite run inside the
same session?"* That is the same mutation-isolation problem, and this ticket cannot be specified
around it.

## Functional requirements

Written against whatever `0059` settles; these hold regardless of which shape it picks.

- FR1 — A verify session may hold more than one ticket only where those tickets were **developed
  together in one gate**. Tickets that merely happen to sit at `next: verify` are not thereby one
  batch.
- FR2 — The outcome envelope carries one array entry per ticket with its own verdict, as the schema
  already requires; a batched session produces per-ticket verdicts, never one verdict spread over
  several ids.
- FR3 — Each ticket's `## QA evidence` section is written with its own per-AC table. A shared table
  covering the batch does not satisfy this.
- FR4 — A red is attributed to a named ticket before any verdict is written. The suite is run
  file-by-file — `for t in tests/*.test.sh; do "$t" || true; done` — rather than fail-fast, per
  `config.yml`'s recorded reason.
- FR5 — Where a red cannot be attributed to one ticket in the batch, the session reports that rather
  than distributing it, and the affected tickets are left open.
- FR6 — `--drive` selects the batch and states it, so the tool and the rule agree; the shipped
  template `skills/queue/templates/next` receives the same change.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The saving claimed is session floors, and it is measured rather than asserted — `0135`'s ledger records verify cost per ticket batched against the single-ticket baseline | `observability-conventions.md` |
| Documentation | The independence risk and the attribution rule are stated in `skills/verify/SKILL.md` where a verify session reads them, not only here | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given three tickets developed in one gate and left at `next: verify`, when `--drive`
      runs, then it dispatches one verify session naming all three. **Red if** it dispatches one id,
      which is today's behaviour.
- [ ] AC2 — Given three tickets at `next: verify` that were **not** developed together, when
      `--drive` runs, then it dispatches them separately. **Red if** the batch condition is written
      as "any rows at the stage", which FR1 rejects.
- [ ] AC3 — Given a completed batched verify, when each ticket's item file is read, then each holds
      its own `## QA evidence` table naming its own ACs. **Red if** one table names ACs from more
      than one ticket.
- [ ] AC4 — Given a batch in which one ticket's guard is red and the others' are green, when the
      session reports, then the red is attributed to that ticket and the others still receive their
      own verdicts. **Red if** a fail-fast run is used, which stops at the first red and leaves the
      remaining tickets unverified while reading as though the batch failed.
- [ ] AC5 — Given a red that no ticket in the batch owns — another session's in-flight work — when
      the session reports, then it reports the red as unattributed and closes none of them. **Red
      if** it is charged to the alphabetically-first ticket, which is the `0084` failure repeated.
- [ ] AC6 — Given the repo after this ticket, when `diff .claude/backlog/next
      skills/queue/templates/next` runs, then they are identical. **Red if** only this project's
      copy is changed.

## QA plan

- **Why that level:** no runner covers a dispatch rule plus a prose contract, but each criterion is
  mechanical — `--drive` against fixtures for AC1, AC2 and AC6, and a fixture batch with a planted
  red for AC4 and AC5.
- **Specific checks:** `tests/next.test.sh` for the selection; a fixture with one deliberately red
  guard for the attribution cases; `tests/sprint.test.sh` for FR3's statement in the verify skill.

## Out of scope

- Deciding the batching rule's condition, or how one ticket's mutation is isolated from another's
  suite run. Both are `0059`.
- Changing how develop gates are formed.
- Worktree-per-ticket isolation, which `0059` may propose and `0137` would carry.

## Notes & decisions

- **2026-09-09 — blocked on `0059` after reading it rather than assuming.** The interaction was first
  recorded here as merely related; `0059`'s open question turns out to name both halves of this
  ticket — the batch condition and the mutation isolation — so specifying this one first would have
  pre-empted a decision that is explicitly still open.
