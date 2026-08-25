---
id: "0033"
title: Guard against stale rule-name citations across the references
type: debt
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - tests/citations.test.sh
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
claimed_by: "8c99"
claimed_at: 2026-08-25T01:59:06Z
touches:
---

## Problem

`references/CONCURRENCY.md` names its rules rather than numbering them, and instructs every reader
to **cite by name**. `CONCURRENCY-INCIDENTS.md`, the skills, and the backlog's own prose all do so.

Nothing checks that a cited name still exists. Retitling *The two scripts* to *The three scripts*
on 2026-08-23 broke two citations in `CONCURRENCY-INCIDENTS.md`, and a wrong rule name reads exactly
like a correct one — the reader follows the citation, finds no such rule, and either guesses which
rule was meant or concludes the reference is stale.

Renaming a rule is never a one-file edit, and prose telling people so is weaker than a check that
fails.

## Functional requirements

- FR1 — a scripted guard extracts the set of rule names defined in `references/CONCURRENCY.md` (its
  `##` headings under both parts) and the set cited elsewhere, and fails naming any citation with no
  matching definition.
- FR2 — the guard covers every place that cites by name: `references/*.md`, `skills/*/SKILL.md`,
  `skills/queue/templates/*`, and `.claude/backlog/QUEUE.md`.
- FR3 — citations are recognised by the convention the files actually use — italicised rule names
  (`*Lock every write to `QUEUE.md`*`) — and the guard states its recognition rule in a comment, so
  a later author can tell why a citation was or was not seen.
- FR4 — the guard reports the **reverse** direction too, as information rather than failure: a rule
  defined and cited nowhere. That is not a defect, but it is how a rule quietly stops being load-
  bearing, and 0021's `## Key Behaviors` finding is the same shape.
- FR5 — the guard tolerates a rule name that legitimately appears as running prose rather than a
  citation, without needing an exemption list. If that proves impossible, an exemption list is
  acceptable but each entry states why.
- FR6 — the guard fails loudly if it extracts **zero** definitions or **zero** citations. Either
  outcome means the recognition rule stopped matching, and an empty set makes every comparison pass
  (`testing-conventions.md`, the filter-then-assert failure).

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Dependencies | `sh`, `awk`, `grep` only | `dependency-conventions.md` |
| Documentation | The guard is the durable form of "renaming a rule is never a one-file edit"; it does not also need saying in prose | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the shipped tree, when the guard runs, then it passes, having found a non-zero
  number of both definitions and citations, and reports both counts.
- [ ] AC2 — Given a fixture tree where one rule heading in `CONCURRENCY.md` is renamed and its
  citations left alone, when the guard runs, then it fails and names every stale citation with its
  file.
- [ ] AC3 — Given a fixture tree where a citation is added for a rule that does not exist, when the
  guard runs, then it fails and names that citation.
- [ ] AC4 — Given a fixture tree where a rule is defined and cited nowhere, when the guard runs,
  then it passes and reports that rule as uncited.
- [ ] AC5 — Given a fixture where the citation syntax is mangled so nothing matches, when the guard
  runs, then it fails on the empty-set check rather than passing vacuously.
- [ ] AC6 — Given each mutation used for AC2–AC5, when it is diffed before the guard runs, then the
  diff is non-empty.
- [ ] AC7 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then all suites
  pass.

## QA plan

- **Level:** verify — a shell guard over prose.
- **Why this level:** the guard's whole behaviour is text extraction and set comparison; fixtures are
  authored trees, so nothing needs a runner.
- **Specific checks:** the four fixture cases above, each mutation diffed first; the real tree run
  with both counts shown in the verdict.

## Out of scope

- Renaming any rule, or fixing citation style. The two known-stale citations from the 2026-08-23
  rename should be fixed by this ticket if still present, but no rule gets retitled here.
- Extending the same idea to the conventions repository. Different repo, different ticket.

## Notes & decisions

- Fixtures are authored trees in a temp directory, never the live `references/`. A guard that
  mutates the files it also measures is the coupling `testing-conventions.md` warns about.
