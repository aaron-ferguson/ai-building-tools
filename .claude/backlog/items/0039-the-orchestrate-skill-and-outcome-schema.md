---
id: "0039"
title: Build the orchestrate skill and the stage outcome schema
type: feature
next: verify
status: ready
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent: "0036"
blocked_by: ["0038"]
relates: ["0026", "0037"]
expects:
  - skills/orchestrate/SKILL.md
  - skills/orchestrate/outcome.schema.json  # the single copy of the FR13 shape
  - skills/verify/SKILL.md                  # AC20 only: relocate the evidence table
  - README.md
  - .claude-plugin/plugin.json
  - tests/skill-size.test.sh
  - tests/orchestrate.test.sh                # new
# `skills/develop/SKILL.md` is deliberately absent: the schema is supplied by the invoker, so no
# stage skill has to describe the FR13 shape, and develop is already over the skill-size goal
# with a recorded reason. See 0036's review amendment, the scope cut.
claimed_by:
claimed_at:
touches:
  # Re-entry of 2026-09-06 (token 6c77). The artifact was correct as delivered; what is
  # being fixed is three guards that cannot fail, plus the untyped new .py file.
  - tests/orchestrate.test.sh                # AC16, AC19, AC21 guards rescoped
  - tools/validate-json-schema.py            # type hints; new in this ticket's own diff
  - .claude-plugin/plugin.json               # version bump — the install predates this change
# `tests/skill-size.test.sh` was in expects: and is deliberately NOT touched: it already derives
# its subjects from skills/*/SKILL.md, so the new skill came under it with no edit. The QA plan's
# "widened by exactly one file" was written against a list that no longer exists.
---

## Problem

This is the supervisor itself — the half of project 0036 that turns `./next --drive`'s decision
(0038) into a driven loop, and the half that answers asks 3, 4 and 5 of Aaron's original request.

Nothing in the suite drives the loop today. `develop` Step 8 and `verify` Step 7 both end by
naming a command for a person to type in a new window, so **the human is the only thing that
knows** a `develop` session has stopped, that a ticket is sitting at `next: verify`, that the
buffer has filled, and that a retro is due. Every cycle a human drives is a cycle where a step can
be dropped, and the steps most often dropped are the ones with no output of their own — parking a
finding, running the full suite, releasing a claim.

The cost is recorded, not hypothetical. On 2026-08-23 hand-driving produced a wrong take: `0026`
was read as blocked and skipped, which `RANKING.md` still records. The same day an eleven-ticket
run spent **~44 tool calls of pure mechanism** on claims and closes that `./claim` and `./close`
now do.

## Functional requirements

**FR numbers are 0036's**, kept rather than renumbered so the design decision and the review
amendment in the parent still resolve. FR3 and FR17 split with 0038, and each says which half is
here. FR8 and FR9 are 0038's entirely: this skill **consumes** `./next --drive` and never
re-derives a routing rule of its own.

- **FR1 — Advance develop → verify.** When a stage session leaves a ticket at
  `next: verify, status: ready`, the supervisor starts a **new context** running `verify` on it.
  It does not verify the ticket itself, for the reason `develop` Step 5 already gives: a stage
  must not self-certify.
- **FR2 — Advance verify → develop, one *gate* at a time.** When a ticket closes green, the
  supervisor starts a new context on the next takeable **gate** — the topmost takeable
  `next: develop` row plus every other takeable `next: develop` row sharing its `expects:` scope
  or its parent slice — chosen by the queue's rank and not by the supervisor's judgement.
  **A gate, not a row:** `develop`'s own opening rule and `README.md`'s *One skill per session*
  both make the unit a gate, because what a session batches away is the startup it pays before
  writing a line. One session per row re-pays that per ticket and regresses the saving 0009 exists
  for — while every test still passes.
- **FR3 (gating half) — the findings gate stops dispatch, and is evaluated once per run.** When
  `./next --findings` reaches the threshold key 0038 adds to `config.yml`, the supervisor starts
  **no further stage session**, lets any running one finish, and runs a `retro` context. **The
  gate is evaluated once per run**: `retro`'s own Step 6 parks findings, so a supervisor that
  re-derives statelessly after a retro reads a still-over-threshold count and dispatches another
  retro, which parks more. FR4 ends the run before this bites in the planned case; AC17's resume
  path reaches it.
- **FR4 — The run ends at the retro, and the release chain is handed over as a checklist.** The
  supervisor runs the `retro` context, sees its edits committed, and stops. It does not push, bump
  the plugin version, install, or restart — it reports every remaining step of the chain `retro`
  Step 5 names, each marked done or outstanding, so no step can go silently missing. The
  2026-08-23 finding on the installed copy diverging from source at the same version number is why
  this is a checklist and not a sentence.
- **FR5 — Development resumes as a new run, started by a human.** There is no automatic resumption
  across the release. The human bumps, reinstalls and starts a fresh supervised session, which
  picks up from the backlog and FR10's log with **no conversational handoff** — so the requirement
  is what the next run needs in order to continue cold, not the resumption itself.
- **FR6 — The supervisor is interactive throughout.** The user can ask what is happening, redirect
  it to a specific ticket, hold it, or stop it, at any point — including while a stage session is
  running — and gets an answer without waiting for the current cycle to end.
- **FR7 — The supervisor's own context is bounded, and the bound is two numbers plus a turn
  count.** It reads disk signals and each stage's short structured outcome; it never ingests a
  stage session's transcript or a stage skill's instruction file.
  - **The floor** is what every turn re-sends before any run state exists: system prompt and tool
    schemas, the project's `CLAUDE.md` and whatever it imports, and this skill. Measured
    2026-08-24 for this repo: `CLAUDE.md` plus the imported `CONVENTIONS_CORE.md` is 2,645 words
    (~3.4k tokens), a skill at the 20,190-byte size goal is ~5k, and the harness floor is ~10–14k
    — **~20k per turn**, fixed before the first stage runs.
  - **The growth** is what a cycle adds: one `--drive` decision (~100 tokens), one stage outcome
    (~80), and the supervisor's own text. **~800 tokens per cycle.**
  - **The turn count is the actual cost driver, and it is the only one this ticket can move.** Cost
    is turns × floor. At three turns per cycle and N ≈ 4–6, a run is ~15 turns and **~350–400k
    cumulative input**, of which FR13's entire trim is ~0.1%. One turn removed per cycle saves
    ~26k, **sixty times the whole trim.** So the requirement is a **stated turns-per-cycle
    budget**, and the report turn is conditional on a state change rather than automatic.
- **FR10 — The supervisor's state survives its own session, and it survives by not being state.**
  What it started, what came back, every gate decision and every escalation land in an append-only
  log — one JSON line per event, under `.claude/backlog/runs/` — as they happen. But a resuming
  session derives **what to do next** from `./next --drive` and the backlog, never from the log:
  the backlog *is* the state, and the only fact not already on disk — how many findings have
  accrued since the last retro — is `./next --findings`, derived rather than stored. **The
  consequence is the requirement:** a crash mid-run and FR4's planned ending resume by the
  identical path, and there is no run state that can go stale or disagree with the backlog. The
  log is provenance and the human's record.

  **One stated exception, rather than a collision left to be discovered:** 0038's same-stage-twice
  guard takes *a completed outcome in between* as an input, and only the log holds that fact. The
  log is read for **what already completed**, never for **what to do next**.
- **FR11 — The supervisor claims nothing and holds no row.** Stage sessions claim and release
  their own rows per `CONCURRENCY.md` *Claim tokens*. Two consequences to handle rather than
  discover: a supervisor holding rows it is not working is the scope reservation *The working tree
  is shared too* forbids, and a supervisor holding none is invisible to every ownership check
  built on rows and tokens — the same blind spot `retro` Step 5 records for itself.
- **FR12 — Only one supervisor runs on a backlog at a time**, and a second one says so rather than
  double-driving the queue.
- **FR13 — Each stage ends with a trimmed, structured outcome, and that outcome is the
  supervisor's only input from it.** Fields rather than prose. **The shape is a session envelope
  wrapping an array of per-ticket outcomes, and it has to be** — AC4 puts two or three tickets in
  one develop session, so a gate where one closes to `verify`, one hits a decision and one leaves
  the tree red has three verdicts and one stdout object. Singular, it reports one and silently
  drops two.
  - **Envelope:** stage, session id, commits, cost, findings-parked count, conventions-resolved,
    escalation-or-null.
  - **Per ticket, one entry each:** id, verdict, resulting `next:` and `status:`, detail pointer.

  **The schema is supplied by the invoker and lives in exactly one file** —
  `skills/orchestrate/outcome.schema.json`. A stage is launched with
  `claude -p --json-schema "$(cat <that file>)"`, which validates at the tool-call layer, so stdout
  is the object or the stage failed.

  **Corrected 2026-09-06, in build:** this FR read `--json-schema <that file>` and cited a
  2026-08-24 run as confirmation. **The flag does not take a path.** Passing the filename fails
  with `Error: --json-schema is not valid JSON: JSON Parse error: Unrecognized token '/'`. The
  inline form above works and was confirmed by running it — the object came back and nothing else
  — and it keeps this FR's actual requirement, which is that the shape is declared in one file and
  supplied by the invoker rather than described by any stage. **So no stage skill has to describe the shape, and none
  should** — one invoker-supplied schema is the single source, which is the argument 0038's FR9
  already makes for `next`.
- **FR14 — Trimming the report moves detail to disk; it does not delete it.** Every kind of thing
  a stage's report carries today that the supervisor will no longer read — the diagnosis behind a
  bounce, the red that turned out to be another session's, the mechanism that surprised it — has a
  named durable home first: *Notes & decisions*, `FINDINGS.md`, or the FR10 log. 0015's FR3 is the
  precedent: the invocation went, and every line of reasoning for why the separate pass matters
  stayed.

  **The fourth kind: `verify` Step 7's evidence table.** Each AC and NFR, how it was checked, the
  actual output. **That is a check, not a narrative** — it is the paragraph that forces enumeration
  against real output rather than against memory, and it is the largest thing a verify report
  carries. Replace it with `{"verdict":"pass"}` and the trim has silently lowered what verify
  *does*, which *Out of scope* forbids. So it **moves into the item file**, where it belongs anyway
  as the QA record of a closed ticket, and the FR13 detail pointer points at it. **What is
  genuinely deleted is the salutation** — the recap of what was built and the closing "now run
  `/verify 0039` in a new session" — because in a supervised run it is addressed to a human who is
  not there. In a hand-driven run it stays, untouched (AC23).
- **FR17 (reporting half) — a pre-flight depth report, before anything is dispatched.** The
  supervisor reports, in one line and from the single `--drive` read 0038's AC29 makes available,
  how many takeable gates deep the backlog is and where it runs dry — *"two develop gates
  takeable; the next row after them is `next: design`."* This is the honest answer to ask 2 of the
  original request: it delivers *don't stop mid-session for unfinished design* without automating
  a design decision, and it costs nothing. Without it the first supervised run halts on the first
  `next: design` row and reads as broken.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | An unattended loop is standing authority to run this project's configured commands, commit, push and replace the tooling it is running on. It acquires none of that beyond the cycle it is in, and the push and install of FR4 stop for explicit human approval — "ship it" earlier in the session is not that approval | `security-conventions.md` |
| Observability | Every stage started, every outcome, every gate decision and every escalation lands on disk as it happens, with a timestamp. The supervising conversation is what dies; a decision that reached only the transcript is unrecoverable | `observability-conventions.md` |
| Performance | FR7's floor, growth and turns-per-cycle are stated numbers with the instrumentation shipping in the same change, and the measure is **cost per closed ticket** against 0026's observed baseline — not total spend, which a longer run always wins | `measurement-conventions.md` |
| Dependencies | The `claude` CLI as a launchable subprocess is a new dependency for a suite that is currently portable markdown and POSIX `sh`. Name it, and say what the suite does where it is unavailable — degrading to the hand-driven loop is an acceptable answer, silently not working is not | `dependency-conventions.md` |
| Compatibility | Any signal the supervisor reads is a contract between the stages and the driver. Adding one must not change what a hand-driven session does, since the plugin is public and installed elsewhere | `api-conventions.md` |
| Documentation | `README.md`'s *One skill per session* is the canonical statement of how this suite is run, and it currently says a person types the next command. It describes the supervised loop in the same change | `documentation-conventions.md` |

## Acceptance criteria

**AC numbers are 0036's.** Every criterion is written against the settled mechanism: a stage
session is a separate `claude -p` process launched in the background, returning a
`--json-schema`-validated outcome on stdout.

**The invocation, fixed by 0036's review amendment — `--bare` is disqualifying.** `claude --help`:
*"`--bare` Minimal mode: skip hooks, LSP, plugin sync, attribution, auto-memory, background
prefetches, keychain reads, and **CLAUDE.md auto-discovery**. Anthropic auth is strictly
`ANTHROPIC_API_KEY` or `apiKeyHelper` (**OAuth and keychain are never read**)."* No CLAUDE.md
discovery means **no conventions**, which `config.yml` makes mandatory — a `--bare` develop session
builds without them and passes every test in `tests/`, because nothing greps a subprocess's loaded
context. And the auth clause puts a secret in an unattended loop's environment on a billing path
separate from the supervisor, breaking AC14's arithmetic. So: **plain `claude -p`, no `--bare`,**
plus three flags all confirmed present — `--add-dir ../ai-building-conventions` (without which
AC19's narrow scoping blocks the very files `config.yml` points the stage at), `--session-id`
**pre-assigned at dispatch** so the transcript path is a dispatch-time fact in the FR10 log rather
than something a dead supervisor has to hunt for, and `--setting-sources` stated rather than
inherited.

- [ ] **AC1 — a stage runs as a separate process, and the skill and the conventions both resolve
  inside it.** Given a backlog with a takeable `next: develop` gate, when the supervisor dispatches
  it, then a `claude -p` process is launched with the `develop` skill invoked by name, it runs to
  completion in its own session, and the ticket is left at `next: verify, status: ready` with its
  claim released. **And the stage's own outcome confirms it resolved the project's conventions.**
  `--bare` appears nowhere in the invocation.
- [ ] **AC2 — the outcome is schema-validated, it is an envelope over an array, and it is all the
  supervisor gets.** Given a finished stage process, when the supervisor reads its result, then
  stdout parses as a single JSON object satisfying `skills/orchestrate/outcome.schema.json` — an
  envelope (stage, session id, commits, cost, findings-parked count, conventions-resolved,
  escalation-or-null) wrapping **one entry per ticket the stage handled** — and the supervisor
  reads no transcript, no skill file and no other output of that process. **Given a gate of three
  tickets whose verdicts differ**, then all three appear with their own verdicts and none is
  dropped.
- [ ] **AC3 — a stage that will not produce the shape fails loudly.** Given a stage process whose
  final message does not satisfy the schema, when it exits, then the supervisor records an
  escalation and starts nothing further — it does not parse prose, infer the verdict, or proceed
  on a partial object.
- [ ] **AC4 — the dispatch unit is a gate.** Given three takeable `next: develop` rows of which two
  share an `expects:` path, when the supervisor dispatches develop, then both sharing rows go to
  **one** stage session and the unrelated row does not, and the session claims and closes each of
  the two individually.
- [ ] **AC5 — verify follows develop without the supervisor verifying anything.** Given a ticket
  left at `next: verify, status: ready`, when the supervisor acts, then it dispatches a **new**
  `claude -p` process running `verify` on that ticket, and the supervisor itself runs no test and
  writes no verdict.
- [ ] **AC6 (gating half) — the gate lets the running stage finish, and fires once.** Given
  `./next --findings` at one entry below the threshold and a stage session running, when that
  stage returns and its parked findings cross the threshold, then the supervisor starts no further
  stage session, dispatches a `retro` process, and the crossing is one line in the run log.
  **Given a completed retro whose own Step 6 parked entries that leave the count still above the
  threshold**, then it does **not** dispatch a second retro: the gate is evaluated once per run
  and the run is over.
- [ ] **AC7 — the run ends at the retro, as a checklist.** Given a `retro` process returned with
  its edits committed, when the supervisor reports, then it stops, and its report enumerates every
  remaining step of `retro` Step 5's release chain each marked done or outstanding. No push, no
  version bump, no install, no restart, and no further stage.
- [ ] **AC8 — no push and no install without an explicit approval in that session.** Given a
  supervised run of any length, when the run ends, then `git push` has not run, the plugin version
  has not changed and no install has happened — unless the user approved that specific action in
  that session. "Ship it" earlier in the session is not that approval.
- [ ] **AC12 — the supervisor stays answerable while a stage runs.** Given a stage process running,
  when the user asks what is happening, redirects the run to a specific ticket, holds it, or stops
  it, then the supervisor answers from the run log and the backlog without waiting for that stage
  to finish and **without polling** — no turn is spent on a check that reports no change.
- [ ] **AC13 — the bound is measured as growth and turns, not as a ratio that cannot go red.**
  Given a completed multi-cycle run, when `tools/harvest-usage.sh` is run over the supervising
  session's transcript, then it reports **three** figures against FR7's stated numbers: the
  per-turn **floor**, the per-cycle **growth** as an absolute figure, and **turns per cycle**
  against the budget. All three land in the run log and the ticket's `cost_tracking:`.
- [ ] **AC14 — cost per closed ticket includes the supervisor's own spend.** Given a completed run,
  when the supervisor reports, then it states cost per closed ticket against this repo's observed
  figures — **$5.71 across all stages, $4.23 counting only develop and verify** (`MEASUREMENT.md`)
  — and not total spend. **Corrected 2026-09-06, in build:** this AC quoted **$6.01 / $4.45**,
  which `MEASUREMENT.md` itself records as the figures published *until 2026-08-30*, superseded
  when a twentieth ticket closed and the denominator was re-read. That file names `0036`, `0040`
  and `0041` as holding the stale pair; this ticket held it too and was not on the list. **The supervisor's own spend is in the numerator**: it attributes to no
  ticket's `cost_tracking:`, so a figure summed from the stages alone omits the one cost this
  project adds and reports a win that is partly unmeasured overhead.
- [ ] **AC15 — the supervisor holds no claim and no row.** Given a run at any point, when the item
  files are inspected, then no `claimed_by:` token was minted by the supervisor, and every
  `in-progress` row corresponds to a stage process that is actually running.
- [ ] **AC16 — a supervisor killed mid-cycle leaves a backlog a hand-driven session can pick up.**
  Given a supervisor killed while a stage runs, when a hand-driven session then runs `./next`, then
  it is offered a takeable row, no claim is orphaned, no row reads `in-progress` with nothing
  running, and `./next --drift` exits zero.
- [ ] **AC17 — a resuming supervisor derives its position, and does not restore it.** Given a run
  log from a killed run, when a new supervisor starts, then it determines the next action from
  `./next --drive` and `./next --findings` alone, and reads the log only for what already
  escalated, what the run has spent, and 0038's completed-outcome input. A log deleted between the
  two sessions changes the next action not at all.
- [ ] **AC18 — a second supervisor refuses.** Given one supervisor active on a backlog, when a
  second is started on the same backlog, then it says so and starts no stage session.
- [ ] **AC19 — each stage gets the narrowest authority that works, for that stage only.** Given a
  dispatched stage, when its process is launched, then it is scoped to the tools that stage needs
  and given a spend cap, and `--dangerously-skip-permissions` appears nowhere. Authority does not
  outlive the process.
- [ ] **AC20 — the trim moved the detail, it did not delete it — and the evidence table survives.**
  Given each kind of content a stage's report carries today that the supervisor will no longer read
  — the diagnosis behind a bounce, the red that proved to be another session's, the mechanism that
  surprised it, **and `verify` Step 7's per-AC evidence table** — when the stage finishes, then that
  content is present in *Notes & decisions*, `FINDINGS.md`, or the run log, and the FR13 detail
  pointer points at where. **Specifically for the evidence table:** given a closed ticket, when its
  item file is read, then every AC and NFR appears with how it was checked and the actual output. A
  verify stage that returns a verdict without having written that table fails this criterion.
- [ ] **AC21 — the loop surfaces what the run learned.** Given a completed cycle, when the
  supervisor reports it, then the report carries the findings-parked count for that cycle. This is
  the only signal left that the run is learning anything, because FR13 removed the narrative it
  would otherwise have come from.
- [ ] **AC22 — where the CLI cannot be invoked, it degrades visibly, and the probe is a real
  dispatch.** Given a host where the supervisor cannot launch a `claude` subprocess, when it starts,
  then it says so and falls back to naming the commands for a human to run — today's behaviour —
  rather than appearing to drive a loop it is not driving. **The detection is a startup probe that
  actually dispatches**: a trivial `claude -p --json-schema` no-op returning a fixed object, checked
  before the first real stage. `command -v claude` is not the check — an unauthenticated CLI and a
  nested session's permissions both look like a present binary, and the nested-dispatch question is
  the untested premise under AC1.
- [ ] **AC23 — a hand-driven session is entirely unaffected.** Given the whole change installed,
  when a session runs `develop` or `verify` by hand with no supervisor, then **its behaviour is
  what it was at 0.9.3** and every existing test still passes. The one intended change to a stage
  skill is `verify` writing its evidence table to the item file (AC20), which is a hand-driven
  improvement rather than a supervised-only one.
- [ ] **AC27 — the pre-flight depth report happens before the first dispatch.** Given a supervised
  run starting, when it reports, then it states how many takeable gates deep the backlog is and
  what stops it — in one line, from the `--drive` read it makes anyway, and **before** any stage
  process is launched.
- [ ] **AC24 — the documentation says how the suite is actually run.** Given the change, when
  `README.md`'s *One skill per session* is read, then it describes the supervised loop alongside
  the hand-driven one, and no longer implies a person typing the next command is the only path.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`), and there is no other runner.
- **Why this level:** the supervisor's failure mode is **silently driving the wrong thing**, and
  prose cannot be red. The routing half is already fixture-tested by 0038, which is what leaves
  this slice's testable surface small enough for the existing runner: a schema fixture, a
  skill-size guard, a hand-driven regression, and AC22's probe — which is itself a scripted
  assertion rather than a manual step, and doubles as the cheapest possible test of AC1's untested
  premise. **What genuinely cannot be a fixture is AC1's real dispatch**, and AC22's probe is the
  reason that is one cheap second rather than halfway through a real ticket.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), and specifically —
  - **A schema fixture** for `outcome.schema.json`: a gate of three tickets with three different
    verdicts validates, and a singular object does not (AC2, AC3).
  - **A probe test** running AC22's trivial `claude -p --json-schema` no-op and asserting the fixed
    object comes back, skipping loudly with a named reason where no CLI is present (AC22).
  - **A `--bare` guard**: a grep asserting `--bare` appears nowhere in `skills/orchestrate/`
    (AC1). This is a scripted assertion over prose, so it matches a phrase short enough to stay on
    one line.
  - **`tests/skill-size.test.sh` widened by exactly one file** — the new `orchestrate` skill. It
    does not widen to `develop`, `verify` or `retro`, because FR13's invoker-supplied schema means
    none of them describes the shape (AC23).
  - **Hand-driven regression**: every pre-existing test still passes with no supervisor present
    (AC23).
  - **A one-supervisor fixture** (AC18) and a killed-supervisor fixture asserting `./next --drift`
    exits zero and no row reads `in-progress` with nothing running (AC16).

## Out of scope

- **Relaxing any standard, or changing what any stage *checks*.** 0009's cross-cutting commitment,
  unchanged. FR13 changes what a stage *reports*: the trim is to a stage's closing narrative, never
  to a check, a test or a standard.
- **Reducing what a stage writes to disk.** FR13 trims what the supervisor *reads*; FR14 is the
  guard that the detail lands somewhere durable instead. A ticket's *Notes & decisions*,
  `FINDINGS.md` and the FR10 log all get *longer* under this change.
- **Re-deriving any routing rule.** 0038 owns `--drive`, the FR8 table and the exit codes. This
  skill reads the decision and acts; a second copy of the rules here is how the two answers
  diverge without either being wrong.
- **The lock policy and the budget-kill recovery.** 0040. This slice sets `--max-budget-usd`
  (AC19) and 0040 owns what happens when it fires.
- **Making `retro` a lifecycle stage or a `next` value.** FR3 schedules it; it stays a cadence job
  run in its own session, as its own skill states.
- **Automating a `design` answer, or `prototype`.** A design ticket needs a human decision; the
  supervisor routes it to one.
- **Concurrent stage *sessions*. The loop is sequential, and that is a decision rather than an
  omission** — the reasoning is in 0036's *Out of scope*, and Aaron confirmed on 2026-08-24 that
  parallelism was an option rather than a requirement. What this delivers instead is concurrency
  of *tickets*: FR2's gate (AC4).
- **Automating asks 1 and 2 of the original request.** "Queuing up new work" and "designing two
  sessions' worth of tickets" are **escalations**, not automation. FR17's depth report is the
  honest half of ask 2.
- **Pushing or releasing unattended**, in any form, however clearly the user asked for the loop to
  keep moving.
- **One supervisor across several repositories.** FR12 is one backlog.
- **A dashboard or reporting UI.** FR10's log is on disk and read by a session.

## QA evidence

**Pass of 2026-09-06, token `6782`. Verdict FAIL** — the change is correct as delivered, but three
criteria rest on a guard that cannot fail on the defect the criterion names, so three ACs are
unverified. `qa_level: unit`; suite is `for t in tests/*.test.sh` (`config.yml`), run per file to
attribute a red. All 22 files green, `tests/orchestrate.test.sh` 97 passed / 0 failed / **0
skipped** — the 0 skipped matters: AC22's probe dispatched for real on this host.

**Which copy executed.** The repo copy is the authority and is what was checked. The `verify` skill
*running* this session resolved from `~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.16/`,
whose bytes **predate this change** — see the finding below. This table was written per the repo
copy's instruction, which the installed copy does not yet carry.

**Method for every AC below: break the behaviour the criterion names, at the criterion's altitude,
confirm the guard reddens, restore.** Control run afterwards was green across all 22 files, which is
what licenses the reds. Every mutation was applied to committed files and restored with
`git checkout -- <the path mutated>`.

| # | How it was checked | Result |
|---|---|---|
| AC1 | `--bare` inserted into the dispatch invocation | ✅ `FAIL AC1/AC19 — the skill's own invocation carries --bare` |
| AC1 | `< /dev/null` deleted from the dispatch block only, probe keeping its own | ✅ `FAIL AC1 — 1 of 2 claude -p invocations do not redirect stdin`. Deleting it from the *probe* only reddens too, so the check is genuinely per-invocation |
| AC2 | `tickets` flipped from array to a singular object in the schema | ✅ `FAIL AC2 — a legitimate three-ticket gate was REFUSED: $.tickets: expected type object, got list` (3 reds) |
| AC2/AC3 | `additionalProperties` flipped to `true` on the envelope, then on a ticket entry | ✅ both redden separately — `a complete envelope carrying a stray 'verdict' validated` / `a complete ticket entry carrying a stray 'cost_usd' validated` |
| AC3 | `verdict` enum keyword disabled | ✅ `FAIL AC3 — an out-of-vocabulary 'verdict' validated; the supervisor would route on a value no stage means` |
| AC4 | *"The dispatch unit is a gate, not a row"* deleted | ✅ `FAIL AC4 — the skill does not state that a gate is the dispatch unit` |
| AC5 | *"A stage must not self-certify"* deleted | ✅ `FAIL AC5 — the skill does not say why verify is dispatched rather than judged here` |
| AC6 | the three once-per-run gate sentences deleted | ✅ `FAIL AC6 — the skill does not state that the findings gate fires once per run` |
| AC7 | the marked-checklist clause deleted from the release-chain rule | ✅ `FAIL AC7 — the skill does not hand the release chain over as a marked checklist` |
| AC8 | the no-push bullet deleted | ✅ `FAIL AC8 — the skill does not state the no-push rule with its "ship it" exclusion` |
| AC12 | the no-polling rule and its cost sentence deleted | ✅ `FAIL AC12 — the skill does not forbid polling; a turn spent on no change is the cost driver` |
| AC13 | `floor = contexts[0]` → `contexts[-1]`; then cycles counted from `outcome` events instead of `dispatch` | ✅ both redden (`no FLOOR of 20000`, `no GROWTH of 1500 per cycle`, `no TURNS per cycle of 2.0`). The fixture records 3 dispatches against 2 outcomes, so the two are genuinely distinguishable |
| AC14 | quoted figures staled back to `6.01 / 4.45` | ✅ `FAIL AC14 — the skill quotes [6.01 4.45] where MEASUREMENT.md records [5.71 4.23]` |
| AC15 | *"It never claims a row and never mints a claim token"* deleted | ✅ `FAIL AC15 — the skill does not state that it holds no row` |
| **AC16** | fixture half genuine — drives the real `./next` over a backlog with an orphaned claim; `--drift` exits 0, `0002` offered, `0001` not. **Prose half: the orphaned-claim rule deleted from Step 5 → still green.** | ❌ **unverified** — see gap 3 below |
| AC17 | *"The log is provenance. It is not state"* deleted; separately, the delete-the-log sentence deleted | ✅ both redden — `the skill does not say the log is not state` / `does not state the falsifiable half` |
| AC18 | `mkdir -p .claude/backlog/runs` line deleted | ✅ `FAIL AC18 — the skill takes the marker without creating runs/ first; on a fresh backlog the first supervisor is told the run is busy`. The fixture also proves the case can fire (a bare `mkdir` of the marker does fail with `runs/` absent) |
| **AC19** | `--dangerously-skip-permissions` inserted into the dispatch → red. `--allowed-tools`, `--add-dir`, `--session-id`, `--setting-sources` each deleted from the dispatch → each reddens by name. **`--max-budget-usd` deleted from the dispatch → still green.** | ❌ **partially unverified** — see gap 1 below |
| AC20 | verify's write-to-item-file instruction deleted → 3 reds; template's `## QA evidence` heading renamed → `FAIL AC20 — templates/item.md has no QA evidence section` | ✅ properly section-anchored, and the "before the close" clause is asserted separately |
| **AC21** | the findings-parked count deleted from Step 8, the report step the criterion names → **still green** | ❌ **unverified** — see gap 2 below |
| AC22 | a shim `claude` returning `{"probe":"WRONG"}` put on PATH | ✅ `FAIL AC22 — the probe did not return the fixed object; a supervisor on this host would drive nothing. Got: {probe:WRONG}`. With PATH emptied it skips loudly: `SKIP AC22 — no claude on PATH; the nested-dispatch premise under AC1 is UNVERIFIED in this run` — and in the real run it did **not** skip, so AC1's nested-dispatch premise is tested on this host |
| AC23 | whole suite per file: 22/22 green, 0 failures anywhere. `orchestrate` removed from `plugin.json`'s description → red. The only stage-skill change is verify's AC20 write | ✅ |
| AC24 | README's *One skill per session* section reverted to person-types-it wording | ✅ `FAIL AC24 — README's One skill per session does not mention the supervised loop` |
| AC27 | the depth sentence relocated below `## Step 3` | ✅ `FAIL AC27 — the depth report is not stated before the dispatch step (depth 186, dispatch 138)`. Anchored to line order, which is the criterion |

### NFRs

| Dimension | How it was checked | Result |
|---|---|---|
| Security | `security-conventions.md` read. AC8 and AC19 mutations both redden; `--dangerously-skip-permissions` and `--bare` are absent from every fenced invocation and the prose says why. Newly-reachable states walked: the marker directory, the stage subprocess's granted tools, the spend cap. No secret in the diff (`grep -inE '(api[_-]?key\|secret\|token *=\|password\|sk-ant)'` over the range returns only the skill's own prose about `--bare` forcing API-key auth) | ✅ |
| Observability | `observability-conventions.md` read. Step 5 states one JSON line per event under `.claude/backlog/runs/`, with a UTC timestamp and the run id, appended as it happens | ✅ stated; no guard asserts the run-log *format*, which is a fixture nothing yet produces — noted, not failed |
| Performance | `measurement-conventions.md` read. FR7's three numbers are stated in the skill and instrumented in `tools/harvest-usage.sh` in the same change; AC13's two mutations both redden; the tool's `DEFAULT_TURN_BUDGET = 3` and the skill's stated three-turn budget are asserted to agree | ✅ |
| Dependencies | `dependency-conventions.md` read. `validate-json-schema.py` documents why it is 114 lines of stdlib rather than `pip install jsonschema`, and states what it is not. The `claude` CLI's absence is handled by a real probe with a named fallback (AC22) | ⚠️ met in behaviour; the CLI is nowhere **named as a dependency** in README — see findings |
| Compatibility | `api-conventions.md` read. All 22 pre-existing test files green; the outcome shape is supplied by the invoker, so no stage skill describes it and a hand-driven session is unchanged | ✅ |
| Documentation | `documentation-conventions.md` read. README's *One skill per session* describes both paths; AC24's mutation reddens; the build session's learnings are recorded in *Notes & decisions* in the same change | ✅ |

**Privacy pass** (always-on, `data-privacy-conventions.md`): the change adds a new on-disk record,
`.claude/backlog/runs/<run-id>.jsonl`. `.gitignore` excludes only `.active/`, deliberately and with
the reason written down — so the **run logs are committed**, into a public repo. Correct for this
project (`company: none`) and the log is meant as the human's record, but the schema's `escalation`
field is free prose from a stage, so it is the field to watch if this plugin is ever run on a
backlog carrying company material. Flagged, not failed.

### The three gaps, and why they fail rather than annotate

Each is the adjacent-measurement shape `verify` Step 3 names: the guard runs, asserts, and measures
something *next to* the defect. In all three the delivered artifact is **correct** — the fix is to
the guard, not to the skill.

1. **AC19 — the spend cap.** `fenced "$SKILL"` concatenates *every* fenced block before grepping, so
   the Step 1 probe's `--max-budget-usd 0.25` (line 68) satisfies the check on the Step 3 dispatch
   (line 147). Deleting the cap from the dispatch leaves the suite at `97 passed, 0 failed`. The
   other four flags in the same loop redden by name because they appear in one block only. This is
   the identical shape this session's own build notes record fixing for `< /dev/null` — *"one entry
   in a sweep over all fenced blocks concatenated"* — one loop above.
2. **AC21 — the findings-parked count.** `grep -qF 'findings-parked count' "$SKILL"` over the whole
   file. The phrase occurs three times; two are in Step 4 describing the schema envelope. Deleting
   it from Step 8, the report step the criterion is written about, leaves the suite green.
3. **AC16 — the orphaned claim.** `grep -qF 'Claim tokens'` over the whole file. That citation also
   appears in Step 7 for an unrelated rule, so deleting Step 5's *"never a row to take over"*
   sentence leaves the suite green.

**The fix is cheap and already demonstrated in this same file**: AC20's guard extracts its section
before grepping and AC27's compares line numbers. The same treatment for these three — scope the
cap check to the dispatch block, scope AC21 to the report section, and anchor AC16 to the sentence
rather than the citation.

**Not carried out here on purpose.** Inventing an assertion at QA time would manufacture a guard for
a decision taken on other grounds; the gap is published and left uncovered for `develop`.

## Notes & decisions

- **The design decision of 2026-08-24 and Aaron's review amendment of the same day both live in
  `items/0036-orchestrate-the-stage-sessions.md`, *Notes & decisions*, and are not restated
  here** — including why a subprocess beat a subagent, the `Workflow`/`SendMessage`/`CronCreate`
  rejections, and the permission-posture trade-off. A copy drifts the first time either is edited,
  and `verify` would then check the stale one.
- **`blocked_by: 0038`, and it is a real blocker rather than a courtesy.** FR8 and FR9 are 0038's
  entirely; this skill consumes `./next --drive`'s decision and exit code. Built first, it would
  have to carry its own copy of the routing rules — the divergence 0038's FR9 exists to prevent.
- **`relates: 0026`, deliberately not `blocked_by`.** 0026 produces the observed per-turn baseline
  AC14 measures against. The precedent is 0025, recorded in `RANKING.md`: *blocking a correct piece
  of work on an unscheduled measurement is how it waits forever.* Fold 0026's figure into the
  measure when it lands.
- **`size: l`, and that is the ceiling rather than a description.** `l` means "multiple sessions or
  needs a design decision first"; the design is settled, so it is multiple sessions. **This is the
  slice to watch** — if a develop session finds it cannot be finished, the split to look at first
  is the schema and the dispatch mechanics (AC1–AC5) from the run-lifecycle requirements
  (FR4–FR7, FR10, AC13–AC18), which is the seam the QA plan already falls along.
- **The second-order cost of the trim, and the thing to look at first on revisiting.** FR6 asks the
  supervisor to surface insights; FR13 removes the stage narrative it would most naturally surface
  them *from*. So **everything the user learns comes from what stages write to disk** — which
  promotes FR14 from a courtesy to the load-bearing requirement, and makes *Notes & decisions* and
  `FINDINGS.md` the product surface rather than a byproduct. Built weakly, the loop runs smoothly
  and quietly teaches the user nothing, which is the one failure mode this suite has no check for:
  nothing goes red when a session learns less than it could have. AC21 is the thin guard.
- **Left as a known cost, not a gap: `FINDINGS.md` holds 28 entries against a threshold of about
  8.** On the measured rate the gate fires almost immediately, which is correct behaviour and an
  uncomfortable amount of it. The threshold is configurable per project (0038's FR3), and this
  repo's rate is inflated because its tickets are *about* the tooling, so every one surfaces tooling
  defects. A project whose tickets are about a product should expect longer runs. Worth revisiting
  if the first supervised run spends more on retros than on tickets.

### From the build session, 2026-09-06 (token 21cb)

- **`--json-schema` takes inline JSON, not a path, and the whole slice rested on it.** See the
  correction in FR13. What is worth carrying forward is the *shape* of the error: the FR cited a
  run that confirmed it, the citation was specific and dated, and it was still wrong — a claim
  about an external tool ages exactly like a quoted figure, and re-running it cost one command.

- **Two more defects only a real dispatch could find, both invisible in prose.**
  **Without `< /dev/null` the nested CLI waits on stdin** and then prints
  `Warning: no stdin data received in 3s` **into the stream the supervisor parses as JSON** — so a
  perfectly good stage reads as a schema failure and the supervisor escalates on it. And
  **`--max-budget-usd 0.05` returns `Error: Exceeded USD budget` rather than the object**, because
  a session pays its ~20k-token floor before doing anything at all; USD 0.25 passed. A cap set
  below the floor fails every stage identically and reads exactly like a broken CLI. Both are now
  in the dispatch block, and the first is guarded per invocation.

- **AC1's untested premise is now tested and holds.** A nested `claude -p` dispatched from inside a
  Claude Code session returns a schema-validated object on stdout in about three seconds. AC22's
  probe is that dispatch, run for real on every suite run, skipping loudly with a named reason
  where no CLI is present.

- **The QA plan's `--bare` guard could not be written as specified.** It asked for "a grep
  asserting `--bare` appears nowhere in `skills/orchestrate/`" — but the skill has to *explain* why
  `--bare` is disqualifying, so a plain absence grep reds exactly the file that documents the rule
  best. This is the negative-assertion trap `testing-conventions.md` names: anchor to a state, not
  to vocabulary. The guard now looks for the flag **inside fenced code blocks** — where an
  invocation lives — and checks the prose separately and positively. Same treatment for
  `--dangerously-skip-permissions`.

- **`tests/skill-size.test.sh` needed no edit, and the QA plan's "widened by exactly one file" is
  stale.** It derives its subjects from `skills/*/SKILL.md`, so `orchestrate` came under it the
  moment the file existed. `tests/last-line.test.sh` and `tests/reporting.test.sh` did **not** —
  both carried a hardcoded six-skill list, so the new skill joined the set they govern without
  joining the set they check. Both now derive, taking the tree root as a parameter so their fixture
  cases keep their own authored trees.

- **Three guards of my own could not fail when first written, and each was found by mutation.**
  Recorded because the shapes recur. (1) With no schema on disk the validator exits 2, and
  `valid()` folded that into "invalid" — so every refusal case was green against a schema that did
  not exist. (2) `additionalProperties: false` had no coverage at all: the singular-object case is
  refused for *missing `tickets`*, so mutating the keyword to `true` changed nothing. (3) The
  `< /dev/null` check was one entry in a sweep over *all* fenced blocks concatenated, so deleting
  the redirect from the dispatch left the probe's satisfying it. All three now fail on the defect
  they name.

- **A fixture that could not tell two implementations apart.** AC13's run-log fixture first had two
  dispatches and two outcomes, so a script counting outcomes instead of dispatches produced
  identical figures and the mutation came back green — on the one line that chooses between them.
  It now records three dispatches and two outcomes, which is also the honest shape: a run killed
  with a stage in flight never has equal counts, and is the run whose figures matter most.

- **A real bug in the single-instance marker, and the wrong diagnosis it produced.** The documented
  `mkdir .claude/backlog/runs/.active` fails on a backlog that has never been driven, because
  `runs/` does not exist — and `|| echo busy` then reports *another supervisor holds this backlog*,
  on the first run, with no second supervisor anywhere. Fixed with `mkdir -p` on the parent; the
  marker is gitignored, because committed it makes every clone report a busy backlog.

- **What this session could NOT verify, stated plainly for the QA pass.** AC1's "the ticket is left
  at `next: verify, status: ready` with its claim released" and AC4's "the session claims and
  closes each of the two individually" are properties of a **real supervised run against a real
  backlog**, and no fixture here reaches them — what is tested is that a nested dispatch works, and
  that the skill instructs the rest. AC6, AC7, AC8, AC12, AC15, AC17 and AC21 are likewise guarded
  as prose: the greps prove the rule is written down, never that a session obeyed it. The first
  real supervised run is what closes that gap, and `0040` is where its recovery behaviour belongs.

- **`cost_tracking:` and `tracker:` are both absent from `config.yml`**, so neither was recorded nor
  mirrored. Not an omission — they are off unless configured.

### From `FINDINGS.md`, landed 2026-09-05

- **FR3's once-per-run gate is now a consequence rather than a workaround.** `retro` Step 4 states the
  invariant FR3 was compensating for: **no entry survives the pass that read it**, and a retro's own
  Step 6 parks are the *next* pass's input rather than residue from this one (`b9a5ee0`). A supervisor
  re-deriving statelessly after a retro therefore reads a small, fresh count instead of a
  still-over-threshold one the retro itself inflated. Evaluating the gate once per run stays correct —
  it is what stops a park-and-redispatch loop in the unplanned case — but FR3 no longer rests on the
  buffer being structurally unable to drain, and its rationale is worth re-reading when this is built.
- **`retro` Step 2's "propose, then wait" has no correct answer in an unattended end-of-run retro**,
  which is the mode FR4 creates. The gate exists so a rejected finding costs nothing to have proposed,
  and it is right when a human is driving; a supervisor cannot answer it. FR4 should say what the
  supervised pass does instead — proceed on the skill's own recommendation and report what it chose,
  or stop and hand the proposal back as part of the checklist. Parked rather than decided here: it is
  FR4's scope, not `retro`'s.

### From the QA pass, 2026-09-06 (token 6782) — FAIL

**The change is correct as delivered; three of its guards are not.** Full per-AC evidence is in
`## QA evidence` above. The suite is green (22/22 files, `orchestrate` 97/0/0, 0 skipped) and every
mutation at a criterion's own altitude reddened except three:

- **AC19's spend cap** — `fenced "$SKILL"` concatenates all fenced blocks, so the Step 1 probe's
  `--max-budget-usd 0.25` satisfies the check on the Step 3 dispatch. Deleting the cap from the
  dispatch leaves the suite at `97 passed, 0 failed`.
- **AC21's findings-parked count** — a whole-file grep for a phrase that occurs three times, twice
  in Step 4's schema description. Deleting it from Step 8, the report step the AC names, is green.
- **AC16's orphaned-claim rule** — a whole-file grep for `Claim tokens`, a citation Step 7 also
  carries. Deleting Step 5's *"never a row to take over"* is green.

**All three are the same shape, and this session already found and fixed it once** — the build notes
above record exactly it for `< /dev/null` (*"one entry in a sweep over all fenced blocks
concatenated"*), one loop above the AC19 check that still has it. Worth reading as one defect in the
sweep rather than three unlucky greps.

**The fix pattern is in the same file already**: AC20's guard extracts its section before grepping,
AC27's compares line numbers. Scope the cap check to the dispatch block, AC21 to the report section,
and AC16 to the sentence rather than the citation. Not done here — inventing an assertion at QA time
manufactures a guard for a decision taken on other grounds.

**Not a reason for the FAIL, but the next session should know:** the installed plugin at
`~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.16/` **predates this whole change**.
`0.9.16` was set by `9528098`, 23 commits before `56b2566` claimed this ticket, so the version never
moved during the work and the version-keyed cache was never re-extracted — `installed_plugins.json`
nonetheless records `lastUpdated: 2026-09-06T05:20:06` against `gitCommitSha: 9528098`. The install
has six skills and no `orchestrate`; its `verify` has no AC20 instruction. This is `CLAUDE.md`'s
documented failure mode observed live, in both halves at once. **The re-entry needs its own version
bump** — `tools/release` — or the next session verifies a copy that still does not exist.

**One convention breach in the diff, flagged rather than scored against an AC.**
`tools/validate-json-schema.py` is the repo's first standalone `.py` and carries **no type hints**
on any of its three functions (`type_ok`, `validate`, `main`), against `CONVENTIONS_CORE.md`'s
*"Python with full type hints"* — a principle, not a preference. It is a **pre-existing repo-wide
pattern** (every python embedded in `tools/*.sh` is unhinted too), so scoping the whole debt to this
ticket is arguable and `develop` should decide; what is not arguable is that this change is where a
new file adopted it. There is no NFR row for it, which is why it surfaced in Step 4's always-on pass
rather than in the table.

### From the re-entry build session, 2026-09-06 (token 6c77)

**Scope: the three unfalsifiable guards and the untyped validator. The skill itself was correct as
delivered and is unchanged** — `git diff` over this session touches `tests/orchestrate.test.sh` and
`tools/validate-json-schema.py` only. That is the shape the QA verdict asked for: the fix was to the
guards, not to the artifact.

- **All three now fail on the defect their criterion names, each proven by mutation with the
  masking phrase left in the file.** AC19: deleting `--max-budget-usd` from the Step 3 dispatch reds
  `1 of 1 dispatch block(s) do not carry --max-budget-usd` while Step 1's probe keeps its own cap
  (`grep -c` still 1). AC21: deleting the count from Step 8 reds while Step 4's two occurrences
  remain (`grep -c` still 2). AC16: deleting Step 5's *"never a row to take over"* reds while Step
  7's citation remains (`grep -c` still 1). The other four AC19 flags redden individually too, and
  the control run afterwards is 100/0/0 — which is what licenses the reds.

- **AC19's set is identified by the prompt, never by a flag under test, and the partition is the
  half worth keeping.** Anchoring "which block is a dispatch" on `--allowed-tools` would make the
  check vacuous exactly when it should red: delete the flag and the block stops being a dispatch, so
  nothing is left to fail. Identity comes from the stage slash-command in the prompt instead. That
  moves the vacuity risk to the prompt, so every `claude -p` block is partitioned into probe or
  dispatch and an unclassified one is loud — renaming the prompt now reds seven checks rather than
  silently emptying the set. **This is the general repair for a derived-subject guard: derive the
  set, then assert the set is exhaustive.**

- **`section()` flattens whitespace before matching, and that was not gold-plating.** AC16's target
  sentence straddles a line break in the skill (`*Claim` / `tokens*`), so a line-based grep cannot
  match it at all — the hazard `CLAUDE.md` names, met live. Flattening also removes the class AC20's
  own comment records having been bitten by. A criterion is about what a section *says*; where the
  words wrap is not part of it.

- **The mechanical check proposed in `FINDINGS.md` for this defect class catches one of these three,
  and the misses are instructive** — parked as its own entry. It under-counts a phrase that wraps
  (so it is blind to AC16 for the same line-based reason the guard was), and it does not recognise a
  guard over a *filtered* stream as whole-file (so it is blind to AC19's `fenced "$SKILL" | grep`).
  Ran it over this file after the fix: two remaining candidates, both examined and both sound —
  AC2's `outcome.schema.json` is a genuinely file-level criterion, and AC7's `checklist` is saved by
  its conjunct, `marked` occurring exactly once. **No further unfalsifiable guard found in this
  file**, but by examination rather than by the check.

- **The untyped validator: fixed for this ticket's own new file, deliberately not swept.**
  `CONVENTIONS_CORE.md` makes type hints a principle, and this diff is where the repo's first
  standalone `.py` adopted the unhinted pattern, so the file is this ticket's to fix. The
  pre-existing embedded python in `tools/*.sh` is the same breach and is **not** fixed here — that
  is the adjacent problem `develop` Step 4 says to queue rather than absorb. It **still needs a
  row**, along with the `ast`-based guard that would hold the rule for the next new file; no such
  row exists as of this writing. Annotations are postponed via `from __future__ import annotations`
  because the python3 actually present is 3.9, which evaluates neither `X | Y` nor the builtin
  generics at runtime. Behaviour unchanged: all three exit codes checked by hand.

- **NOT DONE, and it needs the user: the release.** The QA pass established that the installed
  plugin at `0.9.16` predates this whole change — confirmed again this session, the install has six
  skills and no `orchestrate`. `CLAUDE.md` says the remedy is `tools/release`, whose chain begins
  with a **push to `main`**, and there are 46 unpushed commits. `CONVENTIONS_CORE.md` requires
  specific approval for a push that lands on a shared branch or triggers a deploy, and `develop`
  Step 5 says building a ticket is not authority to publish it — so this session did not run it.
  **This does not block the QA pass**: the repo copy is the authority and is what `verify` checks,
  which is what the previous pass did. It blocks any session that would *run* the orchestrate skill.

- **`cost_tracking:` and `tracker:` remain absent from `config.yml`**, so again neither recorded nor
  mirrored. Off unless configured.

- **`qa_level: unit` is correct and unchanged.** The change is test-side plus one non-behavioural
  file; the suite is the whole of what can judge it.
