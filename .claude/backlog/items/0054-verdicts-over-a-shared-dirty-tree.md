---
id: "0054"
title: Give develop and verify a rule for a result taken over a shared dirty tree
type: bug
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0005", "0026", "0029", "0050"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`develop` Step 5 says to run the whole suite and never hand a red tree to QA, and offers a fork for
triaging a red: falsified versus exposed. Both branches assume the tree is a state that exists as a
commit. In this repo it routinely is not, and four distinct failures follow.

**A red that is another session's uncommitted work.** Two runners went red in one loop and green on
three immediate re-runs; the cause was neither a real failure nor flake but ~30 files mid-rename in
the shared working tree. The falsified/exposed fork cannot classify a red whose cause is
uncommitted and someone else's, and the repeat-both-sides advice for a re-rolling check points at
the wrong diagnosis. What worked: `git status` first, then the suite in a worktree at *my last
commit* — a verdict about a tree that actually exists.

**A red the tree is *supposed* to have.** Another window was mid-TDD on 0031 with its failing tests
written and its implementation not yet, so `tests/next.test.sh` was correctly red and could not be
made green by anyone but them. Step 5's attribution procedure resolves it, but the gate reads as a
blocker until you get there, and what the next `verify` session needs is the *proof* carried into
the handoff, not the sentence "not mine".

**A suite that is measuring a moving target.** 0026's harvest reads a live transcript store, and
the session count moved 30 → 31 mid-run because another window opened a session. Any ticket whose
output is a measurement of the machine it runs on needs its snapshot pinned and recorded, and no
step says so.

**A ticket handed on with part of its own work uncommitted.** 0026 was set to `next: verify` by
`e604703` while the tail of a rename it depends on — two words in `MEASUREMENT.md`, the file that
ticket is *about* — sat in the working tree. The next `verify` session opens on a dirty tree on the
one file its assertions read, which by Step 2 makes its verdict advisory before it has run
anything, and puts an uncommitted change one careless `git add` away from landing under someone
else's message.

Related and already known: a committed `touches:` did not stop another session rewriting that file
forty minutes later, turning a held ticket's own guard red against a contract it never agreed to.
`touches:` is advisory by design; nothing warns either side, and the collision surfaced only
because the verifier happened to re-run the suite at the end.

## Functional requirements

- FR1 — `skills/develop/SKILL.md` Step 5 requires `git status --porcelain` to be read **before**
  any full-suite result is believed, and names the three causes a red can have that the existing
  fork does not cover: another session's uncommitted work, another session's deliberate red-first
  TDD, and a measurement whose subject moved mid-run.
- FR2 — It names the remedy that worked — run the suite in a throwaway worktree at your own last
  commit, which is a verdict about a tree that exists — and says when it is worth the cost.
- FR3 — A red that the tree is *supposed* to have right now is a named case, and the step says the
  evidence for that attribution is carried into the handoff rather than asserted in a sentence.
- FR4 — A ticket whose output is a measurement of the machine it runs on has its snapshot pinned
  and the pin recorded, and the step says so.
- FR5 — Handing a ticket to the next stage requires confirming `git status --porcelain` is clean of
  **your own** paths, and `skills/verify/SKILL.md` Step 2 points at that requirement from the
  receiving side.
- FR6 — `references/CONCURRENCY.md` states that a `touches:` collision is invisible to both
  sessions and that neither is warned, since today the field reads as though declaring it achieves
  something.
- FR7 — Every rule added cites the governing convention rather than restating it, and each citation
  resolves under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rules land in the skills and the concurrency reference per the split 0020 made, and cite rather than copy | `documentation-conventions.md` |
| Progressive delivery | These skills ship to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/develop/SKILL.md` Step 5, when read, then it requires reading
  `git status` before believing a full-suite result.
- [ ] AC2 — Given that step, when read, then it names another session's uncommitted work, another
  session's deliberate red, and a moving measurement as causes distinct from falsified and exposed.
- [ ] AC3 — Given that step, when read, then it names the worktree-at-your-last-commit remedy.
- [ ] AC4 — Given that step, when read, then it requires a machine-measuring ticket to pin and
  record its snapshot.
- [ ] AC5 — Given the handoff instruction in `skills/develop/SKILL.md`, when read, then it requires
  the session's own paths to be committed first.
- [ ] AC6 — Given `skills/verify/SKILL.md` Step 2, when read, then it points at AC5's requirement
  from the receiving side.
- [ ] AC7 — Given `references/CONCURRENCY.md` *The working tree is shared too*, when read, then it
  states that a `touches:` collision warns neither session.
- [ ] AC8 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.

## QA plan

- **Level:** verify — the deliverable is prose in three files and no test runner applies; the
  scripted assertions are the greps named below plus `tests/citations.test.sh`.
- **Why this level:** nothing executable changes. Each AC is a scoped grep with a named phrase.
- **Specific checks:** each grep **scoped to the step or the named rule, not to the file**, and
  matching a phrase short enough to sit on one source line. Then `tests/citations.test.sh`,
  `tests/skill-size.test.sh` and the full suite.

## Out of scope

- **Changing the file-scope rule so the collisions stop happening.** That is 0050. This ticket
  tells a session what to do with a result taken in the world as it is.
- Making `touches:` enforce anything. `CONCURRENCY.md` is explicit that it warns rather than locks,
  and FR6 asks only that the limitation be stated.
- Automating the worktree run. Naming it is enough; a script for it is a separate ticket.

## Notes & decisions

- Routed to `develop`: every remedy is already known and was used successfully — `git status`
  first, a worktree at your own last commit, pin the snapshot. Nothing is undecided.
- FR5 and AC5 are the cheapest half and the one that prevents the worst outcome: a verdict that is
  advisory before it starts, because the previous stage left its own work in the tree.
