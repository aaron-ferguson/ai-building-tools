---
id: "0197"
title: Make tools/release refuse a behaviour-changing bump with no Did not change section
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-09
source: agent
parent:
blocked_by: []
relates: ["0041", "0191"]
expects:
  - tools/release
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-10-07 by verify abe1 of 0191: `CHANGELOG.md`'s preamble says "Each version ends with
`### Did not change`, written by the release session", and `## 0.9.37` (633c4e3) has none, because
`tools/release --bump` does not refuse a behaviour-changing bump without one. The promise rests on a
release session's memory (`CONVENTIONS_CORE.md`, *Prefer enforcement over instruction*). Separately,
0191's QA plan attributes the line to `--no-behaviour-change`, which per `tools/release:66-70` writes a
different line.

## Functional requirements

- FR1 — `tools/release --bump` refuses, before fetching or pushing anything, when `## Unreleased` holds
  entries but no `### Did not change` subsection, and the message names the missing heading.
- FR2 — `--no-behaviour-change` behaviour is unchanged.
- FR3 — `## 0.9.37` gains its missing `### Did not change` only if the release session can say it from
  the diff; otherwise the preamble records that 0.9.37 predates the check. Decide in the build, record
  why in *Notes & decisions*.

## Acceptance criteria

- [ ] AC1 — Given a fixture CHANGELOG with an Unreleased entry and no `### Did not change`, `tools/release
  --bump --yes` exits non-zero, prints `Did not change`, and leaves `HEAD` and `plugin.json` unmoved.
- [ ] AC2 — The same fixture with the subsection added passes this check. Red: remove the new check →
  AC1 fails.

## QA plan

Unit: the configured suite, with the release script run against a fixture repo, never this one.

## Out of scope

- Writing `### Did not change` automatically.

## Notes & decisions

- 2026-10-09 — Filed by retro from the tools `FINDINGS.md` entry of 2026-10-07.
