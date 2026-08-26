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
| **0053** | Row 1 on the **prerequisite override**, not on its tier: it makes 0042, 0044, 0045 and 0052 materially cheaper, and three sessions had each hand-built the same throwaway fixture. | *batch 2*, "0053 goes to row 1" |
| **0044, 0052, 0042, 0046, 0051** | Tier 1 — output that is silently wrong today. Ordered by blast radius (ships to every project > this repo's own files), then capture order. 0051 is `blocked` by 0042 and keeps its rank. | *sweep 1*, "Tier 1"; *batch 2*, "Tier 1" |
| **0047, 0045, 0060, 0054, 0065, 0050** | Tier 2, the compounding defects that fire on ordinary sessions — a lost QA verdict, a `TAKE` on held files, a findings gate that cannot settle, a verdict over a shared dirty tree. | *sweep 1*, "Tier 2"; *batch 2*, "Tier 2"; *batch 3*, "Where the six went" |
| **0055, 0058, 0056, 0059, 0064, 0062** | Tier 2, fully-specified fixes to the stage skills' own steps, above 0048 on tie-breaker 4's *more certain* — 0048 is an open decision of the same size. | *batch 2*, "Tier 2"; *batch 3* |
| **0048, 0057, 0049, 0061** | Tier 2, lower: 0057 on frequency, 0061 above 0043 because the repo↔install identity is paid for continuously as vigilance. | *batch 2*, "Tier 2" |
| **0066, 0063, 0067, 0043** | Tier 2, real but not accruing much; 0067 is dormant until someone starts a rename and beats 0043 only on blast radius. | *batch 3*, "Where the six went" |
| **0038** | Took 0036's exact slot when 0036 became a project — the work is worth what it was worth, and re-ranking on a re-spec is how a stack rank reshuffles for free. Its collision with 0006 was resolved as FR18/AC28, not a `blocked_by`. | *0036 became a project* |
| **0007, 0006, 0008** | Project 0002's phase 1, in their original order. 0008 is last of a `ships: together` group and outranks 0039 because leaving it unshipped strands the other three in a half-migrated backlog. | *0036 became a project*, "vs 0008" |
| **0039, 0040** | Below 0008, above 0003. 0040 sits directly under 0039 by the **regression-guard override**: 0039 without it is an unattended loop with no lock policy, and a stage killed holding `.lock/` blocks every future claim in the repo. | *0036 became a project* |
| **0003, 0004** | Phases 2 and 3 of project 0001, whose phase 1 is not done. | *0036 became a project*, "vs 0003 / 0004" |
| **0037** | In flight. Tie-breaker 3 is decisive: its comparison decays as 0028 and 0035 change how much context a session loads. | *0026 split into 0026 + 0037* |
| **0041** | Last, and considered rather than appended — nothing degrades while it sits, and there is no row it beats. | *0041 — the work-session review* |

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

- **0037's result.** It is the forward-looking measurement run; if the context saving did not
  materialise, the tickets resting on it need rethinking rather than re-ranking.
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
