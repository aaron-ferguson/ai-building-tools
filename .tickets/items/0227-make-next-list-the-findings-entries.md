---
id: "0227"
title: Make next list the findings entries so no drain matches a buffer's header by hand
type: bug
next: develop
status: ready
qa_level: unit
close_by: develop
size: s
created: 2026-11-06
source: agent
parent:
blocked_by: []
relates: ["0213", "0060"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
ac_digest: AC1=86b60aa5 AC2=e530e406 AC3=8374a189 AC4=627b8350 AC5=50f51155
---

## Problem

A sweeper draining `FINDINGS.md` by hand finds entries with the regex the buffer's header gives,
`^- (\*\*)?20[0-9]{2}-`. The header's own fenced example of the head token,
`- 2026-09-05 [->0060] — **what happened.** …` (line 32 of `skills/queue/templates/FINDINGS.md`),
matches that regex, so every buffer seeded from the template counts one entry too many to a
by-hand reader. `./next --findings` does not: `count_findings` in `skills/queue/templates/next`
skips everything above the first `---` rule, so the defect lives only in readers that re-derive
entry boundaries themselves.

It has now hit twice, both times in AetherWorks retros:

- run-20261017T193821Z — counted 8 entries where there were 7; an assertion caught it after the
  items, row and counter were written (recorded in item 0213's Problem).
- run-20261101T172121Z, 2026-11-06 — swept from this repo's `FINDINGS.md`, verbatim: *"a retro
  draining by that regex (as retro Step 4 and the header itself describe) found 3 entries in a
  2-entry AetherWorks buffer and would have truncated the header had it not asserted the count."*

Confirmed 2026-11-06: `grep -nE '^- (\*\*)?20[0-9]{2}-' skills/queue/templates/FINDINGS.md` prints
line 32, and the AetherWorks copy at `.claude/backlog/FINDINGS.md` matches on its line 32 too.

**Why not 0213.** 0213 fixed the template's example line and was withdrawn 2026-10-28 ("a guard over
a guard's wording … reopen if a real project hits the defect"). The second hit was in a project copy,
which 0213's own *Out of scope* leaves unfixed — the header is project-owned and never re-copied
(`skills/queue/SKILL.md` Step 0). Editing the template cannot reach the buffers that already exist,
so a template fix would not have prevented this hit. The reader can: the boundary rule already
exists in one script, and the fix is to expose it rather than have each sweeper re-derive it.

## Functional requirements

- FR1 — The shipped `skills/queue/templates/next` gains a mode that prints every findings entry, one
  line each, as `<buffer path>:<line number>` followed by the entry's first line, for every buffer
  `--findings` counts. Mode name is the builder's choice; `--findings-list` is the recommendation.
- FR2 — That mode decides what is an entry with the **same awk program** `count_findings` uses — one
  function both modes call, not a second parser — so the listing and the count can never disagree. A
  line `count_findings` reports as `MALFORMED` is listed as such, not dropped.
- FR3 — `.claude/backlog/next` is re-copied from the template so the two stay byte-equal, as
  `tests/backlog-scripts-installed.test.sh` already requires.
- FR4 — `skills/retro/SKILL.md` Step 4 and `skills/queue/SKILL.md` Step 5 name FR1's mode as how a
  sweeper enumerates the entries it will remove, in place of matching the header's pattern by hand.
- FR5 — `tests/next.test.sh` carries cases over a fixture buffer the test builds: a preamble holding
  a fenced example line that matches the reader regex, the `---` rule, and two entries, one of them
  `[->NNNN]`-marked.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | FR5's cases are proven red against `next` before FR1 lands, and again under a mutation of the shared awk program. | Delete the `!body && /^---$/` rule from the shared program: AC1 lists three entries, not two. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given FR5's fixture, when FR1's mode runs, then it prints exactly two lines, naming the
      two entries' line numbers and neither preamble line. *Red:* remove the preamble-skip rule from
      the shared program; the fenced example is listed as a third line (`tests/next.test.sh`).
- [ ] AC2 — Given the same fixture, when `./next --findings` runs, then its count equals AC1's line
      count, read from one fixture in one case. *Red:* give the listing its own copy of the program
      without the preamble rule; the count says 2 and the listing 3 (`tests/next.test.sh`).
- [ ] AC3 — Given a fixture whose body holds a `- ` line with no date, when FR1's mode runs, then
      that line is printed marked `MALFORMED`, with its line number. *Red:* drop the MALFORMED
      branch from the listing path (`tests/next.test.sh`).
- [ ] AC4 — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then
      it passes. *Red:* add FR1 to the template only.
- [ ] AC5 — `for t in tests/*.test.sh; do "$t" || exit 1; done` green.

## Out of scope

- Editing the template's fenced example line — that is 0213, withdrawn, and stays withdrawn.
- Rewriting project copies of the header in other repos.
- A new prose guard over FR4's skill wording: the 2026-10-27 triage stopped adding them, and the
  mechanism FR4 points at is asserted by AC1–AC3.
- Changing what `--findings` counts or how `--drive` gates on it.

## Notes & decisions

- 2026-11-06 (queue, unattended, AetherWorks sprint run-20261101T172121Z) — swept from this repo's
  `FINDINGS.md`, the entry parked by that run's retro. **Filed as a new ticket rather than
  un-withdrawing 0213**, because the second hit is in a project copy, which 0213 by its own scope
  cannot reach; the entry offered two fixes and this takes the reader-side one, expressed as a
  script rather than as a sentence telling sweepers where entries start. Routed to `develop`: no
  surface and no open decision — `count_findings` already holds the boundary rule. `close_by:
  develop`: every criterion names a case in a committed test file.
