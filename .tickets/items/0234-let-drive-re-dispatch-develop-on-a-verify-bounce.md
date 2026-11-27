---
id: "0234"
title: Drive a whole outcome ticket through a sprint unattended, routing whatever stage it needs
type: feature
next: verify
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0231", "0153", "0170", "0204", "0050", "0054", "0059", "0134", "0136", "0137"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/config.yml
  - .tickets/next
  - skills/sprint/SKILL.md
  - skills/queue/SKILL.md
  - tests/next.test.sh
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - CHANGELOG.md
  - .tickets/items/0231-drive-one-outcome-ticket-across-slice-sessions-unattended.md
  - tests/sprint.test.sh
  - references/CONCURRENCY.md
  - skills/queue/templates/claim
  - .tickets/claim
  - tests/claim.test.sh
  - skills/develop/SKILL.md
claimed_by: "a7c3"
claimed_at: 2026-11-27T01:11:09Z
touches:
slice: S6
ac_digest: AC1=8d157b25 AC2=99cde558 AC3=7615f1f5 AC4=b8b5e381 AC5=e269ef8c AC6=07913581 AC7=ffd82fa5 AC8=e083f2f6 AC9=6515e3e2 AC10=ea7f7fcb AC11=c2fe5ce7 AC12=7626989e AC13=643d9a36 AC14=070405ec AC15=180d715f AC16=9a294489 AC17=355e6087 AC18=cdd8a9d7 AC19=b1b8bcf3 AC20=566f0ef0 AC21=1c7e5714 AC22=9e17d262 AC23=8a16a8ad AC24=d9075f16 AC25=8a9a83a7 AC26=7b99fe69 AC27=83fa4f4a AC28=c7101f36 AC29=8eb7c220 AC30=db7486fd AC31=5308ea25 AC32=92f40623
---

## Problem

**Outcome (merged 2026-11-26, at the user's direction):** a confirmed outcome ticket runs to `done` in one sprint with no person typing the next command: every leg is routed to the stage it needs, the supervisor's plumbing leaves nothing behind, and running develop legs in parallel has a decided answer.

In sprint run-20261118T074205Z, 0231's leg S5 failed verify on AC14, and
`./next --drive --completed verify:0231` exited 4 with
`ESCALATE  0231 bounced from verify back to next: develop — verify already decided whether the build or the contract was wrong, and re-developing blind spends a stage session rediscovering it`
(`skills/queue/templates/next`, the `--drive` bounce branch). The user's answer, verbatim:
*"going back and redeveloping when something fails is always the right choice. You do not need to ask
me first as the sprint coordinator I fully expect you to be able to handle situations like this on
your own."* The re-develop then cost one $0.66 session pointed at verify's diagnosis.

**This reverses a tested behaviour.** 0231's AC7 asserts "after the fail, exit 4 with the bounce
escalation" (`tests/sprint.test.sh`), so the change is a contract change on the user's call, not a
regression fix — the test is amended, not worked around. (The assertion is in `tests/next.test.sh`, not `tests/sprint.test.sh`; see FR10.)

**Widened 2026-11-18 from verify bounces to every stage the outcome needs** (the user's two quotes
are in *Notes & decisions*). Two more places still read as stops where the user wants routing:
`--drive` caps no re-entry into `design` (`skills/queue/templates/next`, the 0159 NOTE arm after
`--completed`, which carries a `ready` design row to the rank walk however many times it returns), and
a develop session that hands an in-scope row to `next: queue` reaches the stale-contract arm and
exits 4. And `skills/sprint/SKILL.md` Steps 3 and 7 present `stage_budget_usd` / `--max-budget-usd`
as the fixed figure a stage runs under ("never a figure chosen here"), with no rule for raising
one when the outcome needs a larger stage. ~~One stop stays: the envelope (`tools/sprint-ledger.sh
envelope`, 0231 FR13/AC14) and Step 7's account-session-limit pause.~~

**Reworked 2026-11-18 (fourth amend): no run budget or deadline stops a sprint.** 0231 FR13 built
`tools/sprint-ledger.sh envelope` to print `STOP` (exit 3) when the run's confirmed `budget_usd` or
`deadline` cannot cover the next stage's estimate. The user's answer (verbatim in *Notes &
decisions*) is that a budget is only a runaway catch for a session, never a reason to stop a sprint,
unless it is tied to a hard constraint — the account's own usage limit. Nothing checks that limit
before a dispatch today: Step 7 reacts after a stage has already hit *"You've hit your session
limit"*. Verified on this host 2026-11-18, `claude -p --output-format stream-json --verbose` emits a
`rate_limit_event` carrying `rate_limit_info.unifiedWindows.{five_hour,seven_day}`, each with a
`utilization` fraction and a `resetsAt` epoch — a fraction used per window, not tokens left. So the
envelope becomes a headroom gate over those windows (FR18, FR19, FR21), **changing 0231's delivered
contract (FR13, AC14) on the user's call**, and its 0231 tests are amended citing 0234 (FR22).

### Absorbed 2026-11-26: 0170 — Stop the marker heartbeat leaving an orphaned sleep child

Parked 2026-09-14, verbatim:

> The supervisor's hand-rolled marker heartbeat, stopped with `kill $BEAT`, left its `sleep 60`
> child orphaned under launchd. Killing the backgrounded subshell does not kill the `sleep` it is
> waiting on; `pkill -P $BEAT` before `kill $BEAT` stopped it cleanly on later dispatches.

Observed on run `run-20260913T222409Z`: a `sleep 60` with ppid 1 outliving the dispatch that
started it. `0153`'s executed guard asserts the loop stops, which it does — the leak is the child
the loop was blocked on, and no criterion looks for it. It is small and self-clearing within one
interval, and it is still a process nobody stops on purpose, in a skill whose conventions say to
stop what you started.

### Absorbed 2026-11-26: 0204 — Route a queue completion that re-specifies a waiting row to develop instead of exiting 4

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
`./next --drive --completed queue:<id>` exits 4 ("at next: develop / ready after queue, which no routing
rule covers") when a queue session re-specified an owner-ruled `waiting` row back to `develop ready`.
Re-calling with no `--completed` routed it normally, so the supervisor drops the flag by hand.
(quantum-catan run-20261010T144315Z, 0008 after queue session 15061e8a.)

### Absorbed 2026-11-26: 0137 — Decide whether two develop sessions may run at once, and in what isolation

Aaron, 2026-09-08: *"Orchestrate is welcome to run as many develop sessions at once as it feels
appropriate while avoiding potential conflicts with other agents."* Deferred the same day, after the
cost and safety analysis below, and recorded here rather than dropped.

**Parallel develop buys wall-clock and spends the two things this project ranks above it.** The
stated priority order is quality, then cost, then time. N parallel sessions each re-pay the roughly
20k-token startup floor, so they cost strictly more than the same N tickets sequentially and more
again than one gate holding all N — the saving the suite is built on. It buys only time.

**Three specific hazards, none of them hypothetical:**

- **The conflict predicate is a field the code labels unreliable.** `next`'s own comment: `touches:`
  is the claim verified against the code, while `expects:` is *"the prediction the ticket was written
  with"*. Only the prediction exists before dispatch.
- **Gates are not currently disjoint from each other** — `0136`, which is why this row is blocked on
  it. Dispatching two gates in parallel on today's partition can put two sessions in one file.
- **One working tree, one git index.** `CONVENTIONS_CORE.md` forbids `git add .` precisely because
  *"the index is one shared staging area"*. `config.yml` already records this biting with only
  hand-driven concurrency: verifying `0084`, another session's in-flight work reddened the
  alphabetically-first of seventeen guards and the fail-fast loop meant the guard that verdict rested
  on never ran.

The candidate that makes it sound is **one git worktree per parallel session**, which isolates the
code tree while leaving `.claude/backlog/` shared — and shared is correct there, since `claim`,
`close` and the lock are built for it. That is a subsystem, not a flag.


## Functional requirements

- FR1 — **The bounce re-dispatches.** `./next --drive --completed verify:<id>` where the row now
  reads `next: develop` / `ready`, and the arm in `skills/queue/templates/next` that today decides
  `ESCALATE  <id> bounced from verify back to next: develop …` is reached, prints
  `DISPATCH  develop <id>` and exits 0 while the bounce count (FR3) is at or under the bound (FR2).
  The re-dispatch is the bounced ticket alone — verify bounced one ticket, so no gate is assembled
  around it — and it goes through the same findings gate and held-design-file wait every develop
  dispatch takes (`dispatch_leg` already does both; reuse it rather than restating them). This holds
  for a sliced ticket whose named slice is unticked (`leg_state` = `bounced`) and for an unsliced
  one alike. The `started_leg` comment saying "the bounce is a person's" is corrected with it.
- FR2 — **The bound is a config key.** `bounce_max:` in `config.yml`, read the way
  `read_gate_max_rows` reads `gate_max_rows`: absent means **2**; a whole number of 0 or more is
  the bound; anything else is a malformed config (exit 1, naming the key and the value). **0 is
  legal and means every bounce escalates** — the pre-0234 behaviour, kept reachable as the rollback.
  (A develop → design hand-off with no `--bounces` entry is not bounded at all, FR16, so 0 leaves
  it dispatching as before 0234 too.)
  `skills/queue/templates/config.yml` ships the key at 2 with a comment saying what it counts and
  that 0 restores escalate-on-every-bounce.
- FR3 — **The count is the supervisor's, passed in.** `--drive` is stateless, so it takes
  `--bounces <id>=<n>` (repeatable, one per id; `<id>` four digits and `<n>` a whole number of at
  least 1, else a usage error exiting 2, as `--started` and `--scope` refuse a malformed id; a
  second value for an id already given is a usage error too). `<n>` is the number of consecutive
  verify fails of that ticket in this run **including the one `--completed` reports** — counted
  from the run log's verify outcomes for that id since its last verify `pass`. **Widened by FR16:**
  `<n>` counts every **re-entry** of that ticket since its last verify `pass`, including the one
  `--completed` reports — an outcome for that id whose `next` names an earlier stage than the one
  that ran (verify → develop, queue or design; develop → queue or design) — so one allowance covers
  every loop back, whichever stage it went to. A verify → develop → verify → develop run still
  counts 1, 2, as before. Only the
  `--completed` id's entry is read; an absent entry for it counts as 1. Past the bound
  (`n > bounce_max`) the arm exits 4 with a line naming the id, the count and the bound:
  `ESCALATE  <id> bounced from verify <n> time(s) in this run, past bounce_max <max> — …`.
- FR4 — **Where the diagnosis is.** Before the `DISPATCH` line of a bounce, `--drive` prints one
  `NOTE` naming the bounce, the count against the bound, and the ticket's item file as where verify
  recorded the fail: `NOTE      <id> bounced from verify (<n> of <max>) — re-dispatching develop;
  verify's diagnosis is in <item path>`. `--drive` never sees the stage outcome, so it cannot print
  verify's `detail` pointer; the item path is what it already holds (`item_for`), which is the
  cheap half. The `DISPATCH` line itself is unchanged in shape, since drivers parse it.
- FR5 — **A contract-wrong bounce of an in-scope row dispatches `queue`, inside the same cap.** A
  verify that finds the contract wrong (an unmeetable, contradictory or drifted AC) hands to
  `next: queue` (`skills/verify/SKILL.md` Step 5, `./handoff <id> <token> queue`), and a build fault
  hands to `next: develop`. That hand-off target stays the discriminator — never the supervisor's
  reading of the fail. When `./next --drive --completed verify:<id>` finds the row at `next: queue` /
  `ready` **and `<id>` is in `--scope`**, it prints `DISPATCH  queue <id>` (a re-specify that
  repairs the criteria and returns the row to develop) and exits 0 while FR3's count is at or under
  FR2's bound; past it, it exits 4 with FR3's `ESCALATE  <id> bounced from verify <n> time(s) …`
  line. **One cap for the whole cycle, not a second allowance:** `<n>` is FR3's count unchanged —
  consecutive verify fails of that ticket in this run, whichever target each handed to — and the
  queue session and the develop after it add nothing to it, so verify fail → queue → develop →
  verify fail is `n = 2`. There is no separate key. Before the `DISPATCH` line it prints one `NOTE`:
  `NOTE      <id> bounced from verify to next: queue (<n> of <max>) — dispatching queue to repair the
  contract; verify's diagnosis is in <item path>`. The dispatch takes `findings_gate gate` as FR1's
  does (which, given `--scope`, defers while scope work remains) and no held-design-file wait,
  since a queue session writes only `.tickets/`. The new arm sits above the existing `next: queue`
  arm and is keyed on the completed stage being `verify`, so a queue session's own hand-off never
  re-dispatches queue (FR14). `bounce_max: 0` escalates, as for a develop bounce. **Widened:** the
  same arm takes a completed `develop` that handed an in-scope row to `next: queue` / `ready` (a
  build session finding the criteria unmeetable mid-run), with the same count, bound, NOTE (naming
  the completed stage) and gate; an absent `--bounces` entry counts as 1 there too, so
  `bounce_max: 0` escalates it exactly as before 0234. The completed stage being `verify` **or
  `develop`** is the key, never `queue` (FR14's loop guard).
- FR6 — **`--help` and the usage line** in `skills/queue/templates/next` name `--bounces <id>=<n>`
  and `bounce_max`, beside `--started`, saying what the count is and who supplies it.
- FR7 — **`skills/sprint/SKILL.md` Step 2** says a verify bounce (`next: develop` after
  `--completed verify:<id>`) is routed, not escalated, up to `bounce_max`; says the supervisor
  passes `--bounces <id>=<n>` for the completed id on every call after a verify, counted from its
  run log as FR3 defines; and says an exit 4 past the bound is the cap, which is a person's.
  It also says a contract-wrong bounce of an in-scope row (`next: queue` after `--completed
  verify:<id>`) is routed to a `queue` repair under the same `bounce_max` and the same count (FR5),
  that the supervisor reports the repair's finish as `--completed queue:<id>` and `--drive` then
  routes as usual (FR13), and that a repair handed to `waiting` or left at `next: queue` is a
  person's (FR14). The out-of-scope case stays an escalation (FR12).
- FR8 — **`skills/sprint/SKILL.md` Step 3 or Step 4** (wherever the develop prompt is composed):
  a develop dispatch that follows a bounce carries verify's outcome `detail` pointer for that ticket
  and the failed AC named from it — Step 4's existing "open the `detail` pointer of every `fail`"
  rule now feeds the develop prompt as well as any report to a person. **The FR5 `queue` dispatch
  prompt carries the same two**, names the operation as a re-specify of `<id>` that repairs the
  failed criteria and returns the row to `develop`, and states FR14's hand-off for the case where
  only a narrowing would make the criteria meetable.
- FR9 — **`skills/sprint/SKILL.md` Step 8, and every list in Steps 2 and 4 that enumerates what
  escalates**, state the principle as one sentence: **the supervisor escalates only what needs a
  person's judgment — narrowing the outcome, a release action, repeated failure past `bounce_max`,
  a cap kill — and routes every stage the confirmed outcome needs (a `design` session, a `queue`
  repair, a re-develop, a verify) itself**, because an unattended run stalls on every question
  until the person checks in and the goal is the outcome confirmed at the start, not the least
  spend. What is a person's by another rule stays so and is named beside it, not folded in: a row a
  stage left `waiting`, an aged lock, and new work outside the confirmed scope. An account-headroom
  `WAIT` (FR19) is neither an escalation nor a stop: the run waits for the reset and goes on. Step 8's "Queuing new work and designing tickets are escalations" becomes: queuing work
  outside the confirmed scope is an escalation; designing or re-specifying an in-scope ticket is
  routed. Where an existing escalation list names a verify bounce, it is removed from that list.
  **Step 8's escalation list and its exception change with FR5:** "an in-scope `next: queue` row"
  becomes a `next: queue` row no in-scope verify bounce sent there, plus a repair that would narrow
  the outcome; the sentence that today makes the proposal's *repair first* "the one exception" names
  two exceptions — that one, and FR5's contract repair, which the person answered in advance by
  confirming the scope (the reversal quoted in *Notes & decisions*). Step 8's "never … narrows a
  contract" stays true and gains one sentence saying why: a repair corrects a contradictory,
  unmeetable or drifted statement of an outcome the ticket keeps, which is not narrowing it, and
  where repair ends and narrowing starts is `skills/queue/SKILL.md`'s (FR15), not restated. Prose,
  and per this repo's `CLAUDE.md` *Tests* it gets **no prose guard**.
- FR10 — **The two tests asserting the old contract are amended, citing 0234** — both live in
  `tests/next.test.sh`, not `tests/sprint.test.sh` (checked 2026-11-18: `tests/sprint.test.sh`
  asserts no bounce behaviour): the `0038 AC9 — verify bounced the ticket back to develop/ready:
  escalate` block and the `0231 AC7 — after a leg verify fails, the bounce escalation stands` block.
  Each now asserts the dispatch; the old escalation is asserted only under FR2's `bounce_max: 0`
  and past the bound. The `0038 AC9 … stale contract` block is not edited: it passes no `--scope`,
  so it now exercises FR12 and must stay green as it stands.
- FR11 — **The shipped copy reaches this repo's driver**: `.tickets/next` is re-copied from the
  template byte-for-byte (`skills/queue/SKILL.md` Step 0), and `CHANGELOG.md`'s `## Unreleased`
  gains one note per behaviour sessions will now see differently: the develop re-dispatch, the
  in-scope queue repair, the design re-entry bound, per-stage caps as raisable runaway catches, and
  the headroom gate — `envelope` no longer stops a run on `budget_usd` or `deadline` but waits on
  account headroom, stages dispatch with `stream-json`, and `reading`/`outcome` are new modes. The
  existing 0231 bullet saying `/sprint` "asks `tools/sprint-ledger.sh envelope` before every
  dispatch, ending at a clean boundary on `STOP`" is unreleased (it sits under `## Unreleased`), so it
  is corrected in place to the new behaviour rather than contradicted by a second bullet.
- FR12 — **Outside the confirmed scope, a stale contract still escalates as today.** A row at
  `next: queue` after `--completed verify:<id>` where `<id>` is not in `--scope` — including a call
  with no `--scope` at all, which has no confirmed outcome to finish — and a row at `next: queue`
  after any stage other than `verify` or `develop` (FR5 as widened), reach the existing arm unchanged:
  `ESCALATE  <id> went back to next: queue after <stage> — the contract is stale …`, exit 4.
- FR13 — **After the repair, routing is ordinary.** `./next --drive --completed queue:<id>` where
  the row now reads `next: develop` / `ready` reaches no escalation arm; the rank walk dispatches it
  as after any stage that moved a row on, so with `<id>` the only takeable in-scope row the call
  prints `DISPATCH  develop <id>` and exits 0. No new arm is expected; the build confirms none of
  the existing arms catches this shape and adds one only if one does. (A re-specify that leaves
  every FR's code standing may set `next: verify` instead, per `skills/queue/SKILL.md` Step 2; the
  rank walk routes that the same way.)
- FR14 — **A narrowing is a person's, and the hand-off says so mechanically.** A queue session
  dispatched by FR5 that finds the criteria can be made meetable only by narrowing the outcome
  (FR15) writes no criteria: it sets `status: waiting`, leaves `next: queue`, writes `## Waiting on`
  naming the AC and the narrowing a person must choose between, and reports the same one sentence
  in its outcome's `escalation`. `--completed queue:<id>` then reaches the existing `waiting` arm —
  exit 4 with no `--scope`; with `--scope`, the existing NOTE and the rank walk's exit 4 once
  nothing else in scope is takeable (0231 FR9) — so no new arm is needed. A queue session that
  leaves the row at `next: queue` / `ready` without that hand-off reaches FR12's arm (the completed
  stage is `queue`, not `verify`) and escalates too: a repair that did not happen never loops.
- FR15 — **`skills/queue/SKILL.md` distinguishes repair from narrowing**, in Step 1's *Re-specify*
  bullet: a re-specify **repairs** when it corrects a contradictory, unmeetable or drifted statement
  of an outcome the ticket keeps — a wrong path, a fixture that cannot reproduce the case, two ACs
  that contradict, figures that cannot discriminate — and **narrows** when it removes an AC, weakens
  what an AC's outcome asserts, or moves an FR's scope to *Out of scope*. A repair is written and
  recorded in *Notes & decisions* as one line saying what was corrected; a narrowing in a session
  with no person in it (a sprint's `claude -p` dispatch) is not written, and takes FR14's hand-off
  instead. Prose, no guard (`CLAUDE.md` *Tests*).
- FR16 — **A re-entry into `design` spends the same allowance.** In the arm of
  `skills/queue/templates/next` that today prints `NOTE      <id> is at next: design after <stage>
  — design is autonomous work; carrying on to the rank walk` (row at `design` / `ready`, completed
  stage not `design`): when the completed stage is `verify`, `<n>` is FR3's count with an absent
  entry counting as 1; when it is `develop` and `--bounces` names the id, `<n>` is that value; past
  the bound (`n > bounce_max`) it exits 4 with `ESCALATE  <id> went back to next: design <n> time(s)
  in this run, past bounce_max <max> — …` and no `DISPATCH`. At or under the bound, or after a
  `develop` with no entry for the id, the arm is unchanged: the NOTE, then the rank walk, which
  dispatches the design row (in scope, by 0188 FR5's design-first loop). A develop → design hand-off
  with no `--bounces` entry is therefore unbounded exactly as before 0234, and the supervisor
  bounds it by passing the count (FR7). The design session itself stays the one that decides or,
  on taste, architecture or security, leaves the row `waiting` (`design` Step 3), which the existing
  `waiting` arm escalates.
- FR17 — **Per-stage caps are runaway catches, not budgets; the proposal's estimate is a forecast,
  not a stop.** `skills/sprint/SKILL.md` Step 3 (beside the startup-floor paragraph) and Step 7's
  closing paragraph say: `stage_budget_usd` is the default `--max-budget-usd` and exists to catch a
  runaway session; the supervisor **may raise a stage's cap for a dispatch** — a larger gate, a
  re-dispatch after a bounce, a stage whose run-log mean already exceeds the default — **and may add
  sessions the proposal did not forecast** (a design, a queue repair, another develop) when the
  confirmed outcome needs them, logging each raise **before** that dispatch as one `cap_raised`
  run-log event carrying `stage`, `ids`, `session_id`, `from`, `to` and `reason`. Step 7's "never a
  figure chosen here" is corrected to say the *default* is derived and recorded in `config.yml`,
  and a raise is the logged exception. The proposal section says the estimate is a forecast the
  run is scored against (Step 6's `record`), not a ceiling, and **no run budget or deadline stops
  the sprint**: Step 1 still records `budget_usd` and `deadline` on `scope_confirmed` as that
  forecast, and nothing reads them as a stop. A stage hitting its cap is stopped and assessed (Step
  7); the supervisor may raise caps when the outcome needs it. **A cap kill is unchanged**: still Step
  7's escalation (claim token, dirty paths, lock state, start nothing further), because that is what
  a runaway looks like — the remedy is the person's, never a raise-and-retry by the supervisor.
  `skills/queue/templates/config.yml`'s `stage_budget_usd` comment says the same in one line.
- FR18 — **Reading headroom and the outcome from a stage's stream.** *(Replaces the earlier FR18,
  "the envelope prices an unpriced outcome at its `cap_raised` cap": the envelope no longer sums
  spend, so there is nothing left to price. `cap_raised` stays FR17's log record.)*
  `tools/sprint-ledger.sh` gains two read-only modes over a captured
  `claude -p --output-format stream-json --verbose` stdout (one JSON object per line):
  - `reading --stream <file> --stage <stage> --session <id> [--now <iso>]` prints exactly one
    line, a run-log `headroom` event: `{"event":"headroom","stage":…,"session_id":…,"at":<iso now>,
    "windows":{"<name>":{"utilization":<0..1>,"resets_at":<iso>}, …}}`, built from the **last**
    line whose `type` is `rate_limit_event`. Windows come from `rate_limit_info.unifiedWindows`
    (every key it holds, each `utilization` and `resetsAt`); where that object is absent, the one
    window named by the top-level `rateLimitType` with its `utilization` and `resetsAt`. A stream
    holding no readable `rate_limit_event` (none at all, or one whose `utilization` or `resetsAt` is
    missing or not a number) prints `{"event":"headroom",…,"readable":false,"reason":"<what was
    missing>"}` and **exits 0** — an unreadable reading is a fact to log, not an error. A `--stream`
    path that does not exist exits 1. Non-JSON lines in the stream (CLI warnings) are skipped.
  - `outcome --stream <file>` prints the stage outcome as one JSON line: the `structured_output`
    object of the stream's last `type: result` line. No such line, or one with no
    `structured_output`, exits 1 naming which. Step 4 then validates that line exactly as it
    validates the last `{` line today.
- FR19 — **`envelope` becomes the account-headroom gate.** `tools/sprint-ledger.sh envelope --run
  <run log> --stage <stage> [--now <iso>]` no longer reads `budget_usd`, `deadline`, outcome costs,
  `--config` or `--measurement`, and never prints `STOP`. From the run log's `headroom` events
  (FR18) it decides:
  - **The reading** is the last `headroom` event. A window whose `resets_at` is at or before now
    counts as `utilization` 0 (it has reset since the reading).
  - **A stage's expected cost per window** is the mean of this run's samples for that stage, where a
    sample is the rise in a window's `utilization` between two consecutive readable `headroom`
    events with the same `resets_at` for that window, attributed to the later event's `stage`. A
    fall, or a changed `resets_at` (the window reset in between), is no sample. With no sample, the
    default: `0.10` for `five_hour`, `0.02` for `seven_day`, `0.10` for any other window, as named
    constants in the script.
  - **CONTINUE** (exit 0) when, for every window, the expected cost is less than `1 − utilization`,
    both rounded to 6 decimal places before comparing (`1 − 0.98` is not `0.02` in a float);
    it prints one `ENVELOPE  <window>  utilization <u> headroom <1−u> expected <c>  source: <run log,
    n <stage> sample(s) | default>` line per window, then `CONTINUE  <stage> fits the account
    headroom`.
  - **WAIT** (exit 3, the code `STOP` used) when any window's expected cost is at or above its
    headroom: the same `ENVELOPE` lines, then `WAIT  <window> headroom <h> < expected <c>; resets
    <iso>` naming every short window, ending `— resume after <iso>` with the latest reset among them.
  - **Not visible** (exit 0) when the run log holds no `headroom` event or the last one is
    `"readable":false`: `CONTINUE  headroom not visible — <reason>; no stop, relying on Step 7's
    limit_hit pause`. A gate that cannot see headroom never stops anything.
  - Exit 1 stays an unreadable run log (a line that is not JSON, a `headroom` event whose window
    lacks `utilization` or `resets_at`), so a supervisor never mistakes a log it could not read for
    a wait. A run log with no `scope_confirmed`, or one without `budget_usd`/`deadline`, is no
    longer an error.
- FR20 — **`skills/sprint/SKILL.md` Step 2 routes every stage the outcome needs**, in one paragraph
  beside FR7's: a scope row sent to `next: design` mid-run (by verify, by develop, or a design
  question a develop session discovered) is dispatched to `design` under FR16's bound, and the
  supervisor passes `--bounces <id>=<n>` after any outcome that re-entered a ticket (FR3 as widened),
  not only after a verify; and a develop session's hand-off of a scope row to `next: queue` is
  FR5's repair, as a verify's is.
- FR21 — **`skills/sprint/SKILL.md` runs the gate.** Prose, no guard (`CLAUDE.md` *Tests*):
  - **Step 1's probe** dispatches with `--output-format stream-json --verbose`, captured under
    `.tickets/runs/`; the supervisor runs `outcome --stream` on it (the host can drive a loop only
    if that yields a schema-valid outcome, as today) and appends `reading --stream`'s line — the
    run's first `before` reading. **If the probe's stream yields no outcome through `outcome
    --stream`, the run dispatches every stage as today (no stream) and the gate runs blind**, saying
    so once in the run log, rather than refusing to drive.
  - **Step 3's command** gains `--output-format stream-json --verbose`; the `.out` capture now holds
    the stream. **Step 4** reads the outcome as `outcome --stream`'s line, validated as before;
    every other Step 4 rule (all you read is the outcome, the `detail` pointer of every `fail`)
    stands — the stream's other lines are read only by `reading`, never as the stage's report.
  - **After each stage**, the supervisor appends `reading --stream`'s `headroom` line to the run log
    beside the `outcome` event. It is that stage's *after* and the next stage's *before*; utilisation
    before and after each stage is therefore in the log, and `envelope` learns each stage's cost from
    it (FR19).
  - **Step 2's "before every dispatch" paragraph** calls `envelope --run <run log> --stage <stage>`:
    `CONTINUE` dispatches; `WAIT` logs a `headroom_wait` event (`windows`, `until`), waits until the
    named time (Monitor with an until-loop, never a foreground sleep), asks `envelope` again and
    dispatches on `CONTINUE` — **a WAIT never ends the run** and is not an escalation; exit 1 is an
    unreadable log and stops the run as today. Its "leave margin" sentence about understated spend
    goes, since the gate no longer sums spend.
  - **Step 7's account-session-limit paragraph** stays as the reactive fallback (`limit_hit`, then
    `resumed`), and says it is what still catches a limit where the gate could not see headroom
    (API-key auth, a host that emits no `rate_limit_event`) or where a stage ran over its expected
    cost.
  - **Step 1's envelope paragraph** says `budget_usd` and `deadline` are the forecast the person
    confirms and the run is scored against, not a stop (FR17), and drops "refuse an envelope that
    cannot hold one develop leg plus its verify" in favour of saying so as a forecast.
- FR22 — **0231's envelope tests are amended, citing 0234.** In `tests/sprint-ledger.test.sh`, the
  `0231 AC14` and `0231 FR13` blocks (the budget STOP, time STOP, no-prior cap, STOP-versus-error,
  past deadline and unpriced-outcome cases) assert 0231's delivered contract, which this ticket
  changes on the user's call. Each block is replaced by the FR19 assertion it becomes, its header
  naming `0234` and the 0231 case it supersedes; the short-budget and past-deadline fixtures stay,
  now asserting no `STOP` (AC22). 0231's item file gains one dated line in *Notes & decisions*
  pointing at 0234 as where its FR13/AC14 contract changed; its ticked ACs and `ac_digest:` are not
  edited, being the record of what was verified then.
- FR23 *(was 0170 FR1)* — The Step 3 heartbeat snippet kills the loop's descendants before the loop itself.
- FR24 *(was 0170 FR2)* — A committed guard asserts no descendant of the heartbeat survives the snippet's own stop.
- FR25 *(was 0137 FR1)* — Whatever shape is chosen, the skill states the priority order it was chosen under, so a later
  reader does not re-open it on wall-clock grounds alone.
- FR26 *(was 0137 FR2)* — If parallelism is permitted, the rule names what a session does when it discovers another is
  working the same file — the case `0054` covers for a shared dirty tree.
- FR27 *(was 0137 FR3)* — If parallelism is declined, that is recorded as a decision with its reasoning, not left as an
  absence.
- FR28 *(S6)* — **One develop session at a time, in every project these scripts run in.** `./claim <id> [token]` on a
  row at `next: develop` refuses when any other row at `next: develop` is held — its item's `claimed_by:` non-empty —
  by a token other than the one this call claims with. The refusal is decided under the lock and before any write,
  names each holder's id and token on stderr, exits 1, releases the lock, and leaves `QUEUE.md`, the item and `HEAD`
  as they were. A call carrying the holder's own token is not refused: that is how one develop session claims the
  several rows of its gate. A claim at any other stage is not affected by this rule.
- FR29 *(S6)* — `./next --drive` prints no `DISPATCH  develop` while any row at `next: develop` is held or
  `in-progress`, on every path that would otherwise print one — the rank walk's gate, the started-leg dispatch and the
  post-bounce re-dispatch alike. It decides `WAIT` (exit 6, the code `wait_on_design` already uses) with a line naming
  each running develop id. Design and verify dispatch are unchanged: design beside a develop session stays permitted
  (0134, *Design beside other stages*).
- FR30 *(S6)* — `skills/develop/SKILL.md`'s claim step says a gate claims every row after the first with the token
  the first `./claim` printed, and that FR28's refusal is the designed wait (`CONCURRENCY.md`): claim nothing,
  report the holder's id and token, and stop or take work at another stage.
- FR31 *(S6; discharges FR25 and FR27)* — The decision is stated where it is read. `references/CONCURRENCY.md`,
  *The working tree is shared too*, replaces "`develop` is serialised in this repo by design until `0137` decides
  otherwise" with the settled rule: one develop session at a time in every project, enforced by `./claim` (FR28) and
  `--drive` (FR29); the priority order it was chosen under (quality, then cost, then time — wall-clock is the axis
  allowed to vary); and the two rejected candidates, each with the reason it lost (*Notes & decisions*, S6). In
  `skills/sprint/SKILL.md`, *Design beside other stages* and Step 8's "never runs two stage sessions at once" cite
  `0234` S6 in place of "`0137` declines it" and say the scripts enforce it. FR26 does not apply, parallelism being
  declined.
- FR32 *(S6)* — `.tickets/claim` and `.tickets/next` are re-synced from their templates, and `CHANGELOG.md`'s
  `## Unreleased` carries one entry: a second develop claim, or a develop dispatch beside a running develop, is now
  refused or waited on.


## Non-functional requirements

| Dimension | This item must satisfy | How it would red | Convention |
|---|---|---|---|
| Testing | Every new `--drive` behaviour is a behaviour test in `tests/next.test.sh`, every `reading`/`outcome`/`envelope` behaviour one in `tests/sprint-ledger.test.sh` over fixture streams and run logs the test builds, as its `$ENV` fixtures do today, and each amended assertion was seen red against the old code before it changed | AC1 and AC13 against the unmodified script (both arms still escalate) fail `exits 0`; AC4, AC14 and AC19 with `-gt` mutated to `-ge` fail; AC22's short-budget case against the unmodified `envelope` prints `STOP`; AC22's boundary with `<` mutated to `<=` fails | testing-conventions.md |
| Reliability | A gate that cannot see headroom never stops a run, and a wait always has a time to resume at | AC22's not-visible cases exiting non-zero, or a `WAIT` line with no `resume after <iso>`, fail | testing-conventions.md |
| Progressive delivery | Other machines run this script after a release; the old behaviour stays one config line away | AC3 (`bounce_max: 0` escalates) fails if 0 is rejected or treated as "unbounded" | progressive-delivery-conventions.md |

## Acceptance criteria

- [ ] AC1 — Given an unsliced row 0101 at `develop` / `ready` and no `bounce_max:` in `config.yml`, when `./next --drive --completed verify:0101` runs with no `--bounces`, then it exits 0, prints `DISPATCH  develop 0101`, and prints no `ESCALATE`. Red: the bounce arm left as it is (exits 4). Test: `tests/next.test.sh`, the amended `0038 AC9 — verify bounced …` block.
- [ ] AC2 — Given the sliced fixture of `0231 AC7 — after a leg verify fails` (S2 named and unticked, handed off from verify), when `./next --drive --completed verify:0911` runs, then it exits 0 and `dispatch_line` is `DISPATCH  develop 0911`. Red: the bounce arm left as it is. Test: the amended `0231 AC7` block in `tests/next.test.sh`.
- [ ] AC3 — Given AC1's fixture with `bounce_max: 0`, when the same call runs, then it exits 4 with a line containing `ESCALATE  0101 bounced from verify` and no `DISPATCH`. Red: 0 rejected as malformed (exit 1) or read as "no bound" (exit 0). Test: `tests/next.test.sh`.
- [ ] AC4 — Given AC1's fixture with `bounce_max: 2`, when the call carries `--bounces 0101=2`, then it exits 0 with `DISPATCH  develop 0101`; and when it carries `--bounces 0101=3`, then it exits 4 with a line containing `0101`, `3` and `bounce_max 2`, and no `DISPATCH`. The pair is the boundary: `n = max` dispatches, `n = max + 1` escalates. Red: the comparison mutated `-gt` → `-ge` reds the first half; dropping the bound reds the second. Test: `tests/next.test.sh`.
- [ ] AC5 — Given AC1's fixture with `bounce_max: 2`, when the call carries `--bounces 0102=9 --bounces 0101=1`, then it exits 0 with `DISPATCH  develop 0101` — another id's count is not read. Red: an implementation reading the first or the largest `--bounces` value escalates. Test: `tests/next.test.sh`.
- [ ] AC6 — Given AC1's fixture, when `--bounces` is given as `101=1`, `0101=0`, `0101=x`, `0101` (no `=`), or `0101=1 --bounces 0101=2`, then each exits 2. And given `bounce_max: two` (and, separately, `bounce_max: -1`), the AC1 call exits 1 and names `bounce_max`. Red: any of the seven accepted. Test: `tests/next.test.sh`.
- [ ] AC7 — Given AC4's dispatching case, then the output carries a `NOTE` line before the `DISPATCH` line containing `0101`, `2 of 2` and the fixture's item path `.tickets/items/0101-`. Red: the NOTE omitted, or printed after the DISPATCH line. Test: `tests/next.test.sh`.
- [ ] AC8 — Given AC1's fixture with `findings_threshold: 2`, two `FINDINGS.md` entries and `--scope 0102` naming no takeable row (so no confirmed-scope work remains), when `./next --drive --completed verify:0101 --scope 0102` runs, then it exits 5 and prints no `DISPATCH  develop` — the bounce re-dispatch takes the findings gate like any develop dispatch. Red: a re-dispatch that decides `DISPATCH` without `findings_gate gate` (exits 0). Test: `tests/next.test.sh`.
- [ ] AC9 — Given a row 0101 at `queue` / `ready` and `bounce_max: 2` with `--bounces 0101=1`, when `./next --drive --completed verify:0101` runs with no `--scope`, and again with `--scope 0102` only (0102 a ready develop row), then each exits 4 with `the contract is stale` and no `DISPATCH  queue`. Red: FR5's arm made blind to `--scope` (it dispatches queue). Test: the unedited `0038 AC9 — … stale contract` block plus two new cases beside it in `tests/next.test.sh`.
- [ ] AC10 — Given the change, when `diff skills/queue/templates/next .tickets/next` runs, then it prints nothing; and `./next --help` names `--bounces` and `bounce_max`. Red: the project copy not re-synced, or the help left unchanged. Checked by running both commands at verify.
- [ ] AC11 — Given `skills/sprint/SKILL.md` after the change, when verify reads Step 2, the step that composes the dispatch prompts, Step 4 and Step 8, then: Step 2 routes a develop bounce up to `bounce_max` and says how `--bounces` is counted and passed (FR7), and routes an in-scope contract-wrong bounce to a `queue` repair under the same bound and count, with `--completed queue:<id>` after it (FR7); a post-bounce develop dispatch and the FR5 queue dispatch both carry verify's `detail` pointer and the failed AC, and the queue prompt names the repair and FR14's hand-off (FR8); Step 8 states the escalate-only-what-needs-judgment principle with FR9's four examples (narrowing the outcome, a release action, repeated failure past `bounce_max`, a cap kill), "routes every stage the outcome needs" and the reason, says designing or re-specifying an in-scope ticket is routed while queuing work outside the scope is an escalation, lists a narrowing repair and an out-of-scope `next: queue` row as escalations, names two exceptions where it named one, and keeps "never narrows a contract" with the repair-is-not-narrowing sentence (FR9); and no list of escalations in Steps 2, 4 or 8 still names a verify bounce or an in-scope contract-wrong bounce. Red: any of these missing, a bounce still listed as an escalation, or "the one exception" left singular. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.
- [ ] AC12 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it exits 0. Red: any amended or neighbouring assertion left on the old contract.
- [ ] AC13 — Given a row 0101 at `queue` / `ready`, no `bounce_max:` in `config.yml`, and no `--bounces`, when `./next --drive --completed verify:0101 --scope 0101` runs, then it exits 0, prints `DISPATCH  queue 0101` and no `ESCALATE`, and a `NOTE` line before the `DISPATCH` line contains `0101`, `next: queue`, `1 of 2` and `.tickets/items/0101-`. Red: the stale-contract arm left as it is (exits 4), or the NOTE omitted or printed after the DISPATCH. Test: `tests/next.test.sh`.
- [ ] AC14 — Given AC13's fixture with `bounce_max: 2`, when the call carries `--bounces 0101=2`, then it exits 0 with `DISPATCH  queue 0101`; when it carries `--bounces 0101=3`, then it exits 4 with a line containing `0101`, `3` and `bounce_max 2` and no `DISPATCH`; and given `bounce_max: 1` with `--bounces 0101=2` (one earlier fail handed to develop, this one to queue), then it exits 4 with no `DISPATCH` — the queue repair spends the same allowance as a develop re-dispatch. And given `bounce_max: 0` with no `--bounces`, it exits 4 with no `DISPATCH`. Red: the queue arm reading no bound or a separate one (the third and fourth halves dispatch), or `-gt` mutated to `-ge` (the first half escalates). Test: `tests/next.test.sh`.
- [ ] AC15 — Given a row 0101 at `develop` / `ready` and `--scope 0101`, when `./next --drive --completed queue:0101` runs, then it exits 0, prints `DISPATCH  develop 0101`, and prints no `ESCALATE`. Red: the stale-contract arm keyed on the completed stage being `queue` rather than on the row reading `next: queue` (it escalates). Test: `tests/next.test.sh`.
- [ ] AC16 — Given a row 0101 at `queue` / `waiting` with a `## Waiting on` section, when `./next --drive --completed queue:0101` runs with no `--scope`, then it exits 4 with an `ESCALATE  0101 is waiting on a person` line and no `DISPATCH`; with `--scope 0101` and nothing else in scope, it exits 4 with no `DISPATCH`. And given 0101 at `queue` / `ready` with `--scope 0101` and `--bounces 0101=1`, when `--completed queue:0101` runs, then it exits 4 with `the contract is stale` and no `DISPATCH  queue`. Red: FR5's arm keyed on the row alone rather than on the completed stage being `verify` (the third half re-dispatches queue on a queue session's own hand-off, which loops). Test: `tests/next.test.sh`.
- [ ] AC17 — Given `skills/queue/SKILL.md` after the change, when verify reads Step 1's *Re-specify* bullet, then it defines a repair and a narrowing as FR15 does, says a repair is recorded in *Notes & decisions*, and says a narrowing in a session with no person in it takes FR14's hand-off (`status: waiting`, `next: queue`, `## Waiting on`, the outcome's `escalation`) instead of being written. Red: the distinction missing, or a sprint-dispatched narrowing left free to write criteria. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.
- [ ] AC18 — Given a row 0101 at `design` / `ready` with an `## Open design question` section, no `bounce_max:`, and `--scope 0101`, when `./next --drive --completed verify:0101 --scope 0101` runs with no `--bounces`, then it exits 0, prints `DISPATCH  design 0101`, and no `ESCALATE`; and given 0101 at `queue` / `ready`, when `./next --drive --completed develop:0101 --scope 0101` runs, then it exits 0 with `DISPATCH  queue 0101` and a `NOTE` before it containing `0101` and `1 of 2`. Red: the design half — FR16's check reading an absent entry as past the bound; the queue half — FR5's arm left keyed on `verify` alone (it reaches the stale-contract arm, exit 4). Test: `tests/next.test.sh`.
- [ ] AC19 — Given AC18's design fixture with `bounce_max: 2`, when `--completed verify:0101` carries `--bounces 0101=2`, then it exits 0 with `DISPATCH  design 0101`; with `--bounces 0101=3`, it exits 4 with a line containing `0101`, `next: design`, `3` and `bounce_max 2`, and no `DISPATCH`; when `--completed develop:0101` carries `--bounces 0101=3`, it exits 4 likewise; and when `--completed develop:0101` carries no `--bounces` under `bounce_max: 0`, it exits 0 with `DISPATCH  design 0101` (the 0159 AC4 behaviour, unbounded without a count). And given AC18's queue fixture with `bounce_max: 0` and no `--bounces`, `--completed develop:0101 --scope 0101` exits 4 with no `DISPATCH`. Red: `-gt` mutated to `-ge` (the first half escalates); the design arm reading no bound (the second and third halves dispatch); an absent develop entry counted as 1 (the fourth half escalates under 0). Test: `tests/next.test.sh`.
- [ ] AC20 — Given a fixture stream holding a warning line, then two `rate_limit_event` lines (the first with `five_hour` 0.10, the second with `unifiedWindows` `five_hour` 0.21 / `resetsAt` 1795000000 and `seven_day` 0.77 / `resetsAt` 1795500000), then a `result` line, when `tools/sprint-ledger.sh reading --stream <it> --stage develop --session s1 --now 2026-11-18T10:00:00Z` runs, then it exits 0 and prints one JSON line with `"event":"headroom"`, `"stage":"develop"`, `"session_id":"s1"`, `five_hour` utilization `0.21` and `seven_day` utilization `0.77`, each `resets_at` the ISO form of its epoch; given a stream whose only `rate_limit_event` has no `unifiedWindows` but top-level `rateLimitType` `seven_day`, `utilization` 0.5, then the line holds the one window `seven_day` at `0.5`; given a stream with no `rate_limit_event`, it exits 0 with `"readable":false`; and given a path that does not exist, it exits 1. Red: the first event read instead of the last (`five_hour` 0.10); the top-level fallback missing (the second case reads unreadable); an unreadable stream exiting non-zero. Test: `tests/sprint-ledger.test.sh`.
- [ ] AC21 — Given `skills/sprint/SKILL.md` and `skills/queue/templates/config.yml` after the change, when verify reads Step 3, the proposal section, Step 2, Step 7 and Step 8, then: per-stage caps are called runaway catches; the supervisor may raise a stage cap or add sessions when the outcome needs them, logging each raise as a `cap_raised` event with its reason before the dispatch; the proposal's estimate is a forecast, not a stop; Step 7's "never a figure chosen here" no longer forbids a logged raise; a cap kill is still Step 7's escalation; no run budget or deadline stops the sprint, `budget_usd` and `deadline` being the forecast (FR17); Step 2 routes a mid-run `next: design` scope row under `bounce_max` and says `--bounces` follows every re-entry (FR20); and the config template's `stage_budget_usd` comment says the cap is a runaway catch. And per FR21: Step 1's probe and Step 3's command dispatch with `--output-format stream-json --verbose`, with the probe's fallback to today's dispatch and a blind gate; Step 4 reads the outcome through `outcome --stream` and keeps "all you read"; a `headroom` line is appended after every stage; Step 2 calls `envelope` with no `--config`/`--measurement`, and a `WAIT` logs `headroom_wait`, waits to the named time and re-asks, never ending the run; Step 7's `limit_hit` pause is named as the fallback where headroom cannot be seen; and Step 8 lists no envelope `STOP` among the escalations. Red: any of these missing, or any place still presenting a stage cap, the estimate, `budget_usd` or `deadline` as a stop. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.
- [ ] AC22 — Given a run log whose last `headroom` event reads `five_hour` 0.21 and `seven_day` 0.77 (both `resets_at` after `--now`) and no earlier reading, when `tools/sprint-ledger.sh envelope --run <it> --stage develop --now 2026-11-18T10:00:00Z` runs, then it exits 0 and prints `CONTINUE` and two `ENVELOPE` lines whose source is `default`; with `seven_day` at 0.99 it exits 3, prints a `WAIT` line naming `seven_day` and that window's reset time and `resume after`, and prints no `CONTINUE` and no `STOP`; with `seven_day` at 0.98 against its default 0.02 (expected equal to headroom) it exits 3, and at 0.97 it exits 0 — the boundary pair; with `seven_day` at 0.99 but its `resets_at` before `--now`, it exits 0 (the window has reset); with no `headroom` event, and separately with a last event `"readable":false`, each exits 0 and prints `headroom not visible`; and given 0231 AC14's short-budget and past-deadline fixtures (a `scope_confirmed` whose budget or deadline is spent), each exits 0 with no `STOP` — no run budget or deadline stops the gate. Red: the unmodified `envelope` (the 0231 fixtures print `STOP`); the comparison mutated `<` → `<=` so equal headroom continues (the boundary case exits 0); a reset window still counted (the reset case exits 3); not-visible exiting non-zero. Test: `tests/sprint-ledger.test.sh`, the 0231 blocks amended per FR22.
- [ ] AC23 — Given a run log with three readable `headroom` events for one window `five_hour` with the same `resets_at` — after a `verify` at 0.20, after a `develop` at 0.35, after a `develop` at 0.60 — when `envelope --stage develop` runs, then its `five_hour` line reports `expected 0.20` (the mean of 0.15 and 0.25) with source `run log, 2 develop sample(s)`; and when the third event instead carries a different `resets_at` (the window reset), then the expected cost is `0.15` from one sample. Red: samples attributed to the earlier event's stage (verify, giving the develop default); the reset delta counted (expected moves off 0.15); the mean replaced by the last sample (0.25). Test: `tests/sprint-ledger.test.sh`.
- [ ] AC24 — Given AC20's first fixture stream whose `result` line carries a `structured_output` object, when `tools/sprint-ledger.sh outcome --stream <it>` runs, then it exits 0 and prints exactly one line, that object, which `tools/validate-json-schema.py` accepts against `skills/sprint/outcome.schema.json`; given a stream with no `result` line, and separately a `result` line with no `structured_output`, each exits 1 naming which. Red: the whole `result` line printed instead of its `structured_output` (the schema rejects it); a missing outcome exiting 0. Test: `tests/sprint-ledger.test.sh`.
- [ ] AC25 *(was 0170 AC1)* — Given the Step 3 snippet extracted and run with a shortened interval, when the stop it
  prescribes has run, then no descendant of the heartbeat's pid remains. Guard:
  `tests/sprint.test.sh`. Red: the snippet as written today, with the kill of the subshell alone.
- [ ] AC26 *(was 0170 AC2)* — Given the same extraction, the timestamp still advances while the stand-in runs, so
  `0153` AC26 is unaffected. Guard: `tests/sprint.test.sh`. Red: a stop that also prevents the
  refresh.
- [ ] AC27 — Given a fixture backlog with 0101 and 0102 at `develop` / `ready`, 0103 at `design` / `ready`, and 0101 claimed with token `aaaa`, when `./claim 0102 bbbb` runs, then it exits 1, stderr contains `0101` and `aaaa`, 0102's row still reads `ready`, its item's `claimed_by:` is empty and `HEAD` has not moved; and a following `./claim 0103 cccc` exits 0 at once — the lock was released. Red: the unmodified `claim` (the first call exits 0); a refusal that returns with the lock held (the second call refuses as busy). Test: `tests/claim.test.sh`.
- [ ] AC28 — Given AC27's fixture, when `./claim 0102 aaaa` runs, then it exits 0 and 0102 reads `in-progress` — one session's gate; and given 0104 at `verify` / `ready`, `./claim 0104 dddd` exits 0 while 0101 is held. Red: a refusal keyed on any held develop row whatever the token (the first half refuses), or on a held row at any stage (the second half refuses). Test: `tests/claim.test.sh`.
- [ ] AC29 — Given a fixture with 0101 at `develop` / `in-progress` held by `aaaa`, 0102 at `develop` / `ready`, and nothing else takeable, when `./next --drive` runs, then it exits 6, prints a `WAIT` line containing `0101`, and prints no `DISPATCH  develop`; and with 0101 moved to `done`, the same call exits 0 with `DISPATCH  develop 0102`. Red: the unmodified `next`, which prints `DISPATCH  develop 0102` — observed 2026-11-27 on a scratch copy of this backlog, `DISPATCH  develop 0064` exit 0 with develop 0242 held. Test: `tests/next.test.sh`.
- [ ] AC30 — Given AC29's held fixture, when `./next --drive --completed verify:0102` runs (0102 bounced back to `develop` / `ready`), then it exits 6 with no `DISPATCH  develop`; and given 0103 at `design` / `ready` ranked above 0102 and naming no file 0101's `touches:` names, `./next --drive` exits 0 with `DISPATCH  design 0103`. Red: the guard placed only in the rank walk's gate (the bounce half dispatches); the guard placed before the walk for every stage (the design half waits). Test: `tests/next.test.sh`.
- [ ] AC31 — Given the change, when `diff skills/queue/templates/claim .tickets/claim` and `diff skills/queue/templates/next .tickets/next` run, then both print nothing; and when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it exits 0. Red: a project copy not re-synced, or a neighbouring assertion left on the old contract (an existing `claim` or `--drive` fixture holding two develop rows under two tokens).
- [ ] AC32 — Given `references/CONCURRENCY.md`, `skills/sprint/SKILL.md`, `skills/develop/SKILL.md` and `CHANGELOG.md` after the change, when verify reads them, then: *The working tree is shared too* states one develop session at a time in every project, enforced by `./claim` and `--drive`, the priority order quality, cost, time, and both rejected candidates with their reasons, and no longer says "until `0137` decides otherwise"; the sprint skill's two places cite `0234` S6 and the enforcement; develop's claim step carries FR30's gate token and refusal handling; and `## Unreleased` carries FR32's entry. Red: any of these missing. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.


## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [x] S1 — `--drive`: the develop and queue bounce arms, the develop → queue and design re-entry bounds, `--bounces`, `bounce_max`, help, the amended 0038/0231 tests, `.tickets/next` re-synced — discharges AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10, AC12, AC13, AC14, AC15, AC16, AC18, AC19
- [x] S2 — the headroom gate in `tools/sprint-ledger.sh`: `reading` and `outcome` over a stream, `envelope` reworked from a budget/deadline STOP into CONTINUE/WAIT/not-visible, 0231's envelope tests amended citing 0234 — discharges AC20, AC22, AC23, AC24
- [x] S3 — the prose: `skills/sprint/SKILL.md` Steps 1, 2, 3, 4, 7, 8 and the proposal (FR7–FR9, FR17, FR20, FR21), `skills/queue/SKILL.md`'s *Re-specify* bullet, the config template comment, `CHANGELOG.md`, 0231's pointer note — discharges AC11, AC17, AC21
- [x] S4 — the marker heartbeat leaves no orphaned `sleep` child (0170) — discharges AC25, AC26
- [x] S5 — route a queue completion that re-specifies a waiting row to develop instead of exiting 4 (0204) — discharges none: already discharged by FR13/AC15, landed in S1 (the after-queue arm in `skills/queue/templates/next`, guarded by `tests/next.test.sh` block `0234 AC15`); ticked by `queue` on the user's decision, 2026-11-27
- [ ] S6 — one develop session at a time (0137, decided 2026-11-27): `./claim` refuses a second develop holder, `--drive` waits on a running develop, the develop/CONCURRENCY/sprint prose, both scripts re-synced, `CHANGELOG.md` — discharges AC27, AC28, AC29, AC30, AC31, AC32


## QA plan

- **Why that level:** the routing is a shell script with an existing behaviour suite
  (`tests/next.test.sh`); every scripted AC is a fixture call to `--drive`. AC11 and AC17 are
  readings.
- **Specific checks:** run `tests/next.test.sh`, then the whole suite (AC12). For AC1 and AC2,
  confirm from the build's history that the amended assertions were red against the pre-change
  arm. Mutate `-gt` to `-ge` in the bound comparison and confirm AC4's first half reds; move the
  bounce arm above the `next: queue` arm and confirm AC9 reds. Drop the `--scope` test from FR5's
  arm and confirm AC9 reds; drop its completed-stage-is-`verify` test and confirm AC16's third half
  reds; point the queue arm at a constant bound and confirm AC14's third half reds. Run AC10's two
  commands. Read the four places in `skills/sprint/SKILL.md` for AC11 and the *Re-specify* bullet
  of `skills/queue/SKILL.md` for AC17. For AC19, mutate the design arm's `-gt` to `-ge` and
  confirm the first half reds; count an absent develop entry as 1 and confirm the fourth half reds.
  For AC20, read the first `rate_limit_event` rather than the last and confirm the first case
  reds; drop the top-level fallback and confirm the second reds. For AC22, run the 0231
  short-budget fixture against the pre-change `envelope` and confirm it prints `STOP`; mutate the
  comparison `<` → `<=` and confirm the 0.98 boundary reds; drop the reset rule and confirm the
  reset case reds. For AC23, attribute samples to the earlier event and confirm it reds; count a
  delta across a changed `resets_at` and confirm the reset case reds. For AC24, print the whole
  `result` line and confirm the schema check reds. Read the places FR17 and FR21 name for AC21. A leg
  verify checks only the ACs its slice discharges, plus the whole suite (0231 FR5).

### From 0170

- **Why that level:** `unit` — both criteria execute the snippet and read process state.
- **Specific checks:** `tests/sprint.test.sh`, each red proved by reverting the kill order, then the
  whole suite.


## Out of scope

- Any change to how `verify` decides between `next: develop` and `next: queue` — FR5 relies on
  that hand-off as it already is.
- `--drive` reading the run log or the stage outcome itself. It stays stateless; the count and the
  `detail` pointer are the supervisor's to supply.
- A cap on bounces across runs, or on loops other than verify → develop and verify → queue → develop.
- Detecting a narrowing by diffing criteria (a removed AC id against the `ac_digest:` verify saw).
  `--drive` is stateless and never holds the earlier digest; the narrowing call is the queue
  session's reading, made mechanical at its hand-off (FR14), which `--drive` already routes.
- The run log's schema beyond FR17's `cap_raised` event and FR21's `headroom` and `headroom_wait`
  events: the bounce count is derived from outcomes the log already records (their `stage` and each
  ticket's `next`). `tools/sprint-ledger.sh` changes in FR18 and FR19 only; `estimate`, `record`
  and `tail-cap` are untouched.
- Converting a utilisation fraction into tokens or dollars left. The host reports a fraction per
  window, and the gate compares fractions; a stage's dollar cap and its utilisation cost are
  separate figures.
- Learning a stage's utilisation cost across runs. Samples are this run's (FR19); a cross-run prior
  is its own ticket if the per-run default proves too coarse.
- A separate headroom probe before each dispatch. The previous stage's stream carries the reading
  for free; a probe would pay a session's startup floor per dispatch (`MEASUREMENT.md`).
- Changing Step 7's reactive `limit_hit` pause. It stays as built, now the fallback (FR21).
- Renaming `budget_usd` and `deadline` on `scope_confirmed`. They stay, read as the forecast.
- A verify hand-off to `next: design`. `verify` hands to `develop` or `queue` (Step 5); FR16 covers
  the shape if one arrives, and changes nothing in `verify`.
- Releasing it. The `CHANGELOG.md` note is in scope; the bump and install are `tools/release`'s,
  on the user's word.

### From 0170

`0153`'s staleness rule and the heartbeat's interval.

### From 0137

- Design sessions running in parallel — already permitted by `0134` on the ground that they split no
  shared context.
- The gate partition defect — `0136`.


## Notes & decisions

- 2026-11-18 (retro, run-20261118T074205Z findings gate) — filed at the user's request from
  `.tickets/FINDINGS.md`; not held, because the user asked for it.
- 2026-11-18 (queue, amend) — **The user answered the design question; moved to `next: develop`.**
  Their words, verbatim: *"the goal of sprint is to manage the sprint and if there are no weird
  circumstances, and it's just a simple matter of verify failed the ticket and it needs to be
  redone sprint should be smart enough to just send that back and have it be fixed. I like the idea
  of putting a cap on it so that after some number of attempts it does get escalated to me, but
  those are edge cases and the common case should be just keep running the sprint because if I'm
  not monitoring it and you ask me a simple basic or common question that you should be able to
  figure out on your own than the whole sprint stalls until I check in again, which is directly
  contradictory to the intention of the skill."* Decisions written in: (1) the bound is
  `bounce_max` (default 2) over consecutive verify fails of one ticket in a run, the count passed
  as `--bounces <id>=<n>` because `--drive` is stateless (FR2, FR3); (2) the diagnosis travels in
  the supervisor's develop prompt as verify's `detail` pointer (FR8), and `--drive` prints the item
  path, which it already holds, but not `detail`, which it never sees (FR4); (3) a wrong contract
  still escalates, told apart mechanically by verify's hand-off target, `queue` rather than
  `develop` (FR5); (4) the escalate-only-what-needs-judgment principle goes into sprint Step 8
  (FR9). Routed to `develop`: no open decision and no surface remain.
  **Re-checked against the new shape:** the old FR3 named `tests/sprint.test.sh`, but both
  assertions of the old contract are in `tests/next.test.sh` (`0038 AC9` and `0231 AC7`), so FR10
  names both and `expects:` was corrected. `size` s → m: a new flag, a config key, the arm, help,
  three skill steps and about nine fixture cases. `bounce_max: 0` was made legal (unlike
  `gate_max_rows`) so the old behaviour is one config line away. Rank kept: an amend does not
  re-rank.
- 2026-11-18 (queue, amend at develop/ready from `07341c7`) — **The user reversed FR5's
  contract-wrong exception.** Their words, verbatim: *"If the outcome of the sprint is that we
  finish this work then we should include the queue session within the sprint to fix the acceptance
  criteria and then rerun a develop session. The goal here is not to add more process for
  ourselves. It's to achieve outcomes effectively and efficiently."* Decisions written in:
  (1) an in-scope contract-wrong bounce dispatches `queue` instead of exiting 4 (FR5), told apart
  from a build fault by verify's hand-off target as before; (2) that repair spends the **same**
  `bounce_max` and `--bounces` count — the cycle is capped once, with no new key (FR5, AC14);
  (3) `--completed queue:<id>` at `develop` / `ready` routes as usual (FR13, AC15); (4) the one
  boundary left a person's is a repair that would **narrow** the outcome — remove or weaken an AC's
  outcome, or drop scope — as opposed to correcting a contradictory, unmeetable or drifted statement
  of it. It is made mechanical at the queue session's hand-off (`waiting` + `## Waiting on` +
  `escalation`), which `--drive`'s existing `waiting` arm already escalates, and a queue session
  that leaves the row at `next: queue` hits the unchanged stale-contract arm (FR14, AC16); the line
  between repair and narrowing is written once, in `skills/queue/SKILL.md` (FR15), and sprint
  Step 8's "never narrows a contract" stays true by citing it (FR9). (5) Outside `--scope`, or with
  no `--scope`, a stale contract escalates as today (FR12, AC9 rewritten — its old red, "the new
  arm placed above the queue arm", now describes the intended build). **Re-checked against the new
  shape:** `expects:` gains `skills/queue/SKILL.md`; the QA plan gains three mutations; *Out of
  scope* gains criteria-diffing as the narrowing detector, since `--drive` never holds the earlier
  digest. `size` stays `m`: the script delta is one arm sibling to FR1's, reusing its count, NOTE
  and findings gate, and FR13/FR14 reuse existing arms — the added weight is five fixture cases and
  two prose paragraphs, still one focused session. No AC was ticked, so none is un-ticked. Rank
  kept: an amend does not re-rank. Stays `next: develop` — no open decision and no surface.
- 2026-11-18 (queue, amend at develop/ready from `69203c8`) — **The user generalised the principle
  beyond verify bounces; retitled from "Let --drive re-dispatch develop on a verify bounce instead of
  escalating".** Their words, verbatim: (a) *"this principal applies for any type of session, if we
  need if we discover mid sprint that we need another design session great let's do the design
  session. If we need to fix acceptance criteria let's run a queue session. The goal is not to spend
  as little as possible the goal is to achieve the outcome. We said we wanted to achieve when we
  started the sprint and if we need to increase budget caps because we've added more sessions and
  then that's fine if we need to the budget cap is less about spending less money and more about
  catching a runaway session so that's a tool for us to use not an immovable boundary"* and (b) of
  0231's envelope check (`tools/sprint-ledger.sh envelope`): *"that piece that we just built is a
  good exception to the rule that I just stated. In general, we should not be afraid to raise caps.
  However, if we're specifically about to hit a session cap, then we should still respect that and
  hold back until we have enough tokens to reliably do the work needed. So that still holds."*
  Decisions written in: (1) design re-entry is routed and bounded by the same `bounce_max` and count
  (FR16, AC18, AC19); the count widens from verify fails to every re-entry since the last verify
  pass (FR3). Mid-run design dispatch of an in-scope `ready` row already existed (0159 AC4, 0188
  FR5) — what was missing was the cap, so no new dispatch arm. (2) A develop session that hands an
  in-scope row to `next: queue` gets FR5's repair too (AC18) — "fix acceptance criteria" is not only
  verify's finding. (3) Per-stage caps become runaway catches the supervisor may raise with a logged
  `cap_raised` event; the estimate is a forecast; a cap kill stays Step 7's escalation (FR17, AC21).
  Checked for logic that treats a cap or estimate as a stop: `./next --drive` reads no budget;
  `tools/sprint-ledger.sh envelope` uses the stage cap only to price an unpriced outcome and as the
  no-prior estimate, so the one script change is FR18's pricing of a raised session (AC20); `tail-cap`
  only scales. (4) **Interpretation, stated so it can be overruled:** quote (b) names "the envelope
  check", and the user's framing is the account session cap and tokens. The envelope as built checks
  the person's `budget_usd` and `deadline`, and the account limit is Step 7's `limit_hit` pause.
  Both are kept as the exception (FR19), so quote (a)'s "increase budget caps" is read as per-stage
  caps and added sessions, not the run's confirmed `budget_usd`, which only the person raises. A
  pre-dispatch read of the account limit does not exist and is *Out of scope*. (5) Step 8's principle
  is the user's list: narrowing the outcome, release actions, repeated failure past `bounce_max`, a
  cap kill (FR9). **Re-checked against the new shape:** `size` m → **l** — two more `--drive` arms'
  worth of bound checks, a ledger change with its own test file, and five prose places; more than
  one focused session. **Sliced per 0231 FR1** (`## Progress`): S1 the script and its tests, S2 the
  ledger pricing, S3 the prose; each discharges ACs, so each leg ends at `verify`. `expects:` gains
  `tools/sprint-ledger.sh` and `tests/sprint-ledger.test.sh`; *Out of scope*'s ledger line is
  narrowed to FR18's pricing and gains the envelope, account-limit and `budget_usd` lines. AC11 is
  widened for FR9's new list; AC18–AC21 are new. No AC was ticked, so none is un-ticked. Rank kept:
  an amend does not re-rank. Stays `next: develop` — the user answered the only open question.
- 2026-11-18 (queue, amend at develop/ready from `57503dd`) — **The user answered the escalation the
  third amend raised (its decision (4), the envelope read as "the account session cap"): no run
  budget or deadline stops a sprint, and the envelope becomes an account-headroom gate.** Their
  words, verbatim: *"The budget that we set our guesses and their real value is only in preventing
  runway sessions. A totally separate need is session limits where there's actually a hard
  constraint of running out of tokens. The ideal outcome is that we find a way for the sprint
  coordinator to check current usage and then only start a new agent when we expect that agent will
  be able to finish without running out of tokens. So this would give a second use for our budget
  limits because we can compare what we expect a session to take against how many tokens we have
  left if we cannot see how many tokens are left in a session then this part of the tool is not
  actually helpful because our budget is not a reason to stop a sprint unless it's tied to an actual
  hard constraint. It is only a reason to stop a session within a sprint and assess what is going
  wrong."* Decisions written in: (1) no run budget or deadline stops a sprint; the proposal's
  estimate is a forecast; a stage hitting its cap is stopped and assessed (Step 7), and caps may be
  raised (FR17). (2) **This changes 0231's delivered contract** (FR13, AC14: `envelope` prints
  `STOP` on budget or time) on the user's call; its tests are amended citing 0234 and 0231's item
  gains a pointer line (FR22). (3) Feasibility, verified by the user on this host 2026-11-18:
  `claude -p --output-format stream-json --verbose` emits a `rate_limit_event` whose
  `rate_limit_info.unifiedWindows` holds `five_hour` and `seven_day`, each with `utilization` (a
  fraction) and `resetsAt` (epoch), e.g. `five_hour` 0.21 and `seven_day` 0.77 with
  `surpassedThreshold` 0.75. It reports utilisation, not tokens left, so the gate compares
  fractions. **Probe or stream — decided: the stream.** Every stage dispatches with `stream-json`,
  and the reading after stage N is the last `rate_limit_event` in its stream, which is also the
  *before* of stage N+1; Step 1's existing probe gives the run's first reading. A probe per dispatch
  was rejected: it pays a session's startup floor each time, for a reading the previous stream
  already holds. The cost of that choice is Step 4: the outcome is no longer the last `{` line but
  the `result` line's `structured_output`, so `outcome --stream` extracts it and Step 4 validates
  that line as before (FR18, AC24); and because whether this host's stream carries
  `structured_output` was not verified, Step 1's probe proves it per run and falls back to today's
  dispatch with a blind gate if not (FR21) rather than staking the outcome read on it. (4) **A known
  bias, accepted:** if the host emits `rate_limit_event` only at a session's start, a stream's last
  reading is that session's *before*, so each sample prices the interval up to the previous stage
  and attribution lags one stage. The gate still prices one dispatch interval per dispatch, which is
  what it must fit; the build may observe the emission point on the probe's stream and note it, but
  no AC depends on it. Samples also include the supervisor's own usage between dispatches, which the
  next dispatch has to fit too. (5) Defaults with no sample: `five_hour` 0.10, `seven_day` 0.02,
  other windows 0.10 — guesses, labelled `default` in the output, replaced by this run's samples as
  they accrue. (6) Where no reading exists (first dispatch of a blind run, API-key auth, a host that
  emits none), the gate says it cannot see headroom and stops nothing; Step 7's reactive `limit_hit`
  pause remains the catch (FR19, FR21). (7) Re-sliced: S2 was *"envelope prices an unpriced outcome
  at its `cap_raised` cap"*, which no longer fits — the envelope sums no spend — so the old FR18 and
  AC20 are replaced; S2 is now the headroom gate (FR18, FR19, FR22; AC20, AC22–AC24), and FR19's old
  text (the envelope `STOP` as the exception a cap raise never overrides) is replaced by the gate.
  **Re-checked against the new shape:** `size` stays **l** — S2 is now a larger leg (two new modes,
  a reworked mode, its tests and 0231's amended ones) but still one focused session, and S1 and S3
  are unchanged in size except S3's added Step 1/3/4/7 paragraphs. Each slice still discharges ACs,
  so each leg ends at `verify`. `expects:` gains 0231's item file. *Out of scope* loses the three
  lines this amend brings in (the envelope's stop, the pre-dispatch limit read, `budget_usd` as the
  person's) and gains tokens-versus-fractions, cross-run learning, a per-dispatch probe, and
  renaming the forecast fields. FR9's person's-list loses the envelope `STOP`, and AC21 gains FR21's
  places and checks Step 8 lists no `STOP`. No AC was ticked, so none is un-ticked. Rank kept: an amend does not re-rank. Stays `next:
  develop` — no open decision and no surface remain.
- **2026-11-26 (queue): merged by outcome, at the user's direction.** The 2026-11-26 consolidation grouped the backlog by outcome so a whole outcome is worked in one ticket and its context is paid for once. Absorbed and withdrawn, each id burned and each item file kept as the record:
  - `0170` (Stop the marker heartbeat leaving an orphaned sleep child): FR23–FR24, AC25–AC26
  - `0204` (Route a queue completion that re-specifies a waiting row to develop instead of exiting 4): no FRs, no ACs (an unspecified slice)
  - `0137` (Decide whether two develop sessions may run at once, and in what isolation): FR25–FR27, no ACs (an unspecified slice)
  Each absorbed ticket's Problem is quoted verbatim above, and its FRs, ACs, NFR rows, QA plan, Out of scope and Notes are carried below with `*(was NNNN FRn)*` tags. **Bare FR and AC numbers inside the carried text were renumbered to this ticket's.** A reference to another ticket's criterion not written as `NNNN ACn` may have been renumbered too, and the withdrawn file holds the original. An unspecified slice sends this ticket to `design` when it is next; its open question is below.

- **2026-11-26 (develop, S1 leg, token 5542) — S1 built in `482784d`; handed to `queue` on AC8.**
  Built: `read_bounce_max` (`bounce_max:`, absent 2, 0 legal, non-number exits 1); `--bounces
  <id>=<n>` (four-digit id, n ≥ 1, one per id, else exit 2); `bounce_count`/`past_bound` (`n >
  max`); the verify → develop arm now NOTEs and calls `dispatch_leg` (findings gate + design wait);
  a new in-scope `next: queue` arm above the stale-contract arm, keyed on the completed stage being
  verify or develop and the id in `--scope`; FR16's bound inside the 0159 design NOTE arm; help and
  usage; `bounce_max: 2` in `skills/queue/templates/config.yml`; `.tickets/next` re-synced
  (`diff` empty). 0038 AC9's bounce block and 0231 AC7's fail block amended citing 0234; 0038
  AC9's stale-contract block unedited and green. New section `0234 S1` at the end of
  `tests/next.test.sh`. Whole suite green at `482784d` (`git status` clean before the run).
- **FR13 needed an arm, as it allowed for.** `--completed queue:<id>` at `develop`/`ready` reached
  the catch-all `else` ("which no routing rule covers", exit 4) — AC15 was red against it. Added a
  `lstage = queue`, `ready`, `next: develop|verify` arm that NOTEs and carries on to the rank walk.
  **This is also the 0204 case S5 names** (a queue completion that re-specified a row to develop);
  S5 is not ticked here, being `unspecified` and not this leg's — the next `design`/`queue` pass
  should check whether S5 is now discharged by FR13/AC15 alone.
- **AC8 is unmeetable as written — `queue` must correct it (only the author changes a criterion).**
  AC8: "Given AC1's fixture with `findings_threshold: 2` and two `FINDINGS.md` entries and **no
  `--scope`** … exits 5". With no `--scope`, `findings_gate gate` defers by 0174's rule (NOTE
  "deferred until the run is out of work") and returns 0, for every develop dispatch, so a bounce
  that takes the gate exits 0 exactly like one that skips it — the fixture cannot discriminate and
  its stated red cannot be produced. **Run, not reasoned** (scratch fixture, `482784d`'s script):
  no `--scope` → exit 0; `--scope 0101` → exit 0 (deferred, scope live); `--scope 0102` (no such
  row, scope not live) → exit 5 `DISPATCH  retro, then queue`; a plain `--drive` develop dispatch
  under the same fixture → exit 0. **Proposed text:** "AC8 — Given AC1's fixture with
  `findings_threshold: 2`, two `FINDINGS.md` entries and `--scope 0102` naming no takeable row (so
  no confirmed-scope work remains), when `./next --drive --completed verify:0101 --scope 0102` runs,
  then it exits 5 and prints no `DISPATCH  develop` — the bounce re-dispatch takes the findings gate
  like any develop dispatch. Red: a re-dispatch that decides `DISPATCH` without `findings_gate gate`
  (exits 0)." The committed guard is that proposed form, labelled `0234 FR1 (AC8, proposed form)`,
  and M6 below proves it red.
- **Mutation sweep — run** against the committed template, each restored from `HEAD`:
  M1 `past_bound` `-gt`→`-ge`: reds AC4, AC14, AC19 first halves. M2 queue arm's `--scope` test
  dropped: reds AC9. M3 queue arm also keyed on `queue`: reds AC16's third half. M4 queue arm at a
  constant count 1: reds AC14 (third half). M5 the develop → design absent entry counted as 1: reds AC19 (fourth half). M6 the bounce arm deciding `DISPATCH` without `dispatch_leg`: reds the AC8 proposed-form guard. M7 `bounce_count` reading the first entry whatever its id: reds AC5.
  Not swept: "move the bounce arm above the `next: queue` arm" — the two arms test disjoint `next`
  values (`develop` vs `queue`), so their relative order cannot change a decision (reasoned).
- AC1/AC2 amended assertions were red against the pre-change arm (first run of the amended suite:
  `exits 0 — dispatch` / `re-dispatches develop` / `escalates nothing` FAIL in both blocks) — run.
- `--drive`'s NOTE prints the item path `item_for` returns, which is `$DIR`-prefixed (absolute in a
  fixture); the ACs' `.tickets/items/0101-` is a substring of it.
- **2026-11-26 (queue): AC8 replaced with the develop leg's *Proposed text*, verbatim, approved by
  the user on 2026-11-26.** A repair of the fixture, intent unchanged: the criterion still asserts
  that the bounce re-dispatch takes the findings gate like any develop dispatch; only the fixture
  moved from no `--scope` (where 0174 defers the gate and both builds exit 0) to `--scope 0102`
  naming no takeable row, where the gate bites. Only AC8 changed; `ac_digest:` re-stamped from
  `./next --ac-digest 0234`. The code at `482784d` is right and stays — S1 is built and its
  committed guard `0234 FR1 (AC8, proposed form)` already asserts this text, so no FR gains code and
  the row goes to `next: verify`, `status: ready`.

- **2026-11-26 (verify, S1 leg, token b7e3) — PASS on the S1 leg; handed back to `develop` with
  `--slice S1`.** Every AC S1 discharges (AC1–AC10, AC12–AC16, AC18, AC19) checked literally
  against `482784d`'s code, the whole suite green, and each cited guard reddened by a mutation run
  here (table under *QA evidence*). No AC ticked: a leg pass ticks the slice, and the closing leg
  ticks the ACs. **Hand-off defect, recorded rather than worked around silently:** the leg reached
  verify through develop → queue (the AC8 repair) → verify, so no `develop → verify --slice S1`
  hand-off ever wrote `slice:`, and `handoff --slice` refuses when `slice:` is not the slice verify
  was handed. This pass set `slice: S1` in its own claimed item. S1 is the leg develop's build notes
  and this dispatch name, and the first unticked slice. Parked in `FINDINGS.md`.
  QA-plan mutation not run: "move the bounce arm above the `next: queue` arm". The two arms test
  disjoint `next:` values (`develop` vs `queue`), so their order cannot change a decision (develop's
  reasoning, re-read and agreed). AC9 still rests on a run mutation (M2).

- **2026-11-26 (develop, S2 leg, token 7080) — S2 built in `612a548`.** `tools/sprint-ledger.sh`
  gains `reading` and `outcome` (FR18) and `envelope` becomes the headroom gate (FR19); the 0231
  AC14/FR13 envelope blocks in `tests/sprint-ledger.test.sh` are replaced by a `0234 S2` section
  whose headers name the 0231 case each supersedes (FR22). Whole suite green at `612a548`
  (`git status` clean before and after, no concurrent runner). Ledger file: `266 passed, 0 failed`.
- **Decisions the FRs left open, stated so verify can disagree:** (1) `envelope` **accepts and
  ignores** `--config` and `--measurement` rather than refusing them as unknown — the installed
  0.9.49 skill's Step 2 still passes `--config`, and a sprint driven by it must not exit 1 on the
  new script between this leg and S3's prose. FR19's "no longer reads" holds: neither is opened.
  (2) A sample needs two **adjacent** headroom events both readable; a `readable:false` event
  between two readings breaks the pair rather than booking the hidden interval to the later stage.
  (3) A zero rise is a sample (only a fall is excluded). (4) `reading` reads only the last
  `rate_limit_event`; if that one is malformed the line is `readable:false`, even if an earlier one
  was good. (5) The top-level fallback looks for `rateLimitType`/`utilization`/`resetsAt` inside
  `rate_limit_info` first, then on the event itself. (6) A window counted as reset says so in its
  source (`; reset <iso>, since the reading`). (7) `envelope` reads its log strictly (a non-JSON
  line exits 1), unlike `read_run`'s skip-a-partial-line, because FR19 makes that an unreadable log.
- **Mutation sweep — run**, each on the committed `612a548` script, restored from a copy, control
  `266 passed, 0 failed`: M1 first `rate_limit_event` read instead of the last → reds AC20 first case;
  M2 top-level fallback dropped → AC20 second; M3 unreadable stream exits 1 → AC20 third; M4 whole
  `result` line printed → AC24 schema check; M5 missing outcome exits 0 → AC24; M6 `<` → `<=` → AC22
  0.98 boundary; M7 reset rule dropped → AC22 reset case; M8 not-visible exits 3 → AC22 not-visible
  and both 0231 fixtures; M9 samples booked to the earlier event's stage → AC23; M10 delta across a
  changed `resets_at` counted → AC23 reset case; M11 mean replaced by last sample → AC23; M12 lenient
  JSON in the log → FR19 unreadable-log case; M13 resume after the earliest reset → FR19 two-window
  case; M14 a fall counted → the fall case.
- **The 0231 short-budget fixture against the pre-change `envelope` — run:** `1f8ac86`'s script
  printed `STOP  budget: 3.00 left, develop needs an estimated 7.00`, exit 3; `612a548`'s prints
  `CONTINUE  headroom not visible …`, exit 0. (The first red run of the new tests, 47 FAIL, is weaker
  evidence for this: the old script also refused the tests' missing `--config`.)
- **Clause table for S2's ACs** (each row an assertion in the `0234 S2` section):
  AC20 — warning line skipped; last event's `five_hour` 0.21 not 0.10; `seven_day` 0.77; `stage`,
  `session_id`, `event`; `resets_at` ISO of epoch (1795000000 → 2026-11-18T11:06:40Z, 1795500000 →
  2026-11-24T06:00:00Z, checked with `date -u -d @`); one line; top-level fallback one window at 0.5;
  no event → exit 0 `readable:false`; missing path → exit 1.
  AC22 — 0.21/0.77 → exit 0, `CONTINUE`, two `ENVELOPE` lines source `default`; 0.99 → exit 3, `WAIT`
  naming `seven_day`, its reset and `resume after`, no `CONTINUE`, no `STOP`; 0.98 → 3; 0.97 → 0;
  0.99 reset before `--now` → 0; no headroom event → 0 `headroom not visible`; last `readable:false`
  → 0 `headroom not visible`; 0231 short-budget and past-deadline fixtures → 0, no `STOP`.
  AC23 — `expected 0.20` source `run log, 2 develop sample(s)`; reset third event → `expected 0.15`,
  1 sample. AC24 — exit 0, one line, schema-valid via `tools/validate-json-schema.py`; no `result`
  line → 1 naming it; no `structured_output` → 1 naming it.
- **For S3:** `README.md` line 111 still says the sprint "ends at a clean boundary when either runs
  out" of `envelope` — stale since `612a548`, and not on S3's list of places; S3 should take it.

- **2026-11-26 (verify, S2 leg, token 2950) — PASS on the S2 leg; handed back to `develop` with
  `--slice S2`.** AC20, AC22, AC23 and AC24 checked literally against `612a548`'s code, the whole
  suite green, and each cited guard reddened by a mutation run here in a detached worktree (table
  under *QA evidence*). No AC ticked: a leg pass ticks the slice. develop's seven stated decisions
  re-read and not disputed: none contradicts FR18/FR19, and (1), accepting and ignoring
  `--config`/`--measurement`, keeps the installed 0.9.49 Step 2 driving until S3 lands. One
  coverage note, not a gap that fails the leg: AC22's "two `ENVELOPE` lines" is guarded per window
  (each line asserted present), not as a count of two. A direct run printed exactly 2. `.tickets/claim`
  with no token died on the missing `xxd` before taking the lock (already in `FINDINGS.md`), so this
  pass claimed with an explicit token.

- **2026-11-26 (develop, S3 leg, token 95b5) — S3 built at `42fbe87`; handed to `verify` with
  `--slice S3`.** Discharges AC11, AC17, AC21, all readings at verify (no prose guard, `CLAUDE.md`
  *Tests*). Whole suite green at `42fbe87`: 45 files, every one exit 0, `git status --porcelain`
  clean of other sessions' paths, no concurrent runner.
- **The person's direction for this run (2026-11-26), carried explicitly in S3's prose:** *a sprint
  is run to drive toward an outcome, not to a date/time or a budget, so no sprint-wide budget or
  deadline is proposed or enforced; each individual stage session carries a projected per-session
  budget, proposed to the person before dispatch, as a runaway catch.* Written into
  `skills/sprint/SKILL.md` (the proposal's bullets and its sizing paragraph, Step 3's cap paragraph)
  and `CHANGELOG.md`'s `## Unreleased`.
- **Decisions S3 made, stated so verify can disagree:** (1) **The direction supersedes part of FR17
  and FR21**: they had Step 1 still recording `budget_usd` and `deadline` on `scope_confirmed` as
  the forecast; the proposal now asks for neither, and the forecast is the estimate (scored by
  `record`). AC21's clause "`budget_usd` and `deadline` being the forecast" is met only in the
  sentence saying an older run's `scope_confirmed` carrying them is read as that forecast and never
  as a stop. If verify reads that clause as requiring the proposal to ask for them, the AC wants a
  `queue` amend to match the direction — not edited here (only the author changes a criterion).
  (2) "Proposed to the person before dispatch" is read as **the proposal**, before the first
  dispatch, listing each planned session's projected cap; a raised cap or an added session is
  logged as `cap_raised` before its dispatch and named in the next report, not asked mid-run — a
  per-dispatch question would stall the unattended run FR17 and AC21 ask for. (3) **FR11 is stale
  in one respect**: the 0231 bullet it says to correct in place has since been released under
  0.9.49, so a released entry is not rewritten; the new `## Unreleased` bullet says it supersedes
  0.9.49's envelope instead. (4) Step 2 states the principle in short form and points at Step 8,
  which carries FR9's whole sentence with the four examples and the reason, to hold the file's
  growth. (5) `README.md`'s stale envelope sentence, handed to S3 by S2's notes, is corrected.
- **Guards touched — run:** `tests/sprint.test.sh`'s `0180 AC4` guard on Step 8's `'one exception'`
  reddened on FR9's required rewording (two exceptions) and is **deleted**, not re-anchored
  (`CLAUDE.md` *Tests*), with a comment at its site citing 0234. `tests/skill-size.test.sh` reddened
  on the sprint skill's growth (70331 bytes against 60813 + 5000): its justification is re-argued
  and `argued_at` moved with it, as that file's header asks. A first re-argue naming the ticket id
  mid-reason reddened `0035 FR6` (a four-digit run in a reason goes stale), so the reason names the
  change instead.
- **Refused or failed commands this leg:** `.tickets/claim 0234` exited 2 with
  `.tickets/claim: 102: xxd: not found` before taking the lock (already in `FINDINGS.md`); claimed
  with an explicit token. No backlog write was refused.

- **2026-11-27 (verify, S3 leg, token c7e1) — PASS on the S3 leg; handed back to `develop` with
  `--slice S3`.** AC11, AC17 and AC21 read clause by clause against `42fbe87` (plus `81c17ba`'s 0231
  pointer), the whole suite green, table under *QA evidence*. No AC ticked: a leg pass ticks the
  slice. The person's 2026-11-26 direction is stated in `skills/sprint/SKILL.md`: the proposal's
  "no sprint-wide budget or deadline is proposed or enforced" paragraph and its "each planned stage
  session and its projected cap … before the first dispatch" bullet, Step 3's runaway-catch
  paragraph. develop's five S3 decisions re-read and not disputed: (1) AC21's "`budget_usd` and
  `deadline` being the forecast" is met by the older-run sentence, and the direction supersedes
  FR17/FR21's "Step 1 still records them", so no `queue` amend is owed; (2) "proposed before
  dispatch" read as the proposal, with mid-run raises logged as `cap_raised`, matches AC21's
  unattended run. `.tickets/claim 0234` with no token died on `xxd: not found` before the lock
  (already in `FINDINGS.md`); claimed with an explicit token. No backlog write was refused.
- **2026-11-27 (develop, S4 leg, token 668c) — S4 built at `120f1e9` (guard comment `5fa51cf`);
  handed to `verify` with `--slice S4`, since S4 discharges AC25 and AC26.** FR23: Step 3's stop is
  now `pkill -P "$BEAT"; kill "$BEAT"` with one sentence saying why; FR24: the `0234 AC25/AC26`
  block in `tests/sprint.test.sh`, directly after the 0153 AC2 heartbeat block, reusing its
  `$HEARTBEAT` extraction. `CHANGELOG.md` `## Unreleased` gains one bullet. `skills/sprint/SKILL.md`
  grew 131 bytes to 70462, inside `tests/skill-size.test.sh`'s 5000-byte margin over its argued
  70331, so no re-argument is owed.
  - **Why the plain order and not a STOP/CONT freeze (run, not reasoned).** I expected `pkill -P`
    then `kill` to race, with the loop re-forking a `sleep` between the two. A scratch harness
    measured 0 survivors in 40 runs each under `dash` and `bash` with `pkill -P "$BEAT"; kill
    "$BEAT"`, and 5 of 5 with `kill "$BEAT"` alone. So FR23 is built as the finding's own fix, which
    is also simpler to read than `kill -STOP … kill -CONT`. The window is not proven empty, only
    unobserved.
  - **Why 9 s.** AC25 is RUN with the interval shortened from 60 s to 9 s, not 1 s as in the 0153
    run, so an orphan outlives the block by seconds. With 1 s, the check would race the sleep's own
    end and could pass a broken stop. The stand-in records `pgrep -P "$BEAT"` after 1 s. A record
    with no child is a red (the non-vacuity half), and survivors are killed by the test either way.
  - **AC26** reuses the 0153 AC2 run, which is the same extraction with the stop included, so its
    advancing stamps are AC26's evidence. It gets its own named `ok`/`FAIL` line.
  - **Clause table (AC text → guard):** AC25 Given "the Step 3 snippet extracted and run with a
    shortened interval" → `$HEARTBEAT` awk extraction, `sleep 9`; when "the stop it prescribes has
    run" → the block runs as written, stop line included; then "no descendant of the heartbeat's pid
    remains" → every pid in `kids` fails `kill -0`, with `kids` non-empty. AC26 Given "the same
    extraction" → `$HEARTBEAT`; then "the timestamp still advances while the stand-in runs" →
    `BEAT_DISTINCT ≥ 2`, `BEAT_BAD = 0`. Only direct children are recorded: the `sleep` is a direct
    child, and the `$(date)` subshell is transient.
  - **Mutations (run, on the committed `skills/sprint/SKILL.md`, each restored with `git checkout`
    in the same call, then a control run green 389/0):** M1 the stop reverted to `kill "$BEAT"` →
    AC25 red (seen 1, alive 1); M2 `pkill -P "$$"; kill "$BEAT"` → AC25 red; M3 the stop moved above
    the dispatch line → AC26 red, plus AC25's non-vacuity half (seen 0) and 0153 AC2/FR1. Before the
    fix, the new block was red against the unmodified snippet (seen 1, alive 1).
  - Whole suite: `for t in tests/*.test.sh; do "$t" || exit 1; done`, 45 files, all green at
    `120f1e9`, with `git status --porcelain` clean before the run. That macOS's BSD `pkill -P`
    behaves the same is reasoned, not run: this host is Linux. Nothing new for `FINDINGS.md`: the
    `xxd: not found` claim failure is already parked there.

- **S6 built, 2026-11-27, develop token 65ef** — commits `131d16c` (FR28: `./claim`), `77503fa` (FR29:
  `--drive`), `354e084` (FR30–FR32: prose, CHANGELOG), `6fcc17a` (two prose guards deleted). Whole suite
  green at `6fcc17a` with `git status` clean; `diff` of both template/project pairs prints nothing (AC31).
  - **FR28 mechanism.** The refusal sits after the `"*"` exclusive refusal and before the row edit, so the
    EXIT trap releases the lock and nothing is written. A row's stage is its `QUEUE.md` `Next` cell and its
    holder its item's `claimed_by:` — QUEUE.md rather than `items/*.md` alone, because closed items can
    still carry an unstripped token and a closed row has left QUEUE.md. A table with no `Next` column
    is not refused (0106's cannot-tell rule).
  - **FR29 mechanism.** The guard is inside `wait_on_design`, which every `DISPATCH  develop` path already
    calls (the rank gate, `dispatch_leg` for a started or bounced leg, and the same-stage stand-down arm).
    So that arm now WAITs, not ESCALATEs, while another develop runs. That is right for a session FR28
    refused, which stands down leaving its row as it was. The running set is `running_at develop`
    minus the ids being dispatched.
  - **Neighbours amended (AC31).** `tests/claim.test.sh` `add_held` takes an optional stage. The 0067 AC7
    "ordinary ticket" and 0147 AC4 cases now hold their other row at `verify`. `tests/next.test.sh` 0038
    AC29 and 0038 FR8 do the same, each with a comment citing 0234 FR29. Two prose guards pinned the old
    `0137` wording FR31 replaces, and per `CLAUDE.md` *Tests* both were deleted, not re-anchored:
    `tests/shared-dirty-tree.test.sh` ("serialised in this repo by design until `0137` decides
    otherwise") and `tests/sprint.test.sh` (0134 Documentation NFR, "names 0137").
  - **Mutations, all RUN** (claim: whole `tests/claim.test.sh`; next: the 0234 AC29/AC30 block extracted
    with the file's helpers and pointed at a mutant copy):
    | Mutation | Reds |
    |---|---|
    | unmodified `claim` (HEAD before `131d16c`) | AC27: exits 0, no 0101/aaaa, QUEUE.md changed |
    | refusal returns with the lock held (`trap -` before `exit 1`) | AC27 "a following design claim exits 0" |
    | refusal keyed on any held develop row, whatever the token | AC28 first half |
    | refusal applied to a claim at any stage | AC27 tail (design claim), AC28 second half (verify 0104) |
    | other rows counted at any stage, not only develop | 0067 AC7 ordinary case, 0147 AC4 (amended neighbours) |
    | unmodified `next` (HEAD before `77503fa`) | AC29 first half (`DISPATCH  develop 0102`, exit 0), AC30 bounce half |
    | guard only in the rank walk's gate | AC30 bounce half |
    | guard before the walk for every stage | AC30 design half (and the bounce half) |
  - **AC32 is a reading** at verify. The places are `references/CONCURRENCY.md` *The working tree is shared too*
    (new bullet after the 0050 one), `skills/sprint/SKILL.md` *Design beside other stages* and Step 8's
    "never runs two stage sessions at once", the claim step of `skills/develop/SKILL.md`, and `CHANGELOG.md`
    `## Unreleased`. `skills/develop/SKILL.md` is 55,657 bytes, under its 55,862 ceiling (50,862 + 5,000
    margin, `tests/skill-size.test.sh`), so FR30 is three lines.
  - **Claim friction.** `./claim 0234` with no token died at `xxd: not found`: line 102's token default is
    `head -c2 /dev/urandom | xxd -p`, and this host has no `xxd`. `set -e` stopped it before the lock, so
    nothing was written. Claimed with an explicit token. Parked in `FINDINGS.md`, since it is outside S6's
    scope.

### Open questions for the unspecified slices

**Established, not yet specified (it was at next: queue), from 0204 — Route a queue completion that re-specifies a waiting row to develop instead of exiting 4:**

- The rule set has no queue-completion case; the fix is likely one routing rule plus a `tests/next.test.sh`
  section. Not read: which function in `tools/next` holds the completion rules.
- **2026-11-27 — develop (token `c2ca`) handed S5 to `queue` unbuilt: it carries no FR and no AC,
  so there is nothing to build or verify against, and `./handoff --slice S5` refuses an
  `unspecified` slice.** Diagnosis for `queue`, **read from the code, not run**:
  `skills/queue/templates/next` (re-synced to `.tickets/next`, `diff -q` empty) already has the arm
  S5 asks for. In the `--completed` rules, `lstage = queue`, `lstatus = ready`, `lnext` ∈
  {`develop`, `verify`} prints `NOTE  <id> is at next: <next> after queue — carrying on to the rank
  walk` and falls through to the rank walk instead of reaching the catch-all exit 4. Its comment
  cites 0204, and S1 added it under FR13. `tests/next.test.sh` block `0234 AC15` guards it. That arm
  is keyed on the row's state after queue, not on how it got there. So it covers both triggers in
  *From 0204*: the re-specified `waiting` row, and AetherWorks' fresh repair-first row (0130).
  **`queue`'s choices:** (a) tick S5 as discharged by FR13/AC15, (b) give it an AC of its own
  (for example, AC15's case with no `--scope`, which AC15 does not cover; untested here), or
  (c) drop it. The choice is `queue`'s, because it narrows or widens the contract. S6 (0137) stays
  `design`'s, and its open question is above. The expects path `tools/next` and
  `.claude/backlog/next` don't exist. `./claim` warned about both, and `queue` should correct `expects:`.
- **2026-11-27 — decided (the user): choice (a).** S5 is ticked as discharged by FR13/AC15 — the
  after-queue arm in `skills/queue/templates/next` (re-synced as `.tickets/next`), guarded by
  `tests/next.test.sh` block `0234 AC15`. No AC is added or changed, so `ac_digest` is unchanged;
  S5 names no AC, because AC15 is already named by S1 and every AC is named by exactly one slice.
  Option (b)'s uncovered case (AC15 with no `--scope`) is not taken up. `expects:` corrected by
  `queue`: `tools/next` and `.claude/backlog/next` removed, both confirmed absent; the real paths
  `skills/queue/templates/next` and `.tickets/next` were already listed and both exist. Routed
  `next: design`, `status: ready`: the next slice, S6 (0137), is `unspecified` with its open
  design question below, and an `unspecified` next slice goes to `design`
  (`skills/queue/templates/item.md`, *Progress*). S6 is untouched.

**S6 decided — design, 2026-11-27, token `09d9`: one develop session at a time, in every project, enforced by a script.**

- **The question** (from 0137): may two develop sessions run at once, and what isolates their working
  trees? There were three candidates: a worktree per session, one tree with a verified scope predicate,
  or no parallel develop.
- **The answer: no parallel develop.** The user's direction, 2026-11-27, in substance: running more than one develop
  session at once carries a very high risk of two sessions touching the same file at the same time, producing merge
  conflicts or files that cannot be read, and the speed gain is small. A parallel shape could only be proposed if it
  was safe with an extremely high success rate, avoided merge conflicts and did not significantly raise token cost.
  Neither candidate meets that bar.
- **Priority order it was chosen under (FR25): quality, then cost, then time.** Parallel develop buys only
  wall-clock, which is the axis this project lets vary. It spends the two axes ranked above it. A later reader
  should not reopen this on wall-clock grounds alone.
- **Rejected: a worktree per session.** It moves the conflict to merge time rather than removing it. In a repo whose
  prose files are the product, rows share files as a rule (`references/CONCURRENCY.md`, *The working tree is shared
  too*, 0050). Re-verified 2026-11-27: the two takeable develop rows, 0242 and 0064, both name
  `skills/queue/SKILL.md` in `expects:`. It also needs a subsystem that does not exist. `claim`, `close`, `handoff`
  and `reopen` refuse from a linked worktree (*A second checkout never writes the backlog*), so every backlog write
  would have to go back to the primary checkout, and a merge protocol would have to be added on top. Each extra
  session re-pays the ~20k-token startup floor that one gate holding the same rows pays once, and every conflicted
  merge costs another session. That fails "does not significantly increase token cost". *What would have to be true
  for it to win:* gates whose file sets are provably disjoint before dispatch, plus wall-clock ranked above cost.
  Neither holds.
- **Rejected: one tree with a stricter, verified scope predicate.** No verified scope exists before dispatch.
  `expects:` is the prediction, `touches:` is written only on claim, and a `touches:` collision warns neither
  session (`CONCURRENCY.md`). *What would have to be true:* a pre-dispatch predicate with near-zero false
  negatives against the code. Nothing in the suite produces one, and the prose-is-product shape makes its
  true-positive rate high anyway.
- **What made it buildable rather than prose-only.** Observed on 2026-11-27, on a scratch copy of this backlog with
  develop 0242 claimed (`in-progress`, token `aaaa`): `./next --drive` printed `DISPATCH  develop 0064` and exited
  0. 0064 shares `skills/queue/SKILL.md` with 0242. So "serialised by design" (`CONCURRENCY.md`) was a sentence
  that nothing enforced. A supervisor beside a hand-driven develop window would have dispatched the exact collision
  the user named. Per `CLAUDE.md` *Tests*, a rule that must hold exactly goes in a script that refuses. Hence FR28
  (`./claim`, the one path every develop session takes, including hand-driven ones) and FR29 (`--drive`, so a
  supervisor does not pay a session's startup only to be refused at claim). The token exception in FR28 keeps
  gates working: one session, one token, several rows (FR30).
- **Trade-offs accepted.** (1) Wall-clock: develop work is strictly sequential. (2) A dead develop session's stale
  claim now blocks *all* develop work, not just its own row, until it is released. The refusal names the holder's
  id and token so the person can act on it, and stale-claim handling is unchanged. (3) The rule binds every project
  that installs these scripts, including ones whose develop rows touch disjoint files. That follows the user's
  direction, and it has no config knob, because a knob would bring back the hazard as an opt-in.
- **Unchanged:** design beside develop, verify or design (0134), and the gate as the unit that batches tickets
  inside one develop session. FR26 does not apply, because parallelism is declined. FR27 is discharged by this
  entry and FR31.
- **Accounting against S6's existing criteria:** S6 carried FR25–FR27 and no ACs. This pass confirms FR25 and FR27,
  marks FR26 not applicable, adds FR28–FR32 and AC27–AC32, and names them on S6's line. `qa_level: unit` stays,
  because AC27–AC31 are behaviour tests and AC32 is a reading. `close_by: verify` stays. `expects:` gains
  `skills/queue/templates/claim`, `.tickets/claim`, `tests/claim.test.sh` and `skills/develop/SKILL.md`.

### Carried notes of the absorbed tickets

### From 0170 — Stop the marker heartbeat leaving an orphaned sleep child

- 2026-09-17 — filed from `FINDINGS.md` by the sprint supervisor rather than a `queue` session, for
  the reason recorded in `0168`. The sweep's review list ranked it directly below `0167`.

### From 0204 — Route a queue completion that re-specifies a waiting row to develop instead of exiting 4

- 2026-10-24 — Absorbed by retro (second leg of AetherWorks run-20261024T195310Z's tail): a broader trigger than the Problem names: AetherWorks run-20261024T195310Z dispatched a `queue` stage on the repair-first path for 0130, a fresh row rather than a re-specified `waiting` one, and `./next --drive --completed queue:0130` still exited 4 ("which no routing rule covers"); without `--completed` it gave `DISPATCH develop 0130`. So the fix is routing any `develop | ready` row after `queue`, not only a re-specified waiting row.

### From 0137 — Decide whether two develop sessions may run at once, and in what isolation

- **2026-09-09 — deferred, not dropped, at Aaron's direction after the analysis above.** Ranked low
  deliberately: it is the one child of `0128` whose value is wall-clock, which is the axis this
  project is explicitly willing to let vary.
- **2026-09-09 — `0136` is a relation, not a blocker.** It was first written as `blocked_by`, which
  `./next --drift` correctly reported against the row. The block was wrong in substance too: the
  design question can be *decided* on today's partition, and it is only an implementation of
  parallel dispatch that must not ship over a partition that can put two gates in one file. Blocking
  the decision on the fix would have stalled the cheaper half behind the more expensive one.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** `expects:` corrected from `skills/orchestrate/SKILL.md` to `skills/sprint/SKILL.md` by this pass (0129 renamed it). Also relevant to this decision: `--drive`'s `gate_from` still groups develop gates by parent-or-shared-file while `develop`'s prose (0059) makes takeability the batching condition — possibly right, as a conflict unit versus a cost unit, but nothing says so (2026-09-12 buffer entry, 0132 Out of scope).

## QA evidence

**S1 leg — PASS** (verify, 2026-11-26, token b7e3). Code under test: `482784d`; item contract at
`2dbbfe5` (AC8 re-specified). `./next --ac-digest 0234 --check` → `0234: ac_digest matches`.

Conventions: ../ai-building-conventions (CONVENTIONS_CORE.md; testing-conventions.md,
progressive-delivery-conventions.md cited by the NFR rows)

Level: `unit` (frontmatter). Command, verbatim from `.tickets/config.yml` `commands.unit`:
`for t in tests/*.test.sh; do "$t" || exit 1; done` → `UNIT-EXIT=0`; 45 files tallied, none with a
non-zero `failed`; `tests/next.test.sh`: `715 passed, 0 failed`. Also run per file
(`commands.unit_by_file`) first: all 45 tallies `0 failed`. lint / typecheck: not configured.

Tree: `git status --porcelain` empty before the first run and after the last; `HEAD` unmoved
(`73eac2e`, the claim) — dirty set empty, intersection empty, **not advisory**. Copy executed: the
repo's `skills/queue/templates/next` (what `tests/next.test.sh` runs); the installed 0.9.49 cache
differs from it in `templates/next` and `templates/config.yml`, as expected before a release.

Mutations: each applied to its own copy of `skills/queue/templates/next` beside a trimmed
`tests/next.test.sh` holding the harness helpers and the 0038 AC9, 0231 AC7 and `0234 S1` blocks.
Control on the unmutated copy: `92 passed, 0 failed`. Each pattern was required to match exactly
once, and each copy diffed non-empty against the control.

| # | Mutation (requirement broken) | Reddened |
|---|---|---|
| M1 | `past_bound` `-gt` → `-ge` | AC4 first half (and its AC7 NOTE), AC14 first half, AC19 first half |
| M2 | queue-repair arm: `--scope` test dropped | 0038 AC9 stale-contract block, AC9 both cases |
| M3 | queue-repair arm also keyed on completed `queue` | AC16 third half |
| M4 | queue-repair count a constant 1 | AC14 second and third halves |
| M5 | develop → design absent count read as 1 | AC19 fourth half |
| M6 | verify bounce decides `DISPATCH` without `dispatch_leg` (no findings gate) | AC8 |
| M7 | `bounce_count` reads the first entry whatever its id | AC5 |
| M8 | verify → develop arm restored to the old escalation | AC1, AC2, AC4, AC5, AC8 |
| M9 | `bounce_max: 0` read as "no bound" | AC3, AC14 fourth half, AC19 fifth half |
| M9b | `bounce_max: -1` accepted | AC6 (`-1`) |
| M9c | `--bounces 0101=0` accepted | AC6 (`0101=0`) |
| M9d | duplicate `--bounces` id accepted | AC6 (second value) |
| M9e | `--bounces 0101` (no `=`) accepted | AC6 (`0101`) |
| M10 | verify-bounce NOTE deleted | AC7 (three NOTE assertions) |
| M10c | verify-bounce NOTE deferred to an EXIT trap, so it prints after `DISPATCH` (confirmed by a direct run) | AC7 |
| M11 | queue-repair NOTE deleted | AC13 NOTE, AC18 queue-half NOTE |
| M12 | FR13 arm (`--completed queue:` at develop/ready) disabled | AC15 |
| M14 | design re-entry after verify: absent count read as 3 | AC18 design half |
| M14b | queue-repair arm keyed on `verify` alone | AC18 queue half |
| M15 | design arm's bound check removed | AC19 second and third halves |
| M19 | queue-repair arm's bound check removed | AC14 second, third, fourth halves; AC19 fifth half |
| M20 | queue-repair arm disabled (pre-change stale-contract arm) | AC13, AC14, AC18 queue half |
| M21 | `bounce_max: 0` rejected as malformed | AC3, AC14 fourth, AC19 fourth and fifth |
| M22 | non-number `bounce_max` accepted | AC6 (`two`, `-1`) |

Invalid mutation, published rather than counted: M10b sent the NOTE to stderr, but `run_next`
merges `2>&1`, so the output did not move. Replaced by M10c.

Clause table (S1's ACs; Given / qualifier, action, object), each row checked against an assertion
in `tests/next.test.sh`:

| AC | Given (verbatim scope) | Action | Outcome / object | Guard | Result |
|---|---|---|---|---|---|
| AC1 | unsliced 0101 at develop/ready, no `bounce_max:`, no `--bounces` | `--completed verify:0101` | exit 0; `DISPATCH  develop 0101`; no `ESCALATE` | 0038 AC9 / 0234 AC1 | pass, M8 red |
| AC2 | sliced 0911, S2 unticked, handed off from verify | `--completed verify:0911` | exit 0; `dispatch_line` = `DISPATCH  develop 0911` | 0231 AC7 / 0234 AC2 | pass, M8 red |
| AC3 | AC1 fixture, `bounce_max: 0` | same call | exit 4; `ESCALATE  0101 bounced from verify`; no `DISPATCH` | 0234 AC3 | pass, M9/M21 red |
| AC4 | `bounce_max: 2`; `--bounces 0101=2` / `=3` | same call | 0 + `DISPATCH  develop 0101` / 4 + `0101`, `3`, `bounce_max 2`, no `DISPATCH` | 0234 AC4 / AC7 | pass, M1/M8 red |
| AC5 | `bounce_max: 2`; two ids differing in count (`0102=9`, `0101=1`) | same call | exit 0; `DISPATCH  develop 0101` | 0234 AC5 | pass, M7 red |
| AC6 | each of seven malformed inputs | AC1 call | `--bounces` five → exit 2 each; `bounce_max` two → exit 1 naming `bounce_max` | 0234 AC6 (each asserted separately) | pass, M9b–e/M22 red |
| AC7 | AC4's dispatching case | — | NOTE before `DISPATCH` with `0101`, `2 of 2`, `.tickets/items/0101-` | 0234 AC4 / AC7 | pass, M10/M10c red |
| AC8 | AC1 fixture, `findings_threshold: 2`, two entries, `--scope 0102` naming no takeable row | `--completed verify:0101 --scope 0102` | exit 5; no `DISPATCH  develop` | `0234 FR1 (AC8, proposed form)` — the re-specified AC8's text | pass, M6 red |
| AC9 | 0101 at queue/ready, `bounce_max: 2`, `--bounces 0101=1`; no `--scope`, and `--scope 0102` only | `--completed verify:0101` | exit 4; `the contract is stale`; no `DISPATCH  queue` | unedited 0038 AC9 stale block + 0234 AC9 | pass, M2 red |
| AC10 | the change | `diff skills/queue/templates/next .tickets/next`; `./next --help` | empty diff; help names `--bounces` and `bounce_max` | run at verify: diff exit 0, empty; help lines 1, 43, 47 | pass |
| AC12 | whole suite | configured `commands.unit` | exit 0 | `UNIT-EXIT=0` | pass |
| AC13 | 0101 queue/ready, no `bounce_max:`, no `--bounces` | `--completed verify:0101 --scope 0101` | exit 0; `DISPATCH  queue 0101`; no `ESCALATE`; NOTE before with `0101`, `next: queue`, `1 of 2`, `.tickets/items/0101-` | 0234 AC13 | pass, M20/M11 red |
| AC14 | AC13 fixture under four bounds/counts | same call | `=2` dispatch; `=3` exit 4 + `0101`/`3`/`bounce_max 2`; max 1 + `=2` exit 4; max 0 no count exit 4; no `DISPATCH` on the escalations | 0234 AC14 | pass, M1/M4/M19/M21 red |
| AC15 | 0101 develop/ready, `--scope 0101` | `--completed queue:0101` | exit 0; `DISPATCH  develop 0101`; no `ESCALATE` | 0234 AC15 | pass, M12 red |
| AC16 | 0101 queue/waiting + `## Waiting on`; then queue/ready + `--bounces 0101=1` | `--completed queue:0101` (no scope / `--scope 0101`) | exit 4 `is waiting on a person`, no `DISPATCH`; exit 4 no `DISPATCH`; exit 4 `the contract is stale`, no `DISPATCH  queue` | 0234 AC16 | pass, M3 red (third half); halves one and two rest on the pre-existing waiting arm, which S1 did not change |
| AC18 | design/ready + `## Open design question`, no `bounce_max:`; queue/ready | `--completed verify:` / `develop:0101 --scope 0101` | `DISPATCH  design 0101`, no `ESCALATE`; `DISPATCH  queue 0101`, NOTE before with `0101`, `1 of 2` | 0234 AC18 | pass, M14/M14b/M11 red |
| AC19 | design fixture under `bounce_max: 2` / `0`; queue fixture under `0` | verify/develop completions | five halves as written | 0234 AC19 | pass, M1/M15/M5/M19 red. Third half ("exits 4 likewise") asserts exit 4 and no `DISPATCH`, not the line's contents; M15 reds it |

NFR rows (S1's part):

| Row | Check | Result |
|---|---|---|
| Testing | new `--drive` behaviours are behaviour tests in `tests/next.test.sh`; amended assertions seen red against old code | holds: M8 reproduces the pre-change arm and reds AC1/AC2's amended blocks; M20 reds AC13; M1 reds AC4/AC14/AC19. AC22 clauses are S2's and are not checked in this leg |
| Reliability | (AC22 — S2) | not this leg |
| Progressive delivery | `bounce_max: 0` restores escalation; 0 not rejected nor "unbounded" | holds, guarded: M9 ("unbounded") and M21 ("rejected") both red AC3. Config template ships `bounce_max: 2` with the rollback stated in its comment |

Always-on pass (`CONVENTIONS_CORE.md`): fail-loud on malformed input holds (exit 1 config, exit 2
usage, both guarded); no new egress, log field, credential or data visibility, so no privacy or
security row is owed. Newly reachable: escalations became dispatches only inside a bound and only
for an in-scope id (FR5), and every dispatch still passes the findings gate (M6). No destructive
action becomes reachable.

**S2 leg — PASS** (verify, 2026-11-26, token 2950). Code under test: `612a548`; tree at `3f6242f`
(the claim). `./next --ac-digest 0234 --check` → `0234: ac_digest matches`.

Conventions: ../ai-building-conventions (CONVENTIONS_CORE.md; testing-conventions.md cited by the
Testing and Reliability rows)

Level: `unit` (frontmatter). Command, verbatim from `.tickets/config.yml` `commands.unit`:
`for t in tests/*.test.sh; do "$t" || exit 1; done` → `UNIT-EXIT=0`; `tests/sprint-ledger.test.sh`:
`266 passed, 0 failed`. Run per file first (`commands.unit_by_file`): 45 files, every tally `0 failed`,
no file exiting non-zero. lint / typecheck: not configured.

Tree: `git status --porcelain` empty before the first run and in the capture fused onto the last
one; `HEAD` unmoved (`3f6242f`). Dirty set empty, intersection empty, **not advisory**. Copy
executed: the repo's `tools/sprint-ledger.sh` (what `tests/sprint-ledger.test.sh` runs via `$ROOT`).

Mutations: each applied to `tools/sprint-ledger.sh` in a detached worktree at `3f6242f`, each pattern
required to match exactly once and the copy to differ, restored from an in-memory copy (asserted
byte-equal after the sweep, worktree `git status` clean). Control: `266 passed, 0 failed`.

| # | Mutation (requirement broken) | Tally | Reddened |
|---|---|---|---|
| M1 | `reading` takes the first `rate_limit_event`, not the last | 264/2 | AC20 first case (`five_hour` 0.21, `seven_day` 0.77) |
| M2 | top-level `rateLimitType` fallback dropped | 264/2 | AC20 second case |
| M3 | an unreadable stream dies (exit 1) | 260/6 | AC20 third case (exit 0, `readable:false`, reason) |
| M4 | `outcome` prints the whole `result` line | 264/2 | AC24 schema check via `tools/validate-json-schema.py`; not the whole line |
| M5 | no `result` line exits 0 | 265/1 | AC24 no-result case |
| M13 | a `result` with no `structured_output` accepted | 264/2 | AC24 no-`structured_output` case |
| M12 | a non-JSON stream line is fatal | 252/14 | AC20 warning line skipped (first and third cases) |
| M6 | headroom comparison `<` → `<=` | 265/1 | AC22 0.98 boundary |
| M7 | reset rule dropped | 264/2 | AC22 reset case |
| M8a | no headroom event exits 3 | 262/4 | AC22 not-visible, both 0231 fixtures, no-budget scope |
| M8b | last `readable:false` exits 3 | 265/1 | AC22 `readable:false` case |
| M14 | `WAIT` with no `resume after` | 264/2 | AC22 WAIT case, FR19 two-window case |
| M9 | sample booked to the earlier event's stage | 263/3 | AC23 (all three) |
| M10 | rise across a changed `resets_at` counted | 265/1 | AC23 reset case |
| M11 | mean replaced by the last sample | 265/1 | AC23 mean case |
| M0 | the pre-change `envelope` (`1f8ac86`), run directly on 0231's fixtures | — | short-budget: `STOP  budget: 3.00 left, develop needs an estimated 7.00`, exit 3; past-deadline: `STOP  time: the deadline 2026-11-18T09:30:00Z has passed`, exit 3. `612a548`: `CONTINUE  headroom not visible …`, exit 0 on both |

Clause table (S2's ACs), each row checked against an assertion in the `0234 S2` section of
`tests/sprint-ledger.test.sh`:

| AC | Given | Action | Outcome / object | Result |
|---|---|---|---|---|
| AC20 | warning line, two `rate_limit_event`s (0.10; then 0.21/1795000000 and 0.77/1795500000), `result` | `reading --stream … --stage develop --session s1 --now …` | exit 0; one JSON line; `event`, `stage`, `session_id`; 0.21 and 0.77; ISO `resets_at` | pass, M1/M12 red |
| AC20 | only event has no `unifiedWindows`, top-level `seven_day` 0.5 | same | one window `seven_day` 0.5 | pass, M2 red |
| AC20 | no `rate_limit_event`; missing path | same | exit 0 `readable:false`; exit 1 | pass, M3 red; missing path asserted exit 1 |
| AC22 | last event 0.21/0.77, both resets after `--now`, no earlier reading | `envelope --run … --stage develop --now …` | exit 0, `CONTINUE`, two `ENVELOPE` lines source `default` | pass; each window's line asserted, count of 2 seen by direct run, not asserted |
| AC22 | `seven_day` 0.99 | same | exit 3; `WAIT` naming `seven_day`, its reset, `resume after`; no `CONTINUE`, no `STOP` | pass, M14 red |
| AC22 | 0.98 against default 0.02; 0.97 | same | exit 3; exit 0 | pass, M6 red |
| AC22 | 0.99, `resets_at` before `--now` | same | exit 0 | pass, M7 red |
| AC22 | no `headroom` event; last `readable:false` | same | exit 0 each, `headroom not visible` | pass, M8a/M8b red |
| AC22 | 0231 AC14 short-budget and past-deadline fixtures | same | exit 0, no `STOP` | pass, M0 (pre-change prints `STOP`), M8a red |
| AC23 | three readable `five_hour` events, same reset: verify 0.20, develop 0.35, develop 0.60 | `envelope --stage develop` | `expected 0.20`, `run log, 2 develop sample(s)` | pass, M9/M11 red |
| AC23 | third event with a different `resets_at` | same | `expected 0.15`, one sample | pass, M10 red |
| AC24 | AC20's first stream | `outcome --stream` | exit 0, one line, schema-valid | pass, M4 red |
| AC24 | no `result` line; `result` without `structured_output` | same | exit 1 each, naming which | pass, M5/M13 red |

NFR rows (S2's part):

| Row | Check | Result |
|---|---|---|
| Testing | `reading`/`outcome`/`envelope` behaviours are behaviour tests in `tests/sprint-ledger.test.sh` over fixtures the test builds; AC22 short-budget against the unmodified `envelope` prints `STOP`; `<` → `<=` reds the boundary | holds, guarded: M0 and M6 above |
| Reliability | a gate that cannot see headroom never stops; a `WAIT` always has `resume after <iso>` | holds, guarded: M8a/M8b and M14 red |
| Progressive delivery | (`bounce_max` — S1) | not this leg |

Always-on pass (`CONVENTIONS_CORE.md`): fail-loud holds (missing stream or run log, non-JSON log
line, window lacking `utilization`/`resets_at` each exit 1, guarded). The new `headroom` run-log
event carries utilisation fractions, reset times, stage and session id. It holds no personal data
and goes to the gitignored `.tickets/runs/`, so no privacy row is owed. No egress, credential or
visibility change. Newly reachable: a sprint no longer stops on budget or deadline. That is the
contract change FR19 makes on the user's call, and FR21's reactive `limit_hit` pause (S3's prose)
backstops it.

**S3 leg — PASS** (verify, 2026-11-27, token c7e1). Prose under test: `42fbe87` (and `81c17ba`);
hand-off at `427f755`. `./next --ac-digest 0234 --check` → `0234: ac_digest matches`. Copy read: the
repo's `skills/` (the change is unreleased; this session ran the installed 0.9.49 `verify`).

Conventions: ../ai-building-conventions (CONVENTIONS_CORE.md; testing-conventions.md cited by the
Testing row)

Level: `unit` (frontmatter). Command: `for t in tests/*.test.sh; do "$t" || exit 1; done` →
`suite_rc=0`, 45 files, every tally `N passed, 0 failed`. `git status --porcelain` empty at Step 2
and at the verdict, so the advisory intersection is empty.

| AC / row | How checked | Result |
|---|---|---|
| AC11 — Step 2 | `skills/sprint/SKILL.md` Step 2: "A bounce is routed, not escalated, up to `bounce_max`"; develop bounce → `DISPATCH  develop`; in-scope `next: queue` → `queue` repair "under the same bound and the same count"; `--completed queue:<id>` after it; `--bounces <id>=<n>` counting rule and "after any outcome that re-entered a ticket" | met |
| AC11 — prompts (FR8) | Step 3 bullet "A dispatch after a bounce carries verify's `detail` pointer … and the failed AC"; the `queue` prompt names the re-specify repair and FR14's hand-off (`waiting`, `next: queue`, `## Waiting on`, `escalation`); Step 4's "both go into the bounce's prompt" | met |
| AC11 — Step 8 (FR9) | principle with the four examples (narrowing, release action, past `bounce_max`, cap kill), "routes every stage the confirmed outcome needs" (FR9's own wording) and the reason; queuing outside scope escalates, designing/re-specifying in-scope routed; a narrowing repair and a `next: queue` row no in-scope bounce sent there listed as escalations; "two exceptions"; "never … narrows a contract" kept with "A repair is not narrowing" | met |
| AC11 — no bounce in an escalation list | `grep -n bounce skills/sprint/SKILL.md`: no list in Steps 2, 4, 8 names a verify or in-scope contract bounce as an escalation | met |
| AC17 | `skills/queue/SKILL.md` Step 1 *Re-specify*: repair and narrowing defined as FR15 does, repair recorded as one line in *Notes & decisions*, an unattended narrowing not written but handed off (`status: waiting`, `next: queue`, `## Waiting on`, outcome `escalation`) | met |
| AC21 — caps/forecast (FR17) | Step 3 "A stage's cap is a runaway catch, not a budget", raise and added sessions logged as `cap_raised` with `reason` before dispatch; proposal "a forecast … never a ceiling"; Step 7 "never a figure chosen silently", cap kill still the escalation; proposal "no sprint-wide budget or deadline is proposed or enforced", older `budget_usd`/`deadline` "read as that forecast; nothing reads either as a stop"; `skills/queue/templates/config.yml` comment "a runaway catch" | met |
| AC21 — routing (FR20) | Step 2: a mid-run `next: design` scope row dispatched "under that bound too"; `--bounces` after any re-entry | met |
| AC21 — gate (FR21) | Step 1 probe and Step 3 command carry `--output-format stream-json --verbose`, probe fallback "the headroom gate runs blind"; Step 4 reads `outcome --stream`, keeps "all you read", appends `reading --stream`'s `headroom` line after every stage; Step 2 `envelope --run <run log> --stage <stage>` (no `--config`/`--measurement`), `WAIT` logs `headroom_wait`, waits, asks again, "never ends the run"; Step 7 `limit_hit` named as the fallback; Step 8 names no envelope `STOP`; `grep -nE 'STOP|refuse an envelope|deadline'` finds nothing presenting a cap, estimate, budget or deadline as a stop | met |
| Person's direction (2026-11-26) | proposal paragraph and projected-cap bullet; Step 3 cap paragraph; `CHANGELOG.md` `## Unreleased`; `README.md` envelope sentence corrected | stated |
| AC12 (suite) | command above | exit 0 |
| NFR Testing / Reliability / Progressive delivery | rest on S1/S2's behaviour tests, mutated at those legs' verifies; green in this run, not re-mutated here (no AC ticked this leg; the closing verify re-checks every AC) | green, not re-mutated |

Mutations: none — AC11, AC17 and AC21 are readings with no prose guard by design (`CLAUDE.md`
*Tests*); S3 deleted the `0180 AC4` 'one exception' guard in `tests/sprint.test.sh` for FR9's
required rewording, as that rule directs, and re-argued `tests/skill-size.test.sh`'s sprint entry.
Evidence set: `skills/sprint/SKILL.md`, `skills/queue/SKILL.md`, `skills/queue/templates/config.yml`,
`CHANGELOG.md`, `README.md`, `tests/sprint.test.sh`, `tests/skill-size.test.sh`,
`.tickets/items/0231-drive-one-outcome-ticket-across-slice-sessions-unattended.md`, `tests/*.test.sh`.

### S4 leg — verify, 2026-11-27, token 4535 — PASS (leg; no AC ticked, per 0231 FR5)

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, verbatim: `for t in tests/*.test.sh; do "$t" || true; done`
(`commands.unit_by_file`, every file reporting); every file exited 0, `tests/sprint.test.sh`
printing `389 passed, 0 failed, 0 skipped`. Copy executed: the skill under test is the repo's
`skills/sprint/SKILL.md`, which the guard extracts and runs. The session itself ran the installed
0.9.49 skills, which do not yet carry the S4 change. `./next --ac-digest 0234 --check`: `0234: ac_digest matches`.
Tree: `git status --porcelain` empty at Step 2 and again after the last check, so the dirty set is
empty and the intersection is empty. This is not advisory.

| AC | Clause → guard | Mutation (run on committed `skills/sprint/SKILL.md`, restored by path) | Result |
|---|---|---|---|
| AC25 | Given "the Step 3 snippet extracted and run with a shortened interval" → `$HEARTBEAT` awk extraction, `sleep 60` → `sleep 9`; when "the stop it prescribes has run" → block run with its stop line; then "no descendant of the heartbeat's pid remains" → every recorded child fails `kill -0`, record non-empty | M1 stop reverted to `kill "$BEAT"` (the Red the AC names) → `FAIL 0234 AC25 … (seen: 1, alive: 15328)`, 387/2. M3 `pkill -P "$$"; kill "$BEAT"` → `FAIL 0234 AC25 … (seen: 1, alive: 32301)`, 387/2 | ok: `run as written, the Step 3 stop leaves none of the heartbeat's 1 child process(es) alive` |
| AC26 | Given "the same extraction" → `$HEARTBEAT`; then "the timestamp still advances while the stand-in runs" → `BEAT_DISTINCT ≥ 2`, `BEAT_BAD = 0` | M2 stop moved above the dispatch line (a stop that prevents the refresh) → `FAIL 0234 AC26 … (1 distinct stamps, 0 bad samples)` plus 0153 AC2/FR1 and AC25's non-vacuity half, 382/7 | ok: `with that stop, held-by still advanced while the dispatch stood in (4 distinct stamps)` |
| AC12 (whole suite, owed by every leg) | `unit_by_file` above | — | every file exit 0 |

Control after the three mutations: `git status --porcelain` empty, `tests/sprint.test.sh` exit 0,
`389 passed, 0 failed, 0 skipped`.

Note on AC25's quantifier: "no descendant" is checked over **direct** children (`pgrep -P`). The snippet has
only direct children: the `sleep`, plus a short-lived `$(date)` subshell. So the check covers
every descendant this snippet can have. A future snippet that forks grandchildren would need a tree
walk. NFRs: the Testing row holds for S4 (the new block was seen red against the old stop, M1).
The Reliability and Progressive-delivery rows name AC22/AC3, which are not this leg's. Always-on
pass (`CONVENTIONS_CORE.md`): the guard runs the snippet rather than grepping prose, kills any survivor
itself, and the diff carries no private path or company material. No process this pass started is
left running.

Evidence set: `skills/sprint/SKILL.md`, `tests/sprint.test.sh`, `CHANGELOG.md`, `tests/*.test.sh`.
