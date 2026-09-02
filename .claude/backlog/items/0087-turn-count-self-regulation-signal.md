---
id: "0087"
title: Give a session a turn-count signal for the inline-or-own-session break-even
type: feature
next:
status: done
closed: 2026-09-02
qa_level: unit
size: l
created: 2026-09-02
source: user
parent:
blocked_by: []
relates: ["0086"]
expects:
  - MEASUREMENT.md
  - docs/decisions/002-matching-rigour-to-stakes.md
  - references/TRACKER.md
  - .claude/backlog/config.yml
  - tools/classify-turns.sh
  - tools/harvest-usage.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`docs/decisions/002-matching-rigour-to-stakes.md` names a break-even test — *"under about 10 turns,
keep it in the session you are already in"* — for deciding whether to fuse a small piece of work
into the current session or hand it to a fresh one. It is the rule Aaron uses today when deciding
whether he has inlined too much and should break out into a new session.

**There is no measurement backing that decision in the moment.** Every turn figure in this repo
(`MEASUREMENT.md`'s 37.1/38.6/38.4-turn averages) comes from `tools/classify-turns.sh` run
**retrospectively** against a stored transcript — it counts a session that already ended, it does
not watch one that is running. The ~10-turn rule is applied today as a feel, not a read number.

## Open design question

**Can a session observe anything about its own turn count from inside the conversation at all, and
if not, what is the nearest useful proxy?**

1. **A live in-session counter.** Something increments and is checked as the session runs. Unclear
   whether a skill — prompt text, not code with persistent state — can track this reliably on its
   own, or whether it needs a hook or another harness-level mechanism with visibility a Markdown
   skill does not have. Establishing whether this is even possible is itself part of the design work.
2. **A cheap correlated heuristic**, e.g. counting edits or files touched inline this session rather
   than turns directly. Needs no new infrastructure, but measures something merely correlated with
   the actual break-even variable, not the variable itself.
3. **Retrospective, but made useful sooner.** Turn on the currently-disabled `cost_tracking` block
   (`config.yml`, `TRACKER.md`) and extend its "Actual cost" close-out to log turn count alongside
   size, the same way `TRACKER.md` already calibrates `size` against dollars. This gives no live
   mid-session signal, but turns the ~10-turn rule from an assertion into something checked against
   this project's own history, and costs the least to build.
4. **A hook.** Claude Code hooks run shell commands on session events; worth establishing whether one
   can see or approximate a turn count in real time and surface a warning, versus only firing at
   session boundaries where the information arrives too late to act on.

None of these is assumed to be the answer — the first thing the design stage settles is whether a
live signal is feasible at all before designing one.

## Functional requirements

*(Completed by the design stage.)*

1. A session that has been inlining work has some signal — live or retrospective — indicating
   whether it has likely crossed the break-even point named in `docs/decisions/002`.
2. The signal's data source is stated explicitly (live introspection, a hook, or a
   calibration-based proxy), along with what it cannot see, so a session knows how much to trust it.
3. The signal is advisory — it informs the judgment call in `docs/decisions/002`, it does not act on
   its own (see *Out of scope*).
4. Whatever is built adds no new required manual step to every ticket; `size` continues to exist
   as it does today, and this augments rather than replaces it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The chosen mechanism and its known blind spots are stated once, in the file that owns it, and cited from `docs/decisions/002`. | `documentation-conventions.md` |
| Observability | The signal is inspectable — a session (or Aaron) can see what it is based on, not a silent heuristic nobody can check. | `observability-conventions.md` |

## Acceptance criteria

*(Written by the design stage.)*

## QA plan

- **Level:** unit — subject to correction once the design stage picks a mechanism; a live
  in-session signal may not be checkable by this repo's shell suite at all.

## Out of scope

- Automatically stopping or handing off a session — the signal is advisory, per FR3, unless the
  design stage explicitly decides otherwise and says so.

## Verdict — closed 2026-09-02 without being designed

**The signal is worth less than the lifecycle it would enter, and the calibration half of it is
already free.** Recorded per `measurement-conventions.md`: a ticket withdrawn is a decision with a
reason, not a row that quietly stops appearing.

**No acceptance criteria are ticked because none were ever written** — this item reached `design`
with its FRs and ACs marked *completed by the design stage*, and it is closed before that stage ran.
`DONE.md` records it as `not built`.

Three arguments, in the order they decide it:

1. **The payoff is smallest exactly where the signal fires.** The rule it would sharpen is
   `002`'s break-even at about 10 turns. **At break-even the two options cost the same by
   definition** — that is what break-even means — so a reading accurate to a turn or two buys
   nothing there. The money is at the extremes: a 3-turn fix given its own ticket is $0.50 against
   $5.71, and no counter is needed to notice that. A precise instrument aimed at the flattest part
   of the curve.

2. **It contradicts the finding it was captured from.** `002`'s headline is that *the decision that
   costs money is whether something enters the lifecycle, not how carefully it is treated once it
   has* — dropping the QA pass buys 32%, not creating the ticket buys 87%. This item is a `size: l`
   design-first entry, priced at the Full tier's ~$8.03, whose deliverable is a judgement aid for
   that same routing call.

3. **Option 3 was the residue worth keeping, and it does not survive its own arithmetic.** Turning
   on the `cost_tracking:` block (`references/TRACKER.md`, *Recording what an item cost*) makes
   every close append an *Actual cost* block — **a new protocol step on every ticket**, which is the
   category `0085` is cutting from 34.3% of turns, spent to calibrate a heuristic. It also breaks
   this item's own FR4, *adds no new required manual step to every ticket*. **And the answer it
   would buy is already free retrospectively:** `tools/classify-turns.sh` reports turns per session
   over any window with no per-ticket cost at all, and the **2026-10-31 re-measurement**
   (`MEASUREMENT.md`, *The turn budget*) already runs it. If the ~10-turn rule is to be checked
   against this project's history, that is where the number comes from.

**What would reopen it:** a live in-session turn count arriving as a harness capability rather than
as something this suite has to build. The obstacle was never the rule, it was that a Markdown skill
cannot observe the conversation it is running in — if that stops being true, the cheap version is a
line in a skill, not a ticket.

## Notes & decisions

- Captured 2026-09-02 alongside 0086, from the same discussion of
  `docs/decisions/002-matching-rigour-to-stakes.md`'s two tests (which tier, and inline-or-own-
  session) — this item is the second test, 0086 is the first.
- **Closed 2026-09-02, not built.** See *Verdict* above. Closed by hand rather than by
  `.claude/backlog/close`, which refuses any row not at `next: verify`; the missing
  withdraw-or-supersede operation is parked in `FINDINGS.md` for `0057`.
