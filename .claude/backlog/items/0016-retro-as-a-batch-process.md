---
id: "0016"
title: Make retro a batch process over many sessions
type: chore
status: blocked
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: ["0012", "0015"]
relates: []
touches:
---

## Problem

Retro reviews "the session around" a closed item. In its own session there is no such session,
so as written it would run on nothing and report nothing — the appearance of learning with none
of it.

The measured run also shows it is the wrong shape even today. Retro cost **$5.50**, 36% of the
run, at the lowest output per turn of any phase (597), because it runs last where context is
largest. Running it after every ticket in its own session would mostly find nothing, and the
cheapest nothing is the one not run.

## Functional requirements

- FR1 — Retro's scope becomes the parked findings of many sessions, not one session's memory.
  The "check of the session for anything that never got parked" pass is removed, because there
  is no session to check.
- FR2 — Retro runs on a cadence — when `FINDINGS.md` crosses a threshold, or on a schedule —
  and the skill states which. It is not part of the per-ticket lifecycle and is not a `next`
  value.
- FR3 — Its job narrows to what needs the cross-session view: recognising that several sessions
  hit the same thing, choosing destinations, and making the edits.
- FR4 — Retro takes the lesson entries from `FINDINGS.md` and leaves the units of work for queue,
  removing only what it processed and committing in the same turn.
- FR5 — The approval gate is presented before the destination-checking work, not after, so a
  rejected finding costs nothing to have proposed.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The cadence is stated in the skill, not left to whoever remembers. An undocumented cadence is no cadence. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/retro/SKILL.md`, when read, then it describes its input as the findings
      buffer across sessions and contains no instruction to review the current session.
- [ ] AC2 — Given that file, when read, then it names a cadence.
- [ ] AC3 — Given that file, when read, then the approval gate precedes the destination-checking
      step.
- [ ] AC4 — Given that file, when read, then it states that retro is not a lifecycle stage and
      not a `next` value.
- [ ] AC5 — Given that file, when read, then it still states that finding nothing is a complete
      result and that manufacturing a finding is worse than skipping.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -n 'the session around\|check of the session' skills/retro/SKILL.md`
  returns nothing; `grep -n 'allowed to find nothing' skills/retro/SKILL.md` returns a line.
  AC3 is checked by comparing line numbers of the gate and the Step 2 heading, so a reordering
  that only moves the words fails.

## Out of scope

- The parking discipline that fills the buffer — 0012.
- Queue's half of the sweep — 0014.

## Notes & decisions

- **Kill criterion for FR5.** Retro's measured $5.50 was inflated by cache expiry during two
  approval waits at maximum context — 247k of the run's 396k cache-write tokens sit in that one
  phase. If an isolated batch retro measures under $1.50, FR5 buys nothing; drop it and say so
  rather than implementing it because it was written down.
- The system learns *more* under this shape, not less. Today a lesson survives only if a retro
  happens to run after the session that noticed it. With 0012 in place every session contributes
  whether a retro ever runs or not.
