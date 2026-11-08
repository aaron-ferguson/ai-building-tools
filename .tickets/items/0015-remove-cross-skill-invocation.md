---
id: "0015"
title: Remove cross-skill invocation
type: chore
next: verify
status: done
qa_level: verify
size: s
created: 2026-08-23
closed: 2026-08-23
parent: "0009"
blocked_by: []
relates: []
touches:
---

## Problem

`develop` Step 5 invokes `verify` and Step 7 invokes `retro`. Each invocation pulls another
skill into a context that is already the largest in the run, and re-injects that skill's whole
instruction file. It is the mechanism that makes a single session carry the entire lifecycle,
and it is why the measured run reached an average of 191,752 context tokens per turn.

## Functional requirements

- FR1 — `develop` Step 5 becomes stop-and-report: state that the ticket is built and awaiting QA,
  and name the command a new session runs.
- FR2 — `develop` Step 7 becomes stop-and-report in the same shape.
- FR3 — Both keep every line of reasoning about *why* a separate pass matters. Only the
  invocation goes.
- FR4 — `retro`'s description no longer says it is invoked by `develop` when an item closes.
- FR5 — The phrasing matches `design`'s existing precedent — *"Do not invoke `/prototype` — the
  user does"* — rather than inventing a second convention for the same idea.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reason a separate pass exists survives the deletion. Removing the invocation and its justification together is how the practice quietly stops happening. | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/`, when grepped for `Invoke the .* skill`, then there are no matches.
- [x] AC2 — Given `skills/develop/SKILL.md`, when read, then Steps 5 and 7 each name the command
      a following session runs.
- [x] AC3 — Given `skills/develop/SKILL.md` Step 5, when read, then it still states why
      self-certifying is not acceptable.
- [x] AC4 — Given `skills/retro/SKILL.md`, when grepped for `Invoked by`, then there is no match
      claiming develop invokes it.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -rn 'Invoke the .* skill' skills/ && exit 1 || true`, plus
  `grep -n 'self-certify' skills/develop/SKILL.md` returning a line. The second assertion exists
  because AC1 alone passes if someone deletes the whole step, which is the failure this ticket
  most needs to not cause.

## Out of scope

- Retro's cadence and scope — 0016.
- Documenting the workflow for a reader — 0017.

## Notes & decisions

- Blocked on 0012 and 0013 rather than merely ordered after them. Removing the invocations before
  findings are parked and before verify can close converts a measurable saving into silent
  information loss — the more expensive failure and the harder one to notice.
- **The step numbers in AC2 moved.** 0013 deleted `develop`'s close step, so what the AC calls
  "Steps 5 and 7" are now Steps 5 and 6. Asserted by name (the verify stop, the retro step) rather
  than by number, since a renumber is not a regression and pinning the digit would make every later
  ticket in this project fail this one's assertion.
- **0013 landed FR1 already.** A step that stops at `next: verify` cannot also invoke `verify`, so
  that half went with the ticket that made it true. This ticket owns FR2, FR4, FR5 and the
  tree-wide grep.
- The mutation pass is the reason AC3 exists: deleting Step 6 whole makes AC1 and AC4 pass. Both
  the self-certifying reason and the "none of it is optional" line are asserted separately, so the
  cheap way to satisfy this ticket fails it.
- `README.md` claimed `/develop` hands off to `/retro` by invocation. Corrected at source rather
  than annotated — a stale rule reads as current and gets followed.
