---
name: orchestrate
description: >
  Drive a project's backlog without a person typing the next command: dispatch each stage as its
  own `claude -p` session, read back one schema-validated outcome, and route on `./next --drive`
  until the queue runs dry or the findings gate ends the run in a retro. Use when the user says
  "work the backlog", "keep going until it's done", "run the loop", "drive it", "supervise this",
  "do the next few tickets", "run develop then verify", or invokes /orchestrate. Also use when the
  user is about to hand-drive several cycles and would rather watch than type. Reads
  .claude/backlog/ — created by the queue skill. NOT for building one ticket, which is /develop,
  and NOT for deciding anything: a design question, a push, a release and a narrowed contract are
  all escalations to the user, never automation.
---

# /orchestrate

Drive the loop the suite is already built for. Every stage skill ends by naming the command a
person types next; this runs that command instead, as a separate session, and routes on what comes
back until the backlog or the findings gate says stop.

**This skill drives sessions. It does not do their work.** It writes no code, runs no test, writes
no verdict, claims no row and closes no ticket — the stages do all of that, unchanged. A supervisor
that starts doing a stage's job has removed the separation the stages exist to provide, and its own
context is what pays for it.

**Nothing here changes what a hand-driven session does.** A `develop` or `verify` session run by a
person behaves exactly as it did before this skill existed. Every signal below is read from disk or
from a stage's stdout; none of it is a new obligation on a stage that no supervisor invoked.

**This skill states no standards of its own.** How to build, test, commit and review is the
project's conventions, resolved per `references/CONVENTIONS.md` at the plugin root. It states no
routing rules of its own either: `./next --drive` owns which stage runs next and why, and a second
copy of those rules here is how two answers diverge without either being wrong.

**Another session may be working this same backlog.** Read `references/CONCURRENCY.md` at the
plugin root before touching any backlog file — and note that this skill, like `retro`, holds no
row, so every ownership check built on claim tokens is blind to it.

---

## What this costs, and the one number you can move

The supervisor's own context is a floor times a turn count. The floor is what every turn re-sends
before any run state exists — the harness, this file, the project's `CLAUDE.md` and what it
imports — and it is roughly **20k tokens, fixed** before the first stage runs. The growth is what a
cycle adds: one `--drive` decision, one stage outcome, and your own text, at **roughly 800 tokens
per cycle**. Cost is turns times floor, so **the turn count is the only term this skill can move**,
and one turn removed per cycle saves more than trimming every word in a stage's report.

So: **a budget of three turns per cycle** — dispatch, read back, route. The report turn is
conditional on a state change, never automatic. A turn spent checking on a stage that has not
finished is a turn spent for nothing, and there is no state it can discover that the stage's own
return will not deliver.

---

## Step 1 — Three checks before anything is dispatched

All three happen before the first stage process, and the first two can end the run.

**1. Probe the CLI, by actually dispatching.** `command -v claude` is not the check: an
unauthenticated CLI and a nested session that may not spawn one both look like a present binary,
and whether a nested dispatch works at all is the premise everything below rests on. Run a trivial
one:

```sh
claude -p --json-schema '{"type":"object","properties":{"probe":{"type":"string"}},"required":["probe"],"additionalProperties":false}' \
  --max-budget-usd 0.25 'Return the object with probe set to the string ok. Nothing else.' \
  < /dev/null
```

The fixed object comes back, or this host cannot drive a loop. **Where it cannot, say so plainly
and fall back to naming the commands for a person to run** — today's behaviour, which is a working
answer. What is forbidden is appearing to drive a loop you are not driving.

**2. Refuse to be the second supervisor.** One supervisor per backlog, and the marker is a
directory because `mkdir` is atomic:

```sh
mkdir -p .claude/backlog/runs                       # the parent, which a fresh backlog lacks
mkdir .claude/backlog/runs/.active 2>/dev/null || echo busy
```

**The `-p` line is not tidiness.** Without it, a backlog that has never been driven has no `runs/`,
the second `mkdir` fails on the missing parent, and `|| echo busy` reports *another supervisor holds
this backlog* — on the first run, with no second supervisor anywhere. An absent parent and a busy
marker have to be distinguishable, and one line is what distinguishes them.

Busy → read `.active/held-by` for the run id, the pid and the UTC timestamp, and say who holds it
rather than double-driving the queue. **A marker whose pid is no longer alive is stale**: say that
it is, name it, and take it over. Write your own `held-by` the moment you take it, and remove the
directory when the run ends.

**3. Report the depth, in one line, from the read you make anyway.** `./next --drive` prints how
many takeable gates deep the backlog is and where it runs dry. Say it before dispatching anything:

> *"Nine develop gates takeable; runs dry at 0080, which is `next: design` and needs a person."*

This is what stops the first run reading as broken when it halts on a design row. It costs nothing —
the decision line and the depth line come from the same call.

---

## Step 2 — The cycle

One call decides everything:

```sh
.claude/backlog/next --drive --completed <stage>[:<id>]
```

`--completed` says which stage just finished on which ticket, and it is what tells a `verify` bounce
from a fresh `develop` row. Give it at most once per call, and omit it on the first call of a run.

**Route on the exit code, never on your own reading of the queue.** `0` dispatch what it named ·
`3` the run is complete, nothing takeable · `4` escalate, a person decides · `5` the findings gate
is reached, dispatch `retro`. `1` and `2` are drift and usage errors, and both stop the run.

**The dispatch unit is a gate, not a row.** `--drive` prints the whole gate — the topmost takeable
row plus every other takeable row sharing its `expects:` scope or its parent slice — and all of it
goes to **one** stage session. That is the saving the suite is built on: a stage pays for the
conventions, the project's `CLAUDE.md`, the concurrency protocol and its orientation before it
writes a line, and those are shared across tickets touching the same files. Splitting a gate across
sessions re-pays that per ticket while every test still passes.

**`develop` is followed by `verify`, and you verify nothing yourself.** A ticket left at
`next: verify, status: ready` gets a **new** process running `verify` on it.
**A stage must not self-certify** — that is the whole reason there are two stages, and a supervisor
that reads a green and closes the ticket has become the self-certification it was avoiding.

**Stay answerable while a stage runs, and do not poll.** The user can ask what is happening,
redirect the run to a specific ticket, hold it or stop it at any point. Answer from the run log and
the backlog — both are on disk and current — rather than waiting for the cycle to end. A turn spent
asking a running stage whether it has finished reports no change and costs a full floor.

---

## Step 3 — How a stage is dispatched

```sh
claude -p \
  --session-id "$RUN_STAGE_UUID" \
  --json-schema "$(cat <plugin root>/skills/orchestrate/outcome.schema.json)" \
  --add-dir ../ai-building-conventions \
  --setting-sources user,project \
  --allowed-tools '<the tools that stage needs>' \
  --max-budget-usd <cap> \
  '/develop 0039 0086' \
  < /dev/null
```

Every flag earns its place, and two of them are load-bearing in a way that is not obvious:

- **`--json-schema` takes inline JSON, not a path.** Passing the filename fails with *"--json-schema
  is not valid JSON"*. `"$(cat …)"` is the form that works, and it keeps FR13's actual requirement:
  the shape is declared in **one file**, supplied by the invoker, so no stage skill describes it.
- **`--session-id` is pre-assigned here, not read back afterwards.** That makes the transcript path
  a dispatch-time fact in the run log rather than something a dead supervisor has to hunt for.
- **`--add-dir`** reaches the conventions repo. Without it the narrow scoping below blocks the very
  files `config.yml` points the stage at, and the stage stops — correctly, and confusingly.
- **`--setting-sources`** is stated rather than inherited, so a stage's settings are a property of
  the dispatch and not of whatever shell the supervisor happened to start in.
- **`< /dev/null` is load-bearing, not tidiness.** Without it the nested CLI waits on stdin and
  then prints *"Warning: no stdin data received in 3s"* **into the stream you are parsing as
  JSON** — so a perfectly good stage reads as one that failed the schema, and Step 4 escalates on
  it. Redirect stdin on every dispatch, the probe included.

**`--bare` is disqualifying and appears nowhere.** It skips CLAUDE.md auto-discovery, which means
**no conventions** — and a stage that builds without them passes every test in `tests/`, because
nothing greps a subprocess's loaded context. It also forces API-key auth, putting a secret in an
unattended loop's environment on a separate billing path.

**A cap below the startup floor fails every stage identically.** The probe above was written at
USD 0.05 and returned `Error: Exceeded USD budget` rather than the object — not because the work
was expensive, but because a session pays its ~20k-token floor before it does anything at all. A
cap set below that reads exactly like a broken CLI. Size a stage's cap against this repo's observed
per-session figures in `MEASUREMENT.md`, never against a guess at how small the work is.

**Authority is the narrowest that works, and it does not outlive the process.**
`--dangerously-skip-permissions` appears nowhere. Each stage gets the tools it needs and a spend
cap, granted per dispatch. An unattended loop is standing authority to run commands, commit, and
replace the tooling it is running on; it acquires none of that beyond the cycle it is in.

---

## Step 4 — Read the outcome, and nothing else

Stdout is a single JSON object satisfying `skills/orchestrate/outcome.schema.json`, or the stage
failed. That object is **all you read**: not the transcript, not the skill file, not any other
output of that process. The envelope carries the stage, the session id, the commits, the cost, the
findings-parked count, which conventions resolved, and an escalation or null; the array carries one
entry per ticket, each with its id, verdict, resulting `next:` and `status:`, and a pointer to where
its detail landed.

**It is an array because a gate is several tickets.** Three tickets with three different verdicts
is the ordinary case, and all three route independently.

**A stage that will not produce the shape fails loudly.** Record an escalation, start nothing
further, and stop. Do not parse prose, infer a verdict from an exit code, or proceed on a partial
object — an inferred verdict is indistinguishable from a real one afterwards, and it is the one
failure that corrupts the backlog rather than merely halting.

**`conventions_resolved: null` is an escalation, not a pass.** The project makes conventions
mandatory; a stage that resolved none built against no standard.

**The detail pointer is the guarantee that the trim moved the detail rather than deleting it.**
Everything the stage worked out — the diagnosis behind a bounce, the red that turned out to be
another session's, the mechanism that surprised it, and a verify pass's per-AC evidence table — is
on disk in the item file, `FINDINGS.md`, or the run log, and the pointer says which. **Nothing about
this run is learnable from anywhere else**, because the stage narrative you would otherwise have
read is exactly what was trimmed. Surface it: a cycle's report carries the findings-parked count,
and a pointer worth opening gets named.

---

## Step 5 — The run log

**One JSON line per event, appended as it happens, under `.claude/backlog/runs/<run-id>.jsonl`.**
Every stage started, every outcome, every gate decision and every escalation, each with a UTC
timestamp and the run id. The supervising conversation is what dies; a decision that reached only
the transcript is unrecoverable.

**The log is provenance. It is not state, and this is the point of it.** A resuming supervisor —
after a crash or after the planned ending — derives what to do next from `./next --drive` and
`./next --findings` alone. The backlog *is* the state. Delete the log between two sessions and the
next action does not change at all; what is lost is the record, not the position.

**It is read for exactly three things**: what already escalated, what the run has spent, and
`--drive`'s completed-outcome input, which needs to know a stage finished in between. What already
completed, never what to do next.

**A supervisor killed mid-cycle leaves a backlog a hand-driven session can pick up**, and that
falls out of holding no row: `./next` offers a takeable row, `./next --drift` exits zero, and any
claim belongs to a stage process that made it and is responsible for releasing it. If a killed
stage did leave a claim behind, that is a dead session to report — `CONCURRENCY.md`, *Claim
tokens* — never a row to take over.

---

## Step 6 — The findings gate, and the end of the run

**The gate stops dispatch and fires once per run.** When `./next --findings` reaches the project's
threshold, start no further stage session, let any running one finish, and dispatch a `retro`
context. Log the crossing as one line.

**Once per run, and a completed retro does not re-arm it.** `retro`'s own closing step parks what
surprised *it*, so a supervisor that re-derives statelessly afterwards can read a count and
dispatch again, which parks more. The run is over at the retro either way; evaluating the gate once
is what makes that true in the unplanned case too.

**The run ends at the retro, and the release chain is handed over as a checklist.** See the retro's
edits committed, then stop. **No push, no version bump, no install, no restart, and no further
stage** — report every remaining step of the chain `retro`'s durability step names, each marked
done or outstanding, so no step can go silently missing. A chain reported as a sentence is a chain
with a step missing; the installed copy diverging from source at the same version number is exactly
what a prose summary hides.

**An unattended retro cannot answer its own "propose, then wait".** That gate exists so a rejected
finding costs nothing to have proposed, and it is right when a person is driving. Dispatched here,
**the retro proceeds on its own recommendation and reports what it chose**, and every choice it
made goes into the checklist as an outstanding item for review. Do not silently accept them on the
user's behalf.

**Development resumes as a new run, started by a person.** There is no automatic resumption across
a release.

---

## Step 7 — A held lock, and a stage killed by its cap

Both strand the whole repository rather than one ticket, and neither is anything `./next --drift`
can see.

**The lock is not the supervisor's to take. It never takes it and never breaks it** — every `claim`
and `close` in the repo waits behind a broken one, including sessions this run knows nothing about,
and the tempting answer is a driver stealing a lock from a stage that is still working. Age it from
the **directory**, never from `held-by`: `claim` writes no timestamp there where `close` and
`handoff` both do, so the commonest holder is the one a timestamp read cannot see.

```sh
LOCK=.claude/backlog/.lock
[ -d "$LOCK" ] || exit 0
stale=$(sed -n 's/^lock_stale_seconds: *//p' .claude/backlog/config.yml)
mtime=$(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK")
age=$(( $(date -u +%s) - mtime ))
[ "$age" -gt "$stale" ] && echo "aged $age" || echo "fresh $age"
```

**Fresh** — it **waits rather than escalating**. A lock in use is the normal case and is held for
seconds. **Aged** — it escalates, naming the age and the ticket `held-by` records, joined through
the **run log** to the stage process that should have held it, and **dispatches nothing**.

**A stage killed by `--max-budget-usd` is worse than a killed supervisor**, whose tree is at least
clean: here the claim is held, the tree is dirty and the lock may be taken. That exit routes as an
escalation and is **not read as a crash**. The escalation names **the claim token**, **the dirty
paths** and **the lock state**, so nothing needed to recover it lives only in the dead stage's
transcript, and it lands in the run log timestamped before it reaches the user. Then the supervisor
**starts nothing further**. Releasing that claim, cleaning that tree and removing that lock are a
human's, every one — recovery is not authority this loop was given.

**The cap is `stage_budget_usd` in `config.yml`, derived from `cost_tracking:` history and recorded
with the derivation beside it**, never a figure chosen here and never one rounded later.

---

## Step 8 — What this never does

- **It never pushes, bumps a version, installs, or restarts** without the user approving that
  specific action in that session. "Ship it" earlier in the session is not that approval, however
  clearly the loop was asked to keep moving.
- **It never claims a row and never mints a claim token.** Stage sessions claim and release their
  own — `CONCURRENCY.md`, *Claim tokens*. A supervisor holding rows it is not working is the scope
  reservation *The working tree is shared too* forbids, and every `in-progress` row during a run
  should correspond to a stage process that is actually running.
- **It never answers a design question, narrows a contract, or writes a ticket.** A `next: design`
  row, a stale FR and a ticket that needs splitting are all exit code `4`: name what must be decided
  and stop. Queuing new work and designing tickets are escalations, not automation.
- **It never runs two stage sessions at once.** The loop is sequential by decision. What it
  parallelises is *tickets*, through the gate.
- **It never drives more than one backlog.**

---

## Step 9 — Report

What belongs on the screen and what belongs on disk is `references/REPORTING.md` at the plugin
root. Three things it cannot say, because they are specific to a run rather than to a stage:

- **The cost per closed ticket, with your own spend in the numerator.** Not total spend, which a
  longer run always wins. This repo's observed figures, across all stages and then counting only
  develop and verify, are **USD 5.71** and **USD 4.23** — but recompute both from `MEASUREMENT.md`
  rather than quoting these, because a quoted figure is a cache of another file and this
  particular pair has gone stale once already. The denominator moves every time a ticket closes.
  **The supervisor attributes to no ticket's `cost_tracking:`**, so a figure summed from the stage
  outcomes alone omits the one cost this skill adds and reports a win that is partly unmeasured
  overhead.
- **The bound, as three figures rather than a ratio.** `tools/harvest-usage.sh <transcript-dir>
  --run .claude/backlog/runs/<run-id>.jsonl` prints the per-turn **floor**, the per-cycle
  **growth** as an absolute number, and **turns per cycle** against the budget in the section
  above. A ratio of supervisor to stage spend cannot go red — a longer run improves it while the
  supervisor gets steadily worse — which is why none of the three is one. All three land in the
  run log.
- **What the run learned.** Every cycle's findings-parked count, and the pointers worth opening.
  This is the only signal left that the run is learning anything.

**End on the hand-off line, the very last thing printed:**

```
- — <VERDICT> — next: <command>
```

The ID slot is a dash: this session holds no row, so there is no ticket to hand off, and the
`next` slot names the command a person runs rather than a stage.

Example: `- — RUN COMPLETE — next: restart, then /orchestrate` — the queue ran dry or the retro ended it.
Example: `- — ESCALATED — next: /design 0080` — a person decides, and the run stopped there.
Example: `- — DEGRADED — next: /develop 0039` — no CLI to dispatch with; the commands are named for a person.
Example: `- — REFUSED — next: nothing, another supervisor holds this backlog`.

`RUN COMPLETE` closes no ticket and never means `done`: the tickets this run touched were closed by
the `verify` sessions it dispatched, each on its own verdict.
