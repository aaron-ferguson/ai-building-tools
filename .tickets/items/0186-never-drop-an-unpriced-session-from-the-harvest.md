---
id: "0186"
title: Never drop a session from the harvest because its model has no published rate
type: bug
next:
status: done
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
closed: 2026-09-26
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

- [x] **AC1** — Given a fixture run of two transcripts, one on `claude-opus-5` and one entirely on an
  unlisted model id, the harvest prints `HARVEST of 2 sessions` and a row for each.
- [x] **AC2** — Given that fixture, the unlisted session's row carries its unpriced turn count and no
  dollar figure, and the header names the unlisted model id.
- [x] **AC3** — Given a fixture whose turns are all on listed models, the output is unchanged from today.

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

## QA evidence

Verify 2026-09-25, token 1bee, at `baa05d5` (claim commit over 0941c91). Copy executed: the repo's
`tools/harvest-usage.sh` and `tests/`, which is what the suite runs; no skill file is under test.

Conventions: ../ai-building-conventions

Command (configured `unit`, run in its reporting form `commands.unit_by_file`):
`for t in tests/*.test.sh; do "$t" || true; done` — 31 files, every one exit 0; the file under
test reported `sprint-ledger.test.sh 137 passed, 0 failed`, and `next.test.sh 485 passed, 0 failed`.
Lint and typecheck: none configured.

Tree: `git status --porcelain` empty at Step 2 and again after the last evidence command; dirty set
empty, so the intersection with the evidence set is empty — not advisory.

Mutations were run in a detached worktree at `baa05d5` so they could not touch the suite's tree,
each restored by `git checkout -- tools/harvest-usage.sh`, with a control run of
`tests/sprint-ledger.test.sh` reading `137 passed, 0 failed` after the last one.

Clause table (reused from develop's build notes; no clause omitted):

| AC clause | Guard | Mutation (re-run here) | Result |
|---|---|---|---|
| AC1 Given a fixture run of two transcripts, one on `claude-opus-5` and one entirely on an unlisted model id | `store-0186` fixture (`mk_session` on `claude-opus-5`, `mk_unpriced` on `claude-no-such-model-0`) | — | read |
| AC1 prints `HARVEST of 2 sessions` | header case | M1 `if not per_skill and not unpriced:` → `if not per_skill:` | red: `header is: HARVEST of 1 sessions, …` |
| AC1 and a row for each | row grep | M1 | red: `a session row is missing` |
| AC2 row carries its unpriced turn count | `unpriced turns: 1` | M3 `" \| unpriced turns: %d"` → `" \| %d"` | red, 136/1 |
| AC2 and no dollar figure | two-decimal grep | M4 cost cell `"unpriced"` → `"0.00"` | red, 136/1 |
| AC2 the header names the unlisted model id | header case | M2 `if unpriced_models:` → `if False:` | red, 135/2 |
| AC3 Given a fixture whose turns are all on listed models, the output is unchanged from today | golden diff | M5 `if r["unpriced"]:` → `if True:` | red, 136/1 |
| (privacy) unshaped id not echoed | placeholder case | M6 `printable_model` returns the raw id | red: header echoed `SENTINELPROSE says hi` |

| Row | How checked | Result |
|---|---|---|
| AC1 | guard above, plus M1 | PASS |
| AC2 | guards above, plus M2/M3/M4. **Published gap:** the fixture has one unpriced turn in one unpriced session, so M7 (`% r["unpriced"]` → `% 1`) and M8 (`merged["unpriced"] = unpriced` → `= unpriced_total`) both stay `137 passed, 0 failed`. Behaviour checked directly instead: a four-session scratch store printed per-session `unpriced turns:` 2/3/4/4 against `UNPRICED … 13`. Left unguarded here and parked in FINDINGS.md | PASS, count guard samples a single value |
| AC3 | golden guard plus M5; golden re-derived independently: `git show e830d00:tools/harvest-usage.sh` and the current script over the same three-session store diff empty, and over a scratch store of 4 sessions × 6 turns on mixed listed models with cache tokens the two diff empty with `--sessions`, `--since 2026-09-02` and `--run` | PASS |
| FR3 | `RATES` in `tools/harvest-usage.sh` read: no `claude-opus-5-5` key | PASS |
| NFR Measurement | the row's own red — a wholly-unlisted transcript yielding no row — is M1, which reddens | PASS, guarded |
| Always-on / privacy | model ids are transcript input reaching public output; `MODEL_ID_SHAPE` gates them, guarded by M6. Header consumer `tools/sprint-ledger.sh` parses only the `UNPRICED` and `TOTAL` lines, and TOTAL's shape is unchanged | PASS |
| Reachability | the new path is the unpriced-only session row; it is output-only, no write or privileged action | nothing newly reachable |

Evidence set: `tools/harvest-usage.sh`, `tests/sprint-ledger.test.sh`, `tools/sprint-ledger.sh`,
`tests/*.test.sh` (suite run).
