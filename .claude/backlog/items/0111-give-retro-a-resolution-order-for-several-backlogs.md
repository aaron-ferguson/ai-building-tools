---
id: "0111"
title: Give retro a resolution order for a workspace holding more than one backlog
type: bug
next: develop
status: in-progress
qa_level: unit
size: m
created: 2026-09-07
source: retro
parent:
blocked_by: []
relates: ["0060", "0078", "0101"]
expects:
  - skills/retro/SKILL.md
  - references/CONVENTIONS.md
  - tests/retro-tool-edit.test.sh
claimed_by: "cd92"
claimed_at: 2026-09-09T14:47:48Z
touches:
  - skills/retro/SKILL.md
  - references/CONVENTIONS.md
  - tests/retro-tool-edit.test.sh
---

## Problem

**`retro` Step 1 names its input as a bare relative path and a singular, and says nothing about
what that path resolves against or what happens when it resolves to nothing.** The opening
sentence is *"`.claude/backlog/FINDINGS.md` is the input, and the only one"*.

**Measured 2026-09-07.** `/retro` was invoked from `/Users/<name>/Documents/AI`, which is
not a git repository and holds no backlog, with four beneath it: `ai-building-tools` (22 entries,
2.75x this project's `findings_threshold: 8`), `ai-building-conventions` (3), `neumo_repos/Probation`
(4, all invalidated by that backlog's retirement on 2026-09-04) and `tools/jury-config` (0). The
pass swept all four, selecting them on freshness and threshold. **That was defensible and it was
invention** — no step licensed it, and a retro standing in the same place tomorrow has nothing to
reproduce the choice from, so the next pass either re-derives it or picks differently.

**The shape this lacks already exists one file away.** `references/CONVENTIONS.md` resolves the
conventions directory by a numbered ladder and **stops rather than guessing** when nothing
resolves. Step 1 has neither the ladder nor the refusal, and it is the same class of question:
*which instance of a per-project file does this session act on.*

The invocation directory being a workspace root rather than a project root is not exotic here — it
is where this user starts sessions, and it is where `queue` landed too on the same day.

## Functional requirements

- FR1 — Step 1 states where `.claude/backlog/FINDINGS.md` resolves from, as a numbered order rather
  than a bare relative path.
- FR2 — The order covers the invocation directory being neither a repo nor a backlog root, which is
  the case that produced this and the one a bare relative path silently fails on.
- FR3 — Nothing resolving stops the session with a report naming what was searched — the same
  refusal `CONVENTIONS.md` already makes, **cited rather than restated**, so the two cannot drift.
- FR4 — A retired backlog is not swept as though it were live. Step 1 checks the **resolved**
  backlog's own `QUEUE.md` for a retirement banner before reading its buffer and stops if it finds
  one. It states that it does **not** detect retirement in any other backlog, and why that is
  acceptable: under FR5 it never reaches one.
- FR5 — **Exactly one buffer is resolved, and it is resolved upward, never discovered.** The order
  walks from the working directory to the repo root and stops; it never descends, so a sibling
  project's buffer is unreachable by construction rather than by a rule someone has to remember.
  Step 1 states that buffers are not found by searching the filesystem — the prohibition
  `CONVENTIONS.md` rung 3 already carries, cited.
- FR6 — A **second** buffer is read only when another rule names it, never because it was nearby.
  The one such rule is `0078` FR5 — a retro running in a consuming project also reads the tool
  repo's buffer, that repo being *resolved* per `0078` FR2 and not discovered. Step 1 says the
  second buffer comes from a naming rule so that a later reader cannot mistake FR5's single
  resolution for a ban on `0078`.
- FR7 — The privacy clause sits at the order itself, not in a distant section, and states that
  **a backlog carrying no `routing:` block is treated as company-tracked, not as `company: none`**.
  Measured 2026-09-08: two of the four backlogs under this workspace carry no `routing:` block at
  all, so absence is the common case and reading it as "no company" fails open on exactly the
  backlogs the clause exists to catch.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The order must not license carrying a finding from a company-tracked project into this repo, which is public. `Probation` routes to Jira under company policy and `ai-building-tools` is public; a rule that sweeps both in one pass is one step from writing one into the other. Say so where the order is stated, and treat an absent `routing:` block as company-tracked — unknown classification resolves to the stricter handling, never the looser. | `data-privacy-conventions.md` |
| Documentation | `CONVENTIONS.md`'s ladder and refusal are cited, never copied. Two ladders that must agree is the drift this repo has already paid for. | `documentation-conventions.md` |

## Acceptance criteria

Every assertion is anchored to Step 1's window per AC3, never to the file.

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 1, when read, then it states a numbered resolution
  order for locating the buffer. Red when the order is deleted or reduced back to the bare relative
  path.
- [ ] AC2 — Given Step 1, when read, then it states that a session which resolves nothing stops and
  reports what it searched. Red when the refusal sentence is removed — and note the discriminating
  case: a rule saying only *"read the buffer"* satisfies no assertion here while reading as correct.
- [ ] AC3 — Given a guard anchored to Step 1 rather than to the file, when the resolution order is
  moved out of Step 1 into any other step, then the guard reds. This is the house rule in
  `tests/retro-tool-edit.test.sh` — a file-wide grep stays green on a rule moved out of the step
  that has to obey it.
- [ ] AC4 — Given the privacy clause under NFR *Privacy & data*, when it is deleted, then a guard
  reds on its own, separately from AC1's. The clause carries FR7's absent-`routing:` rule, so one
  guard covers both rather than two guards covering one sentence.
- [ ] AC5 — Given Step 1, when read, then it states that the order resolves **upward only** and that
  buffers are not discovered by searching the filesystem. Red when either half is removed. This is
  the assertion that would have failed the 2026-09-07 pass, and the one AC1 does not make: a
  numbered order can be present and still be a discovery.
- [ ] AC6 — Given Step 1, when read, then it states the retirement check on the resolved backlog's
  own `QUEUE.md`. Red when the check is deleted.
- [ ] AC7 — Given Step 1, when read, then it states that a second buffer is read only when a rule
  names it. Red when deleted — without it, FR5 reads as forbidding `0078` FR5 and the two land in
  conflict.

## QA plan

- **Why that level:** the deliverable is prose in one skill, and every guard in this repo greps
  prose; `unit` runs `tests/*.test.sh`, which is the only runner here.
- **Specific checks:** extend `tests/retro-tool-edit.test.sh`, whose cases are already section-scoped
  to `retro`'s steps and whose header states the anchoring rule AC3 depends on. One assertion per AC,
  each anchored to Step 1's window. Prove each can fail by deleting the sentence it matches and
  reverting. **Match a phrase short enough to sit on one source line** — `grep` is line-based and
  this file is wrapped prose.

## Out of scope

- **What the findings gate counts when a workspace holds several buffers.** `findings_threshold` is
  per-project, so four buffers at 6 entries each never trip a gate while the workspace holds 24
  unswept findings. That is a real defect and it belongs to **0060**, which owns the decision about
  what the gate counts; this sweep recorded it in 0060's open design question rather than here.
- **Routing a finding to the repo it is about** — 0078. That decides where a finding is *written*;
  this decides which buffers a retro *reads*. They meet at 0078's FR5 and neither subsumes the other.
- Changing `CONVENTIONS.md`'s own ladder.

## Decision — 2026-09-08, `/design`

**One buffer, resolved upward from where the session stands; a second only when another rule names
it. Not a discovery, and never a workspace sweep.**

Rejected, and why:

- **Sweep every backlog in reach (what the 2026-09-07 pass did).** It makes `cd` a scope control
  that nothing records, and it is the thing `CONVENTIONS.md` rung 3 already forbids one file away:
  *do not search the filesystem for a directory that looks right*. It also multiplies machinery that
  has no workspace form — `findings_threshold`, `conventions.path`, `next_id`, `routing`, the
  claim/close scripts and `tools/release` are all per-backlog, and the three reachable
  `conventions.path` values here are `../`, `../../` and an absolute path.
- **Exactly one, full stop.** Contradicts `0078` FR5, which is already at `next: develop` and has a
  retro reading the tool repo's buffer as well as the local one. The distinction that saves both is
  *resolved or named* versus *found nearby*, so that is the line the rule draws.

**The trade-off accepted:** a workspace with four filling buffers needs four invocations, and
nothing tells you the other three are full. That is real and it is deliberately not fixed here —
the cheap fix buys workspace visibility with a privacy boundary and an unbounded scope. Cross-buffer
visibility is a **report**, not a sweep, and it belongs to **0060**, which owns what the gate counts
across buffers. 0060's open design question already anticipates this and is unblocked by it.

**Why privacy decided it rather than tie-broke it.** Under a sweep, one session holds Neumo
Probation's buffer and this public repo's in the same context and commits into the public one in the
same pass. `data-privacy-conventions.md`'s *highest classification sets the bar for the record*
would make the public repo's retro run under Neumo handling rules, which is backwards and
unenforceable. Resolving upward makes a sibling buffer unreachable by construction — the boundary
stops depending on a rule anyone can forget.

**Evidence re-verified 2026-09-08** (the ticket's figures were 2026-09-07 and the counts have since
moved, which is expected — that day's retro swept three of them):

- Four backlogs under `Documents/AI`, buffers now 20 / 0 / 0 / 0 against the earlier 22 / 3 / 4 / 0.
- The workspace root is still not a git repository and holds no backlog, so it falls to rung 3 and
  stops. That is the measured failure, fixed.
- All four backlogs sit at their own git repo root — `probation-starter`, not `Probation`, is the
  repo — so rung 1 resolves every real case here and rung 2 exists for a nested backlog, not for
  these.
- `Probation`'s retirement carries two signals, `QUEUE.md`'s `**RETIRED 2026-09-04**` banner and
  `tracker.status: superseded-by-jira`; neither is universal, and `jury-config` has neither a
  `tracker:` nor a `routing:` block. **That is why FR4 checks the resolved backlog only** — detecting
  retirement across arbitrary backlogs fails open on signals a backlog is not obliged to carry.
- **New, and not in the ticket:** two of the four carry no `routing:` block at all. FR7 and the
  privacy NFR now say absence means company-tracked.

**What this changed in the ticket, per `/design` Step 4's validate-and-extend path.** Confirmed
FR1–FR3 and AC1–AC3 unchanged. Changed FR4 from *say how a session tells, or say that it does not*
to a positive rule, and AC4 to carry FR7's clause rather than gaining a guard of its own. Added FR5,
FR6, FR7 and AC5, AC6, AC7. AC5 is the one the whole decision rests on: AC1 alone stays green on a
numbered order that is still a discovery.

## Notes & decisions

- **Routed to `design`, not `develop`.** The FR-level shape is clear and the precedent file is
  named, but the one thing every AC turns on — one buffer or all — is a decision, not a fact
  discoverable by reading the code. Guessing it is how a ticket gets built to a contract nobody
  agreed to.
- **No sibling FR naming implementing code, deliberately.** Step 1 is executed by the agent reading
  it; nothing in `./next` or the backlog scripts discovers buffers, so there is no code that
  implements this rule and the guard is the only executable artefact. Saying so here so a reviewer
  applying `queue`'s *an FR describing a rule needs an FR naming what executes it* does not read the
  absence as an oversight.
- Captured from `FINDINGS.md` 2026-09-07, parked by the retro pass that hit it.
