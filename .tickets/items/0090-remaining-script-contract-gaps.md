---
id: "0090"
title: Close the four contract gaps 0081 and 0082 left in claim, close and handoff
type: bug
next:
status: done
qa_level: unit
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: ["0082"]
relates: ["0081"]
expects:
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/handoff.test.sh
  - .claude/backlog/claim
  - .claude/backlog/close
  - .claude/backlog/handoff
claimed_by:
claimed_at:
touches:
closed: 2026-09-09
---

## Problem

`0081` gave the hand-off a script and `0082` made `claim` fail safe. Both were scoped to one script,
and four gaps of the same class are left behind in the other two — each found by a session that was
correctly forbidden from widening someone else's contract.

1. **`./close` clears `touches:` with a skiplist a legal YAML list evades.** YAML permits a block
   sequence at the *same* indentation as its key, so `touches:\n- src/a.ts` is valid.
   `close`'s `if (skiplist && $0 ~ /^[ \t]+-/)` (`close:251`) requires leading whitespace and leaves
   those entries in the item. The row moves to `DONE.md` and the closed item goes on naming two
   files, which `CONCURRENCY.md` (*The working tree is shared too*) obliges every other window to
   read as **held** — an invisible narrowing of what anyone else may take. Found by the mutation
   sweep on `./handoff`, which had copied the same line and was fixed there (`^[ \t]*- `).

2. **`./claim` writes the row to `QUEUE.md` before it checks the item file exists.** `claim:136` is
   the `mv "$tmp" "$QUEUE"`; `claim:140` is the refusal when `items/$ID-*.md` resolves to nothing.
   A row whose item is missing or misnamed therefore leaves `QUEUE.md` **edited, uncommitted and
   unlocked** — the same fail-open shape `0082` exists to close, on a third path `0082` does not
   name and so could not take.

3. **`close` and `handoff` still warn-and-carry.** `close:61` and `handoff:102` each detect that
   their commit will carry another session's uncommitted rows, print a warning, and commit anyway.
   The argument `0082` FR3 makes for refusing is not specific to claiming: a pathspec limits a
   commit to paths and never to authorship (`CONCURRENCY.md`, *A pathspec is necessary but not
   sufficient*), and all three scripts hold the lock when they decide.

4. **`claim` and `close` commit without the `Co-Authored-By` trailer.** `git-conventions.md`
   requires it of every AI-assisted commit; `grep -c Co-Authored-By` returns `0` for both and `1`
   for `handoff`. The scope question — whether a script-generated bookkeeping commit counts as
   AI-assisted — is **already answered** by `skills/develop/SKILL.md` Step 1, which says a lifecycle
   commit is not exempt, and by `references/CONCURRENCY.md` *The git index is shared*, which
   requires it of every AI-assisted commit. `handoff` now carries it; the other two do not, and
   fixing only one of three leaves them inconsistent.

## Functional requirements

- FR1 — `close`'s `touches:` skiplist matches a same-indentation block sequence as well as an
  indented one (`^[ \t]*- `), so closing a ticket clears every form of the list `item.md` and the
  YAML spec permit.
- FR2 — `claim` resolves the item file **above** the `QUEUE.md` row edit, so its refusal path leaves
  the queue untouched.
- FR3 — `close` and `handoff` **refuse** rather than warn when their commit would carry uncommitted
  changes to the shared files they write, matching `0082` FR3's behaviour in `claim`, and release
  the lock on that refusal path.
- FR4 — `claim` and `close` write the `Co-Authored-By` trailer on every commit they make.
- FR5 — Each of FR1–FR4 is asserted by a case in the corresponding `tests/{claim,close,handoff}.test.sh`.
- FR6 — The four edits land in **both** copies of each script: `skills/queue/templates/` (the
  shipped artifact) and `.claude/backlog/` (this repo's instance), and
  `tests/backlog-scripts-installed.test.sh` stays green, since it forces the two byte-identical.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The trailer scope question is recorded as **settled**, with the two files that settled it, so a third session does not re-open it | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given an item whose `touches:` is written as a same-indentation block sequence
  (`touches:\n- src/a.ts`), when `./close <id> <token>` runs, then the closed item's `touches:` is
  empty. Red-making input: today's `close`, which leaves `- src/a.ts` in the file.
- [x] AC2 — Given a row in `QUEUE.md` whose `items/<id>-*.md` does not exist, when `./claim <id>`
  runs, then it exits non-zero **and** `git diff -- QUEUE.md` is empty. Red-making change: moving
  the item resolution back below the `mv`, which leaves the row edited.
- [x] AC3 — Given `QUEUE.md` carries an uncommitted row change made by another session, when
  `./close <id> <token>` runs, then it exits non-zero, commits nothing, and the lock directory does
  not exist afterwards. Red-making change: reverting FR3 to the `echo WARNING` form, which commits.
- [x] AC4 — Given the same precondition, when `./handoff <id> <token> develop` runs, then it exits
  non-zero, commits nothing, and the lock directory does not exist afterwards.
- [x] AC5 — Given a successful `./claim` and a successful `./close`, when `git log -1 --format=%B`
  is read for each resulting commit, then each message body contains a `Co-Authored-By:` line. Red
  if either trailer is absent.
- [x] AC6 — Given the six files of FR6, when `tests/backlog-scripts-installed.test.sh` runs, then it
  reports `0 failed`. Red-making change: editing only `skills/queue/templates/close` and not
  `.claude/backlog/close`.

## QA plan

- **Why that level:** all four gaps are in shell scripts with existing suites; the assertions are
  ordinary test cases in `tests/{claim,close,handoff}.test.sh`.
- **Specific checks:** run those three suites individually, then the whole suite file-by-file
  (`for t in tests/*.test.sh; do "$t" || true; done`) so a red elsewhere does not mask them.
  AC3 and AC4 need a fixture repo with a dirty `QUEUE.md` — `tests/handoff.test.sh` already builds
  one.

## Out of scope

- `next`, which only reads and commits nothing.
- Whether the three scripts should share a sourced helper — that is its own decision, ticketed
  separately, and this item deliberately edits three copies rather than pre-empting it.
- Changing `git-conventions.md`. The exemption question is settled against exempting; this item
  brings the code to the rule, not the rule to the code.

## Notes & decisions

- **`blocked_by: 0082`** and not merely `relates:`: FR2 edits the same region of `claim` that `0082`
  is currently verifying, and building both against one file in parallel is the collision
  `CONCURRENCY.md` *The working tree is shared too* exists to prevent. If `0082` returns to
  `develop`, this stays blocked, which is correct.
- Routed to `develop`: four known defects with known corrective shapes, three of them already
  demonstrated in `handoff`. Nothing is undecided.
- Filed as one ticket rather than four: same three files, same three suites, same reviewer. Split,
  each session pays to re-read all three scripts.
- **The `Co-Authored-By` scope question FR4 answers was never open** (`FINDINGS.md` 2026-09-05,
  landed here by `retro`). `skills/develop/SKILL.md` Step 1 already says *"A lifecycle commit is not
  exempt from it"*, and `CONCURRENCY.md` *The git index is shared* requires the trailer of every
  AI-assisted commit — yet a build pass and a QA pass both read the question as undecided and
  escalated it. The reach defect is **where that sentence sits**: item 4 of Step 1's *by-hand* claim
  sequence, which a session running `./claim` never executes, so the requirement reads as a property
  of the by-hand commit rather than of the scripts'. FR4 is what closes that, and no new rule was
  written — a second copy of a rule that did not fire weakens both.

### Build pass, 2026-09-09 (develop, token 06a6)

- **All four line-number citations in *Problem* had drifted; all four substantive claims held.**
  `close:251`→`642`, `claim:136/140`→`156/159`, `close:61`→`77`, `handoff:102`→`103`. A line number
  is a quoted figure about a file the ticket does not own in the sense `develop` Step 2 means, and it
  ages faster than any other kind — but the symbol grep the same step prescribes (`grep -n skiplist`,
  `grep -n WARNING`) recovered every one in a single call. Cite the symbol as well as the line.
- **All three refusals sit BEFORE the lock, so AC3's and AC4's "the lock does not exist afterwards"
  is satisfied by construction, not by the trap.** `claim` already had this shape from 0082 and its
  comment says why: a refusal that has taken the lock has something to undo. Worth knowing that the
  ACs as written would also pass on a refusal that took the lock and released it correctly — they do
  not distinguish the two, and the stronger property is the one the code actually has.
- **`close` writes `closed: <date>` immediately after `touches:` in the frontmatter.** A first
  FR1 assertion of `touches:\n---` failed on a correct implementation for that reason. The existing
  AC1 case already knew this and asserted `claimed_by:/claimed_at:/touches:` with nothing after it;
  reading the sibling assertion before writing the new one would have skipped the round trip.
- **`handoff`'s trailer comment cited only `develop` Step 1, i.e. the weaker half of the settled
  question.** FR4's NFR is satisfied in all three scripts rather than the two it names: leaving
  `handoff` citing one file would have left a third session the same partial reading that made the
  question look open, in the one script that already had the trailer.
- **`close`'s case-insensitive-pathspec comment gained weight rather than losing it.** It was written
  to stop a warning crying wolf; FR3 turns that warning into a refusal, so the same bug now blocks a
  legitimate close instead of printing noise. The comment was updated to say so — do not "tidy" those
  two pathspecs to `$QUEUE`/`$DONE`.
- Whole suite run file-by-file: 27 files, all green, no red anywhere in or out of scope.

## QA evidence

QA pass 2026-09-09, token `31db`, `qa_level: unit`. Level commands from `config.yml`: `lint` and
`typecheck` are unconfigured (empty), so the level is the shell suite, run **file-by-file** rather
than through the configured fail-fast `unit` line, per that key's own comment and the QA plan.
Tree at Step 2 and at verdict: only this item file (my own `touches:` edit) — no foreign path, so
the whole-project-gate worktree rule did not apply and the intersection with the evidence set is
empty. The copy under test is `skills/queue/templates/{claim,close,handoff}` — `tests/*.test.sh`
copy the **template** into a fixture repo, so every mutation below was applied there, not to
`.claude/backlog/`; the two are held byte-identical by AC6's guard.

| # | How it was checked | Result |
|---|---|---|
| AC1 | `tests/close.test.sh` case *0090 FR1 — a flush-left `touches:` block sequence is cleared on close*. Mutation at the AC's altitude: `skills/queue/templates/close:667` skiplist `^[ \t]*- ` → `^[ \t]+- ` (the pre-fix form) | PASS. Mutation reddens 3 assertions — *the first entry is gone* saw `- src/a.ts` still in the closed item |
| AC2 | `tests/claim.test.sh` case *0090 AC2*. Mutation: item resolution (`claim:162-163`) relocated back **below** `mv "$tmp" "$QUEUE"` | PASS. Mutation reddens 2 — *QUEUE.md is byte-identical* saw the edited table |
| AC3 | `tests/close.test.sh` case *0090 AC3*. Mutation: the refusal's `exit 1` (`close:103`) → `echo "WARNING: carrying on anyway"` | PASS. Mutation reddens 7 — *exits non-zero* saw `exit 0` then `closed 0092 — Verified row` |
| AC4 | `tests/handoff.test.sh` case *0090 AC4*. Same mutation at `handoff:120` | PASS. Mutation reddens 6 — *exits non-zero* saw `exit 0` then `handed off 0090: develop -> verify` |
| AC5 | `tests/claim.test.sh` / `tests/close.test.sh` cases *0090 AC5*, plus the live surface: this session's own `Claim 0090 [31db]` commit body reads `Co-Authored-By: Claude <noreply@anthropic.com>`. Mutation: ` -m "$COAUTHOR"` deleted from each commit invocation | PASS. Mutation reddens 1 in each — *git parses a Co-Authored-By trailer* saw empty |
| AC6 | `tests/backlog-scripts-installed.test.sh`, 37 passed, 0 failed. Mutation: AC1's edit to the template alone | PASS. Mutation reddens 1 — `close has diverged from skills/queue/templates/close` |
| NFR Documentation | `skills/queue/templates/{claim,close,handoff}:55-66` — the trailer comment names both settling files (`skills/develop/SKILL.md` Step 1 and `references/CONCURRENCY.md` *The git index is shared*), says in as many words that they SETTLE the question, and records why it read as open. Present in all three scripts, one more than the NFR asks | PASS |

Control run after every mutation was restored (`git checkout -- <the mutated path>` only, never a bare
`.`): `claim.test.sh` 69 passed 0 failed, `close.test.sh` 233 passed 0 failed, `handoff.test.sh` 123
passed 0 failed, `backlog-scripts-installed.test.sh` 37 passed 0 failed. It is that green that
licenses the reds above. Whole suite, file-by-file, all 27 files green, tallies pasted from each
run — no red in or out of scope.

**One mutation silently did not land**, and the run it produced was fully green and indistinguishable
from a holding guard: the first attempt at AC3/AC4 selected the *comment* line matching
`no lock was taken` rather than the `echo` inside the `if`, so the guard-assertion failed and nothing
was written. `verify` Step 3's *Confirm the break landed* is what caught it. The relanded mutation is
the one recorded above.

### Probes

- 🔍 `handoff` checks `git diff --quiet -- "$QUEUE"` (absolute) where `close` deliberately uses the
  relative `QUEUE.md DONE.md` form and carries a comment against "tidying" it back. Probed on a
  fixture repo with a dirty `QUEUE.md` and a case-mismatched absolute prefix: absolute and relative
  both exit 1 correctly. The hazard the comment describes needs the **two-path** `git diff -- <a> <b>`
  form, which `handoff` does not use — so the asymmetry is not a defect. Worth knowing before someone
  "harmonises" the two.
- 🔍 Real `.claude/backlog/claim 9999` at the live surface: refuses with `no row for 9999 in QUEUE.md`,
  exit 1, `QUEUE.md` untouched, no lock left behind. AC2's *specific* path (a row that exists with no
  item file) sits **behind** that row check, so it is unreachable at the live surface without first
  editing `QUEUE.md` — which is why it is a fixture test and correctly so.
