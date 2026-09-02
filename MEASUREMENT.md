# Measurement — what one skill per session actually cost

**Recorded 2026-08-24, ticket 0026.** Project `0009` opened with a measurement and committed to
closing with one. This is that measurement, and it is **observed against observed**: both runs are
recomputed from their own transcripts by `tools/harvest-usage.sh`, at the same rates, by the same
arithmetic. Re-run it with that script rather than trusting the numbers below.

## How the figures here are pinned

Every figure below is read from a source still being written — the transcript store, `DONE.md`,
`FINDINGS.md`. So each carries an **as-at stamp**, and **both sides of a division carry one**: a
pinned numerator over a live denominator decays exactly like an unpinned figure, silently, while
the arithmetic on the page stays self-consistent and every citation still resolves. That is the
defect this record shipped and `0051` repaired — *Cost per closed ticket* divided a pinned $114.27
by a count re-read from a growing `DONE.md`.

**A date window is not a pin on a live store.** The window that selected these 30 sessions now
returns 42 of them and $170.17. What pins them is the session-id set, which *Re-running this*
carries in full. Give any figure added here the same two things: the source it was read from, and
the stamp it was true at.

## Verdict

**The saving partly materialised, and it is roughly a fifth of what was modelled.**

`0009` justified itself with a modelled figure: the 2026-08-22 run cost **$15.11**, and modelled at a
60k average context the same run would cost **~$5.09** — a 66% cut. Observed:

| Measure, per turn | Baseline 2026-08-22 | Isolated 2026-08-23/24 | Change |
|---|---|---|---|
| Cost | $0.1203 | $0.1028 | **-14.5%** |
| Context tokens | 151,669 | 106,139 | **-30.0%** |
| Share of spend that is output | 19.0% | 22.5% | +3.5pp |

Context per turn fell by nearly a third, which is the mechanism working. Cost per turn fell by half
that, and nothing like the modelled 66%. **The model's premise did not hold:** it assumed a 60k
average context, and the observed average is 106,139 — 1.8x that. Isolation resets context per
*session*, not per *turn*, and a develop session still averages 39 turns, so context still climbs
inside each one. It starts each climb from a much lower floor, and that is the whole of the gain.

**Why cost fell less than context did.** A cache read costs 0.1x the input rate; a cache write costs
1.25x to 2x. Isolation trades cheap re-reads for fresh writes, and each new session re-pays a load
the one long conversation paid once. Per turn, cache reads fell 30.8% — 149,391 to 103,342 — while
cache **writes rose 22.8%**, 2,276 to 2,795. That is the tax on splitting, and it is the reason a 30%
context cut buys a 15% cost cut rather than a 30% one.

**Total spend is not the comparison and is not offered as one.** The isolated run cost $114.27 across
30 sessions because it closed 20 tickets; the baseline session cost $11.79 for one conversation. Per
turn and per closed ticket are the figures that compare.

## The isolated run — 30 sessions, 2026-08-23 and 2026-08-24

This repository's own transcripts, every session that ran a suite skill on those two days. The
session that produced this measurement, and one session still in flight beside it, are excluded:
their cost is not yet complete. 1,112 turns, **$114.27**, $0.1028 per turn, 106,139 context tokens
per turn.

| Skill | Sessions | Turns | Cost | Cost per turn | Context per turn | Output share |
|---|---|---|---|---|---|---|
| develop | 12 | 463 | $48.32 | $0.1044 | 109,750 | 22.1% |
| verify | 10 | 384 | $36.32 | $0.0946 | 97,965 | 21.6% |
| queue | 5 | 181 | $21.20 | $0.1171 | 123,120 | 24.5% |
| retro | 2 | 46 | $5.01 | $0.1090 | 99,482 | 25.2% |
| design | 1 | 27 | $2.32 | $0.0859 | 77,701 | 25.1% |
| unmarked | 2 | 11 | $1.09 | $0.0992 | 57,637 | 14.2% |
| **all** | **30** | **1,112** | **$114.27** | **$0.1028** | **106,139** | **22.5%** |

`queue` is the most expensive turn in the suite and `design` the cheapest, which inverts the
baseline's shape — there, `queue` was the cheap end at $0.12 and `retro` the dear end at $0.25.
Ranked by context per turn the order is the same: queue, develop, retro, verify, design.

### Cost per closed ticket

**The denominator is as live as the numerator, and this is where it was not pinned.** `DONE.md`
records **20 tickets** closed on 2026-08-23 and 2026-08-24 — that date bound is what produces the
count — every one at `qa_level: verify`, **as at 2026-08-30**.

Whole run, $114.27 over 20 is **$5.71 per closed ticket**. Counting only the two gates that close
tickets, develop and verify, $84.64 over 20 is **$4.23 per closed ticket**. This is the figure
`0036`'s Performance NFR measures against; the baseline has no comparable denominator, because it
ran against a different project and `DONE.md` records no ticket closed before 2026-08-23.

Published until 2026-08-30 as 19 tickets, $6.01 and $4.45. One further ticket was closed on
2026-08-24 after this record was written, and the quotient decayed on its own: the numerator was
pinned, the denominator was re-read, and nothing on the page looked wrong. Tickets quoting the old
pair — `0036`, `0040`, `0041` — hold a stale cache of this figure, not a second reading of it.

## Where a session's turns go

**Recorded 2026-09-02, ticket 0073.** The same 30 sessions as the tables above, the same pinned id
set, classified turn by turn by `tools/classify-turns.sh` rather than by a session reading them.
`0009` already paid for guessing once — it modelled a 66% saving from a wrong premise and observed
14.5% — so the categories below are decided by committed code against tool calls on disk.

**The finding, in one line: 41.9% of every turn in the suite is the backlog protocol and the git
bookkeeping around it, which is more than the 34.0% spent on the work itself.**

### What was classified, and how

Five categories, fixed in the script and named in its output:

| Category | What lands in it |
|---|---|
| `mechanism` | The backlog protocol and the git bookkeeping around it: the `claim`, `close` and `next` scripts, the lock, `QUEUE.md`, `DONE.md`, `FINDINGS.md`, `RANKING.md`, `config.yml`, and every `git` call |
| `orientation` | Reading to find out what to do: the skill file, the conventions, a template, the ticket, this repo's own docs |
| `work` | Changing the thing under change, and running a test |
| `narration` | A turn that called no tool at all |
| `other` | Matched no rule. Reported rather than folded into a neighbour, because it is the honest size of what the rules do not cover |

A turn's tool calls can span categories. **The precedence is `work`, `mechanism`, `orientation`,
`other`** — a turn that edited the change is work whatever else it also read — and the share of
turns that needed the rule is published as `MIXED` so its influence is visible rather than assumed.

| Stage | Sessions | Turns | Turns per session | mechanism | orientation | work | narration | other | mixed |
|---|---|---|---|---|---|---|---|---|---|
| develop | 12 | 463 | 38.6 | 38.4% | 17.3% | 37.6% | 2.4% | 4.3% | 6.3% |
| verify | 10 | 384 | 38.4 | **49.5%** | 11.2% | 33.1% | 4.2% | 2.1% | 10.2% |
| queue | 5 | 181 | 36.2 | 39.2% | 16.0% | 30.9% | 5.0% | 8.8% | 6.6% |
| retro | 2 | 46 | 23.0 | 30.4% | 30.4% | 23.9% | 6.5% | 8.7% | 8.7% |
| design | 1 | 27 | 27.0 | 44.4% | 33.3% | 14.8% | 3.7% | 3.7% | 0.0% |
| unmarked | 2 | 11 | 5.5 | 9.1% | 0.0% | 54.5% | 18.2% | 18.2% | 0.0% |
| **all** | **30** | **1,112** | **37.1** | **41.9%** | **15.7%** | **34.0%** | **3.8%** | **4.6%** | **7.6%** |

**`narration` is 3.8%, and that kills the obvious theory.** "The sessions talk too much" was the
first explanation anyone reached for, including this record's own ticket. Measured, a turn that
calls no tool is one turn in twenty-six. Cutting what a session *says* cannot move a turn count that
is 92% tool calls.

### What the mechanism turns were running

`mechanism` being the largest category does not yet aim anything: the backlog protocol and the git
bookkeeping around it are two different fixes. Shares are of the mechanism turns, not of all turns.

| Stage | Mechanism turns | backlog script | lock | queue file | other backlog | git write | git inspect |
|---|---|---|---|---|---|---|---|
| develop | 178 | 29.2% | 21.9% | 18.0% | 17.4% | 2.2% | 11.2% |
| verify | 190 | 22.6% | 20.0% | 19.5% | 16.3% | 1.1% | 20.5% |
| queue | 71 | 9.9% | 18.3% | 25.4% | 29.6% | 4.2% | 12.7% |
| retro | 14 | 7.1% | 0.0% | 0.0% | 42.9% | 21.4% | 28.6% |
| design | 12 | 8.3% | 25.0% | 25.0% | 41.7% | 0.0% | 0.0% |
| **all** | **466** | **22.3%** | **20.0%** | **19.3%** | **20.2%** | **2.6%** | **15.7%** |

**81.8% of the mechanism turns are the backlog protocol itself** — the scripts, the lock, `QUEUE.md`
and its sibling files — and 18.3% is git. So the protocol alone is **34.3% of every turn in the
suite**, about 12.8 turns of a develop session's 38.6, against 3 durable acts a session performs:
claim, hand off, close.

### What the context is made of

Two different quantities, and a reduction aimed at one does nothing to the other. A session pays a
**floor** before it does anything — the harness's system prompt and tool definitions, the skill file
it is running, the conventions its `CLAUDE.md` imports — and then **climbs** from there.

| Stage | Sessions | Floor tokens | End tokens | Climb tokens | Floor share of end |
|---|---|---|---|---|---|
| develop | 12 | 59,200 | 134,170 | 74,970 | 44.1% |
| verify | 10 | 57,281 | 128,766 | 71,485 | 44.5% |
| queue | 3 | 60,830 | 131,537 | 70,707 | 46.2% |
| retro | 2 | 57,357 | 175,230 | 117,873 | 32.7% |
| design | 1 | 55,409 | 99,091 | 43,682 | 55.9% |
| **all** | **30** | **58,060** | **130,807** | **72,747** | **44.4%** |

This table attributes a session by the stage in force at its **first** turn, because a floor is paid
once at session start. That is a different denominator from the turn tables above, which attribute
each turn to the stage in force at that turn — which is why `queue` shows 3 sessions here and 5
there, and `retro` 2 and 2.

**The climb's own composition is an estimate, and is published as one.** The transcripts carry usage
totals per turn, not a breakdown of what those tokens were. The estimator: a turn's context is
`input + cache_read + cache_creation`, so the rise from one turn to the next is what the
conversation appended in between; the previous turn's `output_tokens` is charged against that rise
as the share attributable to the session's **own prior turns**, and only rises are counted, since a
fall means the context was pruned or the session resumed and cannot be attributed.

| Stage | Growth tokens | Own output tokens | Estimated own share | Everything else |
|---|---|---|---|---|
| develop | 899,640 | 410,837 | 45.7% | 54.3% |
| verify | 714,847 | 301,576 | 42.2% | 57.8% |
| queue | 415,124 | 213,262 | 51.4% | 48.6% |
| retro | 96,479 | 38,693 | 40.1% | 59.9% |
| design | 43,682 | 21,218 | 48.6% | 51.4% |
| **all** | **2,182,427** | **990,678** | **45.4%** | **54.6%** |

Put together, an average end-of-session context of 130,807 tokens divides roughly **44% floor, 25%
the session's own prior turns, 30% everything it read or was handed mid-session**. Own output
includes thinking and the arguments of every tool call, so it is not a measure of prose.

**How much of that floor is this project's own prose.** A develop session loads `develop/SKILL.md`
at 6,693 tokens, `CONCURRENCY.md` at 2,337, this repo's `CLAUDE.md` at 629 and
`CONVENTIONS_CORE.md` at 4,065 — 13,724 tokens, at the 4.038 bytes per token this record uses. That
is **23.2% of the 59,200-token floor and 10.2% of the end-of-session context**, as at 2026-09-02.
The rest of the floor is the harness. So halving every word this project controls buys about 5% of a
session's context, and it is the smaller lever by roughly a factor of five.

### The turn budget

**A number and a date, per stage, set 2026-09-02 and due 2026-10-31.** Each is derived from the
composition above rather than wished for: take the stage's measured backlog-protocol turns, leave
four of them, and keep everything else as it is.

| Stage | Turns per session now | Budget by 2026-10-31 | Where the cut comes from |
|---|---|---|---|
| develop | 38.6 | **30** | 12.8 protocol turns to 4 |
| verify | 38.4 | **28** | 14.9 protocol turns to 4 |
| queue | 36.2 | **28** | 11.8 protocol turns to 4 |
| design | 27.0 | **20** | 11.0 protocol turns to 4 |
| retro | 23.0 | **22** | 3.0 protocol turns to 2 |

Re-read with the command below on 2026-10-31 against the sessions run by then. **If the figure has
not moved, the verdict is recorded as not moved** — this record's own history is that a modelled
saving came in at a fifth of the model, and the number is the only thing that settles it.

### Where the reduction aims

**The largest category is `mechanism` at 41.9% of turns, and 81.8% of it is the backlog protocol.
The reduction ticket opened against that is `0085`.** Not the skill files: `orientation` is 15.7% of
turns and this project's whole prose is 10.2% of a session's context.

Three tickets already in the backlog are pieces of the same target and are named in `0085` rather
than duplicated by it: `0081` scripts the hand-off, `0048` decides which remaining write sites
become scripts, and `0047` gives the busy lock a close-time path. What `0085` adds is the figure
they are aiming at and a single command per stage boundary.

### Re-running this

The store is live. What pins this classification is the same session-id set as the tables above, so
the command carries it in full:

```sh
tools/classify-turns.sh <transcript-store> --since 2026-08-23 --until 2026-08-24 \
  --exclude 1860b4f4 --exclude 5c2b0c27 --exclude 26acbad7 --exclude 3ab24685 \
  --exclude 05e441cd --exclude b5862898 --exclude fe292418 --exclude 52cc41c8 \
  --exclude 35873f41 --exclude 873196d2 --exclude ba215ccf --exclude 1a2da19b
```

Verified 2026-09-02: 30 sessions, 1,112 turns, and every cell of the four tables above.

### What this measurement cannot see

- **A turn is classified by its tool calls, not by its intent.** A read is orientation whatever the
  reader meant by it, and 7.6% of turns needed the precedence rule to pick one category of two.
- **Paths cannot tell the work from the reading of it.** A session editing `MEASUREMENT.md` as its
  deliverable is scored the same as one consulting it, and 4.6% of turns matched no rule at all.
- **`mechanism` includes git.** 15.7% of the mechanism turns are `git` inspection that any project
  pays, not a cost of this backlog. The 34.3% figure excludes it; the 41.9% does not.
- **These 30 sessions are this repository's own**, editing the files each of its sessions loads,
  which the *not held constant* section below already records for the cost figures.

## The baseline — 2026-08-22, and how it was matched

The published figures are $15.11 over 95 turns at an average 191,752 context tokens per turn, 85% of
spend on context handling. The candidate is session `2ce6bc83` in the parent workspace's transcript
store, which spans 2026-08-22 and 2026-08-23. **It is matched on turn count and on shape, not on
dollars:**

- Its 2026-08-22 portion is **98 turns** against the published 95 — the only session on that day
  within reach of the figure, and the whole session is 158 turns, so the day boundary is what
  isolates it.
- Recomputed, the output share of spend is **19.0%** against the published 15%, so 81% went on
  context handling against the published 85%. The same shape, a little flatter.
- Recomputed cost and context are **not** reproducible from the transcript: $11.79 against $15.11,
  and 151,669 context tokens per turn against 191,752. Both land at about 78% of the published
  figure. No variant tried reproduced them — per-line rather than per-turn summation, pricing every
  cache write at the 1-hour rate, or folding in the other Opus session of that day.

**So the comparison in the verdict is recomputed-against-recomputed**, which is like for like: one
script, one rate card, one definition of a turn on both sides. The published $15.11 and 191,752 are
retained above as *published*, not recomputed, and the 66% modelled saving is judged against the
recomputed baseline as well.

## The cost model

Both sides are `claude-opus-5`, priced at the same list rates per million tokens. Source: the
`claude-api` skill's model table and its `shared/prompt-caching.md`, read 2026-08-24.

| Component | Rate per million | How it is derived |
|---|---|---|
| Input | $5.00 | list |
| Output | $25.00 | list |
| Cache read | $0.50 | 0.1x input |
| Cache write, 5-minute TTL | $6.25 | 1.25x input |
| Cache write, 1-hour TTL | $10.00 | 2.0x input |

Context tokens per turn is `input + cache_read + cache_creation`; the transcripts carry no field for
it. A **turn is a distinct `message.id`** — a single API response is written to the transcript as
several lines, one per content block, each repeating the same complete `usage` object, so summing
lines overcounts by about 2.2x. Where a cache write is not split into 5-minute and 1-hour buckets it
is priced at the cheaper 5-minute rate.

Every dollar figure here is recomputable from the token counts with that table.

## Effectiveness, alongside cost

`0009`'s standing commitment was that effectiveness must not be traded for cost, so this is read
from the record the run left rather than from memory.

**What the run caught.** 20 tickets closed, all at `qa_level: verify`, and the gate bit at least
once for real: `0021` was sent back with AC1 unmet on four of six files rather than closed. **42
findings were parked** across the two days — 4 dated 2026-08-23 and 38 dated 2026-08-24, counted as
at 2026-08-24 06:00Z — against the baseline run's 4, of which two existed only in conversation and
would have been lost. That is the durable-handoff half of the project doing exactly what it was for.
This measurement itself caught a defect no acceptance criterion would have: naive per-line summation
of the transcripts overstates cost by 2.2x, and the figure would have been published wrong.

**What it missed.** Its own row: `0026` was read as `blocked` and skipped, leaving four rows
unavailable for a session, and the stale row survived three separate closes before `0024` fixed the
derivation. `FINDINGS.md` held all 42 at that same stamp, which the file's own header called
the finding. **As at 2026-08-30 it holds 29 entries, only 2 of them from those two days** — later
retros did sweep it, so that was a snapshot of the buffer and not a standing verdict on the cadence.

**Two cautions on that count, because it read 26 in one sentence and 28 in the next until
2026-08-24.** It is a *live* buffer: sessions that postdate this record keep appending, so the
figure is as-at rather than final, and it is pinned here the same way the token figures are. And it
must be counted format-tolerantly — two entries carry the date inside the bold marker rather than
before it, so the obvious `^- 2026-` grep silently undercounts by exactly those two. Both earlier
numbers came from that grep.

**The honest caveat on all of it.** The baseline run caught a zip-bomb vulnerability every acceptance
criterion passed over, and a test left green with the guard it existed for deleted. The isolated run
caught no equivalent, and that is **not** evidence either way: this repository is markdown skills and
shell guards, with no comparable security surface to miss. Effectiveness across a real application
codebase is not settled here, and `0037` is where it can be.

## The per-gate batching figure

**The recorded sessions contain no batched session, so this ticket does not produce the figure**
`0025`'s FR4 named it as the source of. Of 27 claim tokens across the run, every one maps to exactly
one ticket. Two tokens name a second ticket in a commit subject — `3db2` names `0029` and `795a`
names `0021` — and both are the close reconciling a dependent's `blocked_by`, which is the one write
a closing stage is allowed outside its own ticket. Neither is a session taking two tickets through a
gate.

The run that would produce it is **`0037`**, the fresh-project end-to-end run, and it needs a
deliberate design rather than an observation: at least one `develop` and one `verify` session taking
a multi-ticket gate, against single-ticket sessions on comparable tickets. Until then `0025`'s
develop-side batching rule rests on the capture-side figure and on `0017`'s precedent, which is what
that ticket already says it rests on.

## The kill criterion this also settles

`0016`'s FR5 carried one: drop the approval-gate reorder if an isolated batch retro measures under
$1.50. Two `retro` sessions ran. Retro-attributed turns cost **$5.01** across 46 turns, and the one
retro-only session cost **$4.00** on its own. **Nothing came in under $1.50, so the criterion is not
met and the approval-gate reorder stays.**

## What the two runs did not hold constant

Five things were **not held constant** between the two runs. Weigh the comparison against them
rather than trusting it.

- **The project.** The baseline ran the suite end to end against a new project. The isolated run is
  this repository — established, and markdown skills plus shell guards rather than application code.
- **The skills themselves.** The isolated run *edited the files each of its sessions loads*, 19
  tickets' worth, while running. The suite measured at the end is not the suite measured at the start.
- **The conventions and reference weight.** `0020` and `0021` cut `CONCURRENCY.md` from 17,943 to
  6,017 bytes and trimmed the six skills 22% part-way through the run, which changes the startup
  every later session pays.
- **Scale and work mix.** 98 turns in one conversation against 1,112 turns across 30 sessions, over
  different ticket populations.
- **The baseline's own published figures.** They are not reproducible from its transcript, at about
  78% of published on both cost and context per turn.

Held constant: the model, `claude-opus-5` on both sides, and the rate card and turn definition
applied by one script to both.

## Re-running this

The store is live and has grown. The date window alone now returns **42 sessions and $170.17**
against the 30 and $114.27 published above, because sessions kept landing inside the same two UTC
dates that a date bound cannot separate. What pins the run is the session-id set, so the command
carries it in full:

```sh
tools/harvest-usage.sh <transcript-store> --since 2026-08-23 --until 2026-08-24 \
  --exclude 1860b4f4 --exclude 5c2b0c27 --exclude 26acbad7 --exclude 3ab24685 \
  --exclude 05e441cd --exclude b5862898 --exclude fe292418 --exclude 52cc41c8 \
  --exclude 35873f41 --exclude 873196d2 --exclude ba215ccf --exclude 1a2da19b
```

Verified 2026-08-30: **30 sessions**, 1,112 turns, **$114.27**, and every cell of both tables above
down to each skill's context per turn. Should it stop reproducing those, a session inside the window
has been added or resumed — re-derive the exclusions against the published per-skill session counts
rather than republishing whatever the window returns.

`--since`, `--until`, `--sessions` and `--exclude <session-id-prefix>` are the modes, and
`--exclude` is repeatable. `tests/measurement.test.sh` guards the arithmetic and this record's
claims.
