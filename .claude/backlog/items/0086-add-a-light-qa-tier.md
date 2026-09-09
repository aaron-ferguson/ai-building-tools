---
id: "0086"
title: Settle the qa_level vocabulary once — a light tier, and a level a repo with no runner can run
type: feature
next: verify
status: in-progress
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
claimed_by: "3e7c"
claimed_at: 2026-09-09T03:04:12Z
touches:
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
  # NARROWED 2026-09-09 by 55bd for the RE-ENTRY pass, checked against the code. `./claim`
  # re-seeds this field from `expects:` on every claim, so a narrowing does not survive a second
  # claim — the previous pass's list is preserved in the comments below rather than in entries.
  - skills/queue/templates/close                    # the edit target
  - .claude/backlog/close                           # installed copy, re-copied one-way after it
  - tests/close.test.sh
  - tests/close-by.test.sh
  - docs/decisions/003-who-may-close-a-ticket.md
  # WIDENED 2026-09-09 by 55bd — the FR3 fix reached one file the narrowing had excluded:
  - skills/queue/SKILL.md                           # its close_by precondition described the old gate
  # NOT touched this pass, and each was checked rather than assumed: the `002` price, the template
  # enum, `next`, `graph-fields`, `orchestrate` and the three skill files all passed verify on
  # 2026-09-08 and nothing in the two open defects reaches them.
  #
  # Corrections to expects:, carried from 2026-09-08 by b708 for the next capture to calibrate on:
  #   - `.claude/backlog/close` is the INSTALLED COPY. The edit target is
  #     `skills/queue/templates/close`, re-copied afterwards — the fix direction is one-way
  #     (tests/backlog-scripts-installed.test.sh AC2). Same for `next`, which expects: omitted
  #     entirely even though AC8 names its take line.
  #   - `MEASUREMENT.md` is NOT touched: FR13 already says so, and re-read confirms it holds no
  #     tier table, only the pointer at line 673.
  #   - `references/TRACKER.md` is not touched either; nothing in FR1-FR14 reaches it.
  #   - `.claude/backlog/config.yml` is not touched: this repo has a runner, so it must NOT gain a
  #     `review:` block — AC6's fixture needs a config WITHOUT one. The documented shape goes in
  #     `skills/queue/templates/config.yml`, which expects: omitted.
  #   - `items/0079-…` is not touched; it closed as `merged` on 2026-09-02 and CONCURRENCY.md
  #     forbids writing a `status: done` item.
  #   - the first pass also reached `tests/cost-by-category.test.sh`,
  #     `skills/orchestrate/outcome.schema.json` and `tests/orchestrate.test.sh`, which expects:
  #     never named.
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
- [ ] **AC11** — Given an item at `qa_level: verify` in a repo with no `review:` block in
      `config.yml`, when `verify` reads it after this change, then it resolves exactly as it does
      today — the scripted assertion the item's QA plan names — and `review`'s missing configuration
      is never consulted. *Red when:* `review` is implemented by repurposing the `verify` level
      rather than adding a value beside it, which is the reading FR8 and the schema line disagreed
      about until 2026-09-05. This is AC9's argument applied to the other field: additive means the
      untouched value keeps working, and that is proved rather than asserted.

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
- **Renaming the `verify` level to `review`.** They are different levels and both survive — see
  *Notes & decisions*, 2026-09-05. A rename is a cross-cutting one across 51 items in this backlog
  alone plus every other project's, which is `0067`'s subject and not a side effect of this ticket.
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
  prose: `qa_level ∈ {verify, review, unit, integration, e2e}` is *what is checked*; `close_by ∈ {verify,
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

- **Ambiguity settled 2026-09-05 — `review` is added beside `verify`; neither replaces the other.**
  FR8 says the enum *"gains"* `review`, while *How the two values sit against each other* wrote the
  schema as `{review, unit, integration, e2e}` — omitting `verify` and so reading as a rename. The
  two differ by 51 items in this backlog alone. **FR8 is right; the schema line had simply dropped a
  member while contrasting `qa_level` with `close_by`, and it is corrected.**

  Three things in this ticket already decide it, none of them needing a new judgement:

  1. **No FR migrates anything.** Fourteen FRs — seven for `close_by`, five for `review`, two for the
     record — and not one touches an existing item's `qa_level`. A rename across 51 items with no
     migration FR, no AC and no mention in the QA plan is an omission in one sentence, not a design.
  2. ***Out of scope* already forbids it**, in a line written at capture: *"Retroactively
     reclassifying any already-queued ticket's `qa_level`."* That is exactly what a rename is.
  3. **The rejected option (b) proves they are distinct.** (b) was *"`verify` plus a required
     checklist section"* — overloading the existing level to serve the review case — and it was
     rejected for blunting the refusal FR9 depends on. **If `review` were a rename of `verify`, (b)
     would be the chosen answer rather than a rejected alternative.**

  And they mean different things, which is why both are needed. `verify` is *no runner, but a
  mechanical check*: the `queue` skill requires *"a scripted assertion the ticket names explicitly —
  a grep, a path check, a schema validation"*, supplied by the item. `review` is *no runner and no
  mechanical check*: FR8's checks are judgement, its content is a checklist configured per repo
  (FR9), and it is explicitly not on the pyramid and not cumulative. Collapsing them would put a
  prose review and a grep under one word and lose the refusal that tells them apart.

  **The rename has a real argument, and it is not this ticket's.** `qa_level: verify` and the *stage*
  `verify` are one word for two things, and "run verify at level verify" is genuinely confusing —
  which is why the schema line's slip is an easy one to make and reads as deliberate. But that is a
  cross-cutting rename over every project using this backlog, `0067` exists to decide what shape such
  a rename takes, and `0086` already `relates:` to it. Doing it here would be a second decision
  smuggled into a ticket already at `size: l`. **Recorded so the next reader does not re-open it: if
  the collision is worth fixing, it is `0067`'s to shape and its own ticket to execute.**

  Checked against the amend rule (`queue`, *Amend*): this **narrows** the ticket rather than widening
  it — the additive reading is the one every existing FR and AC was written against — so **`size`
  stays `l`**, the QA plan is unchanged, and the only additions are AC11 and the *Out of scope* line
  above. Found from outside while settling AetherWorks 0119 (whether `qa_level: none` is a level).
- 2026-09-07 — `retro` absorbed a `FINDINGS.md` entry parked in the `ai-building-conventions`
  buffer on 2026-08-26, which is a live instance of this row's second half. **`config.yml`'s
  `commands:` block had no correct answer for a documentation repo.** The template offers
  unit/integration/e2e/lint/typecheck and assumes a package runner; that repo has no build and no
  framework, only a sibling `<name>.test.sh` beside each script, so `unit` became a shell loop over
  `scripts/*.test.sh`. Two consequences the template does not warn about, both bearing on the
  "level a repo with no runner can run" this row is settling: **the glob is a path decision baked
  into config**, so a ticket adding a new directory silently falls outside the runner unless that
  ticket widens it; and **a project with no runner at all has no honest value to put here**, which
  pushes every ticket to `qa_level: verify` whether or not that is the right level for it.

- **Built 2026-09-08 by b708. Six things worth the next reader's time, five of them corrections to
  this ticket's own text.**

  **1 — FR13's −18% was stale in its TENSE, and the fix is the ticket's own subject.** The FR reads
  "~−18% once `0085`'s protocol reduction lands". `0085` closed 2026-09-03, so a literal build would
  have published −18% as a live price. But `MEASUREMENT.md`'s re-measurement is pinned to
  `--since 2026-08-25 --until 2026-10-31` and **has not been run** — there is no post-`0085` figure
  anywhere. Publishing the projection as a measurement is precisely the defect `002` already shipped
  once with $3.89. So `002` states **−26% measured** and labels −18% a forecast due 2026-10-31, and
  `tests/close-by.test.sh` asserts the label rather than the number.

  **2 — FR6 taken literally admits `next: design`.** It says "a row whose `next` is not `verify` is
  refused *unless* its item records `close_by: develop`", which would let an opted-in ticket close
  from any stage. NARROWED to `develop` alone — the session FR2 names — and asserted, because the
  literal reading is what a later edit would restore.

  **3 — a light ticket with NO acceptance criteria is refused, which no AC asked for.** "Every
  criterion is an assertion" is vacuously true of none, and `close`'s pre-existing empty-section
  allowance would have closed such a row self-certified having checked nothing. That is option 3,
  the *self-attested* tier this ticket rejected, reachable through a door nothing guarded. Both
  halves are cases now: the light one refuses, the `close_by: verify` one still closes.

  **4 — `expects:` named the INSTALLED copy, not the edit target.** The script is
  `skills/queue/templates/close`; `.claude/backlog/close` is a byte-identical copy that
  `tests/backlog-scripts-installed.test.sh` AC2 enforces, and the fix direction is one-way. Four
  more corrections are recorded inline in `touches:` — `MEASUREMENT.md` and `references/TRACKER.md`
  are untouched, and `.claude/backlog/config.yml` **must not** gain a `review:` block, because AC6
  and AC11 both rest on this repo having none.

  **5 — the work reached two files `expects:` never named, and one of them is a FALSIFIED guard.**
  `tests/cost-by-category.test.sh` asserted `002` contains `buys 32%` — a rule FR13 deliberately
  reverses, so it went red on a correct document. Rewritten to assert the **relationship**: the
  finding sentence's figure must equal the Light row's, whatever that figure becomes. Strictly
  stronger than the literal it replaced — it still catches every original defect and now also
  catches the two places disagreeing, which is the real drift. It also had to be **flattened before
  matching**: the sentence wraps between `buys 26%.` and `at all buys 87%.`, so the obvious
  one-line matcher reds a correct file.

  **6 — the second file is `skills/orchestrate/outcome.schema.json`, and this is the gap no FR
  could see.** `develop`'s new `CLOSED` last line has no member in the outcome `verdict` enum, so a
  **driven** light close would have been a perfectly good stage reading as a schema failure — and
  `orchestrate` Step 4 escalates on those. One word, additive; the three existing develop verdicts
  are asserted to survive beside it.

- **Where the guards live, and which one is load-bearing.** `tests/close.test.sh` gained 15 cases
  over real fixture repos (AC1-AC5, AC9, plus FR1/FR3/FR6 edges); `tests/close-by.test.sh` is new and
  windowed per section for the prose (AC6, AC7, AC10, AC11, FR4, FR5, FR9, FR10);
  `tests/graph-fields.test.sh` and `tests/next.test.sh` cover AC8.

  **The one mechanical assertion standing behind the whole prose half is AC5** — `close` refusing a
  `## Review checklist` of bullets with not one box ticked, asserted on the **count of ticked
  boxes** and never on the section's presence. Everything in `tests/close-by.test.sh` is a grep over
  instructions: it tells you the instruction is still written, not that the level works.

- **Mutation-proved, three sweeps, 47 mutations, every one landed and red, each sweep with a no-op
  control that landed and stayed green.** 14 over `close`'s new refusals; 27 over the prose guard,
  almost all with blast radius 1, which is what AC7's "each asserted on its own line" means; 6 over
  the reanchored cost check. Restores were from a **copy**, never `git checkout --`, which restores
  to `HEAD` and would have deleted an uncommitted fix silently.

- **Two matcher bugs found by writing the guard, both from this repo's own written traps.** A phrase
  asserted across a line break cannot be matched at all (two assertions), and `grep -F` with an
  embedded newline is two patterns whose second is empty and matches everything. A third:
  `not yet measured` failed against `002`'s emphasis capitals — a presence grep pins one casing — so
  `close-by.test.sh` carries a case-insensitive matcher for claims whose emphasis is a prose
  decision.

- **Failed back 2026-09-08 by afac (verify). One AC is red, and the NFR row behind it with it.**
  Everything in the `close_by` half holds when `close` is driven directly; the red is in the review
  half's single mechanical guard.

  **AC5 fails on its own *Red when* clause, and NFR Testing fails on its second sentence.** The
  guard refuses a checklist of **plain bullets**, which is what its Given describes and what it was
  proved red on. It does **not** refuse a checklist of **checkboxes with none ticked**. The counter
  is `close`'s `rc_boxes`, incremented on `$0 ~ /^- \[[ xX]\]/` — a class containing a **space**, so
  `- [ ] line` counts as a box. `rc_bullets > 0 && rc_boxes == 0` is therefore *checkbox syntax
  present*, exactly the "checked by presence rather than by ticked-ness" the AC exists to exclude.

  Driven, not inferred: a fixture at `qa_level: review` with three unticked checkbox lines under
  `## Review checklist` closed on exit 0, `status: done`, row moved to `DONE.md`, nothing about the
  checklist ticked. That is verbatim the failure the QA plan says AC5 exists to catch — *"a prose
  change closing with nothing checked"* — and `DONE.md` cannot tell it from a performed review.

  **The form that defeats the guard is the form the instructions tell a session to write.** FR11,
  `verify` Step 2 (*"record one checkbox per checklist line"*) and `close`'s own message (*"Tick them
  in the `- [ ] …` form"*) all direct the session to `- [ ]` boxes. A session that writes them and
  then stops has passed the gate. The only input the guard catches is the one no instruction
  produces.

  **Two comments assert the opposite of the code beneath them** and should move with the fix, since
  both read as discharged evidence: `close`'s *"Asserted on the count of TICKED boxes and never on
  the section's presence"*, and `tests/close.test.sh:751`'s *"the reason it is asserted on the count
  of TICKED boxes rather than on the section's presence"*. Neither is true of `rc_boxes`.

  **`tests/close.test.sh` has no case for the input at all** — its four AC5 cases are plain bullets
  (refused), all-ticked (closes), partly-ticked (closes), empty section (closes). The gap between
  "partly ticked closes" and "none ticked closes" is where the defect lives, and the partly-ticked
  allowance is correct and must survive: the fix is `rc_boxes` counting `/^- \[[xX]\]/` only, plus
  the missing case, not a stricter rule.

  **Second thing to settle in the same pass, and it is FR3's gate rather than FR11's.** The citation
  check admits **any backticked, git-tracked path containing `/`** — it never asks whether the path
  is an assertion. Driven: a `close_by: develop` fixture whose two ACs cite only a tracked
  `docs/notes.md` (prose, no assertion anywhere in the repo) closed on exit 0. So the door
  build-note 3 shut for a light ticket with *no* criteria is still open for one whose criteria cite
  documents, which is option 3 — the self-attested tier this ticket rejected — reachable in one
  wrong citation. The residual-risk paragraph accepts that `close` *"cannot check that the guard can
  fail"*; it does not say the gate cannot check that the cited path is a guard at all. Either narrow
  it (a tracked path that is executable, or under a configured test root) or widen that paragraph to
  say so and assert the accepted case.

  Everything else was checked and holds — see `## QA evidence`. The suite is green: 24 files, 1175
  assertions, run file-by-file per `config.yml`'s attribution note.

- **Re-entry built 2026-09-09 by 55bd. Both of `afac`'s open items are fixed; nothing else on the
  ticket was reopened.**

  **AC5 — the counter now measures ticked-ness.** `rc_boxes` became `rc_ticked`, counting
  `/^- \[[xX]\][ \t]/` alone, and the refusal reads *"not one of them is ticked"* rather than
  *"not one of them is a checkbox"*, which was the false half of the old message.
  `tests/close.test.sh` gains the input that defeated it — three `- [ ]` lines, none ticked — beside
  the four cases that already existed, and the partly-ticked allowance is unchanged and still
  asserted.

  **Why the AC counter above it must NOT be changed to match, which is the trap for the next
  reader.** `close` ticks the ACs itself, so an AC list legitimately arrives unticked and `ac_boxes`
  is asking only whether the bullets are in a form this script *can* tick. A checklist arrives
  performed or not at all — nothing downstream ticks it — so the presence of a box says nothing. Two
  counters, four lines apart, that look like a copy-paste inconsistency and are not; the asymmetry
  is written into the code beside both.

  **FR3 — a citation now has to name an assertion, not merely a tracked file.** The gate reads the
  two signals `close` can read, either sufficing: a conventional test path (`tests/`, `spec/`,
  `__tests__/`, `*.test.*`, `*_test.*`, `*.spec.*`, `test_*`) **or** a mode `100755` entry in the
  git index. **Both routes are needed and each is asserted in both directions**: a JS or Python
  suite is committed non-executable and named by convention, a repo-specific check can be an
  executable at a path no convention predicts, and the fixtures prove the discrimination — removing
  the conventional route reds only the `src/thing.test.ts` case, removing the executable route reds
  only the `bin/check-the-thing` case.

  **What the narrowing does not do, and the record says so now.** It cannot tell that a real test
  tests *this* criterion. `003`'s *Residual risk* carries that alongside the falsifiability limit it
  already carried, so the accepted hole is written down rather than discovered again.

  **The two refusal reasons are told apart, because collapsing them was a 0-red mutation.** "Names
  no committed path" (add the guard) and "committed but is not an assertion" (cite a different file)
  have different fixes. The sweep predicted zero for merging them, which was correct and was the
  finding: both are now pinned, each with a `refute_contains` for the other, so no single reason
  string satisfies either case.

  **Mutation-proved: 10 mutations over the two guards plus three over the prose, every one confirmed
  landed by diff, each red at or above its predicted blast radius, with a no-op control that landed
  and stayed green.** Restores were from a copy — the fix was committed first, so `git checkout --`
  was available and still not used (it restores to `HEAD`, which is the trap this repo has
  recorded).

  **One file beyond the narrowed `touches:`, and it was a drift rather than a defect.**
  `skills/queue/SKILL.md`'s `close_by` precondition described the gate as first shipped, so a queue
  session following it could write an eligible-looking ticket whose criteria cited documents. It now
  states the requirement and points at `close` for the enumeration, per the Documentation NFR's
  *stated once, cited elsewhere* — the enumeration lives in `close` alone.

## QA evidence

Verified 2026-09-08 by `afac` at `qa_level: unit` (frontmatter; the QA plan's `**Level:** unit`
agrees — no drift). Suite run file-by-file: **24 files, 1175 assertions, 0 failed.** `lint` and
`typecheck` are unset in `config.yml`, so neither ran. Working tree clean at the level run and at
verdict; intersection with the evidence set empty, so not advisory.

Close-path rows were checked by **driving `.claude/backlog/close` against independently scaffolded
fixture repos**, not by reading `tests/close.test.sh`. Guard mutations were re-run rather than taken
from the build notes' table; 15 mutations, each confirmed landed by hash and restored from a copy,
with two no-op controls that landed and stayed green.

| Row | How it was checked | Result |
|---|---|---|
| AC1 | Drove `close 0201 tok1` on a fixture at `next: develop`, `close_by: develop`, both ACs citing a backticked git-tracked `tests/…`. Exit 0, `closed 0201`, 2 ACs ticked, row moved to `DONE.md`, `status: done`, tree clean after (committed). Guard falsifiable: M1 gated off the `close_by = develop` branch → `close.test.sh` 13 failed | **PASS** |
| AC2 | Same row with `close_by: verify` (fixture 0202) and with the field absent (0203). Both exit 1, *"is at stage 'develop', not 'verify' — only a verified ticket is closable"* + *"verify owns closing"*; QUEUE row intact, 0 ACs ticked, tree unchanged | **PASS** |
| AC3 | Fixture 0204, AC2 reading *"verified by reading it carefully"*. Exit 1, names the criterion by line **and** text: *"line 20: AC2 — second thing, verified by reading it carefully."*; tree unchanged. M2 disabled the per-bullet token test → 11 failed | **PASS** |
| AC4 | Fixture 0205 at `qa_level: review` + `close_by: develop`. Exit 1, *"carries qa_level: review with close_by: develop, and those cannot hold together"*. M3 removed the combined condition → 4 failed | **PASS** |
| AC5 | Given/when/then holds: fixture 0206 (3 plain bullets) exits 1, quotes the count `3`, names the section, names the `- [ ]` form, tree unchanged; M4 gated the refusal off → 6 failed. **But its *Red when* is satisfied by the shipped code**: fixture 0211, three `- [ ]` checkbox lines with none ticked, exits **0** and closes `status: done` with the checklist unperformed. `rc_boxes` counts `/^- \[[ xX]\]/` — presence, not ticked-ness. No case in `tests/close.test.sh` covers this input | **FAIL** |
| AC6 | Repo `config.yml` has no `review:` block (required by AC6/AC11's own fixtures). `skills/verify/SKILL.md:155` carries *"`review` is not exempt: with no `review:` block configured, stop"* with the reason. M6 rewrote it to *"review may be skipped"* → `close-by.test.sh` 1 failed | **PASS** |
| AC7 | `skills/develop/SKILL.md:438` reads `close_by` before choosing its ending; `:449` states raise-only; `:568` the closing branch. `orchestrate/outcome.schema.json` carries `CLOSED` beside the three existing verdicts. M8 made Step 5 unconditional → 1 failed; M9 removed the raise-only direction → 2 failed | **PASS** |
| AC8 | `tests/graph-fields.test.sh:128` enumerates `close_by` in its key list. `./next verify` printed the live take line: `TAKE 0086 \| … \| size l \| qa unit \| close verify` — printed unconditionally, absent or not. M14 dropped the key from the template → 1 failed; M15 removed it from `next`'s printf → `next.test.sh` 2 failed | **PASS** |
| AC9 | Fixture 0208 has no `close_by:` line at all: `close` at `next: verify` exits 0 and closes normally; `claim` and `next` read this repo's own items unchanged (0086's own claim and take line both worked with the field present, 0052's without) | **PASS** |
| AC10 | `002`'s Light row states the mechanism and `$4.20 / **−26%**`; `−32%` survives only as a dated correction (*"was priced at $3.89/−32% … and that figure was wrong"*); −18% is labelled *"PROJECTED AND NOT YET MEASURED"* with the 2026-10-31 date. `003` exists (8.5K), accepted, and cites the shipped `close_by`. M11 restored `$3.89/−32%` as the live row → 3 failed; M12 removed the forecast label → 1 failed; M13 desynced the finding sentence from the row → `cost-by-category.test.sh` 1 failed, which is the reanchored relational assertion working | **PASS** |
| AC11 | Level table holds `verify` **and** `review` as separate rows plus the three pyramid levels; prose tells them apart (*"but a mechanical check does"* / *"no mechanical check either"*); template enum reads `qa_level: verify \| review \| unit \| integration \| e2e`. This session ran at `unit` against a config with no `review:` block and never consulted one. M7 deleted the `verify` row → 1 failed | **PASS** |
| NFR Documentation | The eligibility rule's enforcement lives in one place — `skills/queue/templates/close` is the only file in `skills/` matching *"committed assertion"*. `queue:281-294` states the *setting* precondition (its own job under FR5) and points at `003` and at `close` as the enforcer; `verify` and `develop` cite rather than restate. Note: `queue`'s sentence and `close`'s header comment are near-verbatim, which is the pair to watch | **PASS** |
| NFR Testing | First sentence holds — every close-path row above was proved against a real fixture row, driven, not read. **Second sentence fails:** *"an unperformed checklist must be distinguishable from a performed one"* — fixture 0211 is an unperformed checklist that closes identically to a performed one, and `DONE.md` records both as done. This is the *guard that cannot fail* shape the row names | **FAIL** |
| NFR Migration | Proved against an item with no `close_by:` line at all (fixture 0208, closes as today) and against the two refusal paths for an absent field (0203). This repo's 60-odd existing items carry no `close_by:` and `next --drift` reports nothing new; an invalid value is a loud refusal, not a fail-open (*"records close_by: 'sometimes', which is neither"*) | **PASS** |
| Newly reachable (Step 4) | The change creates one new route to `status: done` — a build session closing its own row. Gated on `next: develop` **and** `close_by: develop` **and** every AC citing a tracked path, all three driven above, and `next: design` + `close_by: develop` is refused (FR6's narrowing). The gate's weak edge is what a "citation" may be: a tracked prose path passes it — recorded in *Notes & decisions* above | **PASS with a noted gap** |
| Always-on (`CONVENTIONS_CORE.md`) | Shell: inputs validated at the top, five refusals before any write, each descriptive and naming the offending value; fails closed where `git` is unreadable rather than degrading to an existence check; `any_token_committed` keeps the loop two deep; `ls-files … -- ":/$tok"` is `--`-terminated so a token from the item cannot become an option. No secrets, no new log field, no analytics event, no egress destination — the privacy pass does not fire. No auth, credential or visibility change; no UI | **PASS** |
