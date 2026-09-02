---
id: "0086"
title: Settle the qa_level vocabulary once — a light tier, and a level a repo with no runner can run
type: feature
next: design
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

## Open design question

**Does a `light` ticket get closed by `develop` itself, or does it still go to `verify` but at a
cost the tier's saving survives?**

1. **`develop` self-closes.** Extend `close`'s refusal check to accept `next: develop` when the
   item's `qa_level` is `light`, called by `develop` at Step 5 in place of setting `next: verify`.
   Realizes the full modeled saving (no second session's startup floor at all) but overturns the
   stated invariant — closing becomes something other than verify's exclusive act, and Step 5's
   self-certify rule needs an explicit, narrow exception rather than a blanket one.
2. **`verify` still closes, but a light ticket's pass is minimal** — confirm the suite is green and
   the self-check ran, tick the ACs, close. Leaves the invariant untouched, but a session's startup
   floor is the dominant cost of a cheap session (`MEASUREMENT.md`, *the carrying constant*), so
   most of the modeled 32% saving does not materialize — light and standard would cost close to the
   same.
3. **Neither closes it as a normal verified row.** `develop` marks it done but distinguishably
   *self-attested* rather than *verified* (e.g. a marker in `DONE.md`), with no live independent
   check at all — preserves "verify owns a **verified** close" by narrowing what closing without
   verify is allowed to claim, at the cost of a new status this backlog does not otherwise have.

**And the second half's question: is a checklist a new `qa_level`, or a documented use of the
existing `verify` level?** `verify` is already defined as *"the scripted assertion the QA plan
names, plus lint/typecheck if present. It must be executed and its output shown"* — which a
checklist is not. Three shapes: **(a)** a new level (`review`, say) whose "command" is a checklist
the QA plan names — honest, but a second new value in the same enum as `light`; **(b)** `verify`
plus a required checklist section in the item, so the existing level carries it — no new vocabulary,
risks reading as a downgrade; **(c)** a per-repo `commands.review:` in `config.yml` pointing at a
checklist file, so the level stays `verify` and the repo supplies its content. Also settle **who the
checklist binds**: whatever is chosen must make an unrun checklist *visible*, since a prose edit
closing with nothing checked looks identical to one properly reviewed.

**Answer both in one decision, and state how the two values sit against each other** — `light`
(fewer sessions, same build gate) and a review level (a different kind of check) are orthogonal, and
a design that settles one and leaves the other implied is the drift this merge exists to prevent.

Also settle: **whether `develop` may ever assign or lower a ticket into `light`.** The existing rule
— *"Correct `qa_level` here too if this session proved the declared level wrong... Raising it is
yours; lowering it is not"* (`develop/SKILL.md` Step 5) — already reads as forbidding a lower-rigour
correction; state explicitly that `light` sits below `verify` in that ordering, so the existing rule
already covers it, or say why it needs its own line.

## Functional requirements

*(Completed by the design stage.)*

1. A ticket declared `qa_level: light` at queue time can reach `status: done` without paying for a
   second session's full startup floor.
2. Whatever closes a `light` ticket still requires the full test suite green and the review
   checklist run — the same build-quality gate every ticket gets today at Step 5, never a lower one.
3. `qa_level: light` is set by `queue` only, at capture or amend time. `develop` never assigns or
   lowers a ticket into `light`.
4. `close`'s refusal grounds and `develop`/`verify`'s Step 5 language are updated to match whichever
   shape is chosen, and the change is guarded in `tests/close.test.sh` against a real fixture.
5. `docs/decisions/002-matching-rigour-to-stakes.md`'s Light-tier row and `MEASUREMENT.md`'s tier
   table cite the mechanism actually built, rather than staying a priced-but-unbuilt model.
6. A repo with **no runner** has a declarable QA level that `verify` can actually execute or perform.
7. That level's checklist items come from `CONVENTIONS_CORE.md` and `documentation-conventions.md`
   and are **cited, never restated** — a second copy of a principle drifts.
8. `verify` records the checklist's result per item, the way it records an AC's evidence, so an
   unperformed checklist is distinguishable from a performed one. The *guard that cannot fail* rule
   (`testing-conventions.md`) applies to a human checklist too.
9. An item in such a repo cannot silently declare a level with no meaning.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The chosen mechanism is stated once (in the skill that enforces it) and cited elsewhere, never restated. | `documentation-conventions.md` |
| Testing | The close-path change is proved against a real fixture row, not asserted from prose alone. And an unperformed checklist must be distinguishable from a performed one — the *guard that cannot fail* rule applies to a human checklist too. | `testing-conventions.md` |

## Acceptance criteria

*(Written by the design stage.)*

## QA plan

- **Level:** unit — this repo's whole shell suite, extended per FR4.
- **The prose half needs a named guard of its own.** FR6–FR9 land mostly in skill prose, and a rule
  that only a reader enforces is the class of guard this repo has been bitten by twice. The design
  stage names the assertion (`tests/`) that would go red if the new level were declared and never
  performed.

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
