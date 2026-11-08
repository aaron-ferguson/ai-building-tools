---
id: "0128"
title: Reshape orchestrate into a sprint that plans, works and closes a slice
type: feature
next:
status: active
qa_level: verify
size: l
created: 2026-09-09
source: user
parent:
blocked_by: []
relates: ["0036", "0038", "0039", "0059", "0060", "0067"]
expects:
claimed_by:
claimed_at:
touches:
---

## Problem

`orchestrate` drives the backlog until the queue runs dry or the findings gate fires. It has no
notion of a **unit of work a person agreed to**, and three consequences follow from that.

**Its dispatch unit is a conflict group, not a plan.** `./next --drive` on 2026-09-09 proposed a
single develop gate of **thirteen** tickets. Ten of the thirteen join it through one file,
`skills/retro/SKILL.md`; 0101 joins through `references/CONVENTIONS.md`; 0089 joins through one of
the twenty-one test files it names. That is exactly the sweep `next` warns about in its own comment
beside `gate_from` — *"would sweep half a backlog into one gate via a file two unrelated efforts both
happen to touch."* The grouping is **correct as a conflict-avoidance unit and wrong as a planning
unit**: 0064 is a README sweep, 0089 is a guard audit and 0114 is retro's release chain, and nothing
about them is one piece of work.

**Nothing is proposed and nothing is confirmed.** The run starts and the user learns the shape of it
afterwards. Aaron, 2026-09-08: *"maybe we should start off by having the agent propose a number of
tickets for the working session"* — with the count, which tickets, what the work is, why those, and
an estimate in real-world time, tokens and dollars.

**A run can end with work open.** `--drive` walks the rank, and `verify` dispatches at the ticket's
own rank position rather than ahead of new work — so a ticket that was just built can sit at
`next: verify` while a higher-ranked *new* develop gate is dispatched over the top of it. Aaron:
*"we should always verify the work that we've started so that it gets closed."*

The shape that fixes all three is a **sprint**: a scope proposed and confirmed, worked to
completion, closed with a retro when the findings warrant one, and recorded.

## Outcome

A person starts a sprint, is shown a proposal, confirms it, and gets back a completed slice —
built, verified, closed, and recorded — without typing the next command at any point.

## Scope

The children carry the stages. This project holds the outcome and the ordering, and is never
claimed or built.

- Rename and alias — `0129`
- The planning proposal — `0130`
- Finish before start — `0131`
- Batched verify — `0132`
- The retro-then-queue tail — `0133`
- Design dispatched in parallel — `0134`
- The estimate ledger — `0135`
- Parallel develop via worktrees, deferred — `0137`
- The sprint record, release notes and cost figures — `0041`, adopted rather than rewritten

## Non-goals

- **No sprint dollar budget.** Decided 2026-09-08. If the work needs doing, a token interruption is
  a pause and not a failure — the backlog is the state and the run log is only provenance, so a
  killed sprint resumes. Sizing a slice to fit a dollar line would cut a coherent slice to fit an
  arbitrary number, trading quality and long-run token efficiency for short-run thrift, which
  inverts the stated priority order of quality, then cost, then time. The per-stage
  `--max-budget-usd` runaway guard is unaffected and stays.
- **No calendar-day staleness window.** See `0133`.
- **No change to what a stage skill does.** A hand-driven `develop` or `verify` session behaves
  exactly as it does today.

## Measure

The number this project is judged on is **cost per closed ticket**, recomputed from `MEASUREMENT.md`
rather than quoted — it has gone stale there once already, which is why `0041` reads it from source.
A sprint that closes its slice should not cost more per ticket than the hand-driven baseline, and
the proposal's estimate should converge on the actual as `0135`'s ledger accumulates passes.

## Notes & decisions

- **2026-09-09 — three existing rows overlap this and are not duplicated.** `0041` already
  specifies the session review, its release notes and its cost figures, and its Problem quotes the
  original request for a *"Sprint Review"*; it is adopted as a child. `0060` and `0067` are
  **prerequisites**, not children — each is broader than this project and each blocks one child.
- **2026-09-09 — the priority order is quality, then cost, then time**, stated by Aaron and applied
  throughout: it is why develop stays sequential in `0137`, why `0132` batches verify only with
  per-ticket evidence, and why `0133`'s threshold is argued on pattern detection rather than on the
  cost it saves.
