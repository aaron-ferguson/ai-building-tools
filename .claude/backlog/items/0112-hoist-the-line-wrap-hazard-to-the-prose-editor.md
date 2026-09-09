---
id: "0112"
title: Hoist the line-wrap hazard to the session editing prose, not only the one writing a guard
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-07
source: retro
parent:
blocked_by: []
relates: ["0063", "0095"]
expects:
  - CLAUDE.md
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - tests/retro-tool-edit.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**One line break defeats two different tools, and only one of them is written down where the
session that trips on it will read it.** `CLAUDE.md` lines 48-51, under `## Tests`, states the
`grep` half:

> **rewrapping a guarded paragraph is a breaking change**: `grep` is line-based, so an asserted
> phrase that straddles a line break cannot be matched at all.

The same break defeats an **anchored edit**, which matches literally. `skills/queue/SKILL.md:239-242`
does say this — *"The same break defeats an `Edit`… Quote within one line, or anchor on a line you
have just read"* — but it says it inside Step 2's guidance on **writing a QA plan's assertions**.
That is read when authoring a ticket. It is not read when editing prose, and **editing prose is how
every change in this repo is made.** `skills/retro/SKILL.md`, which makes most of them, says
nothing; neither does `skills/develop/SKILL.md`.

**Measured 2026-09-07, and the timing is the evidence.** Minutes after landing *"count on flattened
text: a line-based count returns one for a phrase that wraps across a line break"* into
`ai-building-conventions/testing-conventions.md`, an anchored edit to `skills/develop/SKILL.md`
failed: the anchor `Same discipline the backlog already applies` is stored as
`Same\ndiscipline …`, `str.find` returned -1, and the assertion fired. The session that had just
written the rule for guards hit it as an editor and had no rule to reach for.

**This is a cost, not a correctness defect, and that is why it is filed here rather than higher.**
The edit fails loudly; the guard's version of the same break fails silently. What it costs is a
retry per occurrence on every prose change in a repo whose entire product is prose — and, once,
a failure that reads as *the text is absent* rather than *the text is split*, which sends a session
looking for the wrong thing.

**Precedent for the shape.** 0095 hoists the shell short-circuit hazard to where a guard author
reads it. Same operation, different hazard, different reader; whoever takes one should look at the
other.

## Functional requirements

- FR1 — The hazard is stated for the **anchored edit** as well as for `grep`, in the place a session
  about to edit prose reads: an anchor is chosen from within one source line, or from a line just
  read.
- FR2 — It is stated **once** and cited from the others. `skills/retro/SKILL.md`'s edit step is the
  one that must reach it, since that skill makes most of this repo's prose edits and currently says
  nothing.
- FR3 — The two existing statements are reconciled rather than left as apparent duplicates. They
  have **different readers**: `skills/queue/SKILL.md` ships to every project that installs the
  plugin, `CLAUDE.md` is read only in this repo. Whichever is kept says which reader it is for, so
  a later editor tidying duplicates does not delete the one that reaches the other audience.
- FR4 — `CLAUDE.md`'s existing sentence is extended or repointed in the same change, never left
  standing beside a second sentence about the same line break.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Stated once, cited elsewhere; and it is added to files whose size is gated, so a size rejection is a relocation signal rather than something to exempt. `CONVENTIONS_CORE.md`'s *every rule pays rent in context* binds directly — this is a sentence, not a section. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `CLAUDE.md`'s line-break paragraph, when read, then it names the anchored edit as
  well as `grep`. **Red when** the anchored-edit clause is deleted: the paragraph still names `grep`
  and still reads as a complete rule, so this is the mutation that tells the new rule from the old
  one — the assertion must not be satisfiable by the `grep` sentence alone.
- [ ] AC2 — Given `skills/retro/SKILL.md`'s edit step, when read, then it points at the rule. Red
  when the pointer is deleted from that step.
- [ ] AC3 — Given the guard for AC2, when the pointer is moved out of the edit step into any other
  step of the same file, then it reds. Anchored to the step, not the file, per
  `tests/retro-tool-edit.test.sh`'s header rule.
- [ ] AC4 — Given `CLAUDE.md` and `skills/queue/SKILL.md` Step 2, when read, then each says which
  reader its copy serves. Red when the audience clause is stripped from either — asserted per file,
  so dropping one does not stay green on the other.

## QA plan

- **Why that level:** the deliverable is prose in three files and this repo's only runner is
  `tests/*.test.sh`, all of which grep prose.
- **Specific checks:** add cases to `tests/retro-tool-edit.test.sh` for AC2 and AC3, anchored to
  retro's edit step. AC1 and AC4 assert on `CLAUDE.md`; `tests/release.test.sh:264` is the existing
  precedent for a `CLAUDE.md` assertion in this suite. Prove each can fail by deleting exactly the
  clause it matches and reverting — for AC1, delete the anchored-edit clause only, leaving the
  `grep` sentence intact, and confirm it reds.
- **Match within one source line.** These files are wrapped prose and the assertions being written
  are about this exact hazard; an assertion that trips on it would be the joke writing itself.

## Out of scope

- **Building an unwrapping matcher.** That is 0063, and it addresses the `grep` half. This ticket is
  the residual hand-written rule for the half a matcher cannot cover, because the `Edit` tool is not
  ours to change.
- **The `testing-conventions.md` half.** That file is in `ai-building-conventions` and already
  carries the flattened-text rule for counting, landed 2026-09-07.

## Notes & decisions

- **Routed to `develop`.** No decision is open: the rule's text already exists in
  `skills/queue/SKILL.md` and the missing reader is named. Where in `CLAUDE.md` it sits is a
  placement call `develop` can make from the file — the current paragraph is under `## Tests`, which
  is the guard framing, and the anchored edit is not a test.
- **Collides with 0063 FR5**, which rewrites the same `CLAUDE.md` sentence to point at the matcher
  it builds. Neither blocks the other and there is no ordering requirement, but whichever lands
  second edits a paragraph the first has moved. `relates:` rather than `blocked_by:` because either
  order works and forcing one would sink a row for no gain.
- Captured from `FINDINGS.md` 2026-09-07.

- 2026-09-09 (retro, from two `FINDINGS.md` entries of 2026-09-09) — **two additions, one of them a
  trigger this ticket does not currently name and one a detector it could carry.**
  **The trigger: a size-driven rewrap of a paragraph you are still writing.** A session read
  `CLAUDE.md`'s rule before writing anything and still shipped four reds. The asserted phrases were
  chosen first, then the prose was **compressed for the size guard**, and the compression re-flowed
  lines so `reads as a working checkout`, `falls back to a marked local park` and `Routing a finding
  to the repo it is about` each straddled a break. The rule as written warns about *editing* a
  guarded paragraph; reflowing one you are drafting is not felt as an edit to a guarded one. The
  mitigation neither guard states: **after any reflow, `grep -n` each asserted phrase and require
  one hit per file.**
  **The detector: an over-long line is evidence a guarded phrase lives there.** In
  `references/CONVENTIONS.md`, `conventions.path` and `Nothing resolving is a stop` share line 103,
  and `Never derive either from the plugin install` and `reads as a working checkout` share line
  106, so deleting either phrase reds both cases and neither pair can fail alone. Those lines run
  104-108 chars where the file otherwise wraps at ~100, *because* holding a phrase on one line is
  what stretched them. A line longer than its own file's wrap width is a cheaper detector than
  re-grepping every phrase.
