---
id: "0145"
title: Decide what an empty touches means to the scope report, and record it where the field is read
type: debt
next: design
status: ready
qa_level: verify
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0050", "0029"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
---

## Problem

**An empty `touches:` suppresses the whole scope report, and which of the two readings that encodes
was never written down.** `scope_note()` returns early on `[ -n "$declared" ] || return 0`, with no
comment and no test in either direction, so the behaviour is an artefact rather than a decision.

The two readings give opposite answers:

- Under `references/CONCURRENCY.md`'s *The working tree is shared too* — "read an empty `touches:` on
  an `in-progress` row as *its files are held*" — empty means **everything**, nothing can be
  undeclared, and suppressing the report is correct.
- Under `0106` FR3 as worded, empty declared **nothing**, so every touched path is undeclared and the
  report should list them all.

Observed: a ticket with an empty `touches:` whose commits changed `src/undeclared.ts` closed with no
scope line at all.

This matters more than the size suggests, because `0106`'s own FR2 is what makes an empty `touches:`
the **normal** shape for a `verify` claim. So the report `0106` added is structurally silent on the
stage that does most of the closing, unless a session hand-populates the field — in a ticket whose
whole subject is that field meaning one thing.

## Open design question

**Does an empty `touches:` mean *everything is held* or *nothing was declared*, for the purpose of the
scope report — and is the answer the same for `close` as for `handoff`?**

What has to be settled before acceptance criteria can exist:

- Whether the report's silence on a `verify` claim is acceptable given FR2 makes that the normal shape.
  If it is not, the fix may be to the field's default rather than to the reader.
- Whether the two readings can coexist by stage: `CONCURRENCY.md`'s rule is about *ownership* and the
  scope report is about *attribution*, and one field serving both is what `0050` and `0029` are each
  circling from a different side.
- Whether a third shape is needed — an explicit marker meaning "deliberately everything" — so that
  *unset* and *claimed-the-tree* stop being the same bytes.

Constraints the decision may not break: `CONCURRENCY.md`'s ownership reading is load-bearing for every
claim in the repo and is not up for revision here; whatever is decided is recorded beside
`scope_note()` and in the field's own comment, because the absence of that comment is half this defect.

## Out of scope

- Changing what `close` refuses. `0090` FR3 owns the refusals.
- Changing how `claim` seeds the field. That is the shape `0106` FR2 decided.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0106` that identified both readings and
  asked for the decision. Routed to `design` rather than `develop` because the park's own finding is
  that the behaviour is undecided, not that it is wrong — and `0106` reserved the question for
  whoever claims it, which no session has.
