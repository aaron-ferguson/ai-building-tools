---
id: "0132"
title: Let verify batch within a gate that was developed together, with per-ticket evidence
type: feature
next: verify
status: ready
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: ["0059"]
relates: ["0131", "0054"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - skills/verify/SKILL.md
  - skills/orchestrate/SKILL.md
  - .claude/backlog/config.yml
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The tool and the cost model disagree about whether verify batches, and neither is documented as
the answer.** `--drive` dispatches one ticket at a time — `decide "$DISPATCH" "DISPATCH verify
$id"` — while `config.yml` carries `stage_budget_usd.per_extra_ticket.verify: 3.63`, a figure that
only means anything if a verify session can hold more than one ticket. The skill's prose sides with
the tool: *"A ticket left at `next: verify, status: ready` gets a **new** process running `verify`
on it."*

**On a thirteen-ticket gate that difference is thirteen session floors.** A stage pays roughly 20k
tokens before it writes a line, and the whole justification for gating develop is that those
tickets share it. The tickets that shared a develop session share exactly the same files at verify —
they were grouped on `expects:` overlap in the first place — so the re-read is the same re-read.
Aaron, 2026-09-08: *"Verify should batch when it is token-efficient to do so."*

**But verify's independence is the property being spent, and this project's priority order is
quality first.** Two risks, both concrete:

- **Halo.** Several verdicts in one context, where the first is green, is how the second gets read as
  green. The two recorded times the independent gate bit in this repo, it bit on AC quality rather
  than on code — exactly the judgement a shared context erodes.
- **Misattributed red.** `config.yml`'s own note records this happening: verifying `0084`, the
  fail-fast `unit` command stopped at `backlog-scripts-installed.test.sh` — alphabetically first of
  seventeen — which was red from *another session's* in-flight work, so `tests/release.test.sh`, the
  guard that verdict actually rested on, never ran. Sixteen were green. A batched verify multiplies
  the number of tickets one such red can wrongly condemn.

`0059` is the design question that governs this — it asks what the batching rule's condition is, and
separately *"what isolates one ticket's Step 3 mutation from another ticket's suite run inside the
same session?"* That is the same mutation-isolation problem, and this ticket cannot be specified
around it.

## Functional requirements

Written against whatever `0059` settles; these hold regardless of which shape it picks.

- FR1 — A verify session may hold more than one ticket only where those tickets were **developed
  together in one gate**. Tickets that merely happen to sit at `next: verify` are not thereby one
  batch.
- FR2 — The outcome envelope carries one array entry per ticket with its own verdict, as the schema
  already requires; a batched session produces per-ticket verdicts, never one verdict spread over
  several ids.
- FR3 — Each ticket's `## QA evidence` section is written with its own per-AC table. A shared table
  covering the batch does not satisfy this.
- FR4 — A red is attributed to a named ticket before any verdict is written. The suite is run
  file-by-file — `for t in tests/*.test.sh; do "$t" || true; done` — rather than fail-fast, per
  `config.yml`'s recorded reason.
- FR5 — Where a red cannot be attributed to one ticket in the batch, the session reports that rather
  than distributing it, and the affected tickets are left open.
- FR6 — `--drive` selects the batch and states it, so the tool and the rule agree; the shipped
  template `skills/queue/templates/next` receives the same change.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The saving claimed is session floors, and it is measured rather than asserted — `0135`'s ledger records verify cost per ticket batched against the single-ticket baseline | `observability-conventions.md` |
| Documentation | The independence risk and the attribution rule are stated in `skills/verify/SKILL.md` where a verify session reads them, not only here | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given three tickets developed in one gate and left at `next: verify`, when `--drive`
      runs, then it dispatches one verify session naming all three. **Red if** it dispatches one id,
      which is today's behaviour.
- [ ] AC2 — Given three tickets at `next: verify` that were **not** developed together, when
      `--drive` runs, then it dispatches them separately. **Red if** the batch condition is written
      as "any rows at the stage", which FR1 rejects.
- [ ] AC3 — Given a completed batched verify, when each ticket's item file is read, then each holds
      its own `## QA evidence` table naming its own ACs. **Red if** one table names ACs from more
      than one ticket.
- [ ] AC4 — Given a batch in which one ticket's guard is red and the others' are green, when the
      session reports, then the red is attributed to that ticket and the others still receive their
      own verdicts. **Red if** a fail-fast run is used, which stops at the first red and leaves the
      remaining tickets unverified while reading as though the batch failed.
- [ ] AC5 — Given a red that no ticket in the batch owns — another session's in-flight work — when
      the session reports, then it reports the red as unattributed and closes none of them. **Red
      if** it is charged to the alphabetically-first ticket, which is the `0084` failure repeated.
- [ ] AC6 — Given the repo after this ticket, when `diff .claude/backlog/next
      skills/queue/templates/next` runs, then they are identical. **Red if** only this project's
      copy is changed.

## QA plan

- **Why that level:** no runner covers a dispatch rule plus a prose contract, but each criterion is
  mechanical — `--drive` against fixtures for AC1, AC2 and AC6, and a fixture batch with a planted
  red for AC4 and AC5.
- **Specific checks:** `tests/next.test.sh` for the selection; a fixture with one deliberately red
  guard for the attribution cases; `tests/sprint.test.sh` for FR3's statement in the verify skill.

## Out of scope

- Deciding the batching rule's condition, or how one ticket's mutation is isolated from another's
  suite run. Both are `0059`.
- Changing how develop gates are formed.
- Worktree-per-ticket isolation, which `0059` may propose and `0137` would carry.

## Notes & decisions

- **2026-09-09 — blocked on `0059` after reading it rather than assuming.** The interaction was first
  recorded here as merely related; `0059`'s open question turns out to name both halves of this
  ticket — the batch condition and the mutation isolation — so specifying this one first would have
  pre-empted a decision that is explicitly still open.

### 2026-09-12 — Built (token `0a54`)

**Two of the six FRs were already discharged when this session opened, and both were re-verified at
the source rather than taken from the ticket.** FR1's condition — a verify batch is the develop gate
that produced it — landed in `skills/verify/SKILL.md` with `0059` on 2026-09-10, the blocker this
ticket waited on; `grep -c 'developed together in one gate'` returns 1. FR2's per-ticket envelope
entry was already required by `skills/sprint/outcome.schema.json`, whose own description says the
envelope is an array *because* a gate handles several tickets and a singular shape "reports one
verdict and silently drops the rest". So FR1 and FR2 were confirmed and cited, not rebuilt. What
this ticket actually had to add was the selection (FR6), and the three rules a batched session needs
that nothing had yet written down (FR3, FR4, FR5).

**FR4's home is not `config.yml`, and changing it there would have broken a release gate.** The FR
quotes `for t in tests/*.test.sh; do "$t" || true; done` and cites `config.yml`'s recorded reason —
which reads as an instruction to change the `unit:` command. It is not: `config.yml`'s own note says
the fail-fast `|| exit 1` form is *deliberate* because `tools/release` step 5 uses the same line as a
release gate, where stopping at the first red is right. The two readers want opposite behaviour from
one key, and the file already says so. The rule therefore went into `skills/verify/SKILL.md` as an
instruction to the session, generically — "run the level so that every file reports … where
`config.yml` records the reporting form of its own command, use that form here and leave the
configured one alone". `config.yml` was dropped from `touches:` for this reason.

**How `--drive` recovers the gate: two filters, and each is independently load-bearing.**
`verify_batch()` intersects the run's `--started` set (does this run's own work include it — an
INPUT, never derived, per `0131` FR5) with `gate_from` (which gate). Dropping the first admits the
stale verify row `0131` excludes; dropping the second batches two unrelated gates because the run
happened to open both. Both were mutation-proved: N1 removed the `--started` filter and reddened
exactly the two AC2 cases; N2 replaced `gate_from` with the raw pool and reddened only the
separate-gates case. Recovering membership with `gate_from` — the same grouping that formed the gate
at dispatch, replayed over a pool that is now a subset of it, in the same rank order — is what makes
the two ends of the cycle agree by construction rather than by a second rule that can drift.

**The `--completed` → `--started` join had to move ahead of the routing block, and this was not
visible in any test until the batch existed.** `--completed develop:0102` joins `0102` to the started
set, but that join sat *after* the block that routes a develop hand-off to verify. Once that branch
started selecting a batch, the one ticket `--completed` names was absent from the pool at exactly the
moment its own gate was being assembled, so every batch was missing its lead. Mutation N3 shows the
two dispatch sites are independent: reverting the rank walk alone left the `--completed` branch
batching correctly.

**Every DISPATCH assertion added here is an exact line, and that is not style.**
`assert_contains "DISPATCH  verify 0102"` is satisfied by `DISPATCH  verify 0102 0103 0104`, so it
cannot tell a batch from a single row — which is the only distinction this whole ticket makes. A new
`assert_eq` helper carries them. The pre-existing `0131` cases still use `assert_contains`; they are
not wrong and `0132`'s cases cover the regression, so they were left alone rather than rewritten —
parked in `FINDINGS.md` instead.

**NFR Performance claims nothing, deliberately.** The row says the saving is *measured* by `0135`'s
ledger, and `0135` is still `next: develop, status: ready` — so no figure exists yet and none is
asserted here. `tests/sprint-ledger.test.sh` FR7 already guards that the ledger block carries a
`verify_usd_per_ticket` ratio distinguishing batched from unbatched, and it is green against its own
authored fixture. A QA pass should not look for a number in this ticket.

**`expects:` named `skills/orchestrate/SKILL.md`, which `0128` renamed to `skills/sprint/`.**
`./claim` caught it at claim time and said so; `touches:` was narrowed to the real path, and
`tests/sprint.test.sh` was added, which the ticket's own QA plan names for FR3 but `expects:` omitted.

**Evidence.** Whole suite run file-by-file, not fail-fast: 30 files, every one exit `0`, every tally
`0 failed` (`tests/next.test.sh` 428 passed; `tests/sprint.test.sh` 187 passed, 0 skipped — the
`claude -p` probe ran). Seven mutations in total, each applied to a committed tree, confirmed
non-empty with `git diff --stat`, restored with `git checkout -- <one path>`, and followed by a
control run: prose M1–M4 gave 1, 2, 1 and 2 failures against a 187/0 control; script N1–N3 gave 2, 1
and 4 against a 428/0 control. `git status --porcelain` empty after each sweep. Baseline commit
`f8854a8`.

**Substitution in the QA plan, recorded because the next QA pass reads the plan and not this note.**
The plan asks for "a fixture with one deliberately red guard for the attribution cases", meaning
AC4 and AC5. That check cannot be written as stated, and the reason is not a detail: AC4 and AC5 are
each *"when the session reports, then …"* — their subject is a **verify session's conduct**, and a
fixture with a planted red exercises a test runner, not a session. Nothing in this repo can execute
a stage and observe what it concludes; `tests/sprint.test.sh`'s own header says so in terms — the
prose cases "prove the rule is written down, never that a session obeyed it". A planted red would
have produced a green check measuring something adjacent to the criterion, which is the guard that
runs and cannot fail (`testing-conventions.md`).

What was written instead carries the same claim at the only level it is reachable: AC4 and AC5 are
asserted as **prose in `skills/verify/SKILL.md`**, anchored to the claim rather than the vocabulary —
FR4 as a bounded span joining "every file reports" to "before any verdict", because either phrase
alone is satisfied by prose about a single-ticket pass and it is their joining that carries the rule;
FR5 as two separate assertions, because a paragraph naming the unattributed red without saying it
closes nothing is the likely half-done outcome and would otherwise pass. Both were mutation-proved
(M2, M3). AC3 is the same shape and took the same treatment. **AC1, AC2 and AC6 are unaffected** —
those are mechanical, and `tests/next.test.sh` and `tests/backlog-scripts-installed.test.sh` execute
them against the real script.
