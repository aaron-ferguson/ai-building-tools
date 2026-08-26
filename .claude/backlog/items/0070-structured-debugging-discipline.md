---
id: "0070"
title: Add a structured, feedback-loop-first debugging discipline
type: feature
next: design
status: ready
qa_level: verify
size: l
created: 2026-08-26
source: agent
parent:
blocked_by: []
relates: ["0069"]
expects:
  - skills/develop/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Neither `/develop` nor `/verify` has a distinct discipline for a bug ticket that resists a first
look: something intermittent, a regression between two known-good states, a symptom that doesn't
reproduce on the first attempt. `/develop` Step 4 says "for a bug, the first test reproduces the
bug and stays as a permanent guard" — correct once a reproduction exists, but silent on how to get
one when it doesn't. `/verify` checks acceptance criteria against a build; it doesn't diagnose.

A comparable external skill (`diagnosing-bugs`, surveyed 2026-08-26) makes one thing the whole
skill: refuse to theorize about the cause until there is a tight, red-capable feedback loop — one
command, already run, that goes red on this exact bug and green once fixed — then generate 3–5
ranked, falsifiable hypotheses before testing any of them, then instrument to distinguish between
them one variable at a time, then turn the minimised repro into the regression test only once a
correct seam exists for it (treating "no correct seam" as its own finding, handed off rather than
papered over with a shallow test that gives false confidence).

That ordering — loop before hypothesis, ranked hypotheses before instrumentation, regression test
at a real seam or a named absence of one — is a discipline this toolkit does not write down
anywhere, and `/develop`'s single line for bugs assumes the hard part is already done.

## Open design question

- **Question:** Does this become a new standalone skill (e.g. `/diagnose`) invoked before
  `/develop` claims a hard bug ticket, or a step inserted into `/develop` itself, gated on
  `type: bug` plus a signal that the first reproduction attempt failed? The surveyed repo makes it
  standalone specifically because the loop-building phase can consume a whole session on its own —
  folding that into `/develop` risks breaking this toolkit's "one skill per session" cost
  discipline for the bug tickets that *don't* need it.
- **Why it blocks specification:** a standalone skill needs its own `SKILL.md`, a place in this
  repo's skill list, and a description that tells a session when to reach for it instead of
  `/develop`; a step inside `/develop` needs a gate condition and changes `/develop`'s own
  token-cost profile for every bug ticket, not just the hard ones.
- **Settle it with:** `/design` — weigh the cost data `/develop` already carries (Step 4's
  "191,752 tokens per turn" note) against how often a bug ticket in this backlog's own history has
  needed more than a first-look fix.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — Whichever skill owns this states, as its first and heaviest step, that no hypothesis is
  tested until a reproduction command exists that has already been run at least once and shown to
  go red on the reported symptom.
- FR2 — The skill requires 3–5 ranked, falsifiable hypotheses (a stated prediction each) before any
  instrumentation, and states that jumping to a single hypothesis is the exact failure this
  discipline exists to prevent.
- FR3 — The skill states the "no correct seam" outcome explicitly: if the only available test seam
  is shallower than the bug's real trigger path, that absence is itself the finding, reported
  rather than papered over with a shallow regression test.
- FR4 — Any command output, log line, or captured artifact the skill has the session show is
  redacted for secrets and — per this toolkit's own `company: none` / no-Neumo-material rule — for
  anything that would identify a specific company, court, case, or client, before it appears in a
  report or a commit.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | Any shown command output or captured artifact has secrets redacted before display or commit | `security-conventions.md` |
| Privacy & data | Any shown command output has personal or client-identifying data redacted before display or commit | `data-privacy-conventions.md` |
| Documentation | The loop-before-hypothesis and ranked-hypothesis rules are stated once, in the owning skill file | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled.

- [ ] AC1 — Given a hard bug ticket taken up by the owning skill, when the session reaches for a
  fix, then it can point to one command it has already run that went red on the reported symptom.
- [ ] AC2 — Given the owning skill file, when read, then it lists a ranked, falsifiable-hypothesis
  requirement before any instrumentation step.
- [ ] AC3 — Given a bug whose only test seam is shallower than its trigger path, when the owning
  skill reaches its fix-and-regression-test step, then it reports the absent seam as a finding
  rather than writing a shallow test.
- [ ] AC4 — Given any command output or artifact the skill shows, when it is displayed or
  committed, then secrets and company/court/case/client-identifying content are redacted first.

## QA plan

- **Level:** verify — provisional; a new standalone skill file with no executable script stays
  `verify`; revisit if the design answer adds a script (a bisection or fuzz harness template).
- **Why this level:** the deliverable is a skill-file discipline, not code, at this stage.
- **Specific checks:** scoped greps for the loop-first rule, the ranked-hypothesis requirement,
  the no-seam finding, and the redaction rule, each within the section that states it.

## Out of scope

- Building any specific debugging harness or script template — a follow-on ticket once the skill
  exists.
- Retrofitting this discipline onto tickets already closed in `DONE.md`.

## Notes & decisions

- Captured 2026-08-26 from a comparison against a third-party skills repo (`diagnosing-bugs`,
  github.com/mattpocock/skills).
- FR4 is this ticket's own addition, not verbatim in the surveyed source — its redaction step
  covers secrets only; this toolkit's context (built by, and sometimes run against, projects that
  carry a `company:` profile) needs the wider rule stated explicitly, even though this repo's own
  `company: none` means it never fires here.
- Relates to 0069 — see that ticket's note.
- Sized `l`: plausibly a new skill, not a one-file edit.
