---
id: "0109"
title: Give a human-reported source a resolvable form
type: bug
next: develop
status: ready
qa_level: unit
qa_manual:
size: s
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/item.md      # the source: field and its vocabulary
  - references/EXTERNAL-FEEDBACK.md     # what external:<report-id> is supposed to resolve against
  - skills/queue/templates/config.yml   # the optional external_feedback: block
  - tests/external-feedback.test.sh
claimed_by:
claimed_at:
touches:
---
## Problem

**`source: external:<report-id>` has no resolvable meaning without the opt-in feedback block, and
the commonest real case has no field at all.**

In a sibling project, twelve items are sourced from an email thread and recorded as
`external:email-<date>-<person>`. `external_feedback:` is deliberately absent from that project's
`config.yml` — **correctly**, because there is no product holding those reports and no registry to
resolve an id against. So the id points at nothing any tool can follow, and a later reader has only
the string.

The `source:` vocabulary assumes the block exists. `user` means the project's own operator and
`agent` means a session; the plain, frequent case — *a human outside the project told me, and here is
where they said it* — has no form. Writing it as `external:` borrows a resolution mechanism that is
switched off, which reads as a broken pointer rather than as the honest "there is no registry, here
is the provenance" it actually is.

This matters beyond tidiness: a source that cannot be followed cannot be re-consulted when a
requirement derived from it turns out to be ambiguous.

## Functional requirements

- **FR1** — `source:` has a form for a human report that carries its provenance inline and claims no
  registry — distinguishable from `external:<report-id>`, which promises one.
- **FR2** — `external:<report-id>` is stated to require the `external_feedback:` block, and `queue`
  says what to write when the block is absent.
- **FR3** — `references/EXTERNAL-FEEDBACK.md` covers the no-registry case, since it is the file a
  reader consults on the strength of the `external:` prefix.
- **FR4** — The form does not require a person's name. Provenance must be recordable as a channel and
  a date, because a backlog may live in a public repo.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The documented form and every example are free of personal names, and FR4's constraint is stated where the form is defined — a public backlog must be able to use it | `data-privacy-conventions.md` |
| Documentation | The vocabulary is defined once, in the template's `source:` comment, and cited elsewhere | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the template's `source:` comment, when read, then it names a form for a human
  report with no feedback registry, distinct from `external:<report-id>`.
- [ ] AC2 — Given `external:<report-id>`, when read, then the requirement for `external_feedback:`
  is stated at the field, not only in the reference file.
- [ ] AC3 — Given `EXTERNAL-FEEDBACK.md`, when read, then it covers the case where no registry
  exists and says what a `source:` should carry instead.
- [ ] AC4 — Given every documented example of the new form, when checked, then none contains a
  personal name, and the privacy constraint is stated at the definition.
- [ ] AC5 — Deleting the no-registry sentence from `EXTERNAL-FEEDBACK.md` turns a guard red, scoped
  to that section rather than satisfied by the phrase occurring elsewhere in the file.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** prose in a template and a reference file; `tests/external-feedback.test.sh`
  already guards this subject.
- **Specific checks:** one assertion per FR, each on its own source line since `grep` is line-based
  and a rewrap would red it. Scope each to its section and **count the phrase within that scope**
  before trusting it (`testing-conventions.md`). Prove each reds by deleting the sentence it matches.

## Out of scope

- Building a registry, or a mechanism that resolves a human report to a stored artifact. FR1 records
  provenance; storing the artifact is a different ticket and needs a reason to exist first.
- Migrating the twelve existing items in the sibling project. They are that project's to rewrite once
  a correct form exists.

## Notes & decisions

- 2026-09-07 — Filed by `retro` from an entry parked in the `ai-building-conventions` buffer on
  2026-08-26, because the gap is in `queue`'s template and this is where that template lives. The
  reporting person's name is deliberately omitted: this repo is public and `company: none`.
