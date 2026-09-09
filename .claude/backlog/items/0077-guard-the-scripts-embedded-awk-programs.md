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
claimed_by: "566c"
claimed_at: 2026-09-09T16:08:27Z
touches:
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/templates/close
  - skills/queue/templates/claim
  - skills/queue/templates/next
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


## QA evidence

Verified 2026-09-09 at `qa_level: unit` (this repo's whole suite, run file-by-file per
`config.yml`), token `6387`, clean tree at both captures.

| Row | How checked | Result |
|---|---|---|
| AC1 — `sh -n` on four templates and four installed copies | ran `tests/backlog-scripts-installed.test.sh`; AC5 block prints 8 `ok` lines naming both paths per script. Mutated `.claude/backlog/close` alone → `FAIL close has a syntax error — .claude/backlog/close is not valid /bin/sh`, template still `ok` | PASS |
| AC2 — an apostrophe in a template's `awk` comment reds, naming the script | canonical block (DONE-row builder, line 557): reds naming `close`. **Second mutation, `ac_counts` awk at line 288, both copies: 29 passed, 0 failed** while `close.test.sh` gave 118 passed, 83 failed | **FAIL** |
| AC3 — the message says syntax, not divergence | `close has a syntax error — … is not valid /bin/sh (this is not a divergence): … unexpected EOF while looking for a matching quote` | PASS |
| AC4 — the convention is stated where the scripts are documented, with the quoting as its reason | two `ok` lines. Deleting the paragraph → both red; rewording `quoting around the whole program` → the reason assertion red; moving the paragraph to `## Claim tokens` → both red, so the section anchor is load-bearing | PASS |
| NFR Testing — the guard proved able to fail, restored by the path mutated | five mutations, each restored with `git checkout -- <that path>`; control run after each: `29 passed, 0 failed`, `close.test.sh` `201 passed, 0 failed` | PASS |
| NFR Dependencies — adds nothing beyond `/bin/sh` | test shebang is `#!/bin/sh`; new code uses `sh -n`, `grep -F`, `awk` only | PASS |
| Always-on (`CONVENTIONS_CORE.md`) | test-and-docs change in a public repo; no company material, secrets or PII. Full suite 26 files green before mutation | PASS |

Whole-suite baseline, all 26 files green, tallies pasted from each run: `backlog-scripts-installed`
29/0, `close` 201/0, `next` 205/0, `handoff` 104/0, `orchestrate` 130/0/0 skipped,
`measurement` 112/0, `close-by` 67/0, `retro-tool-edit` 50/0, `citations` 46/0, `release` 45/0,
`claim` 42/0, `findings-routing` 41/0, `graph-fields` 36/0, `cost-by-category` 29/0,
`skill-size` 27/0, `reporting` 23/0, `remote-anchor` 20/0, `falsifiable-acs` 17/0, `last-line` 17/0,
`reference-size` 15/0, `batching` 13/0, `floor-probe` 12/0, `money-in-skill-prose` 12/0,
`qa-level-once` 11/0, `external-feedback` 9/0, `item-ac-form` 4/0.
