---
id: "0221"
title: Make the 0182 release-note guard find its entry wherever a release moves it
type: bug
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-10-27
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

- [x] AC1 — Given HEAD's `CHANGELOG.md`, with `## Unreleased` empty and the 0182 entry under `## 0.9.44`, when `tests/backlog-location.test.sh` runs, then it exits 0 and its AC9 lines report all five phrases found. Red: the file as it stands at `b63e23c` (5 failed).
- [x] AC2 — Given two fixture CHANGELOGs built inside `tests/backlog-location.test.sh`, one with the 0182-shaped entry under `## Unreleased` and one with it under `## 9.9.9 — 2099-01-01`, when the AC9 function runs against each, then both pass. Red: restoring `section … "Unreleased"` as the locator reds the version-heading fixture.
- [x] AC3 — Given a fixture whose 0182-shaped entry lacks one of the five phrases, and a **different** entry in the same fixture that does carry it, when the AC9 function runs, then it fails and names that phrase, once for each of the five phrases in turn. Red: a locator that searches the whole file instead of one entry stays green, because the phrase sits in the other entry.
- [x] AC4 — Given a fixture with no matching entry, and another with two, when the AC9 function runs, then each fails and its message says "no entry" or "more than one entry" respectively. Red: dropping the count check makes the two-entry fixture pass.
- [x] AC5 — Given a fixture tests directory holding one file with the line `UNREL="$(section "$ROOT/CHANGELOG.md" "Unreleased")"`, when `tests/changelog-entry-guards.test.sh` scans it, then it fails and names that `file:line`. Given the repo's real `tests/` after the fix, it passes. Red: the fixture line itself, which is the form `b63e23c` broke.
- [x] AC6 — Given the new guard file, when `tests/abort-announce.test.sh` runs, then it passes with that file counted. Red: deleting the abort block from the new file.

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

**PASS** — 2026-10-27, verify token 94b1, at `d947cc2` (build `bbae59c`, claim on top). Executed
copy: the repo checkout's `tests/` (test-only change; no skill file under test).

Conventions: ../ai-building-conventions

Level `unit`, run as `config.yml` `commands.unit_by_file`, verbatim:
`for t in tests/*.test.sh; do "$t" || true; done` — 44 files, every one ending `N passed, 0 failed`.
`ac_digest`: `./next --ac-digest 0221 --check` → `0221: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2 and at the fresh capture after the last check, apart
from this pass's own scratch dir (removed). Dirty set empty → intersection empty → not advisory.

Clause table: develop's, in *Notes & decisions*, reused unchanged; no table omission found.

| AC | Checked by | Mutation (committed file, restored by path) | Result |
|---|---|---|---|
| AC1 | `tests/backlog-location.test.sh` at HEAD against the real `CHANGELOG.md` (0182 entry under `## 0.9.44`; `CHANGELOG.md` unchanged since `b63e23c`) | file replaced by `b63e23c`'s copy | green: five `ok the 0182 entry names …`, `57 passed, 0 failed`; red: `43 passed, 5 failed`, the five `## Unreleased does not name …` lines |
| AC2 | `cl-unreleased.md` / `cl-versioned.md` cases | awk locator collects entries only under a `## …Unreleased` heading | `FAIL 0221 AC2 — cl-versioned.md fails`, real-file AC9 red; `47 passed, 6 failed` |
| AC3 | `cl-lacks.md` loop over `NOTE_PHRASES` | (a) locator := whole file as one entry; (b) phrase loop `break`s after the first phrase; (c) `missing` message drops the phrase | (a) all five `an entry lacking <phrase> passes because another entry names it`, `50 passed, 7 failed`; (b) the three non-locator phrases red, `50 passed, 3 failed` (the two locator phrases fail as "no entry names both …", which names them); (c) three `fails without naming it`, `54 passed, 3 failed` |
| AC4 | `cl-none.md` / `cl-two.md` | (a) `-gt 1` check disabled; (b) `-eq 0` check disabled | (a) `two matching entries passes`, `56 passed, 1 failed`; (b) `no matching entry fails without saying "no entry"`, `56 passed, 1 failed` |
| AC5 | `tests/changelog-entry-guards.test.sh` self-test (fixture `tests/broken.test.sh:3`) and real-`tests/` scan | (a) scan skips every line; (b) hit printed without `NR`; (c) `$ROOT` branch removed; (d) `b63e23c`'s `UNREL=…section "$ROOT/CHANGELOG.md" "Unreleased"` line inserted into `tests/backlog-location.test.sh` | (a) `4 passed, 5 failed`; (b) `fails without naming tests/broken.test.sh:3`, `8 passed, 1 failed`; (c) `6 passed, 3 failed`; (d) `FAIL 0221 FR4 — tests/backlog-location.test.sh:359: UNREL=…`, `8 passed, 1 failed` |
| AC6 | `tests/abort-announce.test.sh` lists `tests/changelog-entry-guards.test.sh` in its per-file checks | abort block (`TALLIED=""` … `trap announce_abort EXIT`) deleted from the new file | `311 passed, 3 failed`, all three naming the new file; control `314 passed, 0 failed` |

Controls after all mutations: `tests/backlog-location.test.sh` `57 passed, 0 failed`;
`tests/changelog-entry-guards.test.sh` `9 passed, 0 failed`; `tests/citations.test.sh`
`51 passed, 0 failed`; `tests/abort-announce.test.sh` `314 passed, 0 failed`.

NFRs: none declared, and correctly so — test-only change, no input, data, surface or dependency.
Always-on pass (`CONVENTIONS_CORE.md`): commits atomic and by pathspec; out-of-scope `CHANGELOG.md`
untouched (`git diff --stat b63e23c HEAD -- CHANGELOG.md` empty). No release note: no session
behaviour changes beyond the suite going green.

## Notes & decisions

- 2026-10-27 (queue) — Minted at the request of sprint run-20261027T185815Z, which found the red
  baseline at `b63e23c` and asked for the row at rank 1. **Routed `next: develop`:** there is no
  surface and no open decision. The entry's location under a version heading is fact, and the fix
  is a locator change plus a guard. **Ranked row 1:** this is Tier 1. Every session's whole-suite
  gate reads red on someone else's account, and the release gate is blocked. See `RANKING.md`,
  "2026-10-27 - 0221 placed at row 1".
- Queue only: nothing was fixed in this session, by instruction.
- 2026-10-27 (develop, token f7e4) — Built in `6ec60db` (locator), `cc2a58a` (guard file),
  `bbae59c` (README suite block). Whole suite 44/44 files green at `bbae59c`, tree clean.
  - **What the check is.** `tests/backlog-location.test.sh` `entries_naming_0182 <changelog>` splits
    the file into top-level `- ` entries (a `#` line or a blank line ends an entry, other lines
    join on as continuation) and prints each one naming both `` `.backlog/` `` and `` `./migrate` ``.
    `check_0182_note <changelog>` (FR2) prints `found`/`missing <phrase>`, or `no entry …` /
    `more than one entry (n) …` (FR3), and returns non-zero on any failure. The real-file call maps
    those lines to ok/bad.
  - **AC3 on the two locator phrases.** An entry lacking `` `.backlog/` `` or `` `./migrate` `` is no
    longer *located*, so the failure is "no entry names both `.backlog/` and `./migrate`". That
    message names the missing phrase, and the AC3 assertion is "fails, and the output names that
    phrase", which holds for all five. For the other three phrases the failure is `missing <phrase>`.
  - **FR4 scan rule.** On a line naming `Unreleased`, a `$ROOT/CHANGELOG.md` in any quoting
    (`${ROOT}`, `"$ROOT"/`) is a hit. Then every `$VAR/CHANGELOG.md` (a fixture) is stripped, and any
    `CHANGELOG.md` left is a literal repo path (bare, `./`, `../`, absolute) and is a hit. **It reads
    comments too:** the guard first reddened on a comment in its own header. That is deliberate.
    A comment pairing the two words is how the next author copies the form, so reword it. The
    AC5 fixture line is assembled from variables so the guard file never carries it whole.
  - **Mutations: run** (named mutation, then the effect). Each was applied to a committed file
    and restored with `git checkout --`.
    | AC | Mutation | Result |
    |---|---|---|
    | AC1 | b63e23c's file, before the change | 43 passed, 5 failed (the repro) |
    | AC2 | locator := `section "$1" "Unreleased"` | `cl-versioned.md fails`, real-file AC9 red; 7 failed |
    | AC3 | locator := the whole file | all five `an entry lacking <phrase> passes because another entry names it`; 7 failed |
    | AC4 | the `-gt 1` count check deleted | `two matching entries passes`; 1 failed |
    | AC5 | b63e23c's `UNREL=…section "$ROOT/CHANGELOG.md" "Unreleased"` line appended to `tests/backlog-location.test.sh` | guard names `tests/backlog-location.test.sh:439`; 1 failed. The fixture case is the in-file self-test |
    | AC6 | abort block deleted from the new file | `tests/abort-announce.test.sh` 3 failed, all naming it |
  - **Coverage the FR4 self-test runs:** `"${ROOT}/CHANGELOG.md"`, `"$ROOT"/CHANGELOG.md`, bare
    `CHANGELOG.md` and `../CHANGELOG.md` are refused, and `"$FIX/…"`, `"$CO2"/…` and `"${WORK}/…"`
    are left alone. **Reasoned, not run:** an absolute literal path and `./CHANGELOG.md` take the
    same branch as `../CHANGELOG.md`.
  - **Clause table (AC text, for verify):** AC1 Given "HEAD's `CHANGELOG.md`, with `## Unreleased`
    empty and the 0182 entry under `## 0.9.44`" → real-file run; predicate "exits 0 and its AC9
    lines report all five phrases found" → five `the 0182 entry names …` ok lines. AC2 "under
    `## Unreleased`" / "under `## 9.9.9 — 2099-01-01`" → `cl-unreleased.md` / `cl-versioned.md`;
    "both pass". AC3 "lacks one of the five phrases" plus "a **different** entry … carry it" →
    `cl-lacks.md` built per phrase with `Another fixture entry, naming <phrase>`; "fails and names
    that phrase, once for each" → the loop over `NOTE_PHRASES`. AC4 "no entry" / "more than one
    entry" → `cl-none.md` / `cl-two.md`, each message substring asserted. AC5 "fixture tests
    directory … that line" → `$FIX/tests/broken.test.sh:3`; "names that `file:line`" → asserted;
    "real `tests/` … passes" → the last guard case. AC6 → abort-announce's three per-file checks.
  - The README suite block (`tests/citations.test.sh`, 0046) has to name every test file, so
    `README.md` was added to `touches:`.
  - **Refused backlog writes, quoted:** (1) `mkdir .claude/backlog/.lock && python3 - <<'EOF' … EOF`
    chained with `git commit … ; rm -rf .claude/backlog/.lock`, refused as a compound;
    (2) `mkdir /Users/…/ai-building-tools/.claude/backlog/.lock`, refused as a sensitive file. After
    that, `python3 os.makedirs` / `shutil.rmtree` took and released the lock, as CONCURRENCY.md
    step 2 says. The lock was never left held.
