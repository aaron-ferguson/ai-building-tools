---
id: "0074"
title: Decide what a stage session tells the human as it runs, and cut the rest
type: debt
next: design
status: in-progress
qa_level: verify
size: m
created: 2026-08-30
source: user
parent:
blocked_by: []
relates: ["0009", "0036", "0039", "0073"]
expects:
  - skills/develop/SKILL.md      # Step 8, and the per-step reporting asides
  - skills/verify/SKILL.md       # Step 7 and the evidence table
  - skills/queue/SKILL.md        # Step 8
  - skills/retro/SKILL.md
  - skills/design/SKILL.md
  - skills/prototype/SKILL.md
  - references/                  # if the shared rule earns a file rather than a repeated paragraph
  - tests/skill-size.test.sh
claimed_by: "5ac2"
claimed_at: 2026-08-30T16:01:51Z
touches:
---

## Problem

**A stage session narrates continuously, and inside a 39-turn session every sentence it writes is
paid for again on every turn that follows it.** Aaron's request, verbatim, 2026-08-30:

> In addition to taking a lot of turns per session, another piece that I assume would make a big
> difference is that right now the agents are fairly verbose and give a lot of updates instead of
> giving critical updates only. Being willing to go into additional context when requested, we could
> save a lot of tokens by simply consolidating and summarizing agent work.

**The direct cost is small and the compounding cost is the one that matters.** `MEASUREMENT.md`
puts output at **22.5% of spend**, so halving what a session says saves single digits of percent
directly. But an assistant turn does not leave the conversation: it becomes context, and
`MEASUREMENT.md` names that as the residual — *"context still climbs inside each one."* A 500-token
narration written at turn 5 of a develop session is re-read on the 34 turns after it, at the
cache-read rate. That is the half nobody has sized, and it is why this ticket must not be specified
from the 22.5% figure alone.

**Nothing in the suite covers this surface today.** `0036`'s FR13 trims what a stage returns **to a
supervisor**, enforced by `--json-schema` — a machine consumer, and only in an orchestrated run.
What a stage tells a **human in its own terminal, turn by turn**, has no rule at all: each skill's
closing step says what to report and nothing governs the running commentary between tool calls.

**The boundary this ticket must not cross is already fixed and was fixed for a reason.** `0036`'s
cross-cutting commitments: *"No rule is dropped anywhere in this project… the trim is to a stage's
closing narrative, never to a check, a test or a standard."* Aaron's framing agrees — *"I don't
want to neuter the power of these tools"*. A trim that quietly removes a step's output removes the
step, because a step with no visible output is the kind this project has already recorded getting
dropped: parking a finding, running the full suite, releasing a claim.

## Open design question

- **Question:** What must a stage session put on the human's screen while it runs, and what becomes
  available only when the human asks for it?
- **Why it blocks specification:** no acceptance criterion about any skill's reporting can be
  written until that default set is fixed, and the failure mode of guessing is not a worse report —
  it is a cut check. Two sub-questions have to be settled with it: **(a)** whether a skill file can
  constrain a session's *per-turn* commentary at all, or only its *step-level* reports, since the
  former is model behaviour and the latter is an instruction the file owns; and **(b)** what "on
  request" means concretely — a phrase the user types, a flag, or a standing default the user sets
  once — because a detail path nobody can find is a deletion.
- **Settle it with:** `/design`

## Functional requirements

Partial by design — the requirements below hold whatever the answer is, and `design` adds the ones
that depend on it.

- FR1 — The reporting rule is stated **in exactly one place** and cited by every stage skill, never
  restated in each. Six copies of a paragraph is six things to drift.
- FR2 — The rule names the **expansion path**: what the human does to get the detail, and what the
  session then produces. A default with no way back is a deletion, not a summary.
- FR3 — **No check, test, standard, or durable write is removed or weakened.** What shrinks is what
  reaches the screen; what reaches disk — a ticket's *Notes & decisions*, `FINDINGS.md`, the item
  file, the commit — is unchanged or larger. Inherited unchanged from `0036`'s cross-cutting
  commitments.
- FR4 — The terse human report and `0036` FR13's machine outcome **do not state different facts**
  about the same run. One of them being shorter is fine; them disagreeing is not.
- FR5 — Whatever the rule turns out to be, it is **enforced by something that fails** — a guard in
  `tests/`, in the manner every other rule in this repo is held — and not only by prose describing
  itself. A rule about what a skill says, verified only by reading the skill that says it, verifies
  its own documentation.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The decision, what it rejected, and the boundary in FR3 are recorded in *Notes & decisions* when settled, not at the end. The rule itself pays context rent on every session of every project, so it is written once and short. | `documentation-conventions.md` |
| Observability | A session that reports less must not become a session whose failures are less visible. Whatever the default set is, it includes what went wrong and what was skipped. | `observability-conventions.md` |

## Acceptance criteria

Written by `design` once the open question is settled — the default set is what every criterion here
would have to name, and inventing it is what this ticket exists to avoid.

- [ ] AC1 — Given the six stage skills, when read, then each cites the reporting rule and none
      restates it.
- [ ] AC2 — Given the suite in `tests/`, when run, then a guard fails if a stage skill states a
      reporting rule of its own instead of citing the shared one.
- [ ] AC3 — Given the shared rule, when read, then it names the expansion path in FR2 concretely
      enough that a cold session could follow it without asking.

## QA plan

- **Level:** verify — the change is prose in skill files and a guard over it; no runner applies.
- **Why this level:** matches every other skill-file ticket in this backlog.
- **Specific checks:** named by `design` alongside the acceptance criteria it adds. FR5 requires at
  least one scripted assertion, and per this repo's `CLAUDE.md` any phrase it greps for must sit on
  one line so a rewrap cannot red it.

## Out of scope

- **Changing `0036` FR13's outcome schema.** `0039` owns it; FR4 here only requires consistency
  with it.
- **Reducing what a stage writes to disk.** The opposite: FR3 requires the detail to land durably.
- **Cutting the turn count.** That is `0073`'s follow-up. Fewer turns and shorter turns are two
  levers and conflating them means neither gets measured.
- **Relaxing any standard, or removing any step.** `0009`'s commitment, inherited: effectiveness is
  not traded for cost.

## Notes & decisions

- **Routed to `design`, and deliberately not blocked on `0073`.** `0073` sizes the compounding half
  and would sharpen the target, but the design question — what a human needs to stay in the loop —
  is answerable without it, and `0073` sits behind two tickets. Blocking this on that would leave
  the top of the efficiency work with nothing takeable. `design` should read `0073`'s figures if
  they exist by then and say so if they do not.
