---
id: "0003"
title: Phase 2 — the readiness gate and outcome reviews
type: feature
status: blocked
qa_level: verify
size: l
created: 2026-08-18
parent: "0001"
blocked_by: ["0002"]
relates: []
touches:
---

## Problem

`ready` currently means "specified", judged by whoever wrote the ticket, which is exactly the kind
of standard that slides session to session. And nothing in the system can record whether a change
*worked*: tickets close when their acceptance criteria pass, which is a statement about
correctness, not about outcome.

Both gaps have the same shape — a commitment made now with nothing holding it later.

## Functional requirements (sketch — decompose before starting)

- FR1 — A stated readiness gate: buildable · FRs written · NFR rows decided · ACs testable and
  covering more than the happy path · QA level set · no open blockers · **every declared trigger
  has a named owner**.
- FR2 — The gate composes. A `routing.default: local` project uses the base gate; a `jira` project
  uses the base gate *plus* the `/jira-ticket` rubric for that issue type and family, with the
  rubric's Critical and Major findings blocking `ready` and review-mode-only checks excluded.
- FR3 — The five AC types imported into the ticket template, with the rubric's standing judgement
  that AC containing only functional criteria is incomplete.
- FR4 — `measure:` with `review_at`, `review_owner`, and `on_success` / `on_failure` branches, each
  branch action carrying an owner. Owner is a role by default, a person only when the commitment is
  genuinely personal.
- FR5 — Rollup close: the last child closing marks its effort done, cascading upward.
- FR6 — On rollup close of an effort carrying a `measure`, a scheduled review ticket is created in
  `SCHEDULED.md` dated `review_at`. Dormant tickets hold no rank; `next` prints `DUE:` on waking.
- FR7 — Branch routing: `queue:` actions to this backlog, `capture:` actions to the personal task
  tool via an optional config key, absent by default so the plugin never hard-depends on its sibling.
- FR8 — A one-time sweep of existing `ready` rows against the new gate. It produces a report and
  fixes rows in rank order; it does **not** mass-flip statuses, which would turn the whole queue
  `blocked` on the day this lands.

## Open design question

- **Question:** which rubric findings block `ready` versus warn — is Major blocking, or only
  Critical?
- **Why it blocks specification:** FR2's acceptance criteria cannot be written until the boundary
  is fixed, and the choice determines whether the sweep in FR8 is a morning or a fortnight.
- **Settle it with:** `/design`, against a sample of recent closed ACT and AJ tickets — the honest
  test is how many real tickets each boundary would have blocked.

## Out of scope

Anything Jira-writing. The gate *reads* the rubrics; pushing tickets is 0004.

## Notes & decisions

- **2026-08-19 — audit of the `/jira-ticket` rubrics against this design.** Aaron asked whether the
  rubrics are comprehensive enough to source the gate from. Five gaps found:
  1. **No owner or date on anything deferred.** `epic.md` requires Success Criteria and a
     measurement framework, but nothing requires *who checks it* or *when*. This is the largest gap
     and it is exactly the one Aaron identified independently.
  2. **No progressive-delivery check anywhere.** Nothing asks whether a change ships behind a flag,
     who owns it, or when it expires — despite the conventions requiring all three, and despite
     court-tenanted rollout carrying per-court notification obligations the Neumo profile treats as
     strict by default.
  3. **`Independence` is review-mode only** (`story.md`). A story can be *created* in Ready-for-Dev
     with open blocking links and nothing flags it at write time.
  4. **Nothing checks decomposition exhaustiveness.** `epic.md` requires In Scope / Out of Scope
     lists but never asks whether the children cover the In Scope list. Jira knows the children, so
     this is checkable.
  5. **`missing_measurement_framework` triggers only on "new user-facing capability."** Under this
     design any effort declaring an outcome needs a measure and a review date, including internal
     ones.
- Gaps 1, 2 and 4 are candidates for `ai-building-conventions` (true without Jira); 3 and 5 are
  rubric trigger changes. Either way that is a change in another repo — sequence it before 0004.
