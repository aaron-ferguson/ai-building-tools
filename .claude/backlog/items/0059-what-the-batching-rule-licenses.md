---
id: "0059"
title: Decide what the batching rule actually licenses
type: chore
next: develop
status: in-progress
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
claimed_by: "5ff9"
claimed_at: 2026-09-10T19:46:10Z
touches:
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
  - tests/batching.test.sh
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

- FR1 — `skills/develop/SKILL.md`'s batching statement gives **takeability at the stage** as its
  condition: any row `./next develop` hands you may be worked in the same session. Its rationale
  stays the amortised startup, and the two then license the same batch size.
- FR2 — That statement keeps shared file scope (`expects:` overlap) and a shared parent slice as
  **why a batch pays more** — orientation in the code, on top of the startup any batch amortises —
  never as the test of batchability, and keeps its one real precondition: tickets from unrelated
  projects do not batch.
- FR3 — That statement says the batch is assembled by **repeating `./next develop` after each
  close**, never by claiming a set up front, and cites `CONCURRENCY.md` for why holding rows you are
  not yet working on is the scope reservation it forbids.
- FR4 — `skills/verify/SKILL.md`'s batching statement gives a **different** condition — the tickets
  were **developed together in one gate** — and its own rationale: what a verify batch spends is the
  gate's independence, which is not a startup cost and is not amortised by anything. Rows merely
  sitting at `next: verify` are not thereby a batch.
- FR5 — Neither statement claims the other's rationale. Each says why the two conditions differ, so
  a reader meeting one does not carry it to the other stage — the current wording's shared "same
  batching case applies for the same reason" is what has to go.
- FR6 — `skills/verify/SKILL.md` names the intra-session Step 3 hazard — a suite run taken for one
  ticket while another ticket's mutation is live in the shared tree — and states what isolates it:
  one ticket at a time, with the tree at a clean committed state before the next ticket's first run,
  so Step 3's commit → mutate → confirm red → restore-by-path → control-green cycle completes inside
  the ticket that opened it (`testing-conventions.md`, restore before you assert).
- FR7 — `tests/batching.test.sh` asserts the settled condition **per file** rather than the current
  wording, and its assertions are anchored to the claim rather than to the paragraph containing it.

**Against the criteria this ticket already carried:** FR1–FR3 *confirm* the old FR1 for `develop`
and make it specific. FR4 and FR5 *change* it — the old FR1 asked only that condition and rationale
agree "in both skills, whichever way the answer goes", and the answer is that they agree per skill
with **different** conditions, which that wording would have read as a failure. FR6 *confirms* the
old FR2 and narrows it to `verify`, where Step 3 lives. FR7 *confirms* the old FR3, now plural.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Both skills carry the statement today and `tests/batching.test.sh` asserts on both, so the decision lands in both or the guard reds | `documentation-conventions.md` |
| Progressive delivery | Both skills ship to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the batching paragraph in `skills/develop/SKILL.md`, when read, then it states
  that any row `./next develop` hands you is batchable. **Red input:** the paragraph still offering
  "tickets that share a file scope or a parent slice" as the test of batchability.
- [ ] AC2 — Given that paragraph, when read, then shared file scope and a shared parent slice appear
  as the reason a batch pays more, not as a condition on entry. **Red input:** naming them only in a
  conditional clause governing whether the rows may be batched.
- [ ] AC3 — Given that paragraph, when read, then it states the batch is assembled by repeating
  `./next develop` after each close, and that rows are not claimed ahead of being worked. **Red
  input:** a paragraph naming no assembly mechanism.
- [ ] AC4 — Given `skills/develop/SKILL.md`, when read, then "Tickets from unrelated projects do not
  batch", "Claim and close each ticket individually" and "Stop at the first ticket whose contract
  turns out wrong" are all still present. **Red input:** deleting any one of the three.
- [ ] AC5 — Given the batching paragraph in `skills/verify/SKILL.md`, when read, then its condition
  is that the tickets were developed together in one gate, and it says in terms that rows merely
  sitting at `next: verify` are not a batch. **Red input:** the paragraph reading "any rows at the
  stage", which is `0132` AC2's red exactly.
- [ ] AC6 — Given both paragraphs, when read together, then neither offers the other's rationale and
  each says why the conditions differ. **Red input:** restoring "The same batching case applies for
  the same reason" to `verify`.
- [ ] AC7 — Given `skills/verify/SKILL.md`'s batching paragraph, when read, then it names the
  intra-session mutation hazard *and* the isolation that answers it. **Red input:** a paragraph
  carrying one without the other — "verify one ticket at a time" with no statement of what goes
  wrong otherwise is the likely half-done outcome.
- [ ] AC8 — Given `tests/batching.test.sh`, when run against the edited skills, then it passes; and
  given either skill's pre-decision batching sentence restored, when run, then it fails naming the
  condition rather than the paragraph window.

## QA plan

- **Level:** unit — this project's `unit` command runs every `tests/*.test.sh`, and the decision is
  prose-only, so `tests/batching.test.sh` carries the whole verdict.
- **Why this level:** no script changes, so there is nothing above unit to exercise. `0132` builds
  the selection this decision licenses and carries the `verify`-level criteria for it.
- **Specific checks:**
  - `for t in tests/*.test.sh; do "$t" || exit 1; done` — the batching guard is not the only file
    that greps these two paragraphs.
  - The guard extracts `develop`'s paragraph on `/one gate per session/` and exits 2 if it cannot
    match, so **that phrase stays lowercase, intact, on one line, and occurring exactly once**; and
    AC4's date binding needs `dated` within four characters of `**2026-08-22**` on the unwrapped
    window. Rewrapping the paragraph breaks both — see `CLAUDE.md`, *Tests*.
  - The guard's AC5 block currently asserts `one gate per session` in `verify` too. Under FR4 that
    phrase may not survive there in the same form; the guard moves with the decision rather than the
    wording being bent to keep it green.
  - Mutation for AC8's second half: restore the old sentence into one skill, confirm the failure
    names the condition and not the window.

## Out of scope

- **Any change to `./next` for the `develop` side.** No set-selection algorithm is needed there:
  `./next develop` already returns the first *takeable* row, a claimed row is not takeable, and
  repeating the call after each close walks the stage.
- **Selecting a verify batch in `--drive`, per-ticket evidence tables, the file-by-file suite run
  and red attribution** — all `0132`, which this ticket blocks and which builds what this decision
  licenses.
- **Whether two develop sessions may run at once, and worktree isolation between them** — `0137`.
  The isolation settled here is *intra*-session only.
- **Whether the stage stalls when rows collide** — `0050`. `./next`'s take-loop selection against
  held files — `0045`.
- **`verify` Step 1's missing every-row-held outcome** — `0058` FR1.
- Changing the "one skill per session" rule the batching rule sits inside.

## Notes & decisions

- Routed to `design` on trigger 1: the three shapes have incompatible acceptance criteria, and the
  chaining property means "make the condition checkable" is not a small implementation detail — it
  needs a definition first.
- Note the asymmetry worth carrying into the design pass: `develop` Step 1 *does* write down the
  every-row-collides outcome, and `verify` Step 1 does not. Whatever is decided here, the two
  skills' statements are asserted by one test file and must move together.

### 2026-09-10 — Design decision: the two stages get different conditions, and that is the answer

**The premise the ticket was written on is the thing that breaks.** It assumes one batching rule
with one condition, stated twice; the skills say as much today — `verify` opens "The same batching
case applies for the same reason". That shared rationale is what is wrong. `develop` batches to
amortise a startup, which is a pure saving. `verify` batches by spending the gate's independence,
which is not a cost anything amortises — it is the property being traded. One condition cannot serve
both, and forcing one is what makes the rule and its reason point in opposite directions.

**`develop` — the condition is the gate itself (shape one).** Takeability at the stage, and it is
already set-wide and checkable because `./next develop` applies it per row: stage match, no open
`blocked_by`, no claim, and no `expects:` file held by another session's `touches:`. Shared file
scope and a shared parent slice are demoted from condition to **the reason a batch pays more**. One
precondition survives, the one `develop` already states: tickets from unrelated projects do not
batch, because a different project's conventions and `CLAUDE.md` are a different startup rather than
a shared one.

**And the mechanism is how a session checks it.** The batch is assembled by **repeating `./next
develop`** — claim, work, close, ask again — never by selecting a set. A claimed row is not takeable,
so the next call hands the next row. No change to `./next` is needed, and the tool and the rule
agree because the tool never selected a set and the rule has stopped asking it to. It satisfies
`CONCURRENCY.md` by construction, since nothing is held before it is worked.

**`verify` — the condition is the develop gate (shape three, made specific).** A verify session may
hold several tickets only where they were developed together in one gate. This is the ticket's third
shape — the scope condition is advisory and the real limit is something else — with the something
else named: **the independence of the gate**, whose two failure modes `0132` records concretely
(halo across verdicts in one context; a red misattributed, as `config.yml` already records happening
on `0084`). Two properties make it the right condition rather than a compromise. It **dissolves the
chaining problem**, because the set is not derived from `expects:` overlap at all — it is the
membership a develop gate already fixed, so it is checkable set-wide without a definition of set-wide
overlap. And it **bounds what the batch re-reads**: the same files, in the same session that would
have re-read them anyway.

**Mutation isolation is ordering, not a worktree.** A batch's tickets are verified one at a time, and
the tree is at a clean committed state before the next ticket's first run, so Step 3's cycle
completes inside the ticket that opened it. `testing-conventions.md` already carries the general form
— a sweep that asserts before it restores leaves a mutation in the tree, and every reading after that
is measured against the wrong file — and what was missing is that a batch is precisely where the
next reading belongs to a *different ticket*. Serialising forfeits a shared suite run, but that
saving never existed: `verify` already forbids one verdict covering several tickets, so each ticket
pays for its own runs regardless.

**Rejected — "make the stated condition checkable set-wide" from `expects:` overlap.** Overlap
chains, so its transitive closure is the whole stage: the five-row batch this ticket cites is
connected 0032–0026–0029–0033 with 0031 attached at directory level only — satisfied pairwise, never
set-wide. A condition reaching every row is "any row at the stage" written obscurely. The only
non-vacuous reading, one file common to *all* members, would have forbidden the 0034/0035 pairing
that demonstrably paid, and would need a set-selection algorithm in `./next`, which returns exactly
one row by design (verified 2026-09-10: `./next verify` prints one `TAKE` line plus its `EXPECTS`).

**Rejected — one condition for both skills, in either direction.** "Any row at the stage" everywhere
is `0132` AC2's red and spends the independence this project ranks first. "Developed together"
everywhere would forbid `develop` batches that cost nothing and pay.

**Rejected — a worktree per batched ticket.** `0026`'s worktree rule answers *inter*-session
interference, where you cannot control the other window; intra-session the session owns the ordering,
so ordering is cheaper and stronger. A checkout per ticket also spends the startup saving batching
exists to produce. The inter-session question is `0137`'s.

**Trade-off accepted, and it is not free.** The two stages now read differently, and a session that
learns the rule at `develop` and carries it to `verify` gets it wrong — which is why FR5 requires
each statement to say why the conditions differ rather than merely stating its own. On the `develop`
side, dropping scope as a condition licenses batches whose per-ticket saving is smaller (startup
only, no shared orientation) and removes the only ground on which a batch could be called wrong other
than a violated guardrail.

**A consequence worth stating plainly:** the five-row verify pass this ticket cites as licensed
would **not** be licensed under this decision — those rows were not developed together. It closed
each ticket on its own ACs and nothing was lost, but it is now an instance of the rule this decision
writes, not evidence for the rule it replaces.

**Re-verified 2026-09-10, not taken from the ticket:** the two batching paragraphs as they stand
(`skills/verify/SKILL.md:23-32`, `skills/develop/SKILL.md:26-42`); `./next`'s four takeability tests
and its one-row output; `tests/batching.test.sh`'s paragraph-window extraction, which exits 2 rather
than failing if `one gate per session` stops matching on one line; and `0132`'s FR1/AC2 and `0137`'s
scope, both written after this ticket and both governing its answer.

### 2026-09-10 — Built (token 5ff9)

**The guard's `present`/`absent` helpers were the wrong instrument for most of this ticket, and it
showed up as a red on correct prose.** They grep the file line by line, so `Tickets from unrelated
projects do not batch` — AC4's phrase, untouched by this change — went red the moment the rewrapped
paragraph split it across a line break. The fix is not to bend the prose back: assertions about a
*claim* in flowing prose are made against the paragraph unwrapped to one logical line (`says`,
`says_not`, `binds` in the guard), and only a whole-file absence (`One item per invocation`) stays
line-based, because nothing about it depends on where the prose wraps. `CLAUDE.md`'s *Tests* rule
says rewrapping a guarded paragraph is a breaking change; this is the other half of it — a guard
built from line-based greps makes every rewrap a breaking change, whether or not the claim moved.

**`binds` is what makes AC2 falsifiable at all.** "Shared scope appears as a reason, not as a
condition" cannot be checked by presence: both wordings contain `expects:` and `parent slice`, which
is why the pre-0059 paragraph satisfied every scope assertion the old guard made. The check that
separates them is a bounded span — `expects:.{0,120}parent slice.{0,40}why a batch pays more` —
which holds only while the two halves sit inside the pays-more sentence.

**Both mutations red on the condition and not on the window, which is what AC8 asks.** Restoring
develop's `a set of tickets that share a file scope … or share a parent slice` gives 36/3 with the
three failures naming the condition; restoring verify's `The same batching case applies for the same
reason` gives 34/5. Neither exits 2 — the extraction anchors (`one gate per session` in develop,
`One gate per invocation` in verify) survive both, which was the risk the QA plan flagged. Control
run after restore: 39/39, tree clean.

**The QA plan expected `one gate per session` to be at risk in `verify`, and it went the other way.**
That phrase is gone from verify's paragraph — not because FR4 forbade it, but because verify's
condition is no longer *per session* at all: it is the membership a develop gate already fixed. The
guard's verify window is anchored on `One gate per invocation` instead, which is the paragraph's
first line and so gives the whole paragraph rather than starting mid-way as develop's anchor does.

**Verified against the source rather than the ticket:** `tests/measurement.test.sh` also greps for
`batch`, but against `MEASUREMENT.md`, not these two paragraphs — so nothing outside
`tests/batching.test.sh` is coupled to this wording. Whole suite green, 28 files.
