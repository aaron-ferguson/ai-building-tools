---
id: "NNNN"
title: <verb + noun phrase, what the change does>
type: bug | feature | chore | debt
# Which skill acts next. `queue` = not specified enough for any stage to take it — captured
# half-baked, or found stale by a later stage · `design` = a decision has to be settled before
# acceptance criteria can exist · `develop` = specified, build it · `verify` = built, QA it.
next: queue | design | develop | verify
# Whether anything can act at all. `ready` = it can · `waiting` = a PERSON is needed · `blocked`
# = an open `blocked_by` · `in-progress` = a session holds a claim · `done` = terminal, the
# ticket's row has moved to `DONE.md`. `waiting` and `blocked` are not one value because
# different things clear them: a person answering, versus another ticket closing. Merged,
# telling which would mean opening the ticket. Two values sit off the stack rank and so out of
# this list: a container ticket is `active` (it is never ranked, claimed, or built — its children
# carry the stages, and its `next:` stays empty), and a dormant ticket in `SCHEDULED.md` is
# `scheduled` with a `wake:` date.
status: ready | waiting | blocked | in-progress | done
qa_level: verify | unit | integration | e2e
# Rough cost, so a session can see what it's taking on WITHOUT reordering the queue.
# s = one sitting · m = a focused session · l = multiple sessions or needs a design decision first.
size: s | m | l
created: YYYY-MM-DD
source: user | agent | notion:<page-id>
# The files this item is PREDICTED to reach, written by `queue` while the code is already open
# to write the FRs below — so a session choosing what to take next can spot a collision with an
# in-progress item's `touches:` without researching every candidate itself. Advisory: it
# protects nothing, it goes stale, and being wrong here costs one suboptimal pick. `develop`
# checks it against the code on claim and promotes the corrected list to `touches:`.
expects:
# Written by `develop` when it claims the item, cleared when it closes or releases it.
# This is where the token lives; the pared QUEUE.md carries no ownership column. An item is
# yours only if you minted its token in this conversation — see the ai-building-tools
# CONCURRENCY.md.
claimed_by:
claimed_at:
# The files this item is ACTUALLY claiming — a live claim, not just on the row. `develop` writes
# it on claim by verifying `expects:` against the code, clears it on close or release, and widens
# it the moment the work reaches further. Unlike `expects:`, being wrong here costs two sessions
# in one file, which has no merge protocol behind it. It warns, it does not lock.
touches:
---

## Problem

Who is hurt, how, and how we know. For a bug: exact repro steps, observed vs expected,
and the evidence (log line, screenshot path, failing request). For a feature: the job the
user is trying to do that they currently can't.

## Functional requirements

Each one independently verifiable. If you can't say how you'd check it, it isn't a
requirement yet.

- FR1 —
- FR2 —

## Non-functional requirements

Keep only the rows that apply and delete the rest. An empty row is noise; a filled row is a
commitment `develop` and `verify` will hold you to.

The middle column says what **this item** must satisfy. The third cites the convention file that
defines the rule — by bare filename, since the conventions directory is resolved per project.
**Cite, never restate:** a rule copied in here drifts from source, and `verify` will then verify the
stale copy. The convention files below are the usual mapping; check the conventions core's index
for the authoritative list.

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | | `security-conventions.md` |
| Privacy & data | | `data-privacy-conventions.md` |
| Performance | | `observability-conventions.md` |
| Accessibility | | `accessibility-conventions.md` |
| Observability | | `observability-conventions.md` |
| Migration / schema | | `migration-conventions.md` |
| Progressive delivery | | `progressive-delivery-conventions.md` |
| Dependencies | | `dependency-conventions.md` |
| Documentation | | `documentation-conventions.md` |

The always-on rules in `CONVENTIONS_CORE.md` apply to every item and get no row here — they are
never optional, so a row would only invite treating them as a choice. `verify` reads them from source
on every run.

## Open design question  *(only while `next: design`)*

What has to be settled before this item can have acceptance criteria. Write it as a question with
a decidable answer, not a topic — "modal or full page for the bulk edit?" not "bulk edit UX".
State it before the design work starts; that is the same discipline as writing kill criteria
before running a test.

- **Question:**
- **Why it blocks specification:** which AC cannot be written until this is answered
- **Settle it with:** `/design` (returns a decision) or `/prototype <level>` (returns something
  to look at, when the answer needs to be seen rather than reasoned about)

Delete this section when the item moves to `next: develop`, and record the answer in
**Notes & decisions**.

## Acceptance criteria

Given / when / then. `verify` checks these literally and will not close the item without them.

- [ ] AC1 —
- [ ] AC2 —

## QA plan

- **Level:** <verify | unit | integration | e2e> — chosen at queue time, not at develop time.
- **Why this level:** <one line; e2e needs a reason that unit + integration can't cover it>
- **Specific checks:** <suites to run, journeys to drive, manual steps if any>

## Out of scope

What this item deliberately does not do, so `develop` doesn't scope-creep.

## Notes & decisions

Appended as work happens — non-obvious mechanisms, disproved theories, why an approach was
rejected. Per `documentation-conventions.md`, this gets written when understood, not at the end.
