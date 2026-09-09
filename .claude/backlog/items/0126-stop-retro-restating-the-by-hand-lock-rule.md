---
id: "0126"
title: Stop retro restating the by-hand lock rule it drifted from
type: bug
next: develop
status: ready
qa_level: verify
close_by: develop
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0048", "0091"]
expects:
  - skills/retro/SKILL.md
  - tests/retro-lock-citation.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` Step 4 restates `CONCURRENCY.md`'s by-hand-lock rule and drops half of it, and the half it
drops is the one a real absorption pass needs.**

`references/CONCURRENCY.md:159` permits two forms: *"Run the whole sequence in one call, or drop the
trap and `rm -rf` explicitly at the end."* `skills/retro/SKILL.md:225` carries only the first —
*"Read, write, commit and release in **one shell invocation**"* — and then gives the reference's own
reason for it, which is that a `trap ... EXIT` releases on the call's return. That reason constrains
the **trap**, not the invocation count, so the rule and the reason printed beside it disagree.

The cost is not theoretical. The retro pass of 2026-09-09 appended dated notes to eight items,
created ten item files, edited `config.yml` and `QUEUE.md`, drained `FINDINGS.md` and committed. One
invocation carrying all of that is a blob nobody can review before approving. That pass took the
lock with a plain `mkdir`, held it across several calls and released explicitly — the reference's
**second** permitted form, correct under the authority the step cites and forbidden by the step
itself. A session reading Step 4 literally has two options and both are wrong: write the
unreviewable blob, or believe the absorptions must be skipped.

This is the *cite, never restate* failure with a receipt. The copy drifted from source; the copy is
what the sweeper reads; and nothing reported it, because a restatement that is merely **incomplete**
reads as correct on its own.

## Functional requirements

- FR1 — `retro` Step 4's lock paragraph cites `CONCURRENCY.md` *Lock every write to the backlog
  directory* for the permitted by-hand forms and enumerates none of them itself, so there is one
  home for the rule and nothing to drift.
- FR2 — What Step 4 keeps is only what is true of `retro` and of no other stage: that it holds no
  claim token, so its writes are visible by the lock alone, and that draining `FINDINGS.md` and
  appending to an unheld item are both inside the boundary.
- FR3 — A guard executes FR1 and FR2 against Step 4's window rather than against the whole file,
  since `trap`, `lock` and `invocation` are ordinary words elsewhere in this skill and a file-wide
  grep stays green on a rule moved out of the step that must obey it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule keeps one home — `CONCURRENCY.md` — and `retro` cites it; the incident behind the second form stays in `CONCURRENCY-INCIDENTS.md` | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 4's lock paragraph, when `tests/retro-lock-citation.test.sh`
  searches that window for the literal `one shell invocation`, then it is not found. Red-making
  input: today's file, which carries the phrase at line 225.
- [ ] AC2 — Given the same window, when `tests/retro-lock-citation.test.sh` reads it, then it names
  `CONCURRENCY.md` and the section title `Lock every write to the backlog directory`. Red-making
  mutation: deleting the section title from the citation, leaving the bare filename.
- [ ] AC3 — Given the same window, when `tests/retro-lock-citation.test.sh` reads it, then it
  contains neither of the reference's two permitted forms — no `in one call` and no `drop the trap`.
  Red-making mutation: pasting `or drop the trap and rm -rf explicitly at the end` into the
  paragraph, which is the plausible cheap fix this item rejects.
- [ ] AC4 — Given a fixture carrying every asserted phrase **outside** Step 4's window, when
  `tests/retro-lock-citation.test.sh` runs against it, then it fails — proving the scoping in FR3 is
  real and not a file-wide grep wearing a window's name. Red-making input: widening the guard's
  window to the whole file, which turns that fixture green.
- [ ] AC5 — Given the edited skill, when `tests/citations.test.sh` and `tests/skill-size.test.sh`
  run, then each reports `0 failed`. Red-making change: citing a section title that does not exist
  in `CONCURRENCY.md`.

## QA plan

- **Why that level:** the artifact is one paragraph of skill prose and one reference it points at;
  every criterion is a scoped grep, and there is no runner in this project that reaches skills.
- **Specific checks:** run `tests/retro-lock-citation.test.sh`, `tests/citations.test.sh` and
  `tests/skill-size.test.sh` individually — never through the `unit` command, which is fail-fast
  and will stop at another session's red before reaching them (`config.yml`).

## Out of scope

- The five other park steps that never mention the lock at all. That is `0091` FR1, and it is a
  different defect: an omission rather than a drifted copy.
- Whether the by-hand write becomes a script (`0048`).
- `CONCURRENCY.md` itself, which already states both forms correctly.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- Routed to `develop`: `CONCURRENCY.md` has already decided what a by-hand lock may do, and Step 4
  is a stale copy of that decision. There is no open question, only a paragraph to replace.
- **Why cite rather than complete the restatement.** Adding the missing clause is one line and
  leaves the same defect armed: two copies of one rule, drifting again the next time
  `CONCURRENCY-INCIDENTS.md` learns something. `0091` FR1 chose the same shape for the same reason.
  AC3 exists to make that choice falsifiable rather than a preference in a note.
- `close_by: develop` because every criterion is a scoped grep the build session commits and proves
  red first; none is a reading.
- 2026-09-09 (queue, from `FINDINGS.md` parked the same day) — line numbers were current at the
  park date; re-read the source rather than trusting them.
