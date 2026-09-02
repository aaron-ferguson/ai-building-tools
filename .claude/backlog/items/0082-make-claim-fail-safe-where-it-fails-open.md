---
id: "0082"
title: Make claim fail safe on the two paths where it currently fails open
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0081"]
expects:
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`./claim` has two paths where it does the safe thing and then does not enforce it.** Both were hit
in AetherWorks on 2026-08-24.

**1. It prints the `touches:` instruction instead of writing it.** The script commits the row and the
ownership keys, then *prints* "now set `touches:` before you open anything" and leaves that field to
the session. So **the one field the other window reads to decide what is safe to take is the only part
of the claim that is neither written nor committed atomically** — and it is trivially skipped, as it
was: item 0091 ran to completion with no `touches:` at all. `CONCURRENCY.md` requires an empty
`touches:` on an `in-progress` row to be read as *its files are held*, so the failure is not
catastrophic — but it converts a precise file scope into a blanket one, which is what
`expects:`/`touches:` exist to avoid. **The script already holds the lock and already knows the item's
`expects:`**, so it can write those as a provisional `touches:` and tell the session to narrow it —
failing safe where the print fails open.

**2. It warns that it is about to carry another session's work, and then carries it.** `claim` detected
that `QUEUE.md` already held another session's uncommitted row edit, said its commit would carry it,
and committed anyway. The other session's 0091 row change is now attributed to
`8f689f2 Claim 0034 [fc89]`. The warning is correct and the behaviour is the documented shared-index
hazard — but **a script that holds the lock can refuse instead of narrating**, and this script already
refuses rather than guesses on three other grounds.

## Functional requirements

1. **`claim` writes a provisional `touches:` from the item's `expects:`**, inside the lock and in the
   claim commit, and reports it with an instruction to narrow it rather than to create it.
2. **Where `expects:` is empty or absent**, say so explicitly and keep today's behaviour — a
   provisional scope invented from nothing would be worse than none.
3. **`claim` refuses when committing would carry a foreign edit to `QUEUE.md`**, naming the rows it
   would have taken and what to do (commit or restore them), and changes nothing.
4. **The refusal is distinguishable from the other three**, so a session can tell "someone else is
   mid-edit" from "your token is wrong".
5. **`CONCURRENCY.md`'s claim rules say `touches:` is written by the claim**, not after it, since the
   current wording is what licenses the gap.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | The refusal path must leave the index and tree exactly as found — a refusal that stages or restores someone else's work is worse than the carry it prevents. | `git-conventions.md`, `CONCURRENCY.md` |
| Testing | Refusals asserted on message **and** files unchanged, never on exit status alone. | `testing-conventions.md` |

## Acceptance criteria

1. Claiming an item with a non-empty `expects:` writes those paths as `touches:` in the claim commit.
2. The report says to narrow the provisional scope, and does not imply the field is unset.
3. An item with no `expects:` claims as it does today, and the report says the scope is unset.
4. With a foreign uncommitted edit to `QUEUE.md` present, `claim` **refuses**, names the affected rows,
   and leaves `QUEUE.md`, the item and the index byte-identical.
5. That refusal's message is distinct from the token, stage and table-shape refusals.
6. Each refusal branch, mutated away, turns `tests/claim.test.sh` red.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** matches `claim.test.sh`, which already scaffolds throwaway repos per case.
- **Specific checks:** a case that dirties `QUEUE.md` as another author before claiming, asserting
  refusal, the message, and `git diff` unchanged. A case with `expects:` populated asserting the
  written `touches:`. A case with `expects:` empty asserting today's behaviour. Mutate each new branch
  away; run one no-op control.

## Out of scope

- Making `claim` commit another session's work under its own message on purpose. FR3 is a refusal.
- Detecting a foreign edit in files other than `QUEUE.md` and the item being claimed.

## Notes & decisions

- Both paths recorded in AetherWorks' buffer, 2026-08-24, items 0034 and 0091, with the carrying commit
  named above.
