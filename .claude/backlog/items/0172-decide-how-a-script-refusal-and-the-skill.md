---
id: "0172"
title: Decide how a script refusal and the skill that must satisfy it reach a session together
type: debt
next: develop
status: in-progress
qa_level: verify
close_by: verify
size: s
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0061", "0064"]
expects:
  - skills/develop/SKILL.md
  - tests/close.test.sh
  - CHANGELOG.md
claimed_by: "8ca7"
claimed_at: 2026-10-27T02:03:54Z
ac_digest: AC1=ae637e8d AC2=207697c6 AC3=c92a6850 AC4=3e7acf23 AC5=6b52b421 AC6=2f8b9f5e
touches:
  - skills/develop/SKILL.md
  - tests/close.test.sh
  - CHANGELOG.md
---

## Problem

**A committed backlog script and the skill that drives it take effect at different times, so a
refusal can land on a session before the instruction that explains it.** `0160` gave `close` a sixth
refusal — a `close_by: verify` ticket needs a `Conventions: <path>` line in its QA evidence — and
taught `skills/verify/SKILL.md` to write one. `.claude/backlog/close` is a committed file and binds
the very next session; a skill resolves from `~/.claude/plugins/cache/` at session start, so until a
release the next verify session meets a refusal its own instructions never mention.

The window opens for **any ticket whose FRs pair a script refusal with a skill change that satisfies
it**, and nothing in `develop` or the release checklist asks which half binds first. `0160` was
survivable only because the refusal text names the missing line and the fix — which was luck, not
design.

## Functional requirements

- **FR1** — `skills/develop/SKILL.md` Step 4 carries one rule for a ticket that adds a refusal to a
  backlog script (`skills/queue/templates/*`) which a skill change in the same ticket satisfies: the
  refusal must be self-sufficient for a session whose skill predates it. That means the refusal text
  (a) names what is missing, (b) names the fix concretely enough to act on without the skill, and
  (c) the refusal fires before anything is written, so the session can fix and re-run.
- **FR2** — The same rule requires the ticket's test to run the script into the refusal and assert
  that its stderr names the fix — the form `tests/close.test.sh` already uses for `0160` AC3
  (`assert_contains "names the line it wants"`).
- **FR3** — A guard in `tests/` reds if the FR1 rule's anchor phrase leaves Step 4 of
  `skills/develop/SKILL.md`. The phrase sits on one line (CLAUDE.md, *Tests*: a rewrapped guarded
  phrase cannot be matched).
- **FR4** — `CHANGELOG.md` `## Unreleased` carries one note for the new develop rule.

## Non-functional requirements

- **Size** — the develop rule is at most four lines of prose; `tests/skill-size.test.sh` stays green.
  If it cannot, trim elsewhere in develop under the ticket rather than raising the ceiling.

## Acceptance criteria

- [ ] AC1 — Given `skills/develop/SKILL.md`, when the text between `## Step 4` and `## Step 5` is grepped for `a refusal that arrives before its skill`, then exactly one line matches.
- [ ] AC2 — Given that rule, when read, then it states all three of FR1's requirements (names what is missing, names the fix, refuses before writing) and FR2's test requirement, and cites `0160` as the case it generalises.
- [ ] AC3 — Given the suite, when the anchor phrase is deleted from `skills/develop/SKILL.md`, then a test in `tests/` fails naming it; when restored, it passes — both runs recorded in QA evidence.
- [ ] AC4 — Given `tests/close.test.sh`, when run, then the `0160` AC3 assertion `names the line it wants` passes (the prior art FR2 cites still holds).
- [ ] AC5 — Given `CHANGELOG.md`, when `## Unreleased` is read, then one note names the develop rule for self-sufficient refusals.
- [ ] AC6 — Given the whole suite (`for t in tests/*.test.sh; do "$t" || exit 1; done`), when run, then it is green, including `tests/skill-size.test.sh`.

## QA plan

`verify`: run the suite; perform AC3's delete-and-restore by hand in the working tree (restore with
`git restore -- skills/develop/SKILL.md`) and record both outputs; read the rule for AC2.

## Out of scope

- Re-litigating `0160`'s refusal, which is correct.
- Making skills resolve at any time other than session start; that is not this repo's to change.
- An atomic-release gate in `develop` Step 5, and a version- or date-stamped refusal that warns
  before it hardens — both rejected below.
- Retro-fitting a test onto every existing refusal in `close`, `claim`, `handoff`, `next`, `reopen`;
  a sweep of existing refusal texts is a separate ticket if anyone files one.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park made while building `0160`. Routed to `design` because
  both candidate answers are whole mechanisms and neither is obviously right.
- **2026-10-25 (design, decided)** — **Neither atomic release nor a degrading refusal: the refusal
  carries its own instruction.** A pair is safe to land in either order when a session whose skill
  predates the refusal can still satisfy it from the refusal text alone. That makes the order the
  halves bind in irrelevant, so neither half has to wait.
  - **Re-verified 2026-10-25:** `diff -q .claude/backlog/close skills/queue/templates/close` printed
    nothing (identical at `811130d`). In consumer projects `queue` Step 0 re-copies the scripts from
    the *installed* skill's `templates/` (`skills/queue/SKILL.md`, "Compare the bytes"), so script
    and skill usually arrive from one plugin version. The window is widest **here**, where `develop`
    commits the live copy alongside the template. It also opens wherever a committed script copy
    moves ahead of a machine's install or a long-running session. A self-sufficient refusal covers
    all three cases. A release gate covers only the first.
  - **Prior art:** nearly every refusal in `skills/queue/templates/close` already names its fix:
    `claim it first: ./claim $ID`, `rewrite the criteria in the '- [ ]' form … and close again`,
    and `0160`'s own `Write the path verify Step 1 resolved, then close`. All the refusals there are
    "counted BEFORE anything is written". `tests/close.test.sh` asserts `0160`'s refusal `names the
    line it wants`. The decision turns that habit into a rule with a test, so it no longer depends
    on luck.
  - **Rejected — atomic release.** An unattended stage cannot run `tools/release` (`sprint`
    Step 8), so a driven `develop` would block on a person for every such ticket. It also does not
    close the window: a session already running keeps the old skill until restart, and another
    machine keeps it until its own update.
  - **Rejected — warn for one cycle, then harden.** The script cannot know which skill version the
    calling session loaded, so a stamp would key on a date or a version, and neither one says what
    the session is running. A warning from a gate is a control that does not run
    (CONVENTIONS_CORE, *A security control that cannot run blocks*). It would also need a second
    hardening ticket per refusal, a mechanism this repo has never carried.
  - **Trade-off accepted:** the gap is not closed. A session whose skill predates the refusal still
    meets it, and spends a turn reading it and acting on it. The cost is one refused call with
    nothing written, against a release gate on every pair.
  - **Depends on:** the fix being expressible in a few lines of stderr. A refusal whose fix needs a
    whole procedure is the one case this does not cover. No such refusal exists yet. If one is ever
    proposed, that ticket goes back to `design`.
  - **Criteria accounting:** the ticket arrived with no FRs or ACs, so all of them are new. Re-read
    against what was written: `qa_level: verify` stays, because AC2 is a reading. `close_by: verify`
    is set explicitly. `size` drops m → s, since it is one rule, one guard and one note.
    `expects:` now names the files a build touches: `skills/retro/SKILL.md` and
    `skills/queue/templates/close` are dropped, and nothing in either changes.
