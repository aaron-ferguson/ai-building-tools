---
id: "0062"
title: Let a ticket's contract express a removal and cover its own prose
type: bug
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0026", "0034", "0052", "0057"]
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

The item template's *Functional requirements* section enumerates what a change adds. Two things it
therefore cannot say, and both have produced a diff that read as complete and was not.

**An addition-only FR list cannot express a move.** 0034's five FRs describe the new derived rule and
none says `verify` Step 2 must **stop** applying the advisory label — only AC2 ("no other trigger
for the label remains anywhere in the file") requires that bullet to change. Worse, its *Out of
scope* opens "Changing what Step 2 *does*" and lists three things it keeps doing, which on a first
read looks like Step 2 is untouched; the paragraph does go on to say the label moves, but a session
working FR-by-FR per `develop` Step 4 reaches the ACs only after implementing, and the diff it would
have written leaves two triggers in the file and fails QA. When a change relocates a decision, one
FR should name the site it is relocated *from*, not only the site it moves to — and the AC that
catches the omission fires after the work is done.

**A ticket's own prose is outside every guard the ticket writes.** 0026's privacy NFR forbade
publishing paths outside the repo. Its test asserts the harvest *output* and the *record* stay
clean, and both do — the two store slugs that breached it sat in the ticket's own *Problem* section,
which no AC and no test reads. An NFR of that kind wants one `git grep` assertion over the whole
change, not one over the deliverable. This has since been written by hand into individual tickets'
acceptance criteria; nothing makes it the default, so it holds only where a session happens to think
of it.

## Functional requirements

- FR1 — `skills/queue/SKILL.md`'s functional-requirements step states that a change which moves or
  removes something needs an FR naming the site it is removed **from**, not only where it goes, and
  says why: an FR list is worked through before the ACs are read.
- FR2 — `skills/queue/templates/item.md`'s *Functional requirements* section carries the same
  requirement where the FRs are written, since the template is what a cold session fills in.
- FR3 — `skills/queue/SKILL.md`'s NFR step states that an NFR forbidding something from appearing is
  asserted over **the whole change** — the item file included — and not over the deliverable alone.
- FR4 — `skills/queue/templates/item.md`'s NFR table guidance carries FR3's rule.
- FR5 — The skill states that an *Out of scope* line which enumerates what a step keeps doing must
  not read as though the step is untouched when the ticket in fact changes it, and says to name the
  change in *Out of scope* itself rather than leaving it to an AC.
- FR6 — Every rule added cites its convention rather than restating it, and each citation resolves
  under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | FR3 is the privacy rule's own enforcement point; the change must be written without reproducing either leaked slug and checked with a `git grep` over the whole change, this item file included | `data-privacy-conventions.md` |
| Documentation | The rule lands in both the skill and the template, because the template is read by sessions that never open the skill's prose | `documentation-conventions.md` |
| Progressive delivery | The skill and template ship to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/SKILL.md`'s functional-requirements step, when read, then it
  requires an FR naming the site a thing is removed from.
- [ ] AC2 — Given `skills/queue/templates/item.md`'s *Functional requirements* section, when read,
  then it carries that requirement.
- [ ] AC3 — Given `skills/queue/SKILL.md`'s NFR step, when read, then it states that an absence NFR
  is asserted over the whole change including the item file.
- [ ] AC4 — Given `skills/queue/templates/item.md`'s NFR guidance, when read, then it carries AC3's
  rule.
- [ ] AC5 — Given the skill, when read, then it states how *Out of scope* names a step the ticket
  does change.
- [ ] AC6 — Given the whole change, when `git grep` is run over every file it touches — this item
  file included — for a transcript-store path segment, then none is present.
- [ ] AC7 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.
- [ ] AC8 — Given the whole suite, when it runs, then every suite passes.

## QA plan

- **Level:** verify — the deliverable is prose in two shipped files and no test runner applies; the
  scripted assertions are the scoped greps below, AC6's `git grep`, and the citation and size guards.
- **Why this level:** nothing executable changes.
- **Specific checks:** each grep **scoped to the step or section it asserts on, not to the file** —
  a document-wide match pins vocabulary rather than structure. Match phrases short enough to sit on
  one source line. Then `tests/citations.test.sh`, `tests/skill-size.test.sh` and the full suite.

## Out of scope

- **Whether an AC can be falsified.** That is 0052, which also touches these two files. Kept apart
  because the root causes are unrelated; the collision is 0050's to settle.
- **Auditing open tickets for addition-only FR lists that hide a removal.** A sweep is separate.
- Changing the NFR table's dimensions or the conventions it cites.

## Notes & decisions

- Routed to `develop`: both findings state the rule they want in a single sentence, and neither has
  a competing shape worth weighing.
- FR5 is the smallest and the one that made 0034 hardest to read: the fence and the FRs disagreed,
  and the only thing that said so was an AC nobody reaches until the work is done.
