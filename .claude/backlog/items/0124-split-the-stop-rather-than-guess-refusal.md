---
id: "0124"
title: Split the stop-rather-than-guess refusal out of the conventions ladder that instances it
type: debt
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
relates: ["0111", "0078", "0116"]
expects:
  - references/CONVENTIONS.md
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`CONVENTIONS.md` rung 3's refusal now has four call sites, and the file it lives in is scoped to
conventions only.** The sentence — *do not guess a path, do not search the filesystem for a
directory that looks right*, stop and say so — was written for resolving the conventions directory.
It is now cited for the findings buffer (`0111`), for the tools repo (`0078` FR2) and, once filed,
for the backlog directory itself (`0116`).

The **prohibition and the stop-rather-than-guess refusal are the general rule**; the conventions
ladder is one instance of it. `references/CONVENTIONS.md` also carries the fail-open warning that
belongs to the same rule — a broken explicit setting masked by a working fallback — which is not
about conventions either.

**Every citing ticket has put "changing `CONVENTIONS.md`'s own ladder" out of scope**, so nothing
owns the generalisation. The predictable next step is a fifth per-project file citing a conventions
file for a reason unrelated to conventions, which reads to a new session as a mis-citation.

## Functional requirements

- FR1 — the refusal, the do-not-search prohibition and the fail-open warning live in one place that
  is not scoped to conventions.
- FR2 — `references/CONVENTIONS.md`'s ladder cites that place rather than stating the rule, per the
  repo's cite-never-restate discipline.
- FR3 — the existing call sites are repointed, and a guard counts them so a fifth cannot quietly
  cite the conventions file again.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | A restated rule is a rule that drifts; exactly one site states it | `documentation-conventions.md` |

## Open design question  *(only while `next: design`)*

- **Question:** does the general rule become its own reference file, a section of an existing one,
  or a convention in the conventions repo? The last is plausible — the rule would hold on someone
  else's codebase — and would change who owns it.
- **Why it blocks specification:** FR1 cannot name a destination and FR3 cannot name a guard until
  this is chosen.
- **Settle it with:** `/design`

## Acceptance criteria

Written once the design question is settled.

## QA plan

- **Why that level:** prose relocation checked by greps and a call-site count.
- **Specific checks:** to be written with the ACs; they must include the count from FR3, since a
  relocation that leaves one caller behind is the failure this ticket exists to prevent.

## Out of scope

Any change to what the conventions ladder itself resolves.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-08 and deferred once by this retro
  before being filed properly. `0116`, filed the same day, is the fourth call site and puts this
  change out of scope like the others.
