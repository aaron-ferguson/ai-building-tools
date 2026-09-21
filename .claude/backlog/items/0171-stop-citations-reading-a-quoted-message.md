---
id: "0171"
title: Stop the citation guard reading an italic-quoted CLI message as a rule name
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
relates: ["0117"]
expects:
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-09-13 by a retro pass: `tests/citations.test.sh` read an italic-quoted CLI message in
`skills/sprint/SKILL.md` as a citation of a rule name, and demanded a rule that does not exist.
Quoting what a tool prints is not citing a rule, and a guard that cannot tell them apart taxes
every future skill edit that quotes an error message — which the sprint skill now does in several
places, because the exact text is what a reader needs to recognise the failure.

`0117` fixed two other false positives in the item-ID matcher, and this is a third matcher with a
different shape, so it is related rather than absorbed.

## Functional requirements

- FR1 — A rule-name citation inside an italic-quoted string that reproduces tool output is not
  counted as a citation.
- FR2 — A real rule-name citation in prose is still counted, including one that carries emphasis of
  its own.

## Acceptance criteria

- [ ] AC1 — Given a fixture file whose only candidate is an italic-quoted reproduction of a CLI
  message, when the guard runs, then it reports no citation and exits 0. Guard:
  `tests/citations.test.sh`. Red: today's matcher.
- [ ] AC2 — Given a fixture carrying one genuine rule-name citation in prose, the guard still counts
  exactly one. Guard: `tests/citations.test.sh`. Red: a fix that suppresses real citations.
- [ ] AC3 — Given the repo as committed, the citation count the guard reports is unchanged by this
  change except for the false positive it removes. Guard: `tests/citations.test.sh`. Red: a matcher
  that drops a real citation elsewhere.

## QA plan

- **Why that level:** `unit` — every criterion runs the guard against an authored fixture.
- **Specific checks:** `tests/citations.test.sh`, each red proved by reverting the matcher, then the
  whole suite. Fixtures are authored, and name no id that could be read as a real backlog row.

## Out of scope

`0117`'s file-mode and clock-time false positives.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 — filed from `FINDINGS.md` by the sprint supervisor rather than a `queue` session, for
  the reason recorded in `0168`. The sweep's review list ranked it directly below `0117` and related
  it to `0117` rather than absorbing it, because the matcher is a different one.
- **2026-09-21 (retro).** Reproduced outside a fixture: a retro edit to `skills/sprint/SKILL.md`
  quoted a CLI refusal message in italics inside a sentence, and `tests/citations.test.sh` failed
  with *cites …, which is not a rule in CONCURRENCY.md*. The guard was right to be loud and wrong
  about what it saw; the edit was reworded to drop the italics, which is an author working around a
  guard rather than the guard improving the text. Quoting a tool's own message is a normal thing for
  these skills to do, so the defect costs an edit every time it recurs.
