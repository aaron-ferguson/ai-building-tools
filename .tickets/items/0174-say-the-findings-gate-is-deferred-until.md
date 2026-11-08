---
id: "0174"
title: Say the findings gate is deferred until the run is out of work when no scope was confirmed
type: bug
next:
status: done
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
closed: 2026-10-05
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

- [x] AC1 — Given a crossed buffer, one takeable row and no `--scope`, when `./next --drive` runs, then the NOTE does not contain the confirmed-scope phrase — reddened by restoring the single-form sentence.
- [x] AC2 — Given the same buffer with a `--scope` naming an unfinished id, when `./next --drive` runs, then the existing confirmed-scope wording is printed unchanged — reddened by applying the no-scope wording to both cases.
- [x] AC3 — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then they match — reddened by editing only the template.

## QA plan

- **Why that level:** a message-shape change in a script with an existing fixture-driven suite.
- **Specific checks:** `tests/next.test.sh` (redirect to a file rather than piping — see `config.yml` beside `commands.unit`), `tests/backlog-scripts-installed.test.sh`.

## Out of scope

- Changing when the gate defers, which is `0168` FR4 and is correct.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park made verifying `0168`. Message wording only.

- **2026-10-04 — built** (develop 24f1, commit `287a91e`). `findings_gate`'s `gate` site now splits
  the one deferral sentence in two: empty `SCOPE` prints *"deferred until the run is out of work"*,
  a live scope keeps the confirmed-scope sentence verbatim. Both copies of `next` carry it. When the
  behaviour runs is untouched (0168 FR4).
  - **Mutations (all run, 2026-10-04):** AC1, the single-form sentence restored, was the red before
    the build (2 failed: the out-of-work phrase missing, and *confirmed scope* present). AC2, the
    no-scope wording applied to both cases, mutated on committed `287a91e`: 1 failed, the
    word-for-word case. AC3, the template edited alone: `tests/backlog-scripts-installed.test.sh`
    read 44 passed, 1 failed until the installed copy was updated, then 45/0.
  - **The AC2 assertion pins the sentence plus its reason's first words** (`— FINDINGS.md holds 8
    entries`), so a reworded NOTE that still contains *confirmed scope* reds too.

## QA evidence

Verify de3c, 2026-10-04 — **PASS**, at `qa_level: unit`, batch 0187/0188/0174/0041 from one develop gate.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`) — 32 files, every tally `0 failed`; `tests/next.test.sh` 572 passed, 0 failed; `tests/backlog-scripts-installed.test.sh` 45 passed, 0 failed; `tests/citations.test.sh` 46 passed, 0 failed. No lint or typecheck is configured.
Tree: `git status --porcelain` empty at Step 2 and at the verdict; the intersection is empty, so this is not advisory.

Mutations were applied to committed `skills/queue/templates/next` (the copy the fixtures run), diff confirmed non-empty, restored by that path, and the tree read clean after each. The `next` cases ran from a verbatim scratch copy of `tests/next.test.sh`'s preamble plus its 0154 AC2/0188/0174 sections (control 53 passed, 0 failed).

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | Given a crossed buffer, one takeable row, no `--scope`; the NOTE lacks the confirmed-scope phrase | single-form sentence restored (`[ -z "$SCOPE" ] \|\| scope_live`) | red, 51 passed, 2 failed |
| AC2 | Given the same buffer with `--scope` naming an unfinished id; the existing wording, unchanged | no-scope wording applied to both cases | red, 52 passed, 1 failed |
| AC3 | both copies of `next` match | template edited alone | red, `tests/backlog-scripts-installed.test.sh` 44 passed, 1 failed |

**Evidence set:** `skills/queue/templates/next`, `.claude/backlog/next`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`, `tests/citations.test.sh`.

| NFR | Check | Result |
|---|---|---|
| Observability — the NOTE names the condition the run is in | AC1's no-scope case asserts the absence of *confirmed scope* (red under the AC1 mutation) | holds, guarded |
| Documentation — no restatement of 0168 FR4, only the wording | the diff touches only the NOTE branch and a two-line why-comment; `tests/citations.test.sh` 46 passed, 0 failed | holds |
| Always-on (CONVENTIONS_CORE) | message-only change, no new field, no egress | holds |
