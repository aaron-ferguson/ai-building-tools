---
id: "0082"
title: Make claim fail safe on the two paths where it currently fails open
type: bug
next:
status: done
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
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
closed: 2026-09-08
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

- [x] AC1 — Claiming an item with a non-empty `expects:` writes those paths as `touches:` in the
  claim commit.
- [x] AC2 — The report says to narrow the provisional scope, and does not imply the field is unset.
- [x] AC3 — An item with no `expects:` claims as it does today, and the report says the scope is
  unset.
- [x] AC4 — With a foreign uncommitted edit to `QUEUE.md` present, `claim` **refuses**, names the
  affected rows, and leaves `QUEUE.md`, the item and the index byte-identical.
- [x] AC5 — That refusal's message is distinct from the token, stage and table-shape refusals.
- [x] AC6 — Each refusal branch, mutated away, turns `tests/claim.test.sh` red.

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
- **Built 2026-09-05 [5af1]. All five FRs land; the whole suite (20 scripts) is green.** Commits:
  `3588524` (FR1–FR4 and the guards), `5df1c11` (FR5 and a citation unwrap).
- **The refusal goes before the lock, and that placement is the requirement rather than a tidiness
  choice.** AC4 asks for "leaves the tree exactly as it found it", and there are two ways to satisfy
  it: refuse before anything is created, or undo what was. Only the first is true by construction —
  the second has to be right about every path out, including the ones `set -eu` takes. The check was
  already sitting above the lock as a warning, so refusing there cost nothing.
- **`exp` is an awk built-in (exponential), and using it as an array name is a parse error reported
  as `illegal statement` on the line that READS the array**, not the line that names it. The first
  implementation used `exp[++n]` and the message pointed at the `for` loop. Renamed `want[]`, and the
  trap is recorded in the script beside it.
- **Every rule in the frontmatter awk is guarded on `fm`, and dropping that guard is a data-loss bug
  no assertion about frontmatter can see.** The `inexp`/`intou` list rules match `/^[ \t]+-/`; without
  `fm` they would also swallow an indented bullet in the item's *prose*, silently, on every claim.
- **One parser, not two.** The report branches on how many `expects:` entries there were, and the
  obvious implementation is a second awk over the same frontmatter. The count is written out by the
  awk that does the rewrite instead: two parsers of one format drift, and the drift is silent — the
  file would say one thing and the report another, which is the class of defect this ticket is about.
- **The mutation sweep, 2026-09-05, against `skills/queue/templates/claim` — the copy the harness
  runs, not `.claude/backlog/claim`.** No-op control: 42/0. Refusal deleted (warn-and-carry restored):
  4 red. Refusal exits 0: 1 red — only the status assertion, which is the right shape, since AC4's
  message assertions are about *what it says* and stay true. `touches:` block written empty: 2 red.
  `expects:` entries never collected: 3 red. The unset branch made unconditional: 1 red. The fix was
  committed BEFORE the sweep, because `git checkout -- <path>` restores to `HEAD` and would otherwise
  have deleted it (`develop` Step 5).
- **FR5 was blocked for part of this session and the wait was the right call.** `references/CONCURRENCY.md`
  sits in `0081`'s `expects:` and `0081` really did edit it while building (`c6862fb`), so it was held
  under *The working tree is shared too* — `touches:` was empty, which reads as *its files are held*.
  Building FR1–FR4 and handing off with FR5 undone would have shipped a live contradiction: the script
  copies `expects:` into `touches:` while the rule said "never copied". Waited for `0081` to release,
  then wrote it. The author made this call; it is recorded because the next reader will see one ticket
  editing a file another ticket predicted and should know it was not an oversight.
- **What FR5 actually needed was narrower than it reads.** The captured FR says the wording "licenses
  the gap", but `CONCURRENCY.md` already said `touches:` is written *on claim*. The live contradiction
  was the parenthetical **"never copied"**, which the new script falsifies. The rule is kept and scoped
  — never-a-copy is about what a session leaves behind, not about what the script starts it with —
  rather than deleted, because an unnarrowed copy is still the wrong scope.
- **`skills/queue/templates/item.md`'s `touches:` comment needed no edit** and was not touched: it
  already reads "`develop` writes it on claim by verifying `expects:` against the code", which the new
  behaviour satisfies. Worth saying because that file is the obvious second place to look, and it is
  held by `0086`.
- **Three adjacent defects found and deliberately not fixed**, all parked in `FINDINGS.md`: `claim`
  edits the row before checking the item file exists (a third fail-open path this ticket does not
  name); `close` and `handoff` still warn-and-carry verbatim; and the `count` temp file leaks on an
  awk failure exactly as the pre-existing `tmp` does — fixing only the new one would leave the file
  inconsistent with itself.

## QA evidence

### Verify 2026-09-08 [f1ff] — PASS, all six ACs and both NFR rows green

Level `unit` per frontmatter (the QA plan agrees — no drift). Whole suite green at baseline and at
verdict: **23 files, 1,134 assertions, 0 failed**. Tree clean at Step 2 and at verdict. Executed
copy: the installed plugin at `0.9.19`, byte-identical to this checkout.

| AC / NFR | How verified — and where | Result |
|---|---|---|
| AC1 — non-empty `expects:` written as `touches:` in the claim commit | Observed on **this session's own two live claims**: `e3fadeb Claim 0081 [9840]` and `f0cc4df Claim 0082 [f1ff]` each carry the `touches:` block in the claim commit itself (7 and 4 paths). Reproduced in a throwaway repo with a `pre-commit` hook: `.lock` **held at commit time**, staged set exactly `QUEUE.md` + the item. | PASS |
| AC2 — the report says to narrow, and does not imply the field is unset | `"touches: is set provisionally from expects: (2 paths) — NARROW it in <item> to what you will actually open, and widen it the moment the work reaches further"`. | PASS |
| AC3 — an item with no `expects:` claims as today, report says the scope is unset | Claimed a fixture item with an empty `expects:`; `touches:` left empty and the report reads `"touches: is unset: 0009 declares no expects:, and a scope invented from nothing would be worse than none"`. | PASS |
| AC4 — with a foreign uncommitted `QUEUE.md` edit, refuses, names the rows, leaves `QUEUE.md` / item / index byte-identical | Dirtied a **different** row as another author, then claimed. Refused, printed the `-`/`+` row pair it would have carried, and `cksum` of `QUEUE.md` + the item and `git diff --cached --name-only` were all unchanged. `"nothing was changed and no lock was taken"` — and no `.lock` was left behind, because the check sits **above** the lock. | PASS |
| AC5 — that refusal's message is distinct from the token, stage and table-shape refusals | Four driven on clean trees: foreign edit (`"QUEUE.md holds uncommitted changes this claim's commit would carry"`), table shape (`"no table header … expected a row with an 'ID' cell"`), no row (`"no row for 9999 in QUEUE.md"`), not-ready (`"0007 is 'in-progress', not ready — pick another row"`). All distinct. | PASS |
| AC6 — each refusal branch, mutated away, turns `tests/claim.test.sh` red | Control 42/0 before and after each. Foreign-edit refusal deleted (warn-and-carry restored) → 38/4; the same refusal made `exit 0` → 41/1; `touches:` entry loop dropped → 40/2; `expects:` entries never collected → 39/3; the report's unset branch made unconditional → 41/1; not-ready refusal disabled → 39/3. | PASS |
| NFR Git — the refusal path leaves index and tree exactly as found | AC4's fingerprints, above: `QUEUE.md`, the item and the index all byte-identical, no lock taken. `LOCK` is absolute (`$DIR` via `cd -- … && pwd`). | PASS |
| NFR Testing — refusals asserted on message **and** files unchanged, never exit status alone | `tests/claim.test.sh:250–252` assert `QUEUE.md` byte-identical, the item byte-identical and the index untouched; reproduced independently. | PASS |

**Two pre-existing refusals do not redden, and both are the benign shape, not a gap.** Disabling
the table-shape refusal drops through to `"no Status column in the QUEUE.md table"`, and disabling
the no-row refusal drops through to `"9999 is '', not ready"` — in both cases rc=1, nothing
written, no lock taken. That is `verify` Step 3's "vaguer escalation with the same exit code": a
**message assertion worth adding**, not a failure, and outside this ticket's new branches (the QA
plan scopes the sweep to "each new branch"). Recorded for **0089**.

**Not this ticket's:** `claim` commits without the `Co-Authored-By` trailer — verified `trailer=`
empty on both of this session's live claim commits (**0090** item 4) — and releasing the lock
before `claim`'s commit reds nothing in `claim.test.sh` (**0092**).
