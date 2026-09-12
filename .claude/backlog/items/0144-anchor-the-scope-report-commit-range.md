---
id: "0144"
title: Anchor the scope report's commit range to the claim commit for this ticket, not any commit carrying the token
type: bug
next:
status: done
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0049"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - .claude/backlog/close
  - .claude/backlog/handoff
  - tests/close.test.sh
  - tests/handoff.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-12
---

## Problem

**`close` and `handoff` find the claim commit that anchors the scope report with a bare token grep
over the whole history, so the first token reuse silently attributes another ticket's files to this
one.** Both scripts run
`git log --format='%H %s' | grep -F "[$TOKEN]" | tail -1` — every commit, any subject, oldest match
wins. Claim tokens are four hex characters and nothing checks one for reuse, so once a token repeats,
the *older* ticket's claim commit becomes the range start and every commit in between is read as this
ticket's work.

Reproduced in a throwaway repo: an ancient `Claim 0001 [abcd]` commit ahead of `Claim 0700 [abcd]`
made the close report `ancient/unrelated-a.ts ancient/unrelated-b.ts` as `0700`'s
touched-but-undeclared paths. No collision exists in this repo's history yet — no token has claimed
two tickets — which is exactly why nothing is red, and why the failure arrives as a confident,
specific, wrong report rather than as an error.

The scripts already know the id, so the precise anchor costs nothing:
`grep -E "^Claim $ID \[$TOKEN\]"`. The failure this produces — a report naming files the ticket never
touched — is the same failure `0106`'s own Problem section exists to prevent, which makes the current
anchor a hole in the feature that added it.

## Functional requirements

- **FR1** — Both scripts anchor the range to a commit whose subject matches the ticket id *and* the
  token, not the token alone.
- **FR2** — Where no such commit exists, the behaviour is the one the scripts have today for a missing
  anchor, unchanged — this row narrows a match, it does not add a refusal.
- **FR3** — The template and the installed copy change together, and the byte-for-byte comparison that
  already guards the shared scope block covers the new line.

## Non-functional requirements

- **Compatibility** — a history with no token collision produces byte-identical reports before and
  after. How this would red: a case capturing the report over a collision-free fixture and comparing
  it against the pre-change output.

## Acceptance criteria

- [x] AC1 — Given a fixture history with `Claim 0001 [abcd]` older than `Claim 0700 [abcd]`, and
  commits between them touching files the ticket never declared, when `close` runs for `0700`, then the
  scope report names none of those files. Red-making input: today's scripts, whose output is captured
  in the Problem section.
- [x] AC2 — Given the same fixture, when `handoff` runs for `0700`, then the same holds. Red-making
  mutation: fixing `close` and not `handoff`, which is the shape the shared-block comment warns about.
- [x] AC3 — Given a fixture history with no collision, when `close` runs, then the report is identical
  to the one today's script produces. Red-making mutation: anchoring on the id alone, which re-breaks
  a ticket whose claim was superseded.
- [x] AC4 — Given a ticket with no claim commit at all, when `close` runs, then it behaves as it does
  today. Red-making mutation: making the narrower match fatal.
- [x] AC5 — Given `tests/close.test.sh`'s byte-for-byte comparison of the scope block in `close` and
  `handoff`, when it runs, then it passes. Red-making change: editing one script and not the other.
- [x] AC6 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing the templates and not the installed copies.

## QA plan

- **Why this level:** `unit` — both scripts have large existing suites that already scaffold fixture
  repositories with claim commits, which is all the collision case needs.
- **Specific checks:**
  - Build the collision fixture first and confirm today's scripts produce the wrong report, so AC1's
    red is observed rather than assumed.
  - Run `tests/close.test.sh`, `tests/handoff.test.sh` and
    `tests/backlog-scripts-installed.test.sh` individually, then the whole suite with `|| true`.

## Out of scope

- Making tokens collision-proof, or checking a token for reuse at claim time. A longer token is a
  different decision and `0049` owns what a token guarantees.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0106` that marked itself NEEDS A ROW. The
  reproduction and the exact replacement grep are the park's, verified in a throwaway repo by that
  session.

### 2026-09-11 — Built (token 7af7)

**The replacement grep the park specified does not work as written, and the reason is the log
format rather than the idea.** The park gives `grep -E "^Claim $ID \[$TOKEN\]"`, but the anchor
reads `git log --format='%H %s'`, so every line begins with a 40-character SHA and the subject never
sits at the start. Anchored as specified the match is empty for every ticket, which fails the way
FR2 forbids — the scripts would silently stop reporting scope at all, and the existing
`no claim commit for this token` cases would go on passing because they assert exactly that silence.
Shipped as `^[0-9a-f]+ Claim $ID \[$TOKEN\]`, which keeps the park's precision and the format.

**Both halves of the anchor are load-bearing, and one case cannot show it.** AC1's fixture (a token
reused across two ids) reds a token-only match and is green under an id-only one; AC3's (one id
claimed twice under different tokens) is the mirror. A single case would leave whichever half it did
not exercise free to regress unnoticed. Proved by mutation: replacing the anchor with
`^[0-9a-f]+ Claim $ID ` gives `237 passed, 3 failed` — AC3's two assertions plus
`tests/close.test.sh`'s byte-for-byte block comparison, which is `0106` FR3's guard correctly
objecting that only one of the two copies moved. Control after restore: `240 passed, 0 failed`,
worktree clean.

**AC5's byte-for-byte comparison proves the two blocks MATCH, never that either is right** — two
identically wrong blocks satisfy it, which is why AC2 asserts the narrowed anchor against `handoff`
directly rather than relying on the comparison to carry it across.

**The mutation ran in a throwaway worktree, not in the checkout, because another session was
mid-mutation in the shared tree.** `pgrep` found a live mutate-and-`git checkout --` script from
another window. `develop` Step 5 says the session arriving second waits; a detached worktree at this
ticket's own commit is stronger than waiting and costs nothing here, since this suite is `/bin/sh`
with no `node_modules` to symlink. **One artefact to know about: `tests/citations.test.sh` fails in
such a worktree** with `no conventions directory resolved from config.yml`, because the conventions
repo is reached by a relative path that does not exist beside a temp checkout. It is green in the
real checkout (`46 passed, 0 failed`). A worktree is not a neutral place to run this project's whole
suite.

**A `perl -pi -e` substitution matched nothing and returned a clean pass**, which read as "the guard
is falsifiable and green" when it meant "nothing was mutated". Caught only by `git diff --stat`
printing an empty diff. Confirm a mutation landed before believing the run that follows it.

## QA evidence

Verified at a named commit in a detached worktree (`251d6e1`, `Claim 0144 [ac9e]`), not in the
checkout: two paths were dirty at Step 2 (`tools/harvest-usage.sh`, `tests/sprint-ledger.test.sh`,
both `0135`'s, since committed at `e5ce510`) and the declared `unit` command is a whole-project gate
that collects every foreign path. The worktree was taken beside the repo so `config.yml`'s
`conventions.path` still resolves — `tests/citations.test.sh` is green there (`46 passed, 0 failed`),
which the `0144` build notes record as failing in a worktree placed elsewhere.

**The harness runs `skills/queue/templates/*`, not `.claude/backlog/*`** (`tests/close.test.sh:25`,
`CLOSE_SRC`). Every mutation below was applied to the template, confirmed landed with
`git diff --stat` before the run, restored by path, and followed by the control.

| # | How it was checked | Result |
|---|---|---|
| AC1 | Mutation: anchor reverted to the bug's `grep -F "[$TOKEN]"` in all four copies, then `tests/close.test.sh` | **PASS** — reds `237 passed, 3 failed`: *the older ticket's first file is not charged to this one*, *nor the second of them*, *and the scope that does match is still reported*. AC3's assertions stayed green, so the token half is independently guarded |
| AC2 | The shape the AC names — template `close` left fixed, template `handoff` reverted to the token-only grep — then `tests/handoff.test.sh` and `tests/close.test.sh` | **PASS** — `handoff` reds `125 passed, 1 failed` (*the older ticket's file is not charged to this one*) and `close` reds `239 passed, 1 failed` on the shared-block comparison. Both halves of the "fix one, not the other" shape fire |
| AC3 | Mutation: anchor narrowed to the id alone (`^[0-9a-f]+ Claim $ID `) in both templates and both installed copies, then `tests/close.test.sh` | **PASS** — reds `238 passed, 2 failed`: *the superseded pass's file is not charged to this one*, *and this pass's own scope agrees*. AC1's assertions stayed green, so the id half is independently guarded |
| AC4 | Mutation: `[ -n "$claim_sha" ] \|\| return 0` made fatal (`exit 9`), then `tests/close.test.sh` | **PASS** — reds `191 passed, 49 failed`, the missing-anchor cases among them. The unchanged no-anchor behaviour is genuinely guarded, and the narrowed match is not fatal |
| AC5 | Mutation: template `close` moved and template `handoff` left alone, then `tests/close.test.sh`; separately `tests/backlog-scripts-installed.test.sh` under a copies-only mutation | **PASS** — `close and handoff carry an identical scope block` reds at `239 passed, 1 failed`; the installed-copy guard reds `35 passed, 2 failed` naming both scripts. Control: `240 / 0`, `126 / 0`, `37 / 0` |
| AC6 | `for t in tests/*.test.sh; do "$t" \|\| true; done` at `251d6e1`, each file run individually so a red can be attributed | **PASS for this ticket, with one named exception.** 28 of 29 files report `0 failed`. `tests/measurement.test.sh` reports `128 passed, 1 failed` on the privacy guard, over a home-directory path published in **`0052`'s** closed item file at line 294 — landed at `2be673f` (`Close 0052 [d3b6]`), present at every commit since, in no file this ticket touches and in nothing this verdict rests on. Already parked in `FINDINGS.md` by the `0144` build session, which correctly declined to write another ticket's item file. **No failure in the suite is attributable to this change** |
| NFR — Compatibility | All 152 `Claim <id> [<token>]` pairs in the real history resolved under both the old anchor and the new one, and the two results compared | **PASS** — zero divergence, and zero token reuse across ids, so no collision exists here yet. A collision-free history reports identically before and after, which is what the row asks |

**Conventions pass.** The diff adds no log field, analytics event or egress destination, so
`data-privacy-conventions.md`'s trigger does not fire on it; it touches no auth, credential or data
visibility, and no UI. It narrows a `grep` in a reporting path and creates no newly reachable state:
the only behaviour it can change is *not matching* where the bug matched, which is FR2's territory
and AC4's guard. Comments explain why, not what (`CONVENTIONS_CORE.md`, Code).

**Advisory:** not advisory. Step 2's dirty set was `tools/harvest-usage.sh` and
`tests/sprint-ledger.test.sh`; the verdict rests on `251d6e1`, where neither file's uncommitted state
existed. The intersection with the evidence set is empty.

**One correction to the build notes.** They record the id-only mutation as `237 passed, 3 failed`,
counting `tests/close.test.sh`'s byte-for-byte comparison among its reds. Applied consistently to
both copies it is `238 passed, 2 failed` — the block comparison stays green, because both blocks
moved together. `237 / 3` is the *one-copy* mutation, which is AC5's shape rather than AC3's. Both
measurements are real; the note merged them.
