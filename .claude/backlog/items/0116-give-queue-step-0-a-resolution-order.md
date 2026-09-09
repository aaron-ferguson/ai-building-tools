---
id: "0116"
title: Give queue Step 0 a resolution order instead of a scaffold instruction
type: bug
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: m
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0111", "0101"]
expects:
  - skills/queue/SKILL.md
  - references/CONVENTIONS.md
  - tests/findings-routing.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`queue` Step 0 says "Find `.claude/backlog/` at the project root. If it doesn't exist, scaffold
it", and read literally from a directory that is not a repo, the instruction is to create one
there.** Invoked from `/Documents/AI` — not a git repository, holding no backlog, with four real
project backlogs beneath it — the literal reading manufactures a fifth backlog in a directory `git`
does not track. Nothing in the step asks whether the current directory *is* a project.

This is the same missing-resolution-order shape `0111` files against `retro` Step 1, and the
failure mode is worse. `retro`'s gap makes a sweep read the wrong buffer; this one creates a buffer
that should not exist, in a place nothing will ever look at again.

Explicitly **not** folded into `0111`. `0111`'s design question is which buffers a *sweep* reads;
this is a create-or-refuse decision at *scaffold* time, and answering either one does not settle
the other. `0101` is the conventions half of the same shape.

`references/CONVENTIONS.md` rung 3 already has the right instinct for a resolution that fails —
*do not guess a path, do not search the filesystem for a directory that looks right*, stop and say
so. Step 0 has no equivalent.

## Functional requirements

- FR1 — `queue` Step 0 states a resolution order for `.claude/backlog/`, in the shape
  `references/CONVENTIONS.md` uses: the explicit answer first, the derived one second, and a
  loud stop last.
- FR2 — Step 0 names at least one condition under which it **refuses to scaffold** rather than
  scaffolding, and the not-a-git-repository case is one of them.
- FR3 — the refusal names what the session should do instead (`cd` to the project, or say which
  project is meant), rather than only declining.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule is stated in the skill and cited, never restated from `CONVENTIONS.md` | `documentation-conventions.md` |

## Open design question  *(only while `next: design`)*

- **Question:** what is the *authority* for "this is a project" at scaffold time — the presence of
  a git repository, a `CLAUDE.md`, an explicit user instruction, or some ordered combination? And
  where exactly one nested backlog exists beneath the cwd, does `queue` offer it or refuse?
- **Why it blocks specification:** no acceptance criterion can be written for FR2 until the
  refusal condition is decided; "not a git repository" is one candidate and may be too narrow
  (a fresh un-initialised project is a legitimate scaffold target).
- **Settle it with:** `/design`

## Acceptance criteria

Written once the design question is settled.

## QA plan

- **Why that level:** the artifact is skill prose; the checks are greps over `skills/queue/SKILL.md`
  for the resolution order and the refusal condition.
- **Specific checks:** to be written with the ACs.

## Out of scope

Changing `references/CONVENTIONS.md`'s own ladder — that generalisation has its own finding and is
not settled here. Anything about which buffers a sweep reads (`0111`).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-07. The verbatim reproduction is in
  that entry: invoked from `/Documents/AI`, Step 0's literal instruction is to create a backlog in
  an untracked directory above four real ones.
