---
id: "0139"
title: Decide what catches an apostrophe that lands where a legitimate awk terminator goes
type: bug
next: design
status: ready
qa_level: verify
qa_manual:
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0077", "0089"]
expects:
  - tests/backlog-scripts-installed.test.sh   # the AC8 scanner
  - references/CONCURRENCY.md                 # The four scripts
claimed_by:
claimed_at:
touches:
---
## Problem

**`0077`'s guard catches every apostrophe inside an `awk` comment and is blind to one placed where
a legitimate terminator goes — which is still a live break.**

Measured 2026-09-09 while verifying `0077` (token `4e31`). Insert a bare `'` at column 0 of
`skills/queue/templates/close:288`, the first body line of the `ac_counts` program, in both copies:

- `sh -n` accepts both copies — under `/bin/sh` here (bash 3.2.57) the file is valid.
- `tests/backlog-scripts-installed.test.sh` reports **37 passed, 0 failed**.
- `tests/close.test.sh` reports **115 passed, 86 failed**.

That is the same end state the two `0077` bounces named: a live broken `close` under a fully green
guard.

**Why the existing clause cannot see it.** The AC8 scanner reports a multi-line region whose closing
quote is *not* the first thing on its line bar whitespace and the block enders `)`, `}`, `]`, or
whose close is preceded inside the region by an `awk` comment start. An apostrophe at the head of a
body line satisfies neither test — it sits exactly where a real terminator sits, and there is no `#`
before it. The two clauses are correct; the shape is outside both by construction.

**Both global signals are silent, measured rather than assumed.** `sh -n` accepts, and the file
re-pairs: an independent tokeniser run to EOF over the mutated `close` reports `state=0 depth=0`,
identical to the clean file. So neither a parse check nor a whole-file quote-balance check can see
it either.

**What is already proved and must not be re-derived.** Every apostrophe position inside every `awk`
comment in the four scripts is caught — 1,298 insertions over the 16 comment-bearing lines inside
the 37 embedded programs, 1,288 of them by the AC8 scanner itself and 10 by `sh -n`, zero misses.
Sweeping a trailing comment, and an inserted comment line, across all 340 in-region lines in both
copies also gives zero misses. `0077`'s AC2 is met; this ticket is the residue outside it.

## Open design question

Three shapes, and they are not equivalent.

**A — teach the scanner what a program body looks like after a close.** On closing a multi-line
region, look ahead: if the text that follows before the next region opener parses as `awk` body
rather than as shell, the close was false. Catches the shape directly. Costs a heuristic with real
false-positive surface, in a guard whose whole value is that it is currently exact — and the four
scripts would have to keep satisfying it forever.

**B — assert the count and span of the embedded programs instead of scanning for defects.** Record
what the four scripts' regions *are* — how many, and which line each opens and closes on — and fail
when that shape moves. A false close changes the region map, so it is caught whatever it looks
like. Costs a fixture that every legitimate edit to these scripts must update, which is either a
useful checkpoint or a tax depending on how often they change.

**C — accept the gap and say so.** Record in `references/CONCURRENCY.md`, *The four scripts*, that
the scan covers prose comments and not a bare apostrophe at the head of a line, and rely on the
convention plus `close.test.sh` for the rest. Costs nothing and leaves a known live-break shape
uncaught.

**What must be true whichever wins:** a session that breaks one of these four scripts learns it from
a guard that names the quote, not from twenty minutes inside `close.test.sh` — which is the outcome
`0077` exists to buy, and the reason `C` is a real option only if it is written down where the next
author reads it.

## Functional requirements

Written after the design question is settled — that is what `next: design` means here.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | Whichever shape wins is proved able to fail by the `close:288` column-0 mutation above, restored by the path mutated | `testing-conventions.md` |
| Dependencies | No new dependency: `shellcheck` stays out of scope, as it was for `0077` | `dependency-conventions.md` |
| Documentation | The chosen shape is stated once in `references/CONCURRENCY.md`, *The four scripts*, and the decision record says why the others were rejected | `documentation-conventions.md` |

## Acceptance criteria

Written after the design question is settled.

## QA plan

- **Level:** verify — the deliverable is a decision plus whatever guard it licenses.
- **Why this level:** to be revised with the ACs; if shape A or B wins, this becomes `unit`.
- **Specific checks:** to be written with the ACs. The column-0 mutation at `close:288` is the
  reproduction either shape has to beat, and a sweep is the way to check it — see the finding
  `0077` parked on 2026-09-09.

## Out of scope

- Rewriting the four scripts to avoid embedded `awk`, and `shellcheck`. Both were ruled out by
  `0077` and neither has become cheaper.
- Anything about apostrophes inside `awk` comments. That is `0077`, closed and proved by sweep.

## Notes & decisions

- 2026-09-09 — Filed by `verify` (`4e31`) rather than bounced onto `0077`. `0077`'s AC2 names an
  apostrophe *inside an `awk` comment* and its Problem names prose comments; this shape is neither,
  and the remedy is a choice between three unequal designs rather than another clause. Bouncing it
  would have handed `develop` a research problem in place of a constraint.
