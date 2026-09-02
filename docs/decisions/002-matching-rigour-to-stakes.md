# 002 — Matching rigour to stakes, at a measured price

**Date:** 2026-09-02 · **Status:** accepted · **Supersedes nothing** · **Related:** `001`, tickets `0073`, `0085`

## Context

Aaron's question, and it is a planning question rather than an engineering one: *we are going to run
hundreds or thousands of tickets — how do I decide what deserves the full treatment and what should
be done quickly?* Answering it needs a price per ticket, which `0073` and `0085` now supply.

**The measured base is `MEASUREMENT.md` and is cited, never restated here.** The figures this
decision turns on, all from the pinned 30-session run of 2026-08-23/24:

| | |
|---|---|
| Cost per closed ticket, all stages | **$5.71** (`$114.27` over 20 tickets) |
| Cost per closed ticket, the two gates that close it | **$4.23** |
| Average session | **$3.81**, 37.1 turns |
| Startup floor | **58,060 tokens** — 44,336 harness, 13,724 this project's prose |

### What a session's cost is made of

One mechanic decides everything below: **every turn re-reads the whole conversation so far.** The
startup floor is not paid once at the beginning, it is paid again on all 37 turns.

| Block | $/session | Share |
|---|---|---|
| Harness floor — system prompt and tool definitions | 1.10 | **28.9%** |
| This project's own prose | 0.34 | 8.9% |
| The climb — what the session accumulates | ~1.10 | ~29% |
| Output — thinking and tool-call arguments | ~0.86 | 22.5% |

### The constant everything is priced in

**A token held in context costs $0.50 per million per turn it survives** — the cache-read rate in
`MEASUREMENT.md`, *The cost model*, applied once per turn rather than once per session. Two
consequences that do the work in this record:

- **10,000 tokens removed from the floor is worth $0.248 a session, or 6.5%.**
- The size of a single read matters far less than **how early it lands and how many turns follow
  it.** A 5,000-token read on turn 2 of a 38-turn session costs six times the same read on turn 32.

## Decision

**Tier by blast radius and detection latency, and understand that the expensive dial is upstream of
thoroughness.**

### The tiers, priced against the measured $5.71

| Tier | What it is | Cost | vs standard | When |
|---|---|---|---|---|
| **Inline** | No ticket. Fixed in the session that found it, 5–10 turns | $0.50–1.00 | **−87%** | Reversible, obvious, and wrong would show within minutes |
| **Light** | Ticket, built, self-checked. No separate QA pass | $3.89 | −32% | Internal tooling and scripts, where failure surfaces on the next run |
| **Standard** | Queued, built, independently verified against written criteria | **$5.71** | — | The default. Anything anyone but you depends on |
| **Full** | A design pass first, then the standard lifecycle at a higher QA level | ~$8.03 | +41% | Expensive to reverse, or on the retrofit list below |

Inline and Light are modelled from the measured stage costs; Standard is measured directly.

### The finding that should change how work is planned

**Dropping the independent QA pass — the saving that feels large — buys 32%. Not creating the ticket
at all buys 87%.** The factor between the cheapest real tier and the most thorough is about 2×; the
factor between inline and the full lifecycle is more than 10×.

So the decision that costs money is **whether something enters the lifecycle**, not how carefully it
is treated once it has. Once a session is committed, the marginal cost of doing it properly is
**$1.82** — the price of the QA pass. Turning a two-minute fix into a tracked item with its own
lifecycle is the expensive move, and it is the one that looks like diligence.

### The two tests

**Which tier:** *what does being wrong cost, and how long until you find out?* Impact and detection
latency — never size or effort. A one-line change to an authorization rule is Full; a 300-line
internal script may be Light.

**Inline or its own session:** *under about 10 turns, keep it in the session you are already in.*
Break-even is where a second session's floor ($0.36, its cache write) equals the cost of re-reading
the first session's climb across the second's turns ($0.0375 per turn). Below ~10 turns fusing wins;
above it isolation wins — which is why `develop` and `verify`, at 38 turns each, stay separate, and
why fusing them outright was priced at **+12%** and rejected (`001`).

### What never scales down

**A tier flexes ceremony and session count. It never flexes correctness.** A cheap tier is cheap
because it uses fewer sessions, not because it tests less — dropping TDD to save $1.82 loses money
the first time a defect reaches production, where the unit of cost is an incident rather than a
session. This is `CONVENTIONS_CORE.md`'s existing rule ("scaling down never touches a principle"),
now with a price attached rather than only an argument.

Some work is Full tier regardless of how small the change looks, because it cannot be retrofitted
once real customer data exists (`product-readiness-conventions.md`): **tenant isolation, identity
shape, authorization as data, the audit trail, stable identifiers, and how time and money are
stored.**

## Consequences

### Where the money is, ranked

1. **The tool-definition floor — 28.9% of a session, and unmeasured.** The largest single
   addressable block in the measurement, and nobody has looked at it. A session working this repo
   needs Bash, Read, Edit, Write, Grep and Glob; every other configured server is loaded, carried on
   every turn, and never called. Worth $0.50–0.75 a session if trimming clears 20–30k tokens —
   comparable to all of `0085`, for a config change. **This is the next thing to measure.**
2. **The backlog protocol — `0085`, −25% per ticket.** Measured, decided, routed.
3. **How much each turn reads.** Orientation turns append the most of any category (2,607 tokens
   against protocol's 1,822) on 15.7% of turns. Reading narrower costs nothing and is available
   today without a ticket.

### What this compounds to

| Scenario | $/ticket | 1,000 tickets |
|---|---|---|
| Today, everything at Standard | 5.71 | $5,710 |
| `0085` lands | 4.28 | $4,283 |
| Plus 30% of items routed Inline instead of Standard | 3.22 | $3,221 |
| Plus a trimmed tool surface, if it clears 20k tokens | 2.83 | **$2,832** |

**Routing discipline is worth more than the engineering work**, and the config change is worth nearly
as much as either. None of it requires building anything slower or worse.

### Closed questions — do not re-open without new measurement

| Theory | Worth | Why it fails |
|---|---|---|
| Split skills and references into smaller load-on-demand files | ~4.5% | All this project's prose is 8.9% of a session; `0035` priced relocation from the other side |
| Make sessions less chatty | 3.8% | A turn calling no tool is one in twenty-six; the count is 92% tool calls |
| A more linear workflow — fuse `develop` and `verify` | **+12%** | Carrying the first stage's climb through the second's turns costs more than the floor it saves |
| Cut the git bookkeeping | 7.4% | `CONCURRENCY.md` requires more tree inspection, not less — it trades a protection for pennies |

### What would trigger revisiting

The 2026-10-31 re-measurement (`001`, *How to tell*), or **any change to the model, its rates, or the
configured tool surface** — every figure here is denominated in the cost model of 2026-09-02, and the
tier spread is a ratio of session counts that a rate change moves bodily.

### What this cannot see

These are one repository's own sessions, editing the files those sessions load. **The floor is the
figure that generalises least**: a project with different MCP servers configured has a different
number, which is exactly why item 1 above is worth measuring rather than assuming.
