---
id: "0213"
title: Stop the findings header's own example matching the entry pattern it tells readers to use
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-17
source: agent
parent:
blocked_by: []
relates: ["0100"]
expects:
  - skills/queue/templates/FINDINGS.md
  - .claude/backlog/FINDINGS.md
  - tests/findings-buffer.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

The header of `skills/queue/templates/FINDINGS.md` tells every sweeper to find entries with
`^- (\*\*)?20[0-9]{2}-`, which it introduces with "Readers match". A few lines further down, the same
header shows a fenced example of the sweeper's head token:

```
- 2026-09-05 [->0060] — **what happened.** why it might matter (pointer: file, item id)
```

That example line matches the pattern, so a reader who follows the header literally counts one entry
too many in every buffer scaffolded from this template. `next --findings` is fence-aware and counts
correctly. A by-hand drain does not. The entry came in from the AetherWorks retro of
run-20261017T193821Z and reads, verbatim:

> a by-hand drain following the header literally counted 8 entries where there were 7; an assertion
> caught it mid-write, after the items, row and counter were already written, so the commit had to
> be completed under a second lock.

Confirmed at `e94ae36`: line 32 of the template matches, and so does line 32 of this repo's own
`.claude/backlog/FINDINGS.md`.

## Functional requirements

- FR1 — No line of the shipped template `skills/queue/templates/FINDINGS.md` matches the reader
  pattern the header states. The example still shows the head token's position after the date.
  Recommended: indent the fenced example line so the `^-` anchor cannot hold. Do not reword the pattern.
- FR2 — This repo's own buffer, `.claude/backlog/FINDINGS.md`, gets the same header correction, so
  the two headers stay byte-equal in that region as they are now.
- FR3 — `tests/findings-buffer.test.sh` asserts FR1 against both headers. The check counts lines
  matching the reader pattern in the template, which ships with no entries, and expects **0**.
  Against the local buffer it counts lines that match the pattern *and* sit inside a code fence, and
  expects **0**.

## Non-functional requirements

| Dimension | Requirement | How it would red | Convention |
|---|---|---|---|
| Testing | FR3's assertion is proven red against the unfixed header before the fix lands. | Revert the indentation on line 32 of either header; the case fails naming that file. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/templates/FINDINGS.md`, when `grep -cE '^- (\*\*)?20[0-9]{2}-'`
      runs over it, then it prints `0`. *Red:* un-indent the example line, and it prints `1`.
- [ ] AC2 — Given `.claude/backlog/FINDINGS.md`, when FR3's fenced-line check runs, then no matching
      line sits inside a fence. *Red:* un-indent the example line in that file.
- [ ] AC3 — Given the header after the fix, the example still shows the token immediately after
      the date, and `tests/findings-buffer.test.sh`'s existing window assertions on the token pass.
      *Red:* deleting the example reds the existing token-form assertions.
- [ ] AC4 — `for t in tests/*.test.sh; do "$t" || exit 1; done` green.

## Out of scope

- **Project copies of the header.** `FINDINGS.md` is seeded once and then belongs to the project,
  per the queue skill's Step 0, so AetherWorks and every other scaffolded backlog keep the matching
  example until their own session edits it. This ticket fixes the source only.
- Changing `next --findings`, which already skips fenced lines.
- Rewording the reader pattern.

## Notes & decisions

- 2026-10-17 (queue, unattended, AetherWorks run-20261017T193821Z) — swept from this repo's
  `FINDINGS.md`. **Chose indenting the example over adding a "skip fenced lines" sentence beside the
  pattern.** Indenting removes the trap. The sentence would be one more rule for every by-hand reader
  to remember, and the entry itself shows that the remembering is what failed. Routed to
  `develop`: no surface and no open decision.
- Ranked directly above 0100, which covers the same file. It sits higher on tie-breaker 4 (smaller and
  more certain): one line in one file, plus a guard.
