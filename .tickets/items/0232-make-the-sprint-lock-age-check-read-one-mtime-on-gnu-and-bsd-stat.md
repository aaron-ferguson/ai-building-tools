---
id: "0232"
title: Make the sprint lock-age check read one mtime on GNU and BSD stat
type: bug
next: verify
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
claimed_by: "95c4"
claimed_at: 2026-11-19T00:57:10Z
touches:
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

- [x] AC1 — Given `tests/sprint.test.sh` at the fix commit on Linux (GNU `stat`), when it runs, then
  the AC25 cases "an aged lock is classified aged…" and "a lock taken a moment ago is classified
  fresh…" print `ok`, and the tally reports 0 failed. Red: restore line 801's
  `stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK"` and both AC25 cases print the
  `Illegal number` FAIL quoted in *Problem*.
- [x] AC2 — Given the same run, when the 0165 AC1/AC2 case runs its clean and injected copies, then
  both print `ok` with no edit to the 0165 case itself. Red: the same restoration of line 801 reds
  0165 AC2 with "the clean copy was not green".
- [x] AC3 — Given the BSD-semantics `stat` shim of FR3 first on `PATH`, when the extracted block runs
  against the aged (mtime 2026-01-01) and fresh fixtures, then it prints `aged <n>` and `fresh <n>`
  respectively, each `<n>` a bare integer. Red: a block calling `stat -c %Y` unguarded (GNU-only)
  reds this case under the shim; the original `stat -f … || stat -c …` form reds AC1 under GNU —
  so no single-platform form passes both.
- [x] AC4 — Given a real macOS machine, when `tests/sprint.test.sh` runs, then the tally reports 0
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

## Waiting on

- **The author, on a real macOS machine (BSD `stat`):** check out a commit at or after `9d261dc`
  and run `tests/sprint.test.sh`. AC4 clears when the last line reads `<n> passed, 0 failed, …`.
  Then tick AC4 and close from a `verify` session with `./close` and the CHANGELOG `--note` proposed in
  *Notes & decisions* (build note). That note discharges the Documentation NFR row; `## Unreleased`
  is still empty. AC1–AC3 are cleared on Linux, see *QA evidence*. Nothing needs deploying: the check
  is a local test run.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**AC4 2026-11-18 (verify, token 95c4): PASS on real macOS (Darwin, BSD `stat`).** The author's Mac, `main` at `e7b40bb` (merge of the cloud branch, includes the fix): `tests/sprint.test.sh` → `388 passed, 0 failed, 0 skipped`. Whole suite green on the same commit. The author approved the close.

**Verdict 2026-11-18 (verify, token fcf2): AC1–AC3 PASS on Linux; AC4 is a manual check → `waiting`.**
Not advisory: `git status --porcelain` printed nothing at Step 2, so the dirty set was empty
and its intersection with the evidence set was empty too.

Conventions: `../ai-building-conventions` (resolved from `.tickets/config.yml` `conventions.path`)
Command (`unit_by_file`, verbatim): `for t in tests/*.test.sh; do "$t" || true; done`, with each file's output
redirected separately. The fail-fast `unit` line would stop at the known foreign red.
Copy executed: the repo checkout at `9d261dc`, not the plugin install. The test extracts the block from
`skills/sprint/SKILL.md` in the repo.
AC digest: `./next --ac-digest 0232 --check` → `0232: ac_digest matches`.

Suite at `9d261dc`: 43 of 44 files exit 0. `tests/sprint.test.sh` → `389 passed, 0 failed, 0 skipped`.
`tests/release.test.sh` → `ABORTED before the tally: 23 passed, 0 failed so far (exit 1)`. That is the
dispatch's baseline red at `cab450d`, owned by 0233. Neither this diff nor its evidence set touches
that file. Reported as unattributed to this ticket, and it closes nothing here.

Clause table and evidence:

| AC / NFR | Clause | Checked by | Result |
|---|---|---|---|
| AC1 | Given `tests/sprint.test.sh` at the fix commit on Linux (GNU `stat`) | Host here is Linux with GNU coreutils `stat`. The run used `9d261dc`, whose `skills/sprint/SKILL.md:801` reads `mtime=$(stat -c %Y "$LOCK" 2>/dev/null \|\| stat -f %m "$LOCK")` | holds |
| AC1 | AC25 "aged…" and "fresh…" print `ok` | `tests/sprint.test.sh` output: `ok   an aged lock is classified aged…` and `ok   a lock taken a moment ago is classified fresh…` | ok |
| AC1 | tally reports 0 failed | `389 passed, 0 failed, 0 skipped` | ok |
| AC1 | Red: restore the original line → both print `Illegal number` | **M1** (I ran it): line 801 → `stat -f %m … \|\| stat -c %Y …`. Output: `FAIL AC25 — …aged; it printed [/tmp/…/agecheck.sh: 5: Illegal number:   File: ".tickets/.lock"` and the same for fresh; `385 passed, 4 failed, 0 skipped` | red as specified |
| AC2 | 0165 clean and injected copies print `ok` | `ok   a forced failure names its case within the last 5 lines of the run`, `ok   a green run prints no re-print block`, `ok   and its tally line keeps its shape…` | ok |
| AC2 | with no edit to the 0165 case | `git diff cab450d..HEAD -- tests/sprint.test.sh` has one hunk (`@@ -1298,6 +1298,44 @@`, additions only) and 0 lines mention 0165 | holds |
| AC2 | Red: same restoration → "the clean copy was not green" | M1: `FAIL 0165 AC2 — the clean copy was not green (381 passed, 2 failed, 2 skipped)…` | red as specified |
| AC3 | Given the BSD shim of FR3 first on `PATH` | The shim at `tests/sprint.test.sh` ~1308–1320 handles `-f %m <path>` only. Any other option prints `stat: illegal option` to stderr and exits 1 with nothing on stdout. The block runs under `PATH="$BSDBIN"` (shim + `sh date sed`) | holds |
| AC3 | aged fixture → `aged <n>`; fresh → `fresh <n>` | `ok   0232 AC3 — …aged lock is classified aged with a bare integer age`, and the same line for fresh | ok |
| AC3 | each `<n>` a bare integer (two fixtures differ in age) | **M3** (I ran it): `echo "aged ${age}s" \|\| echo "fresh ${age}s"`. Output: `FAIL 0232 AC3 — …printed [aged 27763952s]` and `…[fresh 0s]`, 386/3. The host AC25 cases stayed green, because they only grep for the word. The shim cases are the integer guard | red |
| AC3 | Red: GNU-only `stat -c %Y` reds under the shim | **M2** (I ran it): line 801 → `mtime=$(stat -c %Y "$LOCK")`. Output: `FAIL 0232 AC3 — …printed [stat: illegal option -- c` for aged and fresh; 385/4 | red as specified |
| AC3 | the original form reds AC1 under GNU, so no single-platform form passes both | M1 above | holds |
| AC4 | real macOS: tally 0 failed | **Not run.** This container is Linux and no evidence was invented. `qa_manual:` names the author → `## Waiting on` | **open** |
| NFR Dependencies | only POSIX `sh` and the platform `stat` | **M4** (I ran it): line 801 → `mtime=$(perl -e 'print((stat shift)[9])' "$LOCK")`. Output: `FAIL 0232 NFR — the lock-age block reaches for perl/python/gdate…` and both AC3 shim cases `perl: not found`; 384/5 | guarded, holds |
| NFR Documentation | `## Unreleased` gains the Linux line | `CHANGELOG.md` `## Unreleased` is empty. Develop deferred the line to the close's `--note`, and this pass does not close | **open until close**, guarded by `tools/release`'s refusal on an empty Unreleased |

Mutations ran on committed `HEAD` (`9d261dc`). Each one used `awk`/`sed` on `skills/sprint/SKILL.md` and
showed a non-empty diff on line 801 (M3: line 803). Each was restored with `git checkout -- skills/sprint/SKILL.md`
alone. Control after all four: `389 passed, 0 failed, 0 skipped`, and `git status --porcelain` was empty.

Step 4: the change makes no new state reachable. The output shape and the classification are unchanged,
and the supervisor still neither takes nor breaks the lock. The diff touches no auth, data, log or egress
path, so neither the Security nor the Privacy pass applies. Always-on (`CONVENTIONS_CORE.md`): the bug fix
had its failing guard first (red at `cab450d`, quoted in *Problem*). The commits are atomic and in the
imperative. A failure still surfaces: if both `stat` forms fail, the second's stderr reaches the output
and the arithmetic errors. Nothing is swallowed.

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
- 2026-11-18 — **Build (develop, token ca6a; commits 6817272, 206451f).** Fix: the block's line
  is now `mtime=$(stat -c %Y "$LOCK" 2>/dev/null || stat -f %m "$LOCK")` (GNU form first). Why
  that order is safe on both: BSD `stat` rejects `-c` with usage on stderr and **nothing on stdout**,
  so the `-f %m` fallback is the only output. The old order was unsafe because GNU `stat -f`
  prints filesystem stats to stdout before it fails. Output shape unchanged (FR2).
  Test (`tests/sprint.test.sh`, after the AC25 no-lock case): a BSD-semantics `stat` shim
  (`-f %m <path>` → epoch mtime read through the host stat; any other option → exit 1, stderr
  only). It runs on a PATH holding only `stat`, `sh`, `date` and `sed`, so a block that calls an
  unlisted tool fails there (NFR Dependencies), plus a `perl|python|gdate` grep over the extracted
  block. The shim cases need the **whole** output to be exactly one `aged <n>` / `fresh <n>` line.
  The first form only needed one matching line. Under M2 it let `aged` pass, because the shim's
  stderr sat above a matching line. Tightened in 206451f.
  Mutations, **run** on committed state and restored with `git checkout`, control green after each:
  - M1, the original line put back: AC25 aged and fresh FAIL `Illegal number`, plus 0165 AC1/AC2
    FAIL; 385/4. Matches AC1 and AC2.
  - M2, GNU-only `mtime=$(stat -c %Y "$LOCK")`: both 0232 AC3 shim cases FAIL `stat: illegal
    option -- c`, plus 0165 AC2; 385/4. Matches AC3.
  - Control: 389 passed, 0 failed, 0 skipped. The 0165 case was not edited (AC2).
  Whole-suite result at 206451f: see the next note. AC4 (real macOS) is the author's and was not run
  here. The shim's mtime read tries host `-c %Y` and then `-f %m`, so it should hold on macOS too
  (**reasoned**, not run).
  **CHANGELOG line left to `verify`'s `./close --note`**, per the CHANGELOG header (the NFR row is
  not an AC). Proposed: "The sprint supervisor's lock-age check now works on Linux: it reads the
  lock's mtime with GNU `stat -c %Y` first and falls back to BSD `stat -f %m`, where it used to
  error before deciding aged or fresh (0232)."
  `.tickets/claim 0232` without a token failed with `.tickets/claim: 102: xxd: not found`. Claimed
  by passing a token minted with `od -An -N2 -tx1 /dev/urandom | tr -d ' \n'`. A finding with the
  same root cause was already parked on 2026-11-18.
- 2026-11-18 — **Whole suite at 206451f, tree clean:** 43 of 44 `tests/*.test.sh` exit 0. The
  one exception is `tests/release.test.sh`, which ends with `error: pathspec 'README.md' did not
  match any file(s) known to git` / `ABORTED before the tally: 23 passed, 0 failed so far (exit
  1)`. That is the dispatch's stated baseline red at `cab450d`, owned by row 0233. This ticket
  changes neither that file nor anything it reads.
- 2026-11-18 — **Verify (token fcf2): AC1–AC3 pass, AC4 waiting → `next: verify, status: waiting`.**
  I re-ran every mutation in the build table myself (M1 and M2 matched what develop recorded) and added
  M3 (non-integer age) and M4 (perl dependency). All four reddened, and the control was green. AC4 is a
  real-macOS run, and `qa_manual:` names the author. This Linux container cannot produce that evidence,
  so the ticket is not closed and not sent back. No code is owed and the contract is not stale.
  `verify` resumes: when the author reports a macOS tally of 0 failed, tick AC4 and `./close` with
  develop's proposed `--note`. Nothing surprised this pass, so no finding was parked.
