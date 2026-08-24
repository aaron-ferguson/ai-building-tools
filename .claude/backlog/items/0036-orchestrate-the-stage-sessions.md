---
id: "0036"
title: Orchestrate the isolated stage sessions from one supervising session
type: feature
next: design
status: ready
qa_level: unit
size: l
created: 2026-08-24
source: user
relates:
  - "0026"
  - "0027"
expects:
  - skills/orchestrate/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/retro/SKILL.md
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - README.md
  - .claude-plugin/plugin.json
claimed_by:
claimed_at:
touches:
---

## Problem

Effort 0009 split the suite into one skill per session and moved the handoff onto disk. That
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
> can launch one session to orchestrate a larger working session. It should keep each skill limited
> to a single context window, but have the one session orchestrate:
> 1. When a develop task is done, it spins up a new context window for the verify agent.
> 2. When that's green, it starts the next dev agent.
> 3. After we get to a certain amount of findings, we pause all work, run a retro, update the skills
>    themselves, and install the new versions.
> 4. Once that's done, we pick up development again.
> I should be able to interact with that orchestrating session as needed, as it manages keeping
> everything else moving smoothly and surfaces insights to me as I need to know them.

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

**What it leaves open** is which mechanism that budget then permits — a bounded run may put subagents
back in scope, which sub-question 1 had assumed it could not — and what a trimmed stage outcome must
carry to still be enough to orchestrate on. Both remain `/design`'s to settle; this narrows the field
rather than closing it.

## Functional requirements

- **FR1 — Advance develop → verify.** When a stage session leaves a ticket at `next: verify,
  status: ready`, the supervisor starts a **new context** that runs `verify` on that ticket. It does
  not verify the ticket itself, for the reason `develop` Step 5 already gives: a stage must not
  self-certify.
- **FR2 — Advance verify → develop.** When a ticket closes green (its row reaches `DONE.md`), the
  supervisor starts a new context on the next takeable `next: develop` row, chosen by the queue's
  rank and not by the supervisor's judgement.
- **FR3 — The findings gate.** When `FINDINGS.md` reaches `retro`'s stated cadence, the supervisor
  starts **no further stage session**, lets any running one finish, and runs a `retro` context. The
  threshold is read from `retro`'s cadence, not restated here, and is configurable per project.
- **FR4 — The run ends at the retro, and the release chain is handed over as a checklist.** The
  supervisor runs the `retro` context, sees its edits committed, and stops there. It does not push,
  bump the plugin version, install, or restart — it reports every remaining step of the chain `retro`
  Step 5 names, each marked done or outstanding, so no step can go silently missing. The 2026-08-23
  finding on the installed copy diverging from source at the same version number is why this is a
  checklist and not a sentence.
- **FR5 — Development resumes as a new run, started by a human.** There is no automatic resumption
  across the release. The human bumps, reinstalls and starts a fresh supervised session, which picks
  up from the backlog and FR10's log with **no conversational handoff** — so the requirement is what
  the next run needs in order to continue cold, not the resumption itself.
- **FR6 — The supervisor is interactive throughout.** The user can ask what is happening, redirect
  it to a specific ticket, hold it, or stop it, at any point — including while a stage session is
  running — and gets an answer without waiting for the current cycle to end.
- **FR7 — The supervisor's own context is bounded, and the bound is a number.** It reads disk
  signals and each stage's short structured outcome; it never ingests a stage session's transcript
  or a stage skill's instruction file. The per-cycle ceiling is stated in the skill and asserted by
  FR9's test — **two ceilings, both numbers: per cycle, and per run.** The second is promisable only
  because FR3's gate bounds the run, so the last cycle of a run must cost what the first one did.
- **FR8 — Every escalation is named, and the default is to stop.** The set of conditions the
  supervisor hands back to the human rather than deciding — at minimum: a `verify` bounce, a row at
  `next: design` or `next: queue`, a ticket whose contract turns out stale, a red tree that is not
  this ticket's, a `waiting` or `blocked` top row, and anything requiring a push — is enumerated in
  the skill, and anything not on the list stops rather than proceeding.
- **FR9 — The code that decides is named and tested, not only described.** The routing rules above
  are implemented by an executable this ticket ships — the probe that answers "what should happen
  next" from the backlog alone, with an exit-code contract — and by a test in `tests/` that drives
  it against fixtures. An FR describing a rule with no code behind it leaves the prose current and
  the behaviour absent.
- **FR10 — The supervisor's state survives its own session.** What it has started, what came back,
  every gate decision and where it is in the loop live in a file as they happen, so a new session
  can resume the run. The supervising conversation is the one thing in this design guaranteed to
  end — FR4 ends it deliberately.
- **FR11 — The supervisor claims nothing and holds no row.** Stage sessions claim and release their
  own rows, per `CONCURRENCY.md` *Claim tokens*. Two consequences the design must handle rather than
  discover: a supervisor holding rows it is not working is the scope reservation *The working tree
  is shared too* forbids, and a supervisor holding none is invisible to every ownership check built
  on rows and tokens — the same blind spot `retro` Step 5 records for itself.
- **FR12 — Only one supervisor runs on a backlog at a time**, and a second one says so rather than
  double-driving the queue.
- **FR13 — Each stage ends with a trimmed, structured outcome, and that outcome is the supervisor's
  only input from it.** Fields rather than prose: the ticket, the stage, the verdict, the resulting
  `next:` and `status:`, the commits, and a pointer to where detail was written. It carries a stated
  size ceiling, `develop`, `verify` and `retro` all emit it in the same shape, and a scripted
  assertion in `tests/` checks that each stage's final step still does — a contract described in
  three skill files and implemented in none is exactly the defect `queue` warns about.
- **FR14 — Trimming the report moves detail to disk; it does not delete it.** Every kind of thing a
  stage's report carries today that the supervisor will no longer read — the diagnosis behind a
  bounce, the red that turned out to be another session's, the mechanism that surprised it — has a
  named durable home first: *Notes & decisions*, `FINDINGS.md`, or the FR10 log. 0015's FR3 is the
  precedent, and the reason it is quoted here: the invocation went, and every line of reasoning for
  why the separate pass matters stayed.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | An unattended loop is standing authority to run this project's configured commands, commit, push and replace the tooling it is running on. It acquires none of that beyond the cycle it is in, and the push and install of FR4 stop for explicit human approval — "ship it" earlier in the session is not that approval | `security-conventions.md` |
| Observability | Every stage started, every outcome, every gate decision and every escalation lands on disk as it happens, with a timestamp. The supervising conversation is what dies; a decision that reached only the transcript is unrecoverable | `observability-conventions.md` |
| Performance | FR7's ceiling is a stated number with the instrumentation shipping in the same change, and the measure is **cost per closed ticket** against 0026's observed baseline — not total spend, which a longer run always wins | `measurement-conventions.md` |
| Dependencies | Whatever host-harness capability the mechanism rests on is a new dependency for a suite that is currently portable markdown and POSIX `sh`. Name it, and say what the suite does where it is unavailable — degrading to the hand-driven loop is an acceptable answer, silently not working is not | `dependency-conventions.md` |
| Compatibility | Any signal the supervisor reads is a contract between the stages and the driver. Adding one must not change what a hand-driven session does, since the plugin is public at 0.9.3 and installed elsewhere | `api-conventions.md` |
| Documentation | `README.md`'s *One skill per session* is the canonical statement of how this suite is run, and it currently says a person types the next command. It describes the supervised loop in the same change | `documentation-conventions.md` |

## Open design question

- **Question:** what *is* a stage session under the supervisor — a separate process or conversation
  the supervisor only signals and observes through the backlog, or a subagent inside the
  supervisor's own session — and where does the supervisor's state live given that FR4 ends its
  session on purpose?
- **Why it blocks specification:** every acceptance criterion for FR1, FR2, FR6, FR7 and FR10 is a
  different assertion under each answer. Signalled separate sessions make FR7 nearly free and FR6
  and FR10 the hard part; subagents make FR6 free and FR7 the hard part, because each subagent's
  report returns into the supervisor's context and accumulates over a run whose whole purpose is to
  be long. There is no phrasing of an AC that covers both.
- **Settle it with:** `/design`. It is a decision about mechanism and state, reasoned from what the
  harness can do and what 0009 measured — there is nothing to look at.

Sub-questions the decision has to answer:

1. **Does "its own context window" mean its own *session*?** 0009's measured cost is context per
   turn, which a subagent satisfies — it starts near-empty. What a subagent does not give is
   independence from the supervisor's own growth: N cycles of returned reports accumulate in one
   place. State the ceiling first, then pick the mechanism that can hold it. **Aaron's bounded-run
   proposal changes this arithmetic** — N is now known and small, so accumulated reports may be
   affordable rather than disqualifying. Do the sum against a real FR13 outcome size before ruling
   either mechanism in or out.
2. **How does the supervisor survive FR4?** Skills resolve at session start, so a session cannot
   install a new version of the skills it is running and then use them — `retro` Step 5 and
   `README.md`'s fifth step both say the session that writes the change is the last to receive it.
   Either the supervisor's state is a file any new session can resume from (FR10), or the retro gate
   is where the loop deliberately hands back to the human. **Aaron has proposed the second** (see
   *Problem*), which settles the larger half. What stays open is narrower and still real: what FR10's
   log must hold for the *next* run to continue cold, and whether a crash mid-run resumes the same way
   a planned ending does.
3. **What may the supervisor decide alone?** FR8 names the escalations; the question is where the
   line sits on the two genuinely arguable ones — a `verify` bounce (re-develop automatically, or
   surface it), and a ticket whose contract `develop` finds stale.
4. **Is this a skill, an executable, or both?** A skill is instructions a session follows; a loop
   with state that outlives the session wants a file and a reader. FR9 and FR10 both point at code,
   and `next`/`claim`/`close` are the precedent for which parts earn being a script.
5. **What does the interaction model in FR6 cost?** If the supervisor is blocked waiting on a stage,
   answering the user is not free — and a supervisor that polls is paying turns for silence.
6. **What surfaces to the user unprompted, and what waits to be asked?** "Surfaces insights as I
   need to know them" is the request; the decidable version is which events interrupt and which
   land in the FR10 log for the next question.

## Acceptance criteria

*Written by `/design` once the question above is settled.* Three invariants any AC set must include,
recorded now because they are the ones an implementation is most likely to satisfy on paper:

- The FR7 ceiling is **measured** on a multi-cycle run, not asserted in prose.
- No push and no install happens without an explicit approval in that session.
- A supervisor killed mid-cycle leaves a backlog a hand-driven session can pick up unchanged — no
  orphaned claim, no row `in-progress` with nothing running.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`).
- **Why this level:** the supervisor's failure mode is **silently driving the wrong thing** — the
  wrong ticket, past a red, past the findings gate — and prose cannot be red. FR9's routing probe
  takes a backlog as input and produces one decision, which is exactly the shape `next.test.sh` and
  `close.test.sh` already drive against fixtures. Setting this level at queue time is a **constraint
  on the answer, not a prediction of it**: a mechanism whose decisions cannot be exercised by a
  fixture-driven test is disqualified, and if design concludes otherwise it re-opens this field with
  its reason rather than quietly dropping to `verify`.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), including a fixture per FR8
  escalation and per gate boundary — the cycle at the threshold, and the one after it. Plus
  `tests/skill-size.test.sh` — which now covers three **existing** skill files as well as the new
  one, since FR13 edits `develop`, `verify` and `retro`, and `develop` is already over the goal with a
  recorded reason. A fixture asserting FR13's outcome shape and its size ceiling belongs in the same
  suite: until something fails when a stage stops emitting it, FR13 is prose in three files.

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
- **Replacing `next`, `claim` or `close`.** The supervisor drives them. FR9's probe is additive.
- **Pushing or releasing unattended**, in any form, however clearly the user asked for the loop to
  keep moving.
- **One supervisor across several repositories.** FR12 is one backlog.
- **A dashboard or reporting UI.** FR10's log is on disk and read by a session.

## Notes & decisions

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
- **This ticket may come back to `queue` as an effort.** If the answer to the design question is
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
