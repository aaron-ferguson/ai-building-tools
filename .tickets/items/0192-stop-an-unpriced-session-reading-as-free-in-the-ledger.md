---
id: "0192"
title: Stop an unpriced session reading as free in the sprint ledger and the harvest
type: bug
next:
status: done
qa_level: unit
close_by: verify
size: m
created: 2026-10-06
source: retro
relates: ["0186", "0162", "0135"]
expects:
  - tools/sprint-ledger.sh
  - tools/harvest-usage.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
parent:
blocked_by: []
claimed_by:
claimed_at:
touches:
closed: 2026-11-27
---

## Problem

**0186 stopped the harvest's session rows printing USD 0.00 for an unpriced session; three other
readers of the same figures still do, and three sessions hit them independently.**

- `tools/sprint-ledger.sh record`, run-20260925T203345Z: every turn ran on a model missing from
  `RATES` (301 unpriced turns). The summary rows print `unpriced`, but every GATE, RATIO and DESIGN
  line prints `observed USD 0.00` — an unpriced session reads as a free one (`LEDGER.md`).
- `tools/harvest-usage.sh` per-SKILL table (develop 0186): a skill whose every turn is unpriced — the
  `queue` sweep of run-20260922T031109Z — has no skill row; its turns show only in the global
  UNPRICED line.
- `sprint` Step 7's session-limit resume caps the resumed leg at "stage cap less what a harvest of
  that session id already shows spent". Paused verify 0178 ran wholly unpriced (8 turns), the harvest
  said 0.00, and the supervisor subtracted a 1.00 allowance by hand.
- verify 0186: `tests/sprint-ledger.test.sh` 0186 AC2's fixture has one unpriced turn in one unpriced
  session, so mutations `% r["unpriced"]` → `% 1` and `merged["unpriced"] = unpriced` →
  `= unpriced_total` both stay 137/0.
- sprint run-20261008T021734Z (FINDINGS.md, 2026-10-08, "`harvest-usage.sh` has no rate for
  `claude-opus-5-5`"): `claude-opus-5-5`, now the default model, matched no `RATES` entry (154
  unpriced turns), so quantum-catan's three LEDGER.md rows (run-20261008T021734Z, …T023251Z,
  …T031454Z) recorded USD and tokens as `unpriced` and the develop GATE as observed USD 0.00. The
  harvest header also printed `RATES per million: opus 5 in 5.00 out 25.00, cache read 0.1x …` —
  a literal restated beside `RATES` (line ~465), which named a model the run never used.
- Published price for `claude-opus-5-5` (the claude-api skill's model table, cached 2026-10-06, and
  its `shared/prompt-caching.md` "Economics", both read 2026-10-08): input USD 4.00 and output
  USD 20.00 per million tokens; **cache read USD 0.20 per million = 0.05x input, not the 0.1x the
  script applies to every model**; cache writes 1.25x input at 5m and 2x at 1h, as elsewhere.
- develop 6ed0: `record` assigns `log_src = "<run log> event timestamps"` (line ~595) and never writes
  it, dead since `a3f5a7a` (0135), so no ledger line says the wall clock comes from run-log stamps.

## Functional requirements

- **FR1** — A GATE, RATIO or DESIGN line whose sessions include unpriced turns says so with the
  count; one whose sessions are wholly unpriced prints `unpriced`, never `USD 0.00`.
- **FR2** — The harvest's per-skill table has a row for every skill that ran, whether or not any turn
  was priced; a wholly unpriced skill shows its unpriced turn count and no USD figure.
- **FR3** — `sprint` Step 7 states what the resume cap is when the harvest shows the paused session
  wholly or partly unpriced, and that the run log records that the subtraction could not be made.
  Retro's recommendation, open to the build: resume at the full stage cap rather than a guessed
  allowance.
- **FR4** — The `wall_clock_min` ledger row cites `log_src` as its source; the dead assignment goes.
- **FR5** — 0186 FR3 stands, and is now met: `RATES` in `tools/harvest-usage.sh` gains
  `claude-opus-5-5` at input 4.00 / output 20.00, with the source and the date it was read cited in
  the comment above `RATES`.
- **FR6** — The cache-read rate is per model, held in `RATES` beside that model's input and output
  rates: 0.05x for `claude-opus-5-5`, 0.1x for every model already listed. `cost_of` reads it from
  there; the global `CACHE_READ_MULT` no longer prices a turn. Cache-write multipliers stay global
  (1.25x at 5m, 2x at 1h — the same for every listed model).
- **FR7** — The harvest's `RATES per million:` header is derived from `RATES` and the cache-write
  constants, naming every listed model with its input, output and cache-read figures, so it cannot
  disagree with the table that prices the turns. No rate figure is written as a literal in that
  print statement.

## Acceptance criteria

- [x] AC1 — Given a fixture run whose sessions are all unpriced, `record`'s GATE, RATIO and DESIGN
  lines print `unpriced` and no `USD 0.00`. Red: restore the 0.00 formatting.
- [x] AC2 — Given two wholly unpriced skills with different turn counts, the per-skill table prints
  a row for each with its own count. Red: drop the row, or print the first skill's count for both.
- [x] AC3 — 0186 AC2's guard uses two unpriced sessions with different counts, and the mutations
  `% r["unpriced"]` → `% 1` and `merged["unpriced"] = unpriced` → `= unpriced_total` each redden it.
- [x] AC4 — The `wall_clock_min` row names the run log's event timestamps as its source. Red: remove
  `log_src` from that row.
- [x] AC5 — `skills/sprint/SKILL.md` Step 7 names the unpriced-session resume cap. Red: delete it.
- [x] AC6 — Given a fixture session of one `claude-opus-5-5` turn with 1,000,000 each of input,
  output, cache-read and 5-minute cache-write tokens, when it is harvested, then the TOTAL row reads
  USD 29.20 (4.00 + 20.00 + 0.20 + 5.00) and no `UNPRICED` line prints. **Write this test first and
  record it red** (today: unpriced, USD 0.00). Red: remove the `RATES` entry (unpriced), price it at
  0.1x cache read (29.40), or alias it to `claude-opus-5`'s rates (36.75) — the three figures differ
  on purpose.
- [x] AC7 — The same fixture under the date-suffixed id `claude-opus-5-5-20261001` also prices at
  USD 29.20. Red: break the `DATE_SUFFIX` fallback.
- [x] AC8 — Given 0186 AC3's all-priced store, the harvest's `RATES per million:` line names every
  `RATES` key with its own figures, and editing one rate in `RATES` (in a copy of the script made by
  the test) changes that line. Red: restore the literal header. 0186 AC3's golden output is updated in
  the same commit for this one line only; every other line of it stays byte-for-byte.
- [x] AC9 — Given 0186 AC3's all-priced store (`claude-opus-5` only), every figure in the harvest
  other than the `RATES` line is unchanged by FR6. Red: change the 0.1x default in `RATES`.

## Notes & decisions

- **2026-10-06 (retro, run-20261004T232135Z tail).** Filed from five FINDINGS.md entries dated
  2026-09-25..10-07. One row because they share two files and one defect class: an unpriced figure
  printed as zero, or a guard too small to tell counts apart.
- **2026-10-09 (queue, amend).** The owner asked for the `claude-opus-5-5` rate to land together
  with FR1's "no USD 0.00 beside unpriced". FR1 already covered that half, so this row was amended
  rather than a second row filed. Added FR6–FR7 and AC6–AC9, FR5 rewritten from a gate into the
  rate itself (the 2026-10-08 FINDINGS.md entry was already absorbed above, at `07f0a96`). Size went s → m. Routed to
  `develop`, not `design`: the price is published and the header's shape is reachable from the code,
  so no decision is open. **TDD order the owner set:** AC6's test goes in red before any `RATES`
  edit. **Out of scope:** `tools/cost-by-category.sh` holds a second, separate `RATES` and
  `CACHE_READ_MULT`, and its `claude-sonnet-5` (3.00/15.00) disagrees with harvest's (2.00/10.00).
  That is a duplicated-knowledge defect of its own, parked in FINDINGS.md, not widened in here.
  Hand-editing quantum-catan's LEDGER.md rows is also out of scope, as are a push, a version bump
  and a reinstall.
- 2026-10-09 — retro, absorbed from tools `FINDINGS.md` (2026-10-08): a fourth instance. quantum-catan
  run-20261008T021734Z ran on `claude-opus-5-5`, which no `RATES` entry matched (154 unpriced turns),
  so `sprint-ledger.sh record` scored the develop gate at observed USD 0.00 against a predicted 0.00
  and the first sprint's USD 7.66 estimate against nothing. FR1 covers the printing; FR5 still governs
  adding a rate.
- **2026-10-09 (develop, token ead5) — build notes.** Commits `80eb428` (FR5/FR6), `0a8bdbd` (FR7),
  `1e8a3fb` (FR1), `ab9c3f5` (FR2), `05e97c2` (FR4), `dafe7fa` (FR3), `285357b` (CHANGELOG). Every
  new case is in `tests/sprint-ledger.test.sh` under a `0192` heading, and each was recorded red
  before its fix: AC6/AC7 printed `TOTAL … 0.00` plus an `UNPRICED` line, AC8 printed the literal
  `opus 5` header, AC1 printed `observed USD 0.00`, AC2 printed no skill rows, AC4 printed no
  run-log source, AC5 had no text.
  - **Decisions.** `RATES` holds each model's cache read as a **USD rate** (0.20 for opus-5-5,
    0.50 for opus 5), not as a multiplier. That is the figure the source publishes, and it is
    0.05x and 0.1x respectively. `cap_basis: "unpriced"` rides on the existing `resumed` event
    rather than adding a new event name. The per-skill context-breakdown table skips a wholly
    unpriced skill, because its figures are priced turns only. RATIO prints `= unpriced, unpriced:
    <n> turn(s) …`, and its numerator line uses the same text as GATE/DESIGN via `observed_text`.
    Added a bullet to LEDGER.md's "How to read a block" (in `touches:`). 0186 AC3's golden was
    re-captured for its RATES line only. AC9's extra `claude-opus-5` 36.75 case exists because that
    golden has no cache-read tokens, so it could not see FR6 move any other model.
  - **Mutation table — all RUN against the committed tree, each restored by `git checkout`:**
    AC3 `% r["unpriced"]`→`% 1` in `session_row` → 2 fail; AC3 `merged["unpriced"] = unpriced`→
    `= unpriced_total` → 1 fail; AC2 the same `% 1` in `skill_row` → 2 fail; AC2 drop the wholly
    unpriced skill row → 2 fail; AC6 remove the opus-5-5 entry → 6 fail; AC6 cache read 0.40 (0.1x)
    → 3 fail; AC6 alias to opus 5 rates → 4 fail; AC7 break the `DATE_SUFFIX` fallback → 2 fail;
    AC9 opus-5 cache read 0.60 → 1 fail; AC8 restore the literal header → 3 fail; AC1 restore
    `"USD %.2f" % h["usd"]` → 3 fail. AC4 and AC5 are proved by the recorded pre-fix reds
    (reasoned equivalent to deleting the fix).
  - **Not covered, and stays so:** a GATE over a session id with no transcript at all still
    reads a measured `USD 0.00`. That is 0173's case (no turns, no unpriced count), not an
    unpriced one.
- **2026-11-27 (verify, token 12f8) — PASS.** Verified at HEAD `87c5edd` (claim commit over
  `eca8208`); the build commits above are ancestors of it. Every AC re-checked and every mutation
  re-run by this pass; develop's table was not trusted. Some fail counts differ from develop's
  because the 0186 AC3 golden now also reddens on any RATES edit, which is that golden working as
  designed.

## QA evidence

Conventions: ../ai-building-conventions (resolved from `.tickets/config.yml` `conventions.path`)

Level: `unit` (frontmatter; no `**Level:**` prose in the QA plan, so no drift). Command run, the
reporting form of `commands.unit`: `for t in tests/*.test.sh; do "$t" || true; done` — 52 files,
every tally `0 failed` (`tests/sprint-ledger.test.sh`: `266 passed, 0 failed`; `tests/sprint.test.sh`:
`387 passed, 0 failed, 0 skipped`; `tests/next.test.sh`: `815 passed, 0 failed`). Lint, typecheck,
integration, e2e: not configured in `config.yml`, none run.

`./next --ac-digest 0192 --check`: `0192: ac_digest absent — unverifiable: no stamp to compare the
criteria against`.

Tree: `git status --porcelain` empty at the first run and after the last mutation (control); dirty
set empty, so the advisory intersection is empty. Copy executed: the repo copy, via
`tests/sprint-ledger.test.sh`'s `$ROOT`; `tools/harvest-usage.sh`, `tools/sprint-ledger.sh` and
`skills/sprint/SKILL.md` are byte-identical to the installed 0.9.51 copy.

Mutations were applied one at a time to the committed file, the diff checked non-empty, the test
file run, and the path restored with `git checkout -- <path>`; control after all of them:
`266 passed, 0 failed`.

Clause table (Given / predicate / object), each row with the mutation that reddened it:

| AC | Clause | Evidence (paths) | Mutation → result |
|---|---|---|---|
| AC1 | Given: a fixture run whose sessions are all unpriced | `tests/sprint-ledger.test.sh` 0192 AC1, store-0192-up: design, develop and verify sessions all on `claude-no-such-model-0` | fixture read |
| AC1 | GATE line prints `unpriced`, no `USD 0.00` | `tools/sprint-ledger.sh` `observed_text`, GATE block | GATE alone → `"USD %.2f" % usd` → 264/2 (AC1 GATE, FR1 partial) |
| AC1 | RATIO line | RATIO block `per_ticket` and `numerator` | RATIO head → `"0.00"` → 265/1; numerator → `USD %.2f` → 265/1 |
| AC1 | DESIGN line | DESIGN block | DESIGN alone → `USD %.2f` → 265/1 |
| AC1 | Red: restore the 0.00 formatting | `observed_text` | `text = "USD %.2f" % …` → 263/3 (GATE, numerator, DESIGN) |
| AC2 | Given: two wholly unpriced skills with different turn counts | store-0192-skills: queue 2 turns, retro 3 turns | fixture read; two items differing in the value |
| AC2 | a row for each | `tools/harvest-usage.sh` skill print loop | print only skills with priced turns → 264/2 (no queue row, no retro row) |
| AC2 | with its own count | `skill_row` | `% r["unpriced"]` → `% 1` → 264/2; `+= n` → `= unpriced_total` (running count) → 265/1 (retro) |
| AC3 | two unpriced sessions with different counts | 0192 AC3 case, sessions eeeeeeee (2) / ffffffff (3) | fixture read |
| AC3 | `% r["unpriced"]` → `% 1` reddens | `session_row` | 264/2 |
| AC3 | `merged["unpriced"] = unpriced` → `= unpriced_total` reddens | harvest session loop | 265/1 |
| AC4 | `wall_clock_min` row names the run log's event timestamps | `record` FIGURES loop, `log_src` | `src = "%s, actual from %s" % (src, log_src)` → `src = src` → 265/1 |
| AC5 | Step 7 names the unpriced-session resume cap | `skills/sprint/SKILL.md` Step 7 | delete the "Where that harvest shows … measured." sentence → 263/3 (both 0192 AC5 cases, plus 0175 AC2) |
| AC6 | Given: one `claude-opus-5-5` turn, 1M each of in/out/cache-read/5m-write | `mk_model_turn` fixture | fixture read |
| AC6 | TOTAL reads USD 29.20, no `UNPRICED` line | `tools/harvest-usage.sh` `RATES`, `cost_of` | remove entry → 259/7 (unpriced, 0.00); cache read 0.40 → 262/4 (29.40); alias opus-5 rates → 261/5 (36.75); `cost_of` global `inp * 0.1` → 264/2 (29.40) |
| AC6 | written first, recorded red | build commits `80eb4288` and earlier | develop's recorded pre-fix red; not re-derivable, not relied on |
| AC7 | date-suffixed id also 29.20 | `DATE_SUFFIX` lookup in `cost_of` | `rates = RATES.get(model)` only → 264/2 (store-0192-dated unpriced) |
| AC8 | Given: 0186 AC3's all-priced store | `$FIX/store` | fixture read |
| AC8 | header names every `RATES` key with its own figures | RATES header print | literal header → 262/4; omit last key → 264/2 (`omits: claude-haiku-4-5`) |
| AC8 | editing one rate in a copy changes the line | test's `sed` copy `harvest-0192.sh` | literal header → "did not follow an edit" red; alias mutation tripped the "edit matched nothing" check |
| AC8 | golden updated in the same commit for this one line only | `git show 0a8bdbd9 -- tests/sprint-ledger.test.sh` | diff shows exactly one `-`/`+` pair in the golden, the RATES line |
| AC9 | every figure other than the RATES line unchanged by FR6 | 0186 AC3 golden + 0192 AC9 opus-5 36.75 case | opus-5 cache read 0.50 → 0.60 → 264/2 (golden RATES line, AC9 36.85) |

NFRs: the ticket declares no NFR table. Always-on pass against `CONVENTIONS_CORE.md`: no auth,
credentials, UI or new egress; model ids printed in public output stay behind 0186's
`MODEL_ID_SHAPE` guard. AC5's guard is a prose `says` match, which this repo's CLAUDE.md
disfavours for new guards; the AC itself names "Red: delete it", so it is recorded, not failed.

Gaps: none. Every mutation above reddened.
