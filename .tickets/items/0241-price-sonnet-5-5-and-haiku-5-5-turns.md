---
id: "0241"
title: Price Sonnet 5.5 and Haiku 5.5 turns in the harvest, Haiku at its long-prompt rate above 100K
type: chore
next: develop
status: blocked
qa_level: unit
close_by: verify
size: s
created: 2026-11-26
source: user
parent: "0128"
blocked_by: ["0192"]
relates: ["0149", "0240"]
expects:
  - tools/harvest-usage.sh
  - tests/sprint-ledger.test.sh
  - CHANGELOG.md
ac_digest: AC1=cf6537fb AC2=f56fae78 AC3=5baabfa1 AC4=b6e06b7c AC5=fbe5e33f AC6=f2a3495e AC7=0fefc840 AC8=8ffc9de0
claimed_by:
claimed_at:
touches:
---

## Problem

`RATES` in `tools/harvest-usage.sh` (as at `4cff5b5`) lists `claude-opus-5-5`, `claude-opus-5`, three
Opus 4.x, `claude-sonnet-5`, `claude-sonnet-4-6` and `claude-haiku-4-5`. It has no `claude-sonnet-5-5`
and no `claude-haiku-5-5`, so every turn on either is an **unpriced** turn. That is the failure the
comment above `RATES` already cites: run-20260913T034946Z recorded USD 0.00 for two real sessions on
an unlisted model.

The 2026-11-26 model-tiering review (0149) needs those two models priced before any trial of them can
be scored. Any trial run today reads as unpriced in the harvest and the ledger.

Haiku 5.5 cannot be one `RATES` row as it stands. The claude-api skill's model table (cached
2026-11-03) and `shared/models.md` price it at **USD 0.10 / 0.50 per MTok when the prompt is 100K
tokens or fewer and 0.50 / 2.50 above that**. A stage session's context averages above 100K
(`MEASUREMENT.md`, 106,139 per turn), so pricing every turn at the short rate would understate it by
about 5x on exactly the sessions a trial would run. The same sources give Sonnet 5.5 as USD 2.00 /
10.00 with cache reads at 0.10. Neither source states Haiku 5.5's cache-read or cache-write rate.

## Functional requirements

- **FR1** — `RATES` gains `claude-sonnet-5-5` at input 2.00, output 10.00, cache read 0.10, with
  the source and the date it was read cited in the comment above `RATES`.
- **FR2** — A `claude-haiku-5-5` turn is priced by its **prompt size**, meaning input + cache read +
  cache creation tokens. A prompt of 100,000 tokens or fewer is priced at 0.10 / 0.50; above that,
  0.50 / 2.50.
- **FR3** — Haiku 5.5's cache-read rate for each tier comes from Anthropic's published pricing page,
  the Pricing row of the claude-api skill's `shared/live-sources.md`, cited in the comment with the
  date it was read. **A figure the page does not publish is not invented.** If the tier boundary or a
  cache rate cannot be read, `develop` hands the ticket off as `waiting`, saying which figure is
  missing.
- **FR4** — The harvest's `RATES per million:` header, derived from `RATES` since 0192 FR7, names
  `claude-sonnet-5-5` and both Haiku 5.5 tiers.
- **FR5** — `CHANGELOG.md` `## Unreleased` gains one entry naming the two newly priced models.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | A Sonnet 5.5 or Haiku 5.5 session is priced in the harvest and the ledger, not reported as unpriced or USD 0.00 | AC1–AC3: delete the entry and each fixture prints `UNPRICED` | `observability-conventions.md` |
| Documentation | Every new figure's source and read date sit in the comment above `RATES`; the CHANGELOG names the models | AC7 and AC8 are readings | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture session of one `claude-sonnet-5-5` turn with 1,000,000 each of input,
  output and cache-read tokens and no cache writes, when the harvest prices it, then its total is USD
  12.10. Red: remove the `RATES` entry, or set cache read to 0.20. (`tests/sprint-ledger.test.sh`)
- [ ] AC2 — Given a `claude-haiku-5-5` turn of 50,000 input and 10,000 output tokens with no cache, when
  it is priced, then the total is USD 0.0100. Red: price every Haiku 5.5 turn at the long rate.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC3 — Given a `claude-haiku-5-5` turn of 150,000 input and 10,000 output tokens with no cache, when
  it is priced, then the total is USD 0.1000. Red: price every Haiku 5.5 turn at the short rate.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC4 — Given two `claude-haiku-5-5` turns with no cache and 0 output, one with a prompt of exactly
  100,000 input tokens and one with 100,001, when each is priced, then the first is USD 0.0100 and the
  second is USD 0.0500005. Red: change the boundary comparison from "or fewer" to "fewer".
  (`tests/sprint-ledger.test.sh`)
- [ ] AC5 — Given a `claude-haiku-5-5` turn of 1,000 input tokens and 120,000 cache-read tokens, when it
  is priced, then it is priced at the long tier. Red: compute the tier from `input_tokens` alone.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC6 — Given AC2's fixture under the id `claude-haiku-5-5-20261001`, when it is priced, then the
  total equals AC2's. Red: look the tiered model up by its exact id only.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC7 — Given an all-priced fixture store, when the harvest prints its `RATES per million:` line,
  then the line names `claude-sonnet-5-5` and both `claude-haiku-5-5` tiers. Red: drop the tier from
  the header derivation. (`tests/sprint-ledger.test.sh`)
- [ ] AC8 — Given `tools/harvest-usage.sh` and `CHANGELOG.md`, when the comment above `RATES` and
  `## Unreleased` are read, then every new figure has a source and a read date, and one entry names
  both models. A reading. Red: any figure without a source.

## QA plan

- **Why that level:** pricing is a pure function over fixture transcripts; 0192's AC6–AC9 already
  build such fixtures in `tests/sprint-ledger.test.sh`.
- **Specific checks:** AC1–AC7 there, applying each AC's named mutation once. AC8 is read from the files.

## Out of scope

- Running any model trial. That is 0149's follow-on, gated on this ticket and on 0240.
- Re-pricing models already in `RATES`, or `tools/cost-by-category.sh`, beyond whatever it inherits
  from `RATES`. `develop` confirms on claim which of the two it is.
- Tiered pricing for any other model. None of the others publishes a tier.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-11-26 (queue): captured at the user's request** during the 0149 model-tiering review. It is
  a sibling of 0149 under 0128 for the same reason 0240 is.
- **`blocked_by: 0192`.** 0192 is at `next: verify` and its evidence rests on this same file's
  `RATES` and `cost_of`. Building here first would change the code under a verdict that hasn't been
  given yet (`CONCURRENCY.md`, *The working tree is shared too*, the stricter rule for a row held at
  verify).
- **Routed to `develop`.** No decision is open. The rates are published figures, and FR3 names the
  one gap and what to do if it stays a gap.
- **Amend-first test.** 0192's outcome was pricing what was unpriced as at 2026-10-08, and it is
  built and awaiting verify. Amending a ticket at verify would invalidate its evidence, so this is a
  new ticket.
- **For whoever runs the trial:** Haiku 5.5's tokenizer counts the same text as about 30% more tokens
  (claude-api `shared/models.md`). Compare sessions in dollars, not tokens.
