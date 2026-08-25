---
id: "0036"
title: Orchestrate the isolated stage sessions from one supervising session
type: feature
next: develop
status: in-progress
qa_level: unit
size: l
created: 2026-08-24
source: user
relates:
  - "0026"
  - "0027"
expects:
  - skills/orchestrate/SKILL.md
  - skills/orchestrate/outcome.schema.json  # new — the single copy of the FR13 shape
  - skills/verify/SKILL.md                  # AC20 only: relocate the evidence table
  - skills/retro/SKILL.md                   # FR3 only: point the cadence at the config key
  - skills/queue/templates/next
  - skills/queue/templates/config.yml
  - .claude/backlog/next
  - .claude/backlog/config.yml
  - tests/next.test.sh
  - README.md
  - .claude-plugin/plugin.json
# `skills/develop/SKILL.md` was here and came OUT on 2026-08-24: the schema is supplied by the
# invoker, so no stage skill has to describe the FR13 shape. See *Notes & decisions*, the second
# amendment. develop is already over the skill-size goal with a recorded reason, so not reaching
# into it is worth having.
claimed_by: "38c7"
claimed_at: 2026-08-25T06:10:24Z
touches:
---

## Problem

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
is what every acceptance criterion below is written against.

## Functional requirements

- **FR1 — Advance develop → verify.** When a stage session leaves a ticket at `next: verify,
  status: ready`, the supervisor starts a **new context** that runs `verify` on that ticket. It does
  not verify the ticket itself, for the reason `develop` Step 5 already gives: a stage must not
  self-certify.
- **FR2 — Advance verify → develop, one *gate* at a time.** When a ticket closes green (its row
  reaches `DONE.md`), the supervisor starts a new context on the next takeable **gate** — the
  topmost takeable `next: develop` row plus every other takeable `next: develop` row that shares its
  `expects:` scope or its parent slice — chosen by the queue's rank and not by the supervisor's
  judgement. **A gate, not a row**: `develop`'s own opening rule and `README.md`'s *One skill per
  session* both make the unit a gate, because what a session batches away is the startup it pays
  before writing a line. One session per row re-pays that per ticket and regresses the saving 0009
  exists for. Amended from "row" on 2026-08-24 — see *Notes & decisions*.
- **FR3 — The findings gate, counted by code and evaluated once.** When `FINDINGS.md` reaches the
  configured threshold, the supervisor starts **no further stage session**, lets any running one
  finish, and runs a `retro` context. Three things this has to pin that the first draft left as
  prose, each of which is a way for the gate to be wrong rather than a detail:
  - **The threshold lives in `config.yml`**, as a key, defaulted to `retro`'s stated cadence and
    overridable per project. `retro`'s SKILL.md gets a pointer to the key rather than a second
    number. A driver cannot read "eight entries or more, **or weekly** if the buffer fills slower —
    whichever comes first": the time half has no fixture and no reading, so **the driver gates on
    the count only**, and the weekly half stays what it is today, a human's judgement.
  - **The count is a mode on `next`, not a grep.** `FINDINGS.md` uses two entry formats — `- <date>
    — **lead.**` and `- **<date> — lead.**` — and the parked 2026-08-24 finding on exactly this says
    every count taken off the obvious `^- 2026-` grep is low: `MEASUREMENT.md` published 26 and 28 in
    adjacent sentences against a format-tolerant 42. A gate reading a number that is reliably too
    low fires late, silently, and there is nothing to notice it with. So the count is `./next
    --findings`, format-tolerant, and the format is pinned by a guard in the same change.
  - **The gate is evaluated once per run.** `retro`'s own Step 6 parks findings, so a supervisor
    that re-derives statelessly after a retro reads a still-over-threshold count and dispatches
    another retro, which parks more. FR4 ends the run before this bites in the planned case; AC17's
    resume path reaches it. One evaluation per run, and after the retro the run is over.
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
- **FR7 — The supervisor's own context is bounded, and the bound is two numbers plus a turn count.**
  It reads disk signals and each stage's short structured outcome; it never ingests a stage session's
  transcript or a stage skill's instruction file. **The two numbers are the per-turn floor and the
  per-cycle growth, and they are not the same kind of thing** — which the first draft's single
  "per-cycle ceiling" hid:
  - **The floor** is what every turn re-sends before any run state exists: system prompt and tool
    schemas, the project's `CLAUDE.md` and whatever it imports, and this skill. Measured
    2026-08-24 for this repo: `CLAUDE.md` plus the imported `CONVENTIONS_CORE.md` is 2,645 words
    (~3.4k tokens), the skill at the 20,190-byte size goal is ~5k, and the harness floor is
    ~10–14k — call it **~20k per turn**, fixed before the first stage runs.
  - **The growth** is what a cycle adds: one `--drive` decision (~100 tokens), one stage outcome
    (~80), and the supervisor's own text. **~800 tokens per cycle.**
  - **The turn count is the actual cost driver, and it is the only one this ticket can move.** Cost
    is turns × floor. At three turns per cycle — dispatch, notification, report — and N ≈ 4–6, a run
    is ~15 turns and **~350–400k cumulative input**, of which FR13's entire trim is ~0.1%. One
    turn removed per cycle saves ~26k, **sixty times the whole trim.** So the requirement is a
    **stated turns-per-cycle budget**, and the report turn is conditional on a state change rather
    than automatic. Trimming payloads while paying an unbudgeted turn is optimising the wrong term.
- **FR8 — Every transition the three stages can write is routed, and the default is to stop.** The
  table below is the whole space, derived from the stage skills rather than from the happy path, and
  it is the specification `./next --drive` implements. Anything not in it stops rather than
  proceeding (FR8 is what AC10 tests).

  | From → to | Written by | Supervisor does |
  |---|---|---|
  | `develop` → `verify/ready` | develop S5.4 | dispatch `verify` |
  | `verify` green → row to `DONE.md` | verify S5 / `./close` | dispatch the next gate |
  | `verify` red → `develop/ready` | verify S5 | **escalate** — the bounce |
  | stale contract → `queue/ready` | verify S5 | **escalate** |
  | advisory PASS → stays `verify/ready` | verify S7 | **escalate** — else it re-verifies forever |
  | row at `next: design` | queue, or develop S4 | **escalate** — a person decides |
  | row at `next: queue` | verify S5 | **escalate** |
  | **develop → `design/ready`** | **develop S4** | **escalate**, carrying the *Open design question* |
  | **develop, tree not green → `develop/ready`** | **develop S5 tail** | **escalate** |
  | **develop → `waiting`** | **develop S5 tail** | **escalate**, carrying *## Waiting on* |
  | **develop → gains a `blocked_by`** | **develop S5 tail** | re-derive; `blocked` is never typed |
  | close reconciles dependents `blocked`→`ready` | verify S5.3 | re-derive — new rows may be takeable |
  | **ticket becomes a project; row leaves `QUEUE.md`** | queue | not an error, and not a loop |
  | **nothing takeable at `develop`** | — | **end the run clean** — a success, not an escalation |
  | foreign red tree · push required · anything unrecognised | — | **escalate** |

  **The six bolded rows were missing from the first draft**, and five of them are the *unhappy*
  endings of the stage the supervisor dispatches most. Three land the ticket back at `next: develop`,
  which trips the same-stage-twice guard below — the correct outcome, and it means **the ordinary
  red-tree ending halts the run.** Said here rather than discovered on the first run.

  **Which `status:` is authoritative, because there are two vocabularies and nothing pinned one.**
  `./next` reads Status from the `QUEUE.md` column (`ready|waiting|blocked|in-progress`) and
  `size`/`qa_level`/`expects` from item frontmatter — where the vocabulary is *different*: `active`
  appears on projects, which have `next:` blank and no row at all, and `done` appears on closed
  tickets. **The column is the authority for routing** and `--drive` reads it there; item
  frontmatter is the authority for everything else. Fixtures and skill prose both say so, or AC9's
  fixtures get written against one and the skill against the other.

  **The same-stage-twice guard needs an intervening outcome, or it blocks the resume AC17 promises.**
  A supervisor killed after dispatch but before the stage claimed leaves the row `ready`; AC17's
  stateless derivation re-dispatches it; a naive guard then sees the same ticket at the same stage
  twice and escalates the recovery. So the guard is **same ticket, same stage, with a completed
  outcome in between** — which is a fact only the FR10 log holds. **This is the one exception to
  "nothing routes on the log", and it is stated as an exception rather than left to collide:** the
  log is read for *what already completed*, never for *what to do next*.
- **FR9 — The code that decides is named and tested, not only described.** The routing rules above
  are implemented as **`./next --drive`**, a new mode on the existing reader rather than a fourth
  script: it answers "what should happen next" from the backlog alone, printing one decision with an
  exit-code contract, and `tests/next.test.sh` drives it against fixtures. An FR describing a rule
  with no code behind it leaves the prose current and the behaviour absent. **Why a mode and not a
  script:** `next` already owns takeability, the `blocked_by` graph and the exit-code convention, and
  0006, 0022 and 0031 are three separate tickets fixing that parsing in one place — a second copy is
  how the two answers diverge without either being wrong.

  **The exit-code contract, named — AC11 asserted it and nothing specified it.** `next` already
  spends 0 (success, *including* "nothing is takeable"), 1 (drift, malformed) and 2 (usage error).
  `--drive` needs four outcomes a caller can tell apart, so **"nothing to dispatch" cannot share 0
  with "dispatch this"** — which is exactly the collision `./next <stage>` already has and gets away
  with because a human reads the line. Proposed, to be fixed in the build and tested by AC11:
  `0` dispatch this (the decision is on stdout) · `3` run complete, nothing takeable ·
  `4` escalate (the reason is on stdout) · `5` findings gate reached, dispatch `retro` ·
  `1`/`2` unchanged, so every existing caller and test keeps its meaning.
- **FR10 — The supervisor's state survives its own session, and it survives by not being state.**
  What it has started, what came back, every gate decision and every escalation land in an
  append-only log — one JSON line per event, under `.claude/backlog/runs/` — as they happen. But a
  resuming session derives **what to do next** from `./next --drive` and the backlog, never from the
  log: the backlog *is* the state, and the only fact not already on disk — how many findings have
  accrued since the last retro — is `FINDINGS.md`'s own entry count, which is derived rather than
  stored. **The consequence is the requirement:** a crash mid-run and FR4's planned ending resume by
  the identical path, and there is no run state that can go stale or disagree with the backlog. The
  log is provenance and the human's record, and nothing routes on it. The supervising conversation is
  the one thing in this design guaranteed to end — FR4 ends it deliberately.
- **FR11 — The supervisor claims nothing and holds no row.** Stage sessions claim and release their
  own rows, per `CONCURRENCY.md` *Claim tokens*. Two consequences the design must handle rather than
  discover: a supervisor holding rows it is not working is the scope reservation *The working tree
  is shared too* forbids, and a supervisor holding none is invisible to every ownership check built
  on rows and tokens — the same blind spot `retro` Step 5 records for itself.
- **FR12 — Only one supervisor runs on a backlog at a time**, and a second one says so rather than
  double-driving the queue.
- **FR13 — Each stage ends with a trimmed, structured outcome, and that outcome is the supervisor's
  only input from it.** Fields rather than prose. **The shape is a session envelope wrapping an array
  of per-ticket outcomes, and it has to be** — the first draft said "*the* ticket" while AC4 puts two
  or three tickets in one develop session, so a gate where one closes to `verify`, one hits a
  decision and one leaves the tree red has three verdicts and one stdout object. Singular, it
  reports one and silently drops two.
  - **Envelope:** stage, session id, commits, cost, findings-parked count, escalation-or-null.
  - **Per ticket, one entry each:** id, verdict, resulting `next:` and `status:`, detail pointer.

  **The schema is supplied by the invoker and lives in exactly one file** —
  `skills/orchestrate/outcome.schema.json`. A stage is launched with
  `claude -p --json-schema <that file>`, which validates at the tool-call layer, so stdout is the
  object or the stage failed. Confirmed by running it, 2026-08-24: a three-field outcome came back as
  64 bytes of JSON and nothing else.

  **So no stage skill has to describe the shape, and none should** — the scope cut recorded in the
  second amendment. The first draft had `develop`, `verify` and `retro` all "emit it in the same
  shape" with a `tests/` assertion per file, which is three copies of a contract and the same
  divergence FR9 refuses for `next`. One invoker-supplied schema is the single source, AC2 asserts it
  at runtime where it actually matters, and the edits to three skill files — one of them already over
  the size goal — do not happen. It also drops AC23's regression surface to nothing: a hand-driven
  session is passed no schema and emits exactly what it does at 0.9.3.
- **FR14 — Trimming the report moves detail to disk; it does not delete it.** Every kind of thing a
  stage's report carries today that the supervisor will no longer read — the diagnosis behind a
  bounce, the red that turned out to be another session's, the mechanism that surprised it — has a
  named durable home first: *Notes & decisions*, `FINDINGS.md`, or the FR10 log. 0015's FR3 is the
  precedent, and the reason it is quoted here: the invocation went, and every line of reasoning for
  why the separate pass matters stayed.

  **The fourth kind, and the one this list was missing: `verify` Step 7's evidence table.** Each AC
  and NFR, how it was checked, the actual output. **That is a check, not a narrative** — it is the
  paragraph that forces enumeration against real output rather than against memory, and it is the
  largest thing a verify report carries. Replace it with `{"verdict":"pass"}` and the trim has
  silently lowered what verify *does*, which *Out of scope* forbids and no criterion caught. So it
  **moves into the item file**, where it belongs anyway as the QA record of a closed ticket, and the
  FR13 detail pointer points at it. **What is genuinely deleted is the salutation** — the recap of
  what was built and the closing "now run `/verify 0036` in a new session" — because in a supervised
  run it is addressed to a human who is not there. In a hand-driven run it stays, untouched (AC23).

- **FR15 — The lock has a policy, and the supervisor never breaks it.** `claim` and `close` take
  `.claude/backlog/.lock/`, and the supervisor's whole job is launching processes that take it. **A
  stage killed holding the lock blocks every future claim and close in the repo** — and two parked
  findings already say the busy-lock procedure strands a close and that the protocol cannot be
  satisfied by hand. The first draft did not mention the lock at all. The policy: the supervisor
  takes the lock never, breaks it never, and **escalates on a lock older than a stated age**, naming
  the process that should have held it from the FR10 log. Anything else has a driver silently
  stealing a lock from a stage that is still working.

- **FR16 — A stage killed by its own spend cap is a recoverable state, not a discovered one.**
  `--max-budget-usd` is the blast-radius control AC19 requires, and it **creates** the nastiest
  failure in this design: a stage killed mid-work leaves a claim held, a tree dirty, possibly the
  lock taken, and a ticket half-built. AC16 covers the *supervisor* being killed, which is a
  different and easier case — the tree is clean. So: the cap is **set from `cost_tracking:` history
  rather than guessed** (this repo's observed figures are $4.45–$6.01 per closed ticket, so a gate of
  three is not a $1 stage), an over-budget exit is one of FR8's escalations, and the escalation names
  the claim, the dirty paths and the lock state. Orphan detection is not enough on its own: a dirty
  tree is not something `./next --drift` can see.

- **FR17 — A pre-flight depth report, before anything is dispatched.** The supervisor reports, in one
  line and from one `--drive` read, how many takeable gates deep the backlog is and where it runs
  dry — "two develop gates takeable; the next row after them is `next: design`." This is the honest
  answer to ask 2 of the original request: it delivers *don't stop mid-session for unfinished design*
  without automating a design decision, and it costs nothing, because the read happens anyway.
  Without it the first supervised run halts on the first `next: design` row and reads as broken.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | An unattended loop is standing authority to run this project's configured commands, commit, push and replace the tooling it is running on. It acquires none of that beyond the cycle it is in, and the push and install of FR4 stop for explicit human approval — "ship it" earlier in the session is not that approval | `security-conventions.md` |
| Observability | Every stage started, every outcome, every gate decision and every escalation lands on disk as it happens, with a timestamp. The supervising conversation is what dies; a decision that reached only the transcript is unrecoverable | `observability-conventions.md` |
| Performance | FR7's ceiling is a stated number with the instrumentation shipping in the same change, and the measure is **cost per closed ticket** against 0026's observed baseline — not total spend, which a longer run always wins | `measurement-conventions.md` |
| Dependencies | Whatever host-harness capability the mechanism rests on is a new dependency for a suite that is currently portable markdown and POSIX `sh`. Name it, and say what the suite does where it is unavailable — degrading to the hand-driven loop is an acceptable answer, silently not working is not | `dependency-conventions.md` |
| Compatibility | Any signal the supervisor reads is a contract between the stages and the driver. Adding one must not change what a hand-driven session does, since the plugin is public at 0.9.3 and installed elsewhere | `api-conventions.md` |
| Documentation | `README.md`'s *One skill per session* is the canonical statement of how this suite is run, and it currently says a person types the next command. It describes the supervised loop in the same change | `documentation-conventions.md` |

## Acceptance criteria

**Mechanism, fixed by the design decision:** a stage session is a separate `claude -p` process
launched in the background by the supervisor, returning a `--json-schema`-validated outcome on
stdout. Every criterion below is written against that mechanism.

**The invocation, corrected 2026-08-24 — `--bare` is disqualifying and the first draft named it.**
`claude --help` on this machine: *"`--bare` Minimal mode: skip hooks, LSP, plugin sync, attribution,
auto-memory, background prefetches, keychain reads, and **CLAUDE.md auto-discovery**. Anthropic auth
is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` (**OAuth and keychain are never read**)."* Two
consequences, either one fatal:

- **No CLAUDE.md discovery means no conventions.** `config.yml` makes the conventions path required
  and says these tools "carry no standards of their own and will stop rather than guess." A `--bare`
  develop session is a session *building without the conventions* — the single thing this suite
  exists to prevent — and it would pass every test in `tests/`, because nothing greps a subprocess's
  loaded context.
- **Auth becomes an API key in the loop's environment**, on a billing path separate from the
  supervising session. That breaks AC14's arithmetic (two rate sources under one figure) and puts a
  secret in the environment of an unattended loop for no gain.

So: **plain `claude -p`, no `--bare`.** Everything AC1 wants — plugin skill resolution, CLAUDE.md,
OAuth — comes from not passing it. Three flags the invocation does need, all confirmed present:
`--add-dir ../ai-building-conventions`, or AC19's narrow scoping blocks the stage from reading the
conventions `config.yml` points it at; `--session-id <uuid>` **pre-assigned at dispatch**, so the
transcript path is a dispatch-time fact in the FR10 log line rather than something a dead supervisor
has to go hunting for; and `--setting-sources` stated explicitly rather than inherited.

**AC1 — a stage runs as a separate process, and the skill and the conventions both resolve inside it.**
Given a backlog with a takeable `next: develop` gate, when the supervisor dispatches it, then a
`claude -p` process is launched with the `develop` skill invoked by name, it runs to completion in
its own session, and the ticket it was given is left at `next: verify, status: ready` with its claim
released. **And the stage's own outcome confirms it resolved the project's conventions** — a stage
that silently ran without them is the failure `--bare` would have produced, so the schema carries a
field for it and this AC checks it. *`--bare` appears nowhere in the invocation. This is the one fact
the design pass could not check without consuming a real ticket, so it is an AC rather than an
assumption.*

**AC2 — the outcome is schema-validated, it is an envelope over an array, and it is all the supervisor gets.**
Given a stage process that has finished, when the supervisor reads its result, then stdout parses as a
single JSON object satisfying `skills/orchestrate/outcome.schema.json` — an envelope (stage, session
id, commits, cost, findings-parked count, conventions-resolved, escalation-or-null) wrapping **one
entry per ticket the stage handled** (id, verdict, resulting `next:`, resulting `status:`, detail
pointer) — and the supervisor reads no transcript, no skill file and no other output of that process.
**Given a gate of three tickets whose verdicts differ**, when the outcome is read, then all three
appear with their own verdicts and none is dropped.

**AC3 — a stage that will not produce the shape fails loudly.**
Given a stage process whose final message does not satisfy the schema, when it exits, then the
supervisor records an escalation and starts nothing further — it does not parse prose, infer the
verdict, or proceed on a partial object.

**AC4 — the dispatch unit is a gate.**
Given three takeable `next: develop` rows of which two share an `expects:` path, when the supervisor
dispatches develop, then both sharing rows go to **one** stage session and the unrelated row does
not, and the session claims and closes each of the two individually.

**AC5 — verify follows develop without the supervisor verifying anything.**
Given a ticket the previous stage left at `next: verify, status: ready`, when the supervisor acts,
then it dispatches a **new** `claude -p` process running `verify` on that ticket, and the supervisor
itself runs no test and writes no verdict.

**AC6 — the gate fires on a count that is right, lets the running stage finish, and fires once.**
Given `FINDINGS.md` at one entry below the threshold in `config.yml` and a stage session running, when
that stage returns and its parked findings cross the threshold, then the supervisor starts no further
stage session, dispatches a `retro` process, and the crossing is one line in the run log.
**Given a fixture holding both entry formats** — `- <date> — **lead.**` and `- **<date> — lead.**` —
when `./next --findings` counts it, then the count includes both, and a format guard fails on any
third shape. **Given a completed retro whose own Step 6 parked entries that leave the count still
above the threshold**, when the supervisor acts, then it does **not** dispatch a second retro: the
gate is evaluated once per run and the run is over.

**AC7 — the run ends at the retro, as a checklist.**
Given a `retro` process that has returned with its edits committed, when the supervisor reports, then
it stops, and its report enumerates every remaining step of `retro` Step 5's release chain each
marked done or outstanding. No push, no version bump, no install, no restart, and no further stage.

**AC8 — no push and no install without an explicit approval in that session.**
Given a supervised run of any length, when the run ends, then `git push` has not run, the plugin
version has not changed and no install has happened — unless the user approved that specific action
in that session. "Ship it" earlier in the session is not that approval.

**AC9 — every row of FR8's table is routed as the table says, with one fixture each.**
Given a backlog in each FR8 state in turn — verify bounce, `next: design`, `next: queue`, stale
contract, foreign red tree, `waiting` top row, genuinely `blocked` top row, **advisory PASS**,
**develop→`design`**, **develop→`develop` on a red tree**, **develop→`waiting`**,
**develop→new `blocked_by`**, **a row that left `QUEUE.md` because its ticket became a project**,
**nothing takeable at `develop`**, and **the same ticket reaching the same stage twice with a
completed outcome in between** — when `./next --drive` is run against that fixture, then it prints
the decision FR8's table names and exits with that outcome's code. Specifically: in the
advisory-PASS case it does **not** print `verify <id>` again; in the nothing-takeable case it exits
**run-complete and not escalate**; in the became-a-project case it neither errors nor loops; and in
the same-stage-twice case, **given the same backlog with no completed outcome in the log**, it
dispatches rather than escalating — the recovery path AC17 promises.

**AC10 — anything unrecognised stops rather than proceeding.**
Given a backlog state matching no routing rule, when `./next --drive` is run, then it escalates
rather than falling through to a default action.

**AC11 — the probe is a mode on `next`, the codes are the named ones, and both are tested.**
Given the fixtures above, when `tests/next.test.sh` runs, then it exercises `./next --drive` for each
routing outcome and each escalation, asserting the printed decision **and** the exit code against
FR9's named contract — with `0` (dispatch) and the run-complete code asserted as **distinct**, since
sharing 0 is the collision that makes "nothing to do" indistinguishable from "do this". Every
pre-existing `next` exit code still means what it meant, and `./next --help` lists `--drive` and
`--findings`.

**AC12 — the supervisor stays answerable while a stage runs.**
Given a stage process running, when the user asks what is happening, redirects the run to a specific
ticket, holds it, or stops it, then the supervisor answers from the run log and the backlog without
waiting for that stage to finish and **without polling** — no turn is spent on a check that reports
no change.

**AC13 — the bound is measured as growth and turns, not as a ratio that cannot go red.**
Given a completed multi-cycle run, when `tools/harvest-usage.sh` is run over the supervising session's
transcript, then it reports **three** figures against FR7's stated numbers: the per-turn **floor**,
the per-cycle **growth**, and **turns per cycle**. *The first draft asserted "the last cycle within
tolerance of the first", which passes trivially — ~800 tokens of growth against a ~20k floor is
inside any tolerance anyone would write, so it is a criterion that cannot fail and therefore proves
nothing about FR13.* Growth is asserted as an absolute figure per cycle, turns per cycle against the
budget, and all three land in the run log and the ticket's `cost_tracking:`.

**AC14 — cost per closed ticket includes the supervisor's own spend.**
Given a completed run, when the supervisor reports, then it states cost per closed ticket compared
against this repo's observed figures — **$6.01 across all stages, $4.45 counting only develop and
verify** (`MEASUREMENT.md`) — and not total spend, which a longer run always wins. **The
supervisor's own spend is in the numerator.** It attributes to no ticket's `cost_tracking:`, so a
figure summed from the stages alone omits the one cost this ticket adds, and would report a win that
is partly just an unmeasured overhead. Sourced from each stage's `cost_tracking:` **plus** the
supervising session's own harvest.

**AC15 — the supervisor holds no claim and no row.**
Given a run at any point, when the item files are inspected, then no `claimed_by:` token was minted
by the supervisor, and every `in-progress` row corresponds to a stage process that is actually
running.

**AC16 — a supervisor killed mid-cycle leaves a backlog a hand-driven session can pick up.**
Given a supervisor killed while a stage runs, when a hand-driven session then runs `./next`, then it
is offered a takeable row, no claim is orphaned, no row reads `in-progress` with nothing running, and
`./next --drift` exits zero.

**AC17 — a resuming supervisor derives its position, and does not restore it.**
Given a run log from a killed run, when a new supervisor starts, then it determines the next action
from `./next --drive` and the findings count alone, and reads the log only for what already escalated
and what the run has spent. A log deleted between the two sessions changes the next action not at
all.

**AC18 — a second supervisor refuses.**
Given one supervisor active on a backlog, when a second is started on the same backlog, then it says
so and starts no stage session.

**AC19 — each stage gets the narrowest authority that works, for that stage only.**
Given a dispatched stage, when its process is launched, then it is scoped to the tools that stage
needs and given a spend cap, and `--dangerously-skip-permissions` appears nowhere. Authority does not
outlive the process.

**AC20 — the trim moved the detail, it did not delete it — and the evidence table survives.**
Given each kind of content a stage's report carries today that the supervisor will no longer read —
the diagnosis behind a bounce, the red that proved to be another session's, the mechanism that
surprised it, **and `verify` Step 7's per-AC evidence table** — when the stage finishes, then that
content is present in *Notes & decisions*, `FINDINGS.md`, or the run log, and the FR13 detail pointer
points at where. **Specifically for the evidence table:** given a closed ticket, when its item file
is read, then every AC and NFR appears with how it was checked and the actual output. A verify stage
that returns a verdict without having written that table fails this criterion — the table is the
check, and the trim is to the salutation.

**AC21 — the loop surfaces what the run learned.**
Given a completed cycle, when the supervisor reports it, then the report carries the findings-parked
count for that cycle. This is the only signal left that the run is learning anything, because FR13
removed the narrative it would otherwise have come from.

**AC22 — where the CLI cannot be invoked, it degrades visibly, and the probe is a real dispatch.**
Given a host where the supervisor cannot launch a `claude` subprocess, when it starts, then it says so
and falls back to naming the commands for a human to run — today's behaviour — rather than appearing
to drive a loop it is not driving. **The detection is a startup probe that actually dispatches**: a
trivial `claude -p --json-schema` no-op returning a fixed object, checked before the first real stage.
`command -v claude` is not the check — the failure modes that matter are an unauthenticated CLI and
whatever a nested session is or is not permitted to do, and both look like a present binary. **The
nested-dispatch question is the untested premise under AC1**, so the probe is what makes it fail in
one cheap second rather than halfway through a real ticket.

**AC23 — a hand-driven session is entirely unaffected.**
Given the whole change installed, when a session runs `develop` or `verify` by hand with no
supervisor, then **its behaviour is what it was at 0.9.3**, and every existing test still passes. *The
first draft said "apart from the FR13 outcome it now also emits"; that clause is gone with FR13's
scope cut — the schema is invoker-supplied, so a hand-driven session is passed none and emits its
ordinary report.* The one intended change to a stage skill is `verify` writing its evidence table to
the item file (AC20), which is a hand-driven improvement rather than a supervised-only one.

**AC25 — the supervisor never takes or breaks the lock.**
Given a run at any point, when `.claude/backlog/.lock/` is inspected, then it was never created by the
supervisor and never removed by it. **Given a lock older than the stated age with no live stage
process**, when the supervisor acts, then it escalates, naming the lock's age and the process from the
FR10 log that should have held it — and dispatches nothing.

**AC26 — a stage killed by its spend cap leaves a state the escalation describes.**
Given a stage dispatched with a cap it exceeds mid-work, when it is killed, then the supervisor
escalates with the ticket's claim token, the dirty paths, and the lock state named — and starts
nothing further. Given that escalation, when a human follows it, then no information needed to
recover is only in the dead stage's transcript. **And the cap itself is derived, not guessed:** it is
set from `cost_tracking:` history for the stage and gate size, and the derivation is stated where the
number is.

**AC27 — the pre-flight depth report happens before the first dispatch.**
Given a supervised run starting, when it reports, then it states how many takeable gates deep the
backlog is and what stops it — in one line, from the `--drive` read it makes anyway, and **before**
any stage process is launched.

**AC24 — the documentation says how the suite is actually run.**
Given the change, when `README.md`'s *One skill per session* is read, then it describes the
supervised loop alongside the hand-driven one, and no longer implies a person typing the next command
is the only path.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`).
- **Why this level:** the supervisor's failure mode is **silently driving the wrong thing** — the
  wrong ticket, past a red, past the findings gate — and prose cannot be red. FR9's routing probe
  takes a backlog as input and produces one decision, which is exactly the shape `next.test.sh` and
  `close.test.sh` already drive against fixtures. Setting this level at queue time is a **constraint
  on the answer, not a prediction of it**: a mechanism whose decisions cannot be exercised by a
  fixture-driven test is disqualified, and if design concludes otherwise it re-opens this field with
  its reason rather than quietly dropping to `verify`. **Design confirmed this level rather than
  re-opening it, 2026-08-24:** the chosen mechanism puts every routing decision in `./next --drive`,
  which takes a backlog fixture and prints one decision with an exit code — the exact shape
  `next.test.sh` already drives. The constraint set at queue time did its job: a mechanism whose
  decisions lived only in the supervisor's judgement would have failed it.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), and specifically —
  - **A fixture per row of FR8's table**, fifteen of them, each asserting the printed decision and
    the exit code (AC9, AC11). The four develop-side unhappy endings and the two loop hazards are the
    ones with no precedent in the existing tests, so they are the ones to write first.
  - **The gate boundary in both directions**: the cycle at the threshold, the cycle after it, and the
    post-retro fixture that must *not* re-fire (AC6).
  - **A `--findings` fixture holding both entry formats**, plus a format guard that fails on a third
    (AC6). This is the count the whole gate rests on and today it is a grep that under-reports.
  - **A schema fixture** for `outcome.schema.json`: a gate of three tickets with three different
    verdicts validates, and a singular object does not (AC2).
  - **Exit-code regression**: every pre-existing `next` invocation still returns what it returned,
    since `--drive` adds codes to a script three other tickets already depend on (AC11).
  - **`tests/skill-size.test.sh` unchanged in scope.** *The first draft widened it to three existing
    skill files because FR13 edited them; FR13's scope cut removed that, so the guard covers the new
    skill and the two one-line edits and nothing more.* `develop` is not touched at all.

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
