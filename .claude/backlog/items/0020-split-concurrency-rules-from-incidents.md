---
id: "0020"
title: Split CONCURRENCY.md into rules and incidents
type: chore
next: verify
status: done
qa_level: verify
size: m
created: 2026-08-23
closed: 2026-08-23
parent: "0009"
blocked_by: []
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

- [x] AC1 — Given the always-read file, when its size is measured, then it is under 1,500 tokens.
- [x] AC2 — Given the rule names in the file before the change, when each is grepped for after,
      then every one is still present.
- [x] AC3 — Given the skills, when grepped for citations of concurrency rule names, then every
      cited name resolves to a heading in the always-read half.
- [x] AC4 — Given the appendix, when read, then each incident it holds names the rule it
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
- **FR3, recorded: 10 rules before, 10 rules after.** Names verbatim, in file order — *The git index
  is shared…*, *A pathspec is necessary but **not sufficient**…*, *The working tree is shared too…*,
  *A claim must be durable…*, *A stage writes only the ticket it holds*, *Never rewrite `QUEUE.md` by
  hand*, *Re-read immediately before you write*, *Lock every write to `QUEUE.md`*, *Claim tokens…*,
  *The two scripts*.
- **Size: 17,943 → 6,017 bytes, or 4,443 → 1,490 tokens** at the 4.038 bytes/token ratio the ticket
  itself established (it measured 16,928 bytes as 4,191 tokens). Four skills read it, so a full cycle
  now pays ~5,960 tokens for it against ~17,770.
- **The baseline was recaptured after 0013, not taken from before it.** 0013 renamed *`verify` never
  writes the queue* to *A stage writes only the ticket it holds*, which FR5 would otherwise read as a
  dropped rule. The ticket's own note anticipated this ("0013 removes the whole section outright, so
  this ticket should follow it") — the consequence for the baseline is what was not written down.
- **AC3 is a prefix match, and that is a finding not a shortcut.** Skills cite rules by the heading's
  *stem* — *The git index is shared*, *The working tree is shared too* — because the full headings
  carry a trailing clause. An exact-match check would fail on every citation in the tree. Shortening
  the headings to their citable stem would have satisfied AC3 and broken AC2, which requires the
  before-names present verbatim. Prefix matching is the only reading that satisfies both.
- **Six passes of word-shaving moved 1,100 bytes; deciding what leaves moved 11,000.** Rewriting
  prose tighter is nearly free of effect at this scale. What got the file under the ceiling was
  naming a category — live-conflict procedures, design rationale, incident narrative — and moving all
  of it. Recorded because the first five passes were wasted effort of a predictable kind.
- FR4's ceiling requires cutting more than the "roughly two fifths" of narrative the problem
  statement estimated: 2/5 of 16,928 is ~10,150 bytes, still 2,500 tokens. The operational
  procedures had to go too, which is why the appendix is *conflict procedures plus* incidents rather
  than incidents alone.
