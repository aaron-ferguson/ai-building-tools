---
id: "0077"
title: Guard the backlog scripts against a broken embedded awk program
type: bug
next: develop
status: in-progress
qa_level: unit
size: s
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0076"]
expects:
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/templates/close
  - skills/queue/templates/claim
  - skills/queue/templates/next
claimed_by: "6b93"
claimed_at: 2026-09-09T16:26:58Z
touches:
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/templates/close        # transient mutation target only, restored
  - skills/queue/templates/next         # transient mutation target only, restored
  - .claude/backlog/close               # transient mutation target only, restored
  - .claude/backlog/next                # transient mutation target only, restored
---

## Problem

**`close`, `claim` and `next` embed `awk` programs inside single quotes, and their comments carry the
reasoning — so a prose comment inside one is a live shell-quoting hazard.** An apostrophe closes the
`'...'` wrapping the whole program.

Measured 2026-09-01: a comment reading ``other projects' spellings`` was added inside `close`'s
DONE-row builder. The result was not a syntax error at edit time. `close.test.sh` failed **20 of 63**
cases, reporting an **empty reconcile list** and a **commit carrying six extra files** — a signature
that reads as broken reconcile logic, and which named nothing about quoting. The cause was found by
reading the diff, not by any diagnostic.

The hazard is structural rather than careless: these scripts are deliberately comment-heavy, because
each comment carries the incident behind a rule, and the natural English for such a comment contains
apostrophes. **`sh -n` on each script would have caught it in under a second**, before the behavioural
suite ran at all.

## Functional requirements

1. **`tests/backlog-scripts-installed.test.sh` runs `sh -n` on every script it already checks** —
   `next`, `claim`, `close`, in both the template and the installed copy — and fails naming the
   script whose syntax is broken.
2. **The check runs before the byte-identical comparison**, so a syntax error is reported as one
   rather than as a divergence.
3. **State the convention where the scripts are documented**: prose inside a single-quoted `awk`
   program takes no apostrophe, and the reason is the quoting, not style.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | The new guard is proved able to fail by introducing an apostrophe into a template's `awk` comment and confirming it reds, then restoring by the path mutated. | `testing-conventions.md` |
| Dependencies | `sh -n` is POSIX and already required by these tests. Adds nothing. | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — `tests/backlog-scripts-installed.test.sh` runs `sh -n` on each of the four templates and each
  installed copy. (Written as three; `0081` added `handoff`, and FR1 says *every script it already
  checks*, so the built scope is four.)
- [ ] AC2 — Introducing an apostrophe inside a template's `awk` comment turns that test red, naming the script.
- [ ] AC3 — The failure message says the script's syntax is broken, not that it diverged from its template.
- [ ] AC4 — The convention against apostrophes in embedded `awk` comments is stated where the scripts are
  documented, with the quoting as its reason.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** the deliverable is a shell test guarding shell scripts.
- **Specific checks:** run the new case; then mutate — insert `# it's` into `templates/close`'s awk
  block, confirm red and that the message names `close`, restore with `git checkout -- <that path>`
  and confirm green. A no-op control run per `testing-conventions.md`.

## Out of scope

- Rewriting the scripts to avoid embedded `awk`. The programs are correct; the guard is the cheap fix.
- `shellcheck`. A dependency this repo does not have, for a defect `sh -n` already catches.

## Notes & decisions

- The defect that prompted this was introduced and fixed inside the AetherWorks retro of 2026-09-01;
  the fix shipped in `e3514b4`/`e5ad319`. This item is the guard, not the fix.

### From `FINDINGS.md`, landed 2026-09-05

- **The failure signature, which is the thing the guard has to beat.** The incident this ticket
  guards, recorded in full: a comment reading `other projects' spellings` inside `close`'s
  single-quoted `awk` DONE-row builder closed the `'...'` wrapping the whole program, and
  `close.test.sh` then failed **20 of 63 cases, reporting an empty reconcile list and a commit
  carrying six extra files** — a signature that reads as broken reconcile logic and names nothing
  about quotes. `close`, `claim` and `next` all embed `awk` this way and their comments carry the
  reasoning, so the scripts actively invite the hazard. AC3's requirement that the message say the
  syntax is broken rather than that the copy diverged is what stands between a future session and
  that same twenty-minute misdiagnosis (FINDINGS 2026-09-01).
- **Part of FR1 has already been built by another ticket, so re-check before implementing**
  (verified 2026-09-05). `0081` added an `sh -n` case to `tests/backlog-scripts-installed.test.sh`
  citing this hazard, and `SCRIPTS` is now `next claim close handoff` — four scripts, not three.
  What that case does **not** yet do, checked against the file: it parses `$TEMPLATES/$s` in both
  branches, so the **installed copy under `.claude/backlog/` is never parsed**, and it runs as AC5,
  *after* the byte-identical comparison rather than before it — the two things FR1 and FR2
  respectively ask for. FR3's convention is likewise part-landed and not as a stated rule: the
  apostrophe hazard is explained in comments inside `next`, `close` and `handoff`
  (`"\047"` is that apostrophe — this block is single-quoted shell) and in
  `tests/citations.test.sh`, but nowhere as one rule where the scripts are documented. So this
  ticket is smaller than it was written and is not empty; whoever takes it should re-scope rather
  than assume either.

### From `develop`, 2026-09-09 (`24af`)

- **Scope as built, after the re-check the 2026-09-05 note asked for.** `SCRIPTS` is
  `next claim close handoff`, so FR1 is four scripts, not three. The pre-existing AC5 case parsed
  `$TEMPLATES/$s` in both branches; it now parses the template *and* the installed copy, and the
  block moved above AC2. FR3's rule landed in `references/CONCURRENCY.md`, *The four scripts* — the
  one place the scripts are documented as a set — and is guarded against that section's body, not
  the whole file, because the hazard is already explained in comments inside `next`, `close` and
  `handoff` and a file-wide grep would pass on those.
- **The AC2/AC5 ordering is not cosmetic, and mutation 3 is the proof.** Breaking both copies
  *identically* leaves AC2 silent — they are still byte-identical — so the parse check is the only
  thing that sees it. That is the case an ordering argument alone does not make.
- **Where the apostrophe has to go to be a hazard, which the first mutation attempt got wrong.**
  An apostrophe in the shell comment *above* `DECOMMENT='...'` is harmless: it is outside the
  quoted program, and the guard correctly stayed green while AC2 reported the divergence. Only a
  comment inside the assignment closes the quote. A mutation aimed at the block's explanatory
  header therefore proves nothing — aim it between the opening `'` and its close.

### From `verify`, 2026-09-09 (`6387`)

- **FAIL on AC2. The guard catches the historical hazard exactly, and is blind to a second
  apostrophe of the same shape.** Inserting `# other projects' spellings` into `close`'s DONE-row
  builder — the incident verbatim — is caught on both copies with the right message. Inserting
  `# it's the criteria block` into the *same script's* `ac_counts` awk program at line 288 is not:
  `sh -n` exits 0, and with both copies mutated identically
  `backlog-scripts-installed.test.sh` reports **29 passed, 0 failed** while `close.test.sh` reports
  **83 failed**. A live broken `close` with a fully green guard is the state this ticket exists to
  make impossible.
- **Why, measured.** `/bin/sh` here is bash 3.2.57; `bash` on PATH is 5.3.9. `bash -n` rejects the
  line-288 mutation (`syntax error near unexpected token '('`); `sh -n` accepts it. Under the
  interpreter that actually runs the script the file *is* valid — the breakage is semantic, `awk`
  receiving a mangled program — so no parse check of that same shell can ever see it.
- **The constraint, not a menu.** AC2 must hold for an apostrophe anywhere inside a single-quoted
  `awk` program, including one `/bin/sh` still parses. `Out of scope` rules out `shellcheck` and
  rewriting the scripts; it does not rule out a positive check over the scripts' own text.
- **What is proved and must not be rebuilt.** AC1 (eight parses, four templates and four installed
  copies) is real: breaking `.claude/backlog/close` alone reddens naming the installed path, which
  the pre-0077 code — parsing `$TEMPLATES/$s` twice — could not do. AC3's wording is verbatim
  correct. The AC5-before-AC2 ordering is load-bearing and was confirmed by the both-copies
  mutation, where the byte comparison is silent by construction. AC4 reddens on deleting the rule
  and on rewording its reason, and its section anchor holds: the same paragraph moved to
  `## Claim tokens` still fails.


### From `develop`, 2026-09-09 (`566c`), on the AC2 bounce

- **What was added, and what was left alone.** AC1, AC3, AC4 and the AC5-before-AC2 ordering were
  proved by `verify` and are untouched. The only change to the guard is a new `AC8` block, placed
  between AC5 and AC2 for AC5's own reason — an identically-broken pair diverges from nothing, so
  AC2 is silent by construction and the check has to run before it.
- **What AC8 asserts, and why it is a text scan rather than a parse.** A single-quoted region
  spanning more than one line is an embedded program, and the quote closing it must be the first
  thing on its line bar whitespace and the awk block enders `)`, `}`, `]`. A stray apostrophe in
  prose closes the region mid-comment, which fails that test wherever the shell happens to recover
  — including the case `verify` found, where `/bin/sh` re-pairs the quotes and the file stays
  valid. No parse check of the same shell can ever see that one, which is why the remedy had to be
  positive rather than another parser.
- **A scanner that does not model `$( )` sees none of these programs, and passes.** This cost two
  iterations. Every awk program in the four scripts is written `x="$(awk '...')"`, so a state
  machine that treats `"` as opening a double-quoted run to the next `"` never enters the
  single-quoted state at all — it returns a clean report on a file broken exactly the way this
  ticket exists to catch. Inside `$(...)` the shell re-enters unquoted parsing; the scan pushes
  and pops a state stack on `$(` and `)` for that reason.
- **Heredoc bodies had to be skipped, and the false positive was in `next`, not in an awk program.**
  `next`s `cat <<'USAGE'` block is prose with apostrophes in it (`row's`, `graph's`), which a
  quote-tracking scan reads as a two-line single-quoted region closing mid-sentence. Shell comments
  and backslash escapes are handled for the same reason. Nothing else in the eight files trips it.
- **A blanket "no apostrophe on a comment line" was tried first and rejected.** It catches both
  incidents and is trivial to write, but the four scripts carry roughly ninety comment lines with
  apostrophes in them, almost all outside any quoted program and entirely harmless. Making that
  rule true would mean rewording ninety comments whose whole job is to carry an incident — and per
  this repo's `CLAUDE.md`, rewrapping guarded prose is itself a breaking change.
- **Mutation evidence, six mutations plus a clean control, each restored with
  `git checkout -- <path>` after the guard was committed.** (1) `# it's the criteria block` at
  `close:288`, **both copies** — `sh -n` accepts both, AC2 silent, AC8 reds on both naming
  `close:287` as the opener and 288 as the early close: the exact state `verify` reported as
  29 passed / 0 failed. (2) The historical incident verbatim at `close:557`, template only — AC5,
  AC8 and AC2 all red. (3) `next:66`, template only. (4) `claim:130`, installed copy only. (5)
  `handoff:183`, both copies. (6) **No-op control**: the same apostrophe in a *shell* comment
  outside every program — AC8 stays green and only AC2 reds on the divergence, so the check is not
  simply counting quotes. Clean tree: 37 passed, 0 failed.
- **`references/CONCURRENCY.md`, *The four scripts*, now names both checks.** Its closing sentence
  said the guard is `sh -n`, which was true when AC4 was written and is now half the answer. The
  two phrases AC4 greps are on their own lines and were not touched.


### From `verify`, 2026-09-09 (`2ea3`), on the AC8 remedy

- **FAIL on AC2 again. The new scanner closes the hole `6387` found and leaves one of the same
  shape.** The bounce case is genuinely fixed: `# it's the criteria block` inside `close`s
  `ac_counts` awk program, both copies, now reds on both with the right message while `sh -n` still
  accepts — 35 passed / 2 failed against `close.test.sh`s 87 failures. AC1, AC3, AC4 and the
  AC5/AC8-before-AC2 ordering are all re-proved from this session's own mutations.
- **The remaining hole is the program's opening line.** Appending a comment to the line that opens
  a multi-line program — `ac_counts="$(awk '  # it's the criteria block` at `close:287`, both
  copies — leaves `sh -n` accepting, AC8 green, AC2 silent, and
  `backlog-scripts-installed.test.sh` reporting **37 passed, 0 failed** while `close.test.sh`
  reports **115 passed, 86 failed**. That is the same end state the `6387` bounce named: a live
  broken `close` under a fully green guard.
- **Why, mechanically.** `early_close` only reports a close where `NR != sq_line`. That exemption
  is load-bearing — a single-line program such as `awk '/^COUNT/ { print $2; exit }'` legitimately
  closes on its opening line after non-whitespace — but it is written per *region*, so it exempts
  the opening line of a multi-line program too. The distinguishing fact is available: a region that
  opens and closes on one line is fine, whereas one that closes on its opening line and whose
  program text then continues onto following lines is the defect.
- **The constraint, not a menu.** AC2 must hold for an apostrophe anywhere inside a single-quoted
  `awk` program, the opening line included. `Out of scope` still rules out `shellcheck` and
  rewriting the scripts; narrowing the `NR != sq_line` exemption is neither.
- **Not general — it depends on the file re-pairing.** The same mutation on `next:326` *is* caught,
  but only incidentally: the odd quote cascades, `sh -n` reds, and AC8 reports a displaced quote
  four lines further down. Catching it for the wrong reason in one script is not coverage.
- **What is proved and must not be rebuilt.** The `$( )` state stack, the heredoc skip (probed with
  a mutation at `next:326`, well past the `USAGE` block at 81 — the skip resumes correctly), the
  two-apostrophe re-pairing case (`handoff:307`, caught), per-side naming (`claim` installed copy
  only — AC5, AC8 and AC2 all red, template green), and the no-op control (apostrophe in a shell
  comment outside every program — AC8 green, `close` 201/0) are all confirmed working.


### From `develop`, 2026-09-09 (`6b93`), on the opening-line bounce

- **The one-line change, and why it is not another exemption.** `verify`s diagnosis was exact: the
  `NR != sq_line` exemption is written per region, so it covers the opening line of a multi-line
  program as well as a genuine one-liner. The remedy is not to narrow that exemption by asking
  whether the program continues onto later lines — that fact is not available at the close without
  lookahead — but to add a second, independent reason to report: **the closing quote was preceded,
  inside the region on that line, by an awk comment start.** An apostrophe in prose always closes
  the quote from inside a `#` comment; a real terminator never does. The multi-line rule is
  untouched and both clauses now fire on the body case.
- **The `/` and `"` parity test is load-bearing, and `close:288` proves it in passing.** A bare
  "is there a `#` before the close" would fire on `awk '/^#/ { print }'` and on `close`s own
  `/^## Acceptance criteria/`. Counting `/` and `"` before the candidate `#` and requiring both
  even keeps a `#` inside an awk regex or string from counting. Probed directly on a scratch file:
  `/^#/` and `/^## /` single-liners are reported CLEAN.
- **One shape is deliberately over-reported, and the choice is recorded in the test.** A region
  closing on its opening line after a comment start is flagged whether the program continues
  (`awk '/^x/ {  # it's the row`, broken) or not (`awk '{ print }  # a note'`, a legal awk trailing
  comment). Nothing at the close distinguishes them. Reporting both was chosen over missing the
  first: AC2 is the whole ticket, and `references/CONCURRENCY.md` already asks these programs carry
  no prose comments. Neither shape exists in the four scripts — the clean control is 37/0.
- **Mutation evidence, six mutations plus a clean control, enumerated by scanner *state* rather
  than by script** — the lesson `2ea3` parked. Each restored with `git checkout -- <path>` after
  the guard was committed. (1) **The bounce case verbatim**: `close:287`, both copies — `sh -n`
  accepts, AC2 silent, AC8 reds on both naming `close:287` as opener *and* closer; 35/2, where
  before this change it was 37/0 over a `close.test.sh` failing 86. (2) **Opening line at depth 0**
  (`next:326`, template only) — now caught by AC8 on its own terms, not incidentally via cascade,
  which is the gap `2ea3` named as "catching it for the wrong reason". (3) **Opening line at depth
  0, both copies** (`handoff:307`) — AC5 and AC8 both red on both sides. (4) **Opening line that
  already carries program text** (`next:46`, template only) — red. (5) **Installed copy only**
  (`close:480`) — AC8 names the installed path, template green. (6) **Body case, both copies**
  (`close:288`) — still red, the `6387` bounce stays closed. (7) **No-op control**: apostrophe in a
  shell comment outside every program — AC8 green, only AC2 reds on the divergence.
- **Whole suite green, all 26 files, matching the `2ea3` baseline tally for tally.**
- **`references/CONCURRENCY.md`, *The four scripts*, now describes both clauses.** Its sentence said
  the scan asserts a multi-line region closes at the start of a line; that is half the check now.
  The two phrases AC4 greps are on their own lines and were not touched — AC4 still passes.


## QA evidence

Verified 2026-09-09 at `qa_level: unit` (this repo's whole suite, run file-by-file per
`config.yml`), token `2ea3`. Tree clean at both the Step 2 baseline and the verdict capture, so the
evidence set and the dirty set do not intersect.

| Row | How checked | Result |
|---|---|---|
| AC1 — `sh -n` on four templates and four installed copies | mutated `.claude/backlog/claim:130` alone: `FAIL claim has a syntax error — .claude/backlog/claim is not valid /bin/sh`, template green. Per-side naming is real | PASS |
| AC2 — an apostrophe inside a template's `awk` comment reds, naming the script | body case (`close:288`, both copies) reds on both, naming `close:287` as opener — the `6387` bounce is fixed. **Opening-line case (`close:287`, both copies): guard 37 passed / 0 failed while `close.test.sh` gives 115 passed / 86 failed** | **FAIL** |
| AC3 — the message says syntax/quote defect, not divergence | `close has a quote defect, not a divergence — the awk program opened at …:287 is closed early by a quote on line 290`; and `… has a syntax error — … (this is not a divergence)` | PASS |
| AC4 — the convention is stated where the scripts are documented, with the quoting as its reason | three mutations of `references/CONCURRENCY.md`: replacing `takes no apostrophe` → rule assertion red; replacing `quoting around the whole program` → reason assertion red; renaming the `## The four scripts` heading → section assertion red. Anchor is load-bearing | PASS |
| AC5/AC8 before AC2 (ordering) | both-copies mutations diverge from nothing, so AC2 is silent by construction; AC5 and AC8 both reported above it in every run | PASS |
| NFR Testing — the guard proved able to fail, restored by the path mutated | seven mutations, each restored with `git checkout -- <that path>`; control after each. Final control: `backlog-scripts-installed` 37/0, `close` 201/0, `next` 205/0, `claim` 42/0, `handoff` 104/0 | PASS |
| NFR Dependencies — adds nothing beyond `/bin/sh` | new `early_close` uses `awk` only; test shebang unchanged at `#!/bin/sh` | PASS |
| Always-on (`CONVENTIONS_CORE.md`) | test-and-docs change in a public repo; no company material, secrets or PII. `measurement.test.sh` (112/0) guards home-directory paths | PASS |

Whole-suite baseline, all 26 files green, tallies pasted from each run: `next` 205/0, `close` 201/0,
`orchestrate` 130/0/0 skipped, `measurement` 112/0, `handoff` 104/0, `close-by` 67/0,
`retro-tool-edit` 50/0, `citations` 46/0, `release` 45/0, `claim` 42/0, `findings-routing` 41/0,
`backlog-scripts-installed` 37/0, `graph-fields` 36/0, `cost-by-category` 29/0, `skill-size` 27/0,
`reporting` 23/0, `remote-anchor` 20/0, `falsifiable-acs` 17/0, `last-line` 17/0,
`reference-size` 15/0, `batching` 13/0, `floor-probe` 12/0, `money-in-skill-prose` 12/0,
`qa-level-once` 11/0, `external-feedback` 9/0, `item-ac-form` 4/0.
