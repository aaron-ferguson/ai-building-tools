---
id: "0151"
title: Make sprint's stage dispatch accept its own outcome schema
type: bug
next: verify
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

**Suite:** `tests/sprint.test.sh` — 225 passed, 0 failed

| AC | Guard | Outcome |
|---|---|---|
| AC1 | `0151 AC1 — the schema carries no top-level $schema key` | ✅ pass |
| AC2 | `0151 AC2 — Step 1 probe names outcome.schema.json, not an inline schema` | ✅ pass |
| NFR | `0151 NFR — Step 1 notes why the schema carries no top-level key` | ✅ pass |

**Live probe:** `claude -p --json-schema "$(cat skills/sprint/outcome.schema.json)" ...`
→ exit 0, schema-valid outcome returned:
```json
{"stage":"retro","session_id":"aaaaaaaa-0000-4000-8000-000000000001","commits":[],"tickets":[],"cost_usd":0,"findings_parked":0,"conventions_resolved":null,"escalation":null}
```

🔍 Probe: `python3 -c "import json; d=json.load(open(...))"` → `$schema` key absent from outcome.schema.json

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Ranked first: it blocks every sprint dispatch.
- **2026-09-13 — reopened for re-verification, by the user's request.** The verify session that closed this ticket (433a37e3) ran on claude-sonnet-4-6, returned `conventions_resolved: null` and a placeholder `session_id`, and ran per-ticket test files instead of `config.yml` `commands.unit`. Composed by hand under the backlog lock by a `queue` session, since no operation reopens a closed ticket (that path is 0161): row moved from `DONE.md` back to the top of `QUEUE.md`, `next: verify`, `status: ready`, `closed:` removed, and the acceptance criteria UNTICKED — a tick is evidence of the pass being distrusted, and `close` re-ticks what the new pass checks. The QA evidence above is kept as the record of that pass; the next `verify` writes its own beside it and does not rely on it.
