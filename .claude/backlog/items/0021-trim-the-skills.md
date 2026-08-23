---
id: "0021"
title: Hold the skills to the conventions' own context-rent rule
type: chore
status: blocked
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: ["0010", "0013", "0015", "0016", "0017", "0018", "0019", "0020"]
relates: []
touches:
---

## Problem

`develop` is 6,149 tokens and `queue` is 5,699. Together the five skills force 44,090 tokens of
instructions into a full cycle before any project work happens. Both large files carry worked
examples that restate the sentence above them and incidents told twice.

`CONVENTIONS_CORE.md` already sets the bar these files are not meeting: *"Write the rule and the
failure it prevents; cut the reasoning that convinced you, the worked example that restates the
sentence above it, and the second phrasing of the same idea. If one session's lessons visibly
grow a file, that is the signal to compress, not to keep."* The skills enforce that on every
project and do not apply it to themselves.

Re-invoking a skill in one session re-injects its whole file, so length is paid more than once
even within a single run.

## Functional requirements

- FR1 — Each of the five `SKILL.md` files is reduced by roughly 30% measured in bytes.
- FR2 — **No rule is dropped.** What goes is duplicated phrasing, examples that restate the
  adjacent sentence, and narrative that is not the rule.
- FR3 — The ticket records before and after sizes for each file.
- FR4 — Every worked example that survives earns it by showing something the prose cannot state
  directly.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule and the failure it prevents survive every cut; the reasoning that convinced the author is what goes. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given each of the five files, when its size is compared to the recorded baseline,
      then it is at least 25% smaller.
- [ ] AC2 — Given the rule headings captured before the change, when each is grepped for after,
      then every one is still present.
- [ ] AC3 — Given the ticket's notes, when read, then before and after byte counts are recorded
      for all five files.

## QA plan

- **Level:** verify — documentation.
- **Scripted assertion:** `wc -c skills/*/SKILL.md` compared against a baseline captured in the
  ticket, plus the same captured-headings diff 0020 uses. AC1 asserts a *floor* of 25% against a
  30% target, so a file that legitimately compresses less does not fail the ticket while a file
  that was not touched does.

## Out of scope

- `CONCURRENCY.md` — 0020 owns it.
- Removing any check, gate, or standard.

## Notes & decisions

- **Last on purpose.** Every other ticket in effort 0009 rewrites paragraphs in these files.
  Trimming first means trimming text that is about to change, and then trimming again.
- Blocked by the whole effort rather than by one ticket, which is unusual and correct: the
  blocker is not a dependency on any single outcome but on the files settling.
