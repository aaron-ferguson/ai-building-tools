---
id: "0122"
title: Decide whether a mention of the privacy rule may name the thing the rule forbids
type: bug
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: m
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0118"]
expects:
  - CLAUDE.md
  - tests/findings-routing.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**Company and product names sit in item prose in this public repo.** `2a69aa9` redacted published
*home paths* and fixed the guard that could not tell a redaction from a leak; the tracked tree still
carries the company and design-system names in `items/0003`, `items/0004`, `items/0056`,
`items/0070`, `items/0111` and `items/0113`.

They are not all the same thing, and that is the whole difficulty. Several are references to the
constraint itself — "a company tool this public repo must not depend on" — where the name is doing
the work of *explaining the rule*. `items/0003` and `items/0004` are not: they describe a
court-tenanted rollout and a company Jira story rubric, which is material `CLAUDE.md` says plainly
does not belong here.

**A guard that cannot tell those two apart is the same trap the home-path guard fell into** — that
one flagged six lines, four of them redacted prose *about* the defect, including the entry that
recorded it. Widening a pattern until it stops complaining is how a privacy guard becomes noise.

## Functional requirements

- FR1 — the decision is recorded: whether a mention of the rule may name the thing the rule forbids,
  and if so under what form.
- FR2 — the tracked instances that fall outside the decision are redacted.
- FR3 — whatever discriminator FR1 lands on is mechanical enough for a guard, or the ticket records
  that it is not and says what is checked instead.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The rule is `CLAUDE.md`'s public-repo constraint; cite it, never restate it | `data-privacy-conventions.md` |

## Open design question  *(only while `next: design`)*

- **Question:** may an item explaining the no-company-material rule name the company, and if so how
  — a placeholder, a single sanctioned form, or not at all?
- **Why it blocks specification:** FR2 cannot name which instances are violations until FR1 is
  answered, and FR3's guard cannot exist at all.
- **Settle it with:** `/design`

## Acceptance criteria

Written once the design question is settled.

## QA plan

- **Why that level:** greps over the tracked tree; no runner above that applies.
- **Specific checks:** to be written with the ACs, and they must include the both-directions control
  the home-path guard now carries — a real instance still reds, a sanctioned mention does not.

## Out of scope

Running the existing guard where a sweep commits — that is `0118`. Any change to the home-path
pattern.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-08 and deferred once by this retro
  before being filed properly. The item list above was current at the park date; re-read the tree.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Neighbouring case: a fixture name spelled in an item's reproduction block becomes tracked content, so the privacy guard's clean-tree case matched the ticket describing it (0148). Rule if it recurs: a name-shaped fixture is assembled in the test and never spelled in the item.
