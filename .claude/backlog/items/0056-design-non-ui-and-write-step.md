---
id: "0056"
title: Give design a non-UI reading list and complete its write step
type: bug
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0007", "0034", "0035", "0036"]
expects:
  - skills/design/SKILL.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`design` was written for questions about a surface. `next: design` now routinely catches
*mechanism* decisions — 0007 asks whether claiming writes `QUEUE.md`, 0034 whether an advisory PASS
closes — and for those the skill points at nothing and omits what every other writing stage states.

**Step 2's three ordered lookups are prior art, the design system, and "the files the core's index
names for design, UI and accessibility".** Followed literally on 0007, that sends the session to
`design-conventions.md` and the `neumo-ds` MCP, neither of which has anything to say. What actually
decided it was `migration-conventions.md` (*Expand, Migrate, Contract*) and the project's own
`CONCURRENCY-INCIDENTS.md`. The step has a clause for "if the question touches user-facing UI" and
none for the other case, so a non-UI design session either invents its own reading list or cites
nothing.

**Step 4 writes `QUEUE.md` and never mentions the lock.** It tells a session holding an unclaimed
ticket to set `next: develop` / `status: ready` and commit by pathspec — that row edit is a
`QUEUE.md` write, and `CONCURRENCY.md` says every write to it is locked, "every write, no
exemptions". `verify` Step 5 and `develop` both spell the lock out; `design` is the one writing
stage that omits it. Settling 0034, the lock was taken only because that file had been read for the
decision itself.

**Step 4 moves a ticket's stage and never says to re-check `expects:`.** Settling 0035, the answer
changed the work from editing `skills/prototype/SKILL.md` + `skills/develop/SKILL.md` to editing two
files under `tests/` — a completely disjoint scope. Step 4 lists *Notes & decisions*, the FRs and
ACs, the stage fields and the commit, and stops, so a session following it literally hands `develop`
an `expects:` describing the work the decision rejected. A design answer is exactly the event that
can narrow or move a file scope, and in this repo a wrong scope is what stalls the next stage.

**Step 4 has no route for an answer whose consequence is a second ticket.** Its four cases are
item-scoped-unclaimed, item-scoped-claimed, has-to-be-seen, and standing. 0007's answer implied an
expand/contract split whose honest shape is arguably two rows — but minting an ID is a `queue` write
against `config.yml`, and Step 4 neither authorises it nor names the handoff. It was resolvable by
keeping both phases in one ticket with an ordering FR, so nothing was lost; the gap is that the
resolution was forced by the skill's silence rather than chosen.

**A ticket's `## Out of scope` can foreclose the only answer to its own `## Open design question`.**
0034 asked whether an advisory PASS closes, while its out-of-scope line said "Step 2's trigger is
not in question" — but no answer exists without moving where the advisory label is decided. The
skill says answer *that* question and not a broader one, which reads as "obey the fence"; taken
literally it makes the ticket unanswerable. Resolved by narrowing the out-of-scope line in the same
edit and saying so, but that move is invented rather than instructed.

**And a design pass can confirm a load-bearing fact by running it rather than reading it.** 0036's
decision rested on `claude -p --bare` and cited its docs for "skills still resolve via
`/skill-name`" — true, and the same paragraph also skips CLAUDE.md auto-discovery and refuses OAuth.
So the settled mechanism was a stage session building with no conventions loaded, on a second
billing path, and it would have passed every test in `tests/` because nothing greps a subprocess's
context. That pass's own *"every input was a checkable fact and was checked"* is what made it
invisible.

## Functional requirements

- FR1 — Step 2's third lookup is "the convention files this question turns on, per the core's
  index", and the design system becomes a **conditional** lookup taken when the question touches a
  surface rather than an ordered one taken always.
- FR2 — Step 2 names the project's own reference files as a lookup for a question about the
  project's own mechanisms, since that is what actually decided 0007 and 0034.
- FR3 — Step 4 states that its row edit takes the lock, citing `CONCURRENCY.md` *Lock every write to
  `QUEUE.md`* rather than restating the rule.
- FR4 — Step 4 requires `expects:` to be re-checked against the decision before the handoff, and
  says a decision that moves the file scope is the normal case rather than an exception.
- FR5 — Step 4 gains a fifth case: the answer splits the work — write the FRs here, and say in the
  report that `queue` should consider a split — so a design pass never mints an ID and never has to
  invent the handoff.
- FR6 — The skill states that a design answer may narrow an *Out of scope* line that forecloses its
  own question, and how to record that it did.
- FR7 — The skill states that a fact taken from a tool's own help text is quoted whole rather than
  summarised to the clause the decision needed.
- FR8 — Every rule added cites its convention rather than restating it, and each citation resolves
  under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | FR3 cites the concurrency rule rather than copying it — a second copy of the lock rule is a second thing to keep true | `documentation-conventions.md` |
| Progressive delivery | This skill ships to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given Step 2, when read, then its third lookup names the convention files the question
  turns on rather than the design, UI and accessibility files specifically.
- [ ] AC2 — Given Step 2, when read, then the design system is a conditional lookup, not an
  unconditional ordered one.
- [ ] AC3 — Given Step 2, when read, then it names the project's own reference files as a lookup.
- [ ] AC4 — Given Step 4, when read, then it says the row edit takes the lock and cites the rule by
  name.
- [ ] AC5 — Given Step 4, when read, then it requires `expects:` to be re-checked before handoff.
- [ ] AC6 — Given Step 4, when read, then it has a case for an answer that splits the work, and
  that case does not mint an ID.
- [ ] AC7 — Given the skill, when read, then it says a design answer may narrow a foreclosing
  *Out of scope* line and how to record it.
- [ ] AC8 — Given the skill, when read, then it says a fact from a tool's help text is quoted whole.
- [ ] AC9 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.

## QA plan

- **Level:** verify — the deliverable is prose in one skill file and no test runner applies; the
  scripted assertions are the scoped greps below plus the citation and size guards.
- **Why this level:** nothing executable changes.
- **Specific checks:** each grep **scoped to the step it asserts on**, matching a phrase short
  enough to sit on one source line. Then `tests/citations.test.sh`, `tests/skill-size.test.sh` and
  the full suite.

## Out of scope

- **Whether `design`'s row edit should be a script rather than a by-hand lock.** That is 0048.
  FR3 states the rule as it stands today, which is correct whichever way 0048 goes.
- Changing what `next: design` catches, or the two routing triggers in `queue`.
- The `neumo-ds` MCP itself, which is a company tool this public repo must not depend on.

## Notes & decisions

- Routed to `develop`: every gap has a stated fix in the finding that reported it, and FR1's
  wording was proposed there verbatim. Nothing is undecided.
- FR7 is smaller than the others and kept because the failure it prevents is the largest: a settled
  mechanism that would have passed every test in the repo while running with no conventions loaded.
