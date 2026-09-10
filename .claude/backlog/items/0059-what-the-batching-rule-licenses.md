---
id: "0059"
title: Decide what the batching rule actually licenses
type: chore
next: develop
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0025", "0026", "0050", "0058"]
expects:
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
  - tests/batching.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

The batching rule says tickets that **share a file scope or a parent slice** are checked in one
session, justified by the conventions, the skill and the suite's startup being "a shared cost paid
once however many verdicts come out of it". The stated condition and the stated reason point in
opposite directions, and nothing reconciles them.

**The rationale argues for the largest batch available.** What is amortised is startup, paid once
whatever the batch size — so on its own reasoning, two rows sharing nothing should still be taken
together. 0034 (`skills/verify/SKILL.md`, `references/CONCURRENCY.md`) and 0035 (`tests/*.test.sh`)
share neither scope nor parent, and a session reading the condition literally splits them across
two sessions to no benefit. They were taken as one gate and each closed on its own ACs.

**The condition, meanwhile, cannot be checked set-wide, because overlap chains.** One session took
all five `next: verify` rows in a single pass — licensed by `verify`'s own "one gate per session,
not one ticket per session". Checked against the stated condition, by declared `touches:` **no two
of the five share a parent** (only 0026 has one at all), and by exact file the batch is a *chain*
rather than a set: 0032–0026 via `skills/develop/SKILL.md`, 0026–0029 via `skills/verify/SKILL.md`,
0029–0033 via `references/CONCURRENCY.md`, and 0031 attached only at directory level, sharing no
file with any of them. 0026 and 0033 share nothing; 0026 and 0031 share nothing. So the constraint
is satisfied pairwise and transitively but never set-wide — and because overlap chains, any starting
row reaches the entire stage. `./next <stage>` selects by stage regardless, so the only
row-selection tool does not implement the condition at all.

**And the rule does not name its own hazard: Step 3.** Verifying an AC requires deliberately
breaking the check behind it to prove it can red. In a batch those mutations land in the working
tree the other tickets' passes share, with no ordering or isolation rule given — so a suite run for
ticket B while ticket A's mutation is live reads as B's red. 0026's notes already record the
*inter*-session form of exactly this ("a full-suite run taken while another window is mid-edit is a
verdict about a tree that never existed as a commit") and settle on a throwaway worktree; a batch
reproduces it *intra*-session, where there is no other window and that note does not reach.

## Functional requirements

- FR1 — The batching statement in `skills/develop/SKILL.md` and `skills/verify/SKILL.md` states its
  condition as **takeability at the stage**: any row `./next <stage>` hands you may be worked in the
  same session. Condition and rationale then license the same batch size.
- FR2 — Both statements keep shared file scope (`expects:` overlap) and a shared parent slice as
  **why a batch pays more** — orientation in the code, on top of the startup any batch amortises —
  never as the test of batchability. The one surviving precondition is the one `develop` already
  carries: tickets from unrelated projects do not batch.
- FR3 — Both statements say the batch is assembled by **repeating `./next <stage>` after each
  close**, never by claiming a set up front, and cite `CONCURRENCY.md` for why holding rows you are
  not yet working on is the scope reservation it forbids.
- FR4 — `skills/verify/SKILL.md` names the intra-session Step 3 hazard — a suite run taken for one
  ticket while another ticket's mutation is live in the shared tree — and states what isolates it:
  one ticket at a time, with the tree at a clean committed state before the next ticket's first
  run, so Step 3's commit → mutate → confirm red → restore-by-path → control-green cycle completes
  inside the ticket that opened it (`testing-conventions.md`, restore before you assert).
- FR5 — `tests/batching.test.sh` asserts the settled condition rather than the current wording, and
  its assertions are anchored to the claim rather than to the paragraph containing it.

**Against the criteria this ticket already carried:** FR1 and FR2 *confirm* the old FR1 and make it
specific; FR4 *confirms* the old FR2 and narrows it to `verify`, where Step 3 lives; FR5 *confirms*
the old FR3 unchanged. FR3 is *added* — the assembly mechanism is what makes the condition
checkable without touching `./next`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Both skills carry the statement today and `tests/batching.test.sh` asserts on both, so the decision lands in both or the guard reds | `documentation-conventions.md` |
| Progressive delivery | Both skills ship to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the batching paragraph in each of `skills/develop/SKILL.md` and
  `skills/verify/SKILL.md`, when read, then each states that any row `./next <stage>` hands you is
  batchable. **Red input:** either paragraph still offering "tickets that share a file scope or a
  parent slice are checked in one session" as the test of batchability.
- [ ] AC2 — Given either paragraph, when read, then shared file scope and a shared parent slice
  appear as the reason a batch pays more, not as a condition on entry. **Red input:** a paragraph
  that names them only in a conditional clause governing whether the rows may be batched.
- [ ] AC3 — Given either paragraph, when read, then it states the batch is assembled by repeating
  `./next <stage>` after each close and that rows are not claimed ahead of being worked. **Red
  input:** a paragraph naming no assembly mechanism.
- [ ] AC4 — Given `skills/develop/SKILL.md`, when read, then "Tickets from unrelated projects do not
  batch", "Claim and close each ticket individually" and "Stop at the first ticket whose contract
  turns out wrong" are all still present. **Red input:** deleting any one of the three.
- [ ] AC5 — Given `skills/verify/SKILL.md`'s batching paragraph, when read, then it names the
  intra-session mutation hazard *and* the isolation that answers it. **Red input:** a paragraph
  carrying one without the other — "verify one ticket at a time" with no statement of what goes
  wrong otherwise is the likely half-done outcome.
- [ ] AC6 — Given `tests/batching.test.sh`, when run against the edited skills, then it passes; and
  given either skill's pre-decision batching sentence restored, when run, then it fails naming the
  condition rather than the paragraph window.

## QA plan

- **Level:** unit — this project's `unit` command runs every `tests/*.test.sh`, and the decision is
  prose-only, so `tests/batching.test.sh` carries the whole verdict.
- **Why this level:** no script changes, so there is nothing above unit to exercise.
- **Specific checks:**
  - `for t in tests/*.test.sh; do "$t" || exit 1; done` — the batching guard is not the only file
    that greps these two paragraphs.
  - The guard extracts `develop`'s paragraph on `/one gate per session/` and exits 2 if it cannot
    match, so **that phrase stays lowercase, intact, on one line, and occurring exactly once**; and
    AC4's date binding needs `dated` within four characters of `**2026-08-22**` on the unwrapped
    window. Rewrapping the paragraph breaks both — see `CLAUDE.md`, *Tests*.
  - Mutation for AC6's second half: restore the old sentence into one skill, confirm the failure
    names the condition and not the window.

## Out of scope

- **Any change to `./next`.** The decision is that no set-selection algorithm is needed: `./next
  <stage>` already returns the first *takeable* row, a claimed row is not takeable, and repeating
  the call after each close walks the stage. Adding batch selection would build the thing this
  decision found unnecessary.
- **Whether the stage stalls when rows collide** — 0050.
- `./next`'s take-loop selection against held files — 0045.
- **`verify` Step 1's missing every-row-held outcome** — 0058 FR1. This decision makes that case
  more common, and says so, but does not write it.
- Changing the "one skill per session" rule the batching rule sits inside.

## Notes & decisions

- Routed to `design` on trigger 1: the three shapes have incompatible acceptance criteria, and the
  chaining property means "make the condition checkable" is not a small implementation detail — it
  needs a definition first.
- Note the asymmetry worth carrying into the design pass: `develop` Step 1 *does* write down the
  every-row-collides outcome, and `verify` Step 1 does not. Whatever is decided here, the two
  skills' statements are asserted by one test file and must move together.

### 2026-09-10 — Design decision: a batch is a session that keeps going, not a set chosen up front

**Decided — shape one, "the gate itself", with the real limit named.** The condition is
takeability at the stage, and it is already set-wide and checkable, because `./next <stage>`
applies it per row: stage match, no open `blocked_by`, no claim, and no `expects:` file held by
another session's `touches:`. Shared file scope and a shared parent slice are demoted from
condition to **the reason a batch pays more** — they add orientation in the code on top of the
startup any batch amortises. One precondition survives, the one `develop` already states:
**tickets from unrelated projects do not batch**, because a different project's conventions and
`CLAUDE.md` are a different startup rather than a shared one.

**And the mechanism is the answer to how a session checks it.** The batch is assembled by
**repeating `./next <stage>`** — claim, work, close, ask again — never by selecting a set. A
claimed row is not takeable, so the next call hands the next row. This is why no change to `./next`
is needed and why the tool and the rule now agree: the tool never selected a set, and the rule has
stopped asking it to. It also satisfies `CONCURRENCY.md` by construction, since nothing is ever
held before it is worked.

**Mutation isolation is ordering, not a worktree.** A batch's tickets are verified one at a time,
and the tree is at a clean committed state before the next ticket's first run — Step 3's
commit → mutate → confirm red → restore-by-path → control-green cycle completes inside the ticket
that opened it. `testing-conventions.md` already carries the general form ("a sweep that asserts
before it restores leaves a mutation in the tree… every reading after that is measured against the
wrong file"); what was missing is that a batch is precisely where the next reading belongs to a
different ticket.

**Rejected — "make the stated condition checkable set-wide."** Overlap chains, so its transitive
closure is the whole stage: the observed five-row batch is connected 0032–0026–0029–0033 with 0031
attached at directory level only — satisfied pairwise, never set-wide. A condition reaching every
row is "any row at the stage" written obscurely. The only non-vacuous reading, one file common to
*all* members, would have forbidden the 0034/0035 pairing that demonstrably paid, and would need a
set-selection algorithm in `./next`, which returns exactly one row by design (verified
2026-09-10: `./next verify` prints one `TAKE` line plus its `EXPECTS`).

**Rejected — "the condition is advisory."** True of the scope clause, and this decision says as
much, but as the whole answer it leaves a session with "batch when it seems worth it" and leaves
`tests/batching.test.sh` no claim to anchor to.

**Rejected — a worktree per batched ticket.** 0026's worktree rule answers *inter*-session
interference, where you cannot control the other window; intra-session the session owns the
ordering, so ordering is cheaper and stronger. A checkout per ticket also spends the startup saving
batching exists to produce.

**Trade-off accepted.** Dropping scope as a condition licenses batches whose per-ticket saving is
smaller — startup only, no shared orientation — and removes the only ground on which a batch could
be called wrong other than a violated guardrail. Serialising the tickets forfeits a shared suite
run, but that saving never existed: `verify` already forbids one verdict covering several tickets,
so each ticket pays for its own runs regardless.

**Re-verified 2026-09-10, not taken from the ticket:** the two batching paragraphs as they stand
(`skills/verify/SKILL.md:23-32`, `skills/develop/SKILL.md:26-42`); `./next`'s four takeability
tests and its one-row output; and `tests/batching.test.sh`'s paragraph-window extraction, which
exits 2 rather than failing if `one gate per session` stops matching on one line.
