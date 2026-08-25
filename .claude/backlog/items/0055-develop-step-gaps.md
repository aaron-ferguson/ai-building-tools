---
id: "0055"
title: Fill the develop steps that have no case for what now happens routinely
type: bug
next: develop
status: ready
qa_level: verify
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0031", "0038", "0052", "0054"]
expects:
  - skills/develop/SKILL.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Six places in `skills/develop/SKILL.md` where a session following the step literally does the wrong
thing, or has to invent the answer. All were hit while building real tickets.

**Step 5.4 deletes the record Step 1 asked for.** Step 1 says to declare a file you will create in
`touches:` and say inline that it is new; Step 5.4 says to clear `touches:` on handoff. Building
0038 turned up one file `expects:` had not named (`README.md`) — so following both instructions
deletes the only durable record that the prediction was short, which is the signal Step 1 says "the
next capture calibrates on". Nothing says where it goes instead. That session moved the entry into
`expects:` with a `# not predicted` comment; if that is right, Step 5.4 should say so.

**Step 1's inline note poisons the reader it installs.** `fm_list` in `next` and `claim` was made
comment-aware by 0031, but `develop` Step 1 invites the annotation on any frontmatter field and the
scalar readers are still comment-blind — so the note is emitted verbatim in `./next`'s CLAIMED FILES
block as though it were a path. The two instructions are individually right and jointly wrong.

**Step 5's review checklist runs after "confirm green" with nothing said about a finding that
changes behaviour.** On 0038 the checklist caught three things 134 green assertions could not; two
were pure refactors, and the third *changed the interface* — a second `--completed` is now a usage
error — and therefore needed its own red-first test, written after the green step had passed.

**Step 5's mutation rule is stated for the result but not for the mutation's own validity, and the
cheap mutation is the invalid one.** Deleting a `case` branch from a `sh` guard left a dangling
`echo` and a red on a syntax error — a red that looks like the guard biting.
`testing-conventions.md` names this; the skill cites the diff-the-mutation half and not the
read-the-red half, and the diff was non-empty in both the valid and the invalid attempt, so the
diff alone does not separate them.

**Step 5's red-triage has no advice for a figure that will not reconcile.** The published $15.11
baseline could not be reproduced from its own transcript — 78% of published, by every variant
tried. The falsified/exposed distinction does not apply, and what saved the ticket was the FR
having been written with an explicit "or say you could not" fallback.

**Step 4 has no answer for a re-entry whose verdict is "the code is right, only the evidence is
missing".** The cycle it cites is write the test → confirm red → implement → confirm green, and on
a QA bounce of this shape there is nothing to implement: the red can only come from deliberately
mutating correct production code, running, and reverting. That is `testing-conventions.md`'s *prove
a new guard fails*, but Step 4 does not point at it — so the honest paths are to skip the red,
leaving exactly the untrustworthy assertion the bounce existed to remove, or to invent the
technique.

**And Step 1 leaves the working directory somewhere else.** It tells a session to run
`./next develop`, and the natural way to reach the scripts is `cd .claude/backlog && ./next`, which
leaves the Bash tool's cwd inside `.claude/backlog/` for the rest of the session. Every later
repo-root path then fails with *no such file or directory* — including `.claude/backlog/claim`,
which reads as the script being absent rather than the cwd having moved. Two calls were lost to it
in one session.

**And a row can be claimed between `./next develop` printing it and you claiming it.**
`./next develop` offered `TAKE 0032`; by the time the item file had been read and its contract
restated, another session held it. Nothing broke — `./claim` re-reads under the lock, which is
*Re-read immediately before you write* doing its job — but it was noticed only because the harness
happened to send a "QUEUE.md changed on disk" reminder. Without that, Step 2 would have restated
the contract for a ticket the session did not hold. Step 1 reads as though the row `./next` prints
is still there when you get to it; the ordering it should state is **claim first, read the item
file second** — the claim is two seconds and the item file is the expensive read.

## Functional requirements

- FR1 — Step 5.4 says where the record that `expects:` under-predicted goes when `touches:` is
  cleared, so following Steps 1 and 5.4 together does not delete it.
- FR2 — Step 1's "say inline that it is new" instruction either names a field whose reader strips
  comments, or says where the note goes instead, so the annotation cannot reach `./next`'s output
  as a path.
- FR3 — Step 5 states that a review-checklist finding which changes documented behaviour re-enters
  the red-first cycle rather than shipping on the strength of the earlier green.
- FR4 — Step 5's mutation rule requires reading *why* the red happened, not only that the mutation
  landed, and cites `testing-conventions.md`'s statement that a malformed mutation reds for the
  wrong reason.
- FR5 — Step 5's red-triage names the case where a *figure* will not reconcile, and names the
  ticket-writing habit that rescued it: an FR that carries an explicit "or say you could not"
  fallback.
- FR6 — Step 4 names the re-entry case where the code is right and only the evidence is missing,
  and states the procedure: confirm red by the mutation the verdict names, diff the file against a
  copy to prove it landed, revert before committing.
- FR7 — Step 1 shows the `./next` invocation from the repo root, so following it does not move the
  working directory.
- FR10 — Step 5's mutation rule cites `testing-conventions.md`'s statement that on the TDD path
  `git diff` compares against HEAD — which never held the code just mutated — so an empty diff is
  indistinguishable from a mutation that failed to apply, on a run that was correctly red. The
  remedy it names is to copy the file aside and diff against the copy.
- FR9 — Step 1 states the ordering **claim first, read the item file second**, and names why: the
  claim is cheap and `./claim` re-reads under the lock, while restating a contract for a row you do
  not hold is the expensive mistake.
- FR8 — Every rule added cites the governing convention rather than restating it, and each citation
  resolves under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Cite `testing-conventions.md` for FR4 and FR6 rather than copying its text; a copy drifts and `verify` then checks the stale one | `documentation-conventions.md` |
| Progressive delivery | This skill ships to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given Step 5.4, when read, then it says where the under-prediction record goes.
- [ ] AC2 — Given Step 1, when read, then its inline-annotation instruction names a comment-safe
  location or an alternative.
- [ ] AC3 — Given Step 5, when read, then it states that a checklist finding changing behaviour
  goes back through red.
- [ ] AC4 — Given Step 5's mutation rule, when read, then it requires reading why the red happened.
- [ ] AC5 — Given Step 5's red-triage, when read, then it names the irreconcilable-figure case.
- [ ] AC6 — Given Step 4, when read, then it names the evidence-only re-entry and its
  mutate-diff-revert procedure.
- [ ] AC7 — Given Step 1, when read, then the `./next` invocation shown runs from the repo root.
- [ ] AC11 — Given Step 5's mutation rule, when read, then it names the copy-aside diff for code
  that is not yet committed, and cites the convention rather than restating it.
- [ ] AC10 — Given Step 1, when read, then it states that the row is claimed before the item file
  is read, and why that order.
- [ ] AC8 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.
- [ ] AC9 — Given `tests/skill-size.test.sh`, when it runs, then `skills/develop/SKILL.md` is
  within its goal or carries a recorded justification naming this ticket.

## QA plan

- **Level:** verify — the deliverable is prose in one skill file and no test runner applies; the
  scripted assertions are the scoped greps below plus the citation and size guards.
- **Why this level:** nothing executable changes.
- **Specific checks:** each grep **scoped to the step it asserts on**, matching a phrase short
  enough to sit on one source line. Then `tests/citations.test.sh`, `tests/skill-size.test.sh`,
  `tests/batching.test.sh` — which asserts on this file's batching paragraph and must stay green —
  and the full suite.

## Out of scope

- **Anything about a red the session did not cause.** That is 0054, which holds Step 5's
  attribution rules; this ticket holds the six gaps that are not about concurrency.
- Making `./next` and `./claim` behave differently in the race FR9 describes. The scripts are
  already correct — `./claim` refuses an `in-progress` row under the lock — and FR9 changes only
  the order the skill tells a session to work in.
- Making the scalar frontmatter readers comment-aware. That is 0044. FR2 is the skill's half and is
  worth landing either way, since the instruction is wrong even once the readers are fixed.
- Relocating any of this file's content to hold its byte goal. AC9 accepts a recorded justification.

## Notes & decisions

- Routed to `develop`: every fix is named in the finding it came from, and the two that touch
  testing technique are `testing-conventions.md`'s existing rules, cited rather than decided.
- Bundled at the level of "one skill file's steps have no case for what now happens routinely"
  rather than six tickets. Six tickets on one prose file is the stage-wide stall 0050 describes,
  reproduced deliberately.
- **Amended twice on 2026-08-25**, both during the sweep that captured this ticket. The second
  added FR10/AC11 — the copy-aside diff. Re-checked: `size` stays `l`, the QA plan is unchanged
  because AC11 is another scoped grep on the same Step 5 mutation rule as AC4, and *Out of scope* is
  unchanged. It landed here rather than as its own ticket because it is one clause in the exact
  paragraph FR4 already rewrites, and a separate ticket would have been a second session in this
  file for one sentence.
- **Amended 2026-08-25**, during the same sweep that captured it, to add FR9/AC10 — the
  claim-before-read ordering. Re-checked per the amend rules: `size` stays `l` (one more prose
  clause on a file already being edited for seven), the QA plan's named checks are unchanged
  because AC10 is another scoped grep on the same step as AC7, and *Out of scope* gained the line
  above so nobody reads FR9 as a request to change the scripts. The alternative was leaving the
  finding parked, which would have put a future ticket in this file alongside this one — the
  collision 0050 exists to settle.
- `skills/develop/SKILL.md` carries a recorded size justification already (0035). AC9 is written to
  accept an updated one rather than to force a relocation, because relocation is the operation the
  size gate itself says rarely pays.
