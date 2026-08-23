---
id: "0021"
title: Hold the skills to the conventions' own context-rent rule
type: chore
next: develop
status: blocked
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0009"
blocked_by: ["0023", "0025"]
relates: ["0020"]
expects:
  - skills/prototype/SKILL.md
  - skills/queue/SKILL.md
  - tests/skill-size.test.sh   # new
  - README.md
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

- FR1 — **Every `skills/*/SKILL.md` is at most 20,190 bytes** — ~5,000 tokens at the 4.038
  bytes/token ratio this lineage established. A ceiling, not a reduction: it is the number that
  matters at read time, and it does not move when a sibling ticket lands a mandated paragraph.
  Two files are over it today, `prototype` and `queue`; the other four are under it and must stay
  under.
- FR2 — **No rule is dropped.** What goes is duplicated phrasing, examples that restate the
  adjacent sentence, and narrative that is not the rule. FR2 outranks FR1 wherever they conflict.
- FR3 — The ticket records the byte count of all six files before and after this pass, **appended
  to the table already in this ticket** rather than replacing it.
- FR4 — Every worked example that survives earns it by showing something the prose cannot state
  directly.
- FR5 — **The ceiling gets an executable home:** `tests/skill-size.test.sh`, following this repo's
  existing `tests/*.test.sh` pattern, and listed in `README.md` beside the others. A ceiling
  recorded only in a closed ticket is not a gate — the next edit breaches it and nothing says so.
- FR6 — **A file that cannot reach the ceiling without dropping a rule is recorded as a named
  exemption, and that is a pass rather than a failure.** The exemption names the file, its floor in
  bytes, and each surviving section with its byte count, showing that what remains is rules. The
  test reads the exemption list so it stays green while still guarding every other file. This
  exists because the previous pass had nowhere to put that outcome, so a legitimate result read as
  a failed AC and the ticket bounced back to `queue`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule and the failure it prevents survive every cut; the reasoning that convinced the author is what goes. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `wc -c skills/*/SKILL.md`, when each count is compared to 20,190, then every
      file is at or under it, or appears in the FR6 exemption list carrying the evidence FR6
      requires. No percentage and no baseline: the number is absolute.
- [ ] AC2 — Given the `##` and `###` headings captured from all six files immediately before this
      pass, when the same headings are grepped for afterwards, then every one is still present.
      Diffed against the captured list, never counted — a count stays green if one rule is dropped
      and another duplicated.
- [ ] AC3 — Given this ticket's notes, when read, then before and after byte counts for all six
      files are recorded for this pass, alongside the previous pass's table.
- [ ] AC4 — Given `tests/skill-size.test.sh`, when a copy of a compliant `SKILL.md` is padded past
      the ceiling, then the test fails and names that file; when the tree is unmodified, it passes.
      A guard only ever seen passing is indistinguishable from one wired to nothing.
- [ ] AC5 — Given `README.md`, when its test list is read, then `tests/skill-size.test.sh` appears
      beside the existing entries.

## QA plan

- **Level:** verify — documentation and a shell test. No runner exists in this project; the suite
  is `tests/*.test.sh` run by hand.
- **Why this level:** the subject is prose, and the contract is a size a command can measure.
  Nothing crosses a seam.
- **Specific checks:**
  - `wc -c skills/*/SKILL.md` against the fixed 20,190-byte ceiling — exact, no ratio applied at
    assertion time, and immune to a sibling ticket moving a baseline.
  - `tests/skill-size.test.sh`, run clean and run against a padded fixture, per AC4.
  - The captured-headings diff 0020 uses, for AC2.
  - Measure in **bytes**, not `len()` on decoded text: these files are full of multi-byte
    em-dashes, and the previous pass found `len()` undercounting by ~46 on one file.

## Out of scope

- `CONCURRENCY.md` — 0020 owns it. The ceiling here covers `skills/*/SKILL.md` only.
- Removing any check, gate, or standard.
- **Getting under the ceiling by relocating prose into a new file the same cycle still opens.**
  That moves the cost rather than cutting it, and the ceiling is a proxy for what a cycle actually
  loads. Moving a rule into a reference read *conditionally* is legitimate; moving one into a file
  the skill tells every run to read is not.
- Re-trimming `design`, `develop`, `retro` or `verify` beyond whatever it takes to hold them under
  the ceiling. They are under it; FR1 asks them to stay there, not to shrink.

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

### Re-spec (2026-08-23, `queue`)

**Option 2 of the three the outcome proposed: an absolute ceiling.** Options 1 and 3 both keep a
percentage, and a percentage is the defect — the previous pass could not close because its baseline
moved 18% while it sat blocked behind eight tickets. `queue`'s own rule now states this directly:
*state any size or budget target absolutely — bytes, a count, a ceiling — never as a percentage of a
baseline a sibling ticket in the same effort is still moving.* That rule was written out of this
ticket's failure, so applying it here is mandated rather than merely recommended.

**20,190 bytes = ~5,000 tokens**, the figure the outcome recommended. Measured in bytes because
`wc -c` is exact and needs no ratio at assertion time; the token figure is the readable equivalent.

Baseline at re-spec, all six files in the repo working tree:

| File | bytes | ~tokens | vs ceiling |
|---|---|---|---|
| `design` | 8,797 | 2,179 | under |
| `develop` | 19,645 | 4,865 | under — **545 bytes of headroom** |
| `prototype` | 26,262 | 6,504 | **over by 6,072** |
| `queue` | 24,159 | 5,983 | **over by 3,969** |
| `retro` | 14,831 | 3,673 | under |
| `verify` | 14,415 | 3,570 | under |
| **total** | **108,109** | **26,773** | — |

So the work is two files, not six — and that is the honest scope. The previous pass already cut to
FR2's limit; four files are at their floor and the ticket now says so instead of asking for a further
25% it cannot get. Down from the problem statement's 44,090 tokens per cycle, a compliant tree is
≤98,068 bytes / ~24,286 tokens.

**`develop`'s 545-byte margin is a standing cost of the ceiling, not a defect** — the same note 0020
recorded when `CONCURRENCY.md` landed 7 tokens under its own. 0025 adds mandated content to
`develop`, which is part of why this ticket waits for it.

**Routed to `develop`, not `design`.** Nothing is undecided. The ceiling is a number, its home is
this repo's established `tests/*.test.sh` pattern, and the conventions already say a rule belongs in
a test that fails. Unfamiliar is not undecided; there is no surface and no open question.

**`blocked_by` now names tickets instead of an effort.** The original note said this ticket was
"blocked by the whole effort rather than by one ticket" while frontmatter carried `blocked_by: []`
and `status: ready` — a `blocked` nothing could derive, which is exactly what the queue's own rule
forbids. The two open tickets that edit files this ticket must measure are **0023** (in-progress,
`skills/queue/SKILL.md` — a trim target) and **0025** (`skills/develop/SKILL.md` — which consumes
that 545-byte margin). Naming them is the derivable form of "wait for the files to settle," and it
keeps the reason for going last intact: trimming text about to change means trimming twice.

**FR6 is the part that stops this bouncing a second time.** The previous outcome was not a failure —
FR2 held and four files were genuinely at their floor — but the ticket had no way to *record* that
and still close, so a correct result was filed as a red AC. An exemption with an evidentiary bar
(the file, its floor, every surviving section with its byte count) is closable and still auditable.

