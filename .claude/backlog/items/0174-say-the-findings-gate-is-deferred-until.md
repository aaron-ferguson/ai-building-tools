---
id: "0174"
title: Say the findings gate is deferred until the run is out of work when no scope was confirmed
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0168"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**With no `--scope` at all, the deferral NOTE tells a supervisor about a confirmed scope it does not
have.** `./next --drive` over a crossed findings buffer and one takeable row prints:

```
NOTE      the findings gate crossed and is deferred until confirmed scope is finished
```

The behaviour is `0168` FR4's and is right — the gate waits for the `complete` site so a hand-driven
run finishes its work first. The **sentence** has one form for two cases. A supervisor reading it on
a run that confirmed no scope is told about a scope it never passed, and the obvious next move is to
go looking for the `--scope` ids it thinks it sent. Found verifying `0168` (claim 8b1d).

## Functional requirements

- FR1 — Where `SCOPE` is empty, the NOTE says the gate is deferred until the run is out of work,
  and does not use the words *confirmed scope*.
- FR2 — Where `SCOPE` is non-empty, the existing wording is unchanged.
- FR3 — Both copies of `next` carry the change — `skills/queue/templates/next` and
  `.claude/backlog/next` — per `tests/backlog-scripts-installed.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | The NOTE names the condition the run is actually in, so the next action it implies is available | A no-scope fixture asserting the absence of the confirmed-scope phrase in the NOTE | `observability-conventions.md` |
| Documentation | No restatement of `0168` FR4's behaviour; only its message wording changes | `tests/citations.test.sh` | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a crossed buffer, one takeable row and no `--scope`, when `./next --drive` runs, then the NOTE does not contain the confirmed-scope phrase — reddened by restoring the single-form sentence.
- [ ] AC2 — Given the same buffer with a `--scope` naming an unfinished id, when `./next --drive` runs, then the existing confirmed-scope wording is printed unchanged — reddened by applying the no-scope wording to both cases.
- [ ] AC3 — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then they match — reddened by editing only the template.

## QA plan

- **Why that level:** a message-shape change in a script with an existing fixture-driven suite.
- **Specific checks:** `tests/next.test.sh` (redirect to a file rather than piping — see `config.yml` beside `commands.unit`), `tests/backlog-scripts-installed.test.sh`.

## Out of scope

- Changing when the gate defers, which is `0168` FR4 and is correct.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park made verifying `0168`. Message wording only.
