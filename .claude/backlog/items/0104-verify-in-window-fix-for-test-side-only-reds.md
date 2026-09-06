---
id: "0104"
title: Gate and specify an in-window verify fix for test-side-only reds
type: feature
next: develop
status: ready
qa_level: unit
qa_manual: "AC1 — the go/no-go on the measured figures is Aaron's call, not an agent's"
size: m
created: 2026-09-06
source: user
parent:
blocked_by: []
relates: ["0038"]
expects:
  - MEASUREMENT.md                # the gate's figures and its recorded verdict, either way
  - skills/verify/SKILL.md        # Step 5's branch table — ONLY if the gate clears
  - tests/verify-in-window.test.sh # new; the guard on the rule's preconditions
---

## Problem

When `verify` FAILs a ticket it hands off to a fresh `develop`, which re-reads an item file that has
just grown a verdict. For the general case that hand-off is **correct and cheaper**, and this is
measured rather than assumed — `MEASUREMENT.md`, *Would the re-entry after a FAIL be cheaper in the
verify window?*: across all four re-entry `develop` sessions in the corpus the in-window alternative
costs **+$0.37 to +$0.74 per bounced ticket**, and three of the four would have exceeded a 200k window
and compacted mid-work.

**One narrow case was left open by that analysis and is the whole of this ticket.** Where `verify`'s
mutation sweep finds a *missing assertion* — it holds the mutation, it knows the exact absent
assertion, and no production code is at fault — the fix is test-side only and the diagnosis is already
fully characterized. 0038's AC9 fixture was exactly this shape: the verdict named the mutation, the
line, and the fix, and the re-entry `develop` session confirmed *"No production code changed — the
verdict was right that the branch was correct and only the evidence was missing."*

**What is missing is any evidence that the narrow case is cheaper, because it has never been measured
in isolation.** The four measured re-entries each bundled test-side work with other work, so `n = 0`
for the case this ticket is about. The general figure is the only datum, and it points the wrong way.
**So the first deliverable is the measurement, not the rule** — and the rule ships only if the numbers
clear the bar in FR1.

## Functional requirements

- **FR1 — The gate, and it comes first.** Measure the narrow case against the hand-off it would
  replace, and record the result in `MEASUREMENT.md` beside the existing section. The comparison is
  per bounced ticket: the in-window fix's carried differential (the FAILing verify session's context
  at verdict time, minus a fresh `develop` floor) priced across the turns the fix actually takes, at
  the `$0.50 per million per turn` constant, against the saving of one session floor plus its
  orientation turns. **Kill criteria, written before the test and binding:** the rule does not ship if
  the measured net saving is under **$0.50 per bounced ticket**, or if the in-window session's
  projected end context exceeds **180,000 tokens** in more than one of the measured cases, or if fewer
  than **three** eligible instances can be found to measure. Any one of the three kills it.
- **FR2 — The rule in `verify`, and only if FR1 clears.** Add a fourth branch to Step 5's verdict
  table: a red whose cause is a *missing assertion the sweep has already characterized*, whose fix
  touches only files under the project's test paths, is fixed in the verify session rather than handed
  to `develop`.
- **FR3 — An in-window fix must not close the ticket.** The session that writes the fix hands off to
  `verify` with `./handoff <id> <token> verify`, and a **fresh** session closes it. A session that
  diagnosed a red, wrote the assertion that pins it, and then closed on its own assertion has checked
  nothing, and `verify` is the stage that closes tickets — so without this the rule converts the
  suite's only independent gate into a self-report.
- **FR4 — An objective eligibility test, checkable by the next reader.** The branch is available only
  when all of: the sweep has a **named mutation** that reproduces the red; the verdict records that
  **no production file is at fault**; and the fix's file set lies entirely within the test paths
  `config.yml` names. The verdict must state all three in as many words. A criterion resting on the
  session's own sense that it "understands the failure" is not one — it is judged by the party that
  benefits from judging it generously.
- **FR5 — A mandatory abort back to the hand-off.** If the fix reaches any file outside the test
  paths, or a second red appears that the sweep did not characterize, the session stops, records why,
  and hands off to `develop` as it would have. Without a stated abort, a session that has already
  skipped the hand-off has an incentive to keep going.
- **FR6 — A guard.** A test asserting that `verify`'s branch table states FR3's no-self-close rule and
  FR4's three-part eligibility test, so a later rewrap or trim cannot quietly drop either.
- **FR7 — The verdict is recorded either way.** If the gate kills the rule, `MEASUREMENT.md` records
  the negative result and this ticket closes having shipped only that. An unrecorded kill means the
  next session re-derives it, which is the cost this whole line of work exists to avoid.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | FR1's kill criteria are the performance contract; the measure and its date are declared before the change, and the verdict is recorded whichever way it falls | `measurement-conventions.md` |
| Documentation | The rule, if it ships, is stated once in `verify`'s branch table and cited — never restated — anywhere else | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the measurement in FR1 is complete, when its figures are read against the three kill
      criteria, then `MEASUREMENT.md` records the verdict and the decision to ship or kill is Aaron's.
      **Red when:** the section states a net saving without naming all three criteria and where each
      landed.
- [ ] AC2 — Given the gate killed the rule, when the ticket closes, then `skills/verify/SKILL.md` is
      unchanged and `MEASUREMENT.md` carries the negative result. **Red when:** a branch was added to
      `verify` with no passing gate recorded.
- [ ] AC3 — Given the gate cleared, when `skills/verify/SKILL.md` Step 5 is read, then its branch table
      names the in-window branch and states that such a fix hands off to `verify` and never closes.
      **Red when:** the words permitting the branch are present and the no-self-close sentence is
      deleted — `tests/verify-in-window.test.sh` must red on that deletion alone.
- [ ] AC4 — Given the gate cleared, when the eligibility test is read, then it names the mutation
      requirement, the no-production-file requirement, and the test-path requirement as three separate
      conditions. **Red when:** any one of the three is removed while the other two stand.
- [ ] AC5 — Given a session takes the in-window branch and the fix reaches a file outside the
      configured test paths, when it applies FR5, then it aborts and hands off to `develop`.
      **Red when:** the abort sentence is absent from the branch's description.
- [ ] AC6 — Given `tests/verify-in-window.test.sh` runs, when the assertions from AC3 and AC4 are each
      mutated in turn, then each mutation reds on its own assertion and not only on a catch-all.
      **Red when:** deleting a pinned sentence leaves the suite green.

## QA plan

- **Why that level:** the deliverable is prose in a skill file plus a recorded measurement; `unit` is
  what runs `tests/*.test.sh` on this project, and FR6's guard lives there. AC1's go/no-go is the one
  criterion no runner can discharge, which is why `qa_manual:` names it.
- **Specific checks:** run the guard individually, then the full suite with
  `for t in tests/*.test.sh; do "$t" || true; done` so an unrelated red is attributable. Mutate each
  sentence AC3 and AC4 pin, one at a time, and confirm each reds on its own assertion — the
  catch-all trap `MEASUREMENT.md` and 0038 both document. **Assert phrases that sit on one line**: the
  guards grep prose, and rewrapping a guarded paragraph is a breaking change in this repo.

## Out of scope

- **The general in-window re-entry.** Measured and rejected; `MEASUREMENT.md` carries the figures. This
  ticket is the narrow test-side-only case and nothing wider.
- **Any change to `develop`.** The hand-off it receives is unchanged, and it remains the destination
  for every red this branch does not cover.
- **Changing what `verify` closes on.** FR3 constrains one branch; the closing rules are untouched.
- **`skills/verify/SKILL.md` is held by 0039** (`touches:`, AC20 relocating the evidence table) as at
  capture. This ticket does not start until that file is free, and `develop` re-checks on claim.

## Notes & decisions

**Routed to `develop` rather than `design`: the open question is a measurement, not a decision.**
Nothing here turns on a judgement about a surface or a pattern; it turns on four figures that do not
exist yet. FR1 is the riskiest-assumption test and its kill criteria are written before it runs, per
`discovery-conventions.md`.

**Ranked last, deliberately.** Every other row in `QUEUE.md` addresses a problem known to be real. This
one addresses a saving that has never been observed, in a case with `n = 0`, against a general result
that came out **negative**. It is Tier 5 — a speculative optimization — and the honest place for it is
below everything with a demonstrated problem. If it is never reached, the recorded measurement has
already done the useful half of the work.

**The risks, stated plainly, because the rule trades away a check that has visibly caught something.**

1. **It removes the independent read of `verify`'s own diagnosis, and that read has demonstrably
   worked.** On 0038 `verify`'s first pass filed the bounce-branch assertion under *Not defects* —
   *"worth an `assert_contains` next time that block is open; not worth a red on its own."* The fresh
   `develop` session that picked it up overturned that triage (*"It is worth more than that"*), proved
   three pre-existing assertions stayed green under mutation, and generalised the finding into a rule
   about ladders with a catch-all `else`. `verify`'s next pass then found the same defect class on a
   third branch. A session continuing its own work carries its own severity judgment forward — it has
   already written the sentence saying the thing was not worth pursuing. **This is the risk that is not
   hypothetical, and no AC in this ticket eliminates it.**
2. **The eligibility test is self-assessed by the party that benefits from a generous reading.**
   FR4 exists to make the three conditions externally checkable in the verdict rather than felt, but a
   session that misclassifies a production-code fault as a missing assertion produces a fixture that
   pins the wrong behaviour, and the fresh `verify` in FR3 sees it green and closes. FR3 limits the
   blast radius; it does not close the hole.
3. **The window is already near its limit before the fix starts.** The four FAILing verify sessions
   measured ended at 118,160 / 126,737 / 151,554 / 173,029 tokens. Even a short fix on top of the
   upper two risks compaction, and compaction discards the verify context that is the entire
   justification for staying in the window. FR1's second kill criterion is aimed at exactly this.
4. **It puts `develop` work in a `verify` session, against *one skill per session*.** The rule is a
   deliberate exception to a load-bearing constraint, and exceptions to that constraint are how the
   stage boundary erodes one case at a time. FR5's abort is the containment.
5. **The saving may be real and still not worth the rule.** Three of four measured bounces in the
   whole corpus, and eligible instances are a subset of those. A rule that fires twice a quarter and
   costs a paragraph in the most-read skill file may lose on context rent alone — `CONVENTIONS_CORE.md`,
   *Every rule pays rent in context*.
