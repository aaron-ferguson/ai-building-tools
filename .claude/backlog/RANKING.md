# Why the order is what it is

Standing reasoning. Read on a re-rank, not on every claim.

## Current shape

**Effort 0009 — one skill per session — is complete except 0021**, which is back at `next: queue`. Eleven
of its twelve tasks closed on 2026-08-23 (0010 earlier the same day, then 0011–0020). Nothing in the
effort is blocked any more.

**0002 — the ticket graph** is phase 1 of the nested-work design (effort 0001) and is now the live effort.
Its tasks are unchanged in intent but **two of them need re-specifying against what 0009 left behind** —
see *What 0009 changed underneath 0002* below.

## The order now

1. **0022** — `claim` still parses the queue table by fixed column index, so it refuses every row on a
   newly scaffolded five-column table, silently. 0011 fixed the same defect in `next` (which now refuses
   an unparseable shape loudly rather than reporting an empty backlog) and left `claim` to this ticket.
   Tier 1: a new project cannot claim a row at all until it lands, and **0026 cannot run without it.**
2. **0026** — re-run the measured exercise. 0009's own closing commitment, and the reason the effort's
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
   rule dropped) conflict on four of six files, because effort 0009 added ~20,300 bytes of AC-mandated
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
  does not read it as drift. It is now spent — the effort is done.

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

The effort came out of a measured end-to-end run costing $15.11 over 95 turns, of which 85% was context
handling and 15% output. Gate A (the field model) went first because everything else reads or writes
`next` and `status`, so landing it late meant rewriting the same paragraphs twice. 0012 (parking findings)
came before any invocation was removed, because removing them first would have converted a measurable
saving into silent information loss. 0013 (verify closes) preceded the rest of gate B because it deleted a
rule the others would have had to work around, and a section 0020 would otherwise have compressed. 0021
went last because every other ticket rewrites the files it compresses — correct as far as it went, and the
reason it could not close is that those rewrites also *grew* them by 18%.
