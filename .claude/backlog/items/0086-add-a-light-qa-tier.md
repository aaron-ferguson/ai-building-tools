---
id: "0086"
title: Add a light QA tier that closes without a separate verify session
type: feature
next: design
status: ready
qa_level: unit
size: l
created: 2026-09-02
source: user
parent:
blocked_by: []
relates: ["0087"]
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

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The chosen mechanism is stated once (in the skill that enforces it) and cited elsewhere, never restated. | `documentation-conventions.md` |
| Testing | The close-path change is proved against a real fixture row, not asserted from prose alone. | `testing-conventions.md` |

## Acceptance criteria

*(Written by the design stage.)*

## QA plan

- **Level:** unit — this repo's whole shell suite, extended per FR4.

## Out of scope

- Retroactively reclassifying any already-queued ticket's `qa_level`.
- A periodic audit or spot-check of `light` closures, unless the design stage picks option 3 above
  and needs one to make "self-attested" meaningful.

## Notes & decisions

- Captured 2026-09-02 from a discussion of what `docs/decisions/002-matching-rigour-to-stakes.md`'s
  Light tier would take to actually build, prompted by the observation that this backlog has no
  formal light process today despite the tier being priced and named.
