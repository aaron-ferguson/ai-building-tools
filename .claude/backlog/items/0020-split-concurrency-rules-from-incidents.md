---
id: "0020"
title: Split CONCURRENCY.md into rules and incidents
type: chore
status: blocked
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: ["0013"]
relates: []
touches:
---

## Problem

`CONCURRENCY.md` is 4,191 tokens and four of the five skills must read it before doing anything,
so a full cycle pays 16,764 tokens for it. It is the largest single mandated read in the suite.

Roughly two fifths of it is incident narrative — *"this has happened"*, *"a session lost real
time to this"*. Those paragraphs are why the rules are believed, and they are re-read every
cycle to teach something already learned. The conventions core sets the standard the file is
not meeting: cut the reasoning that convinced you, keep the rule and the failure it prevents.

## Functional requirements

- FR1 — The always-read half states every rule, each with the failure it prevents, in one line
  or two.
- FR2 — The incident narratives move to an appendix, read when a conflict actually happens or
  when someone questions a rule.
- FR3 — **No rule is dropped.** This is compression, not gating. The rule count before and after
  is identical, and the ticket records both numbers.
- FR4 — The always-read half is under 1,500 tokens.
- FR5 — Every rule keeps its name, since rules are cited by name across the skills and a rename
  breaks citations this file cannot see.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Citations to rule names elsewhere in the suite still resolve after the split. A broken cross-reference is silent. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the always-read file, when its size is measured, then it is under 1,500 tokens.
- [ ] AC2 — Given the rule names in the file before the change, when each is grepped for after,
      then every one is still present.
- [ ] AC3 — Given the skills, when grepped for citations of concurrency rule names, then every
      cited name resolves to a heading in the always-read half.
- [ ] AC4 — Given the appendix, when read, then each incident it holds names the rule it
      justifies.

## QA plan

- **Level:** verify — documentation.
- **Scripted assertion:** capture the rule headings to a file before the edit
  (`grep '^## ' references/CONCURRENCY.md > /tmp/rules-before`), then after the split assert every
  line of it appears in the new always-read file. AC2 is a diff against a captured baseline rather
  than a count, because a count stays green if one rule is dropped and another duplicated.

## Out of scope

- Gating the file on collaboration mode or backend. Considered and rejected: the git-index hazard
  applies with two windows regardless of what the profile says, and a rule you have to qualify
  before reading is worse than a short one you always read.

## Notes & decisions

- 0013 removes the whole *"verify never writes the queue"* section outright, so this ticket should
  follow it rather than compress a section about to be deleted.
