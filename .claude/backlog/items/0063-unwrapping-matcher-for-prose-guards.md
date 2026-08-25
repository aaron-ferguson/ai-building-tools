---
id: "0063"
title: Give the prose guards a matcher that survives a rewrap
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0005", "0032", "0042", "0053"]
expects:
  - tests/citations.test.sh
  - tests/batching.test.sh
  - tests/graph-fields.test.sh
  - tests/external-feedback.test.sh
  - CLAUDE.md
claimed_by:
claimed_at:
touches:
---

## Problem

Every guard in this repo greps prose, and prose wraps — so a phrase that straddles a line break
cannot be asserted at all. `grep` is line-based, so a sentence containing `never its dependents`
reds against a template that plainly contains it, because the phrase exists only as `never its` and
`dependents` on two lines. Writing 0005's guard cost a session to that.

The red is **indistinguishable from a missing rule**, and the tempting fix is loosening the
assertion to a shorter fragment — which is exactly how these checks go vacuous, and this repo has
already shipped three guards that could not fail. This project has no other kind of test: eleven
suites, all of them fixed-string greps over markdown that a later editor will rewrap for width.

The rule has been written down and the tool has not. `CLAUDE.md` says rewrapping a guarded
paragraph is a breaking change; `testing-conventions.md` carries no rewrap rule at all — checked,
zero occurrences — and **no suite has an unwrapping helper**, also checked. So the whole defence is
a sentence in one project's own documentation asking every future editor to remember, and every
ticket written this week has had to carry "match a phrase short enough to sit on one source line"
into its QA plan by hand.

The cost is now recurring rather than historical: eleven queued tickets name scoped prose greps as
their scripted assertion.

## Functional requirements

- FR1 — The suites gain a matcher that collapses a file's line breaks and runs surrounding
  whitespace together before matching, so an asserted phrase spanning a wrap is found.
- FR2 — The matcher can be **scoped to a section or a step** rather than the whole document, since
  a document-wide match pins vocabulary rather than structure and that is the defect 0042 exists to
  repair. A guard that unwraps a whole file and matches anywhere in it is a worse guard, not a
  better one.
- FR3 — The matcher lives in one place the suites share, or each copy names the others, so the
  eleven suites do not grow eleven spellings of it.
- FR4 — At least one existing guard is converted to it and proved to survive a rewrap of the
  paragraph it asserts on, so the matcher is exercised by a real assertion rather than only by a
  fixture.
- FR5 — `CLAUDE.md`'s statement that rewrapping a guarded paragraph is a breaking change points at
  the matcher, so the remaining hand-written rule is scoped to what the matcher still cannot cover.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `CLAUDE.md`'s existing warning is updated in the same change, not left standing beside a tool that supersedes part of it | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture file whose asserted phrase is split across a line break, when the
  matcher runs, then it matches.
- [ ] AC2 — Given the same fixture with the phrase absent entirely, when the matcher runs, then it
  does not match — so AC1's tolerance has not made the guard unfalsifiable.
- [ ] AC3 — Given the matcher scoped to one section, when the asserted phrase is present only
  **outside** that section, then it does not match.
- [ ] AC4 — Given the guard converted under FR4, when the paragraph it asserts on is rewrapped at a
  different width, then that guard still passes.
- [ ] AC5 — Given that same converted guard, when the asserted claim is deleted from the paragraph,
  then it fails.
- [ ] AC6 — Given `CLAUDE.md`, when read, then its rewrap warning points at the matcher.
- [ ] AC7 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.

## QA plan

- **Level:** unit — the deliverable is a shell function used by the suites, and this project's
  `unit` command runs every `tests/*.test.sh`.
- **Why this level:** AC1–AC3 are fixture-driven calls; AC4 and AC5 are mutations of a real file.
- **Specific checks:** drive AC4 by rewrapping at a genuinely different width, not by reflowing to
  the same one. Drive AC5 by deleting the claim rather than a word of it — `break the definition,
  never the expectation`. Confirm each mutation landed by diffing against a copy taken before the
  edit rather than against HEAD, and revert between.

## Out of scope

- **Converting every existing guard.** FR4 asks for one, proved. A sweep is a separate ticket and
  wants the matcher settled first.
- Landing a rewrap rule in `testing-conventions.md`. That file is in another repo and this ticket
  cannot commit there; if the rule belongs there it is that repo's ticket.
- Changing any guard's *subject*. This is about how a phrase is matched, not what is asserted.

## Notes & decisions

- Routed to `develop`: the mechanism is named in the finding (a helper that unwraps before
  matching) and the alternative it offers — a stated rule that guarded sentences are not rewrapped
  — has already been tried and is what is failing.
- **AC2 and AC3 are the load-bearing half.** An unwrapping matcher is a *looser* matcher, and this
  repo's characteristic defect is a guard that runs and cannot fail. Both ACs exist so the fix
  cannot ship as one.
