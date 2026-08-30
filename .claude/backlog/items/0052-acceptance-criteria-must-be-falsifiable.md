---
id: "0052"
title: Require an acceptance criterion to name the input that would make it red
type: bug
next: develop
status: in-progress
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0032", "0033", "0036", "0042", "0057"]
expects:
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/templates/item.md
  - tests/citations.test.sh
claimed_by: "becd"
claimed_at: 2026-08-30T17:16:12Z
touches:
---

## Problem

`verify` Step 3 says *"a check that cannot be made to fail leaves its AC unverified"* and puts the
burden in the right place. Nothing upstream of it asks the same question, and Step 3's own form of
it is too coarse in both directions. Six live instances, five where an unfalsifiable criterion got
all the way through and one where the rule over-condemned a sound guard.

**An AC can be arithmetically unable to fail.** 0036's AC13 read "the last cycle's cost is within
the stated tolerance of the first". With ~800 tokens of per-cycle growth against a ~20k per-turn
floor, no tolerance anyone would write could catch a regression — a green light dressed as a
measurement. It survived a `queue` pass *and* a `design` pass. `verify` checks whether an AC is
*met*; nothing checks whether it *could have been* red.

**An AC can assert cardinality and go quietly false.** 0007 AC2 reads "names exactly one operation
that takes the lock", written 2026-08-18 when `CONCURRENCY.md` listed two. 0023 added a third on
2026-08-23, so a literal build now strips the lock from `./close` — automating away the atomicity
0023 and 0024 exist to provide. Nothing flags it: every path 0007 names was untouched, and the
count is correct-looking prose in a ticket that reads fresh. 0033 guards stale rule *citations*; a
stale *count* still resolves and still reads fine.

**An AC can prescribe a mutation that passes under both the bug and the fix.** 0032's AC5 said
"when that phrase is added to the paragraph *following* the batching paragraph, then the suite still
passes — proving the window no longer reaches it." It proves nothing: adding a phrase on the far
side leaves every `present` assertion satisfied by the real paragraph, so the suite is green with
the old window *and* the new one. The discriminating mutation is to **move** a pinned phrase across
the boundary, which was verified after the fact. This happened on the one ticket whose whole subject
was adjacent measurement.

**An absence assertion can be built on an estimated wrong answer.** `tests/measurement.test.sh`
named `163.25` as the per-line total proving the message-id dedup gone; removing the dedup two
different ways produces `165.25`. The guard still reddens via a generic branch, so the message that
would have named the cause can never fire.

**A QA plan can contradict a guard another ticket already shipped.** 0026's plan asserted
`grep -c 0026` is zero in `develop`'s SKILL.md; `tests/batching.test.sh` (0025) asserts `0026` is
*present* in the same paragraph. Both were satisfiable at once only because the plan qualified
itself; an unqualified one would have forced a session to edit another ticket's guard to close its
own.

**And Step 3 over-condemns in the other direction.** Three branches in `./next --drive`'s phase-A
ladder are mutation-silent: deleting any of them drops through to a final `else` that escalates
with the same exit code and a vaguer message. Read literally, Step 3 fails all three — which pushes
a QA session toward asserting message wording everywhere and makes every future rewording a red.
The distinction it is missing: mutate, then ask whether the AC's **named outcome** changed. If it
did, the AC is unverified. If only the *message* did, that is a message assertion worth adding, not
a red. Both cases were live in one ticket.

`testing-conventions.md` already carries the underlying rules — *anchor an assertion to the claim*,
*assert membership never cardinality*, *break the definition never the expectation* — landed by the
2026-08-25 retro. What is missing is the point in the lifecycle where anyone is asked.

## Functional requirements

- FR1 — `skills/queue/SKILL.md`'s acceptance-criteria step requires each AC to name the input,
  change or mutation that would make it red, and says an AC for which none can be named is not a
  criterion yet.
- FR2 — That step names the three shapes seen here that read as criteria and are not: a tolerance
  wider than the effect it measures, a cardinality claim over a set the ticket does not own, and a
  mutation applied on the far side of the boundary under test rather than across it.
- FR3 — `skills/queue/SKILL.md` requires a QA plan's **absence** assertions to be checked against
  the guards already shipped, so a new plan cannot demand the removal of a phrase an existing test
  requires.
- FR4 — An absence assertion's expected wrong answer is computed from the fixture rather than
  estimated, or the assertion does not name a specific value.
- FR5 — `skills/verify/SKILL.md` Step 3 distinguishes an AC whose **named outcome** survives its
  mutation from one where only the message changed: the first is unverified, the second is a
  message assertion worth adding rather than a failure.
- FR6 — `skills/queue/templates/item.md`'s acceptance-criteria section carries the FR1 requirement
  where the criteria are written, not only in the skill, since the template is what a cold session
  fills in.
- FR7 — Every rule FR1–FR5 adds cites `testing-conventions.md` rather than restating it, and each
  citation resolves under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rules are cited from `testing-conventions.md`, never copied into the skills — a copy drifts the first time either is edited, and `verify` then checks the stale copy | `documentation-conventions.md` |
| Progressive delivery | These skills ship to every machine installing the plugin; the release is the version bump and the install, per this project's `CLAUDE.md` | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/SKILL.md`'s acceptance-criteria step, when read, then it requires
  each AC to name what would make it red.
- [ ] AC2 — Given that step, when read, then it names the tolerance-too-wide, the cardinality and
  the wrong-side-mutation shapes.
- [ ] AC3 — Given that step, when read, then it requires a QA plan's absence assertions to be
  checked against shipped guards.
- [ ] AC4 — Given `skills/verify/SKILL.md` Step 3, when read, then it separates an unchanged named
  outcome from an unchanged message, and calls only the first unverified.
- [ ] AC5 — Given `skills/queue/templates/item.md`, when its acceptance-criteria section is read,
  then it carries the name-what-would-red requirement.
- [ ] AC6 — Given every convention citation added by this ticket, when `tests/citations.test.sh`
  runs, then each resolves.
- [ ] AC7 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.
- [ ] AC8 — Given `tests/skill-size.test.sh`, when it runs after these additions, then either every
  skill file is within its goal or the one that is not carries a recorded justification naming this
  ticket.

## QA plan

- **Level:** unit — the assertions are greps over skill prose plus the citation guard, and this
  project's `unit` command runs every `tests/*.test.sh`.
- **Why this level:** no runner applies to prose, but every check here is scripted and the existing
  suites already own citation resolution and file size.
- **Specific checks:** each prose grep **scoped to the step it asserts on, not to the file** — a
  document-wide match pins vocabulary rather than structure, which is the defect 0042 exists for.
  Match phrases short enough to sit on one source line, since `grep` is line-based and rewrapping a
  guarded paragraph is a breaking change here. Then `tests/citations.test.sh`,
  `tests/skill-size.test.sh` and the full suite.

## Out of scope

- **Repairing the specific ACs named above.** 0007 AC2's stale count is 0007's own to fix when it
  is built; 0032 and 0036 are closed and their results stand. This ticket changes the rule, not the
  history.
- `tests/measurement.test.sh`'s `163.25` constant. FR4 states the rule; that file's repair belongs
  with 0042 and 0051, which already hold it.
- Auditing every open ticket's ACs against the new rule. A sweep is a separate ticket.

## Notes & decisions

- Routed to `develop`: every rule is already written down in `testing-conventions.md`; what is
  missing is a step that asks the question, and each FR names the step and what it must say.
- **Tier 1, and the argument is worth recording.** Nothing is bleeding in the code — what is wrong
  is that criteria which cannot fail have been closing tickets, so the record of what was verified
  is silently untrue. That is "output that is silently wrong", and nobody is counting it.
- FR5 is the half most likely to be dropped as a nicety. It is not: without it the fix to Step 3
  makes QA sessions assert message wording everywhere, and this repo's guards are already too
  tightly coupled to prose wording.
- `expects:` overlaps 0057 on `skills/queue/SKILL.md` and `templates/item.md`, and 0056/0054 on the
  other skill files. That collision is real and is what 0050 exists to settle; the two tickets are
  not merged because their root causes are unrelated, and merging on collision grounds is how a
  ticket ends up with a contract nobody agreed to.
