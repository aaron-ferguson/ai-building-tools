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
