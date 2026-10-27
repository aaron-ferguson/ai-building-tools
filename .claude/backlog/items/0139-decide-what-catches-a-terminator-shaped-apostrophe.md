---
id: "0139"
title: Decide what catches an apostrophe that lands where a legitimate awk terminator goes
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
ac_digest: AC1=6d585035 AC2=03a5c1bf AC3=2949833a AC4=1badbf48 AC5=5e27d9fe AC6=5cd77fe3
qa_manual:
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0077", "0089"]
expects:
  - tests/backlog-scripts-installed.test.sh   # the AC8 scanner
  - references/CONCURRENCY.md                 # The five scripts
claimed_by: "9a6f"
claimed_at: 2026-10-27T05:50:07Z
touches:
---
## Problem

**`0077`'s guard catches every apostrophe inside an `awk` comment and is blind to one placed where
a legitimate terminator goes — which is still a live break.**

Measured 2026-09-09 while verifying `0077` (token `4e31`). Insert a bare `'` at column 0 of
`skills/queue/templates/close:288`, the first body line of the `ac_counts` program, in both copies:

- `sh -n` accepts both copies — under `/bin/sh` here (bash 3.2.57) the file is valid.
- `tests/backlog-scripts-installed.test.sh` reports **37 passed, 0 failed**.
- `tests/close.test.sh` reports **115 passed, 86 failed**.

That is the same end state the two `0077` bounces named: a live broken `close` under a fully green
guard.

**Why the existing clause cannot see it.** The AC8 scanner reports a multi-line region whose closing
quote is *not* the first thing on its line bar whitespace and the block enders `)`, `}`, `]`, or
whose close is preceded inside the region by an `awk` comment start. An apostrophe at the head of a
body line satisfies neither test — it sits exactly where a real terminator sits, and there is no `#`
before it. The two clauses are correct; the shape is outside both by construction.

**Both global signals are silent, measured rather than assumed.** `sh -n` accepts, and the file
re-pairs: an independent tokeniser run to EOF over the mutated `close` reports `state=0 depth=0`,
identical to the clean file. So neither a parse check nor a whole-file quote-balance check can see
it either.

**What is already proved and must not be re-derived.** Every apostrophe position inside every `awk`
comment in the four scripts is caught — 1,298 insertions over the 16 comment-bearing lines inside
the 37 embedded programs, 1,288 of them by the AC8 scanner itself and 10 by `sh -n`, zero misses.
Sweeping a trailing comment, and an inserted comment line, across all 340 in-region lines in both
copies also gives zero misses. `0077`'s AC2 is met; this ticket is the residue outside it.

## Functional requirements

Decided 2026-10-25 (design, token `2ed8`): shape **E**, a same-line refinement of `A` with no
lookahead. See *Notes & decisions* for the measurement and what was rejected.

- **FR1 — what follows a terminator is shell.** The AC8 scanner reports a multi-line single-quoted
  region whose closing line, after the closing quote, carries anything other than: nothing (bar
  whitespace), a `)` immediately after the quote, or whitespace followed by a `"`. Every legitimate
  terminator in the five scripts takes one of those three forms today (`'`, `}')"`, `' "$item")"`,
  `' "$QUEUE" > "$tmp"`); a head-of-line apostrophe leaves the rest of an `awk` body line there
  instead (`'  /^## / { in_ac = ...`, `'in_ac {`).
- **FR2 — the invariant that makes FR1 exact.** The scanner also reports a line strictly inside a
  multi-line region whose first non-whitespace character is `"` or `)`. Those are the only body
  lines an apostrophe at their head would turn into a legitimate-looking terminator; none exists in
  the five scripts on 2026-10-25, so this costs no edit today and keeps it so.
- **FR3 — the report names the quote.** Both clauses report through the existing AC8 message (or
  one of the same shape): `file:opened`, the line the quote closed on, and its text, with the
  remedy — for FR2, that a body line may not begin with `"` or `)`, so rewrap or reorder it.
- **FR4 — the residue is written down.** `references/CONCURRENCY.md`, *The five scripts*, states the
  terminator rule once, beside the existing scan description, and names what stays uncaught: an
  apostrophe alone on a blank line inside a program, which is byte-identical to a bare terminator.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | Whichever shape wins is proved able to fail by the `close:288` column-0 mutation above, restored by the path mutated | `testing-conventions.md` |
| Dependencies | No new dependency: `shellcheck` stays out of scope, as it was for `0077` | `dependency-conventions.md` |
| Documentation | The chosen shape is stated once in `references/CONCURRENCY.md`, *The four scripts*, and the decision record says why the others were rejected | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/templates/close` with a bare `'` inserted at column 0 of the first body line of the `ac_counts` program (line 479 on 2026-10-25, `  /^## / { in_ac = ...`), in both copies, when `tests/backlog-scripts-installed.test.sh` runs, then it fails naming `close`, the line the program opened on and the line the quote closed it on; restored by the path mutated, it passes.
- [ ] AC2 — Given the same insertion after the line's leading whitespace instead of at column 0, when the suite runs, then it fails the same way.
- [ ] AC3 — Given every line strictly inside every multi-line single-quoted region of all five templates, with a `'` inserted at column 0 and, separately, after leading whitespace, when each mutant is checked by `sh -n` plus the AC8 scanner, then none passes both — the sweep is recorded in the QA evidence with its total and its count of misses, which is zero.
- [ ] AC4 — Given the five unmutated templates and their installed copies, when the suite runs, then FR1 and FR2 report nothing and the file is green.
- [ ] AC5 — Given a program body line in one copy changed to begin with `"` (after whitespace), when the suite runs, then it fails naming that line as a body line that may not begin with `"` or `)`; restored, it passes.
- [ ] AC6 — Given `references/CONCURRENCY.md`, *The five scripts*, when it is read, then it states that the closing line of a multi-line program carries only `)` or double-quoted arguments after the quote, and names the blank-line apostrophe as the shape the scan does not catch; and a guard in `tests/backlog-scripts-installed.test.sh` reds when either statement is removed.

## QA plan

- **Level:** unit — the deliverable is a guard clause in `tests/backlog-scripts-installed.test.sh`
  and the sentence it enforces.
- **Why this level:** the scanner runs over static files; every criterion is a mutation and a
  rerun of one suite. `close_by: verify` stays because AC3 is a sweep whose evidence is read, not a
  pass line.
- **Specific checks:** AC1 and AC2 are the `close:479` reproduction (the `0139` Problem's
  `close:288`, moved by later edits). AC3 is the sweep design ran on 2026-10-25 — see *Notes &
  decisions* for the harness shape and its numbers, which the post-change sweep must reproduce with
  the misses at zero. Mutate copies under a temp directory, never the templates in place.

## Out of scope

- Rewriting the four scripts to avoid embedded `awk`, and `shellcheck`. Both were ruled out by
  `0077` and neither has become cheaper.
- Anything about apostrophes inside `awk` comments. That is `0077`, closed and proved by sweep.

## Notes & decisions

- 2026-09-09 — Filed by `verify` (`4e31`) rather than bounced onto `0077`. `0077`'s AC2 names an
  apostrophe *inside an `awk` comment* and its Problem names prose comments; this shape is neither,
  and the remedy is a choice between three unequal designs rather than another clause. Bouncing it
  would have handed `develop` a research problem in place of a constraint.
- 2026-10-25 — **Decided (design, `2ed8`): shape E — check what follows a terminator's quote on the
  same line, plus an invariant on body-line heads that makes that check exact.** Measured, not
  argued: a sweep over all five templates inserted `'` at column 0 and after leading indentation of
  every line strictly inside every multi-line region — **1,162 mutants**. Today's guards: 824
  caught by the AC8 scanner, 318 more by `sh -n`, **20 missed by both** (all in `close`: the
  `ac_counts` body, lines 479–483, and the `rc_counts` body, 733–737). The `close:288` reproduction
  in the Problem is `close:479` now. A prototype of FR1 in the scanner caught **all 20, and reported
  nothing** on the five clean templates. No body line in the five scripts today begins with `"` or
  `)`, so FR2 is free now. The harness: extend `early_close`'s awk to print every multi-line region
  (open line, close line) rather than exiting on the first violation, and drive it from a
  `sh` loop over mutated copies under `/tmp`.
- **Rejected — B, the region-map fixture.** It catches all 1,162 by construction, but only with
  line spans: in the `close:479` mutant the region count and every opener are unchanged and only the
  `ac_counts` close line moves (486 → 479), so a line-free map misses it. A span map is a fixture
  every template edit moves, and the templates took 36 commits between 2026-09-09 and 2026-10-25 —
  a regenerate-on-every-edit step trains sessions to regenerate it blind, which is a guard that
  cannot fail.
- **Rejected — the opener-side check** (a multi-line region must open after `awk` or an
  assignment, never on a bare line). Tried in the same sweep: it caught **none** of the 20, because
  the scanner, like the shell, re-pairs without ever opening a region at the stranded terminator.
- **Rejected — C, accept the gap.** Twenty live breaks under a green guard, with a cheap exact
  clause available, is not a gap worth documenting instead of closing.
- **Rejected as stated — A's lookahead.** FR1 is A without the lookahead: the evidence that a close
  was false is on the closing line itself, so no parse of later text is needed and the clause stays
  exact over today's scripts.
- **Accepted cost:** FR1 forbids terminators such as `' | sort` or `' file` with an unquoted
  argument; none exists, and widening the allowed set is a later edit that must keep the AC3 sweep
  at zero misses. **Accepted residue:** an apostrophe alone on a blank body line is indistinguishable
  from a bare terminator; blank lines stay allowed because forbidding them taxes readability to
  catch an edit that no prose typo produces. No ADR: this is one test clause, cheap to reverse, and
  this note plus the `CONCURRENCY.md` sentence are the record the Documentation NFR asks for.
- **Criteria accounting:** the item arrived with no FRs or ACs; FR1–FR4 and AC1–AC6 are new.
  `qa_level` moves `verify` → `unit` as the QA plan anticipated; `close_by: verify` is set
  explicitly because AC3 is evidence to be read.

- **2026-10-27 (develop, token c250) — built.** Commit 56eff72; whole suite green after it.
  FR1 is the `after` clause and FR2 the `head` clause in `early_close`; both report through the
  existing AC8 loop with their own message, the scanner now printing a kind before the opened line,
  the line and its text. AC4: 55 passed, 0 failed on the clean tree.
  **All run, in a `git archive` mirror under `/tmp`, never the templates in place:** AC1 (column 0 of
  `close:570`, the `ac_counts` body's first line — 479 at design, moved by 0146's markers) → 2 FAIL,
  `close` named with `:569` opened and line 570; restored → green. AC2 (after the indent) → same 2
  FAIL. AC5 (`  "x" in_ac {` at `close:571`, template only) → the `head` FAIL naming line 571 (plus
  the expected divergence FAIL); restored → green. AC6: deleting either `CONCURRENCY.md` statement
  → 1 FAIL each. `head` disabled in the scanner → the AC5 mutant goes green, so the clause is
  load-bearing; `after` is shown load-bearing by the control sweep below.
  **AC3 sweep (run):** `/tmp/0139sweep/sweep.sh` lifts `early_close` out of the test file, derives
  the region list from the same scanner with its reports turned into a region print, and inserts
  `'` at column 0 and after leading whitespace of every line strictly inside every multi-line
  region of all six templates (`migrate` included, as `SCRIPTS` lists it). **total=1200,
  misses=0.** Control: the same harness over the pre-change scanner gives **total=1200,
  misses=20**, all in `close`'s `ac_counts` and `rc_counts` bodies — the design pass's 20; the
  total grew from 1,162 because the templates grew since. The harness is not committed; its
  shape is the one this note and the design note describe.
  Added a CHANGELOG line: a session editing a script will see the new reds.

## QA evidence

Verified 2026-10-27 by `verify` (token 9a6f) at `qa_level: unit`, against HEAD (a descendant of build commit 56eff72).

Conventions: ../ai-building-conventions

Command (config.yml `commands.unit_by_file`, the reporting form of `commands.unit`): `for t in tests/*.test.sh; do "$t" || true; done`. All 40 files reported `0 failed`, and `tests/backlog-scripts-installed.test.sh` reported `55 passed, 0 failed`. No lint or typecheck is configured. The repo checkout ran (tests and templates). The change is a test clause and a reference paragraph, so no installed-skill copy is under test.

Dirty set at Step 2: empty. At verdict, only this pass's own scratch directory (`.qa-0139/`, since removed) was dirty. Intersection with the evidence set: empty, so the verdict is not advisory.

`ac_digest`: `./next --ac-digest 0139 --check` → `0139: ac_digest matches`.

All mutations ran in a `git archive HEAD` mirror under `.qa-0139/m/`, never on the templates in place. Each was restored by the path mutated, followed by a control run.

### Clause table

| AC | Clause | Guard / mutation | Result |
|---|---|---|---|
| AC1 | Given `close`, `'` at column 0 of the first `ac_counts` body line (now 570), in both copies | `570s/^/'/` on `skills/queue/templates/close` and `.claude/backlog/close` | `53 passed, 2 failed`; both FAILs name `close`, `:569` opened, line 570 |
| AC1 | fails naming `close`, the opened line, the closed line | message text read off the FAIL lines | present in both |
| AC1 | restored, it passes | control | `55 passed, 0 failed` |
| AC1 | could it be red without the change | same mutant against the pre-change test file `56eff72^` | `53 passed, 0 failed`, so the new clause is what catches it; `sh -n` accepts the mutant |
| AC1 | `after` clause load-bearing | `after` report bypassed with `next;` in the mirror test, plus the AC1 mutant | `55 passed, 0 failed` (goes green: the clause is necessary) |
| AC2 | `'` after the leading whitespace, same line, both copies | `570s/^  /  '/` | `53 passed, 2 failed`, same message; control `55 passed, 0 failed` |
| AC3 | every line strictly inside every multi-line region of all templates, `'` at col 0 and, separately, after whitespace | `.qa-0139/sweep.sh`: scanner lifted verbatim from the test file; region list from the same scanner printing each multi-line region at its close; six templates, `migrate` included | `SWEEP-DONE scanner=new.awk total=1200 misses=0` |
| AC3 | the sweep can miss (control) | same harness, scanner from `56eff72^` | `SWEEP-DONE scanner=old.awk total=1200 misses=20`: `close:570–574` and `close:824–828`, col0 and indent each |
| AC4 | the unmutated templates and installed copies report nothing, and the file is green | full suite run above; scanner run directly over each clean template prints nothing | `55 passed, 0 failed` |
| AC5 | a body line in one copy begins with `"` after whitespace | `571s/^  in_ac {/  "x" in_ac {/` on `.claude/backlog/close` only | `head` FAIL naming line 571, "a body line may not begin with " or )", plus the expected divergence FAIL; control `55 passed, 0 failed` |
| AC5 | `head` clause load-bearing | `head_bad = 0` in the mirror test, plus the AC5 mutant | only the divergence FAIL remains (`54 passed, 1 failed`); the `head` report is gone |
| AC5 | FR2's `)` head, beyond the AC | `  ) in_ac {` at 571 | `head` FAIL naming line 571 |
| AC6 | CONCURRENCY.md states that the closing line carries only `)` or double-quoted args | phrase replaced in the mirror | `54 passed, 1 failed` naming the missing statement; control green |
| AC6 | names the blank-line apostrophe as uncaught | phrase replaced in the mirror | `54 passed, 1 failed`; control green |

### NFRs

| Row | Check | Result |
|---|---|---|
| Testing | the `close:288` (now `close:570`) column-0 mutation reddens the guard and is restored by path | holds (AC1 rows) |
| Dependencies | 56eff72 touches only `tests/backlog-scripts-installed.test.sh` and `references/CONCURRENCY.md`, using `sh`/`awk` already required | holds; unguarded (true today, but no test pins it) |
| Documentation | stated once in `references/CONCURRENCY.md`, *The five scripts*; the rejected shapes are recorded in *Notes & decisions* | holds; the statement is guarded by AC6, and the rejection record is prose only. Drift: the row names "*The four scripts*" but the section is titled *five* |

Always-on pass (`CONVENTIONS_CORE.md`): no secrets and no company material. Test-first is shown by the `56eff72^` control. There is no auth, UI, log or egress change, so no security, accessibility or privacy pass is owed.
