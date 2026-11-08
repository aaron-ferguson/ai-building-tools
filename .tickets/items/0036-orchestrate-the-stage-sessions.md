---
id: "0036"
title: Orchestrate the isolated stage sessions from one supervising session
type: feature
next:
status: active
created: 2026-08-24
source: user
parent:
ships: incrementally
relates:
  - "0026"
  - "0027"
---

## Outcome

One supervising session drives a bounded working session end to end. It dispatches `develop` and
`verify` into their own contexts, advances each ticket on what the previous stage wrote to disk,
stops at the findings gate to run a `retro`, and hands the release chain back to a human as a
checklist. It claims no row, decides nothing a person should decide, and **its own context does not
grow with the length of the run** — which is where 0009's central claim gets tested end to end.

## Why this exists

Project 0009 split the suite into one skill per session and moved the handoff onto disk. That
removed the context cost — and moved it onto **the human**, who is now the only thing that knows a
`develop` session has stopped, that the ticket is sitting at `next: verify`, that the buffer has
filled, and that a retro is due. Nothing in the suite drives the loop; `develop` Step 8 and
`verify` Step 7 both end by *naming a command for a person to type in a new window*.

The cost of that is not hypothetical. In this repo, on 2026-08-23, hand-driving produced a wrong
take: `0026` was read as blocked and skipped, which is recorded in `RANKING.md` as an argument for
0027. The same day, an eleven-ticket run spent **~44 tool calls of pure mechanism** on claims and
closes a script now does. Every cycle the human drives is a cycle where a step can be dropped, and
the steps most often dropped are the ones with no output of their own — parking a finding, running
the full suite, releasing a claim.

Aaron's request, verbatim, 2026-08-23:

> I want to build an agent or workflow that strings together the tools inside this plugin so that I
> can launch one claude session to orchestrate a larger real world working session. It should keep each skill limited
> to a single context window, but have the one session orchestrate:
> 1. Queuing up new work and updating rows as needed.
> 2. Designing two working sessions worth of tickets so that we don't have to stop development mid-session due to unfinished design.
> 3. Developing a batch of ready tickets while optimizing for 1. effectiveness and 2. efficiency. Working on tickets one at a time when it will produce a better result and parelellizing work when appropriate. 
> 4. When a develop task is done, it spins up a new context window for the verify agent, which either closes the ticket or kicks it back to develop.
> 5. Run a retro at the end of the working session, update documentation, the queue, and skills
> I should be able to interact with that orchestrating session as needed.

**The tension this ticket has to resolve, rather than ignore.** 0009's finding was that cost comes
from context *accumulating* across a run. A supervisor is the one component that by definition
spans every stage, so a naive one re-creates the 191,752-token turn at the top level — worse,
holding a summary of *everything* instead of one ticket. Isolation is preserved only if the
supervisor reads the same disk signals a fresh session would and never ingests a stage's
transcript. That constraint is FR7, and it is a design input rather than an optimisation.

**Aaron's direction, 2026-08-24, on revisiting the ticket:**

> What if one of my working sessions involves doing enough development that it results in a full
> findings and ends with a single retro? That way, there's still a human in the loop to bump the
> version, reinstall, and start a new session. Part of this would also involve trimming down the
> output of each agent to only the necessary details. That way, the orchestrator doesn't fill up with
> unnecessary context and is just getting the status changes to be able to orchestrate effectively.

**This proposes an answer to the design question, and what makes it a good one is arithmetic rather
than convenience: the findings threshold becomes the supervisor's context budget.** A run is bounded
at FR3's gate, so the supervisor accumulates a known number of cycles and then ends — which turns FR7
from "bounded across an unbounded run", which nothing can honestly promise, into "bounded across N
cycles", which a design can be checked against. It also deletes the hardest problem in this ticket:
**nothing has to survive its own reinstall**, because the run is over before the reinstall happens.

**What it left open** was which mechanism that budget then permits — a bounded run may put subagents
back in scope, which the design question had assumed it could not — and what a trimmed stage outcome
must carry to still be enough to orchestrate on. **Both were settled on 2026-08-24**; the decision,
what it rejected, and the arithmetic behind it are in *Notes & decisions*, and the mechanism it fixed
is what every acceptance criterion in the three tasks is written against.

## Why `ships: incrementally`

The three tasks are independently verifiable and land in dependency order. **0038 ships standing on
its own**: `./next --drive` and `./next --findings` answer "what should happen next" and "how full
is the buffer" from the backlog alone, which is useful to a hand-driven session before any
supervisor exists, and it is testable with fixtures and no subprocess. 0039 consumes that decision,
and 0040 hardens the loop 0039 creates.

**`incrementally` means each slice is separately verifiable, not that the project may stop
anywhere.** The one sequencing mistake available here is shipping 0039 and stalling before 0040:
that leaves a runnable unattended loop with no lock policy and a guessed spend cap — the exact
hazard 0040 exists for, on a lock whose stranding blocks every claim and close in the repository,
not just the run's. 0040 is ranked directly below 0039 for that reason and not merely by dependency
order.

## Slices

1. **0038 — `./next --drive` and `./next --findings`, and their fixtures.** FR3's counting half,
   FR8's routing table, FR9's mode and exit-code contract, FR17's depth data. AC6 (counting half),
   AC9, AC10, AC11, plus AC28–AC29 added at slicing time. **This is the slice to rank** — it is
   where every decision that can be wrong the same way twice actually lives, and the rest is
   instructions.
2. **0039 — the `orchestrate` skill and `outcome.schema.json`.** FR1, FR2, FR3's gating half,
   FR4–FR7, FR10–FR14, FR17's reporting half, and the README change. AC1–AC5, AC6's gating half,
   AC7, AC8, AC12–AC24, AC27. Blocked by 0038 for its routing probe.
3. **0040 — the lock policy and the budget-kill recovery.** FR15, FR16. AC25, AC26. Hardening on a
   loop that has to exist first; blocked by 0039.

**FR and AC numbers are 0036's throughout and were not renumbered**, so the design decision and the
review amendment below still resolve against the tasks that carry them.

## Cross-cutting commitments

- **No rule is dropped anywhere in this project.** 0009's commitment, inherited unchanged. FR13
  changes what a stage *reports*; the trim is to a stage's closing narrative, never to a check, a
  test or a standard. `verify` Step 7's evidence table is a check and moves rather than going.
- **Routing lives in exactly one place.** The FR8 table is implemented by `./next --drive` (0038)
  and by nothing else. No skill restates a routing rule — the same argument FR9 makes for not
  writing a fourth script, and the reason `develop`, `verify` and `retro` are untouched.
- **Nothing routes on the run log**, with one stated exception rather than a collision left to be
  discovered: 0038's same-stage-twice guard takes *a completed outcome in between* as an input, and
  only the log holds that fact. The log is read for **what already completed**, never for **what to
  do next**.
- **The hand-driven loop keeps working, unchanged, at every slice boundary.** The plugin is public
  and installed on backlogs that will not migrate on our schedule; a session running `develop` or
  `verify` by hand behaves as it did at 0.9.3 after each of the three tasks.
- **The supervisor holds no claim and takes no lock.** Every ownership mechanism in this suite is
  built on rows and tokens; a driver that holds neither is invisible to all of them, which is a
  constraint on the design rather than a convenience.

## Out of scope

- **Relaxing any standard, or changing what any stage *checks*.** 0009's cross-cutting commitment,
  unchanged. FR13 does change what a stage *reports*, which is a deliberate widening recorded in
  *Notes & decisions*: the trim is to a stage's closing narrative, never to a check, a test or a
  standard.
- **Reducing what a stage writes to disk.** FR13 trims what the supervisor *reads*; FR14 is the guard
  that the detail lands somewhere durable instead. A ticket's *Notes & decisions*, `FINDINGS.md` and
  the FR10 log all get *longer* under this change, not shorter.
- **Making `retro` a lifecycle stage or a `next` value.** FR3 schedules it; it stays a cadence job
  run in its own session, as its own skill states.
- **Automating a `design` answer, or `prototype`.** A design ticket needs a human decision; the
  supervisor routes it to one (FR8).
- **Concurrent stage *sessions*. The loop is sequential, and that is a decision rather than an
  omission.** Ask 3 of the original request says "parallelizing work when appropriate" — and Aaron
  confirmed on 2026-08-24 that **parallelism was an option, not a requirement: sequential is fine
  where it makes more sense.** It does, on three facts already on disk. `claim` and `close` serialise
  on one lock, so two stages spend their time contending on it (FR15). `CONCURRENCY.md`'s *The
  working tree is shared too* means two stages in one tree collide outside the lock's protection
  anyway, and this repo's own `FINDINGS.md` already holds the incident where a concurrent session
  swept 41 lines of another's uncommitted work into its commit. And `--max-budget-usd` gives a
  serial loop the same throughput ceiling for a fraction of the failure surface. **What the ticket
  delivers instead is concurrency of *tickets*, not of sessions**: FR2's gate batches two or three
  tickets into one session, which is where the startup saving actually is (AC4). Worth re-opening if
  stages ever run in separate worktrees, which is the only form that makes the tree question go away.
- **Automating asks 1 and 2 of the original request.** "Queuing up new work" and "designing two
  sessions' worth of tickets" are **escalations** under FR8, not automation — a `queue` row is
  under-specified and a `design` row needs a decision, and both are things this suite deliberately
  routes to a person. **So this ticket delivers asks 3, 4 and 5 of the five, and routes 1 and 2.**
  Said plainly here because the alternative is a first run that halts on the first `next: design` row
  and reads as broken. FR17's depth report is the honest half of ask 2: it tells the human, before
  anything is dispatched, how far the backlog goes before it needs them.
- **Replacing `next`, `claim` or `close`.** The supervisor drives them. FR9's probe is additive.
- **Pushing or releasing unattended**, in any form, however clearly the user asked for the loop to
  keep moving.
- **One supervisor across several repositories.** FR12 is one backlog.
- **A dashboard or reporting UI.** FR10's log is on disk and read by a session.

## Notes & decisions

### The design decision, 2026-08-24 — settled by `/design`

**A stage session is a separate `claude -p` process, launched in the background by the supervisor and
returning a `--json-schema`-validated JSON outcome on stdout. Not a subagent.** The supervisor's own
state is the backlog; the run log is an append-only audit trail that nothing routes on. The routing
probe is `./next --drive`, a mode on the existing reader. Escalate a `verify` bounce and a stale
contract rather than deciding either.

**The arithmetic the ticket asked for, done — and it acquits both mechanisms.** Sub-question 1 said to
size a real FR13 outcome before ruling either in or out, so: a three-field outcome from
`claude -p --json-schema` measured **64 bytes**, and a full FR13 outcome is **~280 bytes (~80
tokens)**. The findings rate is measurable from this repo's own history — `git log --numstat` on
`FINDINGS.md` shows **2–3 entries parked per stage session**, consistently, across twenty-odd
sessions, so **~5 per closed ticket**. Against `retro`'s ~8-entry cadence, and with `develop`
batching a gate of two or three tickets, a bounded run is **one develop gate, its verify sessions,
and the retro — N ≈ 4–6 stage sessions**. Stage outcomes into the supervisor across a whole run:
**~400 tokens.** Against 0009's observed 191,752 tokens per turn that is noise, at fifty times the
estimate too.

**So the decision does not rest on FR7's arithmetic, and saying otherwise would be dishonest.**
Aaron's bounded run succeeds so completely that it deletes the factor sub-question 1 assumed would
decide this. What it also shows is where FR7's real risk moved: **the bound belongs on what the
supervisor reads from disk, not on what stages return to it.** One unnecessary `QUEUE.md` read costs
more than every stage outcome in the run combined — which is why FR9's probe prints a decision and the
supervisor never opens the queue, exactly as `develop` Step 1 already requires of a stage.

**What the decision rests on instead — four things, in order.**

1. **FR13 is enforceable in the subprocess form and only describable in the other.**
   `--json-schema` validates at the tool-call layer, so stdout is the object or the stage failed.
   FR13's own complaint is "a contract described in three skill files and implemented in none"; the
   flag is the implementation. A subagent returns model-authored prose that nothing structurally
   caps, so FR7 would be a hope about verbosity.
2. **Cost attribution, which the Performance NFR requires.** `--max-budget-usd` is enforced per stage
   (confirmed: a stage refused to start under `$0.05`, which incidentally prices session startup),
   and each stage has its own session id and transcript — the input
   `tools/harvest-usage.sh` already parses, and the source of the per-ticket `cost_tracking:` the
   measure is built from. A subagent's spend is not separately attributable, and the measure is cost
   *per closed ticket*.
3. **Permission scoping.** `--allowedTools` and `--permission-mode` are per invocation, so each stage
   gets the narrowest authority that works and holds it only for that process —
   `security-conventions.md`, *machine identities get their own scoped credentials with the narrowest
   permission set that works*. A subagent inherits the supervisor's session-wide posture, so granting
   `develop` what it needs grants it to the whole run.
4. **Observability.** A separate transcript survives the supervisor's death. A subagent's context does
   not, and the NFR is explicit that the supervising conversation is what dies.

**The trade-off being accepted, stated plainly: a non-interactive stage cannot ask a human anything.**
Everything it would have asked becomes an escalation in its outcome, and it must be handed its
permission posture up front instead of approving calls as they arise. That is a real reduction in
per-stage safety, bought for the loop. Three mitigations, all in the ACs: tools scoped per stage and
never `--dangerously-skip-permissions` (AC19), push and install excluded outright (AC7, AC8), and a
spend cap as the blast radius (AC19). **If Aaron disagrees with any of this, it is the permission
posture** — how much authority an unattended stage may hold is his call, not a fact I can look up, and
the ACs hold either way because "no push, no install, scoped tools" was already in the NFR table.

**What was rejected, and what would have to be true for each to win.**

- **Subagents inside the supervisor's session.** Would win if FR13's shape could be enforced on a
  subagent's return, or if per-stage cost attribution and per-stage permission scoping stopped
  mattering. Its genuine advantage — FR6 for free — turned out to be available anyway: a background
  subprocess is what the harness notifies on, so FR6 is free in both. Worth re-opening if a future
  harness validates a subagent's return against a schema.
- **The `Workflow` tool** — a deterministic orchestration script with `agent()` stages. The best fit
  for a *fan-out*, and this is not one: FR1–FR3 are a sequential loop with a mid-run gate, and a
  workflow runs to completion in the background, so FR6's "redirect it mid-run" has nowhere to land.
  Would win if the loop were fixed-shape and non-interactive.
- **`SendMessage` to other local sessions.** Rejected on a fact: those sessions have to already exist,
  started by a human, so it cannot open a cycle — it is a channel, not a mechanism.
- **`CronCreate` / `/loop`.** Schedules a wake-up; does not decide anything. Both are ways of *polling*,
  which AC12 forbids for a reason — the harness already re-invokes the supervisor when a background
  process exits, so a poll pays turns for silence.
- **A supervisor that survives its own reinstall.** Not rejected on merit — Aaron's bounded run makes
  it unnecessary, and `retro` Step 5 says a session cannot use skills installed after it started.

**Sub-question 2, answered in the half that was still open: the backlog is the state, so there is no
run state to resume.** A resuming supervisor derives its next action from `./next --drive` plus
`FINDINGS.md`'s entry count, both already on disk and both authoritative. The log carries what already
escalated and what the run spent — provenance, not position. **That makes crash-resume and FR4's
planned ending the same path**, which is what sub-question 2 asked, and it means a deleted log changes
the next action not at all (AC17). It also means FR10 cannot go stale or disagree with the backlog,
which a stored position could.

**Sub-question 3, on the two arguable escalations: both escalate.** A `verify` bounce goes to the
human because `verify` Step 5 sends a ticket back to *either* `develop` or `queue`, and which one it
chose already encodes whether the build or the contract was wrong — a supervisor that auto-re-develops
spends a whole stage session to rediscover a bad contract. A stale contract escalates for the same
reason it stops a batch today. **The cost of this is that the loop stops more often than the request
implies**, and the mitigation is that the escalation carries `verify`'s verdict pointer, so the human
answers in one line rather than reading a transcript.

**Sub-question 4: both, and the split follows the existing one.** `./next --drive` is a mode rather
than a fourth script — `next` already owns takeability, the graph and the exit-code convention, and
0006, 0022 and 0031 are three tickets fixing that parsing in one place. The skill is the supervisor's
instructions; the script is every decision that can be wrong the same way twice.

**Sub-question 5: no polling, so FR6 is nearly free.** The stage runs as a background process and the
harness re-invokes the supervisor when it exits. Between dispatches the supervisor is idle and answers
in one turn.

**Sub-question 6: escalations, the gate firing, and a stage exiting non-zero or over budget
interrupt.** Stage started, stage returned green and ticket closed land in the log silently. One
addition the sub-question did not ask for and the *Problem* section's last paragraph demands: **each
cycle's report carries its findings-parked count** (AC21), because after FR13's trim that count is the
only thing telling the user the run is learning — and nothing goes red when a session learns less than
it could have.

**Two corrections to the ticket, made rather than left implied.**

- **FR2 said "row"; the unit is a gate.** `develop`'s opening rule and `README.md`'s *One skill per
  session* both make the batching unit a set of tickets sharing `expects:` or a parent, because what
  batching saves is per-session startup. A supervisor dispatching one session per row re-pays that per
  ticket and quietly regresses the saving 0009 exists for — while every test still passes. FR2 and AC4
  now say gate. **This widens the ticket**, and it is recorded here rather than absorbed.
- **FR8's escalation list was missing an infinite loop.** `verify` Step 7 leaves an advisory PASS at
  `next: verify, status: ready` deliberately, so a supervisor routing on `next:` restarts `verify` on
  that ticket forever. Added, together with its general form — the same ticket reaching the same stage
  twice in one run — which is the only guard available given FR9's probe is stateless by design.

**No prototype is needed and none should be run.** Every input was a checkable fact and was checked:
the CLI's schema enforcement and budget enforcement by running them, the findings rate from
`git log --numstat`, the batching unit from `develop`'s own text. The one thing not checked — that
`claude -p` invoking `/ai-building-tools:develop` resolves the plugin skill and completes a stage — was
not checked because doing so consumes a real ticket, and it is AC1 rather than an open question.

**Left as a known cost, not a gap: `FINDINGS.md` holds 28 entries against a threshold of about 8.**
On the measured rate the gate would fire almost immediately, which is correct behaviour and an
uncomfortable amount of it. FR3's threshold is already configurable per project, and this repo's rate
is inflated because its tickets are *about* the tooling, so every one surfaces tooling defects. A
project whose tickets are about a product should expect longer runs. Worth revisiting if the first
supervised run spends more on retros than on tickets.

- **Routed to `design`, not `develop`**, on the first of `queue`'s two triggers: a decision blocks
  writing acceptance criteria. There is no surface here and nothing to look at, so the second
  trigger does not apply — this is not an unfamiliar-therefore-design routing.
- **Ranked Tier 4, above 0035 and below 0034**, with the full reasoning in `RANKING.md` including the
  promotion argument that was considered and rejected.
- **`relates: 0026`, deliberately not `blocked_by`.** 0026 produces the observed per-turn baseline
  this ticket's Performance NFR measures against, and it is `waiting` on a person. The precedent is
  0025, recorded in `RANKING.md`: *blocking a correct piece of work on an unscheduled measurement is
  how it waits forever.* Fold 0026's figure into the measure when it lands.
- **`relates: 0027`, also not a blocker.** The supervisor's whole interface is `./next`, `./claim`
  and `./close`, and this repo's own backlog does not have them installed yet — 0027 does that. The
  design pass does not need them; a build exercised end-to-end here does.
- **This ticket may come back to `queue` as a project.** If the answer to the design question is
  multi-session work — plausible at `size: l` — the slicing depends entirely on that answer, so
  inventing children now would rank slices against a mechanism nobody has chosen. The precedent for
  the return is 0021.
- **Two findings in `FINDINGS.md` are load-bearing here rather than incidental.** The 2026-08-23
  entry on the installed plugin diverging from source at the same version number is what makes FR4's
  install-and-restart step a requirement rather than a courtesy. The 2026-08-23 entry on *"one skill
  per session has no correct answer for a user who deliberately runs two"* is the same gap from the
  other side: the supervisor is a session that runs **no** skill and directs others, which no
  existing skill's opening paragraph describes.
- **The supervisor is where this suite's central claim gets tested.** If the loop can be driven
  without the supervisor accumulating, 0009's model holds end to end. If it cannot, that is a real
  finding about the model and not merely a failed feature — which is why FR7 is a requirement with a
  number rather than a performance note.
- **Amended 2026-08-24 on Aaron's revisit, before any claim.** Two additions: the run is bounded by
  the findings gate and ends there (FR4, FR5, and the direction quoted in *Problem*), and every stage
  emits a trimmed structured outcome (FR13, FR14). Re-checked against the new shape per `queue`'s
  amend rule — **`size` stays `l`**: FR4, FR5 and FR10 all get *cheaper* because nothing has to
  survive a reinstall, and FR13 spends that saving back by reaching into three existing skill files.
  *(The three-skill-file reach was removed by the 2026-08-24 review amendment below — see it for the
  re-check.)*
  **The ACs are still unwritten**, so what moved is the three invariants, the first of which now has a
  bounded run to be measured over. **The QA plan's named checks grew** by FR13's assertion and the
  size guard's widened scope. **Out of scope changed materially**, and says so rather than being
  quietly widened.
- **The second-order cost of the trim, and the thing to look at first on revisiting.** FR6 asks the
  supervisor to surface insights; FR13 removes the stage narrative it would most naturally surface
  them *from*. After this amendment, therefore, **everything the user learns comes from what stages
  write to disk** — which promotes FR14 from a courtesy to the load-bearing requirement, and makes
  *Notes & decisions* and `FINDINGS.md` the product surface rather than a byproduct. Built weakly,
  the loop runs smoothly and quietly teaches the user nothing, which is the one failure mode this
  suite has no check for: nothing goes red when a session learns less than it could have.

### Review amendment, 2026-08-24 — Aaron's read of the settled design, before any claim

Aaron reviewed the design decision against the scripts, the three stage skills and the CLI's actual
flags. **Five things were wrong or missing, and two of them would have shipped as silent defects.**
All are now in the requirements above; what follows is the reasoning that does not belong in an FR.

**1. `--bare` was disqualifying, and AC1 recommended it.** The design pass cited *"`--bare`'s own
documentation states skills still resolve via `/skill-name`"* — true, and it read the wrong half of
the paragraph. `--bare` also skips **CLAUDE.md auto-discovery**, so a `--bare` stage session builds
**without the project's conventions**, which `config.yml` makes mandatory and which is the one thing
this suite exists to enforce. It would have passed every test in `tests/`, because nothing greps a
subprocess's loaded context. It also forces `ANTHROPIC_API_KEY` (OAuth is never read), which puts a
secret in an unattended loop's environment and splits AC14's cost figure across two billing paths.
**Corrected to plain `claude -p`, plus `--add-dir` for the sibling conventions repo — without which
AC19's narrow scoping blocks the very files `config.yml` points the stage at — and a pre-assigned
`--session-id` so a dead supervisor can still find the transcript.** All four load-bearing flags
were re-confirmed present: `--json-schema`, `--max-budget-usd`, `--allowedTools`, `--permission-mode`.
**The lesson worth keeping: the design pass verified that the flags existed and did not verify what
else they did.** A flag confirmed by running it is confirmed for the thing you ran.

**2. FR13 was singular and AC4 is plural.** "*The* ticket, the stage, the verdict" against a gate of
two or three. One stdout object for three verdicts reports one and drops two — and drops them
silently, since a valid single-ticket object satisfies a schema that says one ticket. Now an envelope
over an array, with AC2 asserting the differing-verdicts case.

**3. Six transitions the stage skills can write were not routed at all** — five of them the *unhappy*
endings of `develop`, the stage the supervisor dispatches most: `develop` → `design` (S4, when what is
missing is a decision), `develop` → `develop` on a tree it could not get green, `develop` → `waiting`,
`develop` gaining a `blocked_by`, a ticket becoming a project and its row leaving `QUEUE.md`, and the
backlog simply running dry. FR8 is now a table derived from the skills rather than a list derived from
the happy path. **The general lesson: the first draft's escalation list was assembled from what the
supervisor should refuse to decide, not from what the stages can actually write.** Those are different
sets, and the second one is enumerable.

Two adjacent defects fell out of writing the table. **The `status:` vocabulary was never pinned** —
`./next` reads the `QUEUE.md` column (`ready|waiting|blocked|in-progress`) while item frontmatter
carries `active` and `done` besides; unpinned, AC9's fixtures and the skill prose get written against
different vocabularies. **And the same-stage-twice guard, as drafted, blocked AC17's own recovery
path**: a supervisor killed after dispatch but before the claim leaves the row `ready`, the stateless
derivation re-dispatches, and a naive guard escalates the recovery. It needs an *intervening completed
outcome*, which only the log holds — so "nothing routes on the log" now carries its one stated
exception rather than a collision.

**4. The token budget was measuring the wrong term.** The design pass's arithmetic on stage outcomes
(~80 tokens each, ~400 per run) is correct, and it correctly noted the bound belongs on what the
supervisor reads from disk — then budgeted neither. The supervisor's cost is **turns × per-turn
floor**, and the floor is fixed before the first stage runs: ~20k, of which `CLAUDE.md` plus the
imported `CONVENTIONS_CORE.md` is a measured 2,645 words. At three turns per cycle and N ≈ 4–6 that is
~15 turns and ~350–400k cumulative input — **FR13's entire trim is ~0.1% of it, and one turn removed
per cycle is worth sixty times the whole trim.** FR7 now states a floor, a growth figure and a
turns-per-cycle budget. **AC13's old assertion could not fail**: ~800 tokens of growth against a ~20k
floor is inside any tolerance anyone would write, so "last cycle within tolerance of the first" was a
green light dressed as a measurement.

**5. On trimming the stage reports: the trim is right and the token argument for it is wrong.** A
stage's closing report is ~800 output tokens in *that stage's* budget, generated after the work is
done — roughly 0.3% of the $4.45-per-closed-ticket baseline. Nobody should spend a requirement on
that. **The real argument is behavioural: the report is where a lesson goes to die.** A stage with an
audience writes its diagnosis to the audience instead of to `FINDINGS.md` or *Notes & decisions*.
Removing the audience removes the sink — which promotes FR14 from a courtesy to the point of the
exercise, exactly as the previous amendment predicted from the other direction.

But the trim had an unenforced edge, and it was the expensive one. ***Out of scope* says the trim
never touches a check; `verify` Step 7's evidence table is narrative-shaped and is a check** — each
AC, how it was checked, the actual output, which is the paragraph that forces enumeration against real
output instead of against memory. AC20 named three content kinds to relocate and not that one. It now
moves into the item file, where it belongs anyway as a closed ticket's QA record. **What is actually
deleted is the salutation**: the recap and the "now run `/verify 0036` in a new session".

And the trim turned out to justify a **scope cut rather than a scope increase**. Under
`-p --json-schema` the invoker supplies the schema and the last message *is* the object, so no stage
skill needs to describe the shape — which deletes the edits to `develop`, `verify` and `retro`, the
per-file `tests/` assertions, the widened `skill-size` scope, and almost all of AC23's regression
surface. One schema file is the single source, which is the argument FR9 already makes for `next`.
`develop` — already over the size goal with a recorded reason — is not touched at all.

**Four things nobody had thought through, now FR15–FR17 and AC25–AC27.**

- **The lock was not mentioned anywhere in the ticket.** `claim` and `close` take
  `.claude/backlog/.lock/`; the supervisor's entire job is launching processes that take it; two parked
  findings already say the busy-lock procedure strands a close and that the protocol cannot be
  satisfied by hand. A stage killed holding it blocks every future claim and close in the repo. The
  supervisor now never takes it, never breaks it, and escalates on an aged one.
- **`--max-budget-usd` creates the failure mode it exists to bound.** A stage killed mid-work by its
  own cap leaves a claim held, a tree dirty and possibly the lock taken — strictly worse than AC16's
  supervisor-killed case, where the tree is clean, and not something `./next --drift` can see. The cap
  is now derived from `cost_tracking:` history rather than guessed, and its escalation names the claim,
  the dirty paths and the lock.
- **The findings gate rested on a count this repo already knows is wrong.** A parked 2026-08-24 finding
  says `FINDINGS.md` carries two entry formats and every count off the obvious grep is low —
  `MEASUREMENT.md` published 26 and 28 in adjacent sentences against a format-tolerant 42. A gate
  reading a reliably-low number fires late and silently. Now `./next --findings`, format-tolerant, with
  a guard pinning the format. **And the threshold had no home**: FR3 said "configurable per project"
  while `config.yml` has no key and `retro`'s cadence is prose including "or weekly", which no driver
  can read. Key added; the driver gates on the count only.
- **`retro` can re-fire its own gate.** `retro`'s Step 6 parks findings, so a stateless re-derivation
  after a retro reads a still-over-threshold count and dispatches another retro, which parks more. FR4
  ends the run before this bites in the planned case — AC17's resume path reaches it. Gate now
  evaluated once per run.

**And three smaller ones.** The exit-code contract was asserted by AC11 and specified nowhere, while
`next` already spends 0 on *"nothing is takeable"* — so "nothing to do" would have been
indistinguishable from "dispatch this"; codes are now named. **AC14 omitted the supervisor's own spend
from cost-per-closed-ticket**, which attributes to no ticket's `cost_tracking:` — reporting a win that
was partly unmeasured overhead, in a ticket whose whole justification is that figure. And **AC22 had
no detection mechanism**: `command -v claude` cannot see an unauthenticated CLI or whatever a nested
session is permitted to do, so the check is now a real trivial dispatch, which is also the cheapest
possible test of AC1's untested premise.

**Two scope statements written down rather than left as inferences.** Ask 3's *"parallelizing work when
appropriate"* — **Aaron confirmed on review that parallelism was an option, not a requirement, and
sequential is fine where it makes more sense.** It does: one lock, one shared working tree, and a
recorded incident of a concurrent session sweeping 41 lines of another's uncommitted work into its
commit. The ticket's answer to "parallelise" is concurrency of *tickets* — FR2's gate — not of
sessions, and that is now in *Out of scope* with the reason. Separately, **asks 1 and 2 are routed
rather than automated**, so this ticket delivers three of the five; FR17's depth report is the honest
half of ask 2, and without it the first run halts on the first `next: design` row and reads as broken.

**Re-checked against `queue`'s amend rule. `size` stays `l`, and that is now the ceiling rather than a
description.** The FR13 cut is real — three skill files, three test assertions and a widened size
guard all removed — but FR15–FR17, `--findings`, the format guard, the exit-code contract, the
envelope schema and fifteen routing fixtures instead of nine spend it back and more. `l` means
"multiple sessions or needs a design" and there is no larger value, which is the signal, not the
answer. **The standing note that this ticket may return to `queue` as a project is now the
recommendation rather than a possibility**, and the slicing is legible for the first time because the
mechanism is settled: `./next --drive` + `--findings` + their fixtures is one slice that ships
standing on its own and is testable without a supervisor existing; the `orchestrate` skill and its
schema is a second; FR15–FR16's lock and budget-kill handling is a third. **The first slice is the one
to rank**, because it is where every decision that can be wrong the same way twice actually lives.

### Routed to `queue` as a project, 2026-08-25 — by `develop`, on this ticket's own recommendation

A `develop` session took this row at the top of the rank, read it whole, and handed it back rather
than building it. **Nothing about the contract is wrong** — the design is settled, the FRs are
enumerable and the ACs are testable. What is wrong is the *unit*: the review amendment above ends by
recommending this ticket become a project, and naming the three slices. A row that recommends its own
slicing is not a row a stage should build as one.

**The slicing recommended above, unchanged, so `queue` has it in one place:**

1. **`./next --drive` + `./next --findings` + their fixtures.** Ships standing on its own and is
   testable with no supervisor existing. FR3's count, FR8's routing table, FR9's exit-code contract,
   AC6, AC9, AC10, AC11. **This is the slice to rank** — it is where every decision that can be wrong
   the same way twice actually lives.
2. **The `orchestrate` skill and `outcome.schema.json`.** FR1, FR2, FR4–FR7, FR10–FR14, FR17 and the
   README change. Depends on slice 1 for its routing probe.
3. **FR15–FR16 — the lock policy and the budget-kill recovery.** AC25, AC26. Hardening on a loop that
   has to exist first.

**Why `queue` and not `design`.** `develop` Step 2 routes a ticket to `design` when a *decision* is
missing; no decision is missing here — the 2026-08-24 design pass settled the mechanism and the review
amendment settled the corrections. What is missing is children, and slicing is `queue`'s job. The
precedent for the return is 0021, already cited above.

**The claim was taken and released, not skipped.** Token `38c7`, minted and cleared in the same turn
under `.lock/`, so `touches:` reserved nothing and no row was held while this was decided.

**Aaron chose this route on 2026-08-25**, over building the ticket whole in one session, when the
`develop` session put both options to him at claim time.

### Sliced into three tasks and made a project, 2026-08-25 — by `queue`

Aaron asked for the update; the slicing is the one the review amendment recommended and the routing
section above names, taken unchanged into **0038**, **0039** and **0040**. What follows is what
slicing decided that the recommendation did not.

**This ticket is now a project and its row has left `QUEUE.md`.** `next:` is blank, `status:
active`, and it is never ranked, claimed or built. Its FRs and ACs **moved** into the three tasks
rather than being copied — a copy left here would drift the first time either side is edited, and
`verify` would then check the stale one. What stayed is the outcome, the coupling, the cross-cutting
commitments, the *Out of scope*, and the design record below, all of which the three tasks cite
rather than restate.

**FR and AC numbers were not renumbered.** Each task carries 0036's numbers and says so, because
`RANKING.md`, the commit history and the review amendment all reference them; contiguity in a
task's own list is worth less than a reference that still resolves.

**0038 inherits this ticket's rank exactly** — below 0034, above 0035, Tier 4 — on the
re-specification rule that the work is worth what it was worth. 0039 and 0040 are ranked below
0008 on tie-breaker 2, and the argument is in `RANKING.md`.

**Two requirements were added at slicing time and are not in the record above** — 0038's **FR18**
(the new `next` modes resolve columns by header name, never by index) and its **AC28**. The reason
is a file-scope fact only slicing surfaced: 0038's `expects:` and **0006**'s overlap on
`.claude/backlog/next`, `skills/queue/templates/next` and `tests/next.test.sh`, and 0006 is the
ticket that exists because fixed-index parsing silently reports wrong values when a column moves.
`RANKING.md`'s existing argument for doing 0007 before 0006 — *"the reader is written once against
the final column set"* — applies here in reverse. The cheap resolution is a requirement rather than
a `blocked_by`: written header-name-first, the new modes give 0006 nothing extra to rewrite, and
0038 does not sink behind a two-hop blocked chain. **`relates: 0006` on 0038, not `blocked_by`** —
either order works, which is the test.

**0038's AC29 carries FR17's data half** so the pre-flight depth report has a source; it costs
nothing because the `--drive` read happens anyway.

**0039 is `size: l`, and that is the ceiling rather than a description**, so it is the slice to
watch. It was not split a fourth way because the recommendation named three and inventing a fourth
would rank a seam nobody has hit yet — but the seam to try first is recorded in 0039's
*Notes & decisions*: the schema and dispatch mechanics (AC1–AC5) away from the run-lifecycle
requirements (FR4–FR7, FR10, AC13–AC18), which is where its QA plan already falls.

**0027 has closed since the note above was written**, so the three scripts are installed in this
repo's own backlog and 0038 can be exercised here directly. The `relates: 0027` entry stays as
provenance.
