---
id: "0009"
title: One skill per session
type: feature
next:
status: active
created: 2026-08-23
parent:
ships: incrementally
---

## Outcome

No skill invokes another, no handoff between skills travels in conversation, and each session
starts near-empty. A ticket moves `queue → design → develop → verify` through fields on disk,
and a session that learns something records it where the next session will read it.

## Why this exists

A measured end-to-end run of the suite against a new project on 2026-08-22 cost **$15.11** over
95 turns. Of that, **85% was context handling** — 59% re-reading context, 26% loading it — and
only 15% was output. The price of a turn doubled across the run, $0.12 in `queue` to $0.25 in
`retro`, for work of the same kind. Nothing got harder; the context got bigger, reaching an
average of 191,752 tokens per turn.

The suite is already built for separate windows — that is what `CONCURRENCY.md` is for, and every
skill already takes a complete file-based input. Running all five in one conversation is what
made it expensive. Modelled at a 60k average context, the same run costs ~$5.09.

Effectiveness is not the problem and must not be traded for cost. The same run caught a real
zip-bomb vulnerability that every acceptance criterion passed over, and a test that stayed green
with the guard it existed for deleted. Both live in the 15% of spend that is output.

## Why `ships: incrementally`

The three gates below are independently useful and independently verifiable. Gate A alone makes
the queue cheaper to read; Gate B alone stops findings being lost whether or not isolation ever
lands. Only Gate C depends on both, and shipping it early is the one sequencing mistake available
here — it converts a measurable saving into silent information loss.

## Slices

- **Gate A — the field model.** `Next` and `Status` as separate fields; the pared table; the
  `## Waiting on` section and the reader that surfaces it. Everything else references these
  fields, so landing them late means rewriting the same paragraphs twice. Tasks 0010, 0011.
- **Gate B — the durable handoff.** Every session parks what surprised it; verify closes; queue
  sweeps the buffer. Tasks 0012, 0013, 0014.
- **Gate C — isolation.** Remove cross-skill invocation, move retro out of the per-ticket loop,
  document the workflow. Tasks 0015, 0016, 0017.
- **Gate D — routing and weight.** Queue routes to design, design escalates on taste,
  `CONCURRENCY.md` compresses, the skills trim. Tasks 0018–0021.

## Cross-cutting commitments

- **No rule is dropped anywhere in this effort.** Every change is to workflow, placement or
  wording. The rigour that produced the defects the measured run caught — mutation testing, the
  separate NFR pass, the `design` gate, TDD — stays exactly as it is.
- **Nothing here is measured by feel.** The effort opened with a measurement and closes with one:
  re-run the same end-to-end exercise against a fresh project and compare cost per turn and
  context per turn, not just the total.
- **`RANKING.md` becomes load-bearing** the moment 0010 lands, because the pared table can no
  longer answer a re-rank. Queue writes it on every insert from then on.

## Out of scope

- Changing what any skill checks for. This effort moves work between sessions; it does not
  relax a standard.
- `prototype`. It stays human-invoked and is not a lifecycle stage.
- The nested-work effort (0002) and its tasks, beyond the one FR handoff recorded in 0010.

## Notes & decisions

- **Verify closes the ticket, not develop.** The current rule that verify writes nothing to the
  backlog exists so it is safe to run alongside a developing session. Isolation removes that
  hazard, so the constraint and the durable-verdict file it would otherwise have required both
  disappear. This deleted a task from the plan rather than adding one.
- **Retro inverts.** It stops observing a session it is no longer in and becomes a periodic
  synthesiser over many sessions' parked findings. In the measured run, two of four findings
  existed only in conversation and would have been lost — which is the whole argument for moving
  observation into each skill.
- Full reasoning and the measured figures: `The Context Tax` and `Splitting the Suite`
  (Claude artifacts, 2026-08-22/23).

## Outcome — 2026-08-23

**Eleven of twelve tasks closed. 0021 is back at `next: queue`.** Gates A, B, C and most of D landed;
`0021` (trim the skills) could not close because its AC1 conflicts with its own FR2 — see that ticket for
the numbers and a proposed re-spec.

### What the workflow is now

`queue` sets the stage at capture time and sweeps `FINDINGS.md` for work. `design` settles the question
and writes the ticket itself when nobody holds it, escalating on taste and deciding on fact. `develop`
builds, leaves the tree green, and stops at `next: verify` — it closes nothing. `verify` claims the row,
runs the declared level, and closes on green or sends it back with the reason written down. `retro` runs
on a cadence over what many sessions parked. **No skill invokes another**, and every one of them parks
what surprised it before reporting.

### The cross-cutting commitments, checked

- **No rule was dropped.** `CONCURRENCY.md` went 17,943 → 6,017 bytes with all 10 rule names intact,
  diffed against a captured baseline rather than counted. All 59 `##` headings across the six skills
  survive. The one rule that *changed* is *`verify` never writes the queue* → *A stage writes only the
  ticket it holds*, which 0013 owns and which replaced a workaround with what it always meant.
- **Nothing was measured by feel** for the parts that could be measured: byte and token counts are
  recorded per file in 0020 and 0021. **The closing measurement is not done** — the effort opened with an
  end-to-end run against a fresh project and closes with one, and that run has not happened. Until it
  does, the ~$5.09 figure remains modelled rather than observed.
- **`RANKING.md` is load-bearing** and was rewritten for the shape this effort left, including a table of
  what each of 0002's tasks must re-specify against it.

### What this effort did *not* do

- **Re-run the measured exercise.** The single most valuable remaining piece of work, and it is not a
  ticket yet: an end-to-end run against a fresh project under one-skill-per-session, compared on cost per
  turn and context per turn rather than total.
- **Reduce the six skills by 30%.** They fell 22% from where this effort had grown them, and 8% from
  where they started before it. `verify` and `design` are still larger than they were on 2026-08-22.
- **Fix `claim`.** The pared table still breaks it on a newly scaffolded project — 0022, ranked first.
