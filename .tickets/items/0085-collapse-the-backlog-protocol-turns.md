---
id: "0085"
title: Collapse the backlog protocol from a third of every session's turns to one command per stage boundary
type: debt
next:
status: done
qa_level: verify
size: l
created: 2026-09-02
source: agent
parent:
blocked_by: []
relates: ["0047", "0048", "0066", "0073", "0081", "0036"]
expects:
  - .claude/backlog/items/0048-remaining-backlog-write-sites.md
  - .claude/backlog/items/0066-three-wrong-answers-in-the-scripts.md
  - skills/verify/SKILL.md
  - tests/cost-by-category.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-03
---

## Problem

**The backlog protocol costs more turns than the work it protects.** `0073` classified all 1,112
turns of the pinned run by their tool calls, and the figures are in `MEASUREMENT.md`, *Where a
session's turns go*:

| Category | Share of every turn in the suite |
|---|---|
| `mechanism` — the backlog protocol and the git bookkeeping around it | **41.9%** |
| `work` — changing the thing under change, and running a test | 34.0% |
| `orientation` — the skill file, the conventions, the ticket | 15.7% |
| `other` | 4.6% |
| `narration` — a turn that called no tool | 3.8% |

81.8% of the mechanism turns are the protocol itself rather than git, so **34.3% of every turn in
the suite is the backlog protocol** — about 12.8 turns of a develop session's 38.6, and 14.9 of a
verify session's 38.4, against **three durable acts a session actually performs: claim, hand off,
close.** `verify` spends 49.5% of its turns here.

Where those turns go, as a share of the mechanism turns: 22.3% the `claim`/`close`/`next` scripts,
20.0% the lock, 19.3% `QUEUE.md`, 20.2% `DONE.md`/`FINDINGS.md`/`RANKING.md`/`config.yml`, 15.7% git
inspection, 2.6% git writes.

**This ticket exists because the obvious answers are measured and wrong.** Cutting narration reaches
3.8% of turns. Trimming the skill files reaches `orientation` at 15.7% of turns, and every word this
project controls is 10.2% of a session's end-of-session context, so halving all of it buys about 5%.
`0035` reached the same conclusion from the other side, on the cost arithmetic: relocation to a
pointer file does not pay below a ~20,000-byte block. The lever is the number of turns the protocol
takes, and nothing else measured comes close.

Aaron's standing instruction of 2026-08-30 — token efficiency until the sessions are slimmed and
orchestrated — is what this ticket serves, and `MEASUREMENT.md` now carries the turn budget it is
judged against: develop 30, verify 28, queue 28, design 20, retro 22, due **2026-10-31**.

## Decision

**Settled 2026-09-02.** `docs/decisions/001-one-command-per-stage-boundary.md` — the record answers
FR1 to FR6 in full and is the shared target the routed tickets aim at.

In one line: **a stage boundary is one command, and a session never sees the lock.** Claim is two
turns (`./next <stage>`, then `./claim`), hand-off is one, close is one — four boundary turns plus a
`FINDINGS.md` append, which is exactly the four-turn protocol budget in `MEASUREMENT.md`.

**Verified in tokens 2026-09-02, and this was not a formality.** The decision above was reached on
a share of *turns*. `tools/cost-by-category.sh` (new, guarded by `tests/cost-by-category.test.sh`)
prices the same pinned set by category: the protocol is **34.3% of turns and 32.8% of dollars**, and
a protocol turn costs **$0.0983 against a work turn's $0.1132 — 87% of one, not a fraction.** A short
command is not a cheap turn, because the dominant per-turn cost is re-reading the cached context and
that is category-blind (102,831 tokens against 109,008, 5.7% apart). **The denominator was right.**

**One claim did not survive the attack, and it is worth recording that it was not this one.** The
published headline *"41.9% mechanism is more than the 34.0% spent on work"* holds only while git sits
inside `mechanism`; splitting git out makes it a tie, and also treating read-only access to
`DONE.md`/`RANKING.md`/`SCHEDULED.md`/`config.yml` as orientation puts mechanism **below** work at
33.1%. The protocol share itself moved only from 34.3% to 31.5% under every attack at once. Both
results are in `MEASUREMENT.md`, *What a turn of each category costs*.

**What decided it:** `tools/classify-turns.sh` resolves a mechanism turn's part by first match wins,
with `backlog script` ahead of `lock` and `queue file`, and `./claim`/`./close` never name the lock.
So every turn counted as `lock` (20.0%) is a **by-hand** lock at a write site with no script, and
every turn counted as `queue file` (19.3%) is `QUEUE.md` opened with no script in the same turn. The
scripts are not the cost — 4.3 script turns against 8.5 by-hand ones per develop session.

## Functional requirements

- FR1 — Decide, per stage boundary (claim, hand off, close), **the minimum number of turns that
  boundary can take while every rule in `CONCURRENCY.md` still holds**, and record the decision with
  the rule each retained turn exists for.
- FR2 — Name the protocol turns that exist only because nothing scripted them together, and route
  each to the ticket that scripts it: `0081` for the hand-off, `0048` for the remaining write sites,
  `0047` for the busy lock's close-time path, `0066` for the three wrong answers. **This ticket does
  not re-do their work** — it gives them a shared target and closes the gaps none of them covers.
- FR3 — Address the **lock** specifically: 20.0% of mechanism turns, and the largest single line in
  the composition after the scripts themselves. State whether a session should ever see the lock as
  its own turn.
- FR4 — Address the **`QUEUE.md` reads**: 19.3% of mechanism turns, against a rule that already says
  to read it with `./next` rather than by eye. Decide whether the rule is unfollowed, insufficient,
  or being paid twice.
- FR5 — State the **expected turn saving per stage** before the change, and the measurement that
  will confirm or refute it — the same script, the same pin. `0009` modelled a 66% saving and
  observed 14.5%; a prediction recorded up front is what makes that visible instead of arguable.
- FR6 — Leave `git` alone, or say explicitly why not. 15.7% of the mechanism turns are git
  inspection that any project pays; it is not this backlog's cost and is out of the 34.3% figure.

- FR7 — **The one gap none of the routed tickets covers:** `verify` Step 7's advisory dirty-path
  intersection, at 20.5% of `verify`'s mechanism turns against a 15.7% mean. It is this protocol's
  own git rather than the project's, so FR6's "leave git alone" does not reach it. Give it a form
  that does not cost the session a turn of its own.

- FR8 — **Price the categories before accepting the prediction.** A share of turns is not a share
  of tokens, and `0009`'s history is a modelled 66% that came in at 14.5%. Measure cost and context
  tokens per turn by category on the same pinned set, with committed code. *(Discharged 2026-09-02:
  `tools/cost-by-category.sh`, guard green.)*
- FR9 — **State the prediction in dollars as well as turns, and name the figure that distinguishes
  "the turns were removed" from "the tokens were saved".** *(Discharged 2026-09-02: the decision
  record's FR5 table and its *How to tell* table.)*

## Amendments to file, and why this ticket cannot file them

`CONCURRENCY.md`, *A stage writes only the ticket it holds*, forbids the session that settled this
from writing them, **and naming them here is explicitly not filing them.** They need a `queue` pass,
which is why this ticket sat at `next: queue` rather than `next: develop`. Both are dated
2026-09-02 and were re-verified against the source before they were run.

**Filed 2026-09-01.** Both amendments below are now in place: `0066` carries FR6/FR7 and `0048`'s
open design question is narrowed to the row insert plus the `RANKING.md` write. What remains on
this ticket itself is FR7 — the decision record's own attribution table names `verify`'s advisory
dirty-path intersection (Step 7) as **owned by `0085`**, not routed to a sibling — so this ticket
moves to `next: develop` rather than closing here.

- **`0066` gains two FRs.** `./claim <id> --touches <paths>`, writing `touches:` inside the same lock
  and commit — **taking paths the session names, never defaulting to `expects:`**, since `queue`
  writes `expects:` predicted and `develop` writes `touches:` actual and never copied. And: a
  `./next` warning must be actionable without a second read of `QUEUE.md`, which is the same class of
  defect as its existing FR4.
- **`0048` narrows.** Its open question asks which of *two* by-hand write sites becomes a script;
  `0081` has since settled the hand-off half as a fourth script with its own incident behind it. What
  is left is `queue`'s row insert and the `RANKING.md` write beside it.
- **`0081` and `0047` need nothing filed** — both already specify their piece. `0047`'s retry belongs
  inside the script rather than in a session's turn, which its FR2 already reaches.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Correctness | No rule in `CONCURRENCY.md` is weakened to buy a turn. A batching that removes a read-back removes the check that made a claim durable, and each of those checks has an incident behind it. | `CONCURRENCY-INCIDENTS.md` |
| Measurement | The saving is predicted before the change and re-measured after with `tools/classify-turns.sh` against a pinned set, and the verdict is recorded whichever way it comes out. | `measurement-conventions.md` |
| Testing | Every script change lands with the guard first, and the existing `claim`/`close`/`next` suites stay green. | `testing-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given the decision record, when read, then it states for each of the three stage
      boundaries the minimum turn count and, per retained turn, the `CONCURRENCY.md` rule it serves.
      *(Confirmed 2026-09-01: "The minimum turn count per boundary, and the rule each retained turn
      serves" table.)*
- [x] AC2 — Given the decision record, when read, then every protocol turn it calls removable names
      the backlog id that removes it, and no removal is left unowned. *(Confirmed 2026-09-01:
      "Every removable turn, and who removes it" table — every row has an owner or is Retained.)*
- [x] AC3 — Given the decision record, when read, then it states the predicted turns-per-session
      figure per stage against the budget in `MEASUREMENT.md`, and the command that will test it.
      *(Confirmed 2026-09-01: FR5's turns table against budget, and "re-measured … with the pinned
      set in `MEASUREMENT.md`, *Re-running this*, as the baseline.")*
- [x] AC4 — Given the lock and the `QUEUE.md` read, when the record is read, then each has an
      explicit verdict rather than being folded into a general statement about mechanism.
      *(Confirmed 2026-09-01: FR3 and FR4 sections each give an explicit, separate verdict.)*
- [x] AC7 — Given a fixture whose every turn has a known context, output and cost, when
      `tools/cost-by-category.sh` runs, then the per-category figures reconcile to the session total
      exactly (0.2550) and a cache-read-only turn prices at 0.0525.
- [x] AC8 — Given a turn that *edits* a skill file, when classified, then it is `work` and not
      `orientation`, because `WRITES` is tested before `ORIENT`.
      *(Confirmed 2026-09-03, token `e940`: `ORIENT` tested before `WRITE_TOOLS` in
      `category_of_call` reds both assertions, 25/2 — work totals 0.0675 not 0.1425, and an
      orientation bucket appears at 0.0750.)*
- [x] AC9 — Given the output, when read, then `mechanism` is split into `protocol` and `git`, since
      only the first is a cost this backlog can remove.
      *(Confirmed 2026-09-03, token `e940`: `mechanism_split` returning `"protocol"`
      unconditionally reds both assertions, 22/5 — protocol totals 0.1125 not 0.0525, git row
      ABSENT.)*
- [x] AC10 — Given four turns whose context climbs by 10,000 each, when the marginal footprint is
      reported, then it is 10,000 per turn, attributed to the turn that appended it rather than the
      turn that followed.
      *(Confirmed 2026-09-03, token `e940`: `r["marg"] += 0` reds three, 24/3; crediting the
      rise to `turns[i + 1]` reds all four, 23/4, with the last turn charged 50000 having appended
      nothing.)*
- [x] AC11 — Given `MEASUREMENT.md`, when read, then it carries a *What a turn of each category
      costs* section stating the protocol-versus-work cost per turn.
**AC6 moved to `0088` on 2026-09-03** — *"the advisory dirty-path intersection costs a `verify`
session no turn of its own"* — because it names a classification pinned to `--until 2026-10-31` and
so could not close here. `0088` is dormant in `SCHEDULED.md` until that date.
- [x] AC5 — Given `tests/claim.test.sh`, `tests/close.test.sh` and `tests/next.test.sh`, when run
      after any change this ticket makes, then all three are green. *(Confirmed 2026-09-02: 18, 93
      and 175 passed respectively, 0 failed; the whole suite — every `tests/*.test.sh` — was also run
      once and is green.)*

## QA plan

- **Level:** verify — the deliverable of this ticket is a decision and a routing of work to existing
  tickets. The script changes it hands off are guarded by their own tickets' suites.
- **Specific checks:** the three script suites green; the decision record's claims read against
  `CONCURRENCY.md` rule names, since a retained turn justified by a rule that does not exist is the
  likely failure.

## Out of scope

- **The reduction to the skill files.** Measured at 10.2% of context for all of this project's prose,
  and `0035` already recorded the arithmetic against relocation. If it is done at all it is done for
  clarity, not for tokens, and it is a different ticket.
- **Cutting narration.** 3.8% of turns. `0074` already decided what a stage tells the human.
- **Orchestration.** `0036` and its slices are the other half of Aaron's instruction and are ranked
  on their own.
- **Re-measuring the fresh project.** That is `0037`.

## Notes & decisions

- Opened by `0073` under its FR5, which required the measurement to name the largest category and
  open the reduction ticket rather than make the reduction itself.
- **The counter-intuitive finding worth keeping:** every theory anyone held before the measurement
  aimed at what a session *says* or *reads*. Narration is 3.8% of turns and this project's whole
  prose is 10.2% of a session's context. The weight is in what the sessions *do* to keep the backlog
  safe for two writers, and that is a design cost, not a verbosity one.
- **Settled 2026-09-02 by `/design`**, token `6983`, into
  `docs/decisions/001-one-command-per-stage-boundary.md`.
- **What the decision rejected.** *Fusing select-and-claim into one command* — the scope-overlap
  judgement in `CONCURRENCY.md`, *The working tree is shared too*, is the session's and not the
  script's, so a fused command would claim a row nobody saw collide; `./next --drive` already makes
  that fusion for the orchestrator, which is a different consumer. *Cutting git inspection* — 15.7%
  of mechanism turns, and *The git index is shared* requires more of it, not less; `git write` is
  already at floor at 2.6% because `claim` and `close` commit internally. *Folding the `FINDINGS.md`
  append into a script* — it is content nothing but the session can author.
- **The trade-off accepted:** four scripts to keep in step with the templates, and one flag
  (`--touches`) whose misuse would silently erase the distinction between predicted and actual file
  scope. That is the single place this decision can weaken a rule, and it is why the flag takes paths
  the session names.
- **The prediction is recorded before the change** (FR5, and the record's own table): develop 29.8,
  verify 27.5, queue 28.4, design 20.0, retro 22.0 turns per session, with `lock` to 0.0% of
  mechanism turns. The verdict is read on turns per session, not on the mechanism share, because
  turns removed from the protocol can reappear elsewhere.
- **Re-opened and verified 2026-09-02**, token `b00a`, on Aaron's instruction not to take `0073`'s
  measurement on faith. What was done and what it found:
  - **All four published tables reproduce exactly** from the pinned command — 30 sessions, 1,112
    turns, and every cell.
  - **The rules were attacked before being built on.** `mechanism` is barely inflated by
    ticket-reading scored by path (**11 turns of 1,112**, correcting this ticket's own earlier
    "1–2 per session"); the 4.6% `other` is `cd`, bare variable assignments and `AskUserQuestion`,
    hiding nothing; but **the "mechanism > work" headline is fragile** and two defensible rule
    changes flip it. The protocol share is not fragile: 31.5%–34.3% under every variant.
  - **The gap was real and is now closed.** Nobody had priced a turn. Priced: protocol 34.3% of
    turns and **32.8% of dollars**. The turn share was not overstating the prize.
  - **The prediction is restated in dollars:** develop −20.6%, verify −29.9%, queue −20.4%, design
    −26.3%, retro −6.3%; **per ticket $7.66 → $5.74, −25.1%.**
  - **A more linear workflow was priced and rejected on its own terms: +12%.** Fusing develop and
    verify makes the second stage re-read the first's 74,970-token climb on every turn ($1.44)
    against $0.36 saved on a floor that is cached anyway.
- **Queue pass, 2026-09-01.** Filed both routed amendments: `0066` gained FR6 (`--touches`) and FR7
  (generalizing FR4's `./next`-warning fix), size raised `m` → `l`; `0048`'s open design question
  narrowed to the row insert plus the `RANKING.md` write beside it, with the former FR2 (stage
  handoff) retired to Out of scope now that `0081` specifies it. Confirmed AC1–AC4 against the
  decision record and ticked them. Set `next: develop`: the one piece left on this ticket itself is
  FR7 (verify's Step 7 dirty-path form), which the decision record's own attribution table assigns
  to `0085`, not to a sibling — there is no open decision or surface left, so `develop` rather than
  `design`.
- **Develop pass, 2026-09-02.** Discharged FR7 with no new script — the removable turn was never
  Step 2's `git status --porcelain` itself (that check is required by *Check whose tree you are
  testing*, and stays), it was a **second** status call the old Step 7 wording invited at verdict
  time to get a "fresher" read. Fixed in `skills/verify/SKILL.md` only: Step 2 now says to capture
  the status in the same tool call as the first level command it runs, and to hold that output;
  Step 7 now says explicitly to reuse it and issue no git command of its own. Added a short
  "Resolved" note to `docs/decisions/001-one-command-per-stage-boundary.md`'s FR6 section naming the
  mechanism and the falsifiable check (`verify`'s git-inspection share of mechanism turns back to the
  ~15.7% mean). **AC6 cannot be ticked by this session** — it names a `verify` session run after this
  change, classified by `tools/classify-turns.sh`, which is exactly the 2026-10-31 re-measurement
  `MEASUREMENT.md` already commits to; this pass only makes the prediction true of the skill text.
  Left unrelated to this ticket: `README.md`, `MEASUREMENT.md` and `tests/cost-by-category.test.sh`
  were already dirty in the shared tree at claim time (uncommitted work referencing
  `docs/decisions/002-matching-rigour-to-stakes.md`) — not touched, not committed, not diagnosed;
  another session's in-progress work.
- **Verify pass, 2026-09-03, token `9fd3` — FAIL on AC8, AC9 and AC10, and the code is not what
  failed.** All three behaviours are correct in `tools/cost-by-category.sh`; what fails is that their
  guards in `tests/cost-by-category.test.sh` **cannot be made to go red on the defect the AC names**,
  which `verify` Step 3 rules leaves the AC unverified, and `testing-conventions.md` (*"Anchor an
  assertion to the claim, not to the document that contains it"*, and *"an assertion that a number is
  present where the contract is that it is formatted"*) names as the failure shape. Each assertion is
  a substring `case` over the tool's **whole output**, so it is satisfied by text the tool prints
  unconditionally:
  - **AC8** — `*"work"*`. Mutation: `category_of_call` made to test `ORIENT` before `WRITE_TOOLS`,
    which moved the fixture's turn 4 from `work` to `orientation` (bucket table: `work 2` → `work 1`
    plus a new `orientation 1` row, so the mutation provably landed). Guard: **19 passed, 0 failed**,
    printing `ok the output names a work bucket` — because turn 3 (`tests/thing.test.sh`) is `work`
    via `TESTS` whatever turn 4 does. The assertion cannot see turn 4 at all, which is the only turn
    the AC is about. **First mutation attempted was a no-op** — `category_of_command`'s `WRITES`/
    `ORIENT` order, which an `Edit` tool call never reaches; `testing-conventions.md`'s *"confirm the
    mutation reached the copy the harness runs"* is what caught it, and the two classifier copies in
    `tools/` are the two copies in question.
  - **AC9** — `*protocol*` and `*git*`. Both words appear in the unconditional header line
    ``mechanism` is split: `protocol` is this backlog's own cost, `git` is what any project pays`
    (`tools/cost-by-category.sh:352`). Mutation: `mechanism_split` made to return `"protocol"`
    always. Both AC9 assertions stayed green; the collapse was caught only **collaterally**, by
    AC7's `0.0525`, and 18 passed / 1 failed names AC7.
  - **AC10** — `*10000*`. The `ctx/turn` column prints `100000`, `110000`, `125000`, `115000`, each
    of which contains `10000` as a substring, so no marginal-footprint value can red it. Mutation:
    `r["marg"] += rise` → `+= 0`, giving `marg/turn` of **0 in every bucket**. Guard: **19 passed, 0
    failed**. Unfalsifiable, not merely loose. The documented off-by-one is also invisible here for a
    second reason: the fixture's contexts climb **uniformly** by 10,000, so attributing the rise to
    the later turn yields the same 10,000 and only moves which bucket carries it.
  - **AC7 is the control and it is sound.** `CACHE_READ_MULT` `0.1` → `0.2` reds both of its
    assertions (`17 passed, 2 failed`). AC1–AC5 and AC11 re-verified from this session's own
    evidence; the whole suite is green (15 files, 597 assertions, 0 failed) and AC5's three named
    suites read 18 / 93 / 175, matching the develop pass.
  - **Fix is to the assertions, not the tool:** anchor each to the row it is about — AC8 to turn 4's
    bucket rather than the presence of the word, AC9 to the two bucket **rows**, AC10 to the
    `marg/turn` cell, with a fixture whose contexts climb **unevenly** so attribution is separable.
- **FR7's own change is unguarded, and this is separate from the FAIL above.** Reverting both hunks of
  `skills/verify/SKILL.md` to the pre-FR7 wording leaves **all 15 guards green**. No AC covers the
  wording (AC6 is the 2026-10-31 re-measure), so this is not a criterion failure — but in a repo whose
  guards grep prose it is the deliverable of this develop pass sitting with nothing asserting it.
- **AC6 structurally cannot close before 2026-10-31**, whoever runs the next pass: it names a
  `verify` session classified by `tools/classify-turns.sh`, and `MEASUREMENT.md`, *Re-running this*
  pins that to `--since 2026-08-25 --until 2026-10-31`. Once the three guards are fixed, this ticket
  is green on everything a session can reach today and blocked only on a dated measurement — a
  `SCHEDULED.md` split for AC6 is the honest shape, and it is `queue`'s call, not this pass's.
- **This session ran the *installed* skill, which does not carry FR7.** `~/.claude/plugins/cache/
  ai-building-tools/ai-building-tools/0.9.8/skills/verify/SKILL.md` differs from the repo at the same
  version number by exactly the two FR7 hunks — the failure `CLAUDE.md` warns about, and the reason
  this pass followed the repo copy as the authority. The FR7 procedure was exercised deliberately
  from the repo text: Step 2's status capture was fused with the first level command, and Step 7's
  intersection reused it with no second git call.
- **Develop pass, 2026-09-03, token `0bd8` — the three guards re-anchored, and the verdict's
  diagnosis needed no revision.** AC8, AC9 and AC10 are each now read out of the *row* the AC is
  about rather than out of the tool's whole output, and every one of them was driven red on the
  defect its AC names, with each mutation confirmed landed by diffing against a copy set aside
  (never against `HEAD`, which on this path never held the mutated bytes):

  | Mutation | Guard | What red |
  |---|---|---|
  | `ORIENT` tested before `WRITE_TOOLS` in `category_of_call` | 25 / 2 | both AC8 assertions |
  | `mechanism_split` returning `"protocol"` unconditionally | 22 / 5 | both AC9 assertions |
  | `r["marg"] += rise` → `+= 0` | 24 / 3 | three AC10 assertions |
  | `rise` credited to `turns[i + 1]` instead of `t` | 23 / 4 | all four AC10 assertions |
  | `CACHE_READ_MULT` `0.1` → `0.2` | 22 / 5 | AC7, the control, still sound |
  | **no-op:** `category_of_command`'s `WRITES`/`ORIENT` order | **27 / 0** | nothing, as expected |

  The no-op is the control `testing-conventions.md` asks for, and it is the same trap the verify
  pass hit: that ordering exists in a function an `Edit` tool call never reaches. A sweep with no
  no-op cannot distinguish a thorough result from a script that stopped parsing.
- **AC10 was unfalsifiable *structurally*, not by a slip of wording, and that is the reusable
  finding.** One fixture cannot serve both AC7 and AC10: AC7 needs contexts whose sums reconcile to
  an exact published decimal, and AC10 needs contexts whose rises are **unequal**, because where
  they climb uniformly, crediting a rise to the turn that appended it and crediting it to the turn
  that followed both yield 10,000 and differ only in which bucket carries it. No assertion over
  that fixture can separate the two attributions at any anchoring. The fix is a **second fixture in
  its own store directory and a second tool run** (`$FIX/ac10`, `$OUT10`) — contexts 100000 →
  110000 → 140000 → 190000, so the correct attribution is protocol 10000 / git 30000 / work 50000 /
  orientation 0 and the off-by-one is 0 / 10000 / 30000 / **50000 charged to the last turn, which
  appended nothing at all**. Two cheap fixtures beat one compromised one.
- **The guard file's fixture comment described a fixture this repo has never had, and that is
  probably what produced the weak assertion.** The block above the fixture read
  `turn 4  Read .../SKILL.md  orient`, where the code has always constructed an `Edit` — and AC8 is
  precisely *"an Edit of a skill file is `work`, not `orientation`"*. Read alongside a comment
  saying turn 4 is orientation, `case "$OUT" in *"work"*` looks like a reasonable question. **A
  comment in a guard file is a cache of the fixture and ages exactly like a figure a ticket quotes
  about a file it does not own** (`develop` Step 2): it reads correctly on its own, the arithmetic
  around it stays consistent, and nothing in a diff looks wrong. Corrected in the same commit, with
  the reason left in place.
- **Anchoring to rows makes bucket collapses cascade, and a future reader should expect that.** The
  AC9 mutation reds five assertions, not two: merging `git` into `protocol` also moves AC7's 0.0525
  and two AC10 cells. That is the anchoring working — but a one-line mutation producing a
  five-failure tally reads like a broken harness, and `testing-conventions.md` warns that an
  implausibly large count usually *is* one.
- **FR7's change is now guarded, closing the second half of the verify verdict.** Four assertions in
  `tests/cost-by-category.test.sh` anchor the four claims of the two `skills/verify/SKILL.md` hunks —
  Step 2's fused capture and its hold, Step 7's reuse and its silence on git. Reverting either hunk
  reds two of them (25 / 2 each). Each asserted phrase sits **within one line** of the source,
  because `grep` is line-based and a phrase straddling a wrap cannot be matched at all, which is why
  rewrapping a guarded paragraph in this repo is a breaking change (`CLAUDE.md`).
- **Whole suite green: 15 files, 605 assertions, 0 failed** (`cost-by-category` 19 → 27). AC5's three
  named suites read 18 / 93 / 175, matching the develop and verify passes exactly. The tree was
  clean at claim and at hand-off — none of the foreign dirt the previous pass had to work around.
- **`qa_level` left at `verify`**, deliberately: this pass proved the level right rather than wrong.
  The deliverable is a set of guards, and the only way to check a guard is to mutate the code under
  it and watch the colour — which is `verify` Step 3's own procedure.
- **AC8, AC9 and AC10 are left unticked for `verify` to re-take.** They stood `[x]` beside a FAIL
  verdict, which is the file contradicting itself; and this session may not certify its own guards
  (`develop` Step 5, *do not self-certify*). **AC6 is untouched and still cannot close** — it names a
  `verify` session classified by `tools/classify-turns.sh`, pinned to `--until 2026-10-31` by
  `MEASUREMENT.md`, *Re-running this*. Once AC8–AC10 are re-taken this ticket is green on everything
  a session can reach today and waiting only on that date; the previous pass's suggestion of a
  `SCHEDULED.md` split for AC6 is still the honest shape and still `queue`'s call.
- **Verify pass, 2026-09-03, token `e940` — PASS on everything a session can reach today, but
  ADVISORY, so it does not close.** AC8, AC9 and AC10 were each driven red on the defect the AC
  names, by this session's own mutations, and the develop pass's tally table reproduced **exactly**:
  25/2, 22/5, 24/3, 23/4 for the four defects, 22/5 for the AC7 control, and **27/0 for the no-op**
  (`category_of_command`'s `WRITES`/`ORIENT` order, which an `Edit` call never reaches). AC11's two
  assertions were mutated too — the section rename reds one; the FR7 hunks were each reverted and
  red their own two guards, 25/2 each. Whole suite **16 files, 633 assertions, 0 failed** (605 + the
  28 of `release.test.sh`, new since the develop pass); AC5's three named suites read 18 / 93 / 175,
  matching both previous passes.
- **Why it is advisory rather than a close.** The tree was clean at Step 2 and went dirty *during*
  the pass: another session (`0081`, token `08b7`) added `tests/handoff.test.sh` and
  `skills/queue/templates/handoff`, then modified `.claude/backlog/close`,
  `references/CONCURRENCY.md`, `references/CONCURRENCY-INCIDENTS.md`, `skills/queue/SKILL.md`,
  `skills/queue/templates/close` and **`skills/verify/SKILL.md`**. The last two of those intersect
  this run's evidence set — `skills/verify/SKILL.md` carries the four FR7 assertions, and
  `references/CONCURRENCY.md` is what the QA plan's rule-name cross-check for AC1 reads. Step 7
  forbids judging whether foreign dirt *looks* relevant, so the intersection is non-empty and the
  ticket stays at `next: verify, status: ready`. **AC8–AC10 are ticked anyway**: their evidence is
  `tools/cost-by-category.sh` and `tests/cost-by-category.test.sh`, neither of which is dirty, and
  every mutation behind them was this session's own.
- **FR7's own premise is false in this repo, and this pass is the counter-example.** Step 7 now
  reads "the tree is either clean throughout or Step 2 already said so" — which is what licenses
  issuing no git command at verdict time. Both disjuncts were false here: Step 2 said clean, and the
  tree went dirty afterwards. A session following FR7 literally would have reported a **plain PASS
  and closed**, against an evidence set that had moved underneath it. The turn FR7 removed is the
  turn that catches a session starting work mid-pass, which `CONCURRENCY.md` (*The working tree is
  shared too*) says is the normal case here. Parked in `FINDINGS.md`; it needs a ticket, and filing
  one is not this pass's to do.
- **AC11's second assertion is loose, though not unfalsifiable.** It is
  `grep -qE '87%|0\.0983|0\.1132'` over the whole of `MEASUREMENT.md`. Changing *both* per-turn
  figures while keeping the `87%` leaves it green (27/0), so the published figures can go stale
  under it; only removing all three tokens reds it (26/1). By Step 3's own test this is not a
  criterion failure — the outcome AC11 names, that the record states the comparison, still holds
  under that mutation — but it is the same shape as the defect that sent AC8–AC10 back, one degree
  weaker.
- **AC6 remains the only unreachable criterion**, unchanged and for the reason both previous passes
  gave: it names a `verify` session classified by `tools/classify-turns.sh`, pinned by
  `MEASUREMENT.md`, *Re-running this*, to `--until 2026-10-31`. The `SCHEDULED.md` split is still
  the honest shape and still `queue`'s call.
- **FR7 amended 2026-09-03, token `fab9`, at Aaron's direction — the hole the verify pass found is
  closed.** FR7's Step 7 wording asserted *"the tree is either clean throughout or Step 2 already said
  so"*, and that is what licensed issuing no git command at verdict time. It is false in this repo:
  the `e940` pass saw a clean tree at Step 2 and six dirty files by the verdict, two of them
  (`skills/verify/SKILL.md`, `references/CONCURRENCY.md`) inside its own evidence set. Followed
  literally the pass would have closed on a plain PASS.
  **The fix keeps FR7's actual goal.** Step 7 now takes a fresh capture *fused onto the last
  evidence-gathering command* — `<last check>; git status --porcelain` — so the intersection is
  computed against a tree that has not moved since, and still costs no turn of its own. Step 2's
  capture is demoted to the baseline that refresh compares against.
  **Guarded, TDD, four assertions** in `tests/cost-by-category.test.sh`, each anchored to its own
  claim rather than to the paragraph: full revert reds all four (25/4), dropping only the
  `never a turn of its own` clause reds exactly one (28/1), dropping only the falsified-premise
  sentences reds exactly two (27/2), and reflowing an unguarded sentence nearby reds none (29/0).
  Whole suite green: **17 files, 744 assertions, 0 failed.**
  **This does not re-open the `e940` verdict's ticks.** AC6 is still the only unreachable criterion,
  and no AC covers FR7's wording — the next `verify` re-take checks the new assertions as it would
  any other guard.
- **AC6 split out to `0088` on 2026-09-03**, at Aaron's direction, so this ticket could close on the
  criteria a session can reach. It is the shape all three previous passes named and declined to
  perform, being `queue`'s call. `.claude/backlog/close` ticks every `- [ ] AC` line unconditionally,
  so leaving AC6 in place and closing would have recorded an unrun measurement as verified — the
  `0044` failure mode from the other side. `0088` carries AC6 verbatim as its own AC1, plus the
  budget comparison, the dollar re-measurement and the record-it-either-way requirement.
