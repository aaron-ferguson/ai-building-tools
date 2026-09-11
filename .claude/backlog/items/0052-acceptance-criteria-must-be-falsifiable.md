---
id: "0052"
title: Require an acceptance criterion to name the input that would make it red
type: bug
next: verify
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
claimed_by: "504f"
claimed_at: 2026-09-11T21:31:41Z
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

### From the develop pass, 2026-09-01

- **FR7 and AC6 were themselves unfalsifiable, which is the defect this ticket is about.** They
  say each added citation "resolves under `tests/citations.test.sh`". That guard resolves
  **`CONCURRENCY.md` rule names only** — it anchors on `CONCURRENCY.md`,
  `CONCURRENCY-INCIDENTS.md` or the `rule:` marker and validates against `CONCURRENCY.md`'s own
  headings. A `testing-conventions.md` citation matches no anchor, so it is invisible: AC6 would
  have passed whether or not the citation resolved. Caught by reading the guard rather than the FR,
  which is `develop` Step 2's rule about a figure a ticket quotes concerning a file it does not own.
- **Resolved at filename level, not phrase level, and the difference is recorded in the guard's own
  header.** Every `*-conventions.md` named in a covered file is now resolved against the directory
  `config.yml` points at — a real failure mode, since the conventions live in a separate repo.
  Checking the cited *rule phrase* would need a citation marker this repo does not have: italics
  carry emphasis throughout, and reading an italicised span after a conventions filename as a rule
  name reports three existing spots (`skills/retro/SKILL.md` twice, `skills/verify/SKILL.md` once)
  that are emphasis, not citations. Introducing that marker is a **decision**, so it is parked
  rather than guessed at here.
- **A hand-run mutation that does not land proves nothing, and it is silent.** The first live
  mutation of the new check replaced `ui-conventions.md` in `skills/design/SKILL.md` — a filename
  that appears nowhere in any covered file. `sed` reported success, the suite stayed green, and the
  reading "the guard is wired to nothing" was available and wrong. This is exactly what
  `citations.test.sh`'s own `mutate()` helper exists to prevent, and the lesson is that the helper's
  discipline applies to mutations run by hand too: **assert the diff is non-empty before believing
  the result.** Re-run against `documentation-conventions.md`, which is present, and the guard fired
  with the file, the name and the directory, exit 1.
- **`verify/SKILL.md` crossed the soft size goal by 126 bytes**, so AC8's second branch applies.
  The payback test rejects relocation on condition **(b)**: mutation guidance is mandatory the
  moment an AC rests on an automated check, and a mandatory step behind a pointer is a step that
  gets skipped — which outranks the arithmetic. `skills/verify/SKILL.md` was added to the loop in
  `tests/skill-size.test.sh` that checks each justification names what was considered and carries
  no byte count; without that, the new entry was the one unguarded entry in the list.
- **The three rules FR7 cites were verified against the source, not the ticket.** *Anchor an
  assertion to the claim*, *assert membership never cardinality* and *break the definition never the
  expectation* are all present at `testing-conventions.md:15`.
- **TDD was clean on FR1–FR6 and not on AC6.** The prose guard was written first, run red on 14
  cases, then made green. The conventions checker was written before its fixtures, with red proven
  afterwards by the live mutation above. Recorded rather than smoothed over.

### From `FINDINGS.md`, landed 2026-09-05

Four entries, and each names a shape FR2's list does not yet carry.

- **An AC can be unfalsifiable *structurally*, because two ACs share a fixture whose construction
  they need to differ on** (FINDINGS 2026-09-03). `0085` AC7 needs contexts whose sums reconcile to
  an exact published decimal; AC10 needs contexts whose **rises are unequal**, because where they
  climb uniformly, crediting a rise to the turn that appended it and crediting it to the turn that
  followed both yield 10,000 and differ only in which bucket carries it. Every anchoring over the
  shared fixture is green under the off-by-one, so no amount of re-anchoring fixes it — the fix was a
  **second fixture in its own directory and a second tool run**, two cheap fixtures beating one that
  serves neither AC's discriminating case. Neither `verify` Step 3 nor FR1's rule asks whether the
  fixture an AC will be checked against *can* separate the defect from the correct behaviour, and
  that is a much cheaper question at capture time than at verdict time.
- **An AC that globs the test directory lets another session rewrite its contract mid-verify**
  (FINDINGS 2026-08-30). 0044's AC9 — "given the whole suite, when `for t in tests/*.test.sh` runs,
  then every suite passes" — was being verified while another session created
  `tests/reporting.test.sh` as an untracked file, so the set the AC quantifies over grew by one
  unfinished guard while the verdict was being formed. Nothing went red, because that run used a
  pinned clone, but the AC as written is satisfied against a moving target and two sessions can hold
  contradictory true answers to it at the same moment. This is FR1's own requirement in a form FR2
  does not list: **a glob names no input**. The fix direction is to pin such an AC to a commit or
  enumerate the suites it means. Note that this ticket's own AC7 is exactly that glob, and so is
  AC9 in several sibling rows — whoever builds this decides whether the rule applies to itself.
- **An interface-conversion AC wants the call-site count, not a prose note listing what was done**
  (FINDINGS 2026-08-30). 0053 routed `close.test.sh`'s eight inline `[ "$rc" -eq 0 ] && ok … || bad …`
  lines through new `assert_rc` helpers and recorded that in its notes, while leaving
  `claim.test.sh`'s five identical lines untouched and `close.test.sh`'s own line 402 unconverted —
  the twin of the line it *did* convert at 193, same shape, same file. Nothing failed: the suites are
  green, the flag works, and AC4's "all three honour it" is satisfied by three suites honouring it to
  three different depths. The gap is visible only by counting `saw:` lines against `ok` lines (13 of
  18 in claim, 92 of 93 in close), which no AC asked for and no guard measures. A partial conversion
  reading as a complete one is the same silent-untruth failure this ticket exists for.
- **An AC can require exactly the assertion `testing-conventions.md` warns against, and nothing says
  which wins** (FINDINGS 2026-08-30). 0074's AC1 asks a guard to check each skill cites the rule
  "exactly once"; the convention says *assert membership, never cardinality*, because "names exactly
  one X" goes quietly false the day a sibling adds a second — which is this ticket's own 0007 AC2
  case. Here the count genuinely **is** the contract: FR1 of that ticket is "stated in one place,
  cited never restated", so a second copy is the defect, and the guard was written to the AC with the
  reasoning recorded in its header. The judgement was sound and was made **silently** by the
  implementing session. `develop` Step 2 says to restate the contract and Step 3 says to load the
  conventions; neither says what to do when they collide, and the cheap answer — follow the AC so
  `verify` passes — is not obviously the right one. FR5 is the nearest hook: an AC that knowingly
  overrides a convention should have to say so where the next reader will see it.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **a fourth shape, arriving structurally rather
  than by oversight: an AC written as the outcome of an *agent-performed* operation has no runner in
  this repo, and nothing in the ticket says so.** `0105` AC1 read "given a withdrawal, `next_id` is
  unchanged or higher". No script withdraws a ticket and none mints an id — both are `queue` prose —
  so the outcome is unobservable at every level and the guard necessarily asserts the *sentence*
  instead. `qa_manual:` was empty, so the split was never declared at queue time, and the ticket
  gives a reader no way to tell this AC from one a runner discharges. The general question — how a
  prose-executed repo verifies a behavioural AC — is larger than this row, but the *declaration*
  half belongs here: a criterion whose subject is an operation only an agent performs should have to
  say so.
