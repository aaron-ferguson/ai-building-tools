---
id: "0110"
title: Decide the shape of a ticket whose first requirement can kill the rest
type: chore
next:
status: done
qa_level: verify
close_by: verify
qa_manual:
size: m
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/item.md   # the optional Kill criteria section
  - skills/queue/SKILL.md            # Step 2, the gate-ticket rule
  - tests/gate-ticket.test.sh        # new; the guard on both
claimed_by:
claimed_at:
touches:
closed: 2026-10-25
---
## Problem

**A ticket whose first requirement is a gate that can kill the rest of it has no shape in
`item.md`, and the template quietly assumes every FR ships.**

The withdrawn `0104` (preserved at commit `7764732`) had FR1 as a measurement with written kill
criteria; FR2-FR6 existed only if it cleared. The honest close on a kill was *"MEASUREMENT.md
records the negative result and nothing else changed"*.

Nothing in the template or in `queue` Step 2 provides for a conditional FR, so the condition had to
be written inline into each dependent FR — *"and only if FR1 clears"* — and a whole acceptance
criterion was spent asserting the **killed** state, so that `verify` could not read a kill as an
unfinished ticket.

`discovery-conventions.md` carries the kill-criteria discipline and the item template has no field
for its result. So every gated ticket re-invents this, and a later reader cannot tell a killed FR
from a skipped one — which is the reading that matters, because one is a recorded verdict and the
other is abandoned work.

## Functional requirements

The shape is settled in `docs/decisions/004-a-gate-ticket-and-the-work-it-decides.md`; these FRs
implement it and do not restate its reasoning.

- **FR1 — An optional `## Kill criteria` section in `skills/queue/templates/item.md`**, marked
  *(only on a gate ticket)* like the other conditional sections. It holds: each threshold and the
  measurement that produces it, written before the measurement runs; a `**Verdict:**` line, empty
  until the measurement runs and then `cleared` or `killed` with the figure against every criterion
  and the date; and an `**If it clears:**` outline of the follow-on work, written as prose and never
  as FRs or checkbox criteria.
- **FR2 — A gate-ticket rule in `skills/queue/SKILL.md` Step 2.** Where work should exist only if a
  measurement clears, the measurement is its own ticket carrying that section, and the work it decides
  is **not filed** — neither as FRs in the gate ticket nor as a ticket `blocked_by` it. The rule states
  the reason in one sentence: `close` frees a dependent whatever the verdict. It cites decision `004`
  rather than restating the rejected alternatives.
- **FR3 — Gate criteria are satisfiable either way.** The same rule states that a gate ticket's ACs
  assert the verdict was recorded against every criterion, never that it was favourable, so the ticket
  closes `done` on a kill.
- **FR4 — The clear path uses the buffer.** The same rule states that a gate ticket carries an FR
  requiring, on `cleared`, one `FINDINGS.md` entry pointing at the ticket's *If it clears* outline — so
  the follow-on reaches `queue` through the Step 5 sweep, and on `killed` nothing else is written.
- **FR5 — A guard, `tests/gate-ticket.test.sh`**, asserting FR1's three parts in the template and
  FR2-FR4's rules in `queue` Step 2, each by a phrase that sits on one line, each able to red on its
  own.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The shape is stated once, in the template and `queue` Step 2; the reasoning and the rejected alternatives live only in decision `004`, which both cite | `tests/gate-ticket.test.sh` reds if the `004` citation is removed from Step 2; the verify pass greps Step 2 for `blocked_by` rejected-alternative prose (`conditional FR`, `third terminal`) and reds on a restatement | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/queue/templates/item.md`, when it is read, then it has a `## Kill criteria`
      section marked as only for a gate ticket, containing a `**Verdict:**` line and an
      `**If it clears:**` line. `tests/gate-ticket.test.sh`. **Red when:** any one of the heading, the
      Verdict line or the If-it-clears line is deleted while the other two stand — each reds its own
      assertion.
- [x] AC2 — Given `queue` Step 2, when the gate-ticket rule is read, then it says the decided work is
      not filed as FRs or as a `blocked_by` dependent, and gives `close` freeing a dependent whatever
      the verdict as the reason. `tests/gate-ticket.test.sh`. **Red when:** the not-filed sentence is
      deleted, or the reason sentence is deleted, each on its own.
- [x] AC3 — Given `queue` Step 2, when the rule is read, then it states a gate ticket's criteria assert
      the verdict was recorded, not that it was favourable. `tests/gate-ticket.test.sh`. **Red when:**
      that sentence is deleted.
- [x] AC4 — Given `queue` Step 2, when the rule is read, then it requires the `FINDINGS.md` entry on
      `cleared` and cites `docs/decisions/004`. `tests/gate-ticket.test.sh`. **Red when:** the
      FINDINGS sentence is deleted, or the `004` citation is deleted, each on its own.
- [x] AC5 — Given the template and Step 2 as shipped, when `0104`'s subject (preserved at `7764732`) is
      rewritten as a gate ticket against them in a scratch file, then it needs no heading, field or
      condition the template does not provide, and none of its ACs is conditional on the verdict.
      **Red when:** the rewrite has to add an inline "only if it clears" clause or an AC asserting the
      killed state — the two inventions this ticket exists to remove.

## QA plan

- **Why that level:** the deliverable is prose in a template and a skill; the greps in
  `tests/gate-ticket.test.sh` are the mechanical check, and AC5 is the check the original plan named —
  whether a gated ticket can now be written without inventing a form.
- **Specific checks:** run `tests/gate-ticket.test.sh` alone, then the full suite with
  `for t in tests/*.test.sh; do "$t" || true; done` so an unrelated red is attributable. Delete each
  pinned phrase one at a time and confirm it reds its own assertion, not a catch-all. Do AC5's rewrite
  in the scratchpad, never under `items/` — a fixture id must not look like a real backlog row.

## Out of scope

- Re-issuing the withdrawn `0104`. Its ID is burned (`0105`) and its subject shipped separately.
- Changing `discovery-conventions.md` or `measurement-conventions.md`. Both are correct; what was
  missing is a place in the backlog to record their result.
- **Any change to `close`, `next` or `verify`.** Decision `004` is chosen so that a gate ticket ends in
  the existing two terminal states; a change to any of the three is a sign the shape has drifted.
- Migrating `0001`'s or `0016`'s existing kill-criteria prose into the new section — closed records
  stay as observed.

## Notes & decisions

- 2026-09-07 — Filed by `retro` at `next: design` rather than deferred in the buffer. The choice
  between A and B is a real decision with a real trade-off, and the queue has a stage for that;
  leaving it parked would have meant the next retro paying to re-derive the same two options.

- **2026-09-12 — Design pass, `/design`. Neither A nor B: the gate is its own ticket, and the work
  it decides is not filed until it clears.** Full record: `docs/decisions/004-a-gate-ticket-and-the-work-it-decides.md`.
  Settled on two mechanisms observed today, not on preference:
  1. **A fails on `close`'s ticking.** `.claude/backlog/close:698` ticks every `- [ ]` in *Acceptance
     criteria* unconditionally, so a killed ticket holding ACs for unshipped FRs closes with them
     ticked — a record of checks nobody ran. Honest A needs a third AC state in `close` and a third
     terminal reading in `verify`.
  2. **B fails on `close`'s reconcile.** `tests/close.test.sh` AC8 (run 2026-09-12, 246 passed, 0
     failed) proves a closing blocker frees its dependents to `ready` regardless of verdict — so a
     killed gate would release killed work straight to `develop`. Withdrawing the gate instead leaves
     them blocked for good: `next` counts any blocker whose status is not `done` as open.
  **The cost accepted:** a gate that clears pays one `queue` sweep to specify its follow-on, one stage
  later than pre-specifying. Bought back by specifying against measured figures — `0104`'s thresholds
  would have been rewritten anyway.
  **Validated against the ticket's own requirement:** a killed FR is distinguishable from a skipped
  one because no killed FR exists — the record is a `done` gate whose *Verdict* reads `killed`, where
  abandoned work is a `withdrawn` ticket. The Documentation NFR row gained a *How it would red*
  column per `0107`. `close_by: verify` set explicitly: AC5 is a judgement, so the light tier does not
  apply.

- 2026-10-25 — develop (844a): **built** in `6ca3875`.
  - `## Kill criteria  *(only on a gate ticket)*` sits in `item.md` directly above
    *Acceptance criteria*, after the other conditional sections; its `- **Criterion:**` bullet lives
    outside the AC section, so `close`'s ticking and `item-ac-form.test.sh` never read it (run: both
    suites green). The gate rule is one paragraph in `queue` Step 2, immediately above *Set `next`
    now*, citing `004` by path; the rejected alternatives are not restated (guarded by two absence
    cases scoped to the paragraph).
  - **The guard's windows are scoped**, the template section from its heading to the next `## `,
    the rule from its opening phrase to the next blank line, plus a case that the rule opens inside
    Step 2. `window()` sets `first` on the opening line, which is the fix the 0089 notes name for
    `falsifiable-acs.test.sh` (the same defect is fixed in `remote-anchor.test.sh` by 0216).
  - **Mutation sweep — run**, scratch copy, one per phrase: heading marker, heading renamed (EMPTY,
    named), Verdict, If-it-clears, prose-only clause, not-filed, neither-FRs-nor-blocked_by, the
    reason, verdict-recorded, never-favourable, on-cleared FINDINGS entry, the `004` citation, a
    restated `conditional FR` (NFR), and the rule moved out of Step 2. Each reddened its own case
    (13/1); the two structural ones reddened every case in their window.
  - **AC5 — a rewrite was done, for verify to judge, not closed here.** Scratch file outside the repo
    (`/tmp/0110-scratch/gate-rewrite.md`, id `9104`): 0104 as a gate ticket needed no heading or field
    the template lacks; FR2-FR7 became the *If it clears* outline; no FR carries "only if it clears"
    and no AC asserts the killed state. **One judgement verify should make:** its AC3 reads "given
    `cleared` … one entry; given `killed` … no entry" — satisfiable either way, but it does name both
    verdicts. A single-branch form ("an entry exists exactly when the verdict reads `cleared`") reads
    the same; I do not believe it is the conditional AC this ticket removes, but it is the closest
    the rewrite came.
  - Sizes: `queue/SKILL.md` grew by the one paragraph; `skill-size` green.


## QA evidence

2026-10-25 — verify (daba). **PASS.**

Conventions: ../ai-building-conventions
Command (the QA plan's scripted assertion, verbatim): `tests/gate-ticket.test.sh` → `gate-ticket: 14 passed, 0 failed`, at the 0110 claim commit, clean tree. No lint or typecheck is configured. Whole suite, run in this session over the same non-backlog tree: by-file (`for t in tests/*.test.sh; do "$t" || true; done`, at `0b85f60`) gave every one of 34 files `0 failed`, including `item-ac-form` `8 passed, 0 failed` and `close` `281 passed, 0 failed`. Fail-fast `commands.unit` at `b5f8f7d` exited 0.
Copy executed: the repo copies (`skills/queue/templates/item.md`, `skills/queue/SKILL.md`). The installed 0.9.42 plugin predates this change.
Digest: `.claude/backlog/next --ac-digest 0110 --check` → `0110: ac_digest absent — unverifiable`. Recorded as **ac_digest absent — unverifiable**, not as a match.

Mutations: re-run by this pass in a detached worktree at the claim commit, each restored by path, worktree clean afterwards. Control: `gate-ticket: 14 passed, 0 failed`.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | heading marked only for a gate ticket | marker removed | `13 passed, 1 failed`, own case |
| AC1 | `## Kill criteria` section exists | heading deleted | `10 passed, 4 failed`, every template case `EMPTY` |
| AC1 | `**Verdict:**` line | removed, others standing | own case red |
| AC1 | `**If it clears:**` line | removed, others standing | own case red |
| AC1 (FR1) | outline is prose, never FRs/checkbox criteria | clause reworded | own case red |
| AC2 | not-filed sentence | reworded | own case red |
| AC2 | neither FRs nor `blocked_by` | reworded | own case red |
| AC2 | reason: `close` frees a dependent whatever the verdict | reworded | own case red |
| AC3 | criteria assert the verdict was recorded / never favourable | each reworded | each red, own case |
| AC4 | on `cleared`, one `FINDINGS.md` entry | reworded | own case red |
| AC4 | cites `docs/decisions/004` | citation removed | own case red |
| scope | rule sits in Step 2 | Step 2 heading renamed | own case red (`EMPTY`) |
| AC5 | 0104 rewritable as a gate ticket with no invented form | judgement: this pass rewrote 0104 (at `7764732`) independently, in a scratch file outside the repo under fixture id `9904` | **holds.** It used only template headings (`## Kill criteria`, `- **Criterion:**` ×3, `**Verdict:**`, `**If it clears:**`). FR2–FR6 became the prose outline. No FR carries "only if it clears", and no AC asserts the killed state (0104's old AC2, "verify unchanged on a kill", has nothing left to assert). The one verdict-referencing AC is the `FINDINGS.md` entry "exists exactly when the Verdict reads `cleared`". That is a biconditional over the gate's own output, required by the rule's FR4, and satisfiable either way, so it is not the conditional AC this ticket removes. |

NFRs:

| Row | Check | Result |
|---|---|---|
| Documentation | `004` citation mutation red; restating `conditional FR` and `third terminal` in the rule each red (`found: …`) | holds, guarded |

Out-of-scope check: `git show --stat 6ca3875` touches no `close`, `next` or `verify`.
Always-on (`CONVENTIONS_CORE.md`): prose-only change, with no secrets and no company material.
Advisory: Step 2 dirty set was empty, and the verdict-time capture was empty. The intersection is empty, so this is not advisory.
