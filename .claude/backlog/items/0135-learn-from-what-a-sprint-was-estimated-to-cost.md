---
id: "0135"
title: Record what a sprint was estimated to cost against what it did, and estimate from that
type: feature
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0041", "0026", "0130", "0133"]
expects:
  - skills/sprint/SKILL.md          # corrected: the 0129 rename deleted skills/orchestrate/
  - tools/harvest-usage.sh
  - tools/sprint-ledger.sh          # NEW — writes and reads the ledger
  - .claude/backlog/LEDGER.md       # NEW — the ledger itself
  - .claude/backlog/config.yml
  - MEASUREMENT.md
  - tests/sprint-ledger.test.sh     # NEW
  - tests/sprint.test.sh
claimed_by: "99e3"
claimed_at: 2026-09-12T17:38:54Z
touches:
---

## Problem

**`0130` requires the proposal to carry an estimate in time, tokens and dollars, and two of those
three have a prior while the third has none.** `MEASUREMENT.md` gives per-session means — develop
$4.03 over ~39 turns, verify $3.63 over ~38, retro $2.51 over 23, queue $4.24 over 36 — and
`tools/harvest-usage.sh` recomputes them over any window. It emits **no elapsed wall-clock time**,
a gap `0041` records independently: *"neither 'time to complete a context window' nor 'total time
for the work session' is derivable from what the repo has."* So the first sprint's time estimate has
no basis at all.

**Nothing anywhere compares an estimate to an outcome.** Every figure in the repo is an actual. An
estimate that is never scored cannot improve, and the proposal `0130` introduces would stay a guess
indefinitely. Aaron, 2026-09-08: *"let's build in the ability to estimate and learn from past
estimations. That way, we can get this to be more accurate."*

**Two model assumptions are currently unvalidated and one of them can destroy work.**
`config.yml` models a gate as `base + per_extra_ticket × (n−1)`, derived from means measured on
**single-ticket sessions** and never checked against a large gate. On the thirteen-ticket gate
`--drive` proposed on 2026-09-09 it predicts a $54.41 develop cap. If the real curve is superlinear
the cap fires partway through — and a stage killed by `--max-budget-usd` is the worst outcome the
design has: a held claim, a dirty tree and possibly a taken lock, all of which the skill's own Step 7
says a human must clear. With `0128` declining a sprint budget, these caps are the only spend limit
left, which makes validating them load-bearing rather than tidy.

The second unvalidated assumption is `0132`'s: that batching verify saves session floors in
proportion to batch size.

## Functional requirements

- FR1 — Each sprint records its **estimate** — tickets, wall-clock, tokens, dollars — before the
  first dispatch, and its **actuals** for the same four at the end, in one durable record per sprint.
- FR2 — Wall-clock is derived from the run log's existing UTC timestamps, which already bracket every
  stage. No new instrumentation.
- FR3 — Token and dollar actuals are read from `tools/harvest-usage.sh` over the sprint's own
  session-id set, not a date window. A date window is not a pin on a live store — `MEASUREMENT.md`
  records the window that once selected 30 sessions now returning 42.
- FR4 — The next sprint's estimate is derived from the recorded history where one exists, and from
  `MEASUREMENT.md`'s priors where none does. A figure with no prior is **labelled as having none**
  rather than presented as derived.
- FR5 — The ledger records **findings parked per sprint**, and for each retro the count it consumed
  against the rows it produced. These are the numbers `0133`'s interim threshold and age limit are
  replaced from.
- FR6 — The ledger records the observed cost of a develop gate against `stage_budget_usd`'s linear
  prediction for that ticket count, so the model in `config.yml` is checkable rather than assumed.
- FR7 — The ledger records verify cost per ticket for batched and unbatched sessions, which is the
  measurement `0132`'s performance NFR commits to.
- FR8 — Every figure carries the source it was read from and the stamp it was true at, and both
  sides of any division carry one. A pinned numerator over a live denominator decays silently —
  the defect `MEASUREMENT.md` shipped and `0051` repaired.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The ledger is committed to a public repo, so like `harvest-usage.sh` it holds only aggregate numbers, skill names and session-id prefixes — never message text, file contents or paths it was not given | `data-privacy-conventions.md` |
| Performance | The ledger is written from data the sprint already has — the run log and one scripted read — and adds no per-cycle supervisor turn | `observability-conventions.md` |
| Documentation | Where the estimate came from is recorded with it, so a later reader can tell a prior from a measurement | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a completed sprint, when its record is read, then it holds an estimate and an
      actual for tickets, wall-clock, tokens and dollars. **Red if** any of the four is recorded as
      an actual only, which is what every existing figure in the repo is.
- [ ] AC2 — Given the very first sprint, when its proposal is produced, then the wall-clock figure is
      marked as having no prior. **Red if** it is printed like the dollar figure, which does have
      one — the two are indistinguishable to a reader otherwise.
- [ ] AC3 — Given two completed sprints, when the third is proposed, then its estimate is derived
      from the recorded actuals rather than from `MEASUREMENT.md`'s priors. **Red if** the ledger is
      written but never read, which is the failure that makes an estimate never improve.
- [ ] AC4 — Given a develop gate of more than one ticket, when the sprint ends, then the record holds
      the observed cost beside `stage_budget_usd`'s prediction for that count. **Red if** only the
      observed cost is recorded, which leaves the linear model unfalsifiable.
- [ ] AC5 — Given the ledger, when `grep` runs over it for a message-text sentinel planted in a
      fixture transcript, then nothing matches. **Red if** the ledger writes anything but aggregates
      — the same assertion `tests/measurement.test.sh` already makes for `harvest-usage.sh`.
- [ ] AC6 — Given any ratio in the ledger, when it is read, then its numerator and denominator each
      carry a source and a stamp. **Red if** either is bare — the shape that went stale in
      `MEASUREMENT.md` once already.

## QA plan

- **Why that level:** no runner applies; the artefact is a record file and a set of derivations, and
  every criterion is a `grep`, a schema check on the record, or a fixture run.
- **Specific checks:** two fixture sprint records for AC3; a fixture transcript carrying a sentinel
  string for AC5, mirroring `tests/measurement.test.sh`; `grep` assertions for AC2 and AC6.

## Out of scope

- Computing the cost figures themselves. `tools/harvest-usage.sh`, `tools/classify-turns.sh` and
  `tools/cost-by-category.sh` already do that, and `0041` owns reporting them for a session. This
  ticket stores the **estimate**, pairs it with the actual, and feeds the next estimate.
- The session review's content and placement — `0041`.
- Choosing `0133`'s final threshold. This supplies the data; the decision is made when there is some.

## Notes & decisions

- **2026-09-09 — deliberately not folded into `0041`.** `0041` reports what a session delivered and
  what it cost, all of it actuals. The learning loop — an estimate recorded before the work, scored
  against the outcome, feeding the next estimate — is a different artefact with a different
  lifetime, and folding it in would have made `0041` unclosable until the loop existed.

### 2026-09-11 — Built (token 887a)

**The ticket's `expects:` named a file the `0129` rename had deleted, and `./next develop` offered
it anyway.** `skills/orchestrate/SKILL.md` is `skills/sprint/SKILL.md` since `bb8b778`;
`tests/orchestrate.test.sh` is `tests/sprint.test.sh`. `FINDINGS.md` had already recorded this about
this very ticket (2026-09-10, develop 0107) and no row was ever written for it, so the correction
was made here in `touches:` as Step 1 requires. Worth stating plainly because a stale `expects:`
path **defeats the file-scope check in the safe-looking direction**: a path that exists nowhere
collides with nothing, so the row reads as clear precisely when nobody can tell.

**0132 was the ranked row and was stepped over, not skipped.** It is `TAKE` at the top of
`./next develop`, and `0107` is `in-progress` at `next: verify` with an empty `touches:` whose
predicted scope includes `skills/verify/SKILL.md` — the file `0132` rewrites. `CONCURRENCY.md` says
to read an empty `touches:` on an in-progress row as *its files are held*. `0135` was the next
takeable row that avoided it.

**`--session` had to be added to `harvest-usage.sh` before FR3 was satisfiable**, and the reason is
in `MEASUREMENT.md` already: a date window is not a pin on a live store, and the window that
selected 30 sessions now returns 42. The `--run` bound needed the same narrowing for a
non-obvious reason — `report_run_bound` globs the whole transcript directory, so over a shared
store it reads its FLOOR off whichever session sorts first, which is very often not one of the
run's at all. That was a latent defect in `0039`'s bound, not something this ticket introduced.

**A ratio is three lines here and that is the whole design, not formatting.** `AC6` cannot be
checked on a ratio's own line: a pinned numerator over a live denominator is self-consistent on the
page and every citation still resolves. The guard asserts the *shape* — a `RATIO` line followed by a
stamped `numerator` and a stamped `denominator` — because that is the only property a reader
can be held to.

**The estimate model, stated so the next session can argue with it rather than reverse-engineer it.**
Dollars and tokens are `Σ over planned stages of (mean per session × (sessions + extra tickets))`,
at `MEASUREMENT.md`'s per-skill table means. A ticket beyond the first in a gate is charged the
**same** mean rather than nothing, because a gate's saving is the startup floor and not the work —
the same assumption `config.yml`'s `per_extra_ticket` makes, and `GATE` lines are what will falsify
it. `config.yml` is deliberately **not** the estimate's source: its figures are caps (mean × 1.5),
and estimating from a cap builds the safety margin into the expectation.

**Deliberate deviation from `CONVENTIONS_CORE.md`'s "Python with full type hints", recorded rather
than taken silently.** `tools/sprint-ledger.sh` is `sh` wrapping an inline `python3` heredoc with no
hints, matching `tools/harvest-usage.sh`, `tools/classify-turns.sh` and `tools/cost-by-category.sh`
— every tool in this directory. Typing this one alone would make it the outlier in a four-file set.
The trade is real and it is a preference rather than a principle; `verify` may reasonably disagree.

**What this ticket does NOT do, and it is visible in the ledger's shape.** `RETRO consumed …
produced …` is emitted only where the run log carries a `retro` outcome with a
`findings_consumed` field. No retro writes one today, so FR5's retro half is *derivable but not yet
sourced* — the line is absent rather than zero, which is the honest of the two. A ticket wanting the
figure needs `retro`'s outcome envelope to carry it, which is a change to
`skills/sprint/outcome.schema.json` and out of scope here.

**`qa_level` raised from `verify` to `unit` by this session, which is a correction and not a
preference.** The QA plan was written for "a record file and a set of derivations", where every
criterion is a grep or a fixture run — true of `tools/sprint-ledger.sh` and
`.claude/backlog/LEDGER.md`. It did not anticipate that FR3 is unsatisfiable without changing
`tools/harvest-usage.sh`, whose behaviour `tests/measurement.test.sh` owns and whose regression no
check named in this ticket's QA plan would run. At `verify` the pass would execute
`tests/sprint-ledger.test.sh` and stop; at `unit` this project runs every `tests/*.test.sh`, which
is the only level that covers the file this ticket edited but does not guard.

**Guard hygiene:** ten mutations, each applied to a committed tree, confirmed non-empty via
`git diff --quiet`, restored with `git checkout -- <one path>`, control run green after each. One
(M1) matched nothing on its first attempt and returned a clean pass — the substitution was written
against a line that does not wrap as assumed — and was re-run against the real text rather than read
as a green.

### 2026-09-11 — Sent back by verify (token 5f9c)

**FR8 is unmet on a reachable path: `record` writes a fabricated estimate instead of refusing.**
`tools/sprint-ledger.sh` `parse()` defaults `estimate_tickets` and `estimate_tokens` to `0`,
`estimate_usd` to `0.0` and `estimate_source` to the literal string `unsourced`. A `record` run with
any of those flags omitted therefore exits 0 and appends a committed block reading
`| usd | 0.00 | 16.00 | unsourced |` — a number in the estimate column that nobody estimated,
carrying a source that is an admission of having none, and no stamp. FR8 says *every* figure carries
the source it was read from and the stamp it was true at; `unsourced` is not a source, and the file's
own preamble is built on the observation that a figure of this shape decays **silently** while the
arithmetic on the page stays self-consistent. `CONVENTIONS_CORE.md` carries the same rule from the
other side — *validate inputs at the top, throw descriptive errors, never swallow failures silently*.

**The constraint: in `record` mode a missing `--estimate-tickets`, `--estimate-tokens`,
`--estimate-usd` or `--estimate-source` must `die()` naming the flag, the way `--ledger` already
does.** AC1 is what settles refuse rather than label: a record with no estimate cannot hold "an
estimate and an actual" for that figure, so there is nothing to label. `--estimate-wall no-prior`
stays as it is — that one is an **explicit declaration** the guard already accepts, which is exactly
what an omitted flag is not. The guard case is that `record` with a flag omitted exits non-zero and
names it; it belongs beside the AC1 block in `tests/sprint-ledger.test.sh`.

**And `paired()` cannot see this, which is why it survived to here.** It asserts a non-whitespace
estimate cell beside a numeric actual, so blanking the cell reddens four assertions while filling it
with `0.00` reddens none. Anchor the AC1 guard on the **source** column, which a default cannot
forge, rather than on the figure, which it trivially can. Parked as a finding.

**Everything else was checked and is green.** All six ACs hold on the documented path, each proved
falsifiable by a mutation at the AC's own altitude — see `## QA evidence`. The three NFR rows hold.
The `sh`-wrapping-`python3` deviation from *Python with full type hints* is **not** what sent this
back: the argument that retyping one of four sibling tools makes it the outlier is a fair one, but
`CONVENTIONS_CORE.md` enumerates *use types* among the principles rather than the preferences, so the
build note's "it is a preference rather than a principle" is wrong as written. That is a repo-wide
question about `tools/*.sh`, not this ticket's to settle — it needs its own row.

### 2026-09-11 — Re-entry built against the verify verdict (token ee4e)

**The bounce verdict was the specification and it named one remedy, so nothing here was chosen.**
Four flags refuse, `--estimate-wall` does not, and the AC1 guard re-anchors on the source column —
all three are the verdict's words. `parse()`'s defaults for `estimate_tickets`, `estimate_tokens`,
`estimate_usd` and `estimate_source` are now `None`, and `record` validates them before `record()`
runs, so nothing is appended to a committed ledger before the refusal. The message names the omitted
flag; `estimate` mode reads none of those four keys, so it is untouched.

**`--estimate-wall` stays optional, and the exception is now pinned rather than merely intended.**
Its default is `NO_PRIOR`, which is a declaration that no prior exists — the honest label AC2 asks
for — not a figure nobody supplied. Left unpinned, the next session reading "validate inputs at the
top" would widen the refusal to all five and turn AC2's own subject into an error; `AC2/FR8 — the one
estimate flag whose omission is a declaration` is the case that reds when that happens (proved: M4,
below).

**The tool's own usage block already declared all five flags mandatory.** This was not a missing
decision about the interface — the code simply did not enforce what its header documented, which is
why the defect reads as a default rather than as an option. No usage text changed.

**`paired()`'s re-anchor needed its own mutation, because the pre-fix mutation cannot reach it.**
M1 restores the forging defaults and reds the twelve refusal assertions — but `paired()` reads the
block produced by the *happy-path* run, which still passes `--estimate-source`, so it stays green
under M1. Proving the new `@`-stamp requirement falsifiable took M2, which strips the stamp from the
source column itself. Worth stating because the two mutations look interchangeable and are not: one
tests the refusal, the other tests the record.

**The refusal cases derive their subject list from `parse()`'s own defaults.** A guard enumerating
the four flags is green by construction the day a fifth estimate figure is added — the moment the
rule most needs it (`testing-conventions.md`, *a guard that enumerates its own subjects cannot notice
a new one*). The derivation carries the trap that comes with it: a filter matching nothing loops zero
times and passes, so there is an explicit non-empty assertion on the derived list, and M3 breaks the
`sed` range to prove it reds (`38 passed, 3 failed`) rather than silently passing.

**The assertion is on the message, not the exit status** (`testing-conventions.md`: *`exits
non-zero` is satisfied by the silent refusal the rule exists to forbid*), and separately on nothing
having been appended — a tool that dies *after* writing has already committed the fabrication.

**Mutation ledger** — each applied to a committed tree, diff confirmed non-empty, restored with
`git checkout -- <one path>`, control green after each (`53 passed, 0 failed`, tree clean):

| # | Mutation | Result |
|---|---|---|
| M1 | restore the pre-fix defaults (`0`/`0.0`/`unsourced`) and delete the validation loop | `41 passed, 12 failed` — the four flags × exit code, named flag, nothing appended |
| M2 | `src = "confirmed scope" if … else "unsourced"` — the source column loses its stamp | `49 passed, 4 failed`, each naming its row |
| M3 | the derivation's `sed` range aimed at a function that does not exist | `38 passed, 3 failed` — the non-empty assertion reds rather than looping zero times |
| M4 | widen the refusal to `--estimate-wall` as well | `29 passed, 24 failed` — AC2/FR8's exception case reds and names why; the large radius is the happy-path `record` refusing, so every assertion over `$BLOCK` follows |

**Unrelated red carried forward, not mine and already parked twice.** `tests/measurement.test.sh`
is `128 passed, 1 failed` on a home-directory path committed inside **closed** item `0052`'s QA
evidence table (line 294, commit `7fdd367`). It predates this work, names no file this ticket
touched, and the item is `status: done` — which `CONCURRENCY.md` makes the one kind of unclaimed item
a session may *not* append to. It also means `tools/release` step 5, which is fail-fast over the same
line, is currently red. Entries already exist at `FINDINGS.md` 2026-09-11 (develop 0144) and
2026-09-11 (verify 0135); no third was written.

**Everything else in the suite is green, run file-by-file rather than fail-fast** per `config.yml`'s
own note on `0084`: 30 files, 29 at `0 failed`. `tests/sprint-ledger.test.sh` `53 passed, 0 failed`
(pasted, not summed), up from 38.

**The `sh`-wrapping-`python3` deviation is left as the verdict left it.** The verdict is right that
`CONVENTIONS_CORE.md` enumerates *use types* among the principles rather than the preferences, so the
previous build note's "it is a preference rather than a principle" was wrong as written — and it is
right that the answer is repo-wide across `tools/*.sh` rather than this ticket's. Retyping one of
four sibling tools inside this ticket would make it the outlier without settling anything. Parked as
a finding; **it still needs a row**, and no row exists.

**0132 was the ranked row and was stepped over, not skipped** — for the second consecutive session,
on a different holder. `./next develop` printed `TAKE 0132` and, in the same breath,
`CLAIMED FILES … 0045 [7564] none declared; predicted by expects: skills/queue/templates/next
.claude/backlog/next tests/next.test.sh — assume held, ask`. That claim landed **between** this
session's two `./next develop` calls — the window `develop` Step 1 tells you to re-run for, and it
caught it. Already a parked finding (2026-09-10, develop 0107); not re-parked.

### 2026-09-11 — Sent back by verify (token 7a9b)

**The estimate side was repaired and the actual side has the identical defect, in the same
function.** `harvest()` runs `tools/harvest-usage.sh` with `check=False`, reads only stdout, and
returns `(0.0, 0)` when no `TOTAL` line matches — so a non-zero exit becomes a measurement of zero.
Observed, on the path `skills/sprint/SKILL.md` Step 6 documents:

```
$ tools/sprint-ledger.sh record --ledger … --run … --transcripts <dir that does not exist> \
    --estimate-tickets 2 --estimate-tokens 100 --estimate-usd 9.99 --estimate-source 'X @ …'
| usd    | 9.99 | 0.00 | X @ 2026-09-06T09:00:00Z |
| tokens |  100 |    0 | X @ 2026-09-06T09:00:00Z |
GATE develop 2 ticket(s) session aaaaaaaa: predicted USD 10.08 (…) observed USD 0.00
  (harvest-usage.sh over 1 session id(s) @ 2026-09-12T04:28:09Z)
exit=0
```

`harvest-usage.sh` itself behaves correctly — `no such transcript directory: …`, exit 2. The
swallow is entirely on this side. This is worse than the defect that bounced the ticket on
2026-09-11: `unsourced` was at least an admission, where `harvest-usage.sh over 1 session id(s) @
<stamp>` is a **false citation** — a source named for a number that source never produced, which is
precisely the silent decay `LEDGER.md`'s own preamble and `0051` exist to prevent. AC1 fails on this
path (a fabricated zero is not an actual, by the same reading the previous verdict applied to the
estimate column), FR8 fails (the figure carries a source it was not read from), and
`CONVENTIONS_CORE.md`'s *validate inputs at the top; throw descriptive errors; never swallow
failures silently* is breached.

**Constraint 1 — `harvest()` must `die()` rather than return a figure, on both of its swallows:**
the subprocess exiting non-zero, and stdout carrying no parsable `TOTAL` line. The message names the
command's exit status and its stderr, the way `read_run`, `read_config` and `read_measurement`
already `die()` on a missing input. AC1 settles refuse rather than label, on the previous verdict's
own reasoning: a record that cannot hold an actual for a figure cannot hold "an estimate and an
actual" for it, so there is nothing to label. **Do not widen this to the empty store**: a real
directory holding none of the run's sessions makes `harvest-usage.sh` exit 0 with a `TOTAL` line
reading `0.00`, which is a measured zero and must keep recording as one. Neither fix touches it.
The guard case is `record` against a missing `--transcripts` directory exiting non-zero and naming
the harvest failure, with nothing appended — beside the existing refusal block.

**Constraint 2 — the AC6 guard cannot see an absent denominator, and the fix is an `END` block.**
`RATIOBAD`'s awk reports a missing side only from inside the `/^ *denominator /` rule. Deleting the
numerator line reds it (`52 passed, 1 failed`); deleting the **denominator** line is invisible
(`53 passed, 0 failed`) — nothing runs, so nothing prints. A ratio with a numerator and no
denominator at all satisfies AC6's *"Red if either is bare"* less than a bare one does, and the
guard is green on it. Report the pending `RATIO` when the next anchor or EOF arrives. The product is
correct today: `record` appends all three lines unconditionally, so this is guard coverage, not a
live defect — but it is the assertion AC6 rests on.

**Everything else was re-checked from this session's own evidence and is green**, including the
four refusals the last bounce asked for, each proved falsifiable by restoring the pre-fix defaults
(`41 passed, 12 failed`). Eleven mutations, table in `## QA evidence`. The `sh`-wrapping-`python3`
deviation is left exactly where the previous verdict left it — repo-wide across `tools/*.sh`, owed
its own row, still without one, and **not** what sends this back.

**One observation that is not a constraint and must not be built as one.** `--estimate-source`
accepts any string, so a caller passing one without an `@` stamp writes an unstamped source column
and no AC catches it. No AC requires the tool to validate the format of a source its caller
supplies, and `paired()` asserting the stamp on the fixture is the coverage the ticket scoped.
Recorded so the next pass does not rediscover it as a defect.

### 2026-09-12 — Re-entry built against the 2026-09-11 verify verdict (token 0db6)

**Both constraints named one remedy each, so nothing here was chosen.** `harvest()` now `die()`s on
each of its two swallows, and the AC6 guard reports a pending ratio from a flush. The one
observation the verdict marked as *not* a constraint — `--estimate-source` accepting a string with
no `@` stamp — was left alone, as it said.

**The exception is the load-bearing half of Constraint 1, and it now has its own case.** A real
directory holding none of the run's sessions makes `harvest-usage.sh` exit 0 with a `TOTAL` line
reading `0.00`. That is a *measured* zero. Probed before building: an empty dir gives exit 0 and
that line; a missing dir gives exit 2 and `no such transcript directory: …` on **stderr**, stdout
empty. Without a case pinning the empty store, the next session reading *validate inputs at the
top* widens the refusal and turns a real measurement into an error — proved by M3, which reds the
exception case and names why.

**The verdict named two swallows and only one is reachable through the real `harvest-usage.sh`.**
The non-zero exit is exercised with a missing directory. The second — exit 0 with no parsable
`TOTAL` — cannot be produced by the real tool, so it is exercised against a **copy** of
`sprint-ledger.sh` placed beside a stub `harvest-usage.sh`, `HARVEST` being resolved relative to
the tool's own directory. The copy is made fresh from `$TOOL` on every run, so it cannot drift from
the subject under test. Guarding only the reachable swallow would have left the other as an
assertion nobody ever ran.

**The refusal quotes the output it could not parse, and the first attempt did not.** Joining
`stdout.split()[:20]` with `" / "` shreds the text across word boundaries, so an assertion on a
phrase the stub printed could not match it — the guard caught the message's own unreadability.
Newlines now collapse to `; ` and the quote is truncated at `HARVEST_QUOTE_CHARS`. *"printed no
parsable TOTAL line"* with nothing after it is unactionable, and a format change is the likeliest
cause.

**Constraint 2 is guard coverage, and the fix is checked by cases rather than by a mutation ledger
entry.** `ratio_bad()` is now a function, and five synthetic fixtures run against it before it is
trusted on the recorded block: a fully stamped ratio, an unstamped denominator, an unstamped
numerator, a missing denominator line, and a missing denominator **followed by another `RATIO`** —
the last because `END` alone would have caught only the final ratio in the file and the guard would
still have been blind everywhere else. The previous pass's M10 (delete the denominator line →
`53 passed, 0 failed`, no redden) is what this replaces.

**Mutation ledger** — each applied to a committed tree, `git diff --quiet` confirming it landed,
restored with `git checkout -- <one path>`, control green after each (`68 passed, 0 failed`, tree
clean):

| # | Mutation | Result |
|---|---|---|
| M1 | restore `harvest()`'s two swallows — drop the exit-status `die()` and revert the no-`TOTAL` `die()` to `return 0.0, 0` | `61 passed, 7 failed` — both refusals, their messages, and nothing-appended |
| M2 | restore the old `RATIOBAD` awk, printing only from inside the `/^ *denominator /` rule | `66 passed, 2 failed` — the two missing-denominator cases, and only those |
| M3 | widen the refusal onto the empty store (`die` when stdout says `0 sessions`) | `65 passed, 3 failed` — the exception case reds and names why it is a measurement |

**The whole suite is green, run file-by-file rather than fail-fast** per `config.yml`'s note on
`0084`: 30 files, every one at `0 failed`. **The `tests/measurement.test.sh` red that two previous
passes carried forward is gone** — `129 passed, 0 failed`. It was a home-directory path committed
inside closed item `0052`'s QA evidence; something has since removed it, so `tools/release` step 5
is no longer red on that line. Not this session's doing and not this ticket's, recorded because two
passes reported it as outstanding.

**Still owed a row, and still without one: the `sh`-wrapping-`python3` typing question across
`tools/*.sh`.** Left exactly where both previous verdicts left it — repo-wide, not this ticket's to
settle, and not what this session changed. `CONCURRENCY.md` forbids this stage from filing it. It
**needs a row**; there is none.


## QA evidence

### 2026-09-12 — verify pass, token 99e3 (PASS)

Verified at `qa_level: unit`, the frontmatter's level and the only one the item declares. **The QA
plan's rationale is stale, not drift:** it still opens *"no runner applies"* — the argument for
`verify` — because the raise to `unit` never rewrote it, but the item carries no second `**Level:**`
line, so `tests/qa-level-once.test.sh` is green and Step 2's drift rule has nothing to fire on. Two
prior verdicts recorded these as agreeing; they do not. Parked as a finding rather than fixed here.

`commands.unit` is `for t in tests/*.test.sh`, run file-by-file rather than fail-fast per
`config.yml`'s note on `0084`. No `lint` or `typecheck` is configured. Repo checkout at `f2c9a30`,
working tree clean at Step 2 and clean again at the verdict, so the dirty set is empty and its
intersection with the evidence set is empty — **not advisory**. Artefacts were executed from the
**repo copy**, not the installed plugin: both suites invoke `tools/sprint-ledger.sh` and
`tools/harvest-usage.sh` by repo path.

Evidence set: `tools/sprint-ledger.sh`, `tests/sprint-ledger.test.sh`, `tools/harvest-usage.sh`,
`.claude/backlog/LEDGER.md`, `skills/sprint/SKILL.md`, `.claude/backlog/config.yml`, `MEASUREMENT.md`.

Every mutation below was applied to a committed tree, confirmed landed with `git diff --quiet`,
restored with `git checkout -- <the one path mutated>`, and followed by a control run — green at
`68 passed, 0 failed` with the tree clean each time. Tallies are pasted from the run that produced
them, never summed.

| # | How it was checked | Result |
|---|---|---|
| AC1 — an estimate and an actual for all four figures | `tests/sprint-ledger.test.sh` `paired()` over the recorded block, the derived estimate-flag refusal block, and the harvest-refusal block. **N1** restore `parse()`'s forging defaults (`0`/`0`/`0.0`/`unsourced`) in place of the validation loop → `56 passed, 12 failed`, each naming its flag, its exit code and that a block was appended before refusing. **N2** strip the `@` stamp from the source column (`src = "confirmed scope" … else "unsourced"`) → `64 passed, 4 failed`, one per figure row — this is the re-anchor the 2026-09-11 verdict asked for, and it catches what `paired()`'s old figure-anchor could not. **N3** restore `harvest()`'s two swallows → `61 passed, 7 failed` | PASS |
| AC2 — a figure with no prior is labelled, not presented as derived | Same suite, AC2 block. **N4** emit `wall_clock_min` as `90.0` sourced to the `MEASUREMENT.md` per-skill table, exactly as the dollar figure is → `67 passed, 1 failed`, *"the wall-clock figure is not marked as having no prior"*. The omitted-`--estimate-wall` exception case stayed green under N1 and N3, which is what keeps a declaration distinguishable from a forged figure | PASS |
| AC3 — the third sprint estimates from the ledger, not the priors | Same suite, two-recorded-sprint fixture. **N5** `sprints = read_ledger(...)` → `sprints = []`, the ledger written but never read → `65 passed, 3 failed`, including the value assertion (300 min derived from the two recorded actuals) and the dollar estimate falling back to citing the priors | PASS |
| AC4 — predicted beside observed for a multi-ticket gate | Same suite, `GATE` block. **N6** emit the `GATE` line keeping its shape, its session and its observed cost but dropping the prediction → `66 passed, 2 failed` — precisely the AC's own *"Red if only the observed cost is recorded"*. The prediction is independently recomputed against `config.yml`'s model at n=3: `6.05 + 4.03 × 2 = 14.11`, against the gate session's observed `10.00` | PASS |
| AC5 — no message text reaches the ledger | Same suite: a `SENTINELPROSE` sentinel planted in the fixture transcript, plus a character-set sweep over every generated line. **N7** leak each transcript `text` field into the block → `67 passed, 1 failed` on the sentinel check. **N8** leak the same prose JSON-quoted with the sentinel substituted out, so only the character-set check can see it → `67 passed, 1 failed` on that check. Neither mutation alone reddens both, so the two assertions are independently load-bearing. N7's first attempt crashed the tool instead of leaking (a `str` in the content list); a crash is not the redden under test, so it was repaired and re-run rather than read as a result | PASS |
| AC6 — both sides of every ratio carry a source and a stamp | Same suite, `ratio_bad()` plus its five self-test fixtures. **N9** restore the pre-fix `RATIOBAD` awk, which printed only from inside the `/^ *denominator /` rule → `66 passed, 2 failed`, and **only** the two missing-denominator cases — the shape the 2026-09-11 verdict found the guard blind to. **N10** drop `(%s @ %s)` from the product's denominator line → `67 passed, 1 failed` on the real block. The guard proves itself against its own defect shapes before it is trusted, which is stronger than a mutation-ledger entry | PASS |
| Constraint 1 (2026-09-11 verdict) — `harvest()` must `die()` on both swallows | Read at `tools/sprint-ledger.sh:336-368`: non-zero exit dies naming the basename, the exit status, the transcripts path and the stderr; unparsable stdout dies quoting the output it could not parse, newline-collapsed and truncated at `HARVEST_QUOTE_CHARS`. N3 reddens both refusals, their messages and the nothing-appended assertions. **The exception the verdict marked load-bearing holds**: an empty store still records a measured `0.00` and is not refused — its case stayed green under every mutation above | **Met** |
| Constraint 2 (2026-09-11 verdict) — the AC6 guard must see an absent denominator | N9 above. Reported from a flush on the next `RATIO` anchor or `END`, so a missing denominator mid-file is caught and not only the last ratio's | **Met** |
| FR8 — every figure carries its source and stamp, both sides of every division | N2 (source column), N10 (denominator stamp), N1 (the `unsourced` default that bounced this ticket on 2026-09-11), N3 (the false `harvest-usage.sh` citation that bounced it on 2026-09-12). All four now redden | PASS |
| NFR Privacy & data (`data-privacy-conventions.md`) | AC5 above, plus `grep -nE '/Users/\|/home/[a-z]\|~/'` over all seven files in the evidence set — no match. The one egress path (transcripts → a committed public file) emits aggregates, stage names, given paths and 8-char session-id prefixes only. `tests/measurement.test.sh` green at `129 passed, 0 failed` | PASS |
| NFR Performance (`observability-conventions.md`) | Two call sites in `skills/sprint/SKILL.md` — `estimate` at the proposal (line 128) and `record` at Step 6 (line 377); the third mention (line 314) is prose. Nothing per cycle, and wall-clock is read from stamps the run log already carries | PASS |
| NFR Documentation (`documentation-conventions.md`) | The block carries an `Estimate source` column; every `ESTIMATE` line a `source: … @ <stamp>`; `LEDGER.md`'s own preamble states the rule and why a three-line ratio exists. Both previously-reported exceptions are closed — the `unsourced` default refuses, and the actual column can no longer carry a citation for a figure its source never produced | PASS |
| Always-on (`CONVENTIONS_CORE.md`) | *Validate inputs at the top; throw descriptive errors; never swallow failures silently* — **now satisfied**; the four estimate flags and both harvest swallows refuse, each message naming what was missing. *Use types* — the `sh`-wrapping-`python3` deviation stands exactly where both previous verdicts left it: a repo-wide question across `tools/*.sh`, owed its own row, **still without one**, and not this ticket's to settle. It does not block this close | PASS |
| Newly reachable states (Step 4) | The re-entry only *narrows* — it converts two silent successes into refusals — and adds no routing, permission or visibility change. No new destructive or privileged path is reachable | PASS |
| Whole suite (`commands.unit`) | 30 files run individually at `f2c9a30`; **every one at `0 failed`**. `tests/sprint-ledger.test.sh` `68 passed, 0 failed`; `tests/sprint.test.sh` `187 passed, 0 failed, 0 skipped`; `tests/measurement.test.sh` `129 passed, 0 failed` — the home-directory red two earlier passes carried forward is confirmed gone. Each tally pasted from its own run | PASS |


### 2026-09-11 — verify pass, token 7a9b (FAIL)

Verified at `qa_level: unit` (frontmatter and the QA plan agree; no drift). `commands.unit` is run
file-by-file rather than fail-fast, per `config.yml`'s own note on `0084`. Repo checkout clean at
Step 2 (`ec50dd1`) and clean at the verdict (`eeea581` — another session landed `0147` during the
pass, touching none of this ticket's six files), so the dirty set is empty and its intersection with
the evidence set is empty: **not advisory**. Artefacts were executed from the **repo copy**, not the
installed plugin — both suites invoke `tools/sprint-ledger.sh` and `tools/harvest-usage.sh` by repo
path.

Evidence set: `tools/sprint-ledger.sh`, `tests/sprint-ledger.test.sh`, `tools/harvest-usage.sh`,
`.claude/backlog/LEDGER.md`, `skills/sprint/SKILL.md`, `.claude/backlog/config.yml`, `MEASUREMENT.md`.

| # | How it was checked | Result |
|---|---|---|
| AC1 — an estimate and an actual for all four figures | `tests/sprint-ledger.test.sh` `paired()` plus the derived refusal block. **M1** restore `parse()`'s pre-fix defaults and delete the validation loop → `41 passed, 12 failed` (four flags x exit code, named flag, nothing appended). **M2a** blank the Estimate cell → `48 passed, 5 failed`. **M2b** strip the `@` stamp from the source column → `49 passed, 4 failed`. Then run directly against a missing `--transcripts` directory | **FAIL** — green on every documented path, but `record` against a missing transcripts dir exits 0 and appends `\| usd \| 9.99 \| 0.00 \|`, an actual nobody measured. See the send-back note |
| AC2 — a figure with no prior is labelled, not presented as derived | Same suite, AC2 block. **M3** `emit("wall_clock_min", None, …)` → `emit(…, 90.0 * tickets, "MEASUREMENT.md per-skill table")` → `52 passed, 1 failed`, *"the wall-clock figure is not marked as having no prior"*, with the dollar figure still citing `MEASUREMENT.md` so the two stay distinguishable. The omitted-`--estimate-wall` exception is pinned by its own case and stayed green | PASS |
| AC3 — the third sprint estimates from the ledger, not the priors | Same suite, two-recorded-sprint fixture. **M4** `read_ledger` reads the Estimate column where it should read the Actual → `51 passed, 2 failed` (the value assertion, 300 min/2 tickets, is what catches it). **M5** `sprints = []`, the ledger written but never read → `50 passed, 3 failed` | PASS |
| AC4 — predicted beside observed for a multi-ticket gate | Same suite, `GATE` block. Prediction independently recomputed from `config.yml`: `6.05 + 4.03 x 2 = 14.11` at n=3, against the gate session's observed `10.00`. **M6** drop the prediction, keep the line's shape and its observed cost → `51 passed, 2 failed` — exactly the AC's own *"Red if only the observed cost is recorded"* | PASS |
| AC5 — no message text reaches the ledger | Same suite, sentinel `SENTINELPROSE` in the fixture transcript plus a character-set sweep of every generated line. **M7** emit the assistant `text` field → sentinel check reds. **M8** emit the raw transcript line, which carries no sentinel → character-set check reds. Each `52 passed, 1 failed`; neither mutation alone catches both shapes | PASS |
| AC6 — both sides of every ratio carry a source and a stamp | Same suite, structural `awk` over `RATIO` / `numerator` / `denominator`. **M9** drop `(%s @ %s)` from the denominator → `52 passed, 1 failed`. **M11** delete the numerator line → `52 passed, 1 failed`. **M10** delete the **denominator** line → `53 passed, 0 failed` — **no redden** | **PASS with an uncovered shape**, published rather than papered over: the product emits all three lines unconditionally so AC6 holds today, but the assertion it rests on is blind to an absent denominator. Constraint 2 in the send-back note; parked as a finding |
| FR3 — actuals over a session-id set, not a date window | Fixture store of three sessions totalling USD 36.00, of which the run owns two; `--session` returns 16.00. **M12** `if opts["session"] and …` → `if False and …` in `harvest-usage.sh` → `49 passed, 4 failed` here. Note `tests/measurement.test.sh` stayed `129 passed, 0 failed` under M12, so this suite is the only guard on `--session` | PASS |
| FR2 — wall-clock from the run log's own UTC timestamps | 09:00:00Z to 14:00:00Z recorded as 300 minutes; asserted on the row, and no new instrumentation was added | PASS |
| FR5 / FR7 — findings parked, verify cost per ticket batched vs unbatched | `FINDINGS parked 5` (3 + 2 summed from the run's outcomes) and `RATIO verify_usd_per_ticket batched … = 2.00` (USD 6.00 over three tickets), both asserted on value | PASS |
| NFR Privacy & data (`data-privacy-conventions.md`) | AC5 above, plus `grep -nE '/Users/\|/home/[a-z]\|~/'` over the ticket's six files — no match; `tests/measurement.test.sh`'s repo-wide sweep for home paths and configured organisation names green at `129 passed, 0 failed`. The new egress path (transcripts → a committed public file) emits aggregates, stage names and 8-char session-id prefixes only | PASS |
| NFR Performance (`observability-conventions.md`) | Two call sites in `skills/sprint/SKILL.md` — one `estimate` at the proposal (line 128), one `record` at Step 6 (line 370). Nothing per cycle | PASS |
| NFR Documentation (`documentation-conventions.md`) | The block carries an `Estimate source` column and every `ESTIMATE` line a `source: … @ <stamp>`; the previous pass's `unsourced` exception is closed. But the **actual** column's citation can now be false — see AC1 | **FAIL**, on the actual side rather than the estimate side |
| Always-on (`CONVENTIONS_CORE.md`) | *Validate inputs at the top; throw descriptive errors; never swallow failures silently* — **breached** by `harvest()`'s `check=False` and its bare `return 0.0, 0`. *Use types* — the `sh`-wrapping-`python3` deviation stands where the last verdict left it: repo-wide, owed its own row, not this ticket's to settle and not what sends it back | **FAIL** on input validation |
| Newly reachable states (Step 4) | The change adds one egress path (transcripts → a committed public file) and no routing, permission or visibility change. The egress is what the privacy NFR and AC5 cover | PASS |
| Whole suite (`commands.unit`) | 30 files run individually; every tally pasted from its own run. `tests/sprint-ledger.test.sh` `53 passed, 0 failed`; `tests/measurement.test.sh` `129 passed, 0 failed` — the home-directory red the previous pass carried forward is gone. No file red. Re-run at the verdict after `0147` landed: unchanged | PASS |


Verified at `qa_level: unit` (frontmatter and QA-plan prose agree after the raising commit `0591f3b`;
no drift). Repo checkout at `514b119`, working tree clean at Step 2 and clean again at the verdict,
so the dirty set is empty and the intersection with the evidence set is empty — **not advisory**.
Artefacts were read and executed from the **repo copy**, not the installed plugin: the suites invoke
`tools/sprint-ledger.sh` and `tools/harvest-usage.sh` by repo path. The installed 0.9.25 tree does
differ from the checkout for eight skill files, which is expected between releases and affects
nothing here.

| # | How it was checked | Result |
|---|---|---|
| AC1 — estimate and actual for all four figures | `tests/sprint-ledger.test.sh` `paired()` over the recorded block. Mutation: drop the Estimate cell from every figure row → `34 passed, 4 failed`. Control `38 passed, 0 failed` | **FAIL** — green on the documented path, but the guard cannot see the red the AC names: defaulting `--estimate-usd` to `0.00` leaves the run at `38 passed, 0 failed` while the estimate column holds a figure nobody estimated |
| AC2 — a figure with no prior is labelled, not presented as derived | Same suite, AC2 block. Mutation: `emit("wall_clock_min", None, …)` → `emit("wall_clock_min", 99, …)` → `37 passed, 1 failed`, *"the wall-clock figure is not marked as having no prior"*, with the dollar figure still citing `MEASUREMENT.md` so the two stay distinguishable | PASS |
| AC3 — the third sprint estimates from the ledger, not the priors | Same suite, two-recorded-sprint fixture. Mutation: `if sprints and total_tickets > 0:` → `if False and total_tickets > 0:` → `35 passed, 3 failed` | PASS |
| AC4 — predicted beside observed for a multi-ticket gate | Same suite, `GATE` block; prediction asserted as `config.yml`'s model at n=3, `6.05 + 4.03 × 2 = 14.11`, against the gate session's observed `10.00`. Mutation: emit the `GATE` line keeping its shape but dropping the prediction → `36 passed, 2 failed` | PASS |
| AC5 — no message text reaches the ledger | Same suite, sentinel `SENTINELPROSE` planted in the fixture transcript, plus a character-set sweep of every generated line. Two mutations: emitting the raw transcript line reddens the character-set check; emitting the assistant `text` field reddens the sentinel check. Each `37 passed, 1 failed`. Neither alone catches both shapes | PASS |
| AC6 — both sides of every ratio carry a source and a stamp | Same suite, structural `awk` over `RATIO` / `numerator` / `denominator`. Mutation: drop `(%s @ %s)` from the denominator line → `37 passed, 1 failed`, *"a ratio is missing a stamped side"* | PASS |
| NFR Privacy & data (`data-privacy-conventions.md`) | AC5 above, plus `grep -nE "/Users/\|/home/[a-z]"` over all six files the ticket touched — no match. The new egress path (transcripts → a committed public file) emits aggregates, stage names and 8-char session-id prefixes only | PASS |
| NFR Performance (`observability-conventions.md`) | Three `sprint-ledger.sh` mentions in `skills/sprint/SKILL.md`, two of them call sites: one `estimate` at the proposal, one `record` at Step 6. Nothing per cycle | PASS |
| NFR Documentation (`documentation-conventions.md`) | The block carries an `Estimate source` column and every `ESTIMATE` line a `source: … @ <stamp>` — except on the defaulted path, where the source reads `unsourced`. Covered by the FR8 finding above | PASS with the FR8 exception |
| FR1/FR4 prose in `skills/sprint/SKILL.md` | `says()` assertions over the proposal and Step 6 sections. Mutation: *"estimate is written to the ledger before the first dispatch"* → *"… at some point"* → reddens *"nothing says the estimate is written before the work"* | PASS |
| FR3 — actuals over a session-id set, not a date window | Fixture store of three sessions totalling USD 36.00, of which the run owns two. `harvest-usage.sh --session` returns 16.00 and the unrelated session never reaches the total | PASS |
| Always-on (`CONVENTIONS_CORE.md`) | *Validate inputs at the top; throw descriptive errors; never swallow failures silently* — **breached**, see FR8 above. *Use types* — deviation documented in the build notes; flagged, not blocked on, and owed its own row | **FAIL** on input validation |
| Whole-suite run (`commands.unit`) | All 33 files run individually rather than fail-fast, per `config.yml`'s own note. Every file green except `tests/measurement.test.sh` at `128 passed, 1 failed`, whose red is a home-directory path committed by **another ticket's** close (`7fdd367`, item `0052` line 294) and touches nothing in this ticket. Parked as a finding; it also means `tools/release` step 5 is currently red | PASS for this ticket |
