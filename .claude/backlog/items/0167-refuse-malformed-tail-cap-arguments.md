---
id: "0167"
title: Refuse a malformed tail-cap argument by name instead of tracing back
type: bug
next: develop
status: ready
qa_level: unit
close_by: develop
qa_manual:
size: s
created: 2026-09-17
source: agent
parent:
blocked_by: []
relates: ["0152"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-09-13, verbatim:

> `tools/sprint-ledger.sh tail-cap --findings abc` still dies with a Python `ValueError` traceback;
> 0152 turned only the zero and negative `--threshold` into a named refusal. The supervisor reads
> these numbers out of `./next --findings` and `config.yml` by text, so a malformed value reaches the
> parser.

Reproduced at 0b5e9cd: `tail-cap --findings abc --threshold 8 --base-cap 3` prints
`ValueError: invalid literal for int() with base 10: 'abc'`. The same parse loop indexes past the
end when a flag is the last argument.

## Functional requirements

- FR1 — A non-integer `--findings` or `--threshold`, or a non-numeric `--base-cap`, exits non-zero
  with one line naming the flag and the value received, and no traceback.
- FR2 — A flag given as the last argument, with no value, exits non-zero naming the flag.
- FR3 — A negative `--findings` or a negative `--base-cap` is refused the same way.

## Acceptance criteria

- [ ] AC1 — Given `tail-cap --findings abc --threshold 8 --base-cap 3`, then exit is non-zero, output
  contains `--findings` and `abc`, and contains no `Traceback`. Guard: `tests/sprint-ledger.test.sh`.
  Red: today's bare `int()`.
- [ ] AC2 — Given `--base-cap x1`, the same shape naming `--base-cap`. Guard:
  `tests/sprint-ledger.test.sh`. Red: bare `float()`.
- [ ] AC3 — Given `tail-cap --findings 3 --threshold 8 --base-cap`, then exit is non-zero naming
  `--base-cap`, no `Traceback`. Guard: `tests/sprint-ledger.test.sh`. Red: today's unchecked index.
- [ ] AC4 — Given `--findings -1`, exit non-zero naming `--findings`. Guard:
  `tests/sprint-ledger.test.sh`. Red: no sign check.
- [ ] AC5 — Given `--findings 72 --threshold 8 --base-cap 3`, output is still `27.00`, exit 0. Guard:
  `tests/sprint-ledger.test.sh`. Red: validation that rejects valid input.

## QA plan

- **Why that level:** argument parsing of one mode; every criterion is a run of the tool.
- **Specific checks:** each AC's red proved by reverting its check, then the whole suite.

## Out of scope

Validating `estimate` and `record` arguments.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 (queue sweep after retro e30dfa9d) — filed from `FINDINGS.md`. `next: develop`: a CLI
  flag, no decision. `close_by: develop`: every criterion is a committed assertion in
  `tests/sprint-ledger.test.sh`.
