---
id: "0232"
title: Make the sprint lock-age check read one mtime on GNU and BSD stat
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual: AC4 — `tests/sprint.test.sh` run on a real macOS machine (BSD stat), the author
size: s
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0040", "0089", "0165"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
ac_digest: AC1=fc0f67b8 AC2=577af61a AC3=e1b45118 AC4=f85bc0c4
claimed_by: "ca6a"
claimed_at: 2026-11-18T07:53:48Z
touches:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
slice:
---

## Problem

The supervisor's lock-age check in `skills/sprint/SKILL.md` (the fenced block at line 801 at
`cab450d`, introduced as 0040's AC25 when the skill was `skills/orchestrate/`) cannot produce a
number on Linux. The shipped form is:

```sh
mtime=$(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK")
age=$(( $(date -u +%s) - mtime ))
```

On GNU coreutils `-f` means `--file-system`, so `%m` is read as a **file operand**, not a format.
`stat` fails on `%m` (exit 1, stderr discarded) but has already printed the lock directory's
**filesystem stats to stdout**; the `|| stat -c %Y` fallback then runs and appends the real mtime.
`mtime` holds several lines, and the arithmetic dies. Observed on this Linux container (git 2.43,
`uname -s` = Linux):

```
$ stat -f %m <dir> >/dev/null 2>&1; echo $?
1
$ v=$(stat -f %m <dir> 2>/dev/null || stat -c %Y <dir>); printf '%s\n' "$v"
  File: "<dir>"
    ID: c6348da9b9e3889a Namelen: 255     Type: ext2/ext3
Block size: 4096       Fundamental block size: 4096
...
1794988242
```

(The request that filed this said `stat -f` "exits 0, so the fallback never runs". The observation
above corrects that: the fallback does run; the defect is the first command's stdout, which `||`
does not discard. Either way the captured value is not a number.)

So a supervisor on Linux that finds `.tickets/.lock` gets neither `aged` nor `fresh` — the block
the skill tells it to run errors out, which is the decision AC25 exists to make. Every Linux
machine running `/sprint` inherits it; macOS (BSD stat, where `-f %m` is the format) is unaffected,
which is why it shipped green.

`tests/sprint.test.sh` extracts and runs that exact block (around line 1254–1295), so the file is
red on Linux at `cab450d`, and already was at `a118a42`, before 0231 was claimed:

```
  FAIL AC25 — the prescribed check did not call a lock from 2026-01-01 aged; it printed [/tmp/tmp.neqw2wK7wu/agecheck.sh: 5: Illegal number:   File: ".tickets/.lock"
  FAIL AC25 — the prescribed check did not call a just-taken lock fresh; it printed [/tmp/tmp.neqw2wK7wu/agecheck.sh: 5: Illegal number:   File: ".tickets/.lock"
  FAIL 0165 AC1 — the forced FAIL line is not in the last 5 lines; a pass filtering to the tally cannot attribute the failure, which is how a real red gets waved off as the flake
  FAIL 0165 AC2 — the clean copy was not green (378 passed, 2 failed, 2 skipped), so 'a green run prints no block' went untested; this file is red for a reason named above, not by 0165
382 passed, 4 failed, 0 skipped
```

The two 0165 failures are consequences: 0165's case runs a clean copy of the file and requires it
green (AC2), and with the two AC25 FAILs re-printed above the tally the injected FAIL is pushed out
of the last five lines (AC1). They need no change of their own.

Provenance: the request named `db52fd7` (*Claim 0089*) as the introducing commit. This checkout is
**shallow** (`git rev-parse --is-shallow-repository` = `true`) and `db52fd7` is its graft boundary,
so every file's history ends there; it is not evidence of where the line came from. The owning
ticket is 0040 (AC25, QA evidence rows "aged lock escalates" / "younger lock waits").

## Functional requirements

- FR1 — The lock-age block in `skills/sprint/SKILL.md` (the shipped artifact, not any local copy)
  assigns `mtime` exactly one integer — the lock directory's modification time in epoch seconds —
  under GNU coreutils `stat` and under BSD `stat`, and nothing else reaches it.
- FR2 — The block still classifies a lock older than `lock_stale_seconds` as `aged <age>`, a younger
  one as `fresh <age>`, and prints nothing when there is no lock; its output shape is unchanged, so
  the supervisor prose around it needs no edit.
- FR3 — `tests/sprint.test.sh` exercises the extracted block under a BSD-semantics `stat` as well as
  the host's, so a regression on the platform the suite is *not* running on reds there. The BSD
  stand-in is a fixture shim on `PATH` that implements only what BSD `stat` does with the forms the
  block uses (`-f %m <path>` prints the epoch mtime; `-c` is an illegal option, exit 1, nothing on
  stdout) — pinned in the test, not reimplementing the block under test.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Dependencies | The block uses only POSIX `sh` and the platform `stat`; no new tool (`gdate`, `perl`, `python3`) is introduced to read an mtime | The AC3 shim run reds if the block calls a tool the shim `PATH` does not provide; a `grep -E 'perl\|python\|gdate'` over the extracted block in the test reds on its introduction | `dependency-conventions.md` |
| Documentation | `CHANGELOG.md` `## Unreleased` gains one line: the sprint lock-age check now works on Linux | `tools/release` refuses a bump on an empty `## Unreleased` | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `tests/sprint.test.sh` at the fix commit on Linux (GNU `stat`), when it runs, then
  the AC25 cases "an aged lock is classified aged…" and "a lock taken a moment ago is classified
  fresh…" print `ok`, and the tally reports 0 failed. Red: restore line 801's
  `stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK"` and both AC25 cases print the
  `Illegal number` FAIL quoted in *Problem*.
- [ ] AC2 — Given the same run, when the 0165 AC1/AC2 case runs its clean and injected copies, then
  both print `ok` with no edit to the 0165 case itself. Red: the same restoration of line 801 reds
  0165 AC2 with "the clean copy was not green".
- [ ] AC3 — Given the BSD-semantics `stat` shim of FR3 first on `PATH`, when the extracted block runs
  against the aged (mtime 2026-01-01) and fresh fixtures, then it prints `aged <n>` and `fresh <n>`
  respectively, each `<n>` a bare integer. Red: a block calling `stat -c %Y` unguarded (GNU-only)
  reds this case under the shim; the original `stat -f … || stat -c …` form reds AC1 under GNU —
  so no single-platform form passes both.
- [ ] AC4 — Given a real macOS machine, when `tests/sprint.test.sh` runs, then the tally reports 0
  failed. Red: a fix that only works under GNU `stat` (e.g. `stat -c %Y` alone) reds the AC25 cases
  there. Manual — see `qa_manual:`.

## QA plan

- **Why that level:** the defect and every check are in `tests/*.test.sh`, which is the `unit`
  command in `.tickets/config.yml`; no seam beyond the extracted shell block is crossed.
- **Specific checks:** `tests/sprint.test.sh` on the Linux container (AC1–AC3), its full tally; the
  restoration mutation for AC1/AC2 and the GNU-only mutation for AC3, each shown red then green;
  then `unit_by_file` to confirm no other file changed state. AC4 by the author on macOS.

## Out of scope

- `tests/release.test.sh`'s abort — its own row, 0233, a separate cause in a separate file.
- Any other `stat` use: at `cab450d` line 801 is the only `stat -f` / `stat -c` in `skills/`,
  `references/`, `tools/` and the backlog scripts.
- Changing `lock_stale_seconds`, the aged/fresh wording, or what the supervisor does with the verdict.
- Rewriting the 0165 case; it is red by consequence, and AC2 asserts it recovers untouched.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-11-18 — Filed by `queue` at the user's request as the repair-first row of sprint
  `run-20261118T074205Z`, not held under `retro` Step 4, because the user asked for it. Two rows,
  not one: this one changes a shipped skill instruction that is wrong on every Linux machine; 0233
  changes a test fixture only. Separate causes, files and outcomes, and either can close without
  the other.
- 2026-11-18 — `next: develop`: no open decision and no surface. The contract is "one integer on
  both `stat`s", discoverable by running it.
- 2026-11-18 — `close_by: verify`, not `develop`: AC4 is a manual macOS observation, so not every
  criterion is a committed assertion.
