---
id: "0021"
title: Hold the skills to the conventions' own context-rent rule
type: chore
next: queue
status: ready
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: []
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
- [x] AC2 — Given the rule headings captured before the change, when each is grepped for after,
      then every one is still present.
- [x] AC3 — Given the ticket's notes, when read, then before and after byte counts are recorded
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

## Outcome — AC1 not met on four of six files; sent back to `queue`

**The trim was done to the limit FR2 allows and stopped there.** FR2 ("no rule is dropped") is
non-negotiable, and 0009 restates it as a cross-cutting commitment for the whole effort. AC1's 25% floor
and FR2 conflict on four files, so FR2 won and this ticket does not close.

### FR3 — before and after, all six files

Two baselines are recorded because they answer different questions. The **0021 baseline** is the size
when this ticket started, which is the right one: this ticket is last *on purpose* because every other
ticket in 0009 rewrites these files. The **pre-effort** column is the size before 0009 began, and it is
the figure the problem statement was written against.

| File | pre-effort | 0021 baseline | after | vs baseline | vs pre-effort | AC1 |
|---|---|---|---|---|---|---|
| `design` | 7,118 | 10,983 | 8,797 | −19.9% | +23.6% | **not met** |
| `develop` | 25,136 | 27,661 | 19,171 | −30.7% | −23.7% | met |
| `prototype` | 31,297 | 32,855 | 26,262 | −20.1% | −16.1% | **not met** |
| `queue` | 22,862 | 28,175 | 22,787 | −19.1% | −0.3% | **not met** |
| `retro` | 16,113 | 17,507 | 14,831 | −15.3% | −8.0% | **not met** |
| `verify` | 10,316 | 15,993 | 11,946 | −25.3% | +15.8% | met |
| **total** | **112,842** | **133,174** | **103,794** | **−22.1%** | **−8.0%** | — |

`references/CONCURRENCY.md`, which 0020 owns, went 17,943 → 6,017 bytes in the same pass, so a full
cycle's mandated reading fell further than this table alone shows.

### Why AC1 and FR2 conflict

**This effort added roughly 20,300 bytes of AC-mandated content to these six files before this ticket
ran** — 0012's closing step in each, 0017's session header in each, 0018's routing section, 0019's
taste/fact escalation, 0013's close step in `verify` and stop in `develop`, 0016's cadence. Every byte of
it is required by an acceptance criterion that is now ticked. Then this ticket asks for 30% off the
result. **The two requirements were written independently and never checked against each other**, and
`verify` and `design` show it plainly: both are *larger* than before 0009 started while having been cut
by a quarter and a fifth of what they had grown to.

The files that hit target are the two that carried the most incident narrative — `develop` (−30.7%) and
`verify` (−25.3%). That is the ticket's own thesis working exactly as written. `queue`, `retro`, `design`
and `prototype` are mostly dense rule lists, and once the narrative was gone what remained was rules.

### AC2, verified

All 59 `##` headings captured before the change are present after, diffed against the baseline rather
than counted — a count stays green if one rule is dropped and another duplicated.

### Proposed re-spec

`queue` should re-write AC1 as one of:

1. **A per-file floor set from each file's own content mix**, not one number across six files. The
   evidence is in the table: narrative-heavy files compress by a third, rule-dense files by a fifth.
2. **An absolute budget per skill** — say 5,000 tokens for a lifecycle skill — which is what actually
   matters at read time and does not move when another ticket adds a mandated paragraph.
3. **A floor measured against the pre-effort baseline**, making the mandated additions visible as the
   cost they are rather than as headroom to cut.

Option 2 is the recommendation: a percentage off a moving baseline is un-auditable, and the reason this
ticket cannot close is that its baseline moved 18% while it sat blocked behind eight others.

## Notes & decisions

- **Last on purpose, and the ordering was right.** Every other ticket in 0009 did rewrite these
  paragraphs; trimming first would have meant trimming text about to change and then trimming again.
  What the ordering did not anticipate is that those rewrites would *grow* the files by 18%, which is
  what makes the percentage target unreachable.
- **Six files, not five.** The ACs say five but the assertion globs `skills/*/SKILL.md`. `prototype` was
  trimmed and recorded with the rest — same reading applied throughout this effort.
- **Word-shaving is nearly free of effect; deciding what leaves is the whole thing.** Measured on
  `CONCURRENCY.md` under 0020: five passes of tighter prose moved 1,100 bytes, and naming a category to
  move — live-conflict procedures, design rationale, incident narrative — moved 11,000. The same held
  here. The categories that legitimately left the skills were incident retelling, examples restating the
  adjacent sentence, and **rules the skills restated from `CONCURRENCY.md`** — that last one is where
  `develop` found most of its 30%, and it is a rule the skills were breaking about themselves.
- **Re-wrapping breaks grep-based assertions, repeatedly.** Compressing a paragraph moves a phrase across
  a line break, and every `verify`-level assertion in this effort greps single lines. It caught 0012,
  0015, 0016 and 0019 during this trim. Worth a rule somewhere: a scripted assertion on prose should
  match a phrase short enough to survive reflow, or the file should be read with newlines collapsed.
