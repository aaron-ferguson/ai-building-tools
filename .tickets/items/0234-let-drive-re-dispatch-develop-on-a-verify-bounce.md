---
id: "0234"
title: Let --drive re-dispatch develop on a verify bounce instead of escalating
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: m
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
  - tests/next.test.sh
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=8d157b25 AC2=99cde558 AC3=7615f1f5 AC4=b8b5e381 AC5=e269ef8c AC6=07913581 AC7=ffd82fa5 AC8=2038cf12 AC9=e3851b98 AC10=ea7f7fcb AC11=cd9436a1 AC12=7626989e
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
  `skills/queue/templates/config.yml` ships the key at 2 with a comment saying what it counts and
  that 0 restores escalate-on-every-bounce.
- FR3 — **The count is the supervisor's, passed in.** `--drive` is stateless, so it takes
  `--bounces <id>=<n>` (repeatable, one per id; `<id>` four digits and `<n>` a whole number of at
  least 1, else a usage error exiting 2, as `--started` and `--scope` refuse a malformed id; a
  second value for an id already given is a usage error too). `<n>` is the number of consecutive
  verify fails of that ticket in this run **including the one `--completed` reports** — counted
  from the run log's verify outcomes for that id since its last verify `pass`. Only the
  `--completed` id's entry is read; an absent entry for it counts as 1. Past the bound
  (`n > bounce_max`) the arm exits 4 with a line naming the id, the count and the bound:
  `ESCALATE  <id> bounced from verify <n> time(s) in this run, past bounce_max <max> — …`.
- FR4 — **Where the diagnosis is.** Before the `DISPATCH` line of a bounce, `--drive` prints one
  `NOTE` naming the bounce, the count against the bound, and the ticket's item file as where verify
  recorded the fail: `NOTE      <id> bounced from verify (<n> of <max>) — re-dispatching develop;
  verify's diagnosis is in <item path>`. `--drive` never sees the stage outcome, so it cannot print
  verify's `detail` pointer; the item path is what it already holds (`item_for`), which is the
  cheap half. The `DISPATCH` line itself is unchanged in shape, since drivers parse it.
- FR5 — **The contract-is-wrong exception stays mechanical, and stays an escalation.** A verify
  that finds the contract wrong (an unmeetable or contradictory AC) hands to `next: queue`
  (`skills/verify/SKILL.md` Step 5, `./handoff <id> <token> queue`), and a build fault hands to
  `next: develop`. That hand-off target is the discriminator — never the supervisor's reading of
  the fail. The existing `next: queue` arm (`ESCALATE  <id> went back to next: queue after <stage> —
  the contract is stale …`) is left exactly as it is and is not subject to `bounce_max`.
- FR6 — **`--help` and the usage line** in `skills/queue/templates/next` name `--bounces <id>=<n>`
  and `bounce_max`, beside `--started`, saying what the count is and who supplies it.
- FR7 — **`skills/sprint/SKILL.md` Step 2** says a verify bounce (`next: develop` after
  `--completed verify:<id>`) is routed, not escalated, up to `bounce_max`; says the supervisor
  passes `--bounces <id>=<n>` for the completed id on every call after a verify, counted from its
  run log as FR3 defines; and says an exit 4 past the bound is the cap, which is a person's.
- FR8 — **`skills/sprint/SKILL.md` Step 3 or Step 4** (wherever the develop prompt is composed):
  a develop dispatch that follows a bounce carries verify's outcome `detail` pointer for that ticket
  and the failed AC named from it — Step 4's existing "open the `detail` pointer of every `fail`"
  rule now feeds the develop prompt as well as any report to a person.
- FR9 — **`skills/sprint/SKILL.md` Step 8, and every list in Steps 2 and 4 that enumerates what
  escalates**, state the principle as one sentence: the supervisor escalates only what needs a
  person's judgment — a decision, a release, a contract change, a cap exceeded — and routes the
  common case itself, because an unattended run stalls on every question until the person checks
  in. Where an existing escalation list names a verify bounce, it is removed from that list. Prose,
  and per this repo's `CLAUDE.md` *Tests* it gets **no prose guard**.
- FR10 — **The two tests asserting the old contract are amended, citing 0234** — both live in
  `tests/next.test.sh`, not `tests/sprint.test.sh` (checked 2026-11-18: `tests/sprint.test.sh`
  asserts no bounce behaviour): the `0038 AC9 — verify bounced the ticket back to develop/ready:
  escalate` block and the `0231 AC7 — after a leg verify fails, the bounce escalation stands` block.
  Each now asserts the dispatch; the old escalation is asserted only under FR2's `bounce_max: 0`
  and past the bound. The `0038 AC9 … stale contract` block (FR5) is not edited.
- FR11 — **The shipped copy reaches this repo's driver**: `.tickets/next` is re-copied from the
  template byte-for-byte (`skills/queue/SKILL.md` Step 0), and `CHANGELOG.md`'s `## Unreleased`
  gains one note for the behaviour sessions will now see differently.

## Non-functional requirements

| Dimension | This item must satisfy | How it would red | Convention |
|---|---|---|---|
| Testing | Every new `--drive` behaviour is a behaviour test in `tests/next.test.sh`, and each amended assertion was seen red against the old arm before the arm changed | AC1 against the unmodified script (the arm still escalates) fails `exits 0`; AC4 with `-gt` mutated to `-ge` fails | testing-conventions.md |
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
- [ ] AC9 — Given a row 0101 at `queue` / `ready` and `bounce_max: 2` with `--bounces 0101=1`, when `./next --drive --completed verify:0101` runs, then it still exits 4 with `the contract is stale` and no `DISPATCH`. Red: the new arm placed above the `next: queue` arm, or the queue arm made subject to the bound. Test: the unedited `0038 AC9 — … stale contract` block plus one new `--bounces` case beside it.
- [ ] AC10 — Given the change, when `diff skills/queue/templates/next .tickets/next` runs, then it prints nothing; and `./next --help` names `--bounces` and `bounce_max`. Red: the project copy not re-synced, or the help left unchanged. Checked by running both commands at verify.
- [ ] AC11 — Given `skills/sprint/SKILL.md` after the change, when verify reads Step 2, the step that composes the develop prompt, Step 4 and Step 8, then: Step 2 routes a bounce up to `bounce_max` and says how `--bounces` is counted and passed (FR7); a post-bounce develop dispatch carries verify's `detail` pointer and the failed AC (FR8); Step 8 states the escalate-only-what-needs-judgment principle with its four examples and the reason (FR9); and no list of escalations in Steps 2, 4 or 8 still names a verify bounce. Red: any of the four missing, or a bounce still listed as an escalation. A reading at verify — no prose guard, per `CLAUDE.md` *Tests*.
- [ ] AC12 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it exits 0. Red: any amended or neighbouring assertion left on the old contract.

## QA plan

- **Why that level:** the routing is a shell script with an existing behaviour suite
  (`tests/next.test.sh`); every scripted AC is a fixture call to `--drive`. AC11 is a reading.
- **Specific checks:** run `tests/next.test.sh`, then the whole suite (AC12). For AC1 and AC2,
  confirm from the build's history that the amended assertions were red against the pre-change
  arm. Mutate `-gt` to `-ge` in the bound comparison and confirm AC4's first half reds; move the
  bounce arm above the `next: queue` arm and confirm AC9 reds. Run AC10's two commands. Read the
  four places in `skills/sprint/SKILL.md` for AC11.

## Out of scope

- Any change to how `verify` decides between `next: develop` and `next: queue` — FR5 relies on
  that hand-off as it already is.
- `--drive` reading the run log or the stage outcome itself. It stays stateless; the count and the
  `detail` pointer are the supervisor's to supply.
- A cap on bounces across runs, or on same-stage loops other than verify → develop.
- `tools/sprint-ledger.sh` and the run log's schema: the count is derived from verify outcomes the
  log already records.
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
