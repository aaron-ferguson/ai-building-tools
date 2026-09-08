---
id: "0113"
title: Give retro's release chain and its one-line report a form for a pass that edited several repos
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-07
source: retro
parent:
blocked_by: []
relates: ["0075", "0114"]
expects:
  - skills/retro/SKILL.md
  - tests/retro-tool-edit.test.sh
  - tests/reporting.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` Step 5 handles several repos in its commit bullet and one repo in its release bullet, and
the report it prescribes can only describe the second.** The commit half is already right:

> A retro often edits several repos at once — the project, the conventions, the tools — so commit
> each in its own repo with its own message

The release half immediately below it is not:

> **A skill edit has a release chain — run `tools/release` from the repo root.** … **Report it in
> one line, not a paragraph** … `Skills changed — ran tools/release, restart required.` is the whole
> message.

`tools/release` exists in `ai-building-tools` and **nowhere else** — not in
`ai-building-conventions`, not in a consuming project. So *"from the repo root"* names a repo the
step never identifies, and the prescribed literal has no form for the pass that actually happened.

**Measured 2026-09-07.** One retro pass edited three repos: `ai-building-tools` (skills, references,
tests, backlog), `ai-building-conventions` (`testing-conventions.md` and its root `FINDINGS.md`) and
`neumo_repos/Probation` (buffer only). One has a release chain, one needs a push and no release, one
needs neither. The prescribed one-liner covers none of that, so the pass **reported in full
instead** — which is the paragraph the one-line rule exists to stop.

**The cost is not tidiness.** Step 5 itself says an unpushed edit in the conventions or tools repo
*"is lost at the next install"*, and Step 7 requires the report to name *anything left uncommitted,
unpushed, or unreleased*. A report form shaped for one repo gives the user no place to see that the
second repo was pushed and the third was not — so the two instructions pull against each other, and
the session resolves it by abandoning the one-line rule.

## Functional requirements

- FR1 — Step 5's release bullet states which repo the chain applies to and how a session tells:
  `tools/release` exists in the tools repo and nowhere else, so the chain runs where the script is
  and the other repos take Step 5's push rule instead.
- FR2 — The prescribed report form covers a pass touching more than one repo — which were committed,
  which pushed, which released, which needed nothing — while staying one line.
- FR3 — Step 5's one-line rule and Step 7's *uncommitted, unpushed, or unreleased* bullet are
  reconciled explicitly, so a multi-repo pass is not choosing between two instructions that cannot
  both be followed. Name which governs when they meet.
- FR4 — The form is guarded, because nothing guards it today: `tests/` asserts that `CLAUDE.md`
  names `tools/release` (`release.test.sh:264`) and asserts nothing about retro's report line at
  all. A prescribed literal with no guard is what allowed this one to go stale unnoticed.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reconciliation in FR3 is stated in one of the two steps and cited from the other; stating it twice is how they drifted apart in the first place. | `documentation-conventions.md` |
| Git | The form must not imply that a push in another repo is granted by having run the chain in this one. Each repo's push is its own decision under that repo's rules — this is the confirm-a-release rule and it is per-repo. | `git-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 5's release bullet, when read, then it states which
  repo runs the chain and how a session tells. Red when that clause is deleted — the bullet still
  reads as complete instruction with *"from the repo root"* alone, which is exactly the state it is
  in now, so the assertion must not be satisfiable by the current text.
- [ ] AC2 — Given Step 5's report rule, when read, then the form it prescribes has a slot for more
  than one repo. Red when it is reverted to the fixed single-repo literal
  `Skills changed — ran tools/release, restart required.`
- [ ] AC3 — Given Step 5 and Step 7, when read together, then one of them names which governs a
  multi-repo pass. Red when that sentence is deleted from whichever step carries it.
- [ ] AC4 — Given the new guard from FR4, when the report form is deleted from Step 5 entirely, then
  the guard reds. Anchored to Step 5's window rather than the file, per
  `tests/retro-tool-edit.test.sh`'s header rule — `report` is an ordinary word elsewhere in that
  skill and a file-wide grep would stay green on a rule moved out of the step that must obey it.

## QA plan

- **Why that level:** prose in one skill file plus a new guard; this repo's only runner is
  `tests/*.test.sh` and `unit` runs all of them.
- **Specific checks:** add the cases to `tests/retro-tool-edit.test.sh`, which is already scoped by
  retro step and whose header states the anchoring discipline AC4 rests on. `tests/reporting.test.sh`
  is the alternative home if the assertion is better grouped with the other report-form guards —
  pick one and say which in *Notes & decisions*, do not assert in both. Prove each case fails by
  deleting the clause it matches and reverting.
- Match a phrase short enough to sit on one source line.

## Out of scope

- **The chain being uncompletable by an agent at all.** That is 0114 — the `/dev/tty` confirmation —
  and it is a different failure in the same bullet: this ticket is about a pass that *can* run the
  chain and cannot describe the result, 0114 about one that cannot run it.
- **Adding a release chain to `ai-building-conventions`.** FR1 records that it has none; whether it
  should is a separate question and nothing here depends on the answer.
- Changing `tools/release` itself.

## Notes & decisions

- **Routed to `develop`.** No decision is open. Step 7 already enumerates the three dispositions —
  uncommitted, unpushed, unreleased — so the report form is a wording job against an existing
  vocabulary, not a choice about what to report.
- **FR4 corrects the finding.** The parked entry implied an existing guard on the literal would need
  updating. Checked: `grep -rn 'tools/release\|restart required' tests/*.test.sh` returns only
  `release.test.sh`'s assertions about the script's presence and about `CLAUDE.md` naming it.
  **Nothing guards retro's report line.** So this is a new guard, not an edit to one.
- Captured from `FINDINGS.md` 2026-09-07.
