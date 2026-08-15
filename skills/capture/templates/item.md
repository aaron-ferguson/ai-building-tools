---
id: "NNNN"
title: <verb + noun phrase, what the change does>
type: bug | feature | chore | debt
status: ready
qa_level: verify | unit | integration | e2e
# Rough cost, so a session can see what it's taking on WITHOUT reordering the queue.
# s = one sitting · m = a focused session · l = multiple sessions or needs a design decision first.
size: s | m | l
created: YYYY-MM-DD
source: user | agent | notion:<page-id>
# Written by `develop` when it claims the item, cleared when it closes or releases it.
# The same token appears in QUEUE.md's Owner column. An item is yours only if you minted its
# token in this conversation — see the ai-building-tools CONCURRENCY.md.
claimed_by:
claimed_at:
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
commitment `develop` and `qa` will hold you to.

The middle column says what **this item** must satisfy. The third cites the convention file that
defines the rule — by bare filename, since the conventions directory is resolved per project.
**Cite, never restate:** a rule copied in here drifts from source, and `qa` will then verify the
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
never optional, so a row would only invite treating them as a choice. `qa` reads them from source
on every run.

## Acceptance criteria

Given / when / then. `qa` checks these literally and will not close the item without them.

- [ ] AC1 —
- [ ] AC2 —

## QA plan

- **Level:** <verify | unit | integration | e2e> — chosen at capture time, not at develop time.
- **Why this level:** <one line; e2e needs a reason that unit + integration can't cover it>
- **Specific checks:** <suites to run, journeys to drive, manual steps if any>

## Out of scope

What this item deliberately does not do, so `develop` doesn't scope-creep.

## Notes & decisions

Appended as work happens — non-obvious mechanisms, disproved theories, why an approach was
rejected. Per `documentation-conventions.md`, this gets written when understood, not at the end.
