# Measurement — what one skill per session actually cost

**Recorded 2026-08-24, ticket 0026.** Effort `0009` opened with a measurement and committed to
closing with one. This is that measurement, and it is **observed against observed**: both runs are
recomputed from their own transcripts by `tools/harvest-usage.sh`, at the same rates, by the same
arithmetic. Re-run it with that script rather than trusting the numbers below.

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
30 sessions because it closed 19 tickets; the baseline session cost $11.79 for one conversation. Per
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

19 tickets closed on 2026-08-23 and 2026-08-24, every one at `qa_level: verify`. Whole run,
**$6.01 per closed ticket**. Counting only the two gates that close tickets, develop and verify,
$84.64 over 19 is **$4.45 per closed ticket**. This is the figure `0036`'s Performance NFR measures
against; the baseline has no comparable denominator, because it ran against a different project and
`DONE.md` records no ticket closed before 2026-08-23.

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

**What the run caught.** 19 tickets closed, all at `qa_level: verify`, and the gate bit at least
once for real: `0021` was sent back with AC1 unmet on four of six files rather than closed. **42
findings were parked** across the two days — 4 dated 2026-08-23 and 38 dated 2026-08-24, counted as
at 2026-08-24 06:00Z — against the baseline run's 4, of which two existed only in conversation and
would have been lost. That is the durable-handoff half of the effort doing exactly what it was for.
This measurement itself caught a defect no acceptance criterion would have: naive per-line summation
of the transcripts overstates cost by 2.2x, and the figure would have been published wrong.

**What it missed.** Its own row: `0026` was read as `blocked` and skipped, leaving four rows
unavailable for a session, and the stale row survived three separate closes before `0024` fixed the
derivation. `FINDINGS.md` still holds all 42, which the file's own header calls the finding —
retros are not emptying it.

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

```sh
tools/harvest-usage.sh ~/.claude/projects/<slug> --since 2026-08-23 --sessions
```

`--until`, `--exclude <session-id-prefix>` and `--sessions` are the other modes; `--exclude` is how
an in-flight session is kept out of a harvest taken from inside one. The store is live, so a harvest
taken while other windows are working is not stable — pin the exclusions and record them, as this
one does. `tests/measurement.test.sh` guards the arithmetic and this record's claims.
