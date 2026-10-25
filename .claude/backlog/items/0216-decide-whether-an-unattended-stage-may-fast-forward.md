---
id: "0216"
title: Decide whether an unattended stage may fast-forward a clean checkout that is only behind
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-25
source: agent
parent:
blocked_by: []
relates: ["0177", "0113"]
expects:
  - skills/retro/SKILL.md
  - skills/sprint/SKILL.md
  - skills/develop/SKILL.md
  - tests/remote-anchor.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**An unattended sprint tail lost a whole pass over the tools buffer because the tools checkout was one
commit behind `origin/main` — and the only commit it lacked was another session's backlog capture.**

Parked in AetherWorks `FINDINGS.md` on 2026-10-24, during run-20261024T195310Z, verbatim:

> An end-of-sprint retro told to sweep the tools buffer could not write to the tools repo: its
> checkout was 1 commit behind `origin/main`, because another session pushed a capture (0214, moving
> `next_id`) during the run. `retro` Step 3 stops on behind and leaves the pull to the user, so the
> 16-entry tools buffer was triaged and nothing was written. That costs a second pass on the same
> entries. The skill's cluster-and-defer guidance assumes it can at least mark entries `[->none]`,
> and here it could not. Either the sprint tail fetches and fast-forwards a clean, behind-only tools
> checkout before dispatching retro, or retro may fast-forward when the tree is clean and the remote
> commits touch only `.claude/backlog/`.

The second pass did happen (`ec5458e`, `cabe7cf`), so the cost was real and paid: the same 16
entries were read twice.

Where the stop comes from. `skills/retro/SKILL.md` Step 3: *"Behind the remote stops the pass, and
the pull is the user's call because that choice is theirs (`git-conventions.md`)."*
`skills/develop/SKILL.md` has the same stop at *"Fetch before you claim, and stop if you are behind"*.
**`git-conventions.md` contains no rule about pulling** — checked 2026-10-25, its only match for
`pull` is the collaborative-mode pull-request line — so "the user's call" is the skills' own rule,
and this ticket may change it without amending a convention.

**Why `0177` does not cover this.** `0177` answers what an unattended pass does when it *cannot*
pull: continue over the current repos, leave the stale repo's findings undispositioned, report. That
answer is exactly what produced this second pass. `0177`'s *Out of scope* names this question
explicitly — *"Letting any session pull on the user's behalf"* — so it is a separate decision, now
with a measured cost. `0177` stays needed either way: a diverged or dirty checkout still has nothing
safe to fast-forward.

## Functional requirements

Provisional — the decision below fixes their wording, and `design` replaces this list.

- FR1 — The rule says whether an unattended session may fast-forward a resolved repo, and if so
  names the full precondition set (at least: clean working tree, strictly behind and not diverged,
  `--ff-only`), and who performs it (the `sprint` supervisor before dispatching a stage, or the
  stage itself).
- FR2 — The rule is written once and cited from every stage that fetches and stops on behind
  (`retro` Step 3, `develop`'s fetch-before-claim, and the `sprint` tail if it is the performer),
  never restated beside each.
- FR3 — A fast-forward that happens is reported: the repo, the SHA before and after, and the paths
  the incoming commits touched.
- FR4 — The attended behaviour is unchanged unless the decision says otherwise in so many words.
- FR5 — `tests/remote-anchor.test.sh` guards the rule's clauses in each stage's window, and its
  existing `Behind the remote stops the pass` check still passes or is replaced by name.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | One definition, cited from each stage; the stages cannot disagree about when a fast-forward is allowed | prose only — no artifact yet; `design` names the guard in `tests/remote-anchor.test.sh` | `documentation-conventions.md` |
| Observability | A fast-forward performed on the user's behalf is never silent — repo, from/to SHA and touched paths reach the stage report | prose only — no artifact yet; the guard asserting the report clause is FR5's | `observability-conventions.md` |

## Open design question

- **Question:** May an unattended session fast-forward a clean, behind-only checkout before writing
  to it — and if yes, (a) is the precondition "any incoming commits" or "incoming commits touch only
  `.claude/backlog/`", and (b) does the `sprint` supervisor do it before dispatching, or the stage
  itself?
- **Why it blocks specification:** every AC is a phrase `tests/remote-anchor.test.sh` asserts in a
  named stage's window, and neither the phrase, the window nor the precondition exists until this is
  answered. Writing them now would pick one of the finding's two proposals by default.
- **Settle it with:** `/ai-building-tools:design` (a decision, no surface).
- **Considerations already on the table:** the stop exists because a pull can be a merge decision
  (the 2026-09-01 pass that was 47 commits behind); a `--ff-only` over a clean tree makes no choice,
  but it does change files under any *other* session working in the same checkout, which a clean
  tree only rules out at that instant. The backlog-only precondition is narrower and covers the
  observed case exactly (a capture moving `next_id`); "any commits" also covers a skill edit
  landing mid-run. A supervisor-side fast-forward runs once per repo per tail; a stage-side one
  runs in every stage, including `develop`, which has the same stop.

## Acceptance criteria

Written by `design` once the question above is answered.

## QA plan

- **Why that level:** the result is a prose rule in shipped skills, guarded by this repo's shell
  suite (`unit` in `config.yml`), the only runner the project has.
- **Specific checks:** `tests/remote-anchor.test.sh`, `tests/citations.test.sh`,
  `tests/skill-size.test.sh`.

## Out of scope

- What a pass does when it cannot fast-forward (diverged, dirty, or the decision says no) — that is
  `0177`.
- `tools/release`'s behind-the-remote refusal (`0075`, `0084`), which guards a push, not a pull.
- Pulling the plugin install or the marketplace clone, which are never edited
  (`references/CONVENTIONS.md`, *Routing a finding to the repo it is about*).

## Notes & decisions

- **2026-10-25 (queue sweep, run-20261024T195310Z tail)** — Filed from the one AetherWorks
  `FINDINGS.md` entry left after that run's retro. Routed to `design`, not `develop`: the entry
  itself offers two incompatible fixes, and choosing which session may change the user's checkout
  is a decision, not a fact readable from the code. Ranked directly above `0177` because the answer
  decides how much of the paragraph `0177` edits survives — settling it first avoids rewriting
  retro Step 3 twice. Not made a blocker of `0177`: `0177`'s FRs hold whatever this decides.
