---
id: "0186"
title: Never drop a session from the harvest because its model has no published rate
type: bug
next: verify
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0162", "0164", "0187"]
expects:
  - tools/harvest-usage.sh
  - tests/sprint-ledger.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`tools/harvest-usage.sh` omits a whole session whose turns all ran on a model missing from its
`RATES` table, so the harvest under-counts sessions and nothing downstream can see the gap.**

Measured on run-20260922T031109Z (parked 2026-09-23 by that run's supervisor): the queue sweep ran
all 42 turns on `claude-opus-5-5`, which `RATES` does not list, and the harvest printed
`HARVEST of 4 sessions` from five transcript files, with no `queue` row. The retro, which mixed 50
`claude-opus-5-5` turns with 29 `claude-opus-5` turns, was priced at USD 1.22 on 12 of its 91 turns.
The ledger row for the run records `tail_usd 1.22`, and the true figure cannot be computed.

0162 already makes the harvest print `UNPRICED turns on a model with no published rate: N` instead of
a measured zero. That line is what made this visible. What it does not cover is a session with
**zero** priced turns: that session is dropped from the per-session table altogether, so its count
of unpriced turns reaches no row. Omitting the session is worse than a wrong rate, because a wrong
rate at least shows the session exists.

Checked 2026-09-25: `RATES` in `tools/harvest-usage.sh` lists `claude-opus-5` and `claude-opus-4-*`
only; `claude-opus-5-5` is absent.

## Functional requirements

- **FR1** — Every transcript the harvest reads produces a session row, whether or not any of its
  turns is priced. A session with no priced turn shows its unpriced turn count and no USD figure,
  never USD 0.00.
- **FR2** — The harvest's session count equals the number of transcripts it read. Where any session
  has unpriced turns, the header line names the model ids that had no rate.
- **FR3** — No rate is added for `claude-opus-5-5` unless it comes from a published source cited in
  the comment above `RATES`. A guessed rate is exactly the wrong number this row exists to prevent.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Measurement | An unknown model is reported rather than skipped | a fixture transcript whose every turn carries an unlisted model id, run through the harvest, yielding no row for it | `measurement-conventions.md` |

## Acceptance criteria

- [ ] **AC1** — Given a fixture run of two transcripts, one on `claude-opus-5` and one entirely on an
  unlisted model id, the harvest prints `HARVEST of 2 sessions` and a row for each.
- [ ] **AC2** — Given that fixture, the unlisted session's row carries its unpriced turn count and no
  dollar figure, and the header names the unlisted model id.
- [ ] **AC3** — Given a fixture whose turns are all on listed models, the output is unchanged from today.

## QA plan

Unit: fixture transcripts under a temp directory, run through `tools/harvest-usage.sh`, asserted in
`tests/sprint-ledger.test.sh`, which already runs the harvest (0162).
Each AC's guard is proved red against the current script first.

## Out of scope

- Which model a dispatch pins, or records: that is `0187`.
- Back-filling the ledger row for run-20260922T031109Z. Its figure cannot be recovered.

## Notes & decisions

- 2026-09-25 — filed by retro from the 2026-09-23 supervisor finding (run-20260922T031109Z tail).
  0162 is credited as the fix that made this visible.
- 2026-09-25 — built (develop, fd62), commits 637462a and the guard follow-up.
  - Shape: an unpriced-only session's `--sessions` row prints `unpriced` in COST USD and `-` in
    USD/TURN and both context cells (unpriced turns' tokens were never accumulated, so an integer
    there would be a false 0), then `| <skills> | unpriced turns: N`. A partly-priced session keeps
    its figures and gains the same suffix. The header reads
    `HARVEST of N sessions, unpriced models: <ids>` — comma and colon because the privacy guard's
    character set (`tests/measurement.test.sh`) admits no parentheses.
  - Model ids come from transcripts and land in a public output, so an id not matching
    `^[A-Za-z0-9.-]{1,64}$` prints as `unrecognised-model-id`; guarded by its own case.
  - FR2 reading: "transcripts it read" is taken as transcripts contributing at least one turn in
    the window. A transcript with no usage-bearing turn (or wholly outside `--since/--until`) is
    still skipped, as before; the ACs do not reach that case.
  - FR3: no rate added for `claude-opus-5-5` (none cited). The TOTAL row still reads 0.00 on an
    all-unpriced harvest — 0162's ledger labels that case, and the ledger's TOTAL regex is
    unaffected because TOTAL's SESSNS stays an integer.
  - AC3's guard is a golden of the pre-0186 script's output over the FR3 store, captured at e830d00.
  - Clause table and mutations (all RUN, against committed code, restored from HEAD):

    | AC clause | Guard | Mutation | Result |
    |---|---|---|---|
    | AC1 Given a fixture run of two transcripts, one on `claude-opus-5` and one entirely on an unlisted model id | `store-0186` fixture | — | — |
    | AC1 prints `HARVEST of 2 sessions` | header case | M1 restore `if not per_skill:` | red |
    | AC1 and a row for each | row grep | M1 | red |
    | AC2 row carries its unpriced turn count | `unpriced turns: 1` | M3 drop the label | red |
    | AC2 and no dollar figure | two-decimal grep | M4 print `0.00` | red |
    | AC2 header names the unlisted model id | header case | M2 skip model list | red |
    | AC3 Given a fixture whose turns are all on listed models, output unchanged | golden diff | M5 suffix always | red |
    | (privacy) unshaped id not echoed | placeholder case | M6 no sanitising | red |
