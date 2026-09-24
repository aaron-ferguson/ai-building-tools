---
id: "0178"
title: Let a join reach below rank adjacency, and bound the gate by something other than rank
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-09-21
source: user
parent:
blocked_by: []
relates: ["0158", "0174", "0130", "0136", "0154"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - skills/develop/SKILL.md
  - tests/sprint.test.sh
  - tests/batching.test.sh
  - skills/queue/templates/config.yml
  - .claude/backlog/config.yml
  - .claude/backlog/items/0158-make-drive-select-gates-by-rank-not-by-join.md
claimed_by:
claimed_at:
touches:
---

## Problem

**A develop gate stops at the first row that does not join, and that is the wrong bound.** Since
`0158` closed on 2026-09-21, `gate_contiguous` in `skills/queue/templates/next` walks down from the
lead and ends the gate at the first pool row that neither joins nor is one the rank walk would step
over. So a row that shares the lead's file scope but sits below an unrelated row is excluded from the
session that is about to edit exactly its files, and is later worked in a session of its own.

**The user's correction, stated 2026-09-21:**

> Rank adjacency should PRIORITISE rows into a gate, not LIMIT which rows may join one. Where the
> most cost-efficient way to make a high-quality change includes a lower-ranked row that shares the
> file scope, including it is correct. Every ticket has to get done eventually, so pulling one
> forward into a gate it shares files with costs nothing and saves a session floor.

Two halves of the rank rule survive the correction unchanged, and they are what stops this becoming
`gate_from`'s old free-for-all:

- **Rank still decides which gate leads.** The lead is the topmost takeable row, always.
- **Rank still forbids leaving a takeable higher-ranked row unstarted while work proceeds below
  it.** That is a property of the *lead*, not of the gate's membership, which is why admitting a
  lower-ranked joiner does not violate it.

What the correction costs is the bound. Contiguity was doing two jobs at once in `0158` — keeping
selection honest, and keeping a gate small enough to dispatch — and only the first was the rule.
Removed with nothing in its place, `gate_contiguous` degenerates to `gate_from`, and `0158`'s own
evidence is what that produced: from rank-1 `0151` a gate of 45 rows, spanning ranks 1 to 97, held
together by `skills/sprint/SKILL.md`. The user has separately called ten rows joining through one
`SKILL.md` a grouping artefact rather than a theme (`skills/sprint/SKILL.md`, the proposal
section). A 45-row gate is also unrunnable against `config.yml`'s `stage_budget_usd`: at
`develop: 6.05` plus `per_extra_ticket.develop: 4.03` it prices at about USD 183 for one session.

### What this does to 0158

This item **supersedes `0158` FR1, FR2 and FR4** — the contiguity bound on new gates, its
application at every new-gate site, and the two prose sentences asserting it. It **keeps `0158`
FR3**: `verify_batch` recovers a membership already fixed and stays unbounded in rank, and it keeps
`0158`'s underlying finding that selection must not follow a join. Nothing here reopens what counts
as a join (shared `expects:` path or shared `parent:`).

The two rules must not be left standing together. Today four places assert contiguity and cite
`0158`: the comment above `gate_contiguous`, `skills/sprint/SKILL.md`'s proposal section, that
file's *dispatch unit is a gate* paragraph, and `skills/develop/SKILL.md`'s gate definition.

## Functional requirements

- FR1 — The lead of every new develop gate is the topmost takeable row. Unchanged in behaviour, and
  stated as its own requirement because it is the half of the rank rule that survives: no gate is
  dispatched while a takeable row ranked above its lead is unstarted.
- FR2 — A pool row that joins the accumulating gate scope is admissible **however many non-joining
  rows separate it from the lead**, and whatever stage or status those rows are at. Implemented in
  `skills/queue/templates/next` and its byte-identical copy `.claude/backlog/next`. `gate_contiguous`
  and `walk_steps_over` (whose only caller it is) are removed rather than left dead.
- FR3 — `verify_batch` is unaffected: it still recovers membership with `gate_from`, unbounded in
  rank and in size. `gate_admits` stays the single definition of a join, and the new-gate builder
  and `gate_from` differ on the row cap alone.
- FR4 — The prose says the new rule once each, and no surviving sentence asserts the old one:
  `skills/sprint/SKILL.md`'s proposal section and its *dispatch unit is a gate* paragraph,
  `skills/develop/SKILL.md`'s gate definition, and the comment above the gate builder in
  `skills/queue/templates/next`. Each cites this item rather than `0158` for the bound, and `0158`'s
  item file gains a dated line naming which of its FRs this supersedes. The sentence **"A join decides
  batching and never selection"** stays where it stands — it is still true, because selection is the
  lead (FR1) — so `0158`'s guards on that phrase are kept, and only the rank-adjacency sentence after
  it changes.
- FR5 — **A new develop gate is bounded by a row cap, and rank orders admission within it.** One
  pass over the takeable develop pool in rank order from the lead: each row is tested once with
  `gate_admits`, a joiner is admitted (and extends the scope) while the gate holds fewer than
  `gate_max_rows` rows, and the pass stops when it holds that many. So when more rows join than fit,
  the ones nearest the lead in rank get in and the rest wait for a later gate. The cap counts the
  lead. Applied at both sites that form a new gate: the rank walk's `develop` arm and `depth_line`'s
  gate count. (`0158` FR2 also named the `design`-row proposal arm; since `0159` that arm proposes
  the one design row and forms no gate — re-read 2026-09-24 — so there is nothing to bound there.)
- FR6 — `gate_max_rows` lives in `config.yml`, read the way `findings_threshold` is read: a missing
  key or a missing file means the default `5`, held as a named constant in `next`; a value that is
  not a whole number of at least 1 makes `next` exit non-zero and name the key, the file and the
  value on stderr, never falling back to the default. `skills/queue/templates/config.yml` and
  `.claude/backlog/config.yml` both carry `gate_max_rows: 5` with a comment giving the derivation in
  *Notes & decisions* below. `1` is legal and means no batching.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The change leaves exactly one rule standing in the four places that assert a gate's rank bound, and `0158` records that part of it was superseded rather than reversed by drift | FR4's guards in `tests/sprint.test.sh` and `tests/next.test.sh`; the `0158` note is prose only — no artifact yet | `documentation-conventions.md` |
| Dependencies | No new one; the gate builder stays POSIX `sh` in the two `next` copies | `tests/backlog-scripts-installed.test.sh` reds if the copies diverge | `dependency-conventions.md` |
| Explicit over implicit | The cap is a named config key with a named default, not a literal in the loop | AC10 | `coding-conventions.md` → "Explicit Over Implicit" |
| Fail loudly | A malformed `gate_max_rows` stops `next` rather than silently gating on 5 | AC10 | `coding-conventions.md` → "Fail Loudly and Early" |

## Acceptance criteria

All fixtures in `tests/next.test.sh`, driven with `run_next --drive`, every row `develop ready` unless
it says otherwise. Where a case amends a `0158` case, that case is edited in place and its heading
re-pointed to this item — never left asserting the old membership beside a new one.

- [ ] AC1 — Given `0101 a/x.md`, `0102 b/y.md`, `0103 c/z.md`, when `next --drive` runs, then it prints `DISPATCH  develop 0101` — the topmost takeable row leads and nothing joins it (FR1).
- [ ] AC2 — Given `0158` AC1's fixture (`0101 a/x.md`, `0102 b/y.md`, `0103 a/x.md`), when `next --drive` runs, then it prints `DISPATCH  develop 0101 0103` (FR2; `0158` AC1 inverted).
- [ ] AC3 — Given `0158` AC4's fixture (`0102` a `verify ready` row on `c/z.md` between two develop rows on `a/x.md`), when `next --drive` runs, then it prints `DISPATCH  develop 0101 0103` (FR2; `0158` AC4 inverted).
- [ ] AC4 — Given `0158` AC5's fixture, when `next --drive` runs, then the output contains `DEPTH     2 develop gate(s)` (FR2, FR5; `0158` AC5 amended from 3).
- [ ] AC5 — Given `0158` AC2's and AC3's fixtures, when `next --drive` runs, then they still print `DISPATCH  develop 0101 0102` and `DISPATCH  develop 0101 0103` respectively — unchanged, kept as the regression guard that batching survives.
- [ ] AC6 — Given `0158` AC6's fixture (verify rows `0101`, `0103` started this run, develop `0102` between), when `next --drive --started 0101 --started 0103` runs, then it prints `DISPATCH  verify 0101 0103`, unchanged (FR3).
- [ ] AC7 — Given seven rows `0101`–`0107` all on `a/x.md` and no `gate_max_rows` key in `config.yml`, when `next --drive` runs, then it prints `DISPATCH  develop 0101 0102 0103 0104 0105` and the output contains `DEPTH     2 develop gate(s)` (FR5, FR6 default).
- [ ] AC8 — Given `gate_max_rows: 2` and `0101 a/x.md`, `0102 b/y.md`, `0103 a/x.md`, `0104 a/x.md`, when `next --drive` runs, then it prints `DISPATCH  develop 0101 0103` — the joiner nearest the lead in rank is admitted and `0104` waits (FR5).
- [ ] AC9 — Given `gate_max_rows: 2` and `0101 a/x.md`, `0102 a/x.md b/y.md`, `0103 b/y.md`, when `next --drive` runs, then it prints `DISPATCH  develop 0101 0102` — the pass stops at the cap, so a row joining only through a capped-out scope does not get in (FR5).
- [ ] AC10 — Given `gate_max_rows: x`, and separately `gate_max_rows: 0`, when `next --drive` runs, then each exits non-zero with stderr naming `gate_max_rows` and the offending value, and prints no `DISPATCH` line (FR6).
- [ ] AC11 — Given `skills/queue/templates/config.yml` and `.claude/backlog/config.yml`, when grepped, then each has a line matching `^gate_max_rows: 5` (FR6).
- [ ] AC12 — Given the four prose sites in FR4, when grepped, then each carries `gate_max_rows` and `0178` on one line within its gate paragraph or comment, and none still contains `rank-adjacent`, `adjacent in rank` or `RANK CONTIGUITY`; `A join decides batching and never selection` is still present in both skills. Guards in `tests/sprint.test.sh` (skills) and `tests/next.test.sh` (template comment), each phrase matched within one line (FR4).
- [ ] AC13 — Given `.claude/backlog/items/0158-make-drive-select-gates-by-rank-not-by-join.md`, when read, then its *Notes & decisions* has a dated line stating `0178` supersedes its FR1, FR2 and FR4 and keeps FR3 (FR4).
- [ ] AC14 — Given the whole change, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it is green, including `tests/backlog-scripts-installed.test.sh` (the two `next` copies byte-identical), `tests/batching.test.sh` and `tests/citations.test.sh`.

## QA plan

- **Why that level:** `next` is a POSIX `sh` script with fixture-driven cases in `tests/next.test.sh`;
  `config.yml`'s `commands.unit` runs every `tests/*.test.sh`. The prose half is greppable in the same
  suite, so nothing here needs `verify` or `review`.
- **Specific checks:** the FR1–FR3 fixtures in `tests/next.test.sh`; FR4's phrase guards in
  `tests/sprint.test.sh`; `tests/backlog-scripts-installed.test.sh` for the two `next` copies;
  `tests/batching.test.sh`, whose window extraction ends on the blank line after `develop`'s gate
  paragraph and which `0158` recorded as sensitive to that paragraph growing; `tests/citations.test.sh`
  for the re-pointed `0158` citations.
- **Mutation note:** `tests/next.test.sh` is 485 cases and runs past a tool timeout on a loaded host.
  Redirect to a file and poll it; do not pipe (`config.yml`, `commands`).
- **Absence assertions:** FR4 removes phrases two `0158` guards currently require
  (`never selection` in both skills, and the contiguity sentences). Those guards are the ones being
  amended — say so in the build note rather than choosing between this ticket and them.

## Out of scope

- What counts as a join. Shared `expects:` path or shared `parent:`, unchanged.
- `verify_batch`'s membership rule (`0158` FR3, kept).
- Whether a ready `design` row is dispatched rather than escalated (`0159`).
- How a proposal presents a gate to a person — that is `0130`'s, and it reads whatever this produces.
- Re-ranking the queue so that today's contiguous bound batches more rows. Done separately on
  2026-09-21 in the same sweep as this capture, and it is a re-rank rather than a requirement here.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-21 — filed by `queue` on the user's stated correction.** Routed to **`design`, not
  `develop`**, and this is the part worth arguing with. The *rule* is decided and needs no design
  pass: rank selects the lead, a join batches, and a joining row below the first non-joining row is
  admissible. What is not decided is the bound. `0158`'s contiguity was load-bearing twice over, and
  the user's correction names only one of the two loads; removing it outright restores a 45-row,
  USD-183 gate that `0158`, `0130` and the proposal section's grouping-artefact rule all exist
  because of. No acceptance criterion can state a gate's membership until something says how far a
  join may reach, so the design trigger is met exactly as `queue` defines it — a decision blocking
  the writing of criteria, not unfamiliarity.
- **FR1–FR4 are written here rather than left for `design`** because they follow from the user's rule
  alone, and a `design` pass that has to re-derive them pays for the reading twice.
- **This supersedes `0158` FR1/FR2/FR4 and keeps FR3.** Said here rather than left implicit so two
  rules are not standing: `0158`'s finding (selection must not follow a join) is upheld, and its
  *mechanism* (contiguity) is what is being replaced.
- **2026-09-24 — decided by `design`: a row cap, `gate_max_rows: 5`, admitted nearest-in-rank-first
  (FR5, FR6).** The four candidates the question named, and what settled each:
  - **A bound derived from `stage_budget_usd` + `per_extra_ticket` — rejected, because it cannot
    bind.** A gate of n rows is dispatched under a cap of `6.05 + 4.03 × (n − 1)` (config.yml,
    re-read 2026-09-24), so the cap grows with the gate and no gate ever prices above the cap it
    is dispatched under. The USD-183 figure is only alarming against an absolute ceiling, and none
    exists — deriving the bound from price would need a new number anyway, which is the row cap
    with extra steps.
  - **A bound on how much of the gate one shared path may explain — rejected.** It contradicts the
    user's rule, whose criterion *is* the shared file scope: a row sharing `skills/sprint/SKILL.md`
    with the lead is exactly the row the correction says to pull in. The grouping-artefact sentence
    is about *presenting* such a gate to a person, which `--propose`'s `JOIN` lines already do and
    `0130` owns. Once a cap exists, a ten-rows-through-one-file gate cannot form anyway.
  - **A row cap in `config.yml` — taken**, as the only candidate that actually bounds, with
    **nearest-in-rank-first admission** as the prioritisation within it. The one-pass rank-ordered
    walk `gate_from` already does gives that ordering for free, so the prioritisation costs no code.
  - **Why 5.** It is the largest develop batch this repo has a measured saving for (the 2026-08-22
    five-ticket figure in `skills/develop/SKILL.md`), and the next data point it holds — an
    eleven-ticket run — is cited there as needing two guardrails, not as a saving. No run log under
    `runs/` records a larger develop gate (re-checked 2026-09-24: none holds a `DISPATCH  develop`
    line). A session's cost is dominated by context re-read per turn, which grows with every row
    worked, so the saving per extra row shrinks as the gate grows; the cap is set at the edge of
    the evidence rather than past it. It is a config key, not a literal, so 0135's ledger can move
    it without a code change.
  - **Cost accepted:** a joiner past the cap is worked in a later session and pays a second startup
    floor, even though it shares files with the gate before it. That is the price of a gate
    bounded to something a session can actually hold; the user's "costs nothing" holds only up to a
    size the evidence covers.
  - **What would flip it:** a ledger measurement showing develop cost per ticket still falling at
    gates above 5 — raise the key. Nothing in the rule changes.
  - **Criteria accounting (the ticket arrived with FR1–FR4 and draft criteria):** FR1 and FR3
    confirmed unchanged. FR2 extended — the stage/status of intervening rows no longer matters, so
    `walk_steps_over` goes with `gate_contiguous`. FR4 **changed**: the draft said FR4 removes the
    `never selection` phrase, but that sentence is still true under the new rule (selection is the
    lead), so it stays and `0158`'s guards on it stay green; only the adjacency sentence changes.
    FR5 written; FR6 added for the config key. `0158` FR2's third site, the `design`-row proposal
    arm, no longer forms a gate since `0159` (re-read 2026-09-24), so FR5 names two sites, not three.
    The draft ACs are carried through as AC1–AC6 and AC12; AC7–AC11, AC13, AC14 are new.
