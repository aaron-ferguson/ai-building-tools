---
id: "0064"
title: Make a stage skill say which copy of it is running
type: bug
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0026", "0061"]
expects:
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - skills/queue/SKILL.md
  - skills/prototype/SKILL.md
  - skills/retro/SKILL.md
  - README.md
  - CLAUDE.md
claimed_by:
claimed_at:
touches:
---

## Problem

A stage whose name collides with a built-in skill is a stage that can silently not run. The session
that verified 0026 invoked `/verify` and loaded the **built-in** evidence-capture skill rather than
`ai-building-tools:verify`; this repo's stage protocol had to be read out of
`skills/verify/SKILL.md` by hand afterwards. Nothing in the run said which skill had answered.

The specific collision the finding named may or may not still exist, and this ticket does not
depend on it: **the class is live now on a different name.** The skill listing available to a
session in this repo today carries a built-in `design` — a canvas-authoring skill — alongside
`ai-building-tools:design`, the stage that settles a backlog decision. Those are unrelated jobs with
one short name, and the failure is silent in the worst direction: the built-in answers, produces
something plausible, and the ticket at `next: design` is never touched.

The stakes are higher than a mis-typed command because these skills *write*. A stage session that
believes it is `ai-building-tools:design` will hand off a ticket, edit `QUEUE.md` and commit; one
that has actually loaded a different skill will not, and the queue is left saying the row moved.

Two facts make this cheap to fix and easy to keep missing. The plugin-qualified form
(`/ai-building-tools:design`) always resolves correctly and is never ambiguous. And a skill can say
what it is in its first line, which turns a silent mis-resolve into something a reader notices in
the transcript.

## Functional requirements

- FR1 — Each of the six stage skills opens by naming itself unambiguously — the plugin and the
  skill — so a session that loaded a different skill of the same name is visible in its own output.
- FR2 — `README.md` documents the plugin-qualified invocation form as the one to use, and says why:
  a bare name can resolve to a built-in or another plugin, silently.
- FR3 — `CLAUDE.md`'s existing paragraph on the installed copy being what runs also covers *which*
  skill answered, since both are the same failure — a session executing something other than what
  this repo contains — and today it covers only the version.
- FR4 — Any place in this repo that tells a reader to invoke a stage by bare name is updated to the
  qualified form, so the documentation does not itself recommend the ambiguous call.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The invocation form is documented where a new reader starts (`README.md`) and where a session in this repo reads its own rules (`CLAUDE.md`) | `documentation-conventions.md` |
| Progressive delivery | The skills ship to every machine installing the plugin, and a name collision depends on what else that machine has installed — so the fix must work without knowing what else is there | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given each of the six `skills/*/SKILL.md` files, when the opening lines are read, then
  each names the plugin and the skill.
- [ ] AC2 — Given `README.md`, when read, then it names the plugin-qualified invocation form and
  says a bare name can resolve elsewhere.
- [ ] AC3 — Given `CLAUDE.md`, when read, then its paragraph on what actually runs covers which
  skill answered, not only which version.
- [ ] AC4 — Given every shipped file in this repo, when grepped for an instruction to invoke a
  stage by bare name, then none remains outside of prose quoting a user's words.
- [ ] AC5 — Given the whole suite, when it runs, then every suite passes — including
  `tests/skill-size.test.sh`, with a recorded justification naming this ticket for any file pushed
  over its goal.

## QA plan

- **Level:** verify — the deliverable is prose across eight files and no test runner applies; the
  scripted assertions are the greps below plus the size guard.
- **Why this level:** nothing executable changes, and each AC is a grep with a named phrase.
- **Specific checks:** AC1 is a loop over the six skill files asserting on their opening lines
  specifically, not on the file. AC4 is a repo-wide grep whose expected result is empty — write it
  so that a match prints the offending file and line, since an absence assertion that only exits
  non-zero cannot say what it found. Then `tests/skill-size.test.sh` and the full suite.

## Out of scope

- **Renaming any skill.** It would break every reference in this repo, in `RANKING.md`, in 40-odd
  item files and in whatever other machines have installed — a migration far larger than the
  failure, and the qualified-invocation form removes the harm without it. If renaming is ever
  wanted it is its own ticket with its own migration plan.
- **Detecting the collision automatically.** A guard here would have to know what else is installed
  on the machine, which this repo cannot see. FR1 makes it visible in the transcript instead.
- Whether the *installed* copy matches this repo. That is 0061 — the same family, a different axis.

## Notes & decisions

- Routed to `develop`: FR1's mechanism is a line of prose per file, and the qualified-invocation
  form is a fact about how skills resolve rather than a decision. Renaming, the only option that
  would have needed a design pass, is ruled out in *Out of scope* on migration cost.
- **The finding's specific example is treated as unverified and the ticket does not rest on it.**
  Whether `/verify` still collides could not be confirmed from inside this session; the `design`
  collision was confirmed from the skill listing this session was given. The FRs are written against
  the class so that neither answer changes the work.
