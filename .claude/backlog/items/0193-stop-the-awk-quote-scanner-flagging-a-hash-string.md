---
id: "0193"
title: Stop the awk-quote scanner flagging a single-quoted shell string that starts with a hash
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: xs
created: 2026-10-06
source: retro
relates: ["0077", "0041"]
expects:
  - tests/backlog-scripts-installed.test.sh
parent:
blocked_by: []
claimed_by:
claimed_at:
touches:
---

## Problem

**`tests/backlog-scripts-installed.test.sh`'s awk-quote scanner reports "closed early by a quote"
for a single-quoted shell string beginning with `#` that sits outside every awk program**, such as
`printf '# Changelog\n'`: it takes the `#` for an awk comment. develop 9b67 (0041) worked around it by
double-quoting the printf, so the scanner still misfires on the next script that writes one
(parked 2026-10-04).

## Acceptance criteria

- [ ] AC1 — Given a fixture script with `printf '# x\n'` outside any awk program, the scanner reports
  no quote defect. Red: revert the fix.
- [ ] AC2 — Given a fixture awk program closed early by an apostrophe in its prose, the scanner still
  reports it. Red: make the scanner skip every line starting with a quoted `#`.

## Notes & decisions

- **2026-10-06 (retro, run-20261004T232135Z tail).** Filed from FINDINGS.md (develop 9b67).
