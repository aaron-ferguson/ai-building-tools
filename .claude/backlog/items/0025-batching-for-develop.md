---
id: "0025"
title: Name the batching case for develop, not just for capture
type: chore
next: verify
status: done
qa_level: verify
size: s
created: 2026-08-23
closed: 2026-08-23
source: agent
parent: "0009"
blocked_by: []
relates: ["0026"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - README.md
claimed_by:
claimed_at:
touches:
---

## Problem

0017 established *one skill per session, **not** one ticket per session*, and argued the batching
exception for `queue` only: understanding the domain is a shared cost paid once, so a capture session
should write every related ticket it can. **Nothing in the suite says the same thing about `develop`**,
and the same arithmetic applies with more force — a develop session pays for the conventions, the
project's `CLAUDE.md`, `CONCURRENCY.md`, the codebase orientation and the skill file itself before it
writes a line, and every one of those is a shared cost across tickets that touch the same files.

The gap is not theoretical. On 2026-08-23 one session took eleven tickets from a single effort, because
running eleven sessions would have re-paid that whole startup eleven times over tickets that rewrote the
same six files. It was the right call and **no rule sanctioned it**. That leaves two bad outcomes
available and no way to tell which one a reader will pick: a session that isolates per ticket and pays
the startup repeatedly, or one that batches without a rule and therefore without the guardrails batching
needs.

`develop` currently says *"One item per invocation unless told otherwise"* — which reads as a
prohibition, and is the sentence a careful reader would follow into the expensive option.

## Functional requirements

- FR1 — `develop` states the batching case in its header, alongside the one-skill-per-session statement:
  **one gate per session, not one ticket per session**, where a gate is a set of tickets that share files
  or a slice.
- FR2 — It gives the test for what may be batched, rather than leaving it to judgement: tickets that
  **share a file scope** (their `expects:` overlap) or **share a parent slice**, and that are all
  `next: develop` and takeable. Tickets from unrelated efforts do not batch — the shared cost is not
  shared.
- FR3 — It names the two guardrails batching needs, both of which today's run needed: **claim and close
  each ticket individually** — the row is the unit of ownership whatever the session is — and **stop at
  the first ticket whose contract turns out wrong** rather than carrying a wrong assumption into the rest
  of the batch.
- FR4 — The statement carries a figure and its date, per 0017's precedent that a workflow rule with no
  cost behind it gets dropped under pressure. Cite the capture-side measurement that exists today and
  name 0026 as the source of the develop-side one.
- FR5 — `develop`'s *"One item per invocation unless told otherwise"* is replaced, not annotated. A
  prohibition and a permission sitting in one file is worse than either.
- FR6 — `verify` gets the same treatment, since a batch of built tickets is checked the same way and for
  the same reason — and says explicitly that a batch does **not** license one verdict covering several
  tickets: each closes on its own ACs.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The figure carries its date and source, so a later reader can tell a measurement from an assertion. | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/develop/SKILL.md`, when read, then it states the batching case and gives the
      shared-file-scope-or-shared-slice test.
- [x] AC2 — Given that file, when grepped for `One item per invocation`, then there is no match.
- [x] AC3 — Given that file, when read, then it requires claiming and closing each ticket individually,
      and stopping the batch on a wrong contract.
- [x] AC4 — Given that file, when read, then the batching statement carries a dated figure.
- [x] AC5 — Given `skills/verify/SKILL.md`, when read, then it states that each ticket in a batch closes
      on its own acceptance criteria.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -c 'one gate per session' skills/develop/SKILL.md` is 1;
  `grep 'One item per invocation' skills/develop/SKILL.md` returns nothing; `grep '20[0-9][0-9]-[0-9][0-9]'`
  finds a date inside the batching paragraph. AC2 is asserted as an absence separately from AC1's
  presence, because adding the permission while leaving the prohibition is the likely half-done outcome.

## Out of scope

- Batching for `design`, `retro` or `prototype`. `retro` is already a batch process by 0016; the other
  two are invoked per question and per artifact.
- Changing what `develop` does per ticket. This ticket says how many tickets a session takes, not what it
  does with one.

## Notes & decisions

- **Not blocked on 0026, deliberately.** The rule is correct on the evidence that exists — 0017 already
  cites a measured capture-side figure, and today's eleven-ticket run is real if qualitative. Blocking
  prose on a measurement that has not been scheduled is how a correct rule waits indefinitely. FR4 is
  written so the develop-side figure can be folded in when 0026 produces it; **revisit this ticket's
  notes when it does.**
- **`gate` now carries two meanings in the files this ticket edits, and FR1 fixed the term.** It
  already meant a quality gate — `develop` Step 5's review checklist is "a build-quality gate, not
  QA", and `README.md` said "no gate is removed" — and FR1 plus the QA plan's `grep` pin the new
  batching sense. Inherited, not chosen: the batching sense is defined at first use in both skills,
  and README's other use is now "no *quality* gate is removed". If a third sense ever appears,
  rename this one; the quality gate is the older and more widely cited.
- **README was in `expects:` but named by no FR or AC.** Editing it is not scope creep:
  `documentation-conventions.md` requires that a change contradicting a documented rule correct that
  rule in the same commit, and README argued the batching exception for `queue` **only** — which
  develop's new rule makes incomplete rather than merely unmentioned.
- FR4 cites the capture-side figure because **0026 has not run**, exactly as this ticket's ordering
  note anticipated. It is named in both skills and in README as the source of the develop-side one,
  so folding it in is a grep rather than a re-read.
- The counter-intuitive half is FR3's first guardrail. Batching is per *session*, and ownership stays per
  *row* — a batch that claims all its tickets at once would hold rows it is not working on, which is the
  scope-reservation problem `CONCURRENCY.md` already names for `touches:`.
- **Verified 2026-08-23 (PASS).** `tests/batching.test.sh` 11/11, and every one of the 11 was
  **proved mutable** — each assertion was driven red by breaking the prose it guards and restored by
  the mutated path alone. The mutation that mattered: `batching.test.sh`'s `awk` window is
  `/one gate per session/` plus 15 lines, which **overspills the batching paragraph by three lines**,
  so the "inside the paragraph" assertions are only paragraph-scoped by luck of what follows.
  Stripping the date from the paragraph alone still goes red today, so it is a latent weakness rather
  than a false green — parked in `FINDINGS.md`, not fixed here.
- **The copy verified is the repo copy, which is not the copy that ran.** `skills/develop`,
  `skills/verify` and `skills/queue` all differ between this repo and the pinned install at
  `0.9.1`, so the session that verified this rule was reading the pre-0025 `verify`. Per `SOURCE`
  the rule is not live until the version is bumped, pushed and reinstalled.
