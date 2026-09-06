---
id: "0081"
title: Give the hand-off a script, as claim and close have
type: feature
next: verify
status: ready
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
claimed_by:
claimed_at:
touches:
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
5. **`./next --drift` reports zero for the row handed off**, checked before and after.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | Commits by pathspec inside the lock, carrying the `Co-Authored-By` trailer. Never `git add -A`. | `git-conventions.md`, `CONCURRENCY.md` |
| Testing | Scaffolds a throwaway git repo per case and asserts on message and resulting files, never on exit status alone — matching `claim.test.sh` and `close.test.sh`. | `testing-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk`. Nothing beyond what the other two scripts use. | `dependency-conventions.md` |

## Acceptance criteria

1. `./handoff <id> <token>` moves a row and its item between stages, committed inside the lock, in one
   invocation.
2. Given an item whose `status:` does not match what the edit expects, it **refuses and changes
   nothing**, with a message naming the mismatch — the 0087 case.
3. It refuses a token that does not hold the claim, and a row not at the expected stage, each with its
   own message and no file changed.
4. After a successful hand-off, `./next --drift` exits zero for that row.
5. `sh -n` passes and the installed copy is byte-identical to the template
   (`tests/backlog-scripts-installed.test.sh`).
6. `develop` and `verify` name `./handoff` as the supported path and keep the by-hand fallback.
7. `CONCURRENCY.md` states that the release is a stage's final act, with the 29-second window as its
   reason.

## QA plan

- **Level:** unit — this repo's whole suite, plus a new `tests/handoff.test.sh`.
- **Why this level:** matches `claim.test.sh` and `close.test.sh`, which are the model.
- **Specific checks:** the refusal cases asserted on message **and** on files unchanged, since
  *exits non-zero* is satisfied by the silent refusal the rule forbids. Mutate each refusal branch
  away and confirm it reds; run one no-op control.

## Out of scope

- Changing what a hand-off means, or which stages hand to which. Only the mechanism.
- Retrofitting the 29-second window into closed tickets' history.

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
