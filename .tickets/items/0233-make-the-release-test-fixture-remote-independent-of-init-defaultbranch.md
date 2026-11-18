---
id: "0233"
title: Make the release test's fixture remote independent of init.defaultBranch
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual: AC4 — `tests/release.test.sh` run on a real macOS machine, the author
size: s
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0084", "0228"]
expects:
  - tests/release.test.sh
ac_digest: AC1=bb90bcd9 AC2=20fb93e8 AC3=9aa29743 AC4=73c58991
claimed_by: "766c"
claimed_at: 2026-11-18T14:03:25Z
touches:
  - tests/release.test.sh
slice:
---

## Problem

`tests/release.test.sh` aborts on this Linux container at `cab450d` (and already did at `a118a42`,
before 0231 was claimed), at the 0084 NFR git case:

```
0084 NFR git — a checkout behind the remote is reported, not resolved
warning: remote HEAD refers to nonexistent ref, unable to checkout
error: pathspec 'README.md' did not match any file(s) known to git

ABORTED before the tally: 23 passed, 0 failed so far (exit 1)
```

Cause, from the fixture: the checkouts are created with an explicit branch
(`git init -q -b main "$CO"`, line 80; `"$CO2"`, line 335) but the bare remotes are not
(`git init -q --bare "$REMOTE"`, line 88; `"$REMOTE2"`, line 342). A bare repo's `HEAD` then names
whatever `init.defaultBranch` resolves to — here unset, so git 2.43's built-in `master` — while
only `main` is ever pushed. `git clone "$REMOTE" "$OTHER"` (line 261) follows `HEAD` to a branch
that does not exist, checks out nothing, and the `commit -- README.md` on line 264 has no such
file. Under `set -eu` the file aborts there, so **every case after line 259 never runs** —
including 0084's AC5 and the 0041 `CLAUDE.md` phrase checks below it. It passes on a machine whose
global git config sets `init.defaultBranch=main`, which is presumably why it shipped green.

Provenance: the cases are 0084's; the request cites `e1dabce` (0228) as the last touch. This
checkout is shallow (`git rev-parse --is-shallow-repository` = `true`, graft boundary `db52fd7`),
so `git log` here cannot confirm either commit.

## Functional requirements

- FR1 — Every fixture repository `tests/release.test.sh` creates and later clones or pushes to has
  a `HEAD` naming the branch the fixture pushes, whatever `init.defaultBranch` the running user's
  git config sets or leaves unset.
- FR2 — The file runs to its tally with 0 failed on the Linux container and on macOS; no case is
  removed, skipped or weakened to get there.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Dependencies | The fixture stays on flags git already supports here (`init -b`, available since git 2.28; the container has 2.43); no git version floor is raised | AC1 reds if a flag the container's git lacks is used | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `tests/release.test.sh` at the fix commit on the Linux container, when it runs
  with the container's own git config (`init.defaultBranch` unset), then it prints its tally (no
  `ABORTED`) with 0 failed, and the "0084 NFR git — a checkout behind the remote is reported, not
  resolved" cases print `ok`. Red: revert line 88 to `git init -q --bare "$REMOTE"` and the run
  aborts with the `remote HEAD refers to nonexistent ref` output quoted in *Problem*.
- [ ] AC2 — Given the same file, when it runs with `GIT_CONFIG_GLOBAL` pointing at a file setting
  `init.defaultBranch=master`, and again at one setting `init.defaultBranch=main`, then both runs
  print their tally with 0 failed. Red: the same revert reds the `master` run while the `main` run
  stays green — the pair is what tells a config-independent fixture from one that happens to match.
- [ ] AC3 — Given the same file, when the run completes, then the cases after line 259 at
  `cab450d` — "0084 AC5 …" and "0041 — CLAUDE.md says what to do when the bump refuses …" — each
  appear in the output. Red: any abort before them drops them from the output.
- [ ] AC4 — Given a real macOS machine, when `tests/release.test.sh` runs, then it prints its tally
  with 0 failed. Manual — see `qa_manual:`.

## QA plan

- **Why that level:** the defect is in a `tests/*.test.sh` fixture, run by the `unit` command in
  `.tickets/config.yml`.
- **Specific checks:** `tests/release.test.sh` three times on the container — own config,
  `GIT_CONFIG_GLOBAL` with `master`, with `main` (AC1–AC3); the line-88 revert shown red under the
  `master` and own-config runs; then `unit_by_file` to confirm no other file changed state. AC4 by
  the author on macOS.

## Out of scope

- `tools/release` itself: nothing in the evidence shows the script is wrong, only its fixture.
- `tests/sprint.test.sh`'s four failures — 0232.
- Pinning `init.defaultBranch` for the whole suite or the repo's own config; the fix is per fixture.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-11-18 — Filed by `queue` at the user's request alongside 0232 as the repair-first rows of
  sprint `run-20261118T074205Z`. Separate row because the cause, file and outcome are separate.
- 2026-11-18 — `next: develop`: no decision and no surface; the fixture's intended branch is
  already stated by its own `git init -b main` checkouts.
- 2026-11-18 — `close_by: verify`: AC4 is a manual macOS observation.
