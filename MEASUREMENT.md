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

**`unmarked` is a session that ran no stage skill** — a shell, a question, a session resumed past
its `/clear`. It is small and it is not interesting, but it is carried in **every** table below
rather than dropped from some of them, because a row omitted from a table whose total still counts
it leaves the reader unable to reconcile the arithmetic of a record written to be reconciled. Three
of these four tables shipped without it; `tests/measurement.test.sh` now sums each table's rows
against its own total row.

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
| unmarked | 1 | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 100.0% |
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
| unmarked | 2 | 52,988 | 91,185 | 38,197 | 58.1% |
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
| unmarked | 12,655 | 5,092 | 40.2% | 59.8% |
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

**Reproduction and re-measurement are two different commands, and the budget needs the second
one.** *Re-running this* below is pinned to `--since 2026-08-23 --until 2026-08-24`, which is what
makes the published figures reproducible — and what makes it useless for the due date, since run
verbatim in October it returns these same August numbers by construction and can never show
movement. On 2026-10-31, run this instead, over the sessions recorded since the pinned set closed:

```sh
tools/classify-turns.sh <transcript-store> --since 2026-08-25 --until 2026-10-31
```

No `--exclude` flags: those pin the *published* set and would carry August's exclusions into a
different window. Compare its `TURNS/SESSN` column against the budget above. As at 2026-09-02 that
window already holds 57 sessions and 2,270 turns at **39.8 turns per session** — above the 37.1 the
budget was set from, so the figure to beat is not standing still. **If the figure has not moved, the
verdict is recorded as not moved** — this record's own history is that a modelled saving came in at
a fifth of the model, and the number is the only thing that settles it.

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

## What a turn of each category costs

**Recorded 2026-09-02, ticket 0085.** The same 30 sessions, the same pinned id set, priced by
`tools/cost-by-category.sh` — committed code, the rate table and cache multipliers of
`tools/harvest-usage.sh`, and the classification rules of `tools/classify-turns.sh`.

**Why this had to be measured before anything was built on the section above.** Every figure there
is a share of *turns*. A protocol turn is a short command and a short result; a work turn is a file
read, an edit and a test run. If protocol turns were cheap turns, removing nine of them would save
far less than 34.3% of anything and `0085` would have been optimising the wrong denominator while
looking rigorous. `0009`'s history — a modelled 66% that came in at 14.5% — is what makes an
unmeasured denominator a real risk rather than a pedantic one.

`mechanism` is split here into **`protocol`**, this backlog's own cost, and **`git`**, which any
project pays. That split is not in the section above, where git sits inside `mechanism`.

| Bucket | Turns | Turn share | $ total | **$ share** | $/turn | Context/turn | Appended/turn |
|---|---|---|---|---|---|---|---|
| `protocol` | 381 | 34.3% | 37.47 | **32.8%** | 0.0983 | 102,831 | 1,822 |
| `git` | 85 | 7.6% | 8.50 | 7.4% | 0.1000 | 110,274 | 1,620 |
| `work` | 378 | 34.0% | 42.77 | 37.4% | 0.1132 | 109,008 | 1,994 |
| `orientation` | 175 | 15.7% | 15.98 | 14.0% | 0.0913 | 103,696 | 2,607 |
| `narration` | 42 | 3.8% | 4.97 | 4.4% | 0.1184 | 128,294 | 4,504 |
| `other` | 51 | 4.6% | 4.57 | 4.0% | 0.0895 | 92,833 | 1,580 |
| **all** | **1,112** | **100%** | **114.27** | **100%** | **0.1028** | **106,139** | **2,017** |

**The finding, in one line: the protocol is 34.3% of turns and 32.8% of dollars, so the turn share
was not overstating anything.** A protocol turn costs $0.0983 against a work turn's $0.1132 — **87%
of a work turn, not a fraction of one.**

### Why a short turn is not a cheap turn

The intuition that a one-line command is cheap is an intuition about *output*. In a cached agentic
loop the dominant per-turn cost is re-reading the conversation so far, and that is very nearly
category-blind: context per turn is 102,831 for `protocol` against 109,008 for `work`, **5.7%
apart**. Output differs by more — 823 tokens against 1,156 — but output is the minority of the bill.

Cost per turn by position makes the same point from the other side, over sessions of 10+ turns:

| Decile | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| $/turn | 0.1313 | 0.0833 | 0.0870 | 0.0997 | 0.1004 | 0.1041 | 0.1063 | 0.1043 | 0.1054 | 0.1037 |
| Context/turn | 62,904 | 76,265 | 85,575 | 97,098 | 105,849 | 114,249 | 123,481 | 129,719 | 137,156 | 143,182 |

Context per turn rises **2.3x** across a session while cost per turn stays roughly flat, because the
growth is cache *reads* at 0.1x. The first decile is the expensive one — cache *writes*, at 1.25x,
are what a session pays to start.

**The constant worth carrying out of this table: a token held in context costs $0.50 per million per
turn it survives.** That, not the size of any one read, is the unit everything below is priced in.

### What removing a turn actually saves

| Bucket | $ own request | $ compounding | **$ per turn removed** |
|---|---|---|---|
| `protocol` | 0.0983 | 0.0183 | **0.1166** |
| `work` | 0.1132 | 0.0228 | 0.1359 |
| `orientation` | 0.0913 | 0.0331 | 0.1244 |

The second column is the cache reads every *later* turn no longer pays for what the removed turn
appended. **A removed turn is worth more than its own request**, which is the opposite of the
direction the risk was in.

### Per stage, which is what a reduction is aimed at

| Stage | Sessions | Turns/session | Protocol turns/session | $/session | **Protocol share of $** |
|---|---|---|---|---|---|
| develop | 12 | 38.6 | 12.8 | 4.03 | **29.9%** |
| verify | 10 | 38.4 | 14.9 | 3.63 | **40.8%** |
| queue | 5 | 36.2 | 11.8 | 4.24 | 30.8% |
| design | 1 | 27.0 | 12.0 | 2.32 | 39.4% |
| retro | 2 | 23.0 | 3.5 | 2.51 | 14.6% |

`design` is one session and is quoted as one.

### What the turn shares survive, and what they do not

The classification rules were attacked before this record was written, by re-running the same
1,112 turns with one rule changed at a time. Two results, and they point in different directions.

**The published headline is fragile.** *"41.9% mechanism is more than the 34.0% spent on work"*
holds only while git sits inside `mechanism`. Splitting git out puts mechanism at 34.3% against
work's 34.0% — a tie — and also reclassifying purely read-shaped access to `DONE.md`, `RANKING.md`,
`SCHEDULED.md` and `config.yml` as orientation puts it at **33.1%, below work.** Both changes are
defensible. **The comparison of `mechanism` to `work` should not be leaned on.**

**The figure a reduction is aimed at is robust.** The protocol share of turns under every variant
tried:

| Variant | Protocol share of all turns |
|---|---|
| published rules | 34.3% |
| read-only sibling-file access → `orientation` | 33.1% |
| precedence `orientation` ahead of `mechanism` | 32.2% |
| every attack at once | **31.5%** |

The worst defensible case is 31.5% against a published 34.3%. **The protocol is about one turn in
three however the rules are bent**, and that is the figure `0085` rests on.

Two smaller corrections from the same attack, both against claims made in
`docs/decisions/001-one-command-per-stage-boundary.md` before it was measured:

- **`mechanism` is barely inflated by ticket-reading scored by path.** Only **11 turns of 1,112**
  are mechanism solely because they read a sibling backlog file in a read-shaped command — 0.37 per
  session, not the "1–2 per session" that record first claimed. 22 more touch those files in a
  write, which is protocol.
- **The 4.6% `other` hides nothing that changes a conclusion.** It is 49 `Bash` turns and 6
  `AskUserQuestion` turns; the shell turns are `cd`, bare variable assignments and reads of paths
  matching no rule. Nothing in it is work or protocol in disguise.

### The one that is a cost of the rules, not of the sessions

`verify`'s git inspection is **20.5% of its mechanism turns against a 15.7% mean**, because
`CONCURRENCY.md` prescribes an advisory dirty-path intersection before a close. That is this
protocol's own git rather than the project's, and it is the only part of the `git` bucket a backlog
change can reach.

### Would a more linear workflow be cheaper? No — modelled at +12%

The question is whether fusing `develop` and `verify` into one session would save the second
session's startup. Priced with the constant above, for one ticket:

| Term | $ |
|---|---|
| Carrying develop's 74,970-token climb through verify's 38.4 turns | **+1.44** |
| Holding both skill files (~6,700 tokens) across 77 turns | +0.26 |
| One session floor's cache write no longer paid | −0.36 |
| Re-orientation and a second claim the fused session skips (~4 turns) | −0.40 |
| **Net against the observed $7.66 for the pair** | **+0.94, or +12%** |

**The saving people expect from fusing is small because the floor is cached; the penalty is large
because the first stage's climb is then re-read on every turn of the second.** This is the cost
argument only — the reason `verify` is a separate session is that it checks what the ACs say rather
than what it remembers building, and that is a correctness argument which does not trade against 12%
either way.

### Re-running this

```sh
tools/cost-by-category.sh <transcript-store> --since 2026-08-23 --until 2026-08-24 \
  --exclude 1860b4f4 --exclude 5c2b0c27 --exclude 26acbad7 --exclude 3ab24685 \
  --exclude 05e441cd --exclude b5862898 --exclude fe292418 --exclude 52cc41c8 \
  --exclude 35873f41 --exclude 873196d2 --exclude ba215ccf --exclude 1a2da19b
```

Verified 2026-09-02: 30 sessions, 1,112 turns, $114.27 — the same total the cost tables above
publish from `tools/harvest-usage.sh`, by a second path.

### What this measurement cannot see

- **It prices a turn, not a fusion.** `$ own request` is what a turn was billed; a fusion that
  replaces two turns with one keeps most of what they appended, so the honest range for a removed
  turn is **$0.0983 to $0.1166** and the predictions below use the low end.
- **`design` is one session**, and `unmarked` is two sessions of 5.5 turns that are attributed to no
  stage.
- **The rates are the published list rates** at 2026-09-02, not an invoice.


## What the harness floor costs, and what trimming it buys

**Recorded 2026-09-02.** The section above attributed 13,724 of the 58,060-token floor to this
project's own prose and left **~44,336 as "the harness"** — the largest single addressable block in
this record, and the only one nobody had opened. It is opened here by `tools/floor-probe.sh`, which
measures a floor the same way `tools/classify-turns.sh` does — the context of the first turn — and
reads each component as the **difference between two observed runs** that differ only in that
component. No component here is estimated.

**The finding, in one line: the MCP surface is 3,668–5,127 tokens of the floor and trimming it saves
$0.13–$0.18 per closed ticket, because the harness already defers MCP tool schemas — while ten
built-in tool definitions this suite never calls are 9,085 tokens, 2.5x the larger lever.**

### What the floor is made of

Each row is a measured floor; each component is the difference from the row above.

| Layer, cumulative | Floor tokens | This layer |
|---|---|---|
| Harness system prompt alone — outside any project, no tools, no MCP | 9,048 | 9,048 |
| …in a git repository with no `CLAUDE.md` | 9,173 | 125 (git and env context) |
| …in this repository, still no tools, no MCP | 16,753 | 7,580 (the `CLAUDE.md` chain) |
| …plus every built-in tool definition | 41,817 | **25,064 (built-in tools)** |
| …plus every configured MCP server | 45,520–47,013 | **3,668–5,127 (MCP)** |

**So the ~44,336 splits roughly 29,000 tool definitions to 9,000 harness system prompt**, and the
tool definitions are 3.2x the prompt. The MCP range is a range because it depends on how many
remote servers answer before the session starts: 6 servers and 133 tools connected on the high run,
fewer on the low one.

**Why MCP is the small half.** The harness records a `deferred_tools_delta` — MCP tools reach the
model as **names only**, and their schemas are fetched on demand. 133 MCP tool names are about 1,632
tokens; the ~1,127 tokens of MCP *server instructions* are not deferred and are the denser half of
what remains. The intuition that ~180 unused MCP tools must cost tens of thousands of tokens was the
premise worth checking, and it is false under this harness.

**Where the built-in 25,064 actually goes.** The `Skill` tool is **8,888 tokens**, of which the
57-skill listing is 6,410 — and **5,101 of that is 51 skills belonging to other plugins**, which this
repository never invokes. The six tools the suite does use (`Bash`, `Read`, `Edit`, `Write`, `Grep`,
`Glob`) are 8,062 together. A fixed ~388-token framing block arrives with the first tool of any set,
which is why these components do not sum to the total exactly.

### The experiment

Four configurations, three repetitions each, identical develop-stage prompt, run 2026-09-02. The
denied set is `Workflow`, `Agent`, `ScheduleWakeup`, `ReportFindings`, `ShareOnboardingGuide`,
`ListAgents`, `NotebookEdit`, `WebSearch`, `WebFetch`, `Artifact` — **no skill in this suite
references any of them**, checked before the run rather than assumed.

| Configuration | Mean floor | Saving | Share of floor |
|---|---|---|---|
| baseline — every tool, every MCP server | 45,520 | — | — |
| MCP servers off | 41,852 | 3,668 | 8.1% |
| 10 unused tool definitions denied | 36,435 | **9,085** | **20.0%** |
| both | 32,767 | **12,753** | **28.0%** |

The three repetitions of each configuration returned **identical** floors, so the figures carry no
run-to-run variance at all.

**`permissions.deny` in `settings.json` removes the definition, not just the permission** — the
denied configuration was measured through a settings file, and `--disallowedTools` gives the same
floor to the token. That makes this a durable, repository-scoped change rather than a launch flag.

**The saving persists to the end of the session, which is the part `0009` got wrong.** Floor fell
12,753 and end-of-session context fell 12,766 — a prefix token removed is removed from every turn's
context by construction, so this is arithmetic rather than a behavioural prediction. `0009` modelled
66% and observed 14.5% because isolation resets context per *session* and the sessions kept
climbing; nothing equivalent applies here.

### What it is worth

Priced with this record's own constant — **a token held in context costs $0.50 per million per turn
it survives** — plus the cache write the floor is paid for once. Two inputs were measured rather
than assumed, and both correct the section above:

- **The floor is written at the 1-hour TTL, exclusively.** Across the pinned 30 sessions' first
  turns: **940,182 write tokens at 1-hour, 0 at 5-minute.** This record's convention of pricing an
  unsplit write at the cheaper 5-minute rate does not reach the floor, which is split and is dear.
- **54.0% of the floor is written fresh and 46.0% arrives as a warm cache read**, so a session pays
  the write rate on about half of it.

That gives **$23.68 per million floor tokens per session** of 37.1 turns. On that rate the whole
58,060-token floor is **$1.375 per session, 36.1% of $3.809**, and the harness part is **$1.050**.

| Lever | Floor tokens | $/session | $/closed ticket | Share of $5.71 | Over 1,000 tickets |
|---|---|---|---|---|---|
| MCP servers off | 3,668–5,127 | 0.087–0.121 | **0.13–0.18** | 2.3–3.2% | **$130–$182** |
| 10 unused tools denied | 9,085 | 0.215 | 0.32 | 5.6% | $323 |
| both | 12,753–14,212 | 0.302–0.337 | **0.45–0.50** | 7.9–8.8% | **$453–$505** |

Per closed ticket uses this record's own 1.5 sessions per ticket — 30 sessions, 20 tickets.

### The verdict

**Trimming the MCP surface alone is not worth a ticket: 2.3–3.2% of a closed ticket, $130–$182 over a
thousand of them.** It is real and it is nearly free, but it is a fifth of the block it was assumed
to be, and the reason is that the harness had already solved it by deferring schemas.

**The lever that is worth taking is the one nobody proposed** — ten built-in tool definitions the
suite never calls, at 2.5x the MCP saving, plus 5,101 tokens of skill listings belonging to other
plugins. Taken together the two are 28.0% of the floor and 7.9–8.8% of a closed ticket.

Both are configuration, not code: an `.claude/settings.json` `permissions.deny` list and an MCP
server list. **Neither has been applied.** A `settings.json` that denies tools changes every session
in this repository including ones already running, so it is a change to make deliberately and not
as the tail of a measurement. Against the reduction `0085` is aimed at — the backlog protocol, 32.8%
of dollars — this whole block is a quarter of the size, and that ranking is the point of measuring
it.

### Re-running this

The pinned session set, read back through the committed probe:

```sh
tools/floor-probe.sh --read <transcript-store> \
  --config baseline:c80118f2,ab6ca254,a29cd503 \
  --config mcp-off:8b5d72bd,b36d62e1,1f66291e \
  --config deny-unused:a170a089,0c571f79,f924cdc6 \
  --config both:32d5ee27,9b733d29,993bc517
```

Verified 2026-09-02: 45,520 / 41,852 / 36,435 / 32,767, and every saving in the experiment table.

To measure a *new* harness rather than reproduce this one, `--run` launches the configurations
instead of reading them, and the figures should be re-derived rather than compared across harness
versions — see the caveat below.

```sh
tools/floor-probe.sh --run --reps 3 \
  --config "baseline:--tools default" \
  --config "both:--tools default --strict-mcp-config --mcp-config {\"mcpServers\":{}}"
```

### What this measurement cannot see

- **It is pinned to one harness version.** Deferral is why MCP is cheap; a harness that stops
  deferring, or starts deferring more, moves every figure here. The floors in the store already
  drift — 59,200 for develop on 2026-08-23 against 45,520 for a baseline probe on 2026-09-02 — and
  the two are **not** comparable, because the probe carries no `/develop` skill file and no
  `CONCURRENCY.md`. Every comparison in this section is between runs made minutes apart.
- **It measures the floor, not the work.** Denying a tool the suite has never called cannot cost
  turns, which is why that set was checked against the skills first; denying one it *would* have
  reached could cost more turns than the floor saves, and no run here would show it.
- **The 12 probe sessions are in the transcript store** and will fall inside any window opened after
  2026-08-25. They are 3-turn `unmarked` sessions and will pull a turns-per-session mean down; the
  ids are listed above and can be excluded.
- **The `CLAUDE.md` chain measures larger than the byte-derived figure** — about 7,580 tokens
  against the 4,694 that 4.038 bytes per token gives for the same files, because the published
  figure omits the parent `CLAUDE.md` and the framing that `@`-imports add. The section above is
  left as published; this is the correction, not a rewrite of it.
- **The rates are the published list rates** at 2026-09-02, not an invoice.


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

### The carrying constant, and why it is the useful form

The rate table prices a token **once**. What a session actually pays is the cache-read rate applied
**once per turn the token survives**, because every turn re-reads the whole conversation so far:

> **A token held in context costs $0.50 per million, per turn it survives.**

Two consequences, and they are what any reduction should be argued against:

- **10,000 tokens removed from the startup floor is worth $0.248 a session — 6.5%** of a $3.81
  session, since the floor is re-read on all 37.1 turns rather than paid once at the start.
- The size of a single read matters far less than **how early it lands and how many turns follow
  it.** A 5,000-token read on turn 2 of a 38-turn session costs six times the same read on turn 32.

**What the floor is made of, which decides where the largest lever is.** Of the 58,060-token floor,
this project's own prose is 13,724 and **the remaining 44,336 is the harness — the system prompt and
the tool definitions.** At the constant above that block is about **$1.10 of a $3.81 session, 28.9%**:
the largest single addressable block in this record, and the one nothing here has measured directly.

**Where the decisions built on all of this are written down:** `docs/decisions/001-one-command-per-stage-boundary.md`
(the protocol reduction, ticket `0085`) and `docs/decisions/002-matching-rigour-to-stakes.md` (what a
ticket costs by tier, and how to choose one). Neither restates the figures above; both cite them.

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
