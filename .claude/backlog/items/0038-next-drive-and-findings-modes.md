---
id: "0038"
title: Add the drive and findings routing modes to next
type: feature
next: develop
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent: "0036"
relates: ["0006"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
  - .claude/backlog/config.yml
  - skills/queue/templates/config.yml
  - skills/retro/SKILL.md   # FR3 only: point the cadence at the config key, no second number
  - README.md               # not predicted: line 208's test inventory names next's modes
claimed_by:
claimed_at:
touches:
---

## Problem

Project 0036 needs one thing before a supervisor can exist: **code that answers "what should
happen next" from the backlog alone**. Nothing answers it today.

`./next <stage>` answers a different question — *which row is takeable at this stage* — and it
spends exit code `0` on both "here is a row" and "nothing is takeable", which a human reading the
line gets away with and a driver cannot. There is no mode that reads a transition a stage has
just written and says what should follow it, and no mode that counts the findings buffer.

**The count is not merely absent; the obvious substitute is wrong.** `FINDINGS.md` carries two
entry formats — `- <date> — **lead.**` and `- **<date> — lead.**` — and a finding parked on
2026-08-24 records that every count taken off the obvious `^- 2026-` grep is low. The evidence is
published: `MEASUREMENT.md` states **26** and **28** in adjacent sentences against a
format-tolerant **42**. A gate reading a reliably-low number fires late, silently, and there is
nothing to notice it with.

**This slice ships standing on its own and is testable with no supervisor existing** — which is
why 0036's review amendment named it as the slice to rank. It is where every decision that can be
wrong the same way twice actually lives; the supervisor built on it (0039) is instructions.

## Functional requirements

**FR numbers are 0036's, kept rather than renumbered** so the design decision and the review
amendment in the parent still resolve. FR3 and FR17 split across slices, and each says which half
lives here.

- **FR3 (counting half) — the threshold has a home and the count is code.** The gate's threshold
  lives in `config.yml` as a key, defaulted to `retro`'s stated cadence and overridable per
  project; `retro`'s SKILL.md gets a pointer to the key rather than a second number. The count
  itself is **`./next --findings`**, format-tolerant across both entry shapes, and the format is
  pinned by a guard in the same change. **The driver gates on the count only** — `retro`'s cadence
  reads "eight entries or more, *or weekly* if the buffer fills slower", and the time half has no
  fixture and no reading, so it stays what it is today: a human's judgement.
  *(0039 owns the gating behaviour — stopping dispatch, and evaluating the gate once per run.)*

- **FR8 — every transition the three stages can write is routed, and the default is to stop.** The
  table below is the whole space, derived from the stage skills rather than from the happy path,
  and it is the specification `./next --drive` implements. Anything not in it stops rather than
  proceeding.

  | From → to | Written by | Decision |
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
  | **nothing takeable at `develop`** | — | **run complete** — a success, not an escalation |
  | foreign red tree · push required · anything unrecognised | — | **escalate** |

  **Which `status:` is authoritative, because there are two vocabularies and nothing pinned one.**
  `./next` reads Status from the `QUEUE.md` column (`ready|waiting|blocked|in-progress`) and
  `size`/`qa_level`/`expects` from item frontmatter — where the vocabulary is *different*:
  `active` appears on projects, which have `next:` blank and no row at all, and `done` appears on
  closed tickets. **The column is the authority for routing** and `--drive` reads it there; item
  frontmatter is the authority for everything else. Fixtures and any prose describing this must
  both say so, or they get written against different vocabularies.

  **The same-stage-twice guard needs an intervening outcome.** A supervisor killed after dispatch
  but before the stage claimed leaves the row `ready`; a stateless re-derivation re-dispatches it;
  a naive guard then sees the same ticket at the same stage twice and escalates the recovery. So
  the guard is **same ticket, same stage, with a completed outcome in between** — a fact only
  0039's run log holds, which means `--drive` takes it as an *input* rather than deriving it.
  Absent that input, `--drive` dispatches.

- **FR9 — the code that decides is named and tested, and the exit codes are a contract.**
  `./next --drive` is a **new mode on the existing reader, not a fourth script**: `next` already
  owns takeability, the `blocked_by` graph and the exit-code convention, and 0006, 0022 and 0031
  are three separate tickets fixing that parsing in one place — a second copy is how the two
  answers diverge without either being wrong.

  `next` already spends `0` (success, *including* "nothing is takeable"), `1` (drift, malformed)
  and `2` (usage error). `--drive` needs four outcomes a caller can tell apart, so **"nothing to
  dispatch" cannot share `0` with "dispatch this"** — exactly the collision `./next <stage>` gets
  away with because a human reads the line:

  | Code | Meaning | stdout |
  |---|---|---|
  | `0` | dispatch this | the decision |
  | `3` | run complete, nothing takeable | why it is dry |
  | `4` | escalate | the reason |
  | `5` | findings gate reached, dispatch `retro` | the count and the threshold |
  | `1` | drift, malformed | unchanged |
  | `2` | usage error | unchanged |

  Every existing caller and test keeps its meaning.

- **FR17 (data half) — `--drive` reports how deep the backlog is.** One read answers both "what
  now" and "how many takeable gates deep is this, and where does it run dry" — because the read
  happens anyway and 0039's pre-flight report has to come from somewhere. *(0039 owns reporting
  it before the first dispatch.)*

- **FR18 — the new modes resolve columns by header name, never by index.** Added at slicing time
  and not in 0036; see *Notes & decisions*. `0006` exists because `next`'s current fixed-index
  parsing silently reports wrong values when a column moves, and it is `blocked` behind 0007. A
  new mode written against fixed indices adds a second reader for 0006 to rewrite and a second
  chance to be silently wrong in the interim. The new modes read the header row by name; `0006`
  still owns converting the pre-existing modes.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Compatibility | `--drive` adds exit codes to a script `claim`, `close` and three closed tickets already depend on. Every pre-existing invocation returns exactly what it returned, and the plugin is public at 0.9.3 and installed on backlogs that will not migrate on our schedule | `api-conventions.md` |
| Documentation | `./next --help` lists both new modes, and the threshold key ships in `skills/queue/templates/config.yml` with a comment naming what reads it. A key with no documented reader is a key the next project deletes | `documentation-conventions.md` |

## Acceptance criteria

**AC numbers are 0036's**, with two additions numbered on from its highest (AC27).

- [ ] **AC6 (counting half) — the count is right and the format is pinned.** Given a fixture
  holding both entry formats — `- <date> — **lead.**` and `- **<date> — lead.**` — when
  `./next --findings` counts it, then the count includes both; and given a third shape, then the
  format guard fails.
- [ ] **AC9 — every row of FR8's table is routed as the table says, with one fixture each.** Given
  a backlog in each FR8 state in turn — verify bounce, `next: design`, `next: queue`, stale
  contract, foreign red tree, `waiting` top row, genuinely `blocked` top row, **advisory PASS**,
  **develop→`design`**, **develop→`develop` on a red tree**, **develop→`waiting`**,
  **develop→new `blocked_by`**, **a row that left `QUEUE.md` because its ticket became a
  project**, **nothing takeable at `develop`**, and **the same ticket reaching the same stage
  twice with a completed outcome supplied** — when `./next --drive` is run against that fixture,
  then it prints the decision FR8's table names and exits with that outcome's code. Specifically:
  in the advisory-PASS case it does **not** print `verify <id>` again; in the nothing-takeable
  case it exits **run-complete and not escalate**; in the became-a-project case it neither errors
  nor loops; and in the same-stage-twice case, **given the same backlog with no completed outcome
  supplied**, it dispatches rather than escalating.
- [ ] **AC10 — anything unrecognised stops rather than proceeding.** Given a backlog state
  matching no routing rule, when `./next --drive` is run, then it escalates rather than falling
  through to a default action.
- [ ] **AC11 — the codes are the named ones, and both modes are tested.** Given the fixtures
  above, when `tests/next.test.sh` runs, then it exercises `./next --drive` for each routing
  outcome and each escalation, asserting the printed decision **and** the exit code against FR9's
  table — with `0` (dispatch) and `3` (run complete) asserted as **distinct**. Every pre-existing
  `next` exit code still means what it meant, and `./next --help` lists `--drive` and `--findings`.
- [ ] **AC28 — the new modes survive a column move.** Given a `QUEUE.md` whose table columns are
  reordered and carry one extra column the script does not know, when `--drive` runs against it,
  then it returns the same decision it returns against the current shape; and given a table with
  no `Status` column, then it fails loudly rather than reading every row as empty.
- [ ] **AC29 — one read answers depth as well as the decision.** Given a backlog with two
  takeable develop gates followed by a `next: design` row, when `./next --drive` is run once,
  then its output states how many takeable gates deep the backlog is and what stops it — without
  a second invocation.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`).
- **Why this level:** every requirement here takes a backlog fixture as input and produces one
  decision plus an exit code. That is exactly the shape `next.test.sh` and `close.test.sh` already
  drive, and it is the whole reason this slice was separated from the supervisor: prose cannot be
  red, and a routing rule that is wrong is wrong the same way every run.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), and specifically —
  - **A fixture per row of FR8's table**, fifteen of them, each asserting the printed decision and
    the exit code (AC9, AC11). The four develop-side unhappy endings and the two loop hazards —
    advisory PASS, and same-stage-twice — have no precedent in the existing tests, so they are the
    ones to write first.
  - **A `--findings` fixture holding both entry formats**, plus a format guard that fails on a
    third (AC6). This is the count 0039's whole gate rests on and today it is a grep that
    under-reports.
  - **Exit-code regression**: every pre-existing `next` invocation still returns what it returned
    (AC11), since `--drive` adds codes to a script three closed tickets already depend on.
  - **A reordered-column and a missing-`Status` fixture** (AC28).
  - **A depth fixture** asserting the depth line comes from the same invocation (AC29).

## Out of scope

- **The supervisor.** Nothing here dispatches anything, launches a process, or reads a stage's
  outcome. `--drive` prints a decision; 0039 acts on it.
- **The gating *behaviour*** — stopping dispatch at the threshold, and evaluating the gate once
  per run. This slice supplies the count; 0039 owns what is done with it.
- **The lock policy and the budget-kill recovery.** 0040.
- **Converting `next`'s pre-existing modes to header-name parsing.** FR18 covers the new modes
  only; `0006` owns the rest and is ranked to do it.
- **Making `retro` a lifecycle stage or a `next` value.** It stays a cadence job; this slice only
  moves its threshold into a key.
- **Reading the time half of `retro`'s cadence.** "Or weekly" has no fixture and stays a human's
  judgement (FR3).

## Notes & decisions

### Built 2026-08-25 — what the implementation turned up

- **FR18 is bigger than the index variables, and this is the part `0006` will miss.** Converting a
  mode to header-name parsing looks like replacing `ID=2; TITLE=3; NEXT=4; STATUS=5` with four
  `column_named` calls. It is not: `rows()` recognised the header and separator lines by testing
  whether **cell 2** held `ID`, so under a reordered table it emitted the *header row itself as a
  data row* — every mode then routes on a row whose Next cell reads `Next`. `row_for`, `all_ids` and
  `ids_where` had the same literal `$2`. All four now take the resolved column. `0006` inherits a
  working example; what it must not inherit is the assumption that the indices were the whole job.

- **The advisory-PASS assertion holds with the guard deleted, and that is not a reason to relax it.**
  `assert_rc 4` + `assert_not_contains DISPATCH` passes against a `--drive` with the
  `lnext = lstage` branch removed, because the phase-A ladder's final `else` escalates anyway. So
  those two assertions do not pin the guard — the **pair** does: the same backlog must escalate with
  `--completed` supplied and dispatch without it. The mutation that proves it is the *naive*
  implementation (dispatch whenever `lnext = verify`, which is what a driver routing on `next:`
  alone would do), and against that the case reds on five assertions. This is the conventions'
  "a guard that is wired and still cannot fail", arriving from the direction where the code is
  right and the test is merely not evidence. Anyone adding a row to FR8's table will reach for the
  same assertion shape; assert the pair, and mutate to the plausible wrong implementation rather
  than to the absent one.

- **Phase A's ladder order is load-bearing and deliberately not alphabetical.** `waiting`, `design`
  and `queue` are tested *before* the same-stage guard, and an acquired `blocked_by` before it too.
  Reorder them and `develop` writing `waiting` on a row still at `next: develop` gets reported as
  "same ticket, same stage" — technically true, and it throws away the `## Waiting on` question that
  is the only thing a person needs. Same for a row that gained a blocker: that one is not stuck at
  all, it is re-derivable, and escalating it stops a run that could have continued.

- **Two routing decisions no AC pins, recorded so they read as chosen rather than accidental.**
  (a) The findings gate is evaluated where a **new develop gate** would be dispatched, never before
  a `verify` — a ticket already built is finished rather than abandoned mid-flight for a retro.
  (b) The rank walk **halts** on the first row a person must act on rather than stepping over it the
  way `./next develop` does. That is the behaviour the design pass already described — "the first run
  halts on the first `next: design` row and reads as broken" — and AC29's depth line is what makes it
  read as finished instead. Both belong to 0039 to *act* on; this slice only decides where they sit.

- **A gate is one hop from its lead, not a transitive closure.** Grouping by "shares a parent or
  overlaps `expects:`" chains: two unrelated efforts that both touch one common file would merge
  into a single gate, and through it a third, until a gate is most of the backlog. One hop from the
  lead row keeps the unit the one `develop` describes.

- **The mechanism this implements was settled by `/design` on 2026-08-24 and corrected by Aaron's
  review the same day. Both live in `items/0036-orchestrate-the-stage-sessions.md`,
  *Notes & decisions*, and are not restated here** — a copy drifts the first time either is
  edited, and `verify` would then check the stale one.
- **FR18 and AC28 are additions made at slicing time, not in 0036.** The reason is the file-scope
  fact slicing surfaced: this slice's `expects:` and `0006`'s overlap on `.claude/backlog/next`,
  `skills/queue/templates/next` and `tests/next.test.sh`. `RANKING.md`'s existing argument for
  doing 0007 before 0006 — *"the reader is written once against the final column set"* — applies
  here in reverse, and the cheap resolution is a requirement rather than a `blocked_by`: writing
  the new modes header-name-first means 0006 has nothing extra to rewrite, and this slice does not
  sink behind a two-hop blocked chain. Re-checked per `queue`'s amend rule: `size` stays `m`
  (header-name resolution is a few lines and `claim` already does it, so there is a working
  implementation in the same directory to follow), the QA plan gains the AC28 fixtures, and
  *Out of scope* gains the line saying 0006 still owns the pre-existing modes.
- **AC29 is the other addition**, carrying 0036's FR17 data half so the depth report has a source.
  It costs nothing: the read happens anyway.
- **`relates: 0006`, deliberately not `blocked_by`.** FR18 is what makes that safe. If 0006 lands
  first, this slice inherits the header-name helper and FR18 is free; if this lands first, 0006
  finds one fewer index-based reader. Either order works, which is the test for `relates` rather
  than `blocked_by`.

### QA 2026-08-25 — FAIL: one of AC9's fifteen fixtures is absent, and the branch it would pin is free to break

The suite is green (134 assertions in `next.test.sh`, 378 across `tests/*.test.sh`) and every other
AC holds under mutation. One gap, found by the Step 3 mutation pass rather than by reading:

- **The rank-walk `waiting` branch has no fixture.** AC9 names `waiting` top row and
  `develop→waiting` as two of its fifteen, and they are two different code paths — `--drive` with
  `--completed` reaches the phase-A branch (`next` line ~599), `--drive` with no completed outcome
  reaches the rank-walk branch (~643). Only the phase-A one is tested (`next.test.sh:571`, which
  supplies `--completed develop:0101`).

  The mutation:

  ```
  -    if [ "$rstatus" = "waiting" ]; then
  +    if false; then
  ```

  **`134 passed, 0 failed`.** Against a fixture with a `waiting` top row and a takeable row below it,
  that mutation turns

  ```
  ESCALATE  0101 is waiting on a person and outranks everything below it
            Aaron — which host holds the credential?      rc=4
  ```

  into `DISPATCH  develop 0101`, rc=0 — a driver dispatching a stage onto a row whose whole state
  means a person has been asked a question. This is the ticket's own "a check that cannot be made to
  fail leaves its AC unverified", so AC9 and AC11 (*each routing outcome and each escalation*) are
  both unmet.

  **The code is right; only the evidence is missing.** Both paths carry `## Waiting on` correctly —
  verified by hand against a fixture. The fix is one fixture in the AC9 block: a `waiting` top row,
  a takeable row beneath it, `--drive` with **no** `--completed`, asserting rc 4, `ESCALATE`, the
  waiting question, and `assert_not_contains DISPATCH`. Assert the last one: without it the case
  still passes with the branch deleted, because the rank walk would dispatch and `ESCALATE` would
  simply be absent rather than wrong.

- **Also resolve AC9's `foreign red tree`, which no fixture can express.** It is listed among the
  fifteen, but a red tree is git state and `--drive` reads none — *Out of scope* is explicit that
  nothing here launches a process or reads a stage's outcome. FR8's table groups it with
  `push required · anything unrecognised`, and only that third clause is implementable here (AC10,
  tested, red under mutation). Either add nothing and **amend AC9 to hand the first two clauses to
  0039**, or say why they belong here. Left as-is, the next QA pass rediscovers the same ambiguity.

**Not defects, recorded so the next pass does not re-derive them.** Three branches are also
mutation-silent but preserve behaviour when removed, because a later `else` escalates anyway with a
less specific message: phase-A `queue` (~608), phase-A `in-progress` (~603), and the verify-bounce
branch (~613). Only the bounce is an FR8 row of its own, and `next.test.sh:491` does pin its outcome
(rc 4 + `ESCALATE`) — just not its reason. Worth an `assert_contains` on the bounce wording next time
that block is open; not worth a red on its own.

**Copies:** `tests/next.test.sh` executes `skills/queue/templates/next`, and
`.claude/backlog/next` is byte-for-byte identical to it — checked, so this repo's own backlog runs
what was tested. The installed plugin at `0.9.3` still carries the pre-0038 script; releasing it is
not this ticket's contract.
