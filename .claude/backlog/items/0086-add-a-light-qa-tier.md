---
id: "0086"
title: Settle the qa_level vocabulary once — a light tier, and a level a repo with no runner can run
type: feature
next: develop
status: ready
qa_level: unit
size: l
created: 2026-09-02
source: user
parent:
blocked_by: []
relates: ["0079", "0087", "0076", "0078"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
  - .claude/backlog/close
  - .claude/backlog/config.yml
  - references/TRACKER.md
  - MEASUREMENT.md
  - docs/decisions/002-matching-rigour-to-stakes.md
  - tests/close.test.sh
  - tests/next.test.sh
  - tests/graph-fields.test.sh
  - tests/close-by.test.sh
  - docs/decisions/003-who-may-close-a-ticket.md
  - .claude/backlog/items/0079-a-qa-level-for-a-repo-with-no-runner.md
claimed_by:
claimed_at:
touches:
---

## Problem

`docs/decisions/002-matching-rigour-to-stakes.md` prices a **Light** tier — "ticket, built,
self-checked. No separate QA pass" — at $3.89 against Standard's $5.71, a 32% saving, for internal
tooling and scripts where a failure would surface on the next run. **It is priced but not built.**

`qa_level` today takes only `unit` and `verify` in this backlog, and both values only select which
commands `verify` runs (`config.yml`'s `unit`/`integration`/`e2e`/`lint`/`typecheck` block) — they
never change whether the `verify` **session** happens. `develop`'s Step 5 sets `next: verify`
unconditionally, regardless of the declared level.

**The obstacle is not documentation, it is an architectural invariant the close script enforces
mechanically.** `.claude/backlog/close` refuses any row whose `next` is not `verify`, with the
message *"verify owns closing, and it holds the verdict when it acts; nothing else may close a
row"* — and `develop`'s Step 5 states the same principle in prose: *"Do not self-certify: the point
of a separate pass is that it checks what the ACs say rather than what you remember building."*
Realizing the modeled saving means either overturning that invariant for this one tier, or finding a
shape for Light that doesn't need to.

## The second half, merged in from `0079` on 2026-09-02

**A repo with no test runner has no QA level it can honestly declare, and that is the same
vocabulary question from the other end.** `ai-building-conventions` holds one script,
`scripts/check-convention-links.sh`, which checks that cross-references resolve and nothing else.
Against that artifact: `develop` Step 4's TDD cycle has nothing to turn red; Step 5's *"run every
runner the project has"* is vacuous; `qa_level: unit | integration | e2e` maps to nothing, so an
item there declares a level that cannot be run; and an NFR table citing
`accessibility-conventions.md` for a prose edit is theatre.

**The gate that repo actually needs already exists and is written down**, in `CONVENTIONS_CORE.md`
itself. Does the rule earn its context rent (*Every rule pays rent in context*)? Is it a
**principle** or a **preference**, and is it in the right file for that? Does it contradict a rule
stated elsewhere? Is it stated as the failure it prevents rather than the reasoning that produced it
(`documentation-conventions.md`)? **Every one of those is a review, and none is a test run.** The
AetherWorks retro of 2026-09-01 edited that repo three times with nothing to check itself against
but its own judgement.

**Why the two are one ticket.** Both add a value to `qa_level` — a vocabulary three skills and two
scripts read — and both change what closing is allowed to claim. Settled apart, they produce two
independent extensions of one enum, by two design sessions that cannot see each other's answer;
`0067` is the ticket for what a cross-cutting rename costs once that has happened. The line that
matters for the second half is **has a runner or does not**, not *product versus tooling*:
`ai-building-tools` has `tests/*.test.sh` and goes through the normal lifecycle today.

## Functional requirements

**Schema.** `qa_level` answers *what is checked*; a new field `close_by` answers *who closes*. The two
are separate fields because they are separate questions, and one enum holding both is the drift this
merge exists to prevent.

1. Items gain `close_by: verify | develop`, default `verify`. **Absent means `verify`** — every one of
   the existing items and every project already using this backlog keeps its current behaviour with no
   edit (`migration-conventions.md`, additive first).
2. A ticket declared `close_by: develop` reaches `status: done` in the session that built it, paying no
   second session's startup floor.
3. **`close_by: develop` is permitted only where every acceptance criterion is discharged by a committed
   automated assertion, named on the AC line, which the develop session proved red before green.** No AC
   whose verdict is a reading, a judgement or an eyeball.
4. Whatever closes such a ticket still requires the project's whole suite green and `develop` Step 5's
   review checklist — the same build-quality gate every ticket gets today, never a lower one.
5. `close_by` is set by `queue` only. `develop` may **raise** it from `develop` to `verify` — handing a
   ticket to an independent pass when it finds an AC that is not a real assertion — and may never set or
   lower it to `develop`. This needs its own line in `develop` Step 5: the existing "raising is yours,
   lowering is not" rule governs `qa_level`, which is a different field.
6. `.claude/backlog/close` gains a **fifth refusal ground**, on the same terms as the four it has: a row
   whose `next` is not `verify` is refused *unless* its item records `close_by: develop`, and such a row
   is refused anyway if any bullet in its *Acceptance criteria* section carries no assertion citation.
   The refusal names which criterion failed.
7. `develop` Step 5 branches on `close_by`: `verify` → the present behaviour; `develop` → run the full
   suite, tick the ACs against the assertions just proved, call `./close <id> <token>`, and report the
   close rather than `/verify <id>`.

**The no-runner level.**

8. `qa_level` gains **`review`**, for a repo whose artifact is prose and whose checks are judgement.
   `verify` performs it; it is not on `testing-conventions.md`'s pyramid and so is **not cumulative** —
   it runs the checklist plus any configured `lint`/`typecheck`, and nothing else is implied.
9. Its content is supplied per repo: `review:` `checklist: <path>` in `config.yml`. **A ticket declaring
   `review` where nothing is configured is refused**, on exactly the same ground as `unit` with no
   command — that refusal is what stops an item silently declaring a level with no meaning, so the level
   must never be one that legitimately has no command.
10. The checklist's items are **cited** from `CONVENTIONS_CORE.md` and `documentation-conventions.md`,
    never restated in a skill or an item. The checklist file itself belongs to the repo being checked.
11. `verify` records **one checkbox per checklist line** in the item's `## Review checklist` section, the
    way Step 3 records an AC's evidence. `close` refuses a `## Review checklist` section holding bullets
    and no checkboxes, on the same grounds as its fourth refusal for ACs.
12. **`qa_level: review` with `close_by: develop` is refused.** A review's checks are judgement, never a
    committed assertion, so FR3 already excludes it — the refusal makes that mechanical rather than
    inferred.

**The record.**

13. `docs/decisions/002-matching-rigour-to-stakes.md`'s Light row cites the mechanism actually built and
    the corrected saving (**−26%** against the measured $5.71, ~**−18%** once `0085`'s protocol
    reduction lands — see *Notes & decisions*), not the $3.89/−32% that priced the close at zero.
    `MEASUREMENT.md` needs no edit: it holds no tier table, only a pointer to `002`.
14. `docs/decisions/003-…` records this decision, its rejected alternatives and its residual risk, and is
    written **with the mechanism** so it cites what shipped rather than what was planned.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The chosen mechanism is stated once (in the skill that enforces it) and cited elsewhere, never restated. | `documentation-conventions.md` |
| Testing | The close-path change is proved against a real fixture row, not asserted from prose alone. And an unperformed checklist must be distinguishable from a performed one — the *guard that cannot fail* rule applies to a human checklist too. | `testing-conventions.md` |
| Migration | `close_by` is additive: absent means `verify`, so no existing item and no other project needs an edit for this change to be safe. Prove it against an item with no `close_by:` line at all. | `migration-conventions.md` |

## Acceptance criteria

- [ ] **AC1** — Given an item with `close_by: develop` whose every AC bullet cites a `tests/` assertion,
      and a `QUEUE.md` row at `next: develop` holding a matching token, when `./close <id> <token>` runs,
      then it closes normally: ACs ticked, row moved to `DONE.md`, dependents reconciled, committed.
      *Red when:* the fifth refusal ground is removed from `close`, or `close_by` is misread — the row is
      refused as "not at verify".
- [ ] **AC2** — Given the same row but with `close_by: verify` (or the field absent entirely), when
      `./close` runs against `next: develop`, then it refuses with the existing grounds and changes
      nothing. *Red when:* the new branch is written to accept `next: develop` unconditionally.
- [ ] **AC3** — Given an item with `close_by: develop` one of whose AC bullets carries no assertion
      citation, when `./close` runs, then it refuses, **names that criterion**, and leaves the tree
      exactly as it found it. *Red when:* the citation check counts the section rather than each bullet,
      or the message reports only a status.
- [ ] **AC4** — Given an item with `qa_level: review` and `close_by: develop`, when `./close` runs, then
      it refuses on FR12's ground. *Red when:* the two fields are checked independently and never
      together.
- [ ] **AC5** — Given an item with a `## Review checklist` section holding bullets and not one checkbox,
      when `./close` runs, then it refuses on the same terms as its fourth refusal for ACs, quoting the
      count. *Red when:* the checklist section is checked by presence rather than by ticked-ness — which
      is the *guard that cannot fail* shape this AC exists to exclude.
- [ ] **AC6** — Given `config.yml` with no `review:` block, when a `qa_level: review` item reaches
      `verify`, then `verify` stops and says the level has nothing configured, and does not substitute a
      lower level. *Red when:* `review` is allowed to mean "no command needed".
- [ ] **AC7** — Given a `develop` session finishing a `close_by: develop` ticket, when it reaches Step 5,
      then it runs the whole suite, closes, and reports the close; and given it finds an AC that is not a
      committed assertion, it raises `close_by` to `verify` and hands off. *Red when:* Step 5's
      `next: verify` line is left unconditional, or the raise-only direction is not stated.
      Guard: a new `tests/close-by.test.sh`, greping both branches, each asserted on its own line.
- [ ] **AC8** — Given `tests/graph-fields.test.sh`, when it runs, then `close_by` is in its enumerated
      key list and `./next`'s take line prints it alongside `size` and `qa_level`. *Red when:* the field
      is added to the template and nothing reads it.
- [ ] **AC9** — Given an item file with no `close_by:` line, when `./close`, `./next` and `./claim` read
      it, then all three behave exactly as today. *Red when:* the readers treat a missing field as an
      error or as `develop`.
- [ ] **AC10** — Given `docs/decisions/002`, when read, then its Light row states the mechanism and
      −26%/−18%, and `docs/decisions/003` exists and cites the shipped mechanism. *Red when:* the −32%
      figure survives anywhere as a live price.

## QA plan

- **Level:** unit — this repo's whole shell suite, extended per AC1–AC9.
- **Where each guard lives.** AC1–AC5 and AC9 are `tests/close.test.sh`, each against a real fixture
  item and a real fixture `QUEUE.md` row; AC6 and AC7 are prose greps in a new self-contained
  `tests/close-by.test.sh` — this repo has no shared prose-grep file, and each test is its own
  script printing its own tally (`CLAUDE.md`); AC8 extends `tests/graph-fields.test.sh` and
  `tests/next.test.sh`; AC10 is a grep over `docs/decisions/`.
- **The prose half's named assertion.** FR8–FR12 land partly in skill prose, and a rule only a reader
  enforces is the class of guard this repo has been bitten by twice. The assertion that goes red if the
  new level is declared and never performed is **AC5** — `close` refusing a checklist section whose
  bullets are unticked. It is mechanical, it fires on the real failure (a prose change closing with
  nothing checked), and it is asserted on the *count of ticked boxes*, not on the section's presence.
- **Prove each new refusal red before green** (`testing-conventions.md`, *Prove a new guard fails*), and
  diff the fixture after each mutation: a mutation that silently failed to apply reads exactly like a
  guard that holds.

## Out of scope

- Retroactively reclassifying any already-queued ticket's `qa_level`.
- Adding a test runner to `ai-building-conventions`. The artifact is prose; a runner would be
  ceremony, and the second half exists because the honest answer there is a review.
- Changing what the conventions themselves say. This is about how a change to them is checked.
- A periodic audit or spot-check of `light` closures, unless the design stage picks option 3 above
  and needs one to make "self-attested" meaningful.

## Notes & decisions

- Captured 2026-09-02 from a discussion of what `docs/decisions/002-matching-rigour-to-stakes.md`'s
  Light tier would take to actually build, prompted by the observation that this backlog has no
  formal light process today despite the tier being priced and named.
- **Amended 2026-09-02: `0079` merged in, and `0079` closed as merged.** Both tickets extended
  `qa_level` and both sat at `design` unclaimed, so two design sessions would have answered one
  question twice. Re-checked against the amend rule (`queue`, *Amend*): **`size` stays `l`** — it was
  already `l` for an open design question, and the second half adds one more branch to the same
  decision rather than a second decision; **the ACs are unaffected** because none was written yet;
  **the QA plan gains the prose-half guard above**; ***Out of scope* gains `0079`'s two lines.** The
  merged ticket takes `0079`'s rank, which was the higher of the two — it now carries `0079`'s whole
  problem, so it cannot be worth less than `0079` was.
- **Rank it on what it buys, not on what it feels like.** `docs/decisions/002` prices the Light tier
  at **−32%** ($3.89 against $5.71) while routing an item Inline instead of Standard buys **−87%**,
  and routing needs no engineering at all. This ticket is worth building; it is not the largest lever
  on the page, and the ranking argument in `RANKING.md` says so explicitly rather than leaving a
  reader to infer it from the position.

- **Design decision, 2026-09-02 — settled on paper; no prototype needed.** Both halves answered
  together, per the ticket's instruction.

  **Half A — a `light` ticket is closed by `develop` (option 1), but the tier is not a `qa_level`
  value and it is gated mechanically.** New field `close_by: verify | develop`, absent = `verify`.
  Eligibility: *every AC is discharged by a committed automated assertion, named on the AC line, proved
  red before green by the session that built it.*

  **Why option 1 rather than 2, on measured grounds and not on feel.** The two recorded times the
  independent gate bit in this repo, it bit on **AC quality, not code defects**: `0021` was sent back
  with AC1 unmet on four of six files (`MEASUREMENT.md`, *Effectiveness*), and `0085` was failed back
  today because three ACs could not be made red on the defect they name. Both are an independent reader
  finding the builder's belief about the ACs wrong — precisely what self-certification is structurally
  blind to. So the tier is only safe where **there is no belief to be wrong about**: the AC's verdict is
  an executed assertion that returns the same answer in either session, and the second session adds a
  re-run plus four protocol turns. That condition is the eligibility rule, and it is `queue`'s existing
  *"name what would make each AC red"* rule promoted from advice to a precondition.

  **The corrected price, which is the other half of the argument.** `002` prices Light at $3.89/−32% by
  deleting the QA stage's whole cost. It cannot go to zero: something must still run the suite and tick
  the ACs. `verify`'s measured share is **$1.82 per closed ticket** ($36.32 over 20) — already less than
  half a `verify` session's $3.63, because the stage amortizes across tickets. Add develop's close
  (2–4 turns at $0.1044 ≈ $0.31): **$4.20 per ticket, −26%.** After `0085` cuts `verify` from 38.4 turns
  to 28, its share falls to ~$1.33 and light's edge to ~$1.02, **~−18%**. Worth building; smaller than
  advertised, and `002` says so now (FR13).

  **Rejected — option 2 (`verify` still closes, minimally).** A minimal pass is cheap only if it drops
  the literal AC read and the NFR pass, which is exactly what bites; kept intact it saves nothing.
  Worse, it is **anti-economical unbatched**: a `verify` session run for one light ticket costs $3.63
  against standard's amortized $1.82, so the tier would make cheap work dearer whenever no batch happens
  to be forming.

  **Rejected — option 3 (`develop` marks it *self-attested*).** `002`'s own *What never scales down*
  settles it: a cheap tier is cheap because it uses fewer sessions, not because it tests less. Option 3
  tests less, and adds a status distinguished only by a marker that nothing reads and nobody audits.

  **Half B — a new `qa_level: review`, whose content comes from `config.yml`.** The ticket framed (a) a
  new level and (c) a configured checklist as alternatives; **they compose**, and that is the answer: the
  level is the vocabulary, the config is where the content lives, so FR10's *cite, never restate* holds
  because the checklist file belongs to the repo being checked.

  **Rejected — (b) `verify` plus a required checklist section.** It blunts the one refusal FR9 depends
  on. `verify` today stops when a declared level has no command in `config.yml`; make a level that
  sometimes legitimately has no command and that refusal can never fire again — which is the silent
  downgrade the per-ticket declaration exists to prevent.

  **Rejected — `light` as a value in `qa_level`.** `qa_level` answers *what is checked*, the light tier
  answers *who closes*. Two orthogonal questions in one enum is the drift the `0079` merge exists to
  prevent, and a prose warning about it is not preventing it. Cost of the separate field, named
  honestly: one more frontmatter key in the template, `tests/graph-fields.test.sh`, `./next`'s take
  line, and `close` — which is why AC8 and AC9 exist. `0067` prices what a cross-cutting rename costs
  once a field is in place; adding one is cheaper than overloading one.

  **How the two values sit against each other.** Orthogonal, and the schema says so rather than the
  prose: `qa_level ∈ {review, unit, integration, e2e}` is *what is checked*; `close_by ∈ {verify,
  develop}` is *who closes*. Their one interaction is a refusal, not a rule to remember —
  `qa_level: review` can never carry `close_by: develop`, because a review's checks are judgement and
  FR3 admits only assertions (FR12).

  **Whether `develop` may ever lower a ticket into the light tier — it needs its own line.** The existing
  *"Raising it is yours; lowering it is not"* governs `qa_level`, and `close_by` is a different field, so
  the existing rule does not reach it by implication. FR5 states the direction explicitly, and the useful
  half is the *raise*: a develop session that discovers an AC is not a real assertion must be able to
  hand the ticket to an independent pass.

  **The trade-off being accepted, stated plainly.** `close` can check that each light AC *cites* a guard;
  it cannot check that the guard *can fail*. That is this repo's known failure mode —
  `testing-conventions.md`: *"a guard only ever seen passing is indistinguishable from one wired to
  nothing"*. The residual risk moves from "nobody checked" to "the builder's own recorded red", which is
  weaker than an independent read and deliberately so; the eligibility rule is what keeps the class
  narrow, and it is the thing to re-examine first if a light ticket ever closes on a guard that proved
  nothing.

  **Why no `docs/decisions/003` yet, rather than skipping the record.** This decision earns one — it
  narrows a stated invariant and rejects three alternatives that will be re-litigated
  (`documentation-conventions.md`, *Decision Records*). It is FR14 rather than written now because a
  record written ahead of its mechanism is the defect this whole ticket exists to fix: `002` priced a
  tier nothing implemented, and it was read as settled for that reason. The reasoning is durable here in
  the meantime, which is where `develop` reads.

  **A factual correction to this ticket's own capture.** FR5 as captured cited "`MEASUREMENT.md`'s tier
  table". There is no tier table there — `MEASUREMENT.md` line 673 only points at `002`. Carried into
  FR13.
