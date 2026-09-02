# 001 — One command per stage boundary

**Date:** 2026-09-02 · **Ticket:** `0085` · **Status:** accepted, revised the same day

**Revision.** Everything below was first written against a share of *turns*. It has since been
verified against a share of *tokens* — `MEASUREMENT.md`, *What a turn of each category costs*,
produced by `tools/cost-by-category.sh`. The decision survived; two of its claims did not and are
corrected in place.

## Context

`0073` classified all 1,112 turns of the pinned 30-session run by their tool calls
(`MEASUREMENT.md`, *Where a session's turns go*). **34.3% of every turn in the suite is the backlog
protocol** — 12.8 turns of a develop session's 38.6, 14.9 of a verify session's 38.4 — against three
durable acts a session performs: claim, hand off, close. `verify` spends 49.5% of its turns on
`mechanism`.

The obvious reductions are measured and wrong. Narration is 3.8% of turns; every word this project
controls is 10.2% of a session's end-of-session context, so halving all of it buys about 5%. The
lever is the number of turns the protocol takes.

**The turn share was verified in tokens before this record was accepted.** The protocol is 34.3%
of turns and **32.8% of dollars**; a protocol turn costs **$0.0983 against a work turn's $0.1132**,
87% of one. The intuition that a one-line command is a cheap turn is an intuition about *output*: in
a cached agentic loop the dominant per-turn cost is re-reading the conversation so far, and that is
category-blind — context per turn is 102,831 for protocol against 109,008 for work, 5.7% apart.
**The denominator was not wrong.**

**One published claim did not survive, and it is not this one.** *"41.9% mechanism is more than the
34.0% spent on work"* holds only while git sits inside `mechanism`; two defensible rule changes put
mechanism below work. That comparison should not be leaned on. The protocol share itself is robust
at **31.5%–34.3% under every attack tried**, which is the figure this decision rests on.

The risk in taking it is specific: **the protocol's rules exist because each of the steps failed
once** (`references/CONCURRENCY-INCIDENTS.md`). A batching that swallows a read-back removes the
check that made a claim durable. So the decision is not "fewer turns" but **which turns exist
because a session must see a result, and which exist only because nobody scripted them together.**

### The fact that decides it

`tools/classify-turns.sh` resolves a mechanism turn's part by **first match wins**, with
`backlog script` ahead of `lock` and `queue file`. `./claim` and `./close` take the lock internally
and never name it. Therefore:

- **Every turn counted as `lock` is a by-hand lock** — a session hand-rolling `mkdir`/`rm -rf` for a
  write site that has no script. 20.0% of mechanism turns; **0.0% in `retro`, the one stage that
  writes no backlog file.**
- **Every turn counted as `queue file` is a session opening `QUEUE.md` with no script in the same
  turn** — a read by eye or a hand `Edit`, against a rule that already says to read it with `./next`.
  19.3% of mechanism turns.

The scripts are not the cost. Per develop session: 4.3 script turns, **3.25 by-hand lock, 2.67
`QUEUE.md`, 2.58 sibling files**. Two-thirds of the protocol's 12.8 turns are work no script covers.

## Decision

**A stage boundary is one command, and a session never sees the lock.**

### The minimum turn count per boundary, and the rule each retained turn serves

| Boundary | Minimum | Turn | The rule it exists for |
|---|---|---|---|
| **Claim** | **2** | `./next <stage>` | *The working tree is shared too* — the session must compare the candidate's `expects:` against every in-progress `touches:` **before** claiming. That comparison is the session's judgement, not the script's; a fused select-and-claim would claim a row nobody saw collide. |
| | | `./claim <id> --touches <paths>` | *A claim must be durable the moment it is made* · *Lock every write to `QUEUE.md`* — lock, re-read, row, frontmatter, commit, unlock. Nothing inside it needs seeing mid-way. |
| **Hand off** | **1** | author *Notes & decisions* into the item, then `./handoff <id> <token> <stage>`, in one shell invocation | *A claim must be durable…* (commit inside the lock) and `0081` FR4 — **the release is the final act**. The notes are content only this session holds, and they are a write to the same file the hand-off commits, so they are not a second turn. |
| **Close** | **1** | `./close <id> <token>` | *`verify` owns closing* — the verdict travels no further than the session that produced it — and the dependent reconcile, which must land in the closing commit because `blocked` is derived. |

Four boundary turns per session, plus one `FINDINGS.md` append. **That is exactly the four-turn
protocol budget `MEASUREMENT.md` sets**, and no smaller decomposition reaches it.

### What is not fused, and why

- **Select and claim stay two turns.** `./next --drive` already collapses the judgement to an exit
  code — for an orchestrator (`0036`), which is a different consumer. The interactive path keeps the
  look.
- **`--touches` must never default to `expects:`.** `queue` writes `expects:` (predicted, from the
  code); `develop` writes `touches:` (actual, checked, **never copied**). A flag that copied one to
  the other would delete the reason there are two fields.
- **The `FINDINGS.md` append stays a turn.** It is content nothing else can author. Fold it into the
  boundary commit where the shell invocation allows; do not fold it into a script.

### FR3 — the lock

**A session must never see the lock as its own turn.** There is no rule in `CONCURRENCY.md` that
requires a session to observe it; the lock is an implementation detail of an atomic write. Two
apparent exceptions, and neither survives:

- **A busy lock** must be seen — as the script's stderr (`backlog is locked by: …`), not as a turn.
  The close-time retry `0047` specifies belongs **inside** the script.
- **A write site with no script** falls back to the by-hand one-tool-call form in
  `CONCURRENCY-INCIDENTS.md`. That fallback's use is the defect, not the fix.

Falsifiable form: **the `lock` line of the mechanism composition goes to 0.0%.** `retro` already
reads 0.0%, which is what makes the target reachable rather than aspirational.

### FR4 — the `QUEUE.md` reads

The rule is **all three at once**, and the split matters because each has a different fix.

- **Paid twice** — the largest share, and it is `./next`'s. The script answers *which row* and then
  **warns** about things it does not show: uncommitted rows, drift, held files. A warning that cannot
  be acted on without a second read buys a turn back for every turn it saves. This session
  reproduced it: `./next` warned about an uncommitted row, and the session then read the diff and 80
  lines of `QUEUE.md` by eye. → **`0066`**, which already owns the same class of defect (FR4: bare
  `./next` printing the takeable row alongside row 1).
- **Insufficient** — for `queue`. "Read it with `./next`" has no answer for *where to insert a row at
  rank*, which is `queue`'s whole job and is a **write**. `RANKING.md` is written at the same site
  under the same lock. → **`0048`**.
- **Unfollowed** — reading the queue whole to learn one row, which `develop` Step 1 already names as
  the largest avoidable read. It is the residue and the smallest, and it is prose against prose. **No
  separate action:** it disappears when the two above land.

### FR6 — git

**Leave it alone**, with one named exception. 15.7% of mechanism turns are git inspection any project
pays; it is outside the 34.3% figure, and `CONCURRENCY.md` *The git index is shared* requires a
session to inspect its tree **more**, not less — cutting it would weaken a protection. `git write` is
already at the floor at 2.6%, because `claim` and `close` commit internally.

The exception is **`verify`'s advisory dirty-path intersection** (Step 7), which is this protocol's
own git rather than the project's, and which puts `verify`'s git inspection at 20.5% of its mechanism
turns against a 15.7% mean. It is removable and it is owned by `0085` itself.

### Every removable turn, and who removes it

| Protocol turn | Turns/session | Verdict | Owner |
|---|---|---|---|
| `./next <stage>` | 1 | Retained | — |
| `./claim <id>` | 1 | Retained | — |
| `touches:` hand edit + commit after `./claim` | ~1–2 (develop) | Removable → `./claim --touches` | **0066** |
| Hand-off: five field edits, two files, by-hand lock, commit | ~3–4 | Removable → `./handoff` | **0081** |
| `./close <id> <token>` | 1 | Retained | — |
| A busy lock surfacing as a session turn | occasional | Removable → retry inside the script | **0047** |
| `queue`'s row insert + `RANKING.md` write, by hand under a by-hand lock | ~2–3 (queue) | Removable → script or a mandatory one-call form | **0048** |
| `QUEUE.md` re-read to act on a `./next` warning | ~1–2 | Removable → `./next` warnings self-sufficient | **0066** |
| `FINDINGS.md` append | 1 | Retained | — |
| `verify`'s advisory dirty-path intersection | ~1–2 (verify) | Removable | **0085** |
| `DONE.md` / `config.yml` reads | **0.37** | **Not overhead, and smaller than this record first claimed.** Measured at **11 turns of 1,112**, not the "1–2 per session" written here before the attack; 22 more touch those files in a *write*, which is protocol | — |

**`0048` is narrowed by this record.** Its open question asked which of *two* by-hand write sites
becomes a script. `0081` has since settled the hand-off half as a fourth script with its own incident
behind it, so `0048` reduces to `queue`'s row insert and the `RANKING.md` write beside it — and to
the disagreement it correctly identifies between `skills/queue/SKILL.md` Step 3 and
`CONCURRENCY.md`'s "every write, no exemptions".

### FR5 — the prediction, made before the change

**In turns.**

| Stage | Protocol turns now | Predicted | Turns/session now | Predicted | Budget |
|---|---|---|---|---|---|
| develop | 12.8 | 4 | 38.6 | **29.8** | 30 |
| verify | 14.9 | 4 | 38.4 | **27.5** | 28 |
| queue | 11.8 | 4 | 36.2 | **28.4** | 28 |
| design | 11.0 | 4 | 27.0 | **20.0** | 20 |
| retro | 3.0 | 2 | 23.0 | **22.0** | 22 |

**In dollars**, derived with no extra assumption as the stage's measured protocol share of session
cost times the fraction of its protocol turns removed:

| Stage | Protocol share of $ | Protocol turns removed | Predicted saving | $/session now → predicted |
|---|---|---|---|---|
| develop | 29.9% | 8.8 of 12.8 (69%) | **20.6%** | 4.03 → **3.20** |
| verify | 40.8% | 10.9 of 14.9 (73%) | **29.9%** | 3.63 → **2.54** |
| queue | 30.8% | 7.8 of 11.8 (66%) | **20.4%** | 4.24 → **3.38** |
| design | 39.4% | 8.0 of 12.0 (67%) | **26.3%** | 2.32 → **1.71** |
| retro | 14.6% | 1.5 of 3.5 (43%) | 6.3% | 2.51 → **2.35** |

**Per ticket — the figure that matters, since a ticket is one develop plus one verify: $7.66 →
$5.74, a saving of $1.92 or 25.1%.** Across the 30-session pinned suite the same reduction is
$114.27 → about $88, or **$26 saved on a run of that size**.

**In tokens**, for a develop session: 8.8 requests no longer made, each carrying ~102,831 context
tokens — about **0.9M fewer cache-read tokens per develop session**, and ~16,000 fewer tokens
appended to the conversation.

**The prediction uses the low end of the honest range.** A removed turn is worth $0.0983 (its own
request) to $0.1166 (with the cache reads every later turn no longer pays for what it appended); a
*fusion* keeps most of what the two turns appended, so the low end is the one to be judged against.

Three composition lines, each of which can come back wrong on its own:

- `lock` → **0.0%** of mechanism turns
- `backlog script` → **≤ 3 turns per session**
- `queue file` → **< 1 turn per session**

Re-measured with both committed scripts against sessions run after the change, with the pinned set
in `MEASUREMENT.md`, *Re-running this*, as the baseline.

### How to tell "the turns were removed" from "the tokens were saved"

**These are different outcomes and only one of them is worth having.** Turns removed from the
protocol can reappear elsewhere: a session with spare turns spends them. Three figures, read
together on **2026-10-31**, separate the cases — and **the verdict is recorded whichever way it
comes out**, as `0009`'s was.

| | Protocol turns/session | **Non-protocol turns/session** | **$/session** | Reading |
|---|---|---|---|---|
| The saving is real | ↓ to ~4 | flat | **↓ ~20–30%** | land it |
| **The turns were replaced** | ↓ to ~4 | **↑ by what protocol lost** | **flat** | the protocol was never the binding constraint |
| The change did not land | flat | flat | flat | the scripts are not being used |
| Better than predicted | ↓ to ~4 | flat | ↓ >30% | compounding is real; record it |

**The single distinguishing figure is `$/session`, and the diagnostic beside it is non-protocol
turns per session.** A turn count that falls while dollars stay flat is the failure mode this table
exists to name, and it is invisible if only turns are published — which is exactly how this record
was nearly accepted on turns alone.

## Consequences

**Easier.** Every stage boundary becomes one auditable command, so the protocol's rules live in code
that cannot forget them rather than in prose a session under load skips. `./next --drift` should read
zero more often, because the two sites that have half-applied in the field (`0081`, `0048`) stop being
hand edits.

**Harder.** Four scripts to keep in step with the templates (`tests/backlog-scripts-installed.test.sh`
AC2), and `./claim` grows a flag whose misuse — defaulting `--touches` to `expects:` — would silently
undo the distinction between predicted and actual file scope. That is the one place this decision can
weaken a rule, and it is why the flag takes paths the session names.

**What this rules out, with a number.** A **more linear workflow** — fusing `develop` and `verify`
into one session to save the second startup — was priced and is **+12%, not a saving**: carrying
develop's 74,970-token climb through verify's 38.4 turns costs $1.44, against $0.36 saved on the
floor's cache write and ~$0.40 of re-orientation. The floor is cached and therefore cheap to pay
twice; the climb is re-read on every subsequent turn and therefore expensive to carry. The
correctness argument for a separate `verify` — it checks what the ACs say rather than what it
remembers building — stands independently and does not trade against 12% either way.

**And what it does not aim at, also with a number.** All the prose this project controls is 13,724
tokens of a 58,060-token floor, which at $0.50 per million per turn carried costs about **$0.34 of a
$3.81 session, 8.9%** — so halving every word buys ~4.5%. Splitting skills or references into
smaller load-on-demand files is not token work, and `0035` already priced relocation from the other
side. If such a change is made it is made for clarity and ranked as clarity.

**What would trigger revisiting.** The 2026-10-31 re-measurement showing turns per session down and
**dollars per session flat** — the second row of the table above, which would mean the turns went
somewhere else and the protocol was never the binding constraint.
