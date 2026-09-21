---
id: "0159"
title: Dispatch a ready design row instead of escalating it to a person
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0134", "0154", "0150", "0158"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-21
---

## Problem

**`./next --drive` treats `next: design, status: ready` as a person's decision (exit 4), so every
driven sprint halts at the first design row.** Design is autonomous work: `/design` settles the
question and writes the answer. Only `status: waiting` needs a person.

Parked from run-20260913T034946Z, verbatim:

> `next: design, status: ready` routes as "a person decides" (exit 4), but a person is needed only at
> `status: waiting`. Design is autonomous work; `--drive` should dispatch `design` on a ready row and
> escalate only `waiting`, and the depth line should not report a ready design row as where the run
> runs dry.

Where it happens in `skills/queue/templates/next`:

- the rank walk's `design)` arm: `ESCALATE  <id> is at next: design and outranks everything below
  it — a person decides`;
- the completed-stage block: `ESCALATE  <id> is at next: design after <stage> — a person decides`,
  and `--completed design:<id>` falls to *which no routing rule covers*;
- `depth_stopper`: `design|queue) printf '%s (next: %s — a person decides)'`.

`skills/sprint/SKILL.md` builds on the escalation in four places:

- Step 1's example: *"runs dry at 0080, which is `next: design` and needs a person"*.
- *Design alongside develop*: *"Exit 4 on an in-scope design row is a dispatch, not a halt"*, and
  *"A design finish is never reported through `--completed`"*.
- Step 8's `next: design` bullet.
- Step 9's `ESCALATED — next: /design 0080` example.

## Functional requirements

- FR1 — The rank walk's `design` arm, on a row that is `ready`, unheld and has no open blocker, runs
  `findings_gate` exactly as the `develop` arm does. It then prints `DISPATCH  design <id>` with the
  `DISPATCH` exit code, carries the item's design-question line, and sets `PROPOSE_STAGE=design`
  and `PROPOSE_IDS=<id>`. This lands in both copies of `next`.
- FR2 — The completed-stage block no longer escalates a row that is `next: design, status: ready`
  after any stage: it prints a `NOTE` and continues to the rank walk. `--completed design:<id>` whose
  row is now `next: develop, status: ready` also prints a `NOTE` and continues to the rank walk. A row
  still `next: design` after `--completed design:<id>` keeps today's same-stage escalation.
- FR3 — `depth_stopper` does not stop at a `ready` design row; `queue` rows and `waiting` rows keep
  their current stopper wording.
- FR4 — `status: waiting` at any stage still exits with the escalate code and prints its
  `## Waiting on` line. That is unchanged, and it becomes the only person-held state `--drive`
  reports.
- FR5 — `skills/sprint/SKILL.md` matches FR1–FR3:
  - Step 1's depth example names no ready design row as needing a person.
  - *Design alongside develop* reads a `DISPATCH  design` line rather than exit 4, and routes a
    design finish through `--completed design:<id>`.
  - Step 8's escalation bullet names only `waiting` rows, `next: queue` rows and design rows
    **outside the confirmed scope**.
  - Step 9's example no longer shows a design row as an escalation.
- FR6 — The existing guards that pin the old behaviour are rewritten to assert the new behaviour,
  not deleted: `tests/next.test.sh` case `0038 AC9`, the `depth_stopper` design-arm wording under
  `0038 AC28`/`AC29`, and 0154's FR3 case.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | Sprint's prose and `next`'s output agree: no sprint sentence describes a ready design row as an escalation | AC7's absence assertion | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a fixture `0101 design ready` with an `## Open design question`, when `next --drive`
  runs, then it exits 0 and prints `DISPATCH  design 0101`. Red: today's template exits 4 with
  `ESCALATE`.
- [x] AC2 — Given `0101 design waiting` with a `## Waiting on` section, when `next --drive` runs, then
  it exits 4 and prints the waiting question. Red: a design arm that dispatches regardless of status.
- [x] AC3 — Given `0101 design ready` held by a claim and `0102 develop ready`, when `next --drive`
  runs, then it prints `DISPATCH  develop 0102` and no `DISPATCH  design`. Red: the design arm
  dispatching a held row.
- [x] AC4 — Given `0101` now `next: design, status: ready` and `0102 develop ready` below it, when
  `next --drive --completed develop:0101` runs, then it exits 0, prints no `ESCALATE`, and prints
  `DISPATCH  design 0101`. Red: today's `after develop — a person decides` escalation.
- [x] AC5 — Given `0101` now `next: develop, status: ready`, when `next --drive --completed
  design:0101` runs, then it exits 0 and prints `DISPATCH  develop 0101`. Red: today's *no routing
  rule covers* escalation.
- [x] AC6 — Given `0101 develop ready`, `0102 design ready`, `0103 queue ready`, when `next --drive`
  runs, then the depth line contains `runs dry at 0103 (next: queue` and not `0102 (next: design`.
  Red: today's `depth_stopper` stops at 0102.
- [x] AC7 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then the file contains
  `DISPATCH  design` and contains neither `Exit 4 on an in-scope design row` nor `needs a person."*`.
  Red: the sections left as they are.
- [x] AC8 — Given `0101 design ready` and a `FINDINGS.md` holding at least `findings_threshold`
  entries, when `next --drive` runs, then it exits 5 and dispatches no design. Red: a design arm that
  skips `findings_gate`.

## QA plan

- **Why that level:** fixture-driven cases for a shell script plus prose guards; `commands.unit`
  runs both suites.
- **Specific checks:** AC1–AC6 and AC8 in `tests/next.test.sh`; AC7 in `tests/sprint.test.sh`;
  `tests/backlog-scripts-installed.test.sh` for the copy.

## Out of scope

- `next: queue` rows: re-specifying stays an escalation here.
- Whether a design session may run alongside develop, which 0134 already settled; unchanged.
- Rank contiguity of gates — 0158.
- `skills/design/SKILL.md`'s own `design waiting` hand-off, which already sets `status: waiting`
  when a person is needed.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**Verdict: PASS** — verify session 2026-09-20/21, token 6351.

Conventions: `../ai-building-conventions` (`config.yml` `conventions.path`; `CONVENTIONS_CORE.md`
plus `documentation-conventions.md`, `testing-conventions.md`).
Level `unit`, run as `config.yml`'s `commands.unit` in the reporting form that file prescribes:
`for t in tests/*.test.sh; do "$t" || true; done` — 31 files, every tally `0 failed`
(`tests/next.test.sh` 485 passed, `tests/sprint.test.sh` 257 passed).
Copy executed: the repo copy `skills/queue/templates/next`, which is also what the fixtures below
ran; `cmp` reports it identical to `.claude/backlog/next`.

| Criterion | How it was checked | Result |
|---|---|---|
| AC1 | Fresh fixture `0101 design ready` with an `## Open design question`; `./next --drive` → exit 0, `DISPATCH  design 0101` with the question carried beneath it | pass |
| AC2 | `0101 design waiting` with a `## Waiting on`; `--drive` → exit 4, `ESCALATE  0101 is waiting on a person`, the question printed | pass |
| AC3 | `0101` held (row and item both `in-progress`, item carrying a token) above `0102 develop ready`; `--drive` → `NOTE  0101 is in-progress — another session holds it; stepping over it`, then `DISPATCH  develop 0102`, no `DISPATCH  design` | pass |
| AC4 | `0101 design ready`, `0102 develop ready`, `--drive --completed develop:0101` → exit 0, `NOTE  0101 is at next: design after develop — design is autonomous work`, `DISPATCH  design 0101`, no `ESCALATE` | pass |
| AC5 | `0101 develop ready`, `--drive --completed design:0101` → exit 0, `NOTE  0101 is at next: develop after design`, `DISPATCH  develop 0101` | pass |
| AC6 | `0101 develop ready`, `0102 design ready`, `0103 queue ready` → depth line reads `runs dry at 0103 (next: queue — a person decides)`; `0102` is not named | pass |
| AC7 | Three guards in `tests/sprint.test.sh`; see the deviation below | pass, as substituted |
| AC8 | 8 findings against a threshold of 8 with `0101 design ready`: `--drive --scope 9999` (scope spent) → exit 5, `DISPATCH  retro, then queue`; `--drive --scope 0101` → exit 0 with `NOTE … deferred` and `DISPATCH  design 0101`. Both halves of FR1's *exactly as the develop arm does* | pass |
| NFR Documentation | No sprint line pairs `next: design` with `a person` (guard below); Step 1's depth example names a `next: queue` row. Checked against `documentation-conventions.md` | pass |

**AC7's second absence string could not be satisfied as written, and this pass confirms the
substitution rather than inheriting it.** The criterion asks that `skills/sprint/SKILL.md` contain
neither `Exit 4 on an in-scope design row` (absent — checked) nor `needs a person."*`. The second
string is still present, at line 107, inside *"runs dry at 0080, which is `next: queue` and needs
a person."* — a `next: queue` row, which genuinely does need a person and which FR5 explicitly
allows. The AC's literal text therefore reds a correct sentence. What is asserted instead is the
pairing the string stood for: no line contains both `next: design` and `a person`. FR5's four
bullets — the depth example, the *Design alongside develop* section, Step 8's escalation bullet,
Step 9's example — were each read and each hold. Recorded here because the substitution is a
narrowing of the written contract, not a finding about the code.

**Mutations run** (committed tree, mutated, red confirmed, restored by path, control green):

1. The rank walk's `design)` ready-arm replaced by the old escalation. AC1 → exit 4 `ESCALATE  0101
   is at next: design and outranks everything below it — a person decides`; AC4 → exit 4; AC8a →
   exit 4 rather than 5, the gate never reached. `tests/next.test.sh` 468 passed, 17 failed, the
   reds naming the design dispatch, the design question, the deferred gate and the `--propose` line.
2. The completed-stage `design after <stage>` NOTE arm disabled → AC4 printed `ESCALATE  0101 is at
   next: design / ready after develop — a person decides`, exit 4.
3. The `<stage> after design` NOTE arm disabled → AC5 stopped routing, exit 1.
4. `depth_stopper`'s `design|develop|verify) continue` split so `design` stops → AC6's depth line
   read `runs dry at 0102 (next: design — a person decides)`, today's behaviour.
5. The waiting check and the design arm's `rstatus = ready` test both disabled → AC2's waiting row
   printed `DISPATCH  design 0101`, which is FR4's failure exactly.
6. `DISPATCH  design` reworded in `skills/sprint/SKILL.md` → 256 passed, 1 failed. A line pairing
   `next: design` with `a person` added → 256 passed, 1 failed, the guard quoting the added line.
   Restored; control `tests/sprint.test.sh` 257 passed, 0 failed.

**Probes** (`🔍`):
- A design row whose QUEUE row reads `ready` over an `in-progress` item routes to `DRIFT` and exit 4
  ahead of any dispatch — the first AC3 fixture was built that way and measured the drift reporter
  instead of the design arm. The same trap 0158's build notes record for its AC3.
- The design dispatch carries the item's design-question line as a second, indented line; a design
  row with no `## Open design question` prints an empty continuation line rather than a complaint.
  Noted, not a red: nothing in FR1 or the ACs asks for a refusal there.

Dirty set at Step 2 and at verdict: `.claude/backlog/runs/` (untracked). Intersection with this
run's evidence set (`skills/queue/templates/next`, `skills/sprint/SKILL.md`, `tests/next.test.sh`,
`tests/sprint.test.sh`) is empty — not advisory.

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`: the user stated the rule ("design tickets are not human-dependent; only status: waiting
  needs a person"), so no decision is open.
- **Supersedes 0154 FR3.** 0154 made `--propose` on a design row name the develop gate *below* it,
  because the run was going to stop there. Once the row is dispatched, the proposal names the design
  dispatch itself. 0154 is re-verified against its own contract first, since it ranks above this
  ticket, so this ticket rewrites that guard rather than re-specifying 0154.
- **`findings_gate` on the design arm (FR1/AC8)** because a design dispatch is new work exactly as a
  develop gate is, and the gate exists to stop new work once the buffer crosses.

- **2026-09-20 (develop, 1150) — this ticket exposed a defect in `0168`, which landed hours earlier
  in the same session, and the fix is in this commit.** `scope_live` asks whether any confirmed-scope
  id is still dispatchable, and 0168 FR2 enumerated `next: develop` and `next: verify` — correct when
  it was written, because a design row escalated and so was never dispatchable. Once this ticket made
  design dispatchable, a scope ticket sitting at `next: design` read as *finished scope* and fired the
  findings tail in the middle of the run: exactly the failure 0168 exists to prevent, arriving through
  the stage this one opened. `scope_live` now accepts `design|develop|verify`. **0168's own FR2 text
  still names two stages and is now a stale enumeration** — this session holds 0159, not 0168, so it
  is reported rather than edited (`CONCURRENCY.md`, *A stage writes only the ticket it holds*).
- **AC8's exit code was pinned to pre-0168 behaviour.** The AC asks for exit 5 on a crossed buffer,
  and since 0168 a crossed gate DEFERS at a dispatch site while confirmed scope is live. FR1's actual
  requirement — the design arm runs `findings_gate` *exactly as the develop arm does* — is what was
  built, and the case asserts both halves: exit 5 with the scope spent (`--scope 9999`), and a
  deferred exit 0 with the design row itself in scope.
- **AC7's second absence string could not be written as specified.** It asked that the file not
  contain `needs a person."*`, which was written against the depth example while that example named a
  `next: design` row. The example now names a `next: queue` row, which genuinely does need a person —
  so the check as stated reds a correct sentence, the negative-assertion trap `testing-conventions.md`
  names. Substituted: no line pairs `next: design` with `a person`, which is the claim the string was
  standing in for. **The next QA pass reads the plan, not this note** — hence it is recorded here.
- **Nine `next.test.sh` cases and four `sprint.test.sh` guards used a design row purely as a
  convenient *this escalates* fixture**, their real subjects being elsewhere (stepping over an
  in-progress row, `--propose` adding nothing to a non-dispatch, the finish-before-start preference,
  exit-code compatibility). Each was swapped to a `next: queue` row, which states the same premise and
  leaves each subject untouched. Only the four cases whose subject *is* the design routing were
  rewritten as reversals.
- **The `--completed design:<id>` reversal is narrower than it looks.** A row still at `next: design`
  after a completed design falls past the new NOTE arms to the pre-existing same-stage escalation,
  because both new arms require `lstage != design`. That is a design session that changed nothing —
  a loop — and keeping it loud is what stops the router re-dispatching design forever. Case added
  under `0159 FR2`.
- **All prose guards here are RUN, not reasoned**: the four rewritten 0134 guards each failed before
  the prose was changed to match, which is the mutation in reverse and evidence of the same kind.
