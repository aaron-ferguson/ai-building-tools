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

### From `FINDINGS.md`, landed 2026-09-05

Two of the four entries below say in their own text that this needs a row and none exists. That was
true when they were written; **this is that row**, and both are filed here rather than re-raised.

- **The guard's failure mode on a *correct* citation is a false accusation, not a miss** (FINDINGS
  2026-09-05, two entries, the second correcting the first). `tests/citations.test.sh` red on the
  shipped tree because `skills/queue/templates/claim` cites *The working tree is shared too* across
  a line break inside a shell comment: the guard reads the citation as `"The # working tree is
  shared too"` and reports a rule that does not exist. This is FR1's hazard hitting the **guard**
  rather than the guarded, and it adds a wrinkle FR1 as written does not cover — collapsing line
  breaks is not enough where the continuation line carries a leading `# `, so the matcher either
  strips a comment marker at a wrap or such a citation is kept on one line by rule. The two entries
  disagree about provenance and the second is right: the wrap was introduced by `0082`'s own first
  commit `3588524`, not inherited, and is already unwrapped and green. The first entry read `git log`
  on the file as evidence of a pre-existing defect, which was the correct read of the only evidence
  available to a session that did not hold the ticket, and still the wrong answer — so **the fix, not
  the incident, is what survives**. FR4's converted guard is a good candidate for this one, since it
  is a real assertion that has already failed this way.
- **A matcher that survives a rewrap does not survive a *reword*, and the anchor word is prose**
  (FINDINGS 2026-08-30). `tests/batching.test.sh` AC4 binds a date to the literal word `dated`, so
  rewriting "capture-side and dated **2026-08-22**" to "capture-side, from **2026-08-22**" leaves
  the figure carrying its own date in exactly the position the assertion exists to require, and the
  suite reports 12 passed, 1 failed. The regex is a good binding and the fix is real — this is its
  residual cost, not an argument against it. But `testing-conventions.md` warns in that same rule
  that a guard whose reds can be artefacts of unrelated correct work teaches everyone to discount
  its reds, and the comment beside the assertion, careful to disclaim rewrap-proofness, does not say
  that the anchor word itself is now load-bearing prose. Whatever FR3 lands should carry that
  disclaimer next to the matcher, so a converted guard does not read as reword-proof.
- **Resolving a cited rule *phrase* is blocked on a citation marker this repo has not decided on**
  (FINDINGS 2026-09-01 `[becd]`, routed here as the nearest live row). 0052's develop pass resolved
  citations at **filename** level and recorded the gap in the guard's own header: telling a citation
  from emphasis needs a marker, because italics carry emphasis throughout, and reading an italicised
  span after a conventions filename as a rule name reports three existing spots
  (`skills/retro/SKILL.md` twice, `skills/verify/SKILL.md` once) that are emphasis and not
  citations. The precedent already exists — `citations.test.sh`'s anchoring rule answered this same
  question for `CONCURRENCY.md` rule names — so it needs extending rather than inventing. This is
  adjacent to FR1 rather than inside it: same suite, same file in `expects:`, but a decision about
  notation rather than a matcher. If it is not taken here it wants its own `design` row, and saying
  so is cheaper than letting it sit unowned a fourth time.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** A NEGATIVE prose assertion whose phrase straddles a wrap is green on arrival and proves nothing, where a positive one reds loudly (3 instances in one session on 0060, `tests/findings-buffer.test.sh`). Whatever matcher this ships should report an absence assertion whose phrase occurs nowhere even unwrapped.
