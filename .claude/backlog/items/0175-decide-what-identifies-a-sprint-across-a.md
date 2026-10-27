---
id: "0175"
title: Decide what identifies a sprint across a suspension, and which mechanisms key off it
type: debt
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: l
ac_digest: AC1=5ee0a93e AC2=a351bd9c AC3=83f85573 AC4=b7f1acb7 AC5=fb6f0520 AC6=df777c04 AC7=d36a4467 AC8=f3177b2b
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0164", "0153", "0152"]
expects:
  - skills/sprint/SKILL.md
  - tools/sprint-ledger.sh
  - tools/harvest-usage.sh
  - tests/sprint.test.sh
  - tests/sprint-ledger.test.sh
claimed_by: "3358"
claimed_at: 2026-10-27T00:57:29Z
touches:
---

## Problem

**A sprint that spans two days is a normal use case, and four separate mechanisms in `sprint` assume
one continuous run.** `run-20260920T222013Z` was interrupted three times — an account session limit
resetting, then the background wrapper's 600 s ceiling, then the host sleeping mid-response twice —
and resumed across a date boundary. What broke, or would have:

1. **The cap formula.** Step 7 caps a resumed leg at the stage cap less what a harvest already shows
   spent. Every resume re-pays the session's context floor, so the remainder shrinks toward zero
   while the unfinished scope does not: at the third resume the formula gave USD 3.21 for two
   untouched tickets against a two-ticket price of 9.08, and obeying it would have fired mid-verify.
   The floor is a cost of *being interrupted*, not of scope, and nothing subtracts it.
2. **The supervisor marker.** `.active/held-by` is kept fresh by a heartbeat living inside one Bash
   call, and `lock_stale_seconds` is 900 s — so any overnight gap ages the marker out and a
   supervisor resuming its own run next morning reads its own marker as a stale one to take over.
3. **`sprint_ended` and the findings gate.** One interrupted sprint resumed later is one sprint, and
   nothing says so: writing the event at each halt inflates `findings_max_sprints` on a technicality;
   writing it once means a run that never resumes is never counted. This run wrote it once, by hand,
   on the supervisor's judgment.
4. **The ledger.** `record` appends one block per invocation and derives wall-clock from the first
   and last event timestamps, so an overnight gap books as work time and a second invocation
   double-counts the run. `0164` covers the elapsed/active split but not the re-invocation.

## Decision (2026-10-25, design)

**A suspended-and-resumed run is one sprint, and its identity is the run id it already has —
`run-<start UTC>`, the name of its run log and the first field of `.active/held-by`.** No new
identifier. The supervisor *conversation* holds it in context across a suspension (in
`run-20260920T222013Z` the conversation survived every interruption; only the Bash call carrying the
heartbeat died), and a person can hand it to a new conversation explicitly. A process continues a run
**iff it holds that run id**; nothing else makes it the same sprint.

- **Written** by the supervisor at Step 1, exactly as today (`held-by`, run log name).
- **Persists** across a suspension untouched: the marker stays, the log stays, nothing is written at
  an interruption the supervisor did not see coming.
- **Cleared** in exactly two ways: the run's own terminal end (`sprint_ended`, marker removed), or
  **supersession** — a supervisor holding a *different* run id takes a stale marker under 0153's
  unchanged rule and, in the same act, ends the run it names.

Which mechanism keys off what:

| # | Mechanism | Keys off | Fix |
|---|---|---|---|
| 1 | Resume cap | the **stage session id** and its leg count in the run log — not the sprint identity | re-pay excluded from scope spend, next leg's re-pay re-granted (FR1–FR2) |
| 2 | Marker | the **run id** in `held-by`, checked before age | own run id → retake whatever its age (FR3–FR4) |
| 3 | `sprint_ended` | the **run id** — terminal halts only, once per run log | written at the planned end, or by the superseding run (FR5–FR6) |
| 4 | Ledger | the **run id** in the block header | `record` replaces its own block, never appends a second (FR7–FR8) |

**Rejected:**

- **Each leg a new run linked by `continues: <run-id>`.** Every consumer — `sprints_since`, the
  ledger, the cap — would then need to group legs back into one sprint, which is the identity problem
  moved into three readers. Would win only if legs needed separate estimates; none do.
- **A graceful `sprint_suspended` write at each halt.** Two of the three interruptions in the source
  run (wrapper ceiling, host sleep) give the supervisor no turn to write anything. A rule that only
  works when the interruption is polite is not a rule. The suspension is instead *inferred* on resume
  from the marker's last heartbeat (FR4).
- **Keeping a suspended run protected from new runs indefinitely.** The marker is 0153's liveness
  signal and stays one; a suspended run that a person has not resumed within `lock_stale_seconds`
  can be superseded. That is the cost accepted (below).

**Trade-off accepted:** a person who starts a fresh `/sprint` while yesterday's run sits suspended
ends yesterday's run rather than continuing it — continuing needs the run id (FR3). It ends with a
recorded `sprint_ended` reason `superseded`, so it counts once and is never lost; what is lost is
only its chance to finish under its own name.

**Facts this rests on, re-read 2026-10-25 at 811130d:**

- `.claude/backlog/next` `sprints_since` breaks out of a log file on its first matching
  `sprint_ended` (`awk … exit`) and adds one per *file*, so two `sprint_ended` events in one log
  already count once. FR5's "once per run" therefore needs no change to `next`; it does need the
  resumed run to keep writing to its original log, which FR3 guarantees.
- `tools/sprint-ledger.sh` writes each block under `## sprint <run_id> -- ended <ts>`, `run_id` taken
  from the events' `run`/`run_id` field, and `read_ledger` splits on `## sprint ` — so a block is
  addressable by run id and FR7 is a replace, not a new format.
- The skill nowhere states how `RUN_ID` is minted; every run log observed is `run-<%Y%m%dT%H%M%SZ>`.
  FR3 writes that down, because an identity nobody specified is one a resumed conversation can
  re-mint by accident.
- `tools/harvest-usage.sh` reports per session and per run, not per leg; FR2 is new harvest surface.

**Constraints honoured:** 0153's liveness rule (heartbeat, 60 s, `lock_stale_seconds`) is unchanged for
every supervisor that does not hold the marker's run id. 0164's elapsed/active split is not decided
here: FR4 only adds the `supervisor_resumed` event carrying the gap's bounds, which 0164 may subtract
exactly as it subtracts `limit_hit`→`resumed` windows.

## Requirements

- FR1 — Step 7's resume cap for stage session S is `stage_cap − (spent_S − repaid_S) + repay_next_S`,
  where `spent_S` is the harvest's spend for S, `repaid_S` is the summed cost of the first priced
  turn of each **resumed** leg of S, and `repay_next_S` is the largest first-priced-turn cost among
  all of S's legs so far (the original leg included). Legs are split on S's `resumed` event
  timestamps in this run's log. The `resumed` event carries `cap`, `repaid` and `repay_next`.
  Where any leg of S is unpriced, the existing `cap_basis: "unpriced"` full-cap rule stands.
- FR2 — `tools/harvest-usage.sh` gains `--legs <session-id> --run <run-log>`, printing one line per
  leg of that session — leg number, start stamp, first-priced-turn USD, leg USD — so FR1's figures are
  read, never estimated.
- FR3 — Step 1 states how the run id is minted (`run-$(date -u +%Y%m%dT%H%M%SZ)`, once, at the run's
  start) and that a supervisor continuing a run reuses that id and that run log; `/sprint resume
  <run-id>` adopts it in a new conversation, taking `RUN_MODEL` from that log's `scope_confirmed`.
- FR4 — Step 1's busy branch checks the run id before the age: `held-by` naming the supervisor's own
  run id is retaken whatever its age — timestamp rewritten, a `supervisor_resumed` event logged
  carrying `suspended_at` (the marker's last heartbeat) and `resumed_at` — and is never reported as
  another supervisor or as stale. Any other run id goes through 0153's rule unchanged.
- FR5 — `sprint_ended` is written only at a terminal end, never at a suspension, and carries
  `reason`: `completed`, `stopped` (escalation or person), or `superseded`.
- FR6 — A supervisor taking over a stale marker naming another run id appends `sprint_ended` with
  `reason: "superseded"` and `by: <its own run id>` to that run's log if the log holds none, before
  writing its own `held-by`; and refuses to continue a run whose log already carries `sprint_ended`.
- FR7 — `sprint-ledger.sh record` replaces an existing `## sprint <run_id>` block for the same run id
  in place, leaving every other block byte-identical, and appends only when none exists.
- FR8 — Step 6 says `record` may be called at any halt the supervisor sees coming (a `limit_hit`
  wait included), since the latest call wins; it still must be called at the terminal end.

## Acceptance criteria

- [ ] AC1 — Given a run-log fixture where session S has an original leg (first turn USD 0.40) and two
  `resumed` legs (first turns USD 1.10 and 1.30), harvested spend 12.00 and stage cap 12.00, when the
  Step 7 cap is computed via `harvest-usage.sh --legs`, then it is 12.00 − (12.00 − 2.40) + 1.30 = 3.70.
  Red: today's rule gives 0.00.
- [ ] AC2 — Given a fixture with one unpriced leg of S, when the cap is computed, then the full stage
  cap is used and the `resumed` event names `cap_basis: "unpriced"`.
- [ ] AC3 — Given `held-by` naming run id R stamped 10 hours ago and a supervisor whose `RUN_ID` is R,
  when Step 1's busy branch runs, then it retakes the marker, rewrites the timestamp, and logs
  `supervisor_resumed` with `suspended_at` equal to the old stamp. Red: reported as stale and taken
  over.
- [ ] AC4 — Given the same marker and a supervisor whose `RUN_ID` is not R, when Step 1 runs, then
  0153's stale-takeover path runs unchanged and R's log gains exactly one `sprint_ended` with
  `reason: "superseded"` and `by` naming the new run.
- [ ] AC5 — Given R's log already holding `sprint_ended`, when a supervisor is asked to resume R, then
  it refuses and dispatches nothing.
- [ ] AC6 — Given a `runs/` fixture where one log carries two `sprint_ended` events after date D,
  when `./next` computes `sprints_since D`, then it counts 1. (Guards the existing behaviour FR5
  relies on.)
- [ ] AC7 — Given a `LEDGER.md` with blocks for runs A and B, when `record` runs twice for B with
  different actuals, then the file holds exactly one `## sprint B` block carrying the second call's
  figures and A's block is byte-identical. Red: two B blocks.
- [ ] AC8 — Given `skills/sprint/SKILL.md`, when grepped, then Step 1 names the run id format and the
  own-run-id check before the age check, Step 6 names `sprint_ended`'s three reasons and that `record`
  replaces its own block, and Step 7 names `repaid` and `repay_next`.

## Out of scope

- Preventing the interruptions. They are the environment, not a defect.
- Re-opening `findings_max_sprints` as the right second limit, which `config.yml` argues.
- Whether `supervisor_resumed` gaps are subtracted from active time — 0164's call.
- Ledger blocks for a run superseded before it ever called `record`: it keeps no block, as a killed
  supervisor's run does today.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park written by the supervisor of
  `run-20260920T222013Z`, which had hit all four in one run. Routed to `design` on the noticer's own
  framing: it is a design question before it is a defect.
- **2026-10-25 (design, token 82d1)** — Settled as above. The ticket arrived with no FRs or ACs;
  FR1–FR8 and AC1–AC8 are authored here. `qa_level` corrected from `verify` (not a level) to `unit`:
  every criterion is a fixture or a grep, as 0153 and 0164 are. `close_by: verify` added. `expects`
  gains `tools/harvest-usage.sh` (FR2) and `tests/sprint-ledger.test.sh` (AC1, AC2, AC7). Size stays
  `l`: three files of behaviour plus two test files. Ordering note for develop: 0164 also edits
  `record` and the `FIGURES` list; FR7's replace is independent of which figures a block carries, so
  either may land first.
- **2026-10-25 (develop, token fa94)** — Built in 9337f11, guard tightened in two follow-ups
  (AC7's outside-span comparison). What landed:
  - **FR1–FR2** — `tools/harvest-usage.sh --legs <sid> --run <log> [--stage-cap <usd>]` prints only
    `LEG n start <stamp> first USD x leg USD y` lines and, with a cap, one `CAP` line: `CAP 3.70 stage
    cap 12.00 spent 12.00 repaid 2.40 repay next 1.30`, or `CAP 12.00 cap basis unpriced` when any
    leg holds an unpriced turn (or no turn). The formula lives once, in the tool; Step 7 names the
    command and says the `resumed` event carries `cap`, `repaid`, `repay_next`. Output stays inside
    the harvest's aggregate-figures character set, so the words are spaced (`repay next`, `cap
    basis`) where the event's JSON keys are underscored. Leg 1 starts at the session's first turn;
    each later leg at its `resumed` event's `ts`/`at`.
  - **FR3–FR6** — Step 1's marker mkdir became one runnable `# step-1-marker` block: refusal of an
    ended `$RUN_ID` first (before `mkdir`, because an ended run has usually removed its marker, so
    a busy-branch-only check would never see AC5), then own-run-id retake with `supervisor_resumed`,
    then 0153's age rule, and on a stale takeover an append of `sprint_ended` `reason: superseded`,
    `by` — only if that log holds none. The tests RUN the extracted block, as 0153's heartbeat guard
    does, against fixture backlogs.
  - **FR7** — `record` writes through `write_block`: the span is the blank line before the heading
    to the blank line before the next `## ` heading (or EOF), exactly what it appends.
  - **AC6** — the guard is in `tests/next.test.sh` beside 0133's age cases, which own the scaffold
    helpers (`expects:` named only `tests/sprint.test.sh`; touches should have been widened to it).
  - **AC25 (0040) guard narrowed, not weakened**: it took "the first fenced block naming
    `lock_stale_seconds`" as Step 7's lock-age check; the new Step 1 block also reads that key, so
    the extraction now requires the block to name `.claude/backlog/.lock` as well.
  - Size: the sprint skill went 60,813 → 63,662 bytes, inside 0190's 5,000-byte margin.
- **Clause table and mutation sweep (all RUN, against committed code)** — each mutation was applied
  to the committed file, the owning suite run, and the file restored:

  | AC clause | Mutation | Result |
  |---|---|---|
  | AC1 `+ repay_next` | drop the re-grant | red (cap 2.40) |
  | AC1 `− (spent − repaid)` | subtract full spend | red (cap 1.30) |
  | AC1/FR2 per-leg lines | (tool absent) | red before build |
  | AC2 unpriced → full cap | ignore unpriced legs | red |
  | AC3 own id retaken at any age | own-id branch → `false` | red |
  | AC4 exactly one `sprint_ended`, `superseded`, `by` | reason → `stopped` | red |
  | AC4/FR6 not appended twice | drop the `grep -qs ||` | red |
  | AC4 0153 unchanged (fresh refused) | asserted directly; pre-build block took nothing | red before build |
  | AC5 refuse, dispatch nothing | drop refusal line | red |
  | AC6 counts 1 | count events in a two-ending log | red |
  | AC7 one B block | always append | red |
  | AC7 A byte-identical (and C, separators) | don't back off over C's leading blank | red after the tightening; green before it (gap found and closed) |
  | AC8 greps | — | each red before the prose was written |
