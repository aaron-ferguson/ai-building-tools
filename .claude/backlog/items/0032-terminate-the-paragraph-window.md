---
id: "0032"
title: Terminate batching.test.sh's paragraph window on a blank line
type: bug
next: verify
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - tests/batching.test.sh
claimed_by: "ade9"
claimed_at: 2026-08-25T02:13:10Z
touches:
  - tests/batching.test.sh
  - skills/develop/SKILL.md
  - .claude/backlog/items/0032-terminate-the-paragraph-window.md
---

## Problem

`tests/batching.test.sh` narrows its assertions to `develop`'s batching paragraph with:

```sh
awk '/one gate per session/{f=1} f{print; if (++n>14) exit}'
```

That is a 15-line window over a 12-line paragraph, so it currently reads three lines of the *next*
paragraph. Every "in the paragraph" assertion is therefore one edit away from passing on unrelated
prose — the adjacent-measurement failure `verify` Step 3 warns about, where a check runs, asserts,
and measures something next to the thing it exists to pin.

Verified on 2026-08-23 that the suite still fails correctly when the date is stripped from the
paragraph alone, so this is **latent, not live**. It becomes live the moment the paragraph shortens
or the following paragraph gains a phrase the assertions look for.

A blank-line terminator costs nothing and cannot drift.

## Functional requirements

- FR1 — the paragraph extraction terminates on the paragraph's own end (a blank line), not on a line
  count.
- FR2 — the extracted window contains no line from any neighbouring paragraph. This is the property
  under test, so it is asserted rather than eyeballed.
- FR3 — the extraction fails loudly if its start pattern matches nothing, rather than yielding an
  empty window. An empty window makes every "does not contain" assertion pass and every "contains"
  assertion fail, so half the suite would go green for the wrong reason.
- FR4 — the same line-count-window pattern is swept for across `tests/`, and any other instance gets
  the same treatment. A latent defect in one guard is usually a copied idiom.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | State in a comment why the terminator is a blank line rather than a count, so the count does not come back as a "simplification" | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `tests/batching.test.sh`, when its extraction is read, then it terminates on a
  blank line and contains no line-count bound.
- [ ] AC2 — Given the extracted window, when it is printed, then its last line is the batching
  paragraph's last line and no line of the following paragraph appears.
- [ ] AC3 — Given a tree where the batching paragraph's start phrase has been renamed, when the
  suite runs, then it fails with a message naming the extraction as the cause — not with a
  misleading content assertion.
- [ ] AC4 — Given the paragraph with its date stripped, when the suite runs, then it still fails —
  the behaviour verified before this change is preserved.
- [ ] AC5 — Given a phrase the suite asserts is absent, when that phrase is added to the paragraph
  *following* the batching paragraph, then the suite still passes — proving the window no longer
  reaches it. This is the regression the ticket exists for.
- [ ] AC6 — Given `grep -rn "n>[0-9]" tests/`, when it runs, then no remaining paragraph extraction
  is bounded by a line count.
- [ ] AC7 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then all
  suites pass.

## QA plan

- **Level:** verify — a shell guard with no runner.
- **Why this level:** every requirement is a property of the guard's own extraction, drivable by
  running it against a mutated copy of `skills/develop/SKILL.md` in a fixture directory.
- **Specific checks:** AC5 driven explicitly, since it is the whole point — add the sentinel phrase
  to the *next* paragraph in a fixture copy and confirm green; AC4 re-driven to confirm nothing
  regressed; each mutation diffed before it is trusted.

## Out of scope

- Any change to `develop`'s batching paragraph itself. The guard is what is wrong here.
- Converting these prose greps into some other mechanism. The `verify` QA level for this project is
  a scripted assertion over prose, and that is not in question.

## Notes & decisions

- Built 2026-08-24. FR4's sweep (`grep -rn '++n\|n>[0-9]' tests/`) returns exactly one hit across all
  ten suites — this line. The idiom was not copied, so there is nothing else to give the same
  treatment.
- The window was 15 lines over a 13-line paragraph (`skills/develop/SKILL.md` lines 30–42), so it
  carried the blank line plus the first line of *"Another session may be working this same backlog."*
  Confirmed before the change and re-confirmed green after.
- FR2 is asserted as two properties rather than one: the window holds no blank line (it cannot have
  run past its own paragraph) **and** the line immediately after the window in `$DEV` is blank or
  EOF (it did not stop short either). One without the other is satisfiable by a broken window —
  a window truncated at 3 lines passes the first alone.
- All three mutations driven against a fixture copy in a temp tree, never the live skill: start
  phrase renamed → exit 2 naming the extraction (AC3); every date stripped from the paragraph →
  still red (AC4); sentinel `parent slice 2026-08-22 0026 expects:` added to the *following*
  paragraph → still green (AC5), which is the regression the ticket exists for.
- **The AC4 mutation did not red on the first attempt, and the guard was right — the mutation was
  incomplete.** The paragraph carries two dates, and AC4's grep is satisfied by either. That is a
  real weakness in a neighbouring assertion but not this ticket's; parked in `FINDINGS.md`
  (2026-08-24) rather than fixed here, per *Out of scope*.
- `grep -m1` was written first and replaced with `grep | head -1`: `-m` is a BSD/GNU extension used
  nowhere else in this project, whose scripts are POSIX `sh` throughout.

- Fixture discipline for this one specifically: build the fixture from a *copy* of the skill placed
  in a temp tree and mutated there, and do not assert against the live `skills/develop/SKILL.md`
  while mutating it. Per `testing-conventions.md`, a fixture derived from the artifact under test is
  how an unrelated edit reds an unrelated case.
