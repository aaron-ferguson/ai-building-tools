---
id: "0202"
title: Name a liveness check for a dispatched stage that works from a backgrounded call in sprint
type: bug
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-10
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 from a park in this repo's buffer (quantum-catan run-20261009T003522Z).
Waiting on a nested design stage, the supervisor polled `until ! kill -0 <pid>` in a backgrounded
Bash call; it returned at once while the stage was still alive. `ps -p <pid>` and the dispatch
wrapper's own completion notice were both reliable. `skills/sprint/SKILL.md` *Design beside other
stages* step 2 (line ~351) says to wait for the row to read held "or the session's outcome arrived
first — with one backgrounded `until` loop" and names no way to detect the second condition, so a
supervisor improvises one.

## Established, not yet specified

- `kill -0 "$$"` at line ~490 is a different use (the calling shell checking itself) and is fine.
- The likely fix is one clause in step 2 naming the check (`ps -p`, or waiting on the dispatch
  wrapper) and why `kill -0` on another process's pid is not used. `skills/sprint/SKILL.md` is near
  its `tests/skill-size.test.sh` cap, so the clause may have to displace text.
- One observation from one run; why `kill -0` failed (sandbox, pid namespace) is not established.

## Notes & decisions
