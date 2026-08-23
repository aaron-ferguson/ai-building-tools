---
id: "0017"
title: Document one skill per session, with the measurement
type: chore
next: develop
status: blocked
qa_level: verify
size: s
created: 2026-08-23
parent: "0009"
blocked_by: ["0015"]
relates: []
touches:
---

## Problem

Once the invocations are gone, nothing tells a reader to open a new session per skill. The suite
would still work in one conversation — expensively — and the saving would erode back to nothing
without anyone noticing, because nothing about a long session looks wrong while it is happening.

A workflow rule with no cost behind it also gets dropped under pressure. The measurement is what
makes it stick.

## Functional requirements

- FR1 — The README states the workflow: one skill per session, and the backlog is the handoff.
- FR2 — Each of the five skills states it once, in its header.
- FR3 — The statement carries the measurement: 85% of a measured end-to-end run was context
  handling, average context reached 191,752 tokens per turn, and the modelled isolated cost is
  ~$5.09 against $15.11.
- FR4 — It says **one skill per session, not one ticket per session**, and gives the reason: a
  capture session should batch related tickets, because the expensive part is understanding the
  domain once rather than the writing.
- FR5 — It names what does *not* change: no standard is relaxed, and the rigour that caught the
  defects in the measured run stays.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The figures carry their date and their source, so a later reader can tell a measurement from an assertion. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `README.md`, when read, then it states the one-skill-per-session workflow and
      the batching exception in FR4.
- [ ] AC2 — Given each of the five `SKILL.md` files, when read, then each states it once.
- [ ] AC3 — Given the README statement, when read, then it carries at least one dated figure from
      the measured run.
- [ ] AC4 — Given the README statement, when read, then it names at least one thing that does not
      change.

## QA plan

- **Level:** verify — documentation.
- **Scripted assertion:**
  `for f in skills/*/SKILL.md; do grep -qi 'one skill per session' "$f" || exit 1; done`, plus a
  grep of `README.md` for `2026-08` to confirm the figures are dated rather than floating.

## Out of scope

- Changing any standard. This ticket documents where work happens, not what is required of it.

## Notes & decisions

- FR4 is the counter-intuitive half and the one most likely to be lost. Writing five related
  tickets in one capture session was measurably cheaper per ticket than five sessions would have
  been, because reading the source material is a shared cost paid once. Isolation is per skill,
  not per unit of work.
