---
id: "0079"
title: Give a repo with no test runner a QA level that is a checklist
type: feature
next: design
status: ready
qa_level: verify
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0076", "0078"]
expects:
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`ai-building-conventions` has no test runner, and the lifecycle has no shape for that.** It holds
one script, `scripts/check-convention-links.sh`, which checks that cross-references resolve and
nothing else. Against that artifact:

- `develop` Step 4's TDD cycle has nothing to turn red;
- `develop` Step 5's *"run every runner the project has"* is vacuous;
- `qa_level: unit | integration | e2e` maps to nothing, so an item there declares a level that
  cannot be run;
- an NFR table citing `accessibility-conventions.md` for a prose edit is theatre.

**The gate that repo actually needs already exists and is written down** — in `CONVENTIONS_CORE.md`
itself. Does the rule earn its context rent (*Every rule pays rent in context*)? Is it a **principle**
or a **preference**, and is it in the right file for that? Does it contradict a rule stated elsewhere,
including a note saying not to do the thing just done? Is it stated as the failure it prevents rather
than the reasoning that produced it (`documentation-conventions.md`)? **Every one of those is a
review, and none is a test run.**

The AetherWorks retro of 2026-09-01 edited that repo three times and had nothing to check itself
against but its own judgement — the link script passes on any prose whatsoever.

## Open design question

**Is this a new `qa_level`, or a documented use of the existing `verify` level?**

`verify` is already defined as *"the scripted assertion the QA plan names, plus lint/typecheck if
present. It must be executed and its output shown"* — which a checklist is not. Three shapes, and the
decision is which:

1. **A new level** (`review`, say) whose "command" is a checklist the QA plan names. Honest, but adds
   a value to a vocabulary three skills read.
2. **`verify` plus a required checklist section** in the item, so the existing level carries it. No new
   vocabulary; risks reading as a downgrade.
3. **A per-repo `commands.review:`** in `config.yml` pointing at a checklist file, so the level stays
   `verify` and the repo supplies its content.

Also to settle: **who the checklist binds.** Whatever is chosen must make an unrun checklist *visible*
— the failure this item exists to prevent is a prose edit closing with nothing checked, which looks
identical to one properly reviewed.

## Functional requirements

*(To be completed by the design stage; the shape below is what the answer must cover.)*

1. A repo with no runner has a declarable QA level that `verify` can actually execute or perform.
2. The checklist's items come from `CONVENTIONS_CORE.md` and `documentation-conventions.md` and are
   cited, never restated.
3. `verify` records the checklist's result per item, the way it records an AC's evidence.
4. An item in such a repo cannot silently declare a level with no meaning.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The checklist cites the conventions; a second copy of a principle here would drift. | `documentation-conventions.md` |
| Testing | Whatever is chosen, an unperformed checklist must be distinguishable from a performed one — the *guard that cannot fail* rule applies to a human checklist too. | `testing-conventions.md` |

## Acceptance criteria

*(Written by the design stage once the question above is settled.)*

## QA plan

- **Level:** verify — the deliverable is prose in the skills plus, possibly, a config key.
- **Why this level:** matches every other skill-shape ticket in this backlog.

## Out of scope

- Adding a test runner to `ai-building-conventions`. The artifact is prose; a runner would be
  ceremony, and this item exists because the honest answer is a review.
- Changing what the conventions say. This is about how a change to them is checked.

## Notes & decisions

- Raised by the AetherWorks retro of 2026-09-01, which made three edits to that repo with no gate but
  its own judgement.
- The distinction worth keeping: the line is **has a runner or does not**, not *product versus tooling*.
  `ai-building-tools` has `tests/*.test.sh` and goes through the normal lifecycle today.
