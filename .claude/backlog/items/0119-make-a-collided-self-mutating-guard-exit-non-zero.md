---
id: "0119"
title: Make a collided self-mutating guard exit non-zero instead of silently printing no tally
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0089", "0093"]
expects:
  - tests/handoff.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`tests/handoff.test.sh` returns rc=0 and prints *no tally at all* when the template is mutated
externally on a line the harness also mutates.** The harness rewrites its own copy of `handoff` for
the read-back cases; an external mutation to the `touches:` skiplist collides with that, the case
prints `FAIL — the mutation did not apply — the case below proves nothing`, and the script then
exits **0** with no `N passed, M failed` line.

`verify` Step 3 names the missing tally as the tell and is right, but **rc=0 is the dangerous
half**: a QA session running the suite in a `|| true` loop and reading tallies sees a file that
produced no output and reads it as noise rather than as the red it is. The mutation did in fact
redden — the read-back fired with `did not apply to: touches.entries` — and that is discoverable
only by reading the full output of a run that reported success.

## Functional requirements

- FR1 — a collided self-mutation exits non-zero.
- FR2 — it prints a tally in the same shape as every other file, so a tally-reading loop sees the
  failure rather than an absence.
- FR3 — the message says the collision is a collision, not a logic failure, so the session does not
  debug the wrong thing.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whatever the fix generalises to is stated in the harness header, not only in this file | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given an external mutation to the `touches:` skiplist in `handoff`, when
  `tests/handoff.test.sh` runs, then it exits non-zero; red by restoring the current `exit 0` path.
- [ ] AC2 — the same run prints a line matching `[0-9]+ passed, [0-9]+ failed`; red the same way.
- [ ] AC3 — that line reports at least one failure rather than `0 failed`.
- [ ] AC4 — given no external mutation, the file still exits 0 with its full tally unchanged at its
  current count — the control that AC1 narrowed rather than broke the harness.

## QA plan

- **Why that level:** the artifact is the guard itself; every criterion is a run of it under a
  named mutation.
- **Specific checks:** `tests/handoff.test.sh` under the collision and without it, and the whole
  suite, since the harness's self-mutation idiom may be shared.

## Out of scope

Sweeping other guards for the same shape — that is `0089`. Changing what `handoff` itself does.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-08. The collision was found while
  verifying an unrelated ticket, which is why the entry records the exact failing read-back string.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Same contract, other failure: `tests/cross-cutting-change.test.sh:190` indents its tally (`printf '\n  %s passed, %s failed\n'`), so a batch grep on `^[0-9]+ passed` reports the one green file as the no-tally shape `verify` Step 3 treats as red (verify 0142). The tally line is a machine interface and nothing asserts its format.
