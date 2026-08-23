---
id: "0012"
title: Every session ends by parking what surprised it
type: chore
status: ready
qa_level: verify
size: s
created: 2026-08-23
parent: "0009"
blocked_by: []
relates: []
touches:
---

## Problem

`retro` currently reviews "the session around" an item. Once each skill runs in its own session
there is no such session to review, and retro's input is whatever happens to be on disk.

Measured on 2026-08-22: of four findings a retro produced, **two existed only in conversation**
and would have been lost. Both survivors were durable because something wrote them at the moment
of noticing. Both casualties — `RANKING.md` ships no template, an empty QA level exits non-zero —
were tooling gaps spotted while using the tooling, which is exactly the class retro exists to
catch and exactly the class nothing currently forces anyone to record.

Parking is already possible and already under-used: one entry was parked against four findings.
An optional habit at the end of a long session is not a mechanism.

## Functional requirements

- FR1 — Every skill gains a closing step: before reporting, write anything that surprised you to
  `FINDINGS.md` as one dated line.
- FR2 — The step names its triggers rather than leaving it to judgement — at minimum: a template
  or skill step that had no correct answer for your case; a configured command that behaved
  unexpectedly; a scaffolding step you had to invent.
- FR3 — The step states that an explicit "nothing surprised me" is a complete result, so the
  habit does not manufacture findings to justify itself.
- FR4 — `FINDINGS.md` is committed in the same turn it is written, by pathspec.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | This is the discovery-time recording `documentation-conventions.md` already requires; the skills cite it rather than restating why. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given each of the five `SKILL.md` files, when read, then each has a closing step that
      names `FINDINGS.md` and at least one concrete trigger.
- [ ] AC2 — Given those files, when read, then each states that finding nothing is a complete
      result.
- [ ] AC3 — Given the closing step, when read, then it says to commit `FINDINGS.md` in the same
      turn, by pathspec.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:**
  `for f in skills/*/SKILL.md; do grep -q 'FINDINGS.md' "$f" || exit 1; done`, plus a grep for the
  same-turn commit instruction in each. The assertion checks all five rather than sampling,
  because a rule that covers four of five callers is the case
  `coding-conventions.md` warns is worse than none.

## Out of scope

- What retro then does with the buffer — 0016.
- Queue's sweep of it for units of work — 0014.

## Notes & decisions

- This is the ticket that makes isolation safe rather than lossy, which is why it is unblocked
  and near the top: it is useful on its own, before any invocation is removed.
- In the measured run `FINDINGS.md` was written at Step 1 and left uncommitted until close —
  one `git stash` from gone, which is the hazard `CONCURRENCY.md` already documents for claims.
  FR4 exists for that, not for tidiness.
