---
id: "0231"
title: Drive one outcome ticket across slice sessions unattended
type: feature
next: design
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0071", "0149", "0220", "0226", "0212", "0137", "0128"]
expects: [skills/sprint/SKILL.md, skills/sprint/outcome.schema.json, tools/validate-json-schema.py, skills/design/SKILL.md, skills/develop/SKILL.md, skills/verify/SKILL.md, skills/queue/SKILL.md, skills/queue/templates/item.md, skills/queue/templates/next, skills/queue/templates/handoff, skills/queue/templates/claim, skills/queue/templates/close, skills/queue/templates/config.yml, references/CONCURRENCY.md, tests/next.test.sh, tests/handoff.test.sh, tests/batching.test.sh, tests/close.test.sh, README.md, CHANGELOG.md]
ac_digest: AC1=f5e035bc AC2=6fca396f AC3=9926fde0 AC4=76f6528f AC5=23fc177e AC6=6b5a6640 AC7=275776c6 AC8=094d8b2a AC9=20b132f5 AC10=18ecb8fd AC11=b2ca314c
claimed_by: "e4ad"
claimed_at: 2026-11-18T05:55:57Z
touches:
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

Settled by the 2026-11-18 design pass (*Notes & decisions*). FR numbering is new; the draft's FR10
was discharged by that pass and is recorded there.

- FR1 — **Slices live in the item.** `templates/item.md` gains a `## Progress` section of ordered
  lines in the form `- [ ] S<n> — <what lands> — discharges AC<a>, AC<b>` (or `— discharges none`),
  and a frontmatter scalar `slice:` naming the slice of the most recent slice hand-off. Every AC is
  named by exactly one slice, the one where it first becomes true; outcome-level ACs sit on the last
  slice. Ticked slices are history and never edited; `develop` may re-split or re-order *unticked*
  slices with a dated note, and never changes an AC. A ticket with no `## Progress` section is a
  single-leg ticket and behaves exactly as today. `queue` Step 2 tells authors to write one outcome
  ticket with ordered slices, each sized to one `develop` session, rather than one ticket per slice,
  citing `product-definition-conventions.md` → "Slice Vertically and Thinly" rather than restating it.
- FR2 — **A `progressed` verdict.** `outcome.schema.json` gains `progressed` in the verdict enum and
  an optional per-ticket `slice` object `{ "done": "S<n>", "next": "S<n>" }` (pattern `^S[0-9]+$`),
  required when the verdict is `progressed`. `develop` returns `progressed` when it hands a ticket
  on at a slice boundary with slices remaining; `verify` returns `pass` with `next: develop` for a
  slice pass. `tools/validate-json-schema.py` implements a subset of JSON Schema with no `if`/`then`,
  so the conditional needs that support added (or an equivalent the validator already has), and
  whether `claude -p --json-schema` accepts the construct is to be checked against the installed CLI,
  not assumed.
- FR3 — **`handoff --slice S<n>`** records slice progress in the same locked commit as the hand-off:
  - develop → develop: ticks S<n> and sets `slice: S<n>`; **refuses if S<n> discharges any AC**,
    naming `verify` as the destination it needs;
  - develop → verify: sets `slice: S<n>` and leaves it unticked (refuses if already ticked);
  - verify → develop with `--slice`: the slice passed — ticks S<n>. Without `--slice` it is the
    fail bounce, unchanged, and S<n> stays unticked;
  - refuses an unknown slice, or one with an earlier unticked slice above it.
  With `--slice`, it **refuses when any path in the item's `touches:` is dirty**, naming those paths
  and changing nothing. Not the whole tree: the tree is shared and other sessions' paths are
  legitimately dirty (`CONCURRENCY.md`, *The working tree is shared too*).
- FR4 — **One slice per `develop` leg.** `develop` ends at every slice boundary; it does not meter
  its own spend, because no session reads its running cost (costs are harvested from transcripts
  afterwards, `references/TRACKER.md`). `stage_budget_usd.develop` is the per-leg cap and keeps its
  name; once the ledger holds legs it is derived from per-leg history as sprint Step 7 requires, and
  until then the proposal labels the leg figure as having no prior. No new config key.
- FR5 — **`next --drive` routes slices.** With an item carrying `## Progress`:
  - `--completed develop:<id>`, row at `develop / ready`, `slice:` ticked and slices remaining →
    `DISPATCH develop <id>`, in place of the same-stage escalation;
  - `--completed develop:<id>`, row at `verify / ready` mid-slices → `DISPATCH verify <id>`, this
    ticket alone;
  - `--completed verify:<id>`, row at `develop / ready`, `slice:` ticked → `DISPATCH develop <id>`;
    `slice:` unticked → the existing bounce escalation;
  - a ticket in `--started` with slices remaining is finished before the rank walk opens a
    different develop row.
  An item with no `## Progress` section routes exactly as today.
- FR6 — **`close` on a sliced ticket** refuses while any slice other than the one `slice:` names is
  unticked, and on success ticks that last slice in the same commit as the ACs.
- FR7 — **Waiting rows do not halt a run that has other work.** `--drive` steps over an in-scope
  `waiting` row with a `NOTE` naming it while other in-scope work is takeable, and exits `4` only
  when a waiting row remains and nothing in scope is takeable. Rows `blocked_by:` it stay blocked, as
  today. An out-of-scope `waiting` or `next: queue` row is stepped over with a `NOTE`, as an
  out-of-scope design row already is (absorbs 0226 Q1–Q2); and once the scope is finished, the
  findings gate's exit `5` is not masked by an escalation only out-of-scope rows produce (0226 Q3).
- FR8 — **Design prepares a person's decision; it never makes it.** `design` Step 3 gains the
  unattended case: where the answer turns on taste, or is an architecture or security choice
  (`coding-conventions.md` → *What Not to Delegate to AI*), and no person can be asked, the pass
  runs its spikes, writes the options and a recommendation, reduces it to specific questions in
  `## Waiting on`, and releases with `./handoff <id> <token> design waiting` (verdict `blocked`). It
  never records the decision. `sprint` Step 8 says the same and Step 2 sends the person a
  notification on every outcome that leaves a row `waiting`.
- FR9 — **Sprint scope is counted in legs.** The proposal's floor of three and target of about five
  is counted in develop legs, with a sliced ticket contributing its unticked slices, because the
  floor's stated reason (a ticket's floors are paid wherever it runs; a one-*session* sprint is
  dearer than `/develop` by hand) is about sessions. The proposal defaults to the top outcome
  ticket and fills with other takeable rows only as needed to reach the floor. Continuing past the
  confirmed scope happens only when the person said so at the proposal, recorded in
  `scope_confirmed`.
- FR10 — **`queue` amend-first.** Before minting an id, `queue` searches open tickets' outcomes and,
  where one is served, amends it (re-checking size, ACs, QA plan and out-of-scope, re-stamping
  `ac_digest`, and adding or re-splitting unticked slices). It mints only for work with an outcome of
  its own, and records which test it applied in *Notes & decisions*.
- FR11 — **`queue` Merge.** Step 1's table gains Merge: absorbing tickets into one outcome ticket
  withdraws each per *Withdrawing a ticket* with a pointer to the requirement that now carries it,
  quotes user-reported evidence verbatim in the absorbing ticket, and burns the ids.
- FR12 — **A claimed ticket is still never amended; the wait is bounded instead.** Step 1's
  prohibition stands. Because every leg releases its claim at a slice boundary (FR3), `queue` waits
  for the release, claims the row itself, amends, and hands it back with `./handoff <id> <token>
  develop`. `CONCURRENCY.md`, *A stage writes only the ticket it holds*, says why that is safe:
  one writer per item file at every instant, and a wait no longer than one leg.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | Unattended runs still never push, bump, install or restart without per-action approval (sprint Step 8 unchanged), and a design pass never records a person's decision (FR8) | prose: no script owns either rule, and this repo adds no prose guards (`CLAUDE.md`, *Tests*), so `verify` reads both against AC11 | `security-conventions.md` |
| Compatibility | A ticket with no `## Progress` section, and every backlog already installed, behaves exactly as before | the existing `tests/handoff.test.sh`, `tests/next.test.sh` and `tests/close.test.sh` cases pass unchanged (AC10) | `api-conventions.md` |
| Documentation | `CHANGELOG.md` `## Unreleased` entry, one per behaviour a session will see differently; README skill descriptions updated where sprint, develop, design and queue change | `tests/changelog-entry-guards.test.sh` | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture item with three slices where S1 discharges none, when `handoff <id> <token> develop --slice S1` runs, then the item shows S1 ticked, `slice: S1`, `claimed_by:` empty, `next: develop`, `status: ready`, and `next --drive --completed develop:<id> --scope <id>` prints `DISPATCH  develop <id>` and exits 0 (`tests/handoff.test.sh`, `tests/next.test.sh`).
- [ ] AC2 — Given the same fixture with a path from the item's `touches:` modified, when `handoff --slice S1` runs, then it exits non-zero naming that path, and the item, the row and `git log` are unchanged; and given a dirty path that is not in `touches:`, then the hand-off succeeds (`tests/handoff.test.sh`).
- [ ] AC3 — Given a fixture slice S2 that discharges an AC, when `handoff develop --slice S2` runs, then it refuses naming `verify`; when `handoff verify --slice S2` runs, then `slice: S2`, S2 unticked and `next: verify`; when verify then runs `handoff develop --slice S2`, then S2 is ticked and `--drive --completed verify:<id>` prints `DISPATCH  develop <id>`; and when verify instead hands back without `--slice`, then S2 stays unticked and `--drive` exits 4 with the bounce escalation (`tests/handoff.test.sh`, `tests/next.test.sh`).
- [ ] AC4 — Given `outcome.schema.json` and `tools/validate-json-schema.py`, then an outcome with verdict `progressed` and `slice: {done: S1, next: S2}` validates, one with `progressed` and no `slice.next` fails, and an existing `built` outcome with no `slice` still validates (the test that owns the schema, or a new `tests/outcome-schema.test.sh`).
- [ ] AC5 — Given a fixture where ticket A has S1 and S2 ticked and S3 unticked at `develop / ready` and ticket B at `develop / ready` ranks above it, when `next --drive --completed develop:A --scope A --scope B` runs, then it dispatches `develop A`, not B (`tests/next.test.sh`).
- [ ] AC6 — Given a fixture where ticket A's last slice is the one `slice:` names and an earlier slice is unticked, when `close` runs, then it refuses naming the unticked slice; and with every earlier slice ticked, then it closes and the last slice is ticked in the close commit (`tests/close.test.sh`).
- [ ] AC7 — Given a fixture with an in-scope row at `design / waiting` carrying `## Waiting on` and an in-scope row at `develop / ready`, when `--drive` runs, then it prints a `NOTE` naming the waiting row, dispatches the develop row and exits 0; and given the waiting row as the only in-scope work, then it exits 4 (`tests/next.test.sh`).
- [ ] AC8 — Given a fixture with an out-of-scope `waiting` row and an out-of-scope `next: queue` row ranked above a finished scope and `FINDINGS.md` past `findings_threshold`, when `--drive` runs, then both are stepped over with a `NOTE` and it exits 5 (`tests/next.test.sh`).
- [ ] AC9 — Given `tests/batching.test.sh`, then its gate cases pass unchanged, so gate batching still holds for a backlog of unsliced rows (`tests/batching.test.sh`).
- [ ] AC10 — Given the full suite `for t in tests/*.test.sh; do "$t" || exit 1; done`, then it exits 0 with no existing case edited to pass, so a ticket without `## Progress` behaves as before.
- [ ] AC11 — Given the changed skill files, when `verify` reads them, then `templates/item.md` documents `## Progress` and `slice:` per FR1, `queue`'s Step 1 table carries Merge (FR11) and its Step 2 carries amend-first (FR10) and the bounded wait (FR12), `design` Step 3 carries the unattended prepare-and-wait case and the clause that it never records the decision (FR8), `sprint` Step 8 still lists push, bump, install and restart as per-action approvals, and its proposal counts legs (FR9) — read, not grepped (`CLAUDE.md`, *Tests*).

## QA plan

- **Why that level:** `unit` — the mechanical changes land in `handoff`, `next`, `close`, the schema
  and its validator, which `tests/*.test.sh` already exercise with fixture backlogs. AC11 is a
  literal read; this repo puts no guard on prose.
- **Specific checks:** the full `tests/*.test.sh` run; AC1–AC9's fixture cases each seen red before
  the change; a dry `/sprint` against a scratch backlog holding one three-slice ticket (S1 discharges
  none, S2 and S3 discharge ACs) to watch develop → develop → verify → develop → verify → close.

## Out of scope

- Running two develop sessions at once — 0137.
- Verify batching for a gate of unsliced rows — 0220, which keeps its own outcome.
- The design-beside-develop held-file check — 0212 defect 1, which keeps its own row. Its defect 2
  edits the same same-stage guard FR5 changes; whichever lands second re-reads the other.
- Charting work too foggy to ticket — 0071, which keeps its own row.
- A develop session metering its own spend mid-leg (FR4: no mechanism exists).
- The release of these changes — `tools/release`, on Aaron's say-so.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

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
