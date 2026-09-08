# 003 — Who may close a ticket, and the level for a repo with no runner

**Date:** 2026-09-08 · **Status:** accepted · **Narrows:** `001`'s stage boundary · **Related:** `002`, tickets `0086`, `0079` (merged in), `0067`

## Context

Two questions arrived from opposite ends of one vocabulary, and `0086` merged them because settling
them apart would have produced two independent extensions of the same enum by two sessions that could
not see each other's answer.

**From the cost end.** `002` priced a **Light** tier — *ticket, built, self-checked, no separate QA
pass* — and shipped it as a table row nothing implemented. `qa_level` took only `unit` and `verify`,
both of which merely select which commands `verify` runs; neither changed whether the `verify`
**session** happened, and `develop` Step 5 set `next: verify` unconditionally. The obstacle was not
documentation but an invariant `.claude/backlog/close` enforced mechanically: *"verify owns closing,
and it holds the verdict when it acts; nothing else may close a row."*

**From the other end.** A repo whose artifact is prose has no QA level it can honestly declare.
`ai-building-conventions` holds one script, checking that cross-references resolve. Against that
artifact `develop`'s TDD cycle has nothing to turn red, *"run every runner the project has"* is
vacuous, and `unit | integration | e2e` maps to nothing — so every ticket there is pushed to
`qa_level: verify` whether or not that is the right level for it. Yet the gate that repo needs is
already written down in `CONVENTIONS_CORE.md`: does the rule earn its context rent, is it a principle
or a preference, is it in the right file, does it contradict a rule stated elsewhere, is it stated as
the failure it prevents. **Every one of those is a review, and none is a test run.**

## Decision

**Two orthogonal fields, never one enum.** `qa_level` answers *what is checked* and gains `review`.
A new `close_by` answers *who closes*.

### `close_by: verify | develop` — the light tier

- **Absent means `verify`.** Every existing item and every project already on this backlog keeps its
  behaviour with no edit (`migration-conventions.md`, additive first).
- **`develop` is permitted only where every acceptance criterion is discharged by a committed
  automated assertion, named on the AC line, which the build session proved red before green.** No
  criterion whose verdict is a reading, a judgement or an eyeball.
- `queue` sets the field. `develop` may **raise** it to `verify` on finding an AC that is not a real
  assertion, and may never set or lower it to `develop` — narrowing a contract is the author's call.
- `close` gains a **fifth refusal ground** and fails closed at every edge: an untracked cited path is
  not a citation, a repo git cannot read admits no light close, and a light ticket with **no**
  criteria is refused rather than closed vacuously, since *every criterion is an assertion* is
  vacuously true of none.

**Why the eligibility rule is that one and not a judgement of blast radius.** The two recorded times
the independent gate bit in this repo, it bit on **AC quality, not code defects**: `0021` came back
with AC1 unmet on four of six files, and `0085` was failed back because three ACs could not be made
red on the defect they name. Both are an independent reader finding the builder's belief about the
criteria wrong — precisely what self-certification is structurally blind to. So the tier is safe only
where **there is no belief to be wrong about**: the verdict is an executed assertion returning the
same answer in either session, and the second session adds a re-run plus four protocol turns.

### `qa_level: review` — the level for a repo with no runner

- Not on `testing-conventions.md`'s pyramid, and therefore **not cumulative**: the checklist plus any
  configured `lint`/`typecheck`, nothing else implied.
- Content is supplied per repo by `review: checklist: <path>` in `config.yml`, and the checklist's
  lines **cite** the conventions rather than restating them — the file belongs to the repo being
  checked.
- **A ticket declaring `review` where nothing is configured is refused**, on exactly the same ground
  as `unit` with no command.
- `verify` records **one checkbox per checklist line** in a `## Review checklist` section, and `close`
  refuses a checklist of bullets with not one box ticked.
- **`qa_level: review` can never carry `close_by: develop`.** A review's checks are judgement, so the
  eligibility rule already excludes it; the refusal makes that mechanical rather than inferred.

### The corrected price

`002` priced Light at **$3.89/−32%** by deleting the QA stage's cost. It cannot go to zero: something
must still run the suite and tick the criteria. `verify`'s measured share is **$1.82 per closed
ticket** ($36.32 over 20, `MEASUREMENT.md`), already under half a session's $3.63 because the stage
amortizes. Add the build session's close at 2–4 turns: **$4.20 per ticket, −26%.** A further ~−18%
after `0085`'s turn reduction is **projected and unmeasured** — the re-measurement is due 2026-10-31,
and `002` now says so rather than publishing the forecast as a price.

## Rejected alternatives

**`verify` still closes, but does a minimal pass.** A minimal pass is cheap only if it drops the
literal AC read and the NFR check, which is exactly what bites. Kept intact it saves nothing. Worse,
it is **anti-economical unbatched**: a `verify` session run for one light ticket costs $3.63 against
standard's amortized $1.82, so the tier would make cheap work dearer whenever no batch forms.

**`develop` marks the ticket *self-attested* and `verify` spot-checks later.** `002`'s own *What never
scales down* settles it: a cheap tier is cheap because it uses fewer sessions, not because it tests
less. This tests less, and adds a status distinguished only by a marker nothing reads and nobody
audits.

**`light` as a value in `qa_level`.** `qa_level` answers *what is checked*; the tier answers *who
closes*. Two orthogonal questions in one enum is the drift the `0079` merge existed to prevent, and a
prose warning about it is not preventing it. The cost of a separate field, named honestly: one more
frontmatter key, `tests/graph-fields.test.sh`, `./next`'s take line, and `close`.

**`verify` plus a required checklist section, instead of a `review` level.** It blunts the one refusal
the level depends on. `verify` stops today when a declared level has no command; make a level that
sometimes legitimately has no command and that refusal can never fire again — for any level.

**Renaming `qa_level: verify` to `review`.** The collision between the level and the *stage* of the
same name is real, and *"run verify at level verify"* is genuinely confusing. But they mean different
things — `verify` is *no runner, a mechanical check*; `review` is *neither* — and a rename crosses 51
items in this backlog alone plus every other project's. `0067` exists to decide what shape such a
rename takes; it is not a side effect of this one.

## Residual risk

**`close` can check that each light criterion *cites* a guard. It cannot check that the guard *can
fail*.** That is this repo's known failure mode — `testing-conventions.md`: *a guard only ever seen
passing is indistinguishable from one wired to nothing*. The residual risk moves from *nobody
checked* to *the builder's own recorded red*, which is weaker than an independent read and
deliberately so. The eligibility rule is what keeps the class narrow.

**What to re-examine first, and what would trigger it:** the first time a light ticket closes on a
guard that proved nothing. If that happens, the question is not whether to widen the check — a
mechanical test for falsifiability does not exist — but whether the eligibility rule should require a
recorded red-then-green transcript rather than a citation.

## Consequences

- `002`'s Light row states this mechanism and the corrected saving, and its superseded −32% survives
  only as dated history.
- The mechanical assertion standing behind the whole prose half is `close` refusing an unticked
  `## Review checklist`, asserted on the count of ticked boxes and never on the section's presence
  (`tests/close.test.sh`, 0086 AC5). A prose rule with no such assertion is the class of guard this
  repo has been bitten by twice.
- `develop`'s last line gains a fourth verdict, `CLOSED`, for the one case where the build stage is
  also the closing one.
