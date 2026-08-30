# AI Building Tools

Five skills that give a project a **stack-ranked local backlog any agent can work from**:
queue a piece of feedback once, and weeks later a cold session can pick it up, build it, and
verify it without asking a single clarifying question.

| Skill | Does | Phase |
|---|---|---|
| `/queue` | Turns something you just said into a fully specified item and inserts it at a considered rank | Define |
| `/design` | Answers a design question and records the decision — no artifact | Design |
| `/prototype` | Builds something to look at — a flow diagram, a clickable mockup, or a real component | Design |
| `/develop` | Takes the top `ready` item, builds it TDD, and stops at `next: verify` | Build |
| `/verify` | Checks a change against the item's written acceptance criteria, then closes it or sends it back | Check |
| `/retro` | Sweeps the parked findings of many sessions and lands the lessons where they get read again | Learn |

`/design` and `/prototype` split the Design phase by output: **tell me** versus **show me**.
Default to `/design` — escalation is cheap, a prototype you didn't need is not. `/design` never
invokes `/prototype`; it names what a prototype would have to settle and leaves the call to you.

**No skill invokes another.** `/develop` stops at `next: verify` and names the command; `/verify`
closes; `/retro` runs on its own cadence over what many sessions parked. Building an item, checking
it, and learning from it are three jobs, and the last two are the ones that get cut short when one
session owns all three — so the handoff travels on disk, through the ticket's `next` field and
`FINDINGS.md`, rather than in a conversation that is about to end. `/retro` is the only skill here
that routinely edits *these skills*, since "the workflow misled me" is a finding like any other.

The executor here is the **agent**, and the artifact is code. Its sibling
[`ai-context-tools`](https://github.com/aaron-ferguson/ai-context-tools) is the other half —
there the executor is you, and the artifact is a decision or a record. `/queue` is for work an
agent will build; `/capture` over there is for your own tasks, meetings, and notes.

---

## One skill per session

**Run each skill in its own conversation.** The backlog is the handoff: a ticket moves
`queue → design → develop → verify` through its `next` field on disk, and anything a session
learned is parked in `FINDINGS.md`. Nothing travels in a conversation, so nothing is lost when one
ends.

**This is measured, not a preference.** An end-to-end run of the suite against a new project on
**2026-08-22** cost **$15.11** over 95 turns. **85% of that was context handling** — 59%
re-reading context, 26% loading it — and only 15% was output. The price of a turn doubled across
the run, $0.12 in `queue` to $0.25 in `retro`, for work of the same kind: nothing got harder, the
context got bigger, reaching an average of **191,752 tokens per turn**.

**Measured again, isolated, and the saving is real but partial.** 30 one-skill sessions over
**2026-08-23/24** closed 20 tickets at **$0.1028 per turn and 106,139 context tokens per turn**,
against a recomputed baseline of $0.1203 and 151,669: **context per turn fell 30%, cost per turn
14.5%**. The projection of a two-thirds cut assumed a 60k average context and did not survive
contact — isolation resets context per *session*, not per *turn*, and a cheap cache read at 0.1x
input is replaced by a fresh cache write at 1.25x to 2x. Full figures, method and caveats:
[MEASUREMENT.md](MEASUREMENT.md).

**One skill per session, not one ticket per session.** This is the counter-intuitive half and the
one most easily lost. A `queue` session should batch every related ticket it can: the expensive
part is understanding the domain once, and reading the source material is a shared cost paid once
however many tickets come out of it. Writing five related tickets in one capture session was
measurably cheaper per ticket than five sessions would have been. Isolation is per *skill*, not
per unit of work.

**The same holds for `develop` and `verify`, with more force.** A develop session pays for the
conventions, the project's `CLAUDE.md`, the concurrency protocol and its orientation in the code
before it writes a line, and every one of those is shared across tickets that touch the same
files. So the unit there is a **gate** — tickets whose `expects:` overlap or that share a parent
slice — and not a ticket. What does *not* batch is ownership or judgement: each row is claimed and
closed on its own, each ticket closes on its own acceptance criteria, and the batch stops at the
first ticket whose contract turns out wrong. The figure above is capture-side. No batched `develop`
or `verify` session exists to measure yet — `0026` looked and found none, and named the run that
would produce one.

**What does not change.** No standard is relaxed and no quality gate is removed — TDD, the separate NFR
pass, mutation testing in `verify`, the `design` gate, `qa_level` chosen at queue time. That
rigour is what caught a real zip-bomb vulnerability every acceptance criterion in the measured run
passed over, and a test that stayed green with the guard it existed for deleted. Both live in the
15% of spend that was output. What moved is *where* work happens, not what is required of it.

Full reasoning: *The Context Tax* and *Splitting the Suite* (2026-08-22/23). Observed figures and
the verdict: [MEASUREMENT.md](MEASUREMENT.md).

---

They're also designed to be run by **two sessions at once** — one developing, another queueing
feedback and verifying — without either destroying the other's work.

---

## Relationship to `ai-building-conventions`

These tools **own workflow**: how work is queued, ranked, claimed, verified, and closed.

They **own no principles about code or product**. Every claim about what good software looks
like — TDD, secrets handling, input validation, PII in logs, accessibility, migration safety —
lives in [`ai-building-conventions`](https://github.com/aaron-ferguson/ai-building-conventions)
and is cited, never restated. A restated rule is a rule that drifts.

The test for any line in this repo is not "is this a principle?" but:

> Would this still be true if the backlog didn't exist?

Yes → it belongs in the conventions and gets cited. No → it's workflow and lives here. That's
why the five-tier ranking model *is* in this repo (it's meaningless without a queue) while the
TDD cycle is *not* (it's true regardless).

**The dependency runs one way.** These tools require the conventions; the conventions know
nothing about these tools and need no changes to work with them. You can adopt the conventions
alone. You cannot usefully adopt these tools alone — with no standard to check against, `verify`
would issue verdicts that look identical whether or not anything was actually verified, and
that silent equivalence is worse than being blocked. So the skills stop and tell you how to
wire it up instead.

---

## Install

```
/plugin marketplace add aaron-ferguson/ai-building-tools
/plugin install ai-building-tools
```

Then wire each project to your conventions — either is enough:

**Option A — the project's `CLAUDE.md`** (this is the wiring the conventions repo already
prescribes, so most projects already have it):

```markdown
## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md
```

**Option B — `.claude/backlog/config.yml`**, once the backlog exists:

```yaml
conventions:
  path: ../ai-building-conventions
```

Then say *"queue this: <the thing>"* in any project. `/queue` scaffolds
`.claude/backlog/` on first use, reading your real test commands out of `package.json` (or
`Makefile`, `pyproject.toml`) rather than guessing.

---

## What lands in your project

```
.claude/backlog/
  config.yml     project settings, next_id, conventions path, test commands
  QUEUE.md       the stack rank — line order IS the rank
  DONE.md        completed items, newest first
  .lock/         transient, held for seconds during a claim or a close. Never commit it.
  items/
    0007-rate-limit-feedback-endpoint.md
```

Plain markdown, committed with the project. **`QUEUE.md` is readable and editable on its own** —
if the skills are unavailable, or you just want to reorder something by hand, nothing is locked
behind tooling. That's deliberate: the queue file is the product, and the skills are a wrapper
over it.

Add `.claude/backlog/.lock/` to `.gitignore`.

---

## Design notes

A few decisions that look odd until you know why:

- **No priority column, and no position number.** Line order is the rank. A priority field and
  a line position can disagree, and then nothing is unambiguous. A `#` column would need
  renumbering on every insert and close — turning each one-row change into a full-file rewrite,
  which is exactly how two concurrent sessions silently clobber each other.
- **Rank by pairwise comparison, never a score.** Five tiers, then ordered tie-breakers. False
  precision produces ties, and ties are the thing the queue exists to eliminate.
- **`qa_level` is set at queue time, not develop time.** This is what stops QA rigor quietly
  sliding session to session — the moment the level is chosen by whoever is doing the work, it
  drifts down to whatever is convenient today.
- **`verify` closes the item, not `develop`.** The stage holding the verdict is the stage that
  acts on it, so there is no window in which a green can go stale. What keeps two sessions off one
  ticket is the `next` field, not a read-only rule: every stage refuses a ticket addressed to
  another one.
- **Three operations take a lock** — claiming an ID, claiming an item, and closing one. Everything
  else is a single-line edit, which two sessions can do concurrently without coordination. A close
  needs the lock because the *commit* takes `QUEUE.md` whole even though the edit is one row.

Full protocol in [`references/CONCURRENCY.md`](references/CONCURRENCY.md), with each rule's incident
in [`CONCURRENCY-INCIDENTS.md`](references/CONCURRENCY-INCIDENTS.md); the conventions lookup in
[`references/CONVENTIONS.md`](references/CONVENTIONS.md). Two more are read only when
`config.yml` opts in: [`TRACKER.md`](references/TRACKER.md) for mirroring to an external tracker and
recording cost, [`EXTERNAL-FEEDBACK.md`](references/EXTERNAL-FEEDBACK.md) for sweeping feedback
other people reported. Which product holds those reports is a profile preference, so the suite
ships no default and prompts for none.

---

## Licence

MIT.

## Testing

Two things carry guards: the shipped scripts, and the prose files' own contract where a command can
measure it. Run every guard:

```bash
tests/claim.test.sh        # ./claim — locking, row parsing, refusals
tests/close.test.sh        # ./close — ticking ACs, DONE.md, reconciling dependents
tests/next.test.sh         # ./next — takeability, --waiting, --drift, --findings, --drive
tests/batching.test.sh     # develop and verify state the batching rule, not the old prohibition
tests/skill-size.test.sh   # every skills/*/SKILL.md within its byte goal, or over it with a reason
tests/reference-size.test.sh     # the same soft goal over references/*.md
tests/external-feedback.test.sh  # no shipped file names a specific feedback product
tests/measurement.test.sh        # the harvest arithmetic, and what MEASUREMENT.md must state
tests/reporting.test.sh          # every stage skill cites references/REPORTING.md, and that rule holds its shape
```

Each case scaffolds a throwaway git repo with one `QUEUE.md` shape, runs the script against it,
and asserts on the exit code, the message and the resulting files — then removes the fixture,
including on failure. Refusals are asserted on the *message* and on *files unchanged*, never on the
exit status alone: "exits non-zero" is satisfied by the silent refusal the guard exists to forbid. There
is no runner and no framework; a guard is a `sh` file that exits non-zero.

The three script suites — `tests/claim.test.sh`, `tests/close.test.sh` and `tests/next.test.sh` —
print one line per case and the tally, and nothing else. Set `SHOW_MATCHED=1` to make every
assertion also print the text it matched against:

```bash
SHOW_MATCHED=1 tests/next.test.sh   # every ok line followed by what that assertion saw
```

That is what a mutation sweep needs and a green run does not: when a case stays green against
deliberately broken code, this is what says what it matched *instead*. A **failing** case prints
the same line with the flag off — a failure with no evidence is the case bare output serves worst.
Turn it on for the one run and leave it off otherwise (`testing-conventions.md`).

A guard on the skills only asserts what a command can measure — a phrase present or absent, a byte
count. Everything else about a skill's behaviour is prose, and is checked by `/verify` against a
ticket's acceptance criteria instead.

## Editing this plugin

**Do not edit the installed copy under `~/.claude/plugins/cache/`.** A plugin is installed from
this repository at a pinned commit, so anything changed in the cache is silently reverted by the
next update — no error, no conflict. Edit here, commit, and **push**: the installer resolves the
plugin from the remote, so a local commit alone still loses the change.

The `SOURCE` file at the repo root ships with the plugin for exactly this reason. It lands in the
install cache and marks that copy as disposable, which is what lets tooling warn before the work
is lost rather than after.

**Pushing is not the last step — updating the install is.** A `/ai-building-tools:*` invocation
runs the version in the plugin cache, pinned at the commit it was installed from. Until you update
it, your pushed change is live for everyone except you, and the session you are testing in is
running the old skill while you read the new one. That failure is quiet by construction: nothing
errors, the skill just behaves like the version you stopped looking at.

So the loop is four steps, not two:

```bash
git push origin main                        # 1. the installer resolves from the remote
# 2. bump "version" in .claude-plugin/plugin.json
claude plugin update ai-building-tools      # 3. pull it into the cache
```

**Bump the patch digit.** A skill edit, a rule change, a new template script — patch. `0.5.0` went
minor for shipping `./claim`, and that was hasty: the version then advertises a scale of change the
plugin has not made, and a reader deciding whether to update cannot tell the releases apart. Reserve
minor for a change to how the skills are *used* — a new skill, a renamed stage, a backlog layout an
existing project has to migrate.

**And a fifth step you cannot skip: restart.** A running session resolves its skills once, at
start, from whatever was installed then — so `claude plugin update` changes nothing for the
session you are sitting in. This is measurable: a `/capture` invocation in the session that
wrote this was still executing the **0.6.1** copy while **0.8.2** was installed. Three
versions behind, no warning, in the session that had just done the release.

So the honest chain is: **push → bump → update → restart.** Skip the last one and you are
reading new docs while running old code, which is the same failure as the first three, one
layer further in.

Then **use the plugin copy** — same as everyone else, and the only way packaging mistakes surface
before someone else finds them.

To see whether the copy you are running matches the one you are editing:

```bash
diff -rq skills ~/.claude/plugins/cache/ai-building-tools/ai-building-tools/*/skills
```

Silence means they agree. Any output is work you have written and are not running.
