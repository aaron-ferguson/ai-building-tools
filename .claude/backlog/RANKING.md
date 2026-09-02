# Why the order is what it is

Standing reasoning. Read on a re-rank, not on every claim. **Current state only** — the dated
narrative of how each placement was argued is in `RANKING-HISTORY.md`, and the sections named below
are its headings.

The tiers, the five tie-breakers and the four overrides are **defined in the `queue` skill** and are
not restated here. One local name: **the "regret operator"** used below is that skill's *"if I could
ship exactly one of these two, which would I regret skipping more?"* — reached only when the
tie-breakers do not separate two rows, and every use of it is flagged, because it is where this
ranking is most arguable.

## The shape of this backlog

**It is dominated by a three-day findings sweep, not by a project plan.** Twenty-six of the
thirty-six rows came off `FINDINGS.md` on 2026-08-25 in three batches, bundled one ticket per root
cause, and they occupy the whole top of the queue. Below them sit the project slices that held the
top before the sweep — 0038 from project 0036, 0007/0006/0008 from 0002, 0039/0040, then 0003/0004
from 0001 — in the order they already had.

So the argument a re-rank has to make here is usually **defect against defect**, not feature against
feature: tier, then blast radius, then what a row unblocks. A new slice of project work does not get
in above these rows by being newer or more interesting.

## The order now, by the argument that placed it

| Rows, in queue order | Why they sit together | Full argument |
|---|---|---|
| **0085** | Row 1, inheriting the position `0073` held as the diagnosis. It is Aaron's standing token-efficiency instruction with a measured target behind it — 41.9% of every turn in the suite is the backlog protocol — and the only row whose cost is paid by every session working every other row. Nothing was moved to make room. | *2026-09-02*, "0085 goes to row 1" |
| **0053, 0044** | Both at `next: verify` — developed and unclosed. In-flight work closes before new work starts, per *`verify` owns closing*; a green left unverified rots as the tree moves. 0053 is also the prerequisite that made four rows below it cheaper. | *batch 2*, "0053 goes to row 1"; *2026-08-30*, "Why 0053 and 0044 stay above all of it" |
| **0074, 0042, 0051, 0073** | **The token-efficiency spine, now all four closed** — `0073` published the figure and opened `0085`, which inherits row 1. Placed on Aaron's stated priority of 2026-08-30 rather than on tier. 0074 is takeable now and needs no diagnosis; 0042 → 0051 → 0073 is a prerequisite chain, since 0073 publishes measurement figures 0051 must first make reproducible. | *2026-08-30*, "The gap the re-rank found first" and "Why 0073 is blocked by 0051" |
| **0075, 0076, 0077** | Tier 1, and placed above every older defect deliberately: each protects **every session that works the rows below it**, and all three are `size: s`. 0075 and 0076 already have a measured cost in this repo — a stale checkout that duplicated `ec650cd` four days later and collided the 0.9.6 bump, and a tool edit committed with a broken script the repo's own suite would have caught. 0077 is the guard for the class 0076 found. | *2026-09-01*, "The AetherWorks tool sweep" |
| **0084** | Tier 1 — the back half of the chain 0075 guards the front of, and the only row here whose failure makes every other row's fix silently not ship. Below 0075–0077 on tie-breaker 4: all three are `size: s` prose with a grep behind them, 0084 is `size: m` and a script. Above 0078 on blast radius — every machine and every consuming project, against this toolset's own improvement loop. | *2026-09-01*, "The release chain reported success and shipped nothing" |
| **0078, 0081, 0082** | Tier 1-2. 0078 is why the other eight sat in another project's buffer for ten days: 25 findings pointing at these tools, and no route out. 0081 and 0082 are the two backlog scripts failing open — a hand-off producing the drift `--drift` exists to catch, and a claim that narrates what it is about to do wrong. Ranked among themselves, **not argued against the sweep rows below**. | *2026-09-01*, "The AetherWorks tool sweep" |
| **0080, 0086, 0083** | The three of the nine that are decisions, so they sit under the buildable six. 0080 is recorded twice and measured the second time; **0086 holds 0079's slot** — 0079 merged into it on 2026-09-02, so the row now settles the whole `qa_level` vocabulary (a light tier *and* a level a repo with no runner can run) and cannot be worth less than 0079 was; 0083 became live load the day `verify` gained a second worktree prescription. | *2026-09-01*, "The AetherWorks tool sweep"; *2026-09-02*, "Two rows withdrawn and one merged" |
| **0038, 0039, 0040, 0041** | Project 0036's three slices in dependency order, plus the review that reads 0039's run log. Promoted from ranks 27/31/32 — the orchestrator is the second half of the same instruction. 0040 stays directly under 0039 by the **regression-guard override**. **0041 was narrowed to release notes on 2026-09-02 and is `size: m`**; the measurement half that earned it this position is built and published, so what holds the row now is a reporting feature and the next re-rank should say whether that still beats the two Tier 1 rows below it. | *0036 became a project*; *2026-08-30*, "What the orchestration chain's promotion cost"; *2026-09-02*, "Two rows withdrawn and one merged" |
| **0052, 0046** | Tier 1 — output that is silently wrong today. Unchanged in argument; they sit below the spine only because the spine was promoted over them, and 0042/0051 stepped past them on the prerequisite override. | *sweep 1*, "Tier 1"; *batch 2*, "Tier 1" |
| **0047, 0045, 0060, 0054, 0065, 0050** | Tier 2, the compounding defects that fire on ordinary sessions — a lost QA verdict, a `TAKE` on held files, a findings gate that cannot settle, a verdict over a shared dirty tree. | *sweep 1*, "Tier 2"; *batch 2*, "Tier 2"; *batch 3*, "Where the six went" |
| **0055, 0058, 0056, 0059, 0064, 0062** | Tier 2, fully-specified fixes to the stage skills' own steps, above 0048 on tie-breaker 4's *more certain* — 0048 is an open decision of the same size. | *batch 2*, "Tier 2"; *batch 3* |
| **0048, 0057, 0049, 0061** | Tier 2, lower: 0057 on frequency, 0061 above 0043 because the repo↔install identity is paid for continuously as vigilance. | *batch 2*, "Tier 2" |
| **0066, 0063, 0067, 0043** | Tier 2, real but not accruing much; 0067 is dormant until someone starts a rename and beats 0043 only on blast radius. | *batch 3*, "Where the six went" |
| **0007, 0006, 0008** | Project 0002's phase 1, in their original order. The recorded argument that 0008 outranks 0039 was **overridden on 2026-08-30**: the backlog stays half-migrated longer, accepted deliberately. | *0036 became a project*, "vs 0008"; *2026-08-30* |
| **0003, 0004** | Phases 2 and 3 of project 0001, whose phase 1 is not done. | *0036 became a project*, "vs 0003 / 0004" |
| **0069, 0070, 0071, 0072** | Tier 4 capability tickets and one Tier 5 polish, from the 2026-08-26 comparison batch. | *2026-08-26*, below |

**A standing instruction sits above this table.** On 2026-08-30 Aaron set token efficiency as the
top priority until the sessions are slimmed and orchestrated — *"once we have that, then we'll
continue to build on all of the other many good ideas"*. Rows 3–10 are there by that instruction
and not by the tier system, so a re-rank that disagrees with them is disagreeing with the
instruction. The cost is recorded rather than hidden: two Tier 1 rows (0052, 0046) sit below work
that nothing is bleeding from.

## Where this ranking is arguable

Three placements were made by the regret operator against what the tie-breakers said, and a later
re-rank is entitled to disagree with any of them:

- **0050 and 0048 above 0049**, where tie-breaker 4 would have put `m` above `l` — preferring the
  compounding *rate* over size.
- **0065 below 0054**, where `s` and completely certain would have put it higher — 0054's failure
  needs only two sessions overlapping, which is the normal condition here.
- **0052 ranked Tier 1** although nothing is bleeding in the code: criteria that could not have
  failed have been closing tickets, so the record of what was verified is silently untrue.

## What would change the order

- **The 2026-10-31 re-measurement.** `MEASUREMENT.md`, *The turn budget*: re-run
  `tools/classify-turns.sh --since 2026-08-25 --until 2026-10-31` against the per-stage budget. Turns
  per session down and **dollars per session flat** is the result that says the protocol was never
  the binding constraint, and the rows resting on that premise need rethinking rather than
  re-ranking. This replaces `0037`, which was the forward-looking run and was withdrawn on
  2026-09-02.
- **Anything starting to consume `./next --findings`' count.** The promotion argument for 0038 was
  recorded and rejected only because nothing gates on that number today.
- **A second session working prose files concurrently.** 0050 is the open decision on file scope; a
  collision that actually costs work promotes it above the fixes queued around it.
- **A findings sweep of comparable size.** The buffer is empty as of 2026-08-25; the next sweep
  should compare its clusters against these rows rather than inserting above them by default.

## 2026-08-26 — four capability tickets appended below 0041

0069–0072 were captured from a comparison against a third-party skills repo, not from this
project's own defects. None of them beat any existing row: nothing bleeds, nothing compounds, and
nothing queued above them is blocked on any of the four, so all four are **Tier 4 (Value)** at
best, sitting below every Tier 1–3 row already in the queue.

Against **0041**, also Tier 4 ("nothing degrades while it sits, and there is no row it beats"):
capture order decides, per tie-breaker 5 — 0041 was captured first and stays higher. None of the
tie-breakers separated 0041 from any of 0069–0071 on grounds other than capture order; the regret
operator was not needed.

**Among 0069, 0070, 0071:** the **prerequisite override** placed 0069 first — both 0070 and 0071
would, per their own *Notes & decisions*, revisit whether to call into whatever 0069 produces
(a shared vocabulary-recording mechanism) once it lands, so specifying 0069 first is not merely
convenient, it is what the other two are conditioned on being aware of. Between 0070 and 0071,
tie-breaker 4 (smaller and more certain) favoured 0070: 0071's open design question has real blast
radius (it may touch a mechanism four live projects already depend on), where 0070's worst case is
a net-new, self-contained skill file.

**0072** is mechanical polish, not a capability decision — it is `next: develop`, fully specified,
`size: s` — so it is **Tier 5 (Debt & polish)** and sits last of the batch, below the three Tier 4
rows, per the tier system itself rather than any tie-break among them.

Order added: 0069, 0070, 0071, 0072, all below 0041.

## 2026-09-01 — the release chain reported success and shipped nothing

0084 was captured from a live investigation rather than a sweep, and it is the first row placed
into the 0075–0083 block since that block was ranked.

**Tier 1 on the "silently wrong output" test**, the same test that put 0052 there: `claude plugin
update` printed a success line, wrote a fresh `gitCommitSha` into `installed_plugins.json`, and
re-extracted nothing, because the cache directory is keyed by version and the version had not
moved. The record named `219f507`; the bytes were `49371a4`. Nothing reports it, and the session
that then runs the stale copy cannot see it — this one did, resolving `queue` from that directory.

**Against 0075, 0076 and 0077 it loses on tie-breaker 4.** All three are `size: s`, are prose with
a grep behind them, and 0075 is the front half of the very chain 0084 completes. Shipping 0075
first also makes 0084 cheaper to build, since the fetch-and-derive rule it encodes is FR1 of the
script. The prerequisite override was considered and **not** applied: 0075 makes 0084 cheaper, not
possible, so it is a tie-breaker and not an override.

**Against 0078 it wins on tie-breaker 1.** 0078's blast radius is this toolset's own improvement
loop — real, and the reason eight rows sat in another project's buffer. 0084's is every machine and
every project that installs this plugin, and it is the one defect whose persistence means the fixes
in every row below it can be released and still not run anywhere. That last part is nearly the
prerequisite override, and was deliberately not called one: the chain does work when a version bump
happens, so the failure is conditional rather than structural.

**The regret operator was not needed.** The tie-breakers separated it from both neighbours.

**0061 was amended, not moved.** The same measurement is evidence in its design question — it kills
"trust the recorded version or sha" as an answer shape and narrows the question to what a session
with no source tree can read. That is an argument for promoting it out of the Tier 2 lower band,
and it is **left unmade here**: rows 1–10 sit under Aaron's standing token-efficiency instruction,
and a promotion into that region is his call rather than a capture session's. Recorded so the next
re-rank has it.

## 2026-09-02 — building what 0085's own cost record priced but did not build

`docs/decisions/002-matching-rigour-to-stakes.md` (built on 0073/0085's measurement) named a Light
QA tier and a ~10-turn inline-or-own-session break-even, both as pricing models rather than
mechanisms. Two tickets captured from asking what building each would actually take.

**0086 (the Light tier) is Tier 2, Compounding.** *(Amended — on 2026-09-02 `0079` merged into
0086, and the merged row took `0079`'s rank, one place above `0083` rather than immediately below
it. The tier argument below stands; the position sentence in its last paragraph does not.)* Decision 002's own *Consequences* section ranks
routing discipline — whether a ticket enters the full lifecycle at all — as worth more than any
single engineering fix under it ("30% of items routed Inline instead of Standard" is the single
largest lever in its cost table after the backlog-protocol change 0085 itself makes). Every ticket
that pays Standard's rate while a Light path is absent is the fix getting no cheaper while it
waits, which is the Tier 2 test.

**Against 0075–0083 it loses on tie-breaker 5, capture order — cleanly, not through the regret
operator.** Tie-breakers 1–4 do not separate them: comparable blast radius (this project's own
backlog machinery), no unblocking relationship either way, both freshly specified today, and 0086 is
`size: l` against that batch's mostly `s`/`m` — tie-breaker 4 actively favours the existing batch,
not 0086. It sits immediately below 0083, the last row of that batch, and above 0038, where the
older, still-blocked 0036 epic and the long tail of legacy `design`-stage debt begin — none of
which are compounding at 0086's rate; they are Value or Debt-tier decisions that have simply been
sitting.

**0087 (the turn-count signal) is Tier 4, Value.** *(Superseded — 0087 was closed not built on
2026-09-02; see `RANKING-HISTORY.md`, "Two rows withdrawn and one merged". The placement argument
below is kept because it is the reasoning the withdrawal disagreed with.)* The break-even test it instruments already exists
and is usable as a judgement call without it; building a live or calibrated signal makes that
judgement more precise, it does not close an active leak the way 0086 does — nothing degrades if it
waits. Compared against the 0069–0072 band (the same kind of process-instrumentation work, same
tier), tie-breaker 5 again decides it cleanly: that band was captured 2026-08-25 or earlier. It sits
last, below 0072.

**The regret operator was not needed for either placement.**
