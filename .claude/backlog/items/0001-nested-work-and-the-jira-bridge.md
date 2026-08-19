---
id: "0001"
title: Nested work and the Jira bridge
type: feature
status: active
created: 2026-08-18
parent:
ships: independently
measure:
  metric: readiness-gate and graph health, measured by `next --check` over this backlog
  baseline: no hierarchy, no dependencies, no gate
  target: all five checks below passing
  by: 2026-10-17
  instrumented_by: "0006"
  review_at: 2026-10-17
  review_owner: Aaron Ferguson
  on_success:
    - capture: write up what the model got right and offer it to anyone else running the plugin
      owner: Aaron Ferguson
    - queue: decompose phase 3 against a real ACT effort
      owner: agent
  on_failure:
    - queue: cut the dependency graph back to hierarchy alone, keeping parent/child only
      owner: agent
    - capture: record why the graph was not maintained, so it is not re-proposed unexamined
      owner: Aaron Ferguson
---

## Outcome

The backlog holds work at any depth, ties related work together, and lets dependencies rather
than memory drive the stack rank. Work in a company project reaches Jira through the existing
ticket rubrics rather than a second set of standards.

## Evidence

A flat backlog cannot express that four tickets are one deliverable, so the coupling lives only
in whoever queued them. Aaron's working hierarchy is four levels (idea → epic → story → subtask)
and wants five; a two-level model would break on contact. Full reasoning and the rejected
alternatives are in the design plan — see **Notes & decisions**.

## Non-goals

- Ranking efforts. Only tasks are ranked; an effort has no single position and forcing one hides
  both ends of its range.
- Two-way field sync with Jira. One owner per field, always.
- A distributed lock for multiple people. Jira already owns assignment; see phase 3.
- Depth for its own sake. Nesting is a capability, not a target.

## Slices

- **0002** — phase 1, the ticket graph. Decomposed.
- **0003** — phase 2, the readiness gate and outcome reviews. Not decomposed yet.
- **0004** — phase 3, extending `references/TRACKER.md`. Not decomposed yet.

Phases 1 and 2 are exercisable in this repo. **Phase 3 is not** — this project is
`routing.default: local`, so testing the bridge needs a company effort in the Court family.

## Cross-cutting commitments

- Every rule this work adds is workflow. Anything that would be true without a backlog belongs in
  `ai-building-conventions` and is cited, never restated.
- No new ranking rules and no score. The graph supplies evidence; a human performs the comparison.
- Backward compatibility: other people's backlogs are installed from a marketplace and will not
  migrate on our schedule. Readers tolerate the old shape (`migration-conventions.md`, additive
  first).

## Kill criteria

- Dependency edges go stale — blockers closed while dependents stay `blocked`. The graph is being
  written and not read; cut back to hierarchy alone.
- `on_success` branches keep firing with nobody announcing anything. Keep only `on_failure`,
  which has natural pressure behind it.

## Measure detail

At 2026-10-17, all five must hold:

1. Every `ships: together` effort has completed or been explicitly abandoned.
2. Zero scheduled reviews overdue by more than a week.
3. Zero `ready` tickets with an unowned declared trigger.
4. No `next --check` rank inversion surviving a week.
5. Median tree depth ≤ 3, maximum ≤ 5.

## Notes & decisions

- **2026-08-18** — Vocabulary: a ticket with children is an **effort**, one without is a **task**.
  "Project" was proposed and rejected: it already means the repo (`config.yml: project:`, and the
  conventions repo's "every project declares two things in its CLAUDE.md") and it means a Jira
  project key (ACT, AAT). A third meaning collides in the exact section where precision matters.
- **2026-08-18** — One parent maximum. Multiple parents make `ships: together` contradictory (a
  child in two release units — does its code go live when the first ships?), give a ticket two
  competing critical-path dates, and cannot be represented in Jira.
- **2026-08-18** — Efforts get no status of their own and no rank. A half-finished coupled effort
  is a ranking failure, not a state to model: if its tasks are ranked honestly it completes, and
  if they are not it correctly does not ship. `next --check` reports stranded siblings so the
  failure is visible; nothing promotes automatically.
- **2026-08-19** — `references/TRACKER.md` was committed 2026-08-17, after this design started,
  and already defines one-way mirroring. Phase 3 extends it in place rather than shadowing it;
  see 0004. Two documents describing one mechanism is how the mechanism drifts.
- Design plan: https://claude.ai/code/artifact/b339b7f0-3dec-41ec-a819-97a7a5953634
