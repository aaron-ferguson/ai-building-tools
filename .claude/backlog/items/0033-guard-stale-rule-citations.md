---
id: "0033"
title: Guard against stale rule-name citations across the references
type: debt
next: verify
status: ready
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - tests/citations.test.sh
claimed_by:
claimed_at:
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

### Built 2026-08-24 [0033]

**`expects:` over-predicted by two files, and the correction is above.** It named
`references/CONCURRENCY.md` and `references/CONCURRENCY-INCIDENTS.md` because *Out of scope* said
the two citations broken by the 2026-08-23 rename "should be fixed by this ticket if still
present". They are not present — `grep -rn "two scripts"` over `references/`, `skills/` and
`QUEUE.md` returns nothing, so 0023's close already fixed them. Nothing outside `tests/` changed.
Left as claimed, those two files would have reserved `references/CONCURRENCY.md` against 0034,
which is the next `develop` row and genuinely needs it.

**The recognition rule lives in the guard's header, not here** — it is the thing a later author
has to read, and a second copy would drift. Two mechanisms behind it were not obvious and cost
real time:

- **Strip the bold DELIMITERS, not the bold SPANS.** The obvious first move is
  `gsub(/\*\*[^*]*\*\*/, "")` to clear bold before matching italics. It fails on this corpus:
  `CONCURRENCY.md` line 41 nests an italic at the *end* of a bold
  (`**...row as *its files are held***`), which that pattern cannot match, so it leaves an
  unpaired asterisk behind that then pairs with the next one and swallows half a paragraph. Three
  citations came out as sentence fragments. Removing only the `**` markers and keeping their text
  resolves `***` correctly and needs no special case.
- **Scope the scan to the markdown paragraph (`RS=""`), not to the file.** Flattening the whole
  file lets an anchor at the end of one paragraph reach a span at the start of the next. That is
  not hypothetical here: `CONCURRENCY-INCIDENTS.md` line 141 is a `rule:` heading and line 143
  opens the next paragraph with the *deleted* rule name `*`verify` never writes the queue*` in
  narrative prose. Whole-file flattening reported it as a stale citation — a false failure on the
  exact case FR5 exists to spare. This is 0032's finding arrived at from the other end: a window
  that does not terminate on the document's own boundary measures its neighbour.

**A theory that was wrong.** The first plan was to recognise a citation as "any italicised span",
per FR3's reading of the convention. That yields ~80 hits, almost all emphasis, because these
files italicise constantly. The check has to run cited → defined (a stale name matches no
definition by construction, so it cannot be filtered by matching the definitions), which means
false positives are false *failures*. Anchoring is what makes FR5 achievable without the
exemption list FR5 would rather avoid.

**Known false negative, documented in the header and deliberately not fixed.** An unanchored
citation is not checked. `CONCURRENCY-INCIDENTS.md` has a real one: "the one place *Claim tokens*
says ownership does not live." Distinguishing it from the emphasis around it requires already
knowing the set of rule names, which is what the guard is computing — so no widening of the
anchor can reach it. The cover that remains was measured: renaming *The three scripts* in a
`git archive` copy of the tree fired 5 anchored citations across 4 files.

**AC5's two cases passed against the stubbed extractor** — before `rule_citations` existed at all.
That is the vacuous pass FR6 was written for, observed live: an empty-set check is green whether
the recognition is broken or the tree is clean, which is why AC2–AC4 have to red separately for
the red-green cycle to mean anything.

**Verified for QA:** whole suite green, 11 suites / 260 assertions, at f823e8f.
