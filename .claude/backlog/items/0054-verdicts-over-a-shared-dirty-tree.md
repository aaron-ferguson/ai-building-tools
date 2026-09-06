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

### From `FINDINGS.md`, landed 2026-09-05

- **What makes *advisory* near-certain here is the width of the evidence set, not the dirtiness of
  the tree** (FINDINGS 2026-08-30, two entries). `tests/measurement.test.sh`'s privacy assertion
  greps the whole repo through `git grep`, which reads the **working tree** — confirmed empirically
  in a throwaway repo — so every tracked file joins the evidence set of any verdict resting on that
  suite, and an AC of the form "the whole suite passes" (0042's AC6) pulls it into every close. A
  Documentation NFR reaches the same place by a different route: 0044's row required its fourth
  refusal ground to land in `skills/verify/SKILL.md` Step 5, so that path is in the evidence set by
  the row's own wording, and `skills/**/SKILL.md` is the one surface every suite-wide ticket edits.
  0044 verified green on nine ACs and three NFRs and still could not close, because 0074 held that
  file uncommitted; the substance agreed in both copies, and Step 7 correctly refuses that as
  grounds to close. So this ticket's rule needs an evidence set narrower than "every path the
  assertion touched": a repo-wide guard excluded by name, and a path a row cites for
  *documentation* not carried on the same terms as one an assertion executed.
- **The dirty set moves during the pass, so the label has to be re-taken at verdict time — and
  `0085` removed the turn that would catch it** (FINDINGS 2026-08-30 `[0f0a]` and 2026-09-03).
  Within one session the dirty set changed three times — `tests/next.test.sh` held by 0045, then
  `tests/measurement.test.sh` held by 0051, then nothing — and the advisory label flipped with it.
  Step 2 takes the snapshot once and Step 7 intersects it, but the label describes the state the
  verdict *closes against*, which is the state at close time. `0085`'s FR7 then made Step 7 read
  "the tree is either clean throughout or Step 2 already said so", which is what licenses issuing
  no git command at verdict time; verifying `0085` falsified it, Step 2 having seen a clean tree
  before `0081` dirtied six files including `skills/verify/SKILL.md`, inside that run's evidence
  set, mid-pass. Followed literally the pass closes on a plain PASS. `CONCURRENCY.md` *The working
  tree is shared too* says a second session starting mid-pass is the normal case here, so the saved
  turn and the advisory label are in direct tension and only one can be right. The check belongs
  immediately before `./close`, with the AC run re-done when a path in the evidence set moved —
  possibly a Step 5 line rather than a Step 2 one.
- **`pgrep` is the wrong wait condition for a shared suite, because the thing to wait for is a
  *sequence* of runs** (FINDINGS 2026-09-05, from `0076`). `develop` Step 5 tells the session
  arriving second to wait, and prescribes `pgrep -f <runner>`. A concurrent `verify` was running
  mutation batches over `tests/claim.test.sh` and `skills/queue/templates/handoff` — `sed -i.bak`,
  run, restore, next file — so `pgrep` reads clear in every gap between runs, and a whole-suite run
  started in one of those gaps reads another session's deliberately-broken file as a red of its
  own. The condition that actually holds is *no runner process **and** a clean `git status`,
  sustained over several samples*, which that session had to invent. This is FR1's failure arriving
  through the step's own remedy rather than through the result.
- **FR2's worktree remedy produces a false red in this repo unless the conventions directory sits
  beside it** (FINDINGS 2026-09-05, from `0076`). `.claude/backlog/config.yml` carries
  `conventions.path: ../ai-building-conventions`, which resolves against the repo's *parent*, so a
  throwaway worktree under `scratchpad/` makes `citations.test.sh` red with *"no conventions
  directory resolved"* — a red produced by where the worktree was put, inside the exact procedure a
  session runs to find out whether a red is its own. Siting the worktree beside a symlinked
  conventions directory fixes it, and nothing says to. Step 5 names `node_modules` as the thing a
  worktree needs symlinked; in this repo it is the conventions directory, and FR2 should say so.
