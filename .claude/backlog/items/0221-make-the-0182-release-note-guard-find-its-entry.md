---
id: "0221"
title: Make the 0182 release-note guard find its entry wherever a release moves it
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: ["0182"]
expects:
  - tests/backlog-location.test.sh
  - tests/changelog-entry-guards.test.sh
ac_digest: AC1=de3ed1a3 AC2=22a6488f AC3=2abe7175 AC4=e8829718 AC5=b2c730d4 AC6=6e862a51
claimed_by: "f7e4"
claimed_at: 2026-10-27T19:08:39Z
touches:
  - tests/backlog-location.test.sh
  - tests/changelog-entry-guards.test.sh
---

## Problem

The whole suite is red at HEAD, and the red comes from the release itself. No code regressed.
Sprint run-20261027T185815Z found the red baseline.

**Repro.** At `b63e23c` ("Bump the plugin version to 0.9.44") and at `0b82321` after it:

```
$ tests/backlog-location.test.sh
AC9 — CHANGELOG ## Unreleased names the move, ./migrate, the legacy end and the install order
  FAIL 0182 AC9 — ## Unreleased does not name `.backlog/`
  FAIL 0182 AC9 — ## Unreleased does not name `./migrate`
  FAIL 0182 AC9 — ## Unreleased does not name 2026-12-31
  FAIL 0182 AC9 — ## Unreleased does not name install
  FAIL 0182 AC9 — ## Unreleased does not name `tools/release verify`

43 passed, 5 failed
```

**Cause.** `tests/backlog-location.test.sh` lines 356-361 read
`UNREL="$(section "$ROOT/CHANGELOG.md" "Unreleased")"` and assert the five phrases inside it.
`tools/release --bump` moves every `## Unreleased` entry under the new version heading and leaves
`## Unreleased` empty, which is its job (0041 AC13, `tests/release.test.sh`). `b63e23c` did exactly
that: the diff is `CHANGELOG.md | 2 ++` and `.claude-plugin/plugin.json | 2 +-`. So the 0182 entry
now sits at `CHANGELOG.md` line 26, under `## 0.9.44 — 2026-10-27`, and it still carries all five
phrases (checked 2026-10-27 with `grep -F` on that line). **The guard can only pass until the first
release after its ticket closes, and every release breaks it.**

**Who is hurt.** Every session that runs the suite. `develop` Step 5 and `verify` both read a red
whole-suite gate, and `config.yml` `unit` is fail-fast. `tools/release` step 5 uses the same line
as its release gate, so **the next release refuses until this is fixed.** Each session that meets
the red has to work out that it is not its own, as run-20261027T185815Z did.

**The general version.** A criterion on a release note asserts *the entry*, and the entry moves on
every release. `verify` already closes on criteria that make `develop` write a note under
`## Unreleased` (0.9.44 notes, `CHANGELOG.md`), so the next ticket written that way inherits this
defect. Today `tests/backlog-location.test.sh` is the only file that reads the repo's own
`## Unreleased` for content. Every other `Unreleased` reader under `tests/` reads a fixture
CHANGELOG the test builds (`$FIX`, `$CO2` in `tests/close.test.sh` and `tests/release.test.sh`).

## Functional requirements

- FR1 — In `tests/backlog-location.test.sh`, the 0182 AC9 check finds the 0182 release-note entry
  by its content: the one top-level `- ` bullet in `CHANGELOG.md` that names both `` `.backlog/` ``
  and `` `./migrate` ``, under any `## ` heading. It asserts the five phrases (`` `.backlog/` ``,
  `` `./migrate` ``, `2026-12-31`, `install`, `` `tools/release verify` ``) within that entry only,
  never within a named section and never across the whole file.
- FR2 — The check is a function that takes a CHANGELOG path, so the suite can run it against
  fixtures the test builds as well as against `$ROOT/CHANGELOG.md`.
- FR3 — If zero entries match the locator, or more than one does, the check fails with a message
  that says which case it is. It never runs the phrase loop over an empty or ambiguous selection.
- FR4 — A guard file, `tests/changelog-entry-guards.test.sh` (named in `expects:`; `develop` may
  rename it), fails on any line in a `tests/*.test.sh` file that names the repo's own
  `CHANGELOG.md` (`$ROOT/CHANGELOG.md` or a literal repo-root path) together with `Unreleased`.
  It reports `file:line`, and it takes the directory to scan as an argument so a fixture can
  exercise it. Fixture CHANGELOGs a test builds are out of its reach by construction.
- FR5 — The new file carries the announce-on-abort block and the `TALLIED=1` line that
  `tests/abort-announce.test.sh` requires (0169).

## Non-functional requirements

No row applies. This is a test-only change in a repo with no runtime: no input, no data, no
surface, no schema, no dependency. A release note for it is `tools/release`'s concern at bump time
(`--no-behaviour-change` if nothing else ships alongside it), not this ticket's.

## Acceptance criteria

- [ ] AC1 — Given HEAD's `CHANGELOG.md`, with `## Unreleased` empty and the 0182 entry under `## 0.9.44`, when `tests/backlog-location.test.sh` runs, then it exits 0 and its AC9 lines report all five phrases found. Red: the file as it stands at `b63e23c` (5 failed).
- [ ] AC2 — Given two fixture CHANGELOGs built inside `tests/backlog-location.test.sh`, one with the 0182-shaped entry under `## Unreleased` and one with it under `## 9.9.9 — 2099-01-01`, when the AC9 function runs against each, then both pass. Red: restoring `section … "Unreleased"` as the locator reds the version-heading fixture.
- [ ] AC3 — Given a fixture whose 0182-shaped entry lacks one of the five phrases, and a **different** entry in the same fixture that does carry it, when the AC9 function runs, then it fails and names that phrase, once for each of the five phrases in turn. Red: a locator that searches the whole file instead of one entry stays green, because the phrase sits in the other entry.
- [ ] AC4 — Given a fixture with no matching entry, and another with two, when the AC9 function runs, then each fails and its message says "no entry" or "more than one entry" respectively. Red: dropping the count check makes the two-entry fixture pass.
- [ ] AC5 — Given a fixture tests directory holding one file with the line `UNREL="$(section "$ROOT/CHANGELOG.md" "Unreleased")"`, when `tests/changelog-entry-guards.test.sh` scans it, then it fails and names that `file:line`. Given the repo's real `tests/` after the fix, it passes. Red: the fixture line itself, which is the form `b63e23c` broke.
- [ ] AC6 — Given the new guard file, when `tests/abort-announce.test.sh` runs, then it passes with that file counted. Red: deleting the abort block from the new file.

## QA plan

- **Why that level:** `unit` runs the whole shell suite, which is this repo's only runner. The
  change is a guard, and the full suite proves that the baseline red is gone and that no other
  file depended on the old locator.
- **Specific checks:** run `unit_by_file` (`config.yml`) so a red elsewhere cannot mask this one.
  Apply each AC's named mutation and watch the stated case go red. Confirm
  `tests/backlog-location.test.sh` reports `0 failed` at the built HEAD.

## Out of scope

- **Do not edit `CHANGELOG.md`.** Moving the 0182 entry back under `## Unreleased` would turn the
  guard green until the next release and repeat this bug. The entry is right where it is.
- The install-before-migrate gap that 0182's QA evidence publishes: the guard's `install` also
  matches "installed beside the others". That is 0182's recorded, accepted gap, and FR1 keeps the
  same five phrases.
- Prose in `queue`, `develop` or the item template telling authors to assert an entry rather than
  a section. FR4 enforces the rule, and prose would be a second copy.
- `tools/release`'s promotion behaviour. It is correct and guarded by 0041 AC13.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-10-27 (queue) — Minted at the request of sprint run-20261027T185815Z, which found the red
  baseline at `b63e23c` and asked for the row at rank 1. **Routed `next: develop`:** there is no
  surface and no open decision. The entry's location under a version heading is fact, and the fix
  is a locator change plus a guard. **Ranked row 1:** this is Tier 1. Every session's whole-suite
  gate reads red on someone else's account, and the release gate is blocked. See `RANKING.md`,
  "2026-10-27 - 0221 placed at row 1".
- Queue only: nothing was fixed in this session, by instruction.
