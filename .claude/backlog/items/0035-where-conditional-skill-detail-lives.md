---
id: "0035"
title: Decide where conditionally-needed skill detail lives
type: debt
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - tests/skill-size.test.sh
  - tests/reference-size.test.sh
claimed_by: "5bec"
claimed_at: 2026-08-25T06:11:29Z
touches:
---

## Problem

Two skills are over the size goal, both recorded, and both for the same reason: they carry detail
that only *some* runs need.

**`prototype`** — Step 5 is 11,690 of its 23,394 bytes: level 1 (Mermaid), level 2 (clickable HTML)
and level 3 (Angular), plus the field-reference contract. Step 2 has already picked one level before
any of it is read, so a level-1 run — the cheapest and probably commonest ask — loads the drawer
rules and the Angular route registration for nothing.

**`develop`** — over the goal, carrying several worked anecdotes (the three-implementations story,
the contrast-ratio ticket, the batching measurement) alongside the rules they illustrate.

Aaron's direction, 2026-08-23: *"We should build in a way that heavily leverages pointers so that
extra context can be held in other files and pulled in as needed, and not always pulled into
context."* The soft goal in `tests/skill-size.test.sh` names relocation as the first move, and
`references/TRACKER.md` is the existing precedent for a conditionally-read file.

**The design question was settled on 2026-08-24 (see *Notes & decisions*): neither file relocates,
because neither passes the payback test — and the payback test is what this ticket now ships.** The
direction stands; what was missing was the arithmetic that says where it applies. `CONCURRENCY.md` →
`CONCURRENCY-INCIDENTS.md` passes it, which is why that split was right and these two are not.

## Functional requirements

- **FR1 — state the payback test once, in `tests/skill-size.test.sh`.** A block of `B` bytes carried
  in context for an `N`-turn session costs one cache write plus `N-1` cache reads; following a
  pointer instead costs one extra turn. With this repo's measured figures — 4.038 bytes/token,
  $6.25/MTok cache write, $0.50/MTok cache read, $0.1028 per turn, ~30 turns per session
  (`MEASUREMENT.md`) — one skipped read only pays for one fetch at **B ≈ 20,000 bytes**, and the
  break-even share of runs that never follow the pointer is **p = 1 / (1 + B/20,000)**. Record the
  constant's derivation, not just its value, so it can be recomputed when turns or rates move.
- **FR2 — state the two non-cost conditions alongside it.** Relocate only when (a) the estimated
  share of runs that skip the branch clears `p`, **and** (b) the content is not *mandatory* once its
  branch is taken. A mandatory step behind a pointer is a step that gets skipped, and no byte count
  outranks that.
- **FR3 — `tests/reference-size.test.sh` cites the test rather than restating it.** Its `RELOCATE`
  block keeps its own prose about the worked instance; the conditions and the arithmetic are named by
  path. Two guards stating one rule is two rules that drift.
- **FR4 — both guards require a recorded justification to name what was considered for relocation
  and why it was rejected.** `reference-size.test.sh` already says this in its header; the skill
  guard's over-goal message and header must say it too, in the same words.
- **FR5 — rewrite the three entries in `skill-size.test.sh`'s `justification()`** so each names what
  was considered and why it was rejected, per FR4:
  - `prototype` — Step 5's mass is not three equal procedures: level 1 is 969 bytes, level 2 is
    5,859, level 3 is 1,427, and the field reference 3,416. Relocating level 2+3+field reference
    (10,702 bytes) needs p ≥ 0.65, the level split is unmeasured, and every byte of it is mandatory
    once its branch is taken. Rejected on (a) and (b).
  - `develop` — its anecdotes are already one-clause statements of *the failure each rule prevents*,
    which is the half the `CONCURRENCY.md` split deliberately kept in the rules file. At their size
    p would have to clear 0.9, and they are read on 100% of runs. Rejected on cost and on FR2(b).
  - `queue` — specification rules read by every other stage: p = 0. Rejected on (a).
- **FR6 — no justification line carries a byte count.** The guard prints the live number; a number in
  the reason is stale the next time the file is edited (this ticket's own Problem statement carried
  one that had already drifted by 219 bytes).
- **FR7 — no skill file is modified.** The decision is that nothing moves; a diff under `skills/` is
  this ticket exceeding its own answer.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The *test* an author applies goes somewhere durable — otherwise every future over-goal file re-litigates this. It goes in the guard that fires, not a decision record: no `docs/decisions/` tree exists here, and `0028` set the precedent by putting the same class of reasoning in `reference-size.test.sh`'s header | `documentation-conventions.md` |
| Documentation | The change must not leave a contradicting sentence standing — `skill-size.test.sh`'s header currently says relocation is unconditionally "the first move", which this ticket qualifies | `documentation-conventions.md` |

## Acceptance criteria

- **AC1** — Given `tests/skill-size.test.sh`, when its header is read, then it states the payback
  test: the `p = 1 / (1 + B/20,000)` break-even, the derivation of the 20,000 constant from the
  bytes/token ratio, the cache-write and cache-read rates, the per-turn cost and the turns-per-session
  figure, and a citation of `MEASUREMENT.md` as their source.
- **AC2** — Given the same header, when the "first move is a POINTER" sentence is read, then it is
  qualified by the two non-cost conditions of FR2 rather than stated unconditionally.
- **AC3** — Given `tests/reference-size.test.sh`, when its `RELOCATE` block is read, then it names
  `tests/skill-size.test.sh` as where the test lives and does not restate the conditions or the
  arithmetic.
- **AC4** — Given each of the three entries in `skill-size.test.sh`'s `justification()`, when read,
  then each names what was considered for relocation and why it was rejected, and none contains a
  digit sequence that is a byte count of the file it describes.
- **AC5** — Given the skill guard's over-goal message (the `elif` branch of `offenders`), when a file
  is over the goal with no entry, then the printed line asks for a justification **naming what was
  considered relocating** — matching the wording `reference-size.test.sh` already uses.
- **AC6** — Given `tests/skill-size.test.sh` is run, then it exits 0 and its AC1 `ok` line still names
  all three recorded files, so no entry has gone stale.
- **AC7** — Given `tests/reference-size.test.sh` is run, then it exits 0.
- **AC8** — Given `git diff --name-only` for this ticket's commits, then no path under `skills/`
  appears.

## QA plan

- **Level:** verify — file content and byte counts, with the two existing size guards doing the
  measuring.
- **Why this level:** every AC is a read of a committed file or an exit code from a guard that already
  exists. Nothing here needs a running system, and nothing needs a human to look at it.
- **Specific checks:** run `tests/skill-size.test.sh` and `tests/reference-size.test.sh` (AC6, AC7);
  read both headers against AC1–AC3, AC5; read the three `justification()` entries against AC4;
  `git diff --name-only` across this ticket's commits for AC8.
- **The red for AC5 and AC6:** a guard that has only ever been seen passing is indistinguishable from
  one wired to nothing. Both files already carry fixture cases that prove they can fail; confirm those
  cases still run and still fail on the breach they name, rather than trusting the summary line.

## Out of scope

- Changing the goal itself, or either guard's semantics. That landed 2026-08-23; `0028` did the same
  for the reference files.
- Cutting any rule. "No rule is dropped" outranks the goal.
- **Measuring the level-1/2/3 split of `prototype` runs.** The decision is deliberately robust to it —
  even at 100% level-1 the saving is ~$0.055 on a ~$3 session, inside the noise of a measurement that
  could not reproduce its own baseline to within 22%. If someone wants to overturn the decision, that
  measurement is what they need, and it is a new ticket.
- **The attention cost of a long file**, as distinct from its token cost. Unmeasured, and this ticket
  accepts it — see *Notes & decisions*.

## Notes & decisions

- Recorded from two findings on 2026-08-23 — one about `prototype` Step 5, one arising when
  `develop` crossed the goal and had to record a reason. They are merged into one ticket
  deliberately: answered separately, two sessions would very likely give the same question two
  different answers, and the inconsistency would be worse than either answer.
- The precedents to compare against: `references/TRACKER.md` (conditionally read, opt-in feature)
  and `references/CONCURRENCY-INCIDENTS.md` (conditionally read, "open it when you hit this").
  Both are read on a *condition that usually does not hold*, which is exactly sub-question 1's test.

### 2026-08-24 — `/design`: the answer is a test, and under it nothing moves

**Decision: neither `prototype` Step 5 nor `develop`'s anecdotes relocate. What ships is the test
that says so, written into the guard that fires.** The three sub-questions, answered:

**1. When does a pointer actually save anything?** Not at file size — at *expected* cost across the
run distribution, and the arithmetic is unkind. A block of `B` bytes sits in context for one cache
write plus `N-1` cache reads; fetching it instead costs one extra turn. At this repo's measured
figures (`MEASUREMENT.md`: 4.038 bytes/token, $6.25/MTok write, $0.50/MTok read, $0.1028/turn,
~30 turns/session) the break-even block size is **~20,000 bytes** — almost exactly the whole goal.
So relocation never pays on size alone; it pays on the *share* of runs that skip the branch:
`p = 1 / (1 + B/20,000)`. The test retro-predicts the one split this repo already made:
`CONCURRENCY-INCIDENTS.md` is 11,990 bytes (p break-even 0.63) read by well under a third of
sessions — comfortably worth it. Prototype's level 2+3+field-reference is 10,702 bytes and needs
p ≥ 0.65 with the distribution unmeasured; `develop`'s anecdotes are ~1,500 bytes and would need
p ≥ 0.93 against an actual p of 0.

**2. Is an anecdote the same kind of thing as a procedure?** No, and the distinction is already
resolved in this repo rather than open. `CONCURRENCY.md`'s own header states the split: the rules
file keeps every rule **and the failure it prevents**; the incidents file takes the narrative, the
reasoning and the live procedure. `develop`'s "anecdotes" are already on the near side of that line —
"one ticket's ACs were all contrast ratios, so a complete implementation was built, tested and
committed before the author rejected the new look in one line" is one clause, and it *is* the failure.
Moving it leaves a rule with no stated failure, which is the one thing the CONCURRENCY split was
careful not to do. **Rejected: nothing to move.** The compression rule, stated for reuse: keep rule +
failure in one clause; move the story.

**3. What does a skill lose by branching to a file?** Reliability on the branch that takes it. A
skill is read start-to-finish by a session already committed to a stage; a reference is read on a
decision. Every byte of `prototype` Step 5's level content is *mandatory once its level is picked* —
the template copy, the drawer rule, the three data states, the Angular route registration. That makes
it the exact content the pointer mechanism is worst at, whatever the token arithmetic says. This is
condition (b), and it outranks (a): a byte count never buys a skipped step.

**4. Does the field-reference contract belong with the levels or above them?** With them. It is not
shared across all three — its own heading says *levels 2 and 3 only*, and a level-1 run never writes
one. So it is a fourth branch, not a preamble, and there is nothing above the levels for it to move
to. It stays where it is.

**Where the measured facts corrected the framing.** Step 5 is not "three build procedures" of
comparable weight: level 1 is 969 bytes, level 2 is 5,859, level 3 is 1,427, the field reference
3,416. The mass is one branch, not three, which is why "each level becomes `references/PROTOTYPE-L<n>.md`"
was never the shape of the answer. `develop` had also grown to 21,532 bytes against the 21,313 this
ticket recorded — which is FR6: a byte count in prose is stale the moment anything edits the file.

**What this rejected.**
- *"Each level becomes a reference file."* Fails condition (b) outright and condition (a) on an
  unmeasured distribution — and would have created three new files each governed by the same goal in
  `reference-size.test.sh`, so the bytes are guarded either way. Relocation is not an escape from the
  goal, only a change of which guard holds it.
- *"Compress `develop`'s anecdotes in place."* There is nothing left to compress: they are already at
  the one-clause form the `CONCURRENCY.md` split preserves on purpose. Compressing further deletes the
  failure, and a rule with no failure named is a rule the next session argues with.
- *A decision record under `docs/decisions/`.* No such tree exists here, and `0028` set the precedent
  by putting this class of reasoning into `reference-size.test.sh`'s header. An ADR that no guard
  points at is read never; the guard that goes red is what the author actually opens.
- *Asking Aaron first.* The question turned entirely on fact — measured rates, byte counts, prior art
  in this repo — which is the case `/design` says to decide rather than ask. His 2026-08-23 direction
  is not overturned by this: it is a direction about *mechanism*, and the test is what says where the
  mechanism applies. The one split this repo has made passes the test.

**The trade-off accepted, and what would flip this.** This optimises measured token cost and
step-reliability, and accepts that both files stay long enough that every session reading them carries
detail it will not use. The *attention* cost of that — a long file diluting what a session actually
follows — is real and unmeasured, and it is the honest reason someone could overturn this. Two facts
would do it: a measured level-split for `prototype` showing level-1 runs above 65%, or evidence that
step compliance falls with file length. Neither exists today, and the second would beat the first.
