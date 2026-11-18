---
id: "0234"
title: Route whatever stage the confirmed outcome needs, mid-sprint
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0231"]
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
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=8d157b25 AC2=99cde558 AC3=7615f1f5 AC4=b8b5e381 AC5=e269ef8c AC6=07913581 AC7=ffd82fa5 AC8=2038cf12 AC9=6515e3e2 AC10=ea7f7fcb AC11=c2fe5ce7 AC12=7626989e AC13=643d9a36 AC14=070405ec AC15=180d715f AC16=9a294489 AC17=355e6087 AC18=cdd8a9d7 AC19=b1b8bcf3 AC20=ff2c1d8b AC21=8c1f7268
---

## Problem

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
one when the outcome needs a larger stage. One stop stays: the envelope (`tools/sprint-ledger.sh
envelope`, 0231 FR13/AC14) and Step 7's account-session-limit pause.

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
  stage left `waiting`, an aged lock, an envelope `STOP` (FR19), and new work outside the confirmed
  scope. Step 8's "Queuing new work and designing tickets are escalations" becomes: queuing work
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
  gains one note per behaviour sessions will now see differently: the develop re-dispatch, and the
  in-scope queue repair.
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
  run is scored against (Step 6's `record`), not a ceiling. **A cap kill is unchanged**: still Step
  7's escalation (claim token, dirty paths, lock state, start nothing further), because that is what
  a runaway looks like — the remedy is the person's, never a raise-and-retry by the supervisor.
  `skills/queue/templates/config.yml`'s `stage_budget_usd` comment says the same in one line.
- FR18 — **The envelope prices an unpriced outcome at the cap that session actually ran under.**
  `tools/sprint-ledger.sh envelope` today prices an outcome with no `cost_usd` at its stage's
  `config.yml` cap ("spend it cannot see must not read as spend it saved"); under FR17 that
  understates a raised session. It reads `cap_raised` events: an unpriced outcome whose
  `session_id` has a `cap_raised` event is priced at that event's `to` (the last one for that
  session), else at the config cap as today, and the `ENVELOPE  budget` source text says how many
  were priced at a raised cap. A `cap_raised` event whose `to` is not a number is unreadable: exit 1
  naming `cap_raised`. The no-prior estimate stays the config cap — a raise is one dispatch's, not
  the stage's.
- FR19 — **The exception that stays, named so a cap raise cannot be read as overriding it.**
  `skills/sprint/SKILL.md`, beside FR17's text and in Step 8, says: the envelope the person
  confirmed — `budget_usd` and `deadline` in `scope_confirmed`, checked before every dispatch by
  `tools/sprint-ledger.sh envelope` (0231 FR13) — and Step 7's account-session-limit pause are
  **not** caps the supervisor raises. When `envelope` prints `STOP`, the run stops at that clean
  boundary as today; when the account session limit is hit or close, the sprint waits for the reset
  (`limit_hit`, then `resumed`) until there are tokens enough to finish the next stage reliably.
  Raising a stage cap never raises `budget_usd` or moves `deadline`; only the person does. No
  script change: `envelope`'s STOP arithmetic is untouched by this ticket (FR18 changes only how an
  unpriced outcome is priced).
- FR20 — **`skills/sprint/SKILL.md` Step 2 routes every stage the outcome needs**, in one paragraph
  beside FR7's: a scope row sent to `next: design` mid-run (by verify, by develop, or a design
  question a develop session discovered) is dispatched to `design` under FR16's bound, and the
  supervisor passes `--bounces <id>=<n>` after any outcome that re-entered a ticket (FR3 as widened),
  not only after a verify; and a develop session's hand-off of a scope row to `next: queue` is
  FR5's repair, as a verify's is.

## Non-functional requirements

| Dimension | This item must satisfy | How it would red | Convention |
|---|---|---|---|
| Testing | Every new `--drive` behaviour is a behaviour test in `tests/next.test.sh`, the envelope change one in `tests/sprint-ledger.test.sh`, and each amended assertion was seen red against the old code before it changed | AC1 and AC13 against the unmodified script (both arms still escalate) fail `exits 0`; AC4, AC14 and AC19 with `-gt` mutated to `-ge` fail; AC20 against the unmodified `envelope` reports spend at the config cap | testing-conventions.md |
| Progressive delivery | Other machines run this script after a release; the old behaviour stays one config line away | AC3 (`bounce_max: 0` escalates) fails if 0 is rejected or treated as "unbounded" | progressive-delivery-conventions.md |

## Acceptance criteria

- [ ] AC1 — Given an unsliced row 0101 at `develop` / `ready` and no `bounce_max:` in `config.yml`, when `./next --drive --completed verify:0101` runs with no `--bounces`, then it exits 0, prints `DISPATCH  develop 0101`, and prints no `ESCALATE`. Red: the bounce arm left as it is (exits 4). Test: `tests/next.test.sh`, the amended `0038 AC9 — verify bounced …` block.
- [ ] AC2 — Given the sliced fixture of `0231 AC7 — after a leg verify fails` (S2 named and unticked, handed off from verify), when `./next --drive --completed verify:0911` runs, then it exits 0 and `dispatch_line` is `DISPATCH  develop 0911`. Red: the bounce arm left as it is. Test: the amended `0231 AC7` block in `tests/next.test.sh`.
- [ ] AC3 — Given AC1's fixture with `bounce_max: 0`, when the same call runs, then it exits 4 with a line containing `ESCALATE  0101 bounced from verify` and no `DISPATCH`. Red: 0 rejected as malformed (exit 1) or read as "no bound" (exit 0). Test: `tests/next.test.sh`.
- [ ] AC4 — Given AC1's fixture with `bounce_max: 2`, when the call carries `--bounces 0101=2`, then it exits 0 with `DISPATCH  develop 0101`; and when it carries `--bounces 0101=3`, then it exits 4 with a line containing `0101`, `3` and `bounce_max 2`, and no `DISPATCH`. The pair is the boundary: `n = max` dispatches, `n = max + 1` escalates. Red: the comparison mutated `-gt` → `-ge` reds the first half; dropping the bound reds the second. Test: `tests/next.test.sh`.
- [ ] AC5 — Given AC1's fixture with `bounce_max: 2`, when the call carries `--bounces 0102=9 --bounces 0101=1`, then it exits 0 with `DISPATCH  develop 0101` — another id's count is not read. Red: an implementation reading the first or the largest `--bounces` value escalates. Test: `tests/next.test.sh`.
- [ ] AC6 — Given AC1's fixture, when `--bounces` is given as `101=1`, `0101=0`, `0101=x`, `0101` (no `=`), or `0101=1 --bounces 0101=2`, then each exits 2. And given `bounce_max: two` (and, separately, `bounce_max: -1`), the AC1 call exits 1 and names `bounce_max`. Red: any of the seven accepted. Test: `tests/next.test.sh`.
- [ ] AC7 — Given AC4's dispatching case, then the output carries a `NOTE` line before the `DISPATCH` line containing `0101`, `2 of 2` and the fixture's item path `.tickets/items/0101-`. Red: the NOTE omitted, or printed after the DISPATCH line. Test: `tests/next.test.sh`.
- [ ] AC8 — Given AC1's fixture with `findings_threshold: 2` and two `FINDINGS.md` entries and no `--scope`, when `./next --drive --completed verify:0101` runs, then it exits 5, not 0 — the bounce re-dispatch takes the findings gate like any develop dispatch. Red: a re-dispatch that decides `DISPATCH` without `findings_gate gate`. Test: `tests/next.test.sh`.
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
- [ ] AC20 — Given a fixture run log whose `scope_confirmed` carries a budget and deadline, a config `develop` cap of 1.00, a `cap_raised` event for session `s1` with `to` 3.00, and a develop outcome for `s1` with no `cost_usd`, when `tools/sprint-ledger.sh envelope --stage develop` runs, then its `ENVELOPE  budget` line reports `spent 3.00` and its source text says one outcome was priced at a raised cap; with the `cap_raised` event's `to` set to `"x"`, it exits 1 naming `cap_raised`; and with no `cap_raised` event, `spent 1.00` as today. Red: `cap_raised` ignored (`spent 1.00` in the first half), or the first `cap_raised` for the session read instead of the last when the fixture carries two (`to` 2.00 then 3.00). Test: `tests/sprint-ledger.test.sh`.
- [ ] AC21 — Given `skills/sprint/SKILL.md` and `skills/queue/templates/config.yml` after the change, when verify reads Step 3, the proposal section, Step 2, Step 7 and Step 8, then: per-stage caps are called runaway catches; the supervisor may raise a stage cap or add sessions when the outcome needs them, logging each raise as a `cap_raised` event with its reason before the dispatch; the proposal's estimate is a forecast, not a stop; Step 7's "never a figure chosen here" no longer forbids a logged raise; a cap kill is still Step 7's escalation; the envelope `STOP` and the account-session-limit pause are named as the exception a cap raise never overrides, with `budget_usd` and `deadline` the person's alone (FR17, FR19); Step 2 routes a mid-run `next: design` scope row under `bounce_max` and says `--bounces` follows every re-entry (FR20); and the config template's `stage_budget_usd` comment says the cap is a runaway catch. Red: any of these missing, or any of the five places still presenting a stage cap or the estimate as a stop. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.

## Progress

- [ ] S1 — `--drive`: the develop and queue bounce arms, the develop → queue and design re-entry bounds, `--bounces`, `bounce_max`, help, the amended 0038/0231 tests, `.tickets/next` re-synced — discharges AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10, AC12, AC13, AC14, AC15, AC16, AC18, AC19
- [ ] S2 — `envelope` prices an unpriced outcome at its `cap_raised` cap — discharges AC20
- [ ] S3 — the prose: `skills/sprint/SKILL.md` Steps 2, 3, 4, 7, 8 and the proposal, `skills/queue/SKILL.md`'s *Re-specify* bullet, the config template comment, `CHANGELOG.md` — discharges AC11, AC17, AC21

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
  For AC20, drop the `cap_raised` read and confirm the first half reds; read the first event
  rather than the last and confirm the two-event case reds. Read the five places for AC21. A leg
  verify checks only the ACs its slice discharges, plus the whole suite (0231 FR5).

## Out of scope

- Any change to how `verify` decides between `next: develop` and `next: queue` — FR5 relies on
  that hand-off as it already is.
- `--drive` reading the run log or the stage outcome itself. It stays stateless; the count and the
  `detail` pointer are the supervisor's to supply.
- A cap on bounces across runs, or on loops other than verify → develop and verify → queue → develop.
- Detecting a narrowing by diffing criteria (a removed AC id against the `ac_digest:` verify saw).
  `--drive` is stateless and never holds the earlier digest; the narrowing call is the queue
  session's reading, made mechanical at its hand-off (FR14), which `--drive` already routes.
- The run log's schema beyond FR17's `cap_raised` event: the count is derived from outcomes the
  log already records (their `stage` and each ticket's `next`). `tools/sprint-ledger.sh` changes
  only in FR18's pricing; `estimate`, `record` and `tail-cap` are untouched.
- Changing what the envelope stops on, or making it wait rather than stop. Its `STOP` arithmetic
  and Step 7's `limit_hit` pause stay as 0231 built them (FR19).
- A pre-dispatch read of the account session limit. Nothing reads it today — `envelope` checks the
  confirmed budget and deadline, and Step 7 reacts to a limit already hit — and building one is its
  own ticket if wanted.
- The supervisor raising `budget_usd` or moving `deadline`. Those are the person's (FR19).
- A verify hand-off to `next: design`. `verify` hands to `develop` or `queue` (Step 5); FR16 covers
  the shape if one arrives, and changes nothing in `verify`.
- Releasing it. The `CHANGELOG.md` note is in scope; the bump and install are `tools/release`'s,
  on the user's word.

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
