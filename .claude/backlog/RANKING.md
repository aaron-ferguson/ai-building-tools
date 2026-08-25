# Why the order is what it is

Standing reasoning. Read on a re-rank, not on every claim.

## Current shape

**Project 0009 — one skill per session — is complete except 0021**, which is back at `next: queue`. Eleven
of its twelve tasks closed on 2026-08-23 (0010 earlier the same day, then 0011–0020). Nothing in the
project is blocked any more.

**0002 — the ticket graph** is phase 1 of the nested-work design (project 0001) and is now the live project.
Its tasks are unchanged in intent but **two of them need re-specifying against what 0009 left behind** —
see *What 0009 changed underneath 0002* below.

## The order now

1. **0022** — `claim` still parses the queue table by fixed column index, so it refuses every row on a
   newly scaffolded five-column table, silently. 0011 fixed the same defect in `next` (which now refuses
   an unparseable shape loudly rather than reporting an empty backlog) and left `claim` to this ticket.
   Tier 1: a new project cannot claim a row at all until it lands, and **0026 cannot run without it.**
2. **0026** — re-run the measured exercise. 0009's own closing commitment, and the reason the project's
   headline number is still *modelled* rather than observed. Ranked this high on **knowledge freshness**:
   the control is a specific run on 2026-08-22, and every week of drift in the skills, conventions and
   model makes that baseline a weaker comparison. It is also the ticket most likely to change what is
   worth doing below it — if the saving did not materialise, 0025 and 0021 both need rethinking.
   `blocked_by: 0022`.
3. **0024** — `blocked` derived from the graph. Tier 2 and **smaller and more certain** than 0023, which
   is why it goes first of the two. The defect is live and was observed this session: four rows sat
   `blocked` for a whole session after their blocker closed. The failure is asymmetric — a stale `blocked`
   hides work and nobody notices, while a stale `ready` is caught by the reader — so it is the direction
   worth spending on.
4. **0023** — a `close` script mirroring `claim`. Tier 2 for the same reason `claim` is a script: the
   commit inside the lock is what a session under load forgets, and a forgotten one strands the close in
   another window's commit. The measured cost is ~44 tool calls of pure mechanism across an eleven-ticket
   session. Below 0024 by tie-breaker 4 and **sequenced after 0022**, whose parser it must share rather
   than write a third copy of.
5. **0025** — name the batching case for `develop`. Prose, and correct on today's evidence, but placed
   below 0026 because FR4 wants that run's per-gate figure and 0017's precedent is that a workflow rule
   with no cost behind it gets dropped under pressure. **Deliberately not `blocked` on it** — blocking a
   correct rule on an unscheduled measurement is how it waits forever.
6. **0021** — at `next: queue`, not `develop`. Its AC1 (each skill at least 25% smaller) and its FR2 (no
   rule dropped) conflict on four of six files, because project 0009 added ~20,300 bytes of AC-mandated
   content to those files before this ticket ran. Two files met the floor, four did not, and the ticket
   records the numbers and a proposed re-spec. `queue` decides which; 0026's result may moot it.
7. **0005, 0007, 0006, 0008** — phase 1 of the graph, in their original order, with the re-specs below.
8. **0003, 0004** — later phases, blocked on 0002.

## What 0009 changed underneath 0002

Read this before picking up any of 0002's tasks.

| 0002 task | What changed | What it needs |
|---|---|---|
| **0006** — rewrite `next` to parse by header name and walk ancestors | 0011 rewrote `next` entirely: five-column shape, per-stage takeable row, `--waiting`, `blocked_by` derived from the graph, and a loud refusal on an unrecognised shape | **Re-specify.** Its FR2/AC2 fixtures enumerate seven- and eight-column tables that no longer exist, so it would close green against a table nothing uses. Header-name parsing is still worth doing; the fixtures and the diff are not what the ticket describes |
| **0005** — add graph fields to the template and `QUEUE.md` | 0010 took FR3 (the header row); 0011 added `## Waiting on` to the template | Check what is left before claiming — the template already carries `next`, `status`, `expects`, `claimed_by`, `claimed_at`, `touches` and `## Waiting on` |
| **0007** — replace the Owner column with claim directories | The pared table already has no Owner column, and the token's home is the item's `claimed_by:` | The remaining scope is the `claims/<id>/` directory mechanism, not the column removal |
| **0008** — add the graph rules to `queue`, `develop`, `verify` | Those three skills were rewritten by 0013, 0018 and 0021, and `develop` already refuses a row with an open `blocked_by` | Re-read the skills first; some of this landed as a side effect |

## The collision to watch — resolved

The `0009` × `0002` file collision `RANKING.md` warned about is over. 0009 landed every file it contended
for: `templates/QUEUE.md`, `templates/item.md`, `.claude/backlog/next`, and all six `skills/*/SKILL.md`.
0002's tasks now read the shape 0009 left rather than competing with it, which is the resolution this file
proposed — *"let 0011 land and then re-specify 0006 against the shape it finds"* — and it is what the table
above records.

## Notes on tie-breakers used

- **0022 at rank 1** is Tier 1 and *also* a prerequisite: it blocks any new project from claiming a row,
  and 0026 scaffolds a new project. Dependency order and tier agree here, which is unusual and made the
  placement free.
- **0026 above three cheaper tickets** is knowledge freshness (tie-breaker 3) doing real work rather than
  breaking a tie. Nothing else on the queue decays; this one's control does.
- **0024 above 0023** is tie-breaker 4, smaller and more certain, on two Tier 2 tickets that are otherwise
  level.
- **0025 not blocked on 0026** is a deliberate departure from how the rest of this backlog treats a
  dependency. The rule is right now and the figure only sharpens it, so the coupling is recorded in the
  ticket's notes with an instruction to revisit, rather than as a `blocked_by` that would park correct
  prose behind an unscheduled experiment.
- **0021 second but not takeable at `develop`.** Its stage is `queue`, so `./next develop` steps over it
  and says why. It is not sunk to the bottom: the work is worth what it was worth, and a ticket back at
  `queue` keeps its rank (see `QUEUE.md`).
- **0009's tasks above 0002's** was an explicit owner decision on 2026-08-23, recorded so a later reader
  does not read it as drift. It is now spent — the project is done.

## The retro sweep of 2026-08-23 — 0027 to 0035

Nine tickets out of a 36-entry `FINDINGS.md`. The order among them, and against what was already
here:

- **0030 (Notion out of the base suite) at the top** on tie-breaker 1, blast radius. Every project
  this suite scaffolds inherits the Notion default, where the rest of this sweep hurts only this
  repo. It is also Tier 2: a foundation defect each new project copies.
- **0027 (install the three scripts) second.** Six separate sessions hit it in one day, which is the
  strongest multiplicity in the buffer, and it is an `s`. Tier 2 compounding — every session in this
  repo claims by hand against exactly the rules the scripts exist to remember, and the documented
  fallback has already produced one wrong take (0026 read as blocked and skipped). Below 0030 only
  because its blast radius is this project.
- **0028 (soft goal for the reference files) above 0029** by the prerequisite rule: 0029 was parked
  *because* correcting the rule cost words the hard ceiling had no margin for. Ranking 0029 higher
  would put a ticket at row N that cannot be started.
- **0029 marked `blocked` with `blocked_by: 0028`**, so the column is derived rather than a judgement.
- **0005 keeps its position** rather than being pushed down by four newer tickets. Nothing in this
  sweep beats it except on the grounds above, and a queue that reshuffles on every capture stops
  carrying signal.
- **0031 to 0033 below 0005**, in tie-breaker 4 order (smaller and more certain first). All three are
  `s`, all three are guards or parsers whose defects are currently latent rather than live —
  0032 was verified still failing correctly today, and 0031's damage is a scope-overlap check that
  fails open.
- **0034 and 0035 last of the new rows, and not sunk below the old blocked ones.** Both are
  `next: design`, which is a real stage rather than a euphemism: each has a decision that blocks
  writing acceptance criteria, and both say so explicitly. A design ticket keeps its rank.
- **0035 merges two findings deliberately** — `prototype`'s three build procedures and `develop`'s
  anecdotes. Answered as separate tickets, two sessions would very likely give the same question two
  different answers, and the inconsistency would be worse than either answer alone.
- **0026 stays at row 1 while `waiting`.** A waiting ticket keeps its rank; sinking it means
  rediscovering why it mattered when the person clears it. What changed is only the honest state: its
  FR1 needs three separate sessions sat by a person, which no stage can execute.

Two decisions by Aaron on 2026-08-23 shaped this sweep and are recorded because they reverse
standing rules:

- **The hard size ceiling is retired in favour of a soft goal with recorded reasons.** If more
  principles exist than fit, the principles win; the goal's job is to stop anecdotes and niche cases
  accreting in a generic tool, and the first response to being over it is relocating detail to a
  pointer file rather than cutting a rule. This landed the same day for `skills/*/SKILL.md` in
  `tests/skill-size.test.sh` and is 0028 for the reference files. It supersedes 0020 FR4 and 0023
  AC7, both of which are closed.
- **Notion is a profile-specific preference, not a tool default**, and does not belong in the base
  suite in any form. 0030.

## Historical — why 0009 was ordered as it was

Kept because the reasoning explains the shape of the eleven closed tickets, not because it affects the
current order.

The project came out of a measured end-to-end run costing $15.11 over 95 turns, of which 85% was context
handling and 15% output. Gate A (the field model) went first because everything else reads or writes
`next` and `status`, so landing it late meant rewriting the same paragraphs twice. 0012 (parking findings)
came before any invocation was removed, because removing them first would have converted a measurable
saving into silent information loss. 0013 (verify closes) preceded the rest of gate B because it deleted a
rule the others would have had to work around, and a section 0020 would otherwise have compressed. 0021
went last because every other ticket rewrites the files it compresses — correct as far as it went, and the
reason it could not close is that those rewrites also *grew* them by 18%.

## 0036 — the supervising session, 2026-08-24

Aaron's own request, captured the same day, and placed **Tier 4: value** — above 0035, below 0034.
The reasoning is recorded at length because the placement is the one a later reader is most likely to
think wrong.

**Why Tier 4 and not Tier 2.** Nothing degrades while it sits. The hand-driven loop is a *recurring*
cost, not a *compounding* one: the fix does not get more expensive each day, no wrong pattern is
being copied into new code, and the ticket is fully specified so there is no knowledge to lose
(tie-breaker 3 does not apply). What is true is that every cycle the human drives is a cycle where a
step can be dropped — but that argument belongs to **0027**, which makes the mechanism forgettable,
not to the supervisor, whose value is throughput.

**The promotion argument, considered and rejected.** A supervisor makes every ticket below it cheaper
to work, which reads like the prerequisite rule ("A makes B materially cheaper, so A goes above B").
It was rejected because it proves too much: *any* tooling improvement makes all later work cheaper,
and admitting that as a promotion would put tooling permanently above product. The prerequisite rule
is for work that makes another ticket **possible**, and nothing on this queue is blocked on 0036.

**Why below 0034.** 0034 is Tier 2 — a complete `verify` pass that cannot close currently leaves no
record it ran at all, which is the silent information loss this whole backlog has been spending
tickets to stop. It is also an `m` against an `l`.

**Why above 0035.** Both are Tier 4/5 design tickets with no decay. Tie-breaker 1, blast radius:
0036 changes how every project running this suite is operated; 0035 decides where prose lives in the
skill files. Neither blocks anything.

**Why not `blocked_by: 0026` or `blocked_by: 0027`,** both of which it genuinely depends on:

- **0026** produces the observed baseline 0036's Performance NFR measures against, and it is
  `waiting` on a person. This follows the 0025 precedent above — blocking correct work on an
  unscheduled measurement is how it waits forever. Recorded in 0036's notes with an instruction to
  fold the figure in.
- **0027** installs the three scripts that *are* the supervisor's entire interface, and this repo's
  backlog still lacks them. The design pass does not need them; a build exercised end-to-end here
  does. Ranked above 0036 already, so the dependency and the order agree without a `blocked_by`.

**It may come back here as a project.** At `size: l` with an open mechanism question, the slicing
depends on the answer — so children invented now would be slices ranked against a mechanism nobody
has chosen. If `/design` returns multi-session work, 0036 returns to `next: queue` for slicing, per
the 0021 precedent.

---

## 0026 split into 0026 + 0037 — 2026-08-24

**Aaron's decision, prompted by the right question: why would we run that test now, with the tooling
work still open?** 0026 had sat at row 1 as `waiting` since 2026-08-23, and both halves of the answer
turned out to be wrong in different directions.

**Nothing was in fact asking for it.** Row 1 is a rank, not a takeability claim: `./next develop`
stepped over 0026 and offered 0005. The row was correct and read as an instruction anyway, which is
worth noting as a cost of a `waiting` ticket holding row 1 — the rule is still right (sinking it
means rediscovering why it mattered) but the display invites the misreading.

**The substantive objection was right, and stronger than the ticket recorded.** 0026 measures context
tokens per turn. `0028` (reference-file size regime) and `0035` (whether conditional skill detail
moves behind pointers) both change exactly that, and `0036` changes the shape of a run outright. A
fresh-project run measured on 2026-08-24 would have measured a configuration this repo is part-way
through replacing. The knowledge-freshness argument that put 0026 at row 1 pushed the other way, but
it is the weaker of the two: 0026's own FR9 handles drift by **disclosure** — record what was not
held constant — whereas measuring a configuration about to change is not fixable by a caveat.

**The split.**

- **0026 keeps its rank at row 1**, amended rather than re-specified: its FR1 relaxes from *a fresh
  project* to *an observed multi-session run*, measured from the transcripts already on disk. This is
  not a scope reduction dressed up — it is a **better** measurement than 0009 committed to, because
  both sides are observed rather than one side modelled. The 2026-08-22 baseline session and the 30
  isolated sessions of 2026-08-23/24 are both recorded, with per-turn `usage` and a skill marker.
- **It also clears the `waiting` state**, which was the actual blocker: FR1 needed three sessions sat
  in sequence and no stage can execute that. A harvest needs nobody. The `## Waiting on` section is
  deleted and the status is `ready`.
- **0037 takes the fresh-project run, ranked last.** Tie-breaker 2 decides it: nothing on the queue
  depends on 0037, while every graph ticket above it releases queued work. The freshness argument is
  spent, because 0026 now delivers the observed figure the decaying baseline was needed for. **Its
  value comes from running late** — after the size regime settles — which is the opposite of urgency,
  and the first ticket in this backlog whose correct position is derived from that.
- **0037 is `blocked_by: ["0028", "0035"]`,** so the column is derived rather than a judgement. This
  is a deliberate departure from the 0025/0026 precedent of *not* blocking work on an unscheduled
  dependency: here the ordering **is** the deliverable, since the whole point is to measure the
  settled configuration. `0028` closed mid-capture on 2026-08-24, leaving `0035` the sole open entry.
- **0037 is not blocked on 0036**, which would let a supervisor drive its sessions rather than a
  person sitting three windows. That follows the 0025 precedent after all — 0036 is `size: l` with an
  open design question — and 0037's FR9 handles either case by recording which way it was driven.

**What this unblocks immediately.** 0036's Performance NFR measures cost per closed ticket against
0026's observed baseline. Holding 0026 for the fresh run would have left 0036 building against
nothing; the harvest gives it a real number now, which is the ordering argument that made the split
better than simply deferring 0026.

**0021's fate is now settled by 0026 as amended.** Its re-spec was noted above as possibly mooted by
0026's result. That still holds, and the result now arrives without waiting on a fresh project.

---

## 0036 became a project — 0038, 0039, 0040 ranked — 2026-08-25

0036 was routed back to `queue` on its own recommendation (see the item's *Notes & decisions*) and
is now a project. **Its row has left `QUEUE.md`**; the three slices carry the stages.

**0038 takes 0036's exact slot — below 0034, above 0035 — on the re-specification rule that the
work is worth what it was worth.** Nothing about the ranking argument recorded above changed;
the *unit* changed. Slicing produced no new information about the value of the top slice, and
re-ranking on a re-spec is how a stack rank reshuffles for free.

**The promotion argument for 0038, considered and rejected.** `./next --findings` fixes a count
this repo already knows is wrong: `MEASUREMENT.md` publishes 26 and 28 in adjacent sentences
against a format-tolerant 42, so every count taken by hand off the obvious grep is low. That is
Tier 2 language — a wrong number being copied into new documents. It was rejected for two reasons.
Nothing consumes the count today, so no gate is mis-firing while it sits; and the wrong figures
are already published and already known, which makes them a documentation defect with a home
rather than damage accruing. Recorded rather than dropped, because it is the argument that would
promote 0038 the moment 0039 exists and something actually gates on the number.

**0039 and 0040 are ranked below 0008 and above 0003.** Three pairwise comparisons decided it:

- **vs 0035** — 0035 wins on tie-breaker 2. It unblocks 0037; 0039 unblocks only 0040. (0035 is
  `in-progress` under a token this session did not mint, so its line was not moved either way.)
- **vs 0007** — 0007 wins on tie-breaker 2. Closing it releases 0006 *and* 0008; and this repo's
  own `QUEUE.md` header still documents the claim-directory scheme as current fact, corrected
  in place, which 0007 owns removing.
- **vs 0008** — 0008 wins, and this is the one that is not obvious. 0008 is the last of a
  `ships: together` group (0002), and 0002's own note is that fields with no reader, a reader with
  no rules, or rules citing a shape that has not landed each deliver nothing alone. Leaving 0008
  unshipped strands 0005, 0007 and 0006 in a half-migrated backlog with two sessions reading
  different conventions — a Tier 2 cost that accrues, against 0039's Tier 4 value.
- **vs 0003 / 0004** — 0039 wins. Those are Phase 2 and Phase 3 of 0001, whose Phase 1 is not
  done; 0039 is the capability Aaron asked for, with its design settled and written down today.
  Tie-breaker 1 does not separate them (both are one project), so tie-breaker 3 decides: 0039's
  mechanism is fresh and its re-derivation cost is the one thing slicing could not reduce.

**0040 sits directly below 0039, and that placement is an argument rather than dependency order.**
0039 shipped without 0040 is a runnable unattended loop with no lock policy and a guessed spend
cap — and a stage killed holding `.claude/backlog/.lock/` blocks every future claim and close in
the repository, not just the run's. Letting 0040 drift down the queue is the same mistake as
splitting a fix from the regression guard that stops it returning.

**The 0006 collision was resolved as a requirement, not a `blocked_by`.** 0038 and 0006 overlap on
`.claude/backlog/next`, `skills/queue/templates/next` and `tests/next.test.sh`, and 0006 exists
because fixed-index parsing silently reports wrong values when a column moves — so 0038 written
against fixed indices would add a second reader for 0006 to rewrite and a second chance to be
silently wrong in the interim. **This repo's own argument for doing 0007 before 0006 —** *the
reader is written once against the final column set* **— applies here in reverse.** Blocking 0038
on 0006 would sink the top slice behind a two-hop blocked chain for a few lines of parsing, so
0038 gained FR18 and AC28 instead: the new modes resolve columns by header name from the start.
Either order then works, which is the test for `relates` rather than `blocked_by`.

## 0041 — the work-session review — ranked last — 2026-08-25

Aaron's own request, captured the same day, placed **Tier 4: value** and inserted **below 0037**,
at the bottom of the rank. Nothing degrades while it sits: the transcripts and `DONE.md` are
permanent, `tools/harvest-usage.sh` is committed and re-runnable, so a run that goes unreported
loses no data — it can be measured later at the same price. That is what keeps it out of Tier 2.

Three pairwise comparisons decided the position:

- **vs 0039 and 0040 — they win on the prerequisite rule.** 0039's FR10 log is what makes a *work
  session* a thing on disk with a boundary, a per-stage cost and timestamps; 0040 is ranked directly
  below it for reasons already recorded. 0041 is buildable without them from `DONE.md` dates and
  transcript timestamps, so this is "materially cheaper after", not "impossible before" — which is
  still the prerequisite rule, and is also why 0041 took `relates` rather than `blocked_by`.
- **vs 0003 / 0004 — they win on tie-breaker 2, unblocks more.** 0003 releases 0004; 0041 releases
  nothing. Tier does not separate them cleanly (0003's readiness gate carries a compounding
  argument — a standard that slides session to session — which if anything puts it higher, not
  lower), and blast radius does not separate them either, since both change every project using the
  suite.
- **vs 0037 — 0037 wins, and it is in flight.** It is the forward-looking measurement run, and
  tie-breaker 3 is decisive: its comparison decays as 0028 and 0035 change how much context a
  session loads, while 0041's inputs are fixed history.

**Last is a considered position here, not an append.** Every row above it is either Tier 1–2, a
prerequisite of it, or unblocks work it does not — and there is no row it beats.

**The knowledge-freshness argument was weighed and rejected as a promotion.** 0026's measurement
method and 0036's log design are both hot right now, which is tie-breaker 3 — but a tie-breaker only
separates rows already tied on tier and on the earlier tie-breakers, and none of the rows above are.
What freshness did earn is the *Notes & decisions* inventory in the item: what
`harvest-usage.sh` already computes, what it does not (elapsed time), and the $6.01 / $4.45
baseline — written down now so design and develop do not re-derive it in a month.

## The findings sweep of 2026-08-25 — ten rows inserted above 0038

`FINDINGS.md` had reached 86 entries and 78KB. The file's own header says a grown buffer *is* the
finding; the 2026-08-25 retro processed 16 and recorded that almost all of the remainder are units
of work only `queue` can take. This sweep took the **Tier 1 and Tier 2 clusters only** — ten
tickets bundled by root cause rather than by file — and left the ~22 skill-prose clusters parked.
That was a scoping decision, and it is why the buffer is still over `findings_threshold`.

**All ten rank above the previous row 1 (0038), so the whole existing queue shifted down.** That
is a large claim and it was checked against the recency trap deliberately: these are not new ideas,
they are defect reports that accumulated in a buffer for three days while the top of the queue held
Tier 3 and Tier 4 project slices from 0036 and 0001. Tier 1 and Tier 2 beat Tier 3, and none of the
four tier-overrides applies — 0038 is a prerequisite of 0039 and 0040, but of nothing inserted here.

### Tier 1 — output that is silently wrong, today

- **0044 first, on tie-breaker 1 (blast radius).** It is the only Tier 1 row that ships to *every
  project* installing this plugin: `./close` silently skips a block-list reconcile (it did, closing
  0028, leaving 0029 blocked and `--drift` red) and closes a ticket reporting success while ticking
  zero acceptance criteria (it did, on 0035). Both corrupt the backlog's own record of what was
  verified. The other three Tier 1 rows are this repo's files.
- **0042 above 0046 and 0051 on tie-breaker 2 (unblocks more)** — it is 0051's `blocked_by`.
  Repairing `MEASUREMENT.md`'s figures while the assertions over them cannot fail would leave no
  evidence the repair held, which is the whole defect one level up.
- **0046 above 0051 on tie-breaker 4.** Both are this repo, neither unblocks anything, both are
  fresh; 0046 is `s` and entirely certain. It is Tier 1 rather than Tier 5 because `README.md`
  offers its block as "run every guard" and it runs 8 of 11 — a contributor following it right now
  gets a false green, including on the guard that catches installed-script drift.

### Tier 2 — compounding

Ordered by the regret operator where the tie-breakers did not separate, and that is recorded
because it is the place this ranking is most arguable:

- **0047 top of the tier.** Two paragraphs, fully specified, and what it prevents is the loss of a
  QA verdict that exists nowhere but in the session about to end.
- **0045 next.** `./next` prints `TAKE` on a row whose expected files are held, with the proof four
  lines below in the same output. Three instances on 2026-08-25 alone.
- **0050 and 0048 above 0049**, against tie-breaker 4, which would have put `m` above `l`. Both
  compound on *every ticket* — 0050's stall fired twice in one day on different file pairs, and
  0048's handoff is traversed twice per ticket and has already half-applied — while 0049's two
  instances are isolated. Preferring the compounding rate over size here is a judgement, not a
  rule, and a later re-rank is entitled to disagree with it.
- **0043 last in the tier.** Its registry entries all resolve *today* (the wrong ticket id the
  finding named was corrected by 0035 before this sweep read it), so the damage is latent rather
  than accruing. It stays Tier 2 rather than Tier 5 because the gates' own first recommendation is
  relocation — the operation most likely to break an entry — so the trigger is built into the
  advice.

### What was deliberately not promoted

- **0050 did not go above 0045**, though tie-breaker 3 (knowledge freshness) initially argued for
  it. That argument dissolved on inspection: what was decaying was the evidence — the four
  candidate shapes and the two stall instances — and writing it into the item is what freshness
  buys. Once captured it stops decaying, so the tie-breaker no longer separates them, and the
  regret operator does: a tool that gives an actively wrong verdict beats better guidance about a
  stall the tool would then report honestly.
- **0051 kept its rank while `blocked`**, per the standing rule. Sinking it would mean
  rediscovering why a published figure was wrong once 0042 clears.

## The findings sweep of 2026-08-25, batch 2 — ten more rows, inserted at five positions

The second pass over the same buffer, taking the clusters batch 1 left. Same bundling rule: one
ticket per root cause, which here mostly means one per skill file — six to eight findings each,
because six tickets on one prose file reproduces the stage-wide stall 0050 exists to settle.

**Rows already in the queue were not re-sorted.** Every insert went above the first row it beat.

### 0053 goes to row 1, on the prerequisite override rather than on its tier

`tests/next.test.sh` prints `ok`/`FAIL` and never the line the assertion saw, so a mutation sweep
cannot tell why a case passed. On its own tier that is a Tier 3 tool — its value is mostly the work
it releases. But **a prerequisite outranks its dependent**, and it makes four queued tickets
materially cheaper: 0042 repairs three guards by mutation, 0044 and 0045 each carry
mutation-driven ACs, and 0052 makes "name the input that would make this red" a requirement of
every criterion. Three consecutive sessions have each hand-built the same throwaway fixture and
thrown it away. Row 1 is the override doing exactly what it is for — otherwise row 1 is work that
is about to be paid for four more times.

### Tier 1 — 0052 above 0042, below 0044

- **0044 keeps row 2 on tie-breaker 5.** 0044 and 0052 are both Tier 1, both ship to every project,
  neither unblocks a queued row, both are `l` and both were specified from a cold read. Nothing
  separates them until capture order, and 0044 was captured first. A queue that reshuffles on every
  capture stops carrying signal.
- **0052 above 0042 on tie-breaker 1.** 0052 changes `queue` and `verify`, which ship to every
  machine installing the plugin; 0042 repairs this repo's own test files.
- **0052 is Tier 1 and the argument is worth recording**, because nothing about it is bleeding in
  the code. Criteria that could not have failed have been closing tickets — 0036's AC13 survived a
  `queue` pass and a `design` pass — so the record of what was verified is silently untrue, and
  nobody is counting it.

### Tier 2 — four inserts above 0050, four above 0048, two lower

- **0060 and 0054 above 0050.** The findings gate counts a number no retro can reduce, so
  `./next --drive` diverts every driver into a retro that reads the buffer again and correctly finds
  nothing — a control loop that cannot settle, firing on every drive. 0054 is what a session does
  with a red or a verdict taken over a tree another session has dirty, which in this repo is the
  normal condition rather than the exception. Both fire more often than 0050's stall and both are
  buildable today, where 0050 is a decision.
- **0055, 0058, 0056 and 0059 above 0048, on tie-breaker 4's "more certain".** All four are
  fully-specified skill fixes; 0048 is an open decision of the same size. 0059 sits with them rather
  than lower because the hazard it names is a *wrong verdict*: in a batch, one ticket's Step 3
  mutation is live in the tree another ticket's suite run reads, and that red is attributed to the
  wrong ticket.
- **0057 below 0048, on frequency.** The handoff is traversed twice per ticket and has already
  half-applied; a split or a task-to-project conversion happens occasionally, and when it does the
  shape is reconstructable from 0009, 0002 and 0026 → 0037, which is how it was done both times.
- **0061 above 0043.** The repo↔install identity is being paid for continuously as vigilance —
  `CLAUDE.md` instructs every session to diff the trees before concluding a rule is absent — where
  0043's registry entries all resolve today.

### Two things this batch deliberately did not do

- **0052 and 0057 were not merged**, though both touch `skills/queue/SKILL.md` and
  `templates/item.md` and will therefore collide. Their root causes are unrelated, and merging two
  contracts because their files overlap is how a ticket ends up built to something nobody agreed to.
  The collision is 0050's problem to solve, not a reason to distort the tickets.
- **The solo-profile cluster was not ticketed at all.** Both entries — the orphaned Notion port from
  0030's *Out of scope*, and the fact that `CONVENTIONS_CORE.md` resolves preferences only through
  `companies/<name>/` so a *solo* preference has nowhere private and discoverable to live — are work
  in the conventions repo and in Aaron's own projects, not in this one. They stay parked, and the
  right home for them is that repo's backlog.

## The findings sweep of 2026-08-25, batch 3 — six rows, three amendments, one unused ID

The pass that empties the buffer. Six tickets at three anchors; three findings landed as
**amendments** to tickets already editing the exact step they concern, rather than as tickets of
their own — see the note at the end, which is a ranking decision as much as a scoping one.

### Where the six went

- **0065 above 0050, against tie-breaker 4.** It is `s` and completely certain, which by the
  tie-breakers would put it above 0054 as well. It sits below 0054 because the regret operator says
  so: 0054 is about verdicts taken over a tree that never existed as a commit, which happens
  whenever two sessions overlap — the normal condition here — while 0065's failure needs someone to
  hand-edit `QUEUE.md` with a stream editor. Same judgement as batch 2's 0050/0048-over-0049, and
  recorded for the same reason: it is where this ranking is arguable.
- **0064 then 0062, above 0048.** 0064's failure is the most severe of the six — a stage silently
  does not run, the session believes it did, and the queue says the row moved. It is Tier 2 rather
  than Tier 1 only because it needs someone to type the bare skill name. 0062 follows it: an
  addition-only FR list cannot express a removal, and an absence NFR asserted over the deliverable
  alone misses the ticket's own prose, which is exactly how 0026 shipped a privacy breach in its
  Problem section.
- **0066, 0063, 0067, above 0043.** All three are real and none is accruing much. 0066 is three
  script defects, one of which (a correct `verify` claim reading as an under-specified `develop`
  one) reaches every other session; 0063 is the unwrapping matcher, which fires on every prose edit
  but only in this repo's own suites; 0067 is dormant until someone starts a rename, and is above
  0043 only on blast radius.

### Two things worth recording about 0063

It is a **looser** matcher in a repo whose characteristic defect is a guard that runs and cannot
fail, so its ACs are written to make the fix unshippable as one — AC2 and AC3 require the matcher to
still miss an absent phrase and to still respect a section boundary. It was also not treated as a
prerequisite of the eleven queued tickets naming scoped prose greps: it makes their assertions more
robust, not possible, and the prerequisite override is for "possible or materially cheaper", not
"better".

### Three findings landed as amendments, not tickets

Each was one clause in a step another ticket was already rewriting, and each would otherwise have
put a second session in the same prose file — the collision 0050 exists to settle.

- **0055 gained FR10/AC11** — Step 5's mutation rule cites the copy-aside diff for uncommitted code,
  one clause in the paragraph FR4 already rewrites.
- **0058 gained FR5/AC8** — Step 3 confirms the mutation reached the file the harness runs, in the
  step FR2 and FR3 already rewrite.
- **0060 gained FR6/AC5** — a bundled ticket's removal list derives from its FRs, not from the
  cluster that produced it. It went to 0060 rather than 0057 because it is a rule about the
  **sweep**, which 0060 owns, not about a `queue` operation.

Each re-check confirmed `size`, the QA plan's named checks and *Out of scope* were unaffected,
which is the actual work of an amend; the FR is the cheap part.

### 0068 was claimed and not used

The batch was scoped at seven and written as six once the three amendments above proved to be the
right home for what the seventh would have held. **The ID is left unused rather than reclaimed**:
`next_id` had already been committed at 69, and rolling it back risks handing 0068 to a concurrent
session that has since read the higher value. A gap in the numbering costs nothing; a duplicate
costs a ticket.
