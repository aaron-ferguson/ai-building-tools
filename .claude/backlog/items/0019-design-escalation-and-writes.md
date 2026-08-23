---
id: "0019"
title: Design asks on taste, decides on fact, and writes the ticket itself
type: chore
next: develop
status: ready
qa_level: verify
size: s
created: 2026-08-23
parent: "0009"
blocked_by: []
relates: []
touches:
---

## Problem

Two costs in one skill.

Design is forbidden from writing item files, so settling one question means handing back to
`queue` — which re-injects queue's whole instruction file. Measured: 5,699 tokens plus five turns
plus **$0.67** to edit a single ticket. The rule exists so two sessions do not write the same
item, and it is paid on every single-session design.

Separately, the skill has no guidance on when to involve a person, so the choice is made per
session. Asking always is expensive and stops the skill doing its job; asking never produces
confident answers to questions that were never answerable by reasoning.

## Functional requirements

- FR1 — When the ticket is unclaimed, design writes the *Notes & decisions* entry, the FRs and
  ACs the answer unblocks, and sets `next: develop` itself. When it is claimed, it hands off as
  today.
- FR2 — The skill states the escalation rule: ask a person when the answer turns on taste; decide
  it yourself when it turns on fact.
- FR3 — The recommendation and the open question go in the **same message**. The skill says why:
  a session that asks early costs cents, one that builds the full case first and then asks has
  already spent the budget.
- FR4 — The skill keeps permission to decide without asking, with the worked case: a question
  that looked like a judgement call was settled by checking the data, and checking killed all
  three candidate answers.
- FR5 — A design session concluding that something must be *seen* sets `status: waiting` and
  writes the ask into `## Waiting on`. It still does not invoke `prototype`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The escalation rule is stated as a test a session can apply, not as a preference. "Ask early" without a test degrades into "ask always". | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/design/SKILL.md`, when read, then it describes writing the ticket when
      unclaimed and handing off when claimed, and names how to tell.
- [ ] AC2 — Given that file, when read, then the taste/fact test is stated.
- [ ] AC3 — Given that file, when read, then it requires the recommendation and the question in
      one message.
- [ ] AC4 — Given that file, when read, then it still says design must not invoke `prototype`.
- [ ] AC5 — Given `skills/queue/SKILL.md`, when read, then its clearing-a-design-ticket paragraph
      matches FR1 rather than claiming design never writes items.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -n 'Do not invoke .*prototype' skills/design/SKILL.md` returns a
  line (AC4 guards against the edit removing it as collateral), and
  `grep -n 'never write to the item\|Do not write to the item yourself' skills/queue/SKILL.md`
  returns nothing — the contradiction AC5 exists to catch.

## Out of scope

- Which tickets reach design — 0018.
- Prototype's own behaviour.

## Notes & decisions

- FR4 is deliberately protective. The measured design run did not ask anything, went and read the
  workbook, and found that all three proposed inputs for a rule did not exist in the data. A rule
  written as "ask early" would have made that run worse.
