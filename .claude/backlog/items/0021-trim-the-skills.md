---
id: "0021"
title: Hold the skills to the conventions' own context-rent rule
type: chore
next: verify
status: done
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0009"
blocked_by: ["0023", "0025"]
relates: ["0020"]
expects:
  - skills/develop/SKILL.md    # 0025 put it over the ceiling after the re-spec was written
  - skills/prototype/SKILL.md
  - skills/queue/SKILL.md
  - tests/skill-size.test.sh
  - references/NOTION.md       # queue's opt-in Notion block moved here
  - README.md
claimed_by:
claimed_at:
touches:
closed: 2026-08-23
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

- [x] AC1 — Given `wc -c skills/*/SKILL.md`, when each count is compared to 20,190, then every
      file is at or under it, or appears in the FR6 exemption list carrying the evidence FR6
      requires. No percentage and no baseline: the number is absolute.
- [x] AC2 — Given the `##` and `###` headings captured from all six files immediately before this
      pass, when the same headings are grepped for afterwards, then every one is still present.
      Diffed against the captured list, never counted — a count stays green if one rule is dropped
      and another duplicated.
- [x] AC3 — Given this ticket's notes, when read, then before and after byte counts for all six
      files are recorded for this pass, alongside the previous pass's table.
- [x] AC4 — Given `tests/skill-size.test.sh`, when a copy of a compliant `SKILL.md` is padded past
      the ceiling, then the test fails and names that file; when the tree is unmodified, it passes.
      A guard only ever seen passing is indistinguishable from one wired to nothing.
- [x] AC5 — Given `README.md`, when its test list is read, then `tests/skill-size.test.sh` appears
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

## Outcome (2026-08-23) — AC1 met via one ceiling and two recorded exemptions

**Three files were over the ceiling, not two.** The re-spec named `prototype` and `queue`; `develop` went
over between the re-spec and this pass when **0025** landed its batching paragraph, consuming exactly the
545-byte margin the re-spec had flagged as "a standing cost of the ceiling, not a defect". It went over by
572. That prediction landing inside one day is the strongest available argument for FR1 being absolute:
a percentage target would have moved with it and hidden the breach.

### FR3 — before and after, this pass, all six files

Appended to the two tables above rather than replacing them. The "0021 re-spec" column is the re-spec's
own baseline; "this pass, before" is the working tree when this session claimed the ticket, and the two
differ only where a sibling ticket landed in between.

| File | pre-effort | first pass | 0021 re-spec | this pass, before | after | vs ceiling |
|---|---|---|---|---|---|---|
| `design` | 7,118 | 8,797 | 8,797 | 8,797 | 8,797 | under by 11,393 |
| `develop` | 25,136 | 19,171 | 19,645 | 20,762 | **20,081** | under by 109 |
| `prototype` | 31,297 | 26,262 | 26,262 | 26,262 | **23,394** | **exempt at floor** |
| `queue` | 22,862 | 22,787 | 24,159 | 24,159 | **21,789** | **exempt at floor** |
| `retro` | 16,113 | 14,831 | 14,831 | 14,831 | 14,831 | under by 5,359 |
| `verify` | 10,316 | 11,946 | 14,415 | 15,659 | 15,659 | under by 4,531 |
| **total** | **112,842** | **103,794** | **108,109** | **110,470** | **104,551** | — |

A compliant cycle is now **104,551 bytes / ~25,893 tokens** of skill instructions, against the problem
statement's 44,090 tokens for five skills. `develop` alone went 25,136 → 20,081 across the effort.

### FR6 — two exemptions, with the evidence

Both files had a full FR2-limited pass in this session on top of the first pass's cuts. What was removed
was duplication, not rules: in `queue`, restatements of `CONCURRENCY.md` and of `testing-conventions.md`'s
test-level pyramid, plus the routing section's justification; in `prototype`, a whole section that restated
rules stated above it (see AC2 below) and the design-system rules stated twice.

**`skills/queue/SKILL.md` — floor 21,789 bytes** (over the ceiling by 1,599)

| Section | bytes | what it is |
|---|---|---|
| frontmatter + header | 2,201 | trigger description; the 0017 session header; the CONCURRENCY and CONVENTIONS pointers |
| Storage layout | 1,558 | the file inventory a scaffold must produce, and why the queue holds only the table |
| Step 0 — locate or create | 1,100 | scaffold rules; the fail-closed conventions resolution |
| Step 1 — decide the operation | 920 | the operation table, incl. the `blocked`/`waiting` derivation rules |
| Step 2 — add an item | 7,129 | the specification contract: ID claim, evidence, FRs, NFR elimination, `qa_level`, `size`, `expects:`, ACs, and the 0018 routing rules |
| Step 3 — insert at the right rank | 4,779 | the five tiers, five ordered tie-breakers, four tier overrides, four never-rank-by rules, the insert procedure |
| Step 4 — rerank | 502 | move-row mechanics; the in-progress prohibition |
| Step 5 — surface parked work | 1,886 | the FINDINGS sweep, its three numbered steps, the two-sweeper rule |
| Step 6 — commit the backlog | 925 | the pathspec rule and the other window's staged work |
| Step 7 — park what surprised you | 642 | mandated verbatim by 0012 |
| Step 8 — report | 147 | |

Every section is a rule list. The two largest are the specification contract and the ranking method, and
both are read on the operation this skill exists for — an add. Neither is conditional, so neither can move
to a reference without moving the cost rather than cutting it, which this ticket puts out of scope.

**`skills/prototype/SKILL.md` — floor 23,394 bytes** (over the ceiling by 3,204)

| Section | bytes | what it is |
|---|---|---|
| frontmatter + header | 1,378 | trigger description (the longest of the six); the 0017 session header |
| Configuration | 1,171 | the capability/needs/if-absent table and the never-guess-a-key rule |
| Invocation | 420 | the four invocation forms |
| The three fidelity levels | 1,036 | what each level is and what it is right for |
| Design system | 1,209 | the MCP tools, the AA contrast rule, the unavailable-MCP fallback |
| Steps 1–4 | 2,800 | input, level choice, the shared flow/wireframe blueprint, the revise loop |
| Step 5 — build the artifact | 11,690 | the three level-specific build procedures and the field-reference contract |
| Steps 6–7 | 2,049 | the Jira comment format; the Figma export |
| Step 8 — park what surprised you | 639 | mandated verbatim by 0012 |
| Error Handling / Handoff | 1,002 | the failure messages; the `/capture` handoff shape |

**Step 5 is half the file and is the honest reason for the exemption.** It holds three build procedures —
diagram, clickable HTML, Angular — and a run uses exactly one. That makes it the clearest candidate in
either file for a conditionally-read reference, and it is *not* clearly permitted: for a level-2 run the
reference is opened the same cycle, so the cost moves rather than falls. Deciding whether a
level-2-only run should pay for level 1 and level 3 is a judgement about where level detail lives, so it
is parked as a finding for `queue` rather than settled here.

### AC2 — 73 of 74 headings intact; one removed section, with the rules it held

Captured before the pass and diffed after, never counted. The single removal is
**`skills/prototype/SKILL.md` — `## Key Behaviors`** (2,027 bytes), deleted because all seven of its
bullets restated rules stated earlier in the same file. FR2 outranks FR1 *and* outranks AC2's proxy: the
proxy exists to catch a dropped rule, and no rule was dropped. Where each one is now stated:

| Key Behaviors bullet | now stated in |
|---|---|
| ticket or ad-hoc, scale depth to source, generate from AC, state assumptions | Step 1; Step 3's closing paragraph |
| built on the design system at every level; real tokens; AA via `check-contrast` | `## Design system`; the Configuration table; Level 2's token bullet |
| ticket posting is optional, never automatic | Step 6's opening ("Ask before posting rather than posting automatically") |
| one directory per prototype; escalation adds files; one field reference across 2 and 3 | Step 5 *Where everything lives* (escalation clause folded in); *Developer documentation* |
| level 2 ships the three-state switcher and Save/Load by default | Level 2's `DATA_STATES` bullet ("not optional polish"); its Save/Load bullet |
| drawer collapsed by default, single topbar toggle, no hover strip, no Notes & Questions, real nav never in the drawer, template does not backfill | Level 2's two drawer paragraphs (both removed experiments folded in); *Real app navigation is not admin tooling*; the copy-forward clause folded into Level 2's opening |
| no decorative emoji, monochrome functional glyphs excepted | Level 2's emoji bullet |

### AC4 — the guard proves it can fail

`tests/skill-size.test.sh` carries its own negative cases rather than leaving the padded-fixture check as
a manual step: it pads a copy of the smallest compliant skill file past the ceiling and asserts the
offender is *named with its overage*, then asserts a clean copy reports nothing. Three further cases drive
the exemption path against a fixture — over the ceiling but under its floor (passes), over its floor
(fails), and back under the ceiling (fails, so a stale exemption cannot sit there unnoticed). Measured with
`wc -c`, never a decoded character count.

### Notes & decisions from this pass

- **The productive lens was duplication, not concision.** Consistent with the first pass's finding that
  word-shaving moved 1,100 bytes and naming a category moved 11,000. Every cut over 300 bytes here was one
  rule stated twice: `prototype`'s `Key Behaviors` against its own steps, its design-system rules against
  Level 2 and Level 3, `queue`'s restatement of `CONCURRENCY.md` and of the testing pyramid. Prose written
  tighter yielded almost nothing.
- **A skill that says "this skill states no standards of its own" was restating two convention files.**
  `queue` carried `testing-conventions.md`'s level definitions inline while declaring it cites rather than
  restates, and summarised `CONCURRENCY.md` in three clauses one line after telling the reader to go read
  it. Same defect this ticket's problem statement names: the skills enforce a rule on every project and
  did not apply it to themselves.
- **The ceiling caught a live breach on its first run, which is the argument for FR5.** `develop` was
  compliant at re-spec and over by 572 when this session started, because 0025 landed in between. Recorded
  only in a closed ticket, nothing would have said so.
- **An exemption floor set at the current byte count is deliberately brittle.** Any later mandated addition
  to `prototype` or `queue` reds the guard and forces the floor to be re-recorded. That is the intent: it
  makes growth in an already-over file a decision rather than a drift.
- **The AC1 pass line names the exempt files rather than reporting a clean sweep.** A guard that prints
  "every skill file within the ceiling" while two sit above it is the silent-cap failure the conventions
  warn about; the message now lists them.
- **`README.md`'s test list was wrong in two ways and both were invisible.** It claimed the shipped scripts
  were "the only thing with a test" — already false when `batching.test.sh` landed under 0025 — and listed
  two of the four existing guards, so a session following it ran neither `next.test.sh` nor
  `batching.test.sh`. Fixed in the same commit per the documentation rule that a change contradicting a
  documented rule updates it.

### Verified (2026-08-23, `verify`, token `e0c1`) — PASS

Baseline for the diff was **`b6d83d5`**, the parent of the first trim commit; its six byte counts
match this ticket's "this pass, before" column exactly, which is what makes the recorded table
auditable rather than asserted.

| AC | How it was checked | Result |
|---|---|---|
| AC1 | `wc -c skills/*/SKILL.md` against the fixed 20,190; `develop` 20,081 (under by 109), `prototype` 23,394 and `queue` 21,789 at their recorded floors | pass |
| AC2 | 74 `##`/`###` headings captured from `b6d83d5`, diffed (not counted) against HEAD — sole removal `prototype: ## Key Behaviors`; all seven of its bullets located in their mapped destinations | pass |
| AC3 | this pass's before/after table present and appended below the two earlier tables; every cell reproduced from git | pass |
| AC4 | proven able to fail **against the real tree**, not only its fixtures — three mutations, each restored by the mutated path alone | pass |
| AC5 | `README.md` lists all five guards, and the stale "only thing with a test" claim is gone | pass |

**The mutations, because the guard's own fixtures could not establish this.** Padding
`skills/design/SKILL.md` past the ceiling → `over the 20190 ceiling by 607`; `queue` +1 byte →
`over its exempt floor of 21789`; `prototype` truncated to 20,000 → `under the 20190 ceiling —
remove its stale exemption`. Both exemption directions and the plain ceiling all red on the real
tree.

**FR6's evidence recomputes exactly.** Every section byte count in both exemption tables was
reproduced by splitting each file on its `##` boundaries: `queue`'s eleven rows match individually
and sum to 21,789; `prototype`'s grouped rows reconcile too, including Step 5's 11,690 as 10,205
plus the 1,485-byte `## Screen:` template nested inside it.

**FR2 held where it was most at risk.** `queue`'s cut restatements of `testing-conventions.md`
(*Test Levels*) and `CONCURRENCY.md` were confirmed present in those files, with the mapping queue
adds — where each level lands — kept. The scaffold's "copy the templates, `chmod +x` the three
scripts" survived, consolidated into Step 0. The Notion block's move to `references/NOTION.md`
satisfies the out-of-scope carve-out: it is read only under `notion.enabled: true`, so the cost
falls rather than moves.

Full suite green — 118 assertions across five guards. `batching.test.sh` matters here: its grep
assertions target `develop`, which was re-wrapped, and the reflow hazard this ticket's own notes
record did not recur.

**Two things a reader should know, neither of them an AC failure.**

- **Committed is not live.** The trim is not in the installed plugin: `0.9.2` was cut at `b83ffb6`,
  before the trims, so its `develop`/`prototype`/`queue` are still the pre-trim copies and a session
  today loads 110,470 bytes, not 104,551. The repo is the authority and the repo is correct; the
  version bump is what makes it real.
- **The guard's fixtures are coupled to the real tree** and can red a compliant one. Parked as a
  finding with the measured threshold; it does not affect any AC today.
