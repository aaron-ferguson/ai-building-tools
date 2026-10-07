---
id: "0194"
title: Give tests/next.test.sh a runner that selects one ticket's sections
type: chore
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-06
source: retro
relates: ["0180"]
expects:
  - tests/next.test.sh
  - .claude/backlog/config.yml
parent:
blocked_by: []
claimed_by:
claimed_at:
touches:
---

## Problem

**A mutation rerun of `tests/next.test.sh` for one ticket runs all 572 cases, about 10 minutes a run,
and `verify` Step 3 asks for one per cited check on every router ticket.** Verify 0187/0188/0174/0041
copied the preamble (helpers, lines 1–389) plus the ticket's own sections to a scratch file with
`ROOT=` pinned: 53 cases in 15 s, each mutation reddening as in the whole file. That copy is made by
hand each time. `config.yml`'s `commands` comment says only to redirect rather than pipe.

## Functional requirements

- **FR1** — `tests/next.test.sh --only <id>` runs the preamble and every section whose `echo` heading
  starts with `<id> ` and nothing else, and prints the usual tally.
- **FR2** — An `<id>` matching no section exits non-zero with a message, never `0 passed, 0 failed`.
- **FR3** — With no flag the file runs exactly as today. `config.yml`'s `commands` comment names the
  flag for mutation reruns; the whole file still runs as the control.

## Acceptance criteria

- [ ] AC1 — `--only 0188` runs more than zero and fewer than all cases, and every case it runs is
  headed `0188`. Red: ignore the flag.
- [ ] AC2 — `--only 9999` exits non-zero. Red: let it exit 0 on an empty selection.
- [ ] AC3 — The no-flag case count equals the count before the change. Red: drop a section.

## Notes & decisions

- **2026-10-06 (retro, run-20261004T232135Z tail).** Filed from FINDINGS.md (verify 0187/0188/0174/0041).
