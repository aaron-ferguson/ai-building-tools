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
