---
id: "0231"
title: Drive one outcome ticket across slice sessions unattended
type: feature
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0071", "0149", "0220", "0226", "0212", "0137", "0128", "0204"]
expects: [skills/sprint/SKILL.md, skills/sprint/outcome.schema.json, tools/validate-json-schema.py, skills/design/SKILL.md, skills/develop/SKILL.md, skills/verify/SKILL.md, skills/queue/SKILL.md, skills/queue/templates/item.md, skills/queue/templates/next, skills/queue/templates/handoff, skills/queue/templates/claim, skills/queue/templates/close, skills/queue/templates/config.yml, references/CONCURRENCY.md, tests/next.test.sh, tests/handoff.test.sh, tests/batching.test.sh, tests/close.test.sh, tests/sprint-ledger.test.sh, tools/sprint-ledger.sh, README.md, CHANGELOG.md]
ac_digest: AC1=d8fb5dee AC2=315e6e9d AC3=7c1fb14c AC4=a8520dae AC5=d6c01921 AC6=414ddd39 AC7=6caf69d4 AC8=1295a15c AC9=1dab5f85 AC10=865d23ca AC11=63334335 AC12=570dc5d8 AC13=ccc5aeaa AC14=6cd4e5b9 AC15=aca1f25c AC16=e3a5e129 AC17=06b1bf5e
claimed_by: "33d4"
claimed_at: 2026-11-18T16:08:13Z
touches: [tests/sprint-ledger.test.sh, tools/sprint-ledger.sh (transient mutation only, E8/E9, restored in-turn)]
slice: S5
---

## Problem

**The convention changed under the suite.** `ai-building-conventions` `a325686` (2026-11-17) replaced
*"if it can't be finished in a few days, it isn't a slice yet"* with: **size a unit of work by its
outcome and the context its parts share, not by calendar time — one outcome is one ticket even across
many sessions, its slices worked in order with a handoff; split only where a part has an outcome of
its own** (`product-definition-conventions.md` → "Slice Vertically and Thinly", and the core). Aaron,
2026-11-17: *"AI is much better at handling large projects and understanding context than it used to
be… merge them into as few tickets as would still be effective and efficient at achieving the long
term outcome, rather than splitting into little parts."* The first consumer to apply it, Traitors and
Allies, went from 47 rows to 5; its 0060 has eight requirement groups (S1–S8) and will take many
sessions.

**The goal of `/sprint`** (Aaron, 2026-11-17): *"spin up an agent that will orchestrate whole project
or long sessions so that my work progresses without me needing to be present at my computer the
entire time."* Big tickets make that more valuable — someone otherwise restarts every session — but
the suite assumes a ticket fits in one stage session, in five places:

1. **No partial-progress outcome.** `skills/sprint/outcome.schema.json`'s verdicts are `queued,
   re-specified, parked, decided, handed-to-queue, prototyped, built, red, blocked, closed, pass,
   fail, advisory`. Nothing means "slice 3 of 8 done, tree green, continue". `handoff`'s usage is
   `<id> <token> <stage>` between stages; develop cannot hand to develop.
2. **So a multi-session ticket can only end by cap kill**, which sprint Step 7 rightly treats as the
   worst case — claim held, tree dirty, lock possibly taken — escalating and starting nothing further.
3. **`stage_budget_usd` is one cap per stage session, derived from per-session cost history on small
   tickets** (sprint Step 7), so it cannot be met by a ticket sized to an outcome.
4. **The dispatch unit is a gate of rows** sharing `expects:` scope (Step 2, `gate_max_rows`). With a
   handful of outcome tickets there is nothing to batch; the saving moves to giving each *slice* a
   fresh session, which bounds context growth instead of amortising startup.
5. **Verify runs once per ticket**, so an eight-slice ticket meets its independent check only after
   all eight — the longest possible distance between a defect and its detection.

And two gaps in capture, both seen in the 2026-11-17 Traitors and Allies session:

6. **`queue` mints first.** Step 2 always claims a new id; nothing asks *which existing outcome does
   this serve?* — the question the new convention makes the default. There is no merge operation;
   the consolidation invented one (withdraw each merged ticket with a pointer, quote reported
   evidence verbatim in the absorbing ticket, burn ids).
7. **`queue` must never amend a claimed ticket** (Step 1, *Amend*). With long-lived tickets the one a
   new finding belongs to will often be claimed, so amend-first collides with that rule.

And one in decisions: architecture and security choices are a person's (`coding-conventions.md` →
*What Not to Delegate to AI*), so an unattended run reaching a `design` row escalates and stops
(Step 8), even though most of a decision's cost — spikes, options, a recommendation — needs no person.

## Functional requirements

Amended 2026-11-18 by `queue` at Aaron's direction (*Notes & decisions*, second amendment), over the
design pass's set. Absorbs 0212, 0220, 0226 and 0071, each withdrawn with a pointer to the FR named.

**Slices and legs**

- FR1 — **Slices live in the item.** `templates/item.md` gains a `## Progress` section of ordered
  lines `- [ ] S<n> — <what lands> — discharges AC<a>, AC<b>` (or `— discharges none`, or
  `— unspecified` for a slice not yet sharp enough to give ACs), and a frontmatter scalar `slice:`
  naming the last slice of the most recent leg. Every AC is named by exactly one slice, the one where
  it first becomes true. Ticked slices are history; `develop` may re-split or re-order unticked
  slices with a dated note and never changes an AC. A ticket with no `## Progress` is single-leg and
  behaves exactly as today. `queue` Step 2 tells authors to state the outcome first and write one
  outcome ticket with ordered slices, each about one develop session's work, folding adjacent small
  slices that touch the same files into one, citing `product-definition-conventions.md` → "Slice
  Vertically and Thinly" rather than restating it.
- FR2 — **Fog is an unspecified slice, not a separate mechanism** (absorbs 0071). A slice marked
  `unspecified` routes the ticket to `design` when it is the next slice; `design` gives it ACs and
  re-stamps `ac_digest`. Work ruled out stays in *Out of scope*, so in-scope-but-unsharp and ruled-out
  are visibly distinct. `parent:` projects stay for parts with an outcome of their own.
- FR3 — **A leg is one or more consecutive slices.** `develop` commits each slice as it lands and
  writes a dated *Notes & decisions* line naming it and its SHA, so a killed leg loses at most the
  unfinished slice. It continues into the next slice only when that slice touches files it already
  has open **and** its leg so far is short of the break-even `MEASUREMENT.md` measured for carrying
  a session's climb into more work (*Would the re-entry after a FAIL be cheaper…*). Otherwise it
  ends the leg. It never meters spend, because no session reads its running cost
  (`references/TRACKER.md`).
- FR4 — **`handoff --slice S<n>`** ends a leg whose slices run from the one after the last ticked
  slice up to S<n>, in the same locked commit as the hand-off:
  - develop → develop: ticks every slice in the leg and sets `slice: S<n>`; **refuses if any slice in
    the leg discharges an AC**, naming `verify`;
  - develop → verify: sets `slice: S<n>` and ticks nothing;
  - verify → develop with `--slice`: the leg passed, so it ticks every slice in it. Without `--slice` it
    is the fail bounce, unchanged, and nothing is ticked;
  - refuses an unknown slice, and a leg containing an `unspecified` slice, naming `design`.
  With `--slice`, it **refuses when any path in the item's `touches:` is dirty**, naming the paths and
  changing nothing. Not the whole tree, which is shared (`CONCURRENCY.md`, *The working tree is
  shared too*).
- FR5 — **Verify once per leg, never once per slice.** A leg that discharges at least one AC is
  verified by one fresh `verify` session against that leg's ACs literally plus the whole suite. A leg
  discharging none is not verified. The leg holding the last slice is the closing verify and checks
  every AC. Mid-ticket verifies tick no AC; `close` ticks ACs once. This is the same rule as a gate's
  (`--drive` names one verify session for what was developed together), so FR11 applies to both.
- FR6 — **`close` on a sliced ticket** refuses while any slice before the closing leg is unticked,
  and on success ticks the closing leg's slices in the same commit as the ACs.
- FR7 — **A `progressed` verdict.** `outcome.schema.json` gains `progressed` and an optional
  per-ticket `slice` object `{ "done": "S<n>", "next": "S<n>" }` (pattern `^S[0-9]+$`), required when
  the verdict is `progressed`. `develop` returns it at a leg end with slices remaining; `verify` returns
  `pass` with `next: develop` for a leg pass. `tools/validate-json-schema.py` has no `if`/`then`, so it
  gains the support (or an equivalent it already has), and whether `claude -p --json-schema` accepts the
  construct is checked against the installed CLI.

**Routing**

- FR8 — **`next --drive` routes legs.** With an item carrying `## Progress`:
  `--completed develop:<id>` at `develop / ready` with `slice:` ticked and slices left →
  `DISPATCH develop <id>`, in place of the same-stage escalation; at `verify / ready` mid-slices →
  `DISPATCH verify <id>`; `--completed verify:<id>` at `develop / ready` with `slice:` ticked →
  `DISPATCH develop <id>`, unticked → the existing bounce escalation; at `design / ready` (an
  unspecified slice is next) → the existing design routing. A ticket in `--started` with slices left is
  finished before the rank walk opens a different develop row. No `## Progress` → unchanged.
- FR9 — **Waiting rows do not halt a run that has other work** (absorbs 0226). `--drive` steps over
  an in-scope `waiting` row with a `NOTE` while other in-scope work is takeable, exiting `4` only when
  nothing in scope is takeable. An out-of-scope `waiting` or `next: queue` row is stepped over with a
  `NOTE`, as an out-of-scope design row already is; and once the scope is finished, exit `5` is not
  masked by an escalation only out-of-scope rows raise. Implemented in `templates/next`, and
  `sprint` Step 6 says so.
- FR10 — **A held design file makes develop wait** (absorbs 0212). `--drive` exits `6` instead of
  dispatching a develop gate or leg any of whose predicted files intersect an in-progress design
  row's `touches:` or `expects:`; a `--completed develop:<id>` that left the row unchanged while such
  a design row still holds an intersecting file re-enters that wait, not the loop escalation.
- FR11 — **One verify session per develop gate or leg** (absorbs 0220). After `--completed
  develop:<lead>`, `--drive` names every row that gate developed in one `DISPATCH verify` line, never
  one session each. Before building, read the verify branch and run-20261025T215324Z's log to learn
  whether the resume lost the gate's membership or the branch never batched, and record which.

**Sprint scope, and what reaches the person**

- FR12 — **A sprint is sized by an envelope, not a count.** The proposal replaces the three-ticket
  floor and five-ticket target with a **budget (USD) and an end time** the person confirms, offering as
  defaults the estimated cost and time to finish the top outcome ticket, or to its next verified leg
  if that does not fit. The run takes work in rank order within the confirmed scope. Before every
  dispatch it continues only when the remaining budget and time cover that stage's estimate, and
  otherwise ends at the boundary it is on, which is always a clean one. The proposal refuses an
  envelope that cannot hold one develop leg plus its verify. The person may also name tickets beyond
  the top one, and continuing past the confirmed scope happens only when they said so. All of it is
  recorded in `scope_confirmed`.
- FR13 — **The envelope check is a script.** `tools/sprint-ledger.sh envelope` reads the run log's
  `scope_confirmed` budget and deadline, the outcome costs and timestamps so far, and the ledger's
  per-stage estimate for the named next stage (the stage cap where there is no prior, labelled as
  such), and prints `CONTINUE` or `STOP <reason>` with distinct exit codes.
- FR14 — **Every ask of the person is a decision brief.** A `## Waiting on` section, and every
  escalation the sprint reports, has these subsections: `### Outcome` (what the work is driving
  toward), `### Where it stands` (done, blocked, what keeps running meanwhile), `### What needs you`
  (the challenge, and why it cannot be decided without you), `### Options` (at least two
  `#### Option` entries, each with pros, cons and what would have to be true for it to win),
  `### Recommendation` (which and why), `### What to do` (the exact steps or reply that unblocks it,
  and the command that resumes), `### If no answer` (what waits and what does not). `templates/item.md`
  carries the shape. `handoff <id> <token> <stage> waiting` refuses a section missing any subsection
  or holding fewer than two options, naming what is missing. The notification is one line naming the
  ticket, the decision and where the brief is, and never replaces it.
- FR15 — **Design prepares a person's decision and never makes it.** `design` Step 3 gains the
  unattended case: where the answer turns on taste, or is an architecture or security choice
  (`coding-conventions.md` → *What Not to Delegate to AI*), and no one can be asked, the pass runs
  its spikes, writes the FR14 brief, and releases with `./handoff <id> <token> design waiting`
  (verdict `blocked`). It never records the decision. `sprint` Step 8 says the same, and Step 2
  sends the FR14 notification on every outcome that leaves a row `waiting`.

**Capture**

- FR16 — **`queue` amend-first.** Before minting an id, `queue` searches open tickets' outcomes and,
  where one is served, amends it (re-checking size, ACs, QA plan, out-of-scope and the slice plan,
  re-stamping `ac_digest`). It mints only for work with an outcome of its own, and records which test
  it applied in *Notes & decisions*.
- FR17 — **`queue` Merge.** Step 1's table gains Merge: absorbing tickets into one outcome ticket
  withdraws each per *Withdrawing a ticket* with a pointer to the FR that now carries it, quotes
  user-reported evidence verbatim in the absorbing ticket, re-points every `blocked_by:` naming a
  withdrawn id, and burns the ids. This amendment is the procedure's worked example.
- FR18 — **A claimed ticket is still never amended; the wait is bounded instead.** Step 1's
  prohibition stands. Every leg releases at a slice boundary (FR4), so `queue` waits for the release,
  claims the row, amends and hands it back with `./handoff <id> <token> develop`. `CONCURRENCY.md`,
  *A stage writes only the ticket it holds*, says why: one writer per item file, and a wait of at most
  one leg.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | Unattended runs still never push, bump, install or restart without per-action approval (sprint Step 8 unchanged), and a design pass never records a person's decision (FR15) | prose: no script owns either rule and this repo adds no prose guards (`CLAUDE.md`, *Tests*), so `verify` reads both (AC17) | `security-conventions.md` |
| Compatibility | A ticket with no `## Progress`, and every installed backlog, behaves as before; existing `waiting` rows are not refused retroactively, since only a new `handoff … waiting` checks the brief | the existing `tests/*.test.sh` cases pass unchanged (AC16) | `api-conventions.md` |
| Documentation | `CHANGELOG.md` `## Unreleased` entry, one per behaviour a session will see differently; README skill descriptions updated where sprint, develop, verify, design and queue change | prose only — no artifact yet: `verify` reads the entry and the README (AC17), and `tools/release` refuses a bump over an empty `## Unreleased` | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture item with three slices where S1 discharges none, when `handoff <id> <token> develop --slice S1` runs, then the item shows S1 ticked, `slice: S1`, `claimed_by:` empty, `next: develop`, `status: ready` (`tests/handoff.test.sh`).
- [ ] AC2 — Given the same fixture with a path from the item's `touches:` modified, when `handoff --slice S1` runs, then it exits non-zero naming that path, and the item, the row and `git log` are unchanged; and given a dirty path not in `touches:`, then it succeeds (`tests/handoff.test.sh`).
- [ ] AC3 — Given a fixture where S1 discharges none and S2 discharges an AC, when `handoff develop --slice S2` runs, then it refuses naming `verify`; when `handoff verify --slice S2` runs, then `slice: S2` and neither slice is ticked; when verify then runs `handoff develop --slice S2`, then S1 and S2 are both ticked; and when verify instead hands back without `--slice`, then neither is ticked (`tests/handoff.test.sh`).
- [ ] AC4 — Given a fixture whose leg contains a slice marked `unspecified`, when `handoff --slice` covers it, then it refuses naming `design` and changes nothing (`tests/handoff.test.sh`).
- [ ] AC5 — Given a sliced fixture whose closing leg is the one `slice:` names and an earlier slice is unticked, when `close` runs, then it refuses naming the unticked slice; and with every earlier slice ticked, then it closes and ticks the closing leg's slices in the close commit (`tests/close.test.sh`).
- [ ] AC6 — Given `outcome.schema.json` and `tools/validate-json-schema.py`, then a `progressed` outcome with `slice: {done: S1, next: S2}` validates, one with `progressed` and no `slice.next` fails, and an existing `built` outcome with no `slice` still validates (a new `tests/outcome-schema.test.sh`).
- [ ] AC7 — Given the AC1 and AC3 fixtures, when `next --drive` runs with `--completed develop:<id>` after the develop → develop hand-off, then it prints `DISPATCH  develop <id>`; after the develop → verify hand-off, `DISPATCH  verify <id>` naming that ticket alone; with `--completed verify:<id>` after the pass, `DISPATCH  develop <id>`; and after the fail, exit 4 with the bounce escalation (`tests/next.test.sh`).
- [ ] AC8 — Given ticket A with S1 and S2 ticked and S3 unticked at `develop / ready`, and ticket B at `develop / ready` ranked above it, when `next --drive --completed develop:A --scope A --scope B` runs, then it dispatches `develop A`, not B (`tests/next.test.sh`).
- [ ] AC9 — Given three rows developed in one gate, all at `verify / ready`, all in `--started`, when `--drive --completed develop:<lead>` runs, then one `DISPATCH  verify` line names all three; red if any is named in a separate session (`tests/next.test.sh`).
- [ ] AC10 — Given an in-scope `design / waiting` row with a complete brief and an in-scope `develop / ready` row, when `--drive` runs, then it prints a `NOTE` naming the waiting row, dispatches the develop row and exits 0; and with the waiting row as the only in-scope work, then it exits 4 (`tests/next.test.sh`).
- [ ] AC11 — Given an out-of-scope `waiting` row and an out-of-scope `next: queue` row ranked above a finished scope, with `FINDINGS.md` past `findings_threshold`, when `--drive` runs, then both are stepped over with a `NOTE` and it exits 5 (`tests/next.test.sh`).
- [ ] AC12 — Given design row A in-progress with file F in `touches:` and develop row B expecting F, when `--drive` runs, then it exits 6 naming A and prints no `DISPATCH` for B; with A's files disjoint, then it dispatches B; and with B unchanged after `--completed develop:B` while A still holds F, then it exits 6, not 4 (`tests/next.test.sh`).
- [ ] AC13 — Given a fixture item whose `## Waiting on` lacks `### If no answer`, or has one `#### Option`, when `handoff <id> <token> design waiting` runs, then it refuses naming the missing part and changes nothing; and given every subsection with two options, then it succeeds (`tests/handoff.test.sh`).
- [ ] AC14 — Given a fixture run log whose `scope_confirmed` carries a budget and deadline, when `tools/sprint-ledger.sh envelope` runs with the outcomes so far leaving less than the next stage's estimate, then it prints `STOP` naming budget or time and exits non-zero; with enough left, `CONTINUE` and exit 0; and with no ledger prior, it uses the stage cap and says so (`tests/sprint-ledger.test.sh`).
- [ ] AC15 — Given `tests/batching.test.sh`, then its gate cases pass unchanged, so gate batching still holds for unsliced rows (`tests/batching.test.sh`).
- [ ] AC16 — Given the full suite `for t in tests/*.test.sh; do "$t" || exit 1; done`, then it exits 0 with no existing case edited to pass.
- [ ] AC17 — Given the changed skill files, when `verify` reads them, then: `templates/item.md` documents `## Progress`, `slice:`, `unspecified` and the FR14 brief; `develop` carries FR3's leg rule citing `MEASUREMENT.md`; `verify` carries FR5's per-leg cadence; `design` Step 3 carries the unattended prepare-and-wait case and the clause that it never records the decision; `sprint` carries the envelope proposal (FR12), the FR14 notification, and a Step 8 still listing push, bump, install and restart as per-action approvals; `queue` carries Merge, amend-first and the bounded wait (FR16–FR18); `CONCURRENCY.md` carries FR18's reasoning. Read, not grepped (`CLAUDE.md`, *Tests*).

## Progress

This ticket's own slice plan. The tooling for it lands in S1–S3, so until then the legs are driven by
hand.

- [x] S1 — item shape, `handoff --slice` legs, the dirty-`touches:` refusal and `close` on sliced tickets — discharges AC1, AC2, AC3, AC4, AC5
- [x] S2 — `progressed` in the outcome schema and validator support for the conditional — discharges AC6
- [x] S3 — `--drive` leg routing, started-first, and one verify session per gate or leg (0220) — discharges AC7, AC8, AC9, AC15
- [x] S4 — `--drive` waiting and out-of-scope rows, exit precedence (0226), and the held-design-file wait (0212) — discharges AC10, AC11, AC12
- [ ] S5 — the decision brief enforced by `handoff`, and the `envelope` check — discharges AC13, AC14
- [ ] S6 — skill, template and reference prose for develop, verify, design, sprint, queue and CONCURRENCY; README; CHANGELOG — discharges AC16, AC17

## QA plan

- **Why that level:** `unit`. The mechanical changes land in `handoff`, `next`, `close`, the schema,
  its validator and `sprint-ledger.sh`, which `tests/*.test.sh` exercise with fixtures. AC17 is a
  literal read, since this repo puts no guard on prose.
- **Specific checks:** the full `tests/*.test.sh` run; each fixture AC seen red before its change; a
  dry `/sprint` against a scratch backlog holding one four-slice ticket (S1 none, S2 an AC, S3
  `unspecified`, S4 an AC) with a small envelope, to watch a leg, a verify, a design detour, a waiting
  brief and an envelope stop.

## Out of scope

- Running two develop sessions at once — 0137.
- Cheaper stage sessions in themselves (suite-check dedup, model tiering) — 0149, which keeps its
  own outcome and measurement.
- Re-charting the live `parent:` projects (0001, 0002, 0009, 0036) as sliced tickets.
- A develop session metering its own spend mid-leg (FR3: no mechanism exists).
- The release of these changes — `tools/release`, on Aaron's say-so.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

### Leg S1 — verify (0a93), 2026-11-18: PASS, not closing

Leg verify per FR5: AC1–AC5 only (the ACs S1 discharges), plus the whole suite. No AC is ticked —
`close` ticks them once, at the closing leg. NFR rows are not discharged by this leg (AC16/AC17 sit on
S6); the Compatibility row's check, the existing suite unchanged and green, held at this SHA.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`; `unit` is the same
files fail-fast). Subject: `0918f6c` (S1 = `fb7255a`, `56cebad`). Copy executed: the repo's
`skills/queue/templates/{handoff,close}` (the harness copies them); `.tickets/{handoff,close}` byte-identical.
`./next --ac-digest 0231 --check` → `0231: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2 and after the last check, so the dirty set is empty and
the advisory intersection is empty.

Suite: 44 files, 44 tallies reading `0 failed`, no `ABORTED`. `tests/handoff.test.sh` `208 passed, 0 failed`;
`tests/close.test.sh` `322 passed, 0 failed`; `tests/declared-copies.test.sh` `23 passed, 0 failed`.
(The three baseline reds in the build notes — `release`, `sprint`, `item-nfr-red` — are green at this SHA.)

**Clause table, every mutation re-run by this pass** in a detached worktree at `0918f6c`, applied to
`skills/queue/templates/{handoff,close}`, diff confirmed non-empty, restored by path, control green after
(handoff `208 passed, 0 failed`, close `322 passed, 0 failed`, worktree clean):

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | Given: three slices, S1 discharges none; `handoff develop --slice S1` | fixture `0901`, `tests/handoff.test.sh` | — |
| AC1 | S1 ticked | develop→develop `TICK_LEG=""` | red, 2 (`S1 is ticked`, `and the leg is ticked`) |
| AC1 | `slice: S1` | `slice:` line kept, not rewritten | red, 16 |
| AC1 | `claimed_by:` empty, `next: develop`, `status: ready` | `claimed_by:` kept | red, 58 |
| AC2 | dirty `touches:` path → non-zero, item/row/log unchanged | dirty check returns empty | red, 5 (`exits non-zero`, `byte-identical`, `git log is unchanged`, …) |
| AC2 | naming that path | dirty-path listing deleted | red, 1 (`names the dirty touches: path`) |
| AC2 | dirty path not in `touches:` → succeeds | dirty check over the whole tree | red, 16 |
| AC3 | develop→develop `--slice S2` refuses naming `verify` | AC refusal off | red, 8 |
| AC3 | develop→verify: `slice: S2`, neither ticked | develop→verify sets `TICK_LEG=1` | red, 3 |
| AC3 | verify→develop `--slice S2` ticks S1 and S2 | verify-pass `TICK_LEG=""` | red, 2 |
| AC3 | verify→develop without `--slice` ticks neither | tick every slice when `--slice` absent | red, 2 (fixture `0904`) |
| AC4 | `unspecified` in the leg → refuses naming `design`, unchanged | unspecified refusal off | red, 6 (both destinations) |
| AC5 | earlier slice unticked → `close` refuses naming it | gap refusal off (`tests/close.test.sh`) | red, 4 |
| AC5 | all earlier ticked → closes, ticks the closing leg | closing-leg tick deleted | red, 2 |
| AC5 | in the close commit | not mutated; asserted by `rev-list --count HEAD` = 2 | guarded by assertion, unmutated |

Step 4, newly reachable: `--slice` is a new path into `handoff`. It is accepted only on
develop→develop, develop→verify and verify→develop at status `ready`, and a verify pass can tick only
the leg named by `slice:` (fixture `0905`). It adds no route to a destructive action.
Evidence set: `skills/queue/templates/handoff`, `skills/queue/templates/close`, `.tickets/handoff`,
`.tickets/close`, `tests/handoff.test.sh`, `tests/close.test.sh`, `tests/declared-copies.test.sh`, `tests/*.test.sh`.

### Leg S2 — verify (8ffc), 2026-11-18: PASS, not closing

Leg verify per FR5: AC6 only (the AC S2 discharges), plus the whole suite. No AC is ticked — `close`
ticks them once, at the closing leg. NFR rows are not discharged by this leg (AC16/AC17 sit on S6); the
Compatibility row's check, the existing suite unchanged and green (`tests/sprint.test.sh`'s schema
cases included), held at this SHA.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`; `unit` is the same
files fail-fast). Subject: `e4439ad` (S2 = `6bfec33`, `a3ae3e6`). Copy executed: the repo's
`skills/sprint/outcome.schema.json` and `tools/validate-json-schema.py`, which the test reads by repo
path; the installed 0.9.48 schema has no `progressed`, which is expected until a release.
`./next --ac-digest 0231 --check` → `0231: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2 and after the last check, so the dirty set is empty and
the advisory intersection is empty.

Suite: 45 files, every one exit 0, every tally `0 failed`, none aborted. `tests/outcome-schema.test.sh`
`12 passed, 0 failed`; `tests/sprint.test.sh` `389 passed, 0 failed, 0 skipped`;
`tests/citations.test.sh` `52 passed, 0 failed`.

**Clause table, every mutation re-run by this pass** in a detached worktree at `e4439ad`, applied to
`skills/sprint/outcome.schema.json` or `tools/validate-json-schema.py`, diff confirmed non-empty,
restored by path; control after `12 passed, 0 failed`, worktree clean:

| AC6 clause | Mutation | Result (`tests/outcome-schema.test.sh`) |
|---|---|---|
| Given `outcome.schema.json` and `tools/validate-json-schema.py` | — (the test reads both by repo path; every row below mutates one of them) | — |
| a `progressed` outcome with `slice: {done: S1, next: S2}` validates | M1 `progressed` removed from the verdict enum | red, 1 |
| one with `progressed` and no `slice.next` fails | M2 schema `if`/`then` deleted | red, 2 |
| (same) | M3 `then`'s `slice.required` reduced to `done` | red, 1 |
| (same) | M4 validator ignores `if` | red, 4 |
| (same, slice absent altogether) | M7 `then.required` emptied | red, 1 |
| an existing `built` outcome with no `slice` still validates | M5 `slice` made required on every ticket | red, 1 |
| (same) | M6 validator always applies `then` | red, 5 |

Step 4, newly reachable: a schema enum value and an optional object; no route, permission or
destructive action is added.
Evidence set: `skills/sprint/outcome.schema.json`, `tools/validate-json-schema.py`,
`tests/outcome-schema.test.sh`, `tests/sprint.test.sh`, `tests/*.test.sh`.

### Leg S3 — verify (2a45), 2026-11-18: PASS, not closing

Leg verify per FR5: AC7, AC8, AC9 and AC15 only (the ACs S3 discharges), plus the whole suite. No AC
is ticked; `close` ticks them once, at the closing leg. NFR rows are not discharged by this leg
(AC16/AC17 sit on S6). The Compatibility row's check, the existing suite unchanged and green, held at
this SHA: S3 added 193 lines to `tests/next.test.sh` and deleted none.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`; `unit` is the same
files fail-fast), each file's exit captured. Subject: `d4be431` (claim over `34eb735`; S3 = `61ceb12`,
`d29fa86`). Copy executed: the repo's `skills/queue/templates/next`, which `tests/next.test.sh` copies
into each fixture (`NEXT_SRC`). `.tickets/next` is byte-identical (`cmp`).
`./next --ac-digest 0231 --check` → `0231: ac_digest matches`.
Tree: `git status --porcelain` was empty at Step 2 and again after the last check, so the dirty set is
empty and the advisory intersection is empty.

Suite: 45 files, every one `EXIT 0`, no `ABORTED`, no tally with a non-zero failure count.
`tests/next.test.sh` `600 passed, 0 failed`; `tests/batching.test.sh` `39 passed, 0 failed`;
`tests/declared-copies.test.sh` `declared-copies: 23 passed, 0 failed`.

**Clause table. This pass re-ran every mutation itself** in a detached worktree at `d4be431`, against
a trimmed harness: `tests/next.test.sh` lines 1–412 (helpers), its later `assert_eq` and
`dispatch_line` definitions, and the whole 0231 section. Every mutation was applied to
`skills/queue/templates/next`, with the diff confirmed non-empty, then restored by path. The control
before and after was `25 passed, 0 failed`, and the worktree was removed clean.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC7 | Given the AC1 and AC3 fixtures (S1 none; S2 an AC; three slices) | fixtures `0911` in the 0231 section | — |
| AC7 | `--completed develop:<id>` after develop → develop → `DISPATCH  develop <id>` | M1 leg arm `&& false` | red, 7 (incl. `dispatches that ticket's next leg`) |
| AC7 | after develop → verify, `DISPATCH  verify <id>` | M2 `completed_batch` → `verify_batch` | AC7 case stays green (the sliced lead is still alone); see the next row |
| AC7 | naming that ticket alone | M3 sliced-lead early return deleted | red, 1 (`verifies the leg's ticket alone`) |
| AC7 | `--completed verify:<id>` after the pass → `DISPATCH  develop <id>` | M1 | red (`dispatches the next leg`, `a pass is not a bounce`) |
| AC7 | after the fail, exit 4 with the bounce escalation | M4 `bounced` never printed | red, 3 (`exits 4`, `names the bounce`, `dispatches nothing`) |
| AC8 | Given A (S1, S2 ticked, S3 not) at develop/ready, B ranked above | fixtures `0921`/`0920` | — |
| AC8 | `--completed develop:A --scope A --scope B` → dispatches `develop A` | M1 | red (`exits 0`, `dispatches the sliced ticket`) |
| AC8 | not B | M9 leg arm keeps its NOTE but does not dispatch, and `started_leg` is off, so the run falls to the rank walk | red: `got: DISPATCH  develop 0920` |
| AC9 | Given three rows developed in one gate, all at verify/ready, all in `--started` | fixtures `0931`–`0933`, which share no `expects:` and no parent. The lead joins `STARTED` via `--completed` (`next` line 1836) | — |
| AC9 | one `DISPATCH  verify` line names all three | M2 `verify_batch` re-derivation | red, 2 (`names all three in one verify session`) |
| AC9 | red if any is named in a separate session | M8 `completed_batch` pool = the lead alone | red, 2 |
| AC9 (FR11) | a sliced leg is left out of the gate's batch | M5 sliced-member skip deleted | red, 1 |
| AC15 | `tests/batching.test.sh` gate cases pass unchanged | the file is unedited since baseline `6829ae8` (`git diff --stat` empty) and runs green. Liveness: rewording the verify `SKILL.md` phrase it asserts gave `38 passed, 1 failed`, and restored gave `39 passed, 0 failed` | green, and can red |

Beyond the ACs, also re-run: M6 `handed_off_from` always true → red, 3 (the same-stage loop case).
M7 `started_leg` off → red, 1 (`the started leg goes before rank 1`).

**AC15, read literally:** `tests/batching.test.sh` guards the batching prose in `skills/develop` and
`skills/verify`, which S3 does not touch, so no change to `next` can redden it. Unsliced gate
*behaviour* is held by `tests/next.test.sh`'s existing gate cases (0132 and the others). They passed
unchanged, with no line of that file deleted.

Step 4, newly reachable: `--drive` can now dispatch `develop` on a ticket that is not newly ranked.
That is limited to a clean leg whose item's last commit handed it out of the completed stage
(`handed_off_from`, M6), so a session that dies before claiming escalates and does not loop. It adds
no route to push, release or any destructive action. Known and deferred to S4 by the build notes: a
leg dispatch does not run `gate_wait` (FR10/AC12). Also from the build notes: `completed_batch` takes
every started verify row, so a row skipped earlier for a blocker could widen a later gate's batch.
That only happens among rows this run itself developed.
Evidence set: `skills/queue/templates/next`, `.tickets/next`, `tests/next.test.sh`,
`tests/batching.test.sh`, `skills/verify/SKILL.md` (liveness mutation only),
`tests/declared-copies.test.sh`, `tests/*.test.sh`.

### Leg S4 — verify (7c3e), 2026-11-18: PASS, not closing

Leg verify per FR5: AC10, AC11 and AC12 only (the ACs S4 discharges), plus the whole suite. No AC
is ticked; `close` ticks them once, at the closing leg. NFR rows are not discharged by this leg
(AC16/AC17 sit on S6). The Compatibility row's check still held at this SHA: S4 added 182 lines to
`tests/next.test.sh` and deleted none, and the whole suite is green.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`; `unit` is the same
files fail-fast), each file's exit captured. Subject: `04885aa` (claim over `b0cd540`; S4 = `20677fa`,
`53596c4`). Copy executed: the repo's `skills/queue/templates/next`, which `tests/next.test.sh` copies
into each fixture (`NEXT_SRC`). `.tickets/next` is byte-identical (`cmp`).
`./next --ac-digest 0231 --check` → `0231: ac_digest matches`.
Tree: `git status --porcelain` was empty at Step 2 and again after the last check, so the dirty set is
empty and the advisory intersection is empty.

Suite: 45 files, all 45 `EXIT 0`, and no tally with a non-zero failure count. (The one `ABORTED`
string in the run's output is `tests/abort-announce.test.sh` asserting the announcement. That file
tallied `321 passed, 0 failed` and exited 0.) `tests/next.test.sh` `635 passed, 0 failed`;
`tests/batching.test.sh` `39 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`.

**Clause table. This pass ran every mutation itself** in a detached worktree at `04885aa`. The trimmed
harness was `tests/next.test.sh` lines 1–410 (helpers), plus its later `assert_eq`, `dispatch_line`,
`eight_findings`, `first_line`, `add_sliced` and `fixture_handed_off_from`, plus the whole S4 section.
Each mutation was applied to `skills/queue/templates/next`. A script required each pattern to occur
exactly once and the `git diff --stat` to be non-empty, then restored the file by path. The control
was `35 passed, 0 failed` before and after. The worktree was clean apart from the harness and was
removed.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC10 | Given an in-scope `design / waiting` row with a complete brief and an in-scope `develop / ready` row | fixtures `0941` (design/waiting, FR14 brief via `waiting_brief`) and `0942`, both `--scope` | — |
| AC10 | prints a `NOTE` naming the waiting row | M12 the in-scope step-over `printf` → `:` | red, 1 (`a NOTE names the waiting row`) |
| AC10 | dispatches the develop row, exits 0 | M2 `scope_live` → `false` (in-scope waiting always escalates) | red, 6 (`exits 0`, `the develop row is dispatched`, `nothing escalates`, and the FR9 completion case) |
| AC10 | with the waiting row the only in-scope work, exits 4 | M3 `scope_live` → `true` (always step over) | red, 5 (`exits 4`: got exit 0 and `DISPATCH  develop 0942`) |
| AC10 (FR9) | stepped over, then nothing dispatched → exit 4 on the waiting row | M4 `WAITED` escalation off; M3+M4 together | red, 3; red, 8 |
| FR9 | `--completed` leaving the row waiting does not halt a scope | M9 completion arm escalates as before | red, 2 |
| AC11 | Given an out-of-scope `waiting` row and an out-of-scope `next: queue` row ranked above a finished scope, with `FINDINGS.md` past `findings_threshold` | fixtures `0951` (waiting), `0952` (queue), scope `0953` in `DONE.md`, threshold 8 with `eight_findings` | — |
| AC11 | both stepped over: the waiting one | M1 out-of-scope waiting not stepped over | red, 6 (incl. `exits 5`) |
| AC11 | both stepped over: the queue one | M5 out-of-scope queue not stepped over | red, 4 (incl. `exits 5`) |
| AC11 | with a `NOTE` (each row) | M13 waiting NOTE silent; M14 queue NOTE silent | red, 1 each |
| AC11 | exits 5 | M1, M5 (an escalation masks the gate) | red (`exits 5 — the findings gate`) |
| AC12 | Given design A in-progress with F in `touches:`, develop B expecting F → exit 6 naming A, no `DISPATCH` for B | M6 `gate_wait` reads `expects:` only; M10 `wait_on_design` never waits; M15 rank-walk wait off | red, 10; red, 10; red, 4 |
| AC12 | with A's files disjoint, dispatches B | M11 `gate_wait` ignores shared paths (always waits) | red, 3 (`with disjoint files it exits 0`, `dispatches the develop row`, `with the file released it is the loop again`) |
| AC12 | B unchanged after `--completed develop:B` while A still holds F → exit 6, not 4 | M7 same-stage wait off | red, 3 (`exits 6, not 4`, `naming the design`, `not the loop escalation`) |
| FR10 | a sliced ticket's leg waits too | M8 `dispatch_leg` wait off | red, 3 |

Plural clause: AC11's "both" uses two rows that differ in the value under test (waiting against
queue), and each row's step-over and NOTE has its own mutation that reddens alone (M1/M5, M13/M14).
Every clause reddened. The developer's table (M1–M11) was re-run, not trusted, and it agrees. M12–M15
are this pass's own additions.

Step 4, newly reachable: an out-of-scope `waiting` or `next: queue` row no longer stops the walk, so
the walk can now reach and dispatch develop rows ranked below it. M3's red output shows such a row
(`DISPATCH  develop 0942` under `--scope 0941`). That is pre-existing scope semantics: `--scope`
governs findings-gate deferral and design ordering, not develop dispatch (`next --help`). It is the
step-over FR9 asks for, "as an out-of-scope design row already is". FR12's "continuing past the
confirmed scope happens only when they said so" is not enforced by `next` at this SHA. FR12 is S5/S6
work, and the closing verify should check where it lands. S4 adds no route to push, release or any
destructive action. `waiting_on` now prints the brief's `### What needs you` line, covered by
"carrying its question" (developer's M10).
Evidence set: `skills/queue/templates/next`, `.tickets/next`, `tests/next.test.sh`,
`tests/declared-copies.test.sh`, `tests/*.test.sh`.

### Leg S5 — verify (b5c7), 2026-11-18: FAIL — AC14's "naming budget or time" is unguarded

Leg verify per FR5: AC13 and AC14 only (the ACs S5 discharges), plus the whole suite. No AC is ticked.

Conventions: ../ai-building-conventions
Command: `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`), each file's exit
captured. Subject: `9c3b097` (claim over `638a76a`; S5 = `439d05c`, `e2d7d63`, `d244651`). Copy executed:
the repo's `skills/queue/templates/handoff` (`tests/handoff.test.sh` copies it, `HANDOFF_SRC`;
`.tickets/handoff` byte-identical by `cmp`) and `tools/sprint-ledger.sh` (`TOOL`).
`./next --ac-digest 0231 --check` → `0231: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2 and after the last check; dirty set empty, advisory
intersection empty.

Suite: 45 files, all `EXIT 0`. `tests/handoff.test.sh` `250 passed, 0 failed`;
`tests/sprint-ledger.test.sh` `229 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`.

**Clause table. This pass ran every mutation itself** in a detached worktree at `9c3b097`, by a script
that required each pattern exactly once, confirmed `git diff --stat` non-empty, ran the owning test
file and restored by path. Control before and after: handoff `250 passed, 0 failed`, sprint-ledger
`229 passed, 0 failed`; worktree clean, then removed.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC13 | Given `## Waiting on` lacks `### If no answer`, `handoff design waiting` | fixture `0911` (`brief_text`), destination `design` | — |
| AC13 | refuses (lacking `### If no answer`) | H2 drop it from the wanted list | red, 8 |
| AC13 | refuses (one `#### Option`) | H3 threshold `< 1` | red, 6 |
| AC13 | naming the missing part | H5 `missing <heading>` → `missing a part`; H6 options-count line dropped | red, 9; red, 2 |
| AC13 | and changes nothing | H4 refusal does not exit | red, 25 |
| AC13 | the check at all / on a `design` hand-off | H1 check off; H8 `design` destination exempted | red, 38; red, 34 |
| AC13 | every subsection with two options → succeeds | H7 success needs three options | red, 4 |
| AC14 | Given a run log whose `scope_confirmed` carries budget and deadline | fixtures `env_log` (budget, deadline, one 40-min develop outcome), `--now` pinned | — |
| AC14 | outcomes so far leave less than the estimate → `STOP` | E1 budget test off; E2 time test off; E4 spend not summed; E11 run-log estimate ignored | red, 7; red, 2; red, 7; red, 1 |
| AC14 | exits non-zero | E3 STOP exits 0 | red, 5 |
| AC14 | **naming budget** | E8 STOP reason `budget:` → `over:` | **green, 229/0 — gap** |
| AC14 | **naming time** | E9 STOP reason `time: %d min left` → `over: %d min left` | **green, 229/0 — gap** |
| AC14 | enough left → `CONTINUE` | E5 `CONTINUE` → `GO` | red, 1 |
| AC14 | and exit 0 | E10 CONTINUE exits 3 | red, 2 |
| AC14 | no ledger prior → uses the stage cap | E6 estimate 0 instead of the cap | red, 4 |
| AC14 | and says so | E7 `no prior: the stage cap` label dropped | red, 1 |

**The gap, with output.** Under E8+E9 the observable output moved and the suite stayed green:
`STOP  budget: 3.00 left, develop needs an estimated 7.00` became `STOP  over: 3.00 left, …`, and
`STOP  time: 20 min left, …` became `STOP  over: 20 min left, …`, both still exit 3. The STOP line no
longer names budget or time, which is AC14's outcome. The assertions `names budget` and `names time`
match the whole output, and the always-printed `ENVELOPE  budget …` / `ENVELOPE  time …` header lines
satisfy them whichever reason fired, an adjacent measurement. The time case's `hasnt … budget` is
already scoped to `^STOP`, and the past-deadline case's `has … time` is too; these two are not.

AC13 passes: every clause reddened.

Step 4, newly reachable: `handoff … waiting` gains a refusal (narrows, never widens, what is
reachable); `envelope` is a read-only new mode. No route to push, release or a destructive action.
Evidence set: `skills/queue/templates/handoff`, `.tickets/handoff`, `tools/sprint-ledger.sh`,
`tests/handoff.test.sh`, `tests/sprint-ledger.test.sh`, `tests/declared-copies.test.sh`, `tests/*.test.sh`.

## Notes & decisions

- 2026-11-18 — captured at Aaron's direction from the Traitors and Allies session of 2026-11-17, which
  consolidated that backlog to five outcome tickets and asked whether `/sprint` still fits. Routed to
  `design`: Q1–Q5 are open and change the FRs' shapes. Ranked row 1: it is Aaron's stated goal for the
  suite (unattended progress), every project now writes tickets in the shape this fixes, and until it
  lands a sprint over a consolidated backlog can only end each leg by cap kill.
- 2026-11-18 — **amend-first applied to this capture** (FR7 eating its own cooking): 0071 (decision map
  for oversized work), 0149 (sprint efficiency), 0220 (one verify session per develop gate), 0226 and
  0212 (`--drive` routing) all touch this outcome. They are left as rows for now and named in
  `relates:`; the `design` pass decides which are absorbed here — likely 0220 and 0212 (their gate
  premise changes), possibly 0071 — and withdraws them with pointers per FR8.
- 2026-11-18 — absorbs the FINDINGS entry of 2026-11-17 *"queue's guidance pushes toward many small
  tickets…"* (FR7, FR8).
- 2026-11-18 — **design pass (e4ad): Q1–Q5 settled, all on fact; nothing needed a person.** Sources
  re-read this date: `skills/sprint/SKILL.md` (proposal, Step 2, Steps 7–8), `outcome.schema.json`,
  `skills/develop/SKILL.md` Step 5, `skills/queue/SKILL.md` Step 1, `templates/handoff`, `templates/next`'s
  `--drive` routing block, `tools/validate-json-schema.py`. Three observed results changed the draft:
  (a) `handoff` already accepts `develop` as a destination from `develop` — the stage check is a
  plain enum — so the blocker for develop → develop is `--drive`'s *same-stage* escalation
  ("still at next: develop after a completed develop"), not the script; (b) `--drive` escalates
  exit 4 on any `waiting` row reached after a stage, and on `verify` → `develop` as a bounce,
  so a slice pass and a slice fail are indistinguishable to it today without a marker on disk;
  (c) `tools/validate-json-schema.py` is a hand-written subset with no `if`/`then`.
  - **Q1 → `## Progress` slice lines plus a `slice:` scalar (FR1).** Confirms the draft and adds
    `slice:`: `--drive` needs to tell "verify passed S2" from "verify failed S2", and both leave
    slices unticked unless the ticked state of the *named* slice carries it. Every AC sits on exactly
    one slice, so a slice verify has a defined contract. Rejected: one child ticket per slice — the
    convention this ticket implements says one outcome is one ticket; a frontmatter-only counter —
    loses what each slice lands, which the next leg needs to read.
  - **Q2 → verify each slice that discharges an AC; the last slice's verify is the closing verify
    (FR2, FR3, FR6).** Changes the draft: no separate "final verify" session, because the last slice
    carries the outcome ACs and the closing verify checks every AC literally anyway — one floor
    saved per ticket. AC-less slices go develop → develop with no verify, and `handoff` enforces that
    split (refusing develop → develop on an AC-carrying slice). Mid-ticket verifies tick no AC;
    `close` ticks ACs once, so an earlier slice's pass cannot survive a later regression. Rejected:
    final verify only — the defect-to-detection distance that problem 5 names. Accepted cost: one
    verify floor per AC-carrying slice.
  - **Q3 → the claimed-ticket prohibition stays; the wait is bounded (FR12).** Changes the draft:
    the `## Pending amendments` fallback is **rejected** on two facts. It puts a second writer in a
    held item file, and the folding-in would be `develop` changing criteria `queue` authored, which
    is exactly what `ac_digest` exists to refuse (0195). One slice per leg (Q4/FR4) bounds the wait
    to a single leg, so `queue` waits, claims on release, amends and hands back.
  - **Q4 → one slice per leg; scope counted in legs (FR4, FR9).** Changes the draft's "when to end a
    leg is develop's call (slice boundary or budget)": no session can read its running spend — cost
    is harvested from transcripts afterwards (`references/TRACKER.md`) — so a develop leg cannot
    budget itself, and the one-slice leg is the bound that exists. Slices are sized to one session
    at authoring time; a slice that overruns is a cap kill (Step 7), and the fix is re-splitting
    the plan, not raising the cap. The proposal's 3/≈5 floor (a person's correction, 2026-09-25) is
    kept and recounted in legs, because its stated reason is about sessions, not tickets: it
    defaults to the top outcome ticket and fills only to reach the floor. Rejected: one outcome
    ticket only — breaks that floor whenever the ticket has fewer than three slices left.
    Accepted cost: one develop floor per slice, in exchange for context that resets every slice.
  - **Q5 → design prepares, leaves `waiting`, and `--drive` steps over it (FR7, FR8).** Confirms the
    draft, and extends it to the out-of-scope rows 0226 asks about. Prior art decides that half: an
    out-of-scope design row is already stepped over with a NOTE, and treating a `waiting` or
    `next: queue` row the person excluded from `--scope` differently has no stated reason. Exit 5
    then wins once the scope is done, since no in-scope escalation is left to mask it.
  - **Confirmed / changed / added against the draft criteria:** AC1 confirmed, with `--slice` made
    explicit. AC2 changed — dirty means a path in `touches:`, not the whole tree, which is shared.
    AC3 changed from schema-only to the slice verify round trip; the schema check moved to AC4, now
    with a regression case and the validator named. AC4 → AC5, unchanged in substance. AC5 (queue
    prose) → AC11, a literal read: the draft's "checked by the test that owns queue's table" has no
    such test, and `CLAUDE.md` bars a new prose guard. AC6 → AC7, adding the only-waiting-row exit 4
    case. Added: AC6 (close on a sliced ticket), AC8 (0226), AC9 (gates still batch), AC10
    (unsliced tickets unchanged).
  - **Draft FR10 discharged here:** 0220 and 0212 re-checked against the new dispatch unit. Both
    keep their own outcomes, because gates still exist for unsliced rows; neither is absorbed (*Out of
    scope*). 0071 keeps its row — fog before ticketing is a different outcome — and its
    "ticket vs project" premise is now weaker under the convention. 0149 is unaffected.
  - **0226 is absorbed (FR7, AC8) and is owed a `queue` Merge.** This pass holds only 0231, so it does
    not withdraw 0226 itself; a `queue` session withdraws it with a pointer to FR7 — FR11's procedure,
    applied by hand before FR11 lands.
  - `qa_level: unit` and `close_by: verify` re-read against AC1–AC11: both hold (fixture scripts,
    plus one literal read). `size: l` holds.
- 2026-11-18 — **second amendment (`queue`, at Aaron's direction): the design pass's Q2 and Q4 were
  too rigid, sprint sizing moves to an envelope, every ask of the person becomes a brief, and four
  rows are merged in.** Aaron, verbatim: *"are you sure that a hard rule of one dev session per slice
  also meets our goal of optimizing token efficiency while maintaining the same outcome
  effectiveness? It sounds like we are going to pay the tax of starting a new session a lot when
  there might be opportunities to develop more than one slice at once profitably … I have the same
  question about running a verify session after each dev session. Don't let me sacrifice
  effectiveness since that is the main goal"*; on sizing, *"The principle is take on enough work to
  make meaningful progress while not taking on so much that it causes problems. We do still have to
  worry about budgets and real world time"*; on escalations, *"enough context is given into the
  outcome we are driving toward, the current situation, the challenges we are trying to address,
  more than one potential option, and the pros and cons of each. Sometimes I also need instructions
  on what I need to do."*
  - **Legs (FR3), and the evidence on both sides.** `MEASUREMENT.md` prices a fresh session at the
    floor's cache write (−$0.36) plus 4–7 orientation turns (−$0.50 to −$0.87), about **$0.86–1.23**,
    and carrying a 75k-token climb through a further ~38 turns at **+$1.44**. So for a slice of normal
    size a fresh session is usually *cheaper* as well as fresher, which is the pushback on the
    "startup tax" worry. Aaron's point holds below the break-even: a short follow-on slice reusing open
    files is cheaper in the same session. Hence the rule is not one slice per leg but continuing only
    on shared files and a short leg so far, with each slice committed as it lands so a kill costs at
    most one slice. Rejected: a fixed slices-per-leg number, since nothing measured supports one.
  - **Verify per leg (FR5).** The ledger (run-20261027T185815Z) shows verify cost per ticket at
    **$1.04–1.07 batched against $1.02–1.13 unbatched**: verify spend tracks the ACs checked, not the
    session count, so an extra verify costs roughly a floor plus orientation. On the effectiveness side,
    a bounce costs a mean **$1.60** re-entry (`MEASUREMENT.md`) plus rework on every slice built on the
    defect. So verify follows the leg, one session per leg that discharges an AC, and grouping small
    slices into a leg (FR1, FR3) is also how verifies get fewer. Rejected: final verify only (the
    distance problem 5 names); verify by slices judged "risky" (a judgement that invites skipping).
    Weak evidence, flagged: n = 4 sessions.
  - **Envelope, not a count (FR12, FR13).** The 3/≈5 rule's own reason was not paying a supervisor
    floor for too little work. A budget and an end time state that directly, and they also bound what
    a count cannot: spend and wall-clock. The floor of meaningful progress becomes "fits one leg
    plus its verify". The check is a script because it protects money (`CLAUDE.md`, *Tests*: a rule
    that must hold exactly goes in a script). The default figures are Aaron's to set per run; none is
    invented here.
  - **Decision brief (FR14).** The headings map one-to-one to the asks above. It is enforced on new
    `waiting` hand-offs, which is a structure check in a script rather than a prose grep, and is not
    applied to existing rows.
  - **Merged (FR17's procedure, applied by hand):** 0226 → FR9 (it was already absorbed by the design
    pass); 0212 → FR10, the same `--drive` guards, and a sliced run makes the stand-down case
    commoner; 0220 → FR11, which states FR5's verify rule for gates; 0071 → FR2, because under the new
    convention fog is an outcome ticket's unsharp later slices, and its "destination first" is FR1's
    outcome-first. 0071's question (extend `parent:` or a new skill) is answered **neither**. Their
    ACs carried over as AC9, AC11 and AC12. No `blocked_by:` named any of them.
    **Kept as rows:** 0149, cheaper sessions, which has its own outcome and measurement, is separable
    from slicing, and is the natural next ticket; and 0137, parallel develop, already declined on the
    token fact.
  - **Re-checked:** `size: l` holds (now six slices). `qa_level: unit` holds, since every fixture AC
    runs under `tests/`. `close_by: verify` holds, since AC17 is a read. `next: develop` holds: Aaron
    made the remaining choices and nothing is open. A `## Progress` section is added so this ticket
    follows its own convention.
- 2026-11-18 — **develop (7295), leg S1: built, handed to verify with `--slice S1`.** Commits
  `fb7255a` (handoff `--slice`, sliced `close`, `item.md` `## Progress` and `slice:`, tests) and
  `56cebad` (quote-scan fix). S1 alone is the leg: S2 touches `outcome.schema.json` and the validator,
  no file S1 had open, so FR3 ends the leg here.
  - **Definitions this build had to pick, all inside FR4/FR6's wording.** A leg is the slices after
    the *last ticked* slice (by position) up to `--slice S<n>`. `--slice` is accepted only on
    develop → develop, develop → verify and verify → develop, with status `ready`; a ticket with no
    `## Progress` refuses it. On verify → develop, S<n> must equal `slice:` (a pass ticks the leg it
    was handed; asserted by `0905`). A slice's kind is read from its last ` — ` field only; a last
    field that is neither `discharges none` nor `unspecified` reads as `ac`, so a misparse refuses
    develop → develop rather than skipping a verify. `close` defines its closing leg the same way
    and additionally refuses when `slice:` is not the last slice (a mid-ticket verify must not
    close), naming the slices still to come — FR5's "the leg holding the last slice is the closing
    verify", made mechanical. Shared parser: declared copy `progress-slices` in `handoff` and `close`.
  - **Dirty check** is `git status --porcelain -- <touches: entries>` from the repo root; `touches:
    "*"` checks the whole tree. It runs only with `--slice`.
  - **NFR Documentation cell corrected:** it cited `tests/changelog-entry-guards.test.sh`, which
    checks that tests do not *read* the changelog and cannot red on a missing entry; it was also
    the baseline `tests/item-nfr-red.test.sh` red (bare file reference, red at `a118a42` before the
    claim). Now names what actually checks it. Criteria untouched; `ac_digest` unaffected.
  - **Clause table (S1's ACs) — every row run, as a mutation of committed code restored by
    `git checkout` in the same call:**

    | AC clause | Assertion (`tests/…`) | Mutation that reds it (run) |
    |---|---|---|
    | AC1 S1 ticked, `slice: S1`, claim cleared, `develop / ready` | handoff `0231 AC1` | M4-class: no tick → red (2) |
    | AC2 dirty `touches:` path → non-zero naming it, item/row/log unchanged | handoff `0231 AC2` | M2 dirty refusal off → 5 red |
    | AC2 dirty path not in `touches:` → succeeds | handoff `0231 AC2`, second half | — (positive case; reds if the check covers the whole tree) |
    | AC3 develop → develop over an AC slice refuses naming verify | handoff `0231 AC3` | M1 → 8 red |
    | AC3 develop → verify sets `slice: S2`, ticks nothing | handoff `0231 AC3` | M4/M5 rows |
    | AC3 verify → develop `--slice S2` ticks S1, S2 | handoff `0231 AC3` | M4 verify-pass ticks nothing → 2 red |
    | AC3 verify → develop without `--slice` ticks neither | handoff `0231 AC3` (`0904`) | — (unchanged path; reds if ticking ignores `--slice`) |
    | AC4 unspecified in leg → refuses naming design, unchanged | handoff `0231 AC4` | M3 → 6 red |
    | AC5 earlier slice unticked → close refuses naming it | close `0231 AC5` | M6 → 4 red |
    | AC5 all earlier ticked → closes, ticks closing leg in the close commit | close `0231 AC5` | M8 no leg tick → 2 red |
    | FR6 (beyond AC5) `slice:` not last → refuses | close `0231 FR6` | M7 → 3 red |
    | declared copy kept identical | `tests/declared-copies.test.sh` | M9 drift in close's copy → 1 red |

    Every new case was also red before the implementation (27 in handoff, 9 in close).
  - **Whole suite at `56cebad`:** green except three files, each red at `a118a42` before the claim too,
    and none touched by this leg: `tests/release.test.sh` aborts at *0084 NFR git* (`remote HEAD
    refers to nonexistent ref`, the container's git); `tests/sprint.test.sh` 4 failures, AC25's
    lock-age check calling `stat -f` (BSD form; Linux prints filesystem stats), and 0165's two cases
    that follow from it; `tests/item-nfr-red.test.sh` the NFR cell above, fixed in this commit.
  - **Not done in this leg, for the next ones:** `.tickets/claim` does not seed `touches:` from a
    flow-style `expects: [a, b]` (it reads block lists only), and needs `xxd` to mint a token —
    both parked in `FINDINGS-HELD.md`, neither in this ticket's scope.
- 2026-11-18 — **verify (0a93), leg S1: PASS.** AC1–AC5 checked literally, and each clause was
  mutated red by this pass (*QA evidence*, Leg S1). The full suite is green at `0918f6c`. Handed back with
  `--slice S1` so S1 ticks; no AC ticked. Next leg: S2.
- 2026-11-18 — **develop (c41b), leg S2: built, handed to verify with `--slice S2`.** Commits
  `6bfec33` (schema `progressed` + `slice`, validator `if`/`then`/`else`, new
  `tests/outcome-schema.test.sh`) and `a3ae3e6` (README guard-block line, which
  `tests/citations.test.sh` 0046 requires for every new suite). S2 alone is the leg: it discharges
  AC6, so FR4 refuses develop → develop, and S3 opens `templates/next` and `tests/next.test.sh`,
  neither of which S2 had open (FR3).
  - **Shape chosen inside FR7's wording.** `slice` is optional on every verdict and requires only
    `done`; the `if` (`verdict` ∈ [`progressed`]) / `then` makes `slice` and `slice.next` required.
    So a leg handed to verify may report `slice: {done: S2}` under `built`, and a closing leg needs
    no `next`. The `if` uses `enum` rather than `const`, which the validator already had (FR7: "or an
    equivalent it already has"). The validator's `if` contributes no errors of its own; it only picks
    `then` or `else`.
  - **CLI probe (FR7), run against the installed `claude` 2.1.327 with this schema file, stdin from
    `/dev/null`:** (b) a `progressed` outcome with `slice {done: S1, next: S2}` came back
    schema-valid, exit 0; (c) told to omit `slice.next`, the CLI refused it with *"/tickets/0/slice:
    must have required property 'next', /tickets/0: must match "then" schema"* and the session
    printed prose instead of JSON, so the CLI both accepts **and enforces** the conditional. The first
    version printed a strict-mode warning on stderr, *"missing type "object" for keyword "required" at
    "#/properties/tickets/items/then/properties/slice" (strictTypes)"*. Adding `"type": "object"` to
    that sub-schema cleared it, and re-probe (d) returned valid JSON with 0 bytes on stderr. Offline
    validator agrees with (d).
  - **Clause table (AC6), every mutation run on committed `6bfec33` and restored by `git checkout`
    in the same call; control after: `12 passed, 0 failed`, tree clean.**

    | AC6 clause | Assertion (`tests/outcome-schema.test.sh`) | Mutation (run) | Red |
    |---|---|---|---|
    | Given `outcome.schema.json` and `tools/validate-json-schema.py` | every case runs the real schema through the real validator | — | — |
    | `progressed` with `slice: {done: S1, next: S2}` validates | first case | M1 `progressed` out of the enum | 1 |
    | `progressed` with no `slice.next` fails | second case, reason names `'next'` | M2 if/then deleted; M3 `then` drops `next`; M8 validator ignores `if` | 2; 1; 4 |
    | (and no `slice` at all fails) | third case, names `'slice'` | M4 `then` drops `slice` | 1 |
    | existing `built` with no `slice` still validates | fourth case | M9 validator always applies `then` | 5 |
    | FR7 pattern `^S[0-9]+$` | `a slice name off ^S[0-9]+$` | M5 pattern dropped | 1 |
    | slice keys closed | `an undeclared key inside slice` | M6 `additionalProperties` dropped | 1 |
    | `next` required only when progressed | `built may report … slice.done alone` | M7 `next` required unconditionally | 1 |
    | validator `else` | conditional fixture cases | M10 `else` never applied | 1 |

    Every AC6 case was red before the change (8 of 12; the 4 green were the unchanged-shape and
    if-matching positives).
  - **Whole suite at `a3ae3e6`: 45 files, every one exit 0.** The S1 build notes listed three baseline reds
    (`release`, `sprint`, `item-nfr-red`), and all three are green here. `tests/sprint.test.sh` ran AC22's
    live probe with the new schema.
  - **For S3/S6, observed this leg:** `handoff`'s `declared_touches` reads block-list `touches:` only.
    The claim wrote none (0231's `expects:` is flow-style, the parked `claim` gap), and a flow-style
    `touches: [a, b]` written by hand parses to nothing. That makes `--slice`'s dirty check pass
    vacuously, with no refusal. Written here as a block list for that reason (`b6d4f08` → `14b9fb3`).
    `.tickets/claim` also still needs `xxd`, so this claim passed a token explicitly. Both sit with
    the parked `claim` findings. Neither is in S2's scope.
  - The installed outcome schema (plugin 0.9.48) has no `progressed` until a release, so this leg
    reports `built` to its supervisor. S6 owes the CHANGELOG line for it.
- 2026-11-18 — **verify (8ffc), leg S2: PASS.** AC6 checked literally, each clause mutated red by this
  pass (*QA evidence*, Leg S2); full suite green at `e4439ad`. Handed back with `--slice S2` so S2
  ticks; no AC ticked. Next leg: S3. `.tickets/claim` still needs `xxd` (parked); this claim passed a
  token explicitly.
- 2026-11-18 — **develop (5a3e), leg S3: built, handed to verify with `--slice S3`.** Commits
  `61ceb12` (leg routing, started-first, sliced gate of one, one verify per gate; tests) and
  `d29fa86` (bounce and gate-of-one guards, an unfalsifiable check dropped). All in
  `skills/queue/templates/next` (`.tickets/next` byte-identical) and `tests/next.test.sh`.
  **S3 alone is the leg.** S4 shares both files, but FR3's second condition fails: this session was
  about 45 turns in at S3's commit, past the 28.5-turn break-even `MEASUREMENT.md` gives
  (*Would the re-entry after a FAIL be cheaper…*). S3 discharges ACs, so develop → develop was not
  available anyway.
  - **FR11's question, answered: neither of the two.** `--drive`'s verify branch did batch. It
    recovered a gate by re-running the join (`gate_from`) over the started rows now at
    `verify | ready`, and that re-derivation splits a gate in two cases. The first is a join that ran
    through a member no longer at verify (closed by `close_by: develop`, or left red at develop). The
    second is a member whose `expects:` a develop session corrected after the gate formed, which
    `develop` Step 1 tells it to do. Evidence, read: `.tickets/LEDGER.md` records gate `e9c46949` as
    *"GATE develop 4 ticket(s)"*. 0177, 0190 and 0183 as they stand share no `expects:` path and no
    `parent:`. **Reasoned, not read:** which member was missing, and why. The run's jsonl is not on
    this machine (`.tickets/runs/` is gitignored and the clone is shallow).
  - **Fix, inside FR11's wording ("after `--completed develop:<lead>`").** The batch is now every
    started row at `verify | ready` (`completed_batch`), not a re-derivation. Finish-before-start
    (0131) verifies every started verify row before a new develop gate forms, so at that moment those
    rows are that gate's. The rank walk and the started-verify preference keep `verify_batch`, so
    0132 AC2's cases are unchanged. **A residual edge, reasoned:** an earlier gate's row that was
    skipped for an open blocker, and whose blocker cleared during a later gate, would join that
    later gate's batch. That costs a wider batch of rows this run developed, never a row it did not.
  - **Definitions this build picked.** `leg_state` reads the item. It answers `unsliced` (no slice
    lines), `finished` (all ticked), `bounced` (`slice:` names an unticked slice) or `clean`.
    A sliced ticket is a gate of one at develop and at verify (`gate_from`, `completed_batch`), because
    a leg ends in a `handoff --slice` that describes one ticket.
  - **The loop guard (`handed_off_from`) is beyond FR8's letter, and it is load-bearing.** "At
    `develop / ready` with `slice:` ticked" also describes a develop session that died before it
    claimed after a verify pass, and dispatching on that state alone would loop forever. So a leg is
    dispatched only when the item's last commit moved it out of the completed stage, read with
    `git show <sha>^:` on the item. Any doubt answers no, which means the existing escalation.
    Test fixtures model the hand-off as two commits (`fixture_handed_off_from`).
  - **Not done here, for S4:** a leg dispatch does not run `gate_wait`. FR10's held-design-file
    wait for legs (AC12) is S4's. `--help` does not describe legs yet; that prose goes in S6.
  - **Clause table (S3's ACs). Every mutation was run on committed code** in a detached worktree,
    against a trimmed copy of `tests/next.test.sh` (its helpers plus the 0231 section). Each was
    restored by `git checkout` and controlled green after (25 passed, 0 failed):

    | AC clause | Assertion (`tests/next.test.sh`) | Mutation (run) | Red |
    |---|---|---|---|
    | AC7 Given the AC1/AC3 fixtures; after develop → develop, `DISPATCH  develop <id>` | `0231 AC7 — after develop -> develop` | M1 leg arm off | 7 (with AC8, FR8) |
    | AC7 after develop → verify, `DISPATCH  verify <id>` naming that ticket alone | `… that ticket alone is verified` | M5 sliced lead batched | 1 |
    | AC7 `--completed verify:<id>` after the pass, `DISPATCH  develop <id>` | `… after a leg verify passes` | M1 | (in M1's 7) |
    | AC7 after the fail, exit 4 with the bounce escalation | `… after a leg verify fails` | M3 bounced reads clean | 3 |
    | FR8 (beyond the ACs) a develop that ended no leg is the same-stage loop | `… a develop that ended no leg` | M2 hand-off guard always true | 3 |
    | FR8 (beyond) all slices ticked → nothing dispatched | `… every slice ticked` | M12 finished reads clean | 2 |
    | AC8 A (S1, S2 ticked, S3 not) at develop/ready, B ranked above → `develop A`, not B | `0231 AC8` | M1 | (in M1's 7) |
    | FR8 started-first in the rank walk | `… from --started alone` | M9 `started_leg` off; M10 `--started` ignored | 1; 2 |
    | FR8 a sliced ticket is never a gate member, and leads a gate of one | `… its own dispatch unit` | M8 joiner skip off; M7 lead return off | 1; 1 |
    | AC9 three rows from one gate, all at verify/ready, all started → one `DISPATCH  verify` naming all three | `0231 AC9 — every row one gate developed` | M4 `completed_batch` → `verify_batch` | 2 |
    | AC9 (FR11) a sliced leg does not join the gate's batch | `… does not join a gate's verify session` | M6 sliced member admitted | 1 |
    | AC15 `tests/batching.test.sh` gate cases pass unchanged | the file itself, unedited | — (not mutated; that file guards skill prose, which S3 does not touch) | — |

    Every AC7/AC8/AC9 case except the bounce (a guard on an unchanged path) was red before the
    change: 12 failures at the first run. One mutation was green and its check was removed rather
    than kept: requiring a non-empty `slice:` in the leg arm was indistinguishable from the
    hand-off guard.
  - **Whole suite at `d29fa86`: 45 files, every one exit 0** (`tests/next.test.sh` `600 passed, 0
    failed`; `tests/batching.test.sh` `39 passed, 0 failed`; `tests/declared-copies.test.sh` `23
    passed, 0 failed`, which now covers a third `progress-slices` copy in `next`).
    `git status --porcelain` was clean at the run apart from this notes edit.
- 2026-11-18 — **verify (2a45), leg S3: PASS.** AC7, AC8, AC9 and AC15 were checked literally, and
  this pass mutated each clause to red itself (*QA evidence*, Leg S3). The full suite is green at
  `d4be431`. Handed back with `--slice S3` so S3 ticks. No AC was ticked. Next leg: S4.
  `.tickets/claim` still needs `xxd` (parked), so this claim passed a token explicitly.
- 2026-11-18 — **develop (1995), leg S4: built, handed to verify with `--slice S4`.** Commits
  `20677fa` (FR9 and FR10 in `skills/queue/templates/next`, `.tickets/next` byte-identical, and
  tests) and `53596c4` (a guard on the end-of-walk escalation, added because the sweep found it
  unguarded). **S4 alone is the leg.** It discharges AC10–AC12, so FR4 refuses develop → develop.
  S5 also opens `handoff` and `tools/sprint-ledger.sh`, which S4 never opened (FR3).
  - **Definitions this build had to pick, all inside FR9/FR10's wording.**
    - **"In-scope" requires `--scope`.** With no `--scope` a waiting or `next: queue` row stops the
      walk exactly as before. 0038 AC9 and 0188 AC3 assert that and pass unedited (AC16).
    - **"While other in-scope work is takeable" is `scope_live`**, the predicate the findings gate
      already uses. It is checked when the walk reaches the waiting row: false → the existing
      escalation, true → `NOTE` and continue. The first such row is remembered (`WAITED`). If the
      walk then dispatches nothing (for example, the other in-scope row is a design row stepped over
      for a file a running develop holds), it escalates on that row before the findings tail. So exit
      5 is masked only by an **in-scope** waiting row, never by an out-of-scope one.
    - **The completion arm.** `--completed <stage>:<id>` that leaves the row waiting no longer
      escalates when `--scope` is given. It prints a `NOTE` and the rank walk decides by the rule
      above. Without `--scope` it still escalates.
    - **An out-of-scope `next: queue` row** is stepped over with a `NOTE`. An in-scope one still
      escalates (asserted).
    - **FR10's "touches: or expects:"** widens `gate_wait` to read both of the running design row's
      lists. 0188's `gate_wait` read `expects:` only. 0188 is closed and 0212 is withdrawn into FR10,
      so no open FR is left stale by this. The wait (`wait_on_design`) now also runs in
      `dispatch_leg` (a leg is a gate of one, which S3 deferred) and in the same-stage arm, for
      `develop` at `develop / ready`. That last case is a develop that stood down, so it re-enters
      exit 6 instead of exit 4. With the file released it is the loop escalation again (asserted).
  - **Beyond the ACs, in this leg's file: `waiting_on` reads the FR14 brief.** A brief opens on
    `### Outcome`, so the escalation used to carry the bare heading. Where `### What needs you`
    exists, its first line is printed. Otherwise the section's first line is printed, as before. S5
    enforces the brief in `handoff`, and this is the reader side of it.
  - **Not done here, for S6:** `--help` does not yet describe FR9's step-over or the touches-wide
    wait. That prose belongs with the S6 skill text, as S3 also left it. `sprint` Step 6 is not
    changed yet either (FR9's last clause, S6).
  - **Clause table (S4's ACs).** Every mutation was **run** on committed `20677fa`/`53596c4` in a
    detached worktree, against a trimmed copy of `tests/next.test.sh` (helpers, plus the S3 fixture
    helpers, plus the S4 section). Each diff was confirmed non-empty and restored by
    `git checkout`. The control before and after was `35 passed, 0 failed`, and the worktree was
    removed.

    | AC clause | Assertion (`tests/next.test.sh`) | Mutation (run) | Red |
    |---|---|---|---|
    | AC10 Given an in-scope `design / waiting` row with a complete brief and an in-scope `develop / ready` row | fixtures `0941`/`0942`, `waiting_brief` | — | — |
    | AC10 prints a `NOTE` naming the waiting row, dispatches the develop row, exits 0 | `0231 AC10 — an in-scope waiting row is stepped over…` | M2 in-scope waiting always escalates | 6 |
    | AC10 with the waiting row the only in-scope work, exit 4 | `… the only in-scope work, exit 4` | M3 always step over, never escalate | 5 |
    | FR9 the walk dispatched nothing after stepping over → exit 4, not COMPLETE | `… stepped over for in-scope work the walk then cannot dispatch` | M4 end-of-walk escalation off | 3 (green before `53596c4`, hence that commit) |
    | FR9 a completed stage leaving its row waiting | `0231 FR9 — a stage that leaves its row waiting…` | M9 completion arm escalates as before | 2 |
    | AC11 Given out-of-scope `waiting` and `next: queue` rows above a finished scope, `FINDINGS.md` past threshold | fixtures `0951`/`0952`, scope `0953` in `DONE.md`, `eight_findings` | — | — |
    | AC11 both stepped over with a `NOTE`, exit 5 | `0231 AC11 — out-of-scope waiting and next: queue rows…` | M1 out-of-scope waiting not stepped over; M5 out-of-scope queue not stepped over | 6; 4 |
    | AC11 (beyond) an in-scope queue row still escalates | `… an IN-scope next: queue row still escalates` | M11 every queue row stepped over | 2 |
    | AC12 Given design A in-progress with F in `touches:`, develop B expecting F → exit 6 naming A, no `DISPATCH` for B | `0231 AC12 — a develop row expecting a file…` | M6 `gate_wait` reads `expects:` only | 10 (with the two below) |
    | AC12 with A's files disjoint, dispatches B | same loop, `g/other.md` | — (positive case; reds if the wait ignores the paths) | — |
    | AC12 B unchanged after `--completed develop:B` while A holds F → exit 6, not 4 | `… a develop that left its row unchanged…` | M7 same-stage wait off | 3 |
    | FR10 a leg waits too | `0231 FR10 — a sliced ticket's next leg waits…` | M8 `dispatch_leg` wait off | 3 |
    | (beyond) escalation carries the brief's question | `carrying its question` | M10 `waiting_on` ignores `### What needs you` | 1 |

    Before the change, 23 of the new cases were red.
  - **Whole suite at `53596c4`: 45 files, every one exit 0** (`tests/next.test.sh` `635 passed, 0
    failed`; `tests/batching.test.sh` `39 passed, 0 failed`; `tests/declared-copies.test.sh` `23
    passed, 0 failed`). `git status --porcelain` was clean at the run.
- 2026-11-18 — **verify (7c3e), leg S4: PASS.** AC10, AC11 and AC12 were checked literally. This pass
  ran every clause mutation to red itself (M1–M15, *QA evidence*, Leg S4). The full suite is green at
  `04885aa`: 45 files, all exit 0. Handed back with `--slice S4` so S4 ticks. No AC was ticked. Next
  leg: S5. For the closing verify: FR12's scope-bounded continuation is not enforced by `next`
  (see Step 4 in the evidence).
- 2026-11-18 — **develop (46a6), leg S5: built, handed to verify with `--slice S5`.** Commits
  `439d05c` (AC13: `handoff` refuses an incomplete waiting brief; template and `.tickets/handoff` copy),
  `e2d7d63` (AC14: `tools/sprint-ledger.sh envelope`), `d244651` (two envelope assertions tightened
  after a mutation left them green). **S5 alone is the leg.** It discharges AC13–AC14, so FR4 refuses
  develop → develop, and FR3's two conditions both fail for S6: S6 opens skills, README, CHANGELOG
  and `CONCURRENCY.md`, none of which this leg opened, and the session was ~30 turns in, past
  `MEASUREMENT.md`'s 28.5-turn break-even. Whole suite at `d244651`: 45 files, all exit 0, tree clean.
  `.tickets/claim` still needs `xxd` (parked), so this claim passed a token explicitly.
  - **Decision inside FR14's text, for the closing verify to read:** the brief is checked only on a
    `waiting` hand-off **of an item that has a `## Waiting on` section**. An item with no section at
    all still hands off waiting as before, because `tests/handoff.test.sh`'s FR2 case does exactly
    that with no section and AC16 forbids editing it. FR14 says "refuses a section missing any
    subsection", which this satisfies literally. The NFR Compatibility row ("only a new handoff …
    waiting checks the brief") is the other half: a `ready` hand-off over a partial brief is never
    checked. If the author wants a section-less waiting hand-off refused too, that is a contract
    change for `queue`, since it needs the FR2 case edited.
  - **Options are counted under `### Options` only**, up to the next `### `; a `#### Option` elsewhere
    and a `### ` heading after the `## Waiting on` section ends do not count. The refusal lists the
    whole brief shape itself rather than pointing at `templates/item.md`, which gains that shape only
    in S6 (develop Step 4: a refusal in a template must be actionable without the skill).
  - **`envelope`'s definitions** (FR13 names the inputs, not the arithmetic): spend is the sum of the
    outcome events' `cost_usd`. An outcome with none is priced at its stage's cap and counted aloud.
    The supervisor's own spend is in no outcome and is not counted, and a resumed session's outcome
    covers only its last leg (sprint Step 7). Both understate spend, so S6's sprint prose should say
    so or add a margin. The cost estimate is this run's mean for the stage, then MEASUREMENT.md's
    per-skill row when `--measurement` is given, then the stage cap labelled `no prior: the stage
    cap`. "Ledger prior" is read as that chain, because `LEDGER.md` holds per-sprint figures and no
    per-stage ones. The time estimate is the mean dispatch-to-outcome window paired by `session_id`.
    With none, only a past deadline stops on time. Field names `budget_usd` and `deadline` (ISO UTC)
    on `scope_confirmed` are this build's, and S6's sprint Step 1/5 prose must write them. Exit codes:
    CONTINUE 0, STOP 3, unreadable 1. `--now` exists for fixtures.
  - **FR12 is not done here.** The proposal, the defaults and "continue past scope only when told" are
    sprint prose, so they belong to S6. `envelope` is only the check that FR12's per-dispatch rule calls.
  - **Clause table (S5's ACs).** Every mutation was **run** on committed code. Each pattern was required
    once, the diff was confirmed non-empty and restored by `git checkout --`, and the control was green.
    `handoff` mutations ran against `tests/handoff.test.sh` (control 250/0). `envelope` mutations ran
    against `tests/sprint-ledger.test.sh` (control 229/0).

    | AC clause | Guard (test title) | Mutation | Reds |
    |---|---|---|---|
    | AC13 Given `## Waiting on` lacks `### If no answer` → refuses naming it, changes nothing | `0231 AC13 — a brief lacking ### If no answer…` | M6 drop it from the wanted list; M8 refusal does not exit; M1 check off | 8; 25; 38 |
    | AC13 or has one `#### Option` → refuses naming the missing part | `… one #### Option…` | M3 threshold `< 1` | 6 |
    | AC13 every subsection with two options → succeeds | `… every subsection with two options hands off waiting` | M9 no `### ` heading recognised (all "missing") | 6 |
    | FR14 any subsection (quantifier) | seven-part sweep `… each of the seven subsections, missing alone` | M1, M9 | (in 38, 6) |
    | FR14 options counted under `### Options` only; section ends at next `## ` | `… an option outside ### Options…` | M5 `inopt = 1`; M4 section never ends | 1; 1 |
    | NFR compat: never checked on a ready hand-off | `… never on a ready one` | M7 status test dropped | 2 |
    | AC14 less budget than the estimate → `STOP` naming budget, non-zero | `0231 AC14 -- with less budget left…` | E1 budget test off; E10 costs not summed; E6 run-log prior off | 7; 7; 1 |
    | AC14 less time than the estimate → `STOP` naming time | `… less time left…` | E2 time test off; E11 windows not measured | 2; 3 |
    | AC14 enough left → `CONTINUE`, exit 0 | `… with enough left, CONTINUE and exit 0` | E4 STOP exits 0 (inverse direction) | 5 |
    | AC14 no ledger prior → stage cap, says so | `… no prior for the stage, the stage cap is used and labelled` | E8 label dropped | 1 (after `d244651`; 0 before) |
    | FR13 distinct exit codes; missing envelope is an error | `0231 FR13 -- STOP and an error exit differently…` | E5 STOP exits 1; E9 missing-field check off | 1; 2 (after `d244651`; 0 before) |
    | FR13 past deadline stops with no prior | `… a deadline already past…` | E3 past-deadline test off | 2 |
    | FR13 unpriced outcome counted at its cap | `… an outcome carrying no cost_usd…` | E7 unpriced not added | 2 |
- 2026-11-18 — **verify (b5c7), leg S5: FAIL on AC14, handed back to develop without `--slice`.**
  AC13 passes, every clause mutated red by this pass. AC14's clause *"prints `STOP` naming budget or
  time"* is unguarded. Rewording the STOP reason (`budget:` → `over:`, and `time: %d min left` →
  `over: %d min left`) changes the output and leaves `tests/sprint-ledger.test.sh` at `229 passed, 0
  failed` (*QA evidence*, Leg S5, E8/E9). The cause is that `names budget` and `names time` (the
  short-budget and short-time cases) match the whole output, and the `ENVELOPE  budget` / `ENVELOPE  time`
  header lines always carry both words. **Constraint:** those two assertions must read the `STOP`
  line alone (`grep '^STOP'`, as the time case's `hasnt` and the past-deadline case already do), so
  that E8 and E9 each go red. `tools/sprint-ledger.sh` is correct as it stands and needs no change.
  Mechanism cleared: the budget, time, exit-code, CONTINUE and stage-cap clauses all reddened. Suite
  green at `9c3b097`, 45 files.
- 2026-11-18 — **develop (33d4), leg S5 re-entry for verify b5c7's AC14 FAIL.** Under
  `tests/sprint-ledger.test.sh` (commit `575ec14`), the short-budget case's `names budget` and the
  short-time case's `names time` now read the `^STOP` line alone (`grep '^STOP'`), renamed `the STOP
  line names budget` and `the STOP line names time`. `tools/sprint-ledger.sh` is unchanged. **Run, not
  reasoned:** with the mutations applied to the committed tree and restored by path in the same turn,
  E8 (`reasons.append("budget: ` → `"over: `) gave `228 passed, 1 failed`, `FAIL the STOP line names
  budget -- wanted 'budget' in: STOP  over: 3.00 left, develop needs an estimated 7.00`. E9
  (`"time: %d min left` → `"over: %d min left`) gave `228 passed, 1 failed`, `FAIL the STOP line names
  time -- wanted 'time' in: STOP  over: 20 min left, develop needs an estimated 40 min`. The control run
  afterwards gave `229 passed, 0 failed`, with `git status` clean. Whole suite: 45 files, 0 red, at
  `575ec14`. No other AC14 row moved, so the rest of b5c7's clause table stands. S6 has not been
  started.
