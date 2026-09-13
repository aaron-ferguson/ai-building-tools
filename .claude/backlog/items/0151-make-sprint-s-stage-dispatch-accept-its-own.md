---
id: "0151"
title: Make sprint's stage dispatch accept its own outcome schema
type: bug
next:
status: done
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
closed: 2026-09-13
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

- [x] AC1 — Given `skills/sprint/outcome.schema.json`, when `tests/sprint.test.sh` runs, then an assertion that the file has no top-level `$schema` key passes. Red-making change: restoring line 2.
- [x] AC2 — Given `skills/sprint/SKILL.md` Step 1, when the suite runs, then an assertion that the probe names `outcome.schema.json` passes. Red-making change: the probe's inline schema, as today.

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

### Re-verification 2026-09-13 — session 33d2edfe, token 1913 — **PASS**

**Suite — `config.yml` `commands.unit`, whole suite, run twice at 0dd303f (before and after the session-limit pause), exit 0 both times.** Per-file tallies, second run, pasted:
`backlog-scripts-installed 37/0 · batching 39/0 · citations 46/0 · claim 98/0 · close-by 67/0 · close 246/0 · cost-by-category 29/0 · cross-cutting-change 21/0 · design-hold 34/0 · external-feedback 9/0 · falsifiable-acs 34/0 · findings-buffer 46/0 · findings-routing 41/0 · floor-probe 12/0 · graph-fields 36/0 · handoff 132/0 · item-ac-form 4/0 · last-line 17/0 · measurement 131/0 · money-in-skill-prose 12/0 · next 431/0 · qa-level-once 11/0 · reference-size 15/0 · release 45/0 · remote-anchor 20/0 · reporting 23/0 · retro-tool-edit 50/0 · skill-size 27/0 · sprint-ledger 95/0 · sprint 231/0/0 skipped · transient-mutation 6/0` (passed/failed, each file's own tally line).
Conventions resolved: `/Users/aaronferguson/AI/ai-building-conventions` (config.yml `conventions.path`). Copy under test: the repo copy; the installed 0.9.28 cache differs from it (pre-fix `outcome.schema.json` and `SKILL.md`). Dirty set at both captures: `?? .claude/backlog/runs/` only. Written through Bash, not the Write tool (Write was not attempted). Every mutation below was applied to a committed file, confirmed by a non-empty `git diff --stat`, and restored by its own path; each cycle ended on a green control run.

| Row | How checked | Result |
|---|---|---|
| AC1 | guard `0151 AC1` (python: `"$schema" in json.load(...)`). Mutation M1 (re-insert `"$schema": "https://json-schema.org/draft/2020-12/schema"` as line 2) → `FAIL 0151 AC1 — outcome.schema.json has a $schema key`, 230 passed 2 failed | ✅ |
| AC1 at its altitude — the CLI | live `claude` 2.1.270, `claude -p --model haiku --max-budget-usd 0.25 --json-schema "$(cat skills/sprint/outcome.schema.json)" …` on the **mutated** file → `Error: --json-schema is not a valid JSON Schema: no schema with key or ref "https://json-schema.org/draft/2020-12/schema"`, exit 1; on the **committed** file → exit 0, `is_error False`, `structured_output` = `{"stage": "retro", "session_id": "aaaaaaaa-0000-4000-8000-000000000001", "commits": [], "cost_usd": 0, "findings_parked": 0, "conventions_resolved": null, "escalation": null, "tickets": []}` | ✅ the key alone decides acceptance |
| FR1 (still validates conforming outcomes) | the only change to the schema is the deleted key (`git show 51b0ed2`, 1 deletion); the CLI returned a conforming outcome against it | ✅ |
| AC2 | Step 1 probe uses `--json-schema "$(cat <plugin root>/skills/sprint/outcome.schema.json)"`. Mutation M2 (restore the pre-51b0ed2 inline `{"type":"object","properties":{"probe":…}}` schema) → `FAIL 0151 AC2 — Step 1's probe still uses an inline schema`, 230 passed 1 failed | ✅ |
| NFR Documentation | guard `0151 NFR`. Mutation M3 (delete the *"no top-level `$schema` key"* note) → `FAIL 0151 NFR`, 230 passed 1 failed | ✅ |
| Always-on (CONVENTIONS_CORE.md) | no secrets, no data; the probe used a synthetic session id | ✅ |

Evidence set: `skills/sprint/outcome.schema.json`, `skills/sprint/SKILL.md`, `tests/sprint.test.sh` (which builds its own temp `runs/`, never the repo's). Intersection with the dirty set `.claude/backlog/runs/`: empty — not advisory.

⚠️ Not live yet: the installed plugin 0.9.28 still carries the `$schema` key, so `/sprint` on this machine keeps failing until a release (parked in FINDINGS.md, 68b9dc0).

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Ranked first: it blocks every sprint dispatch.
- **2026-09-13 — reopened for re-verification, by the user's request.** The verify session that closed this ticket (433a37e3) ran on claude-sonnet-4-6, returned `conventions_resolved: null` and a placeholder `session_id`, and ran per-ticket test files instead of `config.yml` `commands.unit`. Composed by hand under the backlog lock by a `queue` session, since no operation reopens a closed ticket (that path is 0161): row moved from `DONE.md` back to the top of `QUEUE.md`, `next: verify`, `status: ready`, `closed:` removed, and the acceptance criteria UNTICKED — a tick is evidence of the pass being distrusted, and `close` re-ticks what the new pass checks. The QA evidence above is kept as the record of that pass; the next `verify` writes its own beside it and does not rely on it.
- **2026-09-13 — re-verified (session 33d2edfe) and closed on this pass's own evidence**, above; the earlier pass's table is kept as history only.
