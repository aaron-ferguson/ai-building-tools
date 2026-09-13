---
id: "0151"
title: Make sprint's stage dispatch accept its own outcome schema
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0134"]
expects:
  - skills/sprint/outcome.schema.json
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**Every `/sprint` stage dispatch fails before a session starts.** On run `run-20260913T021045Z`,
`claude -p` 2.1.270 rejected the schema: *"--json-schema is not a valid JSON Schema: no schema with key
or ref https://json-schema.org/draft/2020-12/schema"*, exit 1, empty stdout, and the run escalated with
nothing done. A scratchpad copy with only line 2's top-level `$schema` key removed was accepted and
returned a conforming object, so that key alone is the cause. Step 1's probe passes because its inline
schema carries no `$schema`, so the probe cannot catch this.

## Functional requirements

- FR1 — `skills/sprint/outcome.schema.json` carries no top-level `$schema` key, and remains a schema
  every existing conforming outcome still validates against.
- FR2 — `sprint` Step 1's dispatch probe passes the real schema file rather than an inline one, so a
  schema the CLI rejects stops the run at Step 1.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The reason the key is absent is a comment-equivalent note beside the probe in the skill, so nobody restores it as tidying. | A guard asserting the note reds when it is removed. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/outcome.schema.json`, when `tests/sprint.test.sh` runs, then an assertion that the file has no top-level `$schema` key passes. Red-making change: restoring line 2.
- [ ] AC2 — Given `skills/sprint/SKILL.md` Step 1, when the suite runs, then an assertion that the probe names `outcome.schema.json` passes. Red-making change: the probe's inline schema, as today.

## QA plan

- **Why that level:** `unit` — both requirements are file assertions in the existing sprint suite; the live CLI acceptance was already observed and recorded above.
- **Specific checks:** `tests/sprint.test.sh`; one live `claude -p --json-schema skills/sprint/outcome.schema.json` probe, output quoted in evidence.

## Out of scope

- Any other sprint tooling defect from the same run (0152, 0153, 0154).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Ranked first: it blocks every sprint dispatch.
