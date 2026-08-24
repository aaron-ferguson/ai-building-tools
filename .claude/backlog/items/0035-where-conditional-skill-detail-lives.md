---
id: "0035"
title: Decide where conditionally-needed skill detail lives
type: debt
next: design
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: agent
expects:
  - skills/prototype/SKILL.md
  - skills/develop/SKILL.md
  - references/
  - tests/skill-size.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Two skills are over the size goal, both recorded, and both for the same reason: they carry detail
that only *some* runs need.

**`prototype`** — Step 5 is 11,690 of its 23,394 bytes: level 1 (Mermaid), level 2 (clickable HTML)
and level 3 (Angular), plus the field-reference contract. Step 2 has already picked one level before
any of it is read, so a level-1 run — the cheapest and probably commonest ask — loads the drawer
rules and the Angular route registration for nothing.

**`develop`** — 21,313 bytes, carrying several worked anecdotes (the three-implementations story,
the contrast-ratio ticket, the batching measurement) alongside the rules they illustrate.

Aaron's direction, 2026-08-23: *"We should build in a way that heavily leverages pointers so that
extra context can be held in other files and pulled in as needed, and not always pulled into
context."* The soft goal in `tests/skill-size.test.sh` names relocation as the first move, and
`references/TRACKER.md` is the existing precedent for a conditionally-read file.

So the direction is settled. What is **not** settled is whether relocation actually pays here, and
that is a real question rather than a formality: for a level-2 `prototype` run the reference opens
in the same cycle, so the cost *moves* rather than falls. 0021 put this out of scope for exactly
that reason.

## Open design question

- **Question:** which kinds of skill detail move to a conditionally-read reference, and what is the
  test an author applies to decide? Specifically: do `prototype`'s three build procedures each
  become a reference, and do `develop`'s anecdotes move, get cut, or stay?
- **Why it blocks specification:** the acceptance criteria depend entirely on the answer. "Each
  level becomes `references/PROTOTYPE-L<n>.md`" is checkable by file existence and a byte count;
  "anecdotes compress in place" is a rule-by-rule diff; "nothing moves, the goal's reason stands"
  is a documentation change. These are three different tickets.
- **Settle it with:** `/design` — a decision about where content lives, not something to look at.

Sub-questions the decision has to answer:

1. **When does a pointer actually save anything?** A reference read on every run of its branch has
   moved the cost, not removed it. The saving is real only where a run *doesn't* open it — so the
   test is about the distribution of runs across branches, not about file size. State the test.
2. **Is an anecdote the same kind of thing as a procedure?** A procedure is used or not used. An
   anecdote is *evidence for a rule* — the rule stays either way, and the question is whether the
   evidence has to be co-located to be persuasive. A rule nobody believes gets skipped, which is
   the cost of moving its justification away.
3. **What does a skill lose by branching to a file?** A skill is read start-to-finish by a session
   that has already committed to a stage; a reference is read on a decision. Moving a *mandatory*
   step behind a pointer is how a step gets skipped. Which of `prototype` Step 5's content is
   mandatory-per-level versus reference-per-level?
4. **Does the field-reference contract in Step 5 belong with the levels or above them?** It appears
   to be shared across levels, which would make it the one part that must not move.

## Functional requirements

*Written once the design question is answered.*

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whatever the answer, the *test* an author applies goes somewhere durable — otherwise every future over-goal file re-litigates this | `documentation-conventions.md` |

## Acceptance criteria

*Blocked on the design question. Any relocation must also update the recorded reason in
`tests/skill-size.test.sh` — a file that comes back under the goal fails until its entry is
removed, so the guard will catch a half-finished move.*

## QA plan

- **Level:** verify — file content and byte counts, with the existing size guard doing the
  measuring.
- **Why this level:** to be re-confirmed with the ACs.
- **Specific checks:** `tests/skill-size.test.sh`; a read of each relocated file's entry point to
  confirm the branch is unmissable from the skill.

## Out of scope

- Changing the goal itself, or the guard's semantics. That landed 2026-08-23; 0028 does the same for
  the reference files.
- Cutting any rule. "No rule is dropped" outranks the goal, and this ticket is about *where* rules
  live, not which survive.

## Notes & decisions

- Recorded from two findings on 2026-08-23 — one about `prototype` Step 5, one arising when
  `develop` crossed the goal and had to record a reason. They are merged into one ticket
  deliberately: answered separately, two sessions would very likely give the same question two
  different answers, and the inconsistency would be worse than either answer.
- The precedents to compare against: `references/TRACKER.md` (conditionally read, opt-in feature)
  and `references/CONCURRENCY-INCIDENTS.md` (conditionally read, "open it when you hit this").
  Both are read on a *condition that usually does not hold*, which is exactly sub-question 1's test.
