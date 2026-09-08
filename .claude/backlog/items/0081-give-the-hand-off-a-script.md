---
id: "0081"
title: Give the hand-off a script, as claim and close have
type: feature
next: verify
status: in-progress
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0082"]
expects:
  - skills/queue/templates/handoff
  - .claude/backlog/handoff
  - tests/handoff.test.sh
  - tests/backlog-scripts-installed.test.sh
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
claimed_by: "6954"
claimed_at: 2026-09-08T23:24:04Z
touches:
  - skills/queue/templates/handoff
  - .claude/backlog/handoff
  - tests/handoff.test.sh
  - tests/backlog-scripts-installed.test.sh
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
---

## Problem

**The hand-off is the third lifecycle transition and the only one with no script, and it fails the way
the other two used to.** `./claim` and `./close` exist precisely because a lifecycle edit *"is
otherwise a matter of remembering"* — the commit inside the lock being the step a session under load
forgets. The hand-off is still five edits across two files, done by hand.

**Measured in AetherWorks, item 0087.** The hand-off commit set the token, the timestamp and `touches:`
but **not `next` and `status`**, because the edit was written against `status: ready` while the item
read `status: in-progress` — so it no-oped and committed anyway. The result was a queue row reading
`verify | ready` over an item reading `develop | in-progress`: **precisely the drift `./next --drift`
exists to catch, produced by the skill's own prescribed procedure.** `Edit` failing rather than
guessing is the safety `CONCURRENCY.md` relies on, and here the failure was silent because the commit
did not depend on the edit having applied.

**A second defect belongs to the same script.** A stage currently **releases its claim before its last
write**, so a ticket is unowned while its holder is still committing to it. From 0051's own history:
`39b858b Hand 0051 to verify [7a34]` set the row to `verify | ready` and blanked `claimed_by:` at
23:34:35; `844d328 Park two findings from building 0051 [7a34]` committed at 23:35:04. **For 29 seconds
the row read takeable while the develop session was still writing**, and `./claim` would have granted
it — correctly, by every rule it enforces. No lock can see this: the lock guards the two-second edit,
and the hole is in the *order of the hand-off*. Two sessions holding one ticket is then
indistinguishable in the git record from a clean sequential hand-off.

## Functional requirements

1. **`./handoff <id> <token>`**, in the same shape as `claim` and `close`: lock → re-read → edit row
   and item → commit → unlock, in one shell invocation (`CONCURRENCY.md`, *Lock every write to
   `QUEUE.md`*).
2. **It sets `next` and `status` and clears `claimed_by:`, `claimed_at:` and `touches:`** — all five,
   or it fails. **A no-op edit is a failure**, not a success: the defect above was an edit that did not
   apply and a commit that proceeded regardless.
3. **It refuses rather than guesses**, on the same grounds the other two do: a table shape it cannot
   read, a row not at the stage it is being handed *from*, and a token that is not the one holding the
   claim.
4. **The release is the final act.** Either the hand-off commit is the last write of the stage, or the
   release is folded into the same commit as the stage's final writes. The skills' hand-off steps say
   so, and say why no lock can catch the alternative.
5. ~~**`./next --drift` reports zero for the row handed off**, checked before and after.~~
   **Withdrawn 2026-09-08 — the instrument cannot see the property.** `./next --drift` compares the
   `Status` column against `blocked_by` and reads neither the item's `next:` nor its `status:`
   (`next:473-494`), so it prints `no drift` over exactly the row/item disagreement FR2 exists to
   prevent — confirmed by mutation, `verify [9840]`. FR2's *all five, or it fails* is what carries
   this requirement, and the report's blindness is **`0115`**. Numbering kept: `tests/handoff.test.sh`
   and this item's two QA verdicts cite these numbers, and a renumber re-points a citation silently.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | Commits by pathspec inside the lock, carrying the `Co-Authored-By` trailer. Never `git add -A`. | `git-conventions.md`, `CONCURRENCY.md` |
| Testing | Scaffolds a throwaway git repo per case and asserts on message and resulting files, never on exit status alone — matching `claim.test.sh` and `close.test.sh`. | `testing-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk`. Nothing beyond what the other two scripts use. | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — `./handoff <id> <token>` moves a row and its item between stages, committed inside the
  lock, in one invocation.
- [ ] AC2 — Given an item whose `status:` does not match what the edit expects, it **refuses and
  changes nothing**, with a message naming the mismatch — the 0087 case.
- [ ] AC3 — It refuses a token that does not hold the claim, and a row not at the expected stage,
  each with its own message and no file changed.
- [ ] AC4 — Given a successful hand-off, when `./next --drift` runs, then it exits zero for that
  row — **recorded as evidence of nothing**, and tickable on that basis alone. `--drift` compares the
  `Status` column against `blocked_by` only and reads no item field, so its zero is returned equally
  by a correct `handoff` and by one with `mv "$queue_tmp" "$QUEUE"` removed (driven, mutation diffed
  first, `verify [9840]`). The atomicity AC4 was written to check is carried by **AC1** (all five
  item fields and both row cells move in one commit) and **AC2** (a row and item that disagree going
  in are refused, from both sides). The blind report is **`0115`**, which also makes
  `tests/handoff.test.sh:461-472` a guard that can fail. Do not tick this as *verified by `--drift`*.
- [ ] AC5 — `sh -n` passes and the installed copy is byte-identical to the template
  (`tests/backlog-scripts-installed.test.sh`).
- [ ] AC6 — `develop` and `verify` name `./handoff` as the supported path and keep the by-hand
  fallback.
- [ ] AC7 — `CONCURRENCY.md` states that the release is a stage's final act, with the 29-second
  window as its reason.

## QA plan

- **Level:** unit — this repo's whole suite, plus a new `tests/handoff.test.sh`.
- **Why this level:** matches `claim.test.sh` and `close.test.sh`, which are the model.
- **Specific checks:** the refusal cases asserted on message **and** on files unchanged, since
  *exits non-zero* is satisfied by the silent refusal the rule forbids. Mutate each refusal branch
  away and confirm it reds; run one no-op control.

## Out of scope

- Changing what a hand-off means, or which stages hand to which. Only the mechanism.
- Retrofitting the 29-second window into closed tickets' history.
- **`./next`, and what `--drift` can see.** That is `0115`. `next` only reads and commits nothing,
  and widening this ticket into it would mean re-opening a build that is finished and green to fix a
  criterion's instrument rather than its subject.
- **`tests/handoff.test.sh:461-472`, the AC4 case.** It becomes a live guard the moment `--drift`
  gains the check, so it is `0115`'s to fix rather than a case to delete here (`0089` is the standing
  sweep for its class).

## Notes & decisions

- Both defects were recorded in AetherWorks' buffer (items 0087 and 0051) and are reproduced above
  with their commits and timestamps.
- **FR1's signature is superseded by `docs/decisions/001-one-command-per-stage-boundary.md`**
  (ticket `0085`, accepted 2026-09-02 — a day *after* this ticket was captured). That record
  specifies `./handoff <id> <token> <stage>`, with the destination stage as a third argument, and
  cites this ticket's FR4 while doing so. Built to the three-argument form, plus an optional fourth
  positional `[status]` defaulting to `ready`: `verify` Step 5 has a `waiting` branch and a
  `next: queue` branch, so a script that inferred the destination from a fixed transition table
  would be guessing exactly where FR3 says it must refuse.
- **What "a row not at the stage it is being handed *from*" (FR3) is checked against.** The command
  carries no from-stage, so the check is that **the row's `Next` cell and the item's `next:` agree**
  — the 0087 drift class itself — and that both read `in-progress`. A row already handed off reads
  `ready`, so re-running `handoff` on it refuses rather than handing it on a second time.
- **What was built.** `skills/queue/templates/handoff`, installed to `.claude/backlog/handoff`,
  `tests/handoff.test.sh` (101 assertions), `handoff` added to `tests/backlog-scripts-installed.test.sh`
  along with an `sh -n` case, `CONCURRENCY.md` gains *The release is the final act* and *The three
  scripts* becomes *The four scripts*, and `develop` Step 5 / `verify` Step 5 route through the
  script while keeping their by-hand fallbacks.
- **The rename carried five anchored citations across four files**, and `tests/citations.test.sh`
  is what made that mechanical rather than a search-and-hope — the guard exists because retitling
  *The two scripts* to *The three scripts* broke two of them silently in August.
- **The mutation sweep found two guards that could not fail, and they are the interesting half.**
  - **The read-back verification is redundant by construction.** Removing it changed nothing,
    because the up-front presence check catches every malformed fixture before the editor runs —
    the "filter for a set, then assert over it" failure `testing-conventions.md` names, where the
    loop body never executes. With a correct editor *no input reaches the read-back*, so the only
    mutation that reaches it is one that breaks the editor. Two cases now do exactly that, in the
    copy the harness runs, and assert on the read-back's own message. The script says this about
    itself, because a guard nothing can reach is normally a defect and here it is the point: the
    0087 failure was not a bad input, it was an edit written against the wrong value.
  - **Releasing the lock before the commit is invisible to every other assertion.** The files end
    up right and the commit lands, so nothing but observing the lock *at commit time* separates a
    correct hand-off from the 29-second window. A `pre-commit` hook in the fixture is that
    observation. This is worth reusing: `claim.test.sh` and `close.test.sh` have the same blind
    spot, and neither script is currently proven to hold the lock through its commit.
- **Two real defects fell out of the sweep, neither visible in a diff.**
  - **YAML allows a block sequence at the same indentation as its key**, so `touches:` entries can
    legally begin at column 0. The skiplist copied from `close` requires leading whitespace and
    left them in place — a ticket reading handed off while still reserving two files, which
    `CONCURRENCY.md` obliges the other window to treat as held. **`close` has the identical
    skiplist and the identical defect**; not fixed here, because it is `close`'s contract and
    `close.test.sh`'s guard. Parked in `FINDINGS.md`.
  - **`grep -q "^touches:"` is satisfied by a *Notes & decisions* line** that happens to start that
    way. The key the edit needs is still absent, and the refusal that followed blamed the script
    rather than naming the missing field. Presence is now scoped to the frontmatter (`fm_has`).
- **The step numbering in both skills now contradicts the commit order, deliberately.** `FINDINGS.md`
  is Step 7 in `develop` and Step 6 in `verify`, but neither `./handoff` nor `./close` commits that
  file, so the append cannot ride along and must land *before* the release. Said at the findings
  step, where it is read, rather than only at the hand-off step.
- **`docs/decisions/001` also names `./claim --touches`, owned by 0066** — not built here. `claim`
  still prints the `touches:` instruction rather than writing it, which is 0082's FR1.

### Verify 2026-09-05 [c67f] — FAIL on one NFR row, all seven ACs green

**All 7 ACs pass, driven against the real script**, not read: the happy path moves all five fields
and both cells in one invocation and commits by pathspec (2 files, lock released after); the three
refusals each print their own message and leave a `cksum` fingerprint of the whole backlog directory
unchanged; `./next --drift` exits zero after; template and installed copy are byte-identical and both
pass `sh -n`; `develop` and `verify` name the command and keep their fallbacks; `CONCURRENCY.md`
carries *The release is the final act* with the 29-second window.

**Five mutations were re-run rather than taken from the build notes, and all five redden** (control
101/0 both before and after): token guard neutered 98/3, in-progress guard 96/5, stage-agreement
guard 99/2, `touches:` skiplist narrowed to require leading whitespace → FAILs, and — the one worth
recording — **releasing the lock before the commit reds exactly one assertion**, the `pre-commit`
hook witness, confirming the build note's claim that nothing else can see that defect.

**The red: the commit carries no `Co-Authored-By` trailer**, which this item's own NFR table requires
("Commits by pathspec inside the lock, carrying the `Co-Authored-By` trailer"). Observed directly —
`git log -1 --format=%B` on a real hand-off prints the subject alone. `git-conventions.md`
*Co-authorship* asks for it on **all** AI-assisted commits, and a commit a session's script makes on
its behalf was read here as AI-assisted.

**This item contradicts itself, and `develop` may reasonably resolve it the other way.** FR1 asks for
"the same shape as `claim` and `close`" — and neither of those carries the trailer either, so
`handoff` matched its siblings exactly as FR1 asked while missing what the NFR row asked. The choice
is therefore not local to this script: either all three scripts gain the trailer, or the convention
exempts script-generated bookkeeping commits and the NFR row is the thing that is wrong. **If the
answer is the latter, send this to `queue` rather than editing the NFR row here.** Parked in
`FINDINGS.md` because the scope decision is not this ticket's to take alone.

### Develop 2026-09-05 [792e] — the trailer red, fixed for `handoff` only

**The scope question was resolved by the repo's own prose, not by judgement.** The verify verdict
offered two branches — all three scripts gain the trailer, or the convention exempts
script-generated bookkeeping commits. `skills/develop/SKILL.md` Step 1 already answers it in as many
words: *"A lifecycle commit is not exempt from it."* `references/CONCURRENCY.md` *The git index is
shared* says the same, requiring the trailer of "every AI-assisted commit". So the NFR row is right
and FR1's "same shape as `claim` and `close`" describes the mechanism, not the message.

**What changed.** `COAUTHOR` is a named constant at the top of the script, next to `DIR`/`QUEUE`/
`LOCK`, and the commit takes a **second `-m`**. The second `-m` is the whole mechanism: git puts a
blank line between the two, which is what makes the line a trailer git will parse rather than prose
in the body.

**The generic name is deliberate.** `git-conventions.md` prints `Claude <noreply@anthropic.com>`, and
a script cannot know which model is driving the session that invoked it. `skills/queue/SKILL.md`
writes `<model>` as a placeholder for a human-authored commit; a script has no such placeholder to
fill, so it uses the convention's own literal.

**The guard reads through git's trailer parser, not through `grep`.** `%(trailers:key=Co-Authored-By,
valueonly)` is the assertion, because the rule is that the commit *carries a trailer* — a `grep` of
the body is satisfied by the word appearing anywhere, which is the "anchor the assertion to the
claim" failure `testing-conventions.md` names. Two mutations prove it, plus a no-op control
(104/0 both before and after):

- **drop `-m "$COAUTHOR"`** → 103/1, the defect the guard exists to catch.
- **fold the trailer into the subject `-m`** → 103/1, and the subject assertion still passes. This is
  the mutation a `grep`-based guard could not have seen, and it is why the parser is used.

**`claim` and `close` still carry the same gap, and it is not fixed here.** `claim` is `0082`'s file
and held by another session; `close` is nobody's right now but is outside this ticket's `touches:`.
Both **still need a row** — no such row exists as of this writing.

**Two reds in the suite are not this ticket's**, both in files this session never opened and both from
commits that predate its first: `tests/citations.test.sh` on
`skills/queue/templates/claim` (commit `3588524`, `0082`, held by `5af1`) and
`tests/skill-size.test.sh` on `skills/retro/SKILL.md` being 38 bytes over goal (commit `16d7f9c`, no
in-progress row owns it). `tests/last-line.test.sh` was excluded from the run as untracked — another
window mid-TDD, which `develop` Step 5 says is settled by `git status` alone.

### From `FINDINGS.md`, landed 2026-09-05

- **A live instance of the exact drift this ticket removes, found while it was still open**
  (FINDINGS 2026-09-03). `0084`'s row and its item disagreed: the queue said `develop | in-progress`
  under token `ae35`, the item said `next: verify`, `status: ready`, `claimed_by:` empty. The effect
  is the pair of symptoms worth keeping — `./next verify` did **not** offer it, and `./next develop`
  **did** report its files as claimed, so a ticket that was ready to QA was invisible to the stage
  that would take it while still reserving scope against the stage that would not. It looks like a
  hand-off that wrote the item and not the row, which is the 0087 failure in mirror image: there the
  edit missed the item's fields, here it missed the row's. The session that found it correctly did
  not repair it — not its ticket. Useful to the QA pass as the shape to check `handoff`'s read-back
  against: **all five fields land or none does** has to hold in both directions, and only one of them
  is what 0087 demonstrated.

### Re-specified 2026-09-08 [queue] — AC4's instrument, not the code

**The code at `2344d29` is right and stays.** Verify `[9840]` drove all seven ACs and all three NFR
rows against the real script and re-ran ten mutations, control 104/0 before and after every one:
six ACs and every NFR row green, the whole suite green at baseline and at verdict (23 files, 1,134
assertions, 0 failed). Nothing in `skills/queue/templates/handoff`, `.claude/backlog/handoff` or
`tests/handoff.test.sh` needs to change, which is why this returns to `verify` and not to `develop` —
no FR gains code.

**What changed here, and only this.** FR5 and AC4 both named `./next --drift` as the instrument for
FR2's *all five, or it fails*. It cannot answer that question: `--drift` is a `Status`-column-versus-
`blocked_by` cache check (`next:473-494`) and reads no item field at all, so its zero exit survives
the queue write being mutated out of `handoff` — which is the `0087` drift itself. Both are now the
observation `queue` Step 2 requires of a criterion whose reproduction lies outside the ticket's own
scope, each naming `0115` as the fix.

**Why not simply delete AC4.** Two verdicts and one test file cite these numbers by position, and
`queue`'s rule for a withdrawn id applies to a withdrawn criterion for the same reason: a citation
left pointing at nothing is a dead link a reader can see, and one silently re-pointed at different
work is not.

**Why `verify` gets it back rather than closing it here.** `./close` closes on ticked ACs, and AC4
was the only unticked one; the tick is a statement about what was checked, and only the stage that
drives the check may make it. What `verify` owes this pass is the six PASS rows re-confirmed and AC4
ticked as the recorded observation above — not a re-run of the ten-mutation sweep, which
`[9840]` already reproduced independently of the build notes.

## QA evidence

### Verify 2026-09-08 [9840] — FAIL on AC4, six ACs and all three NFR rows green

Level `unit` per frontmatter (the QA plan's `**Level:** unit` agrees — no drift). Whole suite green
at baseline and at verdict: **23 files, 1,134 assertions, 0 failed**, run file-by-file per
`config.yml`'s note rather than fail-fast. Tree clean at Step 2 and at verdict. Executed copy:
the installed plugin at `0.9.19`, `diff -rq` byte-identical to this checkout.

| AC / NFR | How verified — and where | Result |
|---|---|---|
| AC1 — moves row + item, committed inside the lock, one invocation | Drove `./handoff 0007 8a04 verify` in a throwaway git repo. All five item fields moved (`next`→verify, `status`→ready, `claimed_by:`/`claimed_at:`/`touches:` cleared **with its two column-0 entries**), both row cells moved, `expects:` untouched. A `pre-commit` hook witnessed `.lock` **present at commit time** and the staged set as exactly `QUEUE.md` + the item. Lock released, tree clean. | PASS |
| AC2 — status mismatch refuses and changes nothing (the 0087 case) | Both directions: item `ready` / row `in-progress`, and item `in-progress` / row `ready`. Each names the mismatch (`"the item reads 'ready' and the row reads 'in-progress'"`); `cksum` over the whole fixture unchanged. | PASS |
| AC3 — refuses a wrong token and a row not at the expected stage, each own message, no file changed | Six distinguishable refusals driven: wrong token, no `claimed_by:` at all, row/item stage disagreement, unreadable table header, unrecognised stage, and each of the three forbidden statuses (`blocked`/`done`/`in-progress`). Every one left the fixture byte-identical. | PASS |
| AC4 — `./next --drift` exits zero for that row after a hand-off | Zero before, zero after — **but the check cannot fail.** Mutating `mv "$queue_tmp" "$QUEUE"` away (break confirmed landed) produced the exact 0087 drift: item at `next: verify, status: ready, claimed_by:` empty over a row still reading `develop \| in-progress` — and `--drift` still printed `no drift`, rc=0. `--drift` is a Status-vs-`blocked_by` cache check (`next:88`) and is blind to row/item disagreement, so AC4's named outcome holds against deliberately broken code. | **FAIL — unverified** |
| AC5 — `sh -n` passes, installed copy byte-identical to template | `sh -n` clean on all four templates; `cmp` identical for `claim`, `close`, `handoff`, `next`. | PASS |
| AC6 — `develop` and `verify` name `./handoff`, keep the by-hand fallback | `develop` Step 5 line 445 + fallback at 463; `verify` Step 5 line 325 with all three branches (331–333) + fallbacks at 286 and 336. | PASS |
| AC7 — `CONCURRENCY.md` states the release is the final act, with the 29-second window | `references/CONCURRENCY.md:181`, *The release is the final act*, carrying the 29-second window and "no lock can see this". | PASS |
| NFR Git — pathspec inside the lock, `Co-Authored-By` trailer | Hook witness proves both. Trailer read through git's own parser: `%(trailers:key=Co-Authored-By,valueonly)` → `Claude <noreply@anthropic.com>`. **The 2026-09-05 red is fixed.** | PASS |
| NFR Testing — throwaway repo per case, asserts on message and files, not exit status alone | Confirmed in source and reproduced independently with `cksum`/`git diff --cached` fingerprints. | PASS |
| NFR Dependencies — `/bin/sh`, `git`, `awk` only | Plus `mktemp`, as `claim` and `close` already use. | PASS |

**Ten mutations re-run rather than taken from the build notes** (control 104/0 before and after
every one): token guard neutered → 101/3; in-progress guard → 99/5; stage-agreement guard → 102/2;
no-claim guard → 103/1; five-fields presence check → 102/2; stage vocabulary → 101/3; `touches:`
skiplist narrowed to `^[ \t]+- ` → the read-back fires with `did not apply to: touches.entries`
(2 red); **drop `-m "$COAUTHOR"` → 103/1**; **fold the trailer into the subject `-m` → 103/1**,
the mutation a `grep`-based guard could not see; and **releasing the lock before the commit →
103/1, exactly the `pre-commit` hook witness**, confirming the build note that nothing else can
observe that defect.

**Why AC4 routes to `queue` and not to `develop`.** `handoff` is correct — the mechanism AC4
gestures at is verified decisively by AC1 (all five fields and both cells move in one commit) and
AC3 (the script refuses when row and item disagree going in, and reads both back before moving
either into place). What is broken is the criterion's **instrument**. Fixing it is a
re-specification decision — either AC4 becomes an assertion about the read-back, which AC1/AC2
already cover, making it redundant; or `./next --drift` gains a row/item agreement check, which is
code in `next`, a file outside this ticket's `touches:`. Neither pass nor fail is honest, and
`verify` may not re-specify. Ticking AC4 would record "verified by `--drift`" when `--drift`
verifies nothing, and `./close` closes on ticked ACs.

**Not this ticket's, and each already has a row:** `handoff:102` still warns-and-carries a foreign
`QUEUE.md` edit rather than refusing as `claim` now does (**0090** item 3); `claim` and `close`
carry no `Co-Authored-By` trailer, confirmed `trailer=` empty on both live claim commits from this
session (**0090** item 4); `claim.test.sh`/`close.test.sh` cannot see a lock released before the
commit (**0092**).

### Verify 2026-09-08 [6954] — PASS, all seven ACs and all three NFR rows green

Level `unit` per frontmatter; the QA plan's `**Level:** unit` agrees — no drift. Whole suite green at
baseline and at verdict: **23 files, 1,034 assertions, 0 failed**, run file-by-file per `config.yml`'s
note rather than fail-fast. Tree clean at Step 2 **and** at verdict, so the advisory intersection is
empty. Executed copy: the installed plugin at `0.9.19`, `diff -rq` byte-identical to this checkout.
Code and guards are unchanged since the build at `2344d29` — `git log 174b885..HEAD -- tests/` is
empty — so this pass re-drove the ACs and re-ran only the mutations it cites, per the re-specification
above.

| AC / NFR | How verified — and where | Result |
|---|---|---|
| AC1 — moves row + item, committed inside the lock, one invocation | Drove `./handoff 0007 8a04 verify` in a throwaway git repo. All five item fields moved (`next`→verify, `status`→ready, `claimed_by:`/`claimed_at:`/`touches:` cleared **with its two column-0 entries**), `expects:` untouched, both row cells moved, both neighbour rows untouched. A `pre-commit` hook witnessed `LOCK: present at commit time` and the staged set as exactly `QUEUE.md` + the item. Lock released after, fixture tree clean. | PASS |
| AC2 — status mismatch refuses and changes nothing (the 0087 case) | Both directions driven: item `ready` / row `in-progress`, and item `in-progress` / row `ready`. Each names the mismatch — `"the item reads 'ready' and the row reads 'in-progress'"` — rc=1, and a `cksum` over every file in the backlog directory was unchanged. | PASS |
| AC3 — refuses a wrong token and a row not at the expected stage, each own message, no file changed | Eleven distinguishable refusals driven, every one leaving the backlog byte-identical by `cksum`: wrong token, no `claimed_by:` at all, row/item stage disagreement, header with no `ID` cell, header missing `Next`, unknown row id, unrecognised stage, each of the three forbidden statuses (`blocked`/`done`/`in-progress`), and the usage error (rc=2). | PASS |
| AC4 — `./next --drift` exits zero for that row, **recorded as evidence of nothing** | Zero before the hand-off and zero after. Then the instrument's blindness reproduced independently: removing `mv "$queue_tmp" "$QUEUE"` (break diffed first — one line, confirmed landed) produced the exact 0087 drift, an item at `next: verify, status: ready, claimed_by:` empty over a row still reading `develop \| in-progress` — and `--drift` printed `no drift`, rc=0, identically. Source confirms why: `.claude/backlog/next:473-494` compares the `Status` column against `derived_of`/`blocked_by` and reads no item field. Ticked as the recorded observation the re-specification defines, **not** as *verified by `--drift`*; the atomicity is carried by AC1 and AC2. Blind report is `0115`. | PASS |
| AC5 — `sh -n` passes, installed copy byte-identical to template | `sh -n` clean on all four templates; `cmp -s` identical for `claim`, `close`, `handoff`, `next`. | PASS |
| AC6 — `develop` and `verify` name `./handoff`, keep the by-hand fallback | `develop` Step 5 line 445 names the command, fallback at 465–470. `verify` Step 5 line 325 with all three branches (331–333), fallbacks at 286 and 336. | PASS |
| AC7 — `CONCURRENCY.md` states the release is the final act, with the 29-second window | `references/CONCURRENCY.md:181`, *The release is the final act*, carrying the 29-second window and "No lock can see this". | PASS |
| NFR Git — pathspec inside the lock, `Co-Authored-By` trailer | Hook witness proves both halves. Trailer read through git's own parser: `%(trailers:key=Co-Authored-By,valueonly)` → `Claude <noreply@anthropic.com>`. Subject is imperative sentence case. | PASS |
| NFR Testing — throwaway repo per case, asserts on message and files, not exit status alone | `mktemp -d` per case (`tests/handoff.test.sh:130`), 17 file-state assertions across the file, and reproduced independently here with `cksum` fingerprints on all eleven refusals. | PASS |
| NFR Dependencies — `/bin/sh`, `git`, `awk` and nothing beyond what the other two use | Command set extracted from all three templates: `handoff` uses `awk cat date git grep head ls mktemp printf` — **identical to `close`**, and `claim`'s set plus `grep`. | PASS |

**Four mutations re-run — the ones this verdict cites** (control 104/0 before **and** after all four,
each break diffed to confirm it landed, each restored by its own pathspec):

- **drop `-m "$COAUTHOR"`** → 103/1, `FAIL — git parses a Co-Authored-By trailer on the hand-off commit`.
- **fold the trailer into the subject `-m`** → 103/1, same assertion. This is the mutation a `grep` of
  the commit body could not see, and it is why the guard reads through git's trailer parser.
- **release the lock before the commit** → 103/1, and the red is *exactly* the `pre-commit` hook
  witness (`FAIL — the lock was held when the commit ran`), confirming that nothing else in the file
  can observe the 29-second window.
- **`touches:` skiplist narrowed to `^[ \t]+- `** → the read-back fires with `did not apply to:
  touches.entries`. Note the shape: this collides with the guard's own internal mutation cases and the
  file exits **with no tally**, printing `FAIL — the mutation did not apply — the case below proves
  nothing`. That is the collision `verify` Step 3 warns about, observed here as documented.

**Newly-reachable states walked** (Step 4): every stage/status pair the script accepts — `queue ready`,
`design ready`, `develop ready`, `verify ready`, `develop waiting` — lands consistently in **both** the
row and the item, which covers `verify`'s three outgoing branches. The `queue` branch is not only
driven but live: `0081` itself travelled it at `174b885`. No destructive or privileged path is newly
reachable — `rm -rf "$LOCK"` resolves from `$DIR`, an absolute `cd`-resolved path, and the three
statuses a hand-off must never write are refused before the lock is taken.

**Not this ticket's, each already carrying a row:** `handoff:102` warns-and-carries a foreign
`QUEUE.md` edit rather than refusing as `claim` now does (`0090` item 3); `claim` and `close` carry no
`Co-Authored-By` trailer (`0090` item 4); `claim.test.sh`/`close.test.sh` cannot see a lock released
before the commit (`0092`). The bare `30` commit-retry limit sits outside each script's own named-
constant block in all three of `claim:198`, `close:416` and `handoff:345` — a shared house pattern
rather than this ticket's defect, and out of scope here.
