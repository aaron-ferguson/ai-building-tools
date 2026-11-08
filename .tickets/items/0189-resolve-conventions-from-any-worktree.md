---
id: "0189"
title: Make the citations guard resolve the conventions path from a worktree outside the checkout's parent
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0180", "0083"]
expects:
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-10-28
---

## Problem

**`tests/citations.test.sh` goes red in a worktree that is not a sibling of the checkout, because
`config.yml`'s `conventions.path: ../ai-building-conventions` is resolved from the worktree root.**

Measured by verify 0180 (token eb65) at 9f0cf0c: `git worktree add --detach` under a temp directory
gave `45 passed, 1 failed` (`FAIL no conventions directory resolved from config.yml`); the checkout
and a sibling worktree (`../<name>`) both gave `46 passed, 0 failed`. 0180's sprint Step 1 baseline
runs the suite "in a throwaway worktree" without saying where. A baseline placed in a temp directory
therefore reports a red that no ticket owns, and *repair first* then mints a row for it.

## Functional requirements

- **FR1** — `tests/citations.test.sh` resolves a relative `conventions.path` against the main
  worktree's root (`git rev-parse --path-format=absolute --git-common-dir`, then its parent), so
  the result does not depend on where the worktree sits.
- **FR2** — Run from the checkout itself, the resolution is unchanged.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | The suite's verdict does not depend on the worktree's location | the test run from a worktree under a temp directory reports a failure the checkout does not | `testing-conventions.md` |

## Acceptance criteria

- [x] **AC1** — Given a detached worktree created under a temp directory, `tests/citations.test.sh` run
  there reports the same tally as in the checkout.
- [x] **AC2** — Given the checkout, the tally is unchanged from before the fix.

## QA plan

Unit: a guard that creates a detached worktree under `mktemp -d`, runs the test there, compares the
tally, and removes the worktree in the same run. Proved red against the current test first.

## Out of scope

- Whether sprint Step 1 should name a worktree location. With FR1 it no longer needs to.

## Notes & decisions

- 2026-09-25 — filed by retro from verify 0180's finding (token eb65). Of the two fixes the finding
  offered, this row takes the resolution fix. It removes the hazard for every caller, where a named
  location would only instruct one caller.
- 2026-10-27 — develop (token 0e85), built in 22f6966. `conventions_dir` now resolves a relative
  path against `main_worktree_of <root>`: the parent of `git rev-parse --path-format=absolute
  --git-common-dir` when `<root>` is the top of a git worktree, else `<root>` itself — so every
  authored fixture (temp dirs, not repos) resolves exactly as before. In the checkout the common
  dir is `.git`, whose parent is the checkout, so FR2 holds by construction.
- **QA-plan substitution.** The plan asks for a guard that runs the *whole file* inside the worktree
  and compares tallies. Written that way the nested run re-enters the same case (recursion), and runs
  HEAD's copy of the guard rather than the one under test. The guard instead drives
  `conventions_audit` — the only location-dependent check — on a real detached worktree under
  `$FIX` (a `mktemp -d`), and requires its SKIP/COUNT lines to equal the checkout's.
- Evidence (run): before the fix, the new case red — `FAIL 0189 AC1 — the temp-directory worktree
  resolved no conventions directory: SKIP  no conventions directory resolved from config.yml`,
  `51 passed, 1 failed`. After: checkout `52 passed, 0 failed`; whole file run inside a detached
  worktree under `mktemp -d` at 22f6966: `52 passed, 0 failed` (AC1). AC2: the 51 pre-existing
  checks in the checkout pass unchanged. Whole suite green at 22f6966, tree clean.

## QA evidence

verify, token c480, 2026-10-27, at fff95d9 (build 22f6966). **PASS.**

Conventions: ../ai-building-conventions
Level: `qa_level: unit` (frontmatter; the QA plan agrees). Command, verbatim from `commands.unit_by_file`:
`for t in tests/*.test.sh; do "$t" || true; done` — 44 files, every one `0 failed`;
`tests/citations.test.sh: 52 passed, 0 failed`. Copy executed: the repo copy of `tests/citations.test.sh`
(a test, not a skill, so the plugin install is not in play). `ac_digest absent — unverifiable`
(`./next --ac-digest 0189 --check`).

Tree: `git status --porcelain` empty at Step 2 and again after the last check, so the dirty set is
empty and the intersection with the evidence set is empty — not advisory.

Clause table (no prior table in the build notes; this one is the first):

| AC | Clause | Row |
|---|---|---|
| AC1 | Given | a detached worktree created under a temp directory |
| AC1 | predicate | `tests/citations.test.sh` run there reports |
| AC1 | object | the same tally as in the checkout |
| AC2 | Given | the checkout |
| AC2 | predicate / object | the tally is unchanged from before the fix |

| Check | How | Result |
|---|---|---|
| AC1 | Literally: `git worktree add --detach` under `mktemp -d` at HEAD, ran `tests/citations.test.sh` there | `52 passed, 0 failed`, identical to the checkout's `52 passed, 0 failed` ✓ |
| AC1 mutation (AC altitude) | in that worktree's own copy, `base="$(main_worktree_of "$root")"` → `base="$root"` (diff 1+/1-) | `FAIL no conventions directory resolved from config.yml`, `FAIL 0189 AC1 — the temp-directory worktree resolved no conventions directory`, `50 passed, 2 failed`; restored by path → `52 passed, 0 failed` |
| AC1 permanent guard | the same mutation in the checkout's `tests/citations.test.sh` | `FAIL 0189 AC1 — …`, `51 passed, 1 failed`; restored by path, control `52 passed, 0 failed` |
| AC2 | checkout, HEAD copy vs the pre-fix copy (`git show 22f6966^:tests/citations.test.sh`), `ok` lines diffed | pre `51 passed, 0 failed`, post `52 passed, 0 failed`; `every conventions filename resolves — 36 mentions, 36 checked` on both; the only other differing line is `every item-ID citation resolves — 219 ids, 291 cited` → `292 cited`, the new code citing 0189 itself, not a resolution change ✓ |
| AC2 mutation | `dirname -- "$common"` → `dirname -- "$(dirname -- "$common")"` (breaks the checkout's own resolution) | `FAIL no conventions directory resolved from config.yml` plus the 0189 case, `50 passed, 2 failed`; restored, `52 passed, 0 failed` |
| NFR Testing | the row's own red: the guard run from a temp-directory worktree against the reverted resolution | reddens (AC1 mutation row above) — guarded, not merely true ✓ |
| Always-on (`CONVENTIONS_CORE.md`) | diff read: no secrets, nothing written outside the repo, the worktree is removed under `$FIX` in the same run | holds |

Notes: develop's QA-plan substitution (driving `conventions_audit` in the worktree rather than
re-running the whole file) is sound — the literal whole-file run above covers what it skips.
Cosmetic: in `tests/citations.test.sh` the `conventions_dir` header comment now sits above
`main_worktree_of`'s, so the two functions' comments read stacked; no behaviour rests on it.
