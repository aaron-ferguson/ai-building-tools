---
id: "0061"
title: Decide how a session learns the installed plugin differs from this repo
type: chore
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0027", "0035"]
expects:
  - SOURCE
  - CLAUDE.md
  - .claude-plugin/plugin.json
  - skills/retro/SKILL.md
  - skills/verify/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Sessions in this repo work a backlog **using** the skills stored in it, resolved once at session
start from `~/.claude/plugins/cache/`. The installed copy and the source tree can differ, they have
differed repeatedly, and nothing fails when they do.

**They can differ at the same version number.** `0.9.2`'s installed `prototype/SKILL.md` was 26,262
bytes against a source of 23,394 — the pre-0021 copy, so that trim was committed and never released.
The installed `references/` was also missing a file the source had. A session therefore resolves
skills from a copy it cannot date.

**They can differ by whole tickets.** While 0027 was closing, the installed plugin was two merged
tickets behind the repo, so the sessions running these skills were executing prose the repo no
longer contained. A session has reported a rule missing that had shipped the same day.

**And the install record can name a commit whose bytes are not on disk.** Measured 2026-09-01:
`claude plugin update` wrote `"gitCommitSha": "219f507…"` into `installed_plugins.json` while the
version-keyed cache directory it named kept its earlier mtime and its `49371a4` content — eight
differing files under `skills/` and `references/REPORTING.md` absent. On the same evening
`/reload-plugins` built a `0.9.7` cache directory without rewriting that record, so `/plugin list`
went on printing `0.9.6`. **Both fields a session might read as identity were wrong, in opposite
directions, hours apart.** That rules out any answer of the shape "trust the recorded version or
sha" and constrains the rest: whatever mechanism this settles on has to be grounded in content, not
in what the harness recorded about it. 0084 acts on the same measurement from the releasing side.

**One level down, the same failure already has a guard.** 0027 added
`tests/backlog-scripts-installed.test.sh`, so a drifted `.claude/backlog/` copy fails a suite run.
The identity one level up — repo ↔ installed plugin — has nothing. `SOURCE` explains why the cache
is disposable but gates nothing, and `retro`'s trap ("you may be running an older copy") has no
check behind it: comparing the two needs the source checkout, which most sessions do not have.

This project's own `CLAUDE.md` already records the consequence and the workaround — diff the trees
before concluding a rule is absent — which means the cost is currently paid by every session, as
vigilance, forever.

## Open design question

- **Question:** What tells a session that the copy it is running differs from the repo, and when?
  The shapes: a **version marker the installed side can read alone** — a build stamp or content
  hash the skill itself carries, so a session can compare without a checkout; a **guard in this
  repo's suite** that fails when the installed tree and the source differ, which catches it at
  develop time but only on a machine that has both; a **release check** attached to the version
  bump, so the bump cannot be recorded without the install being updated; or **accept it** and make
  the `CLAUDE.md` workaround a step in the skills that most often need it. They differ in *who* is
  protected — the session running a stale copy, versus the developer about to ship one.
- **Why it blocks specification:** the acceptance criteria are incompatible, and so is the blast
  radius. A content hash is a change to what every skill file carries and to how the plugin is
  built. A suite guard is one test file and protects only this machine. A release check is a
  change to the documented release chain. And a fifth possibility is that the honest answer is that
  a cache a session cannot date is a property of the harness rather than something this repo can
  fix, in which case the deliverable is a documented detection step and nothing else.
- **Settle it with:** `/design` — the inputs are the install layout, `SOURCE`, the release chain in
  `CLAUDE.md` and what a session can actually read at start. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — A session can determine whether the skills it resolved match this repo, by a stated method,
  without being told to remember to check.
- FR2 — Whatever FR1 lands, the code or check that implements it is named — a test file, a build
  step, or a documented command — not only the rule.
- FR3 — `CLAUDE.md`'s existing workaround points at the settled mechanism rather than standing as
  the only defence.
- FR4 — `skills/retro/SKILL.md`'s "you may be running an older copy" trap points at a check that
  exists.
- FR5 — Whatever FR1 lands is grounded in content rather than in a recorded version or sha, both of
  which were observed lying on 2026-09-01. A mechanism that reads `installed_plugins.json` and
  believes it does not satisfy this.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Progressive delivery | The release chain here is push → bump `.claude-plugin/plugin.json` → update the install → restart, and every step is silent when skipped; any mechanism must survive a session that skipped one | `progressive-delivery-conventions.md` |
| Documentation | The detection method is documented where a session that suspects drift will look, which today is `CLAUDE.md` | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given a session that has resolved these skills, when it follows the stated method, then
  it can say whether the copy it is running matches this repo.
- [ ] AC2 — Given `CLAUDE.md`, when read, then its drift paragraph points at that method.
- [ ] AC3 — Given `skills/retro/SKILL.md`'s older-copy trap, when read, then it points at a check
  that exists.

## QA plan

- **Level:** unit — provisional, argued across the candidate shapes: a suite guard or a build stamp
  is `unit`, a documented-method answer is `verify` with a named scripted assertion, and this
  project's `unit` command runs every `tests/*.test.sh`, so `unit` subsumes both.
- **Why this level:** the level is the same across every candidate.
- **Specific checks:** settled by the design pass. If the answer is a guard, it must be proved to
  red against a deliberately drifted copy, and the mutation must be confirmed to have reached the
  copy under test rather than the one being read.

## Out of scope

- **The templates ↔ `.claude/backlog/` identity**, which already has a guard (0027) and whose
  `expects:` half is 0057's FR7.
- Changing the release chain itself, unless the answer requires it.
- Anything about how the harness caches plugins, which this repo does not control — though
  establishing that boundary is part of the design pass.

## Notes & decisions

- Routed to `design` on trigger 1: four candidate mechanisms with incompatible criteria, and the
  question of *who* is protected — the stale session or the developer about to ship — is the part
  that has to be settled before an AC can be written.
- Ranked in Tier 2 rather than Tier 5 because the cost is being paid continuously as vigilance:
  `CLAUDE.md` instructs every session to diff the trees before concluding a rule is absent, which
  is a tax on every session that suspects anything.
- **Amended 2026-09-01** with the measurement above. Two of the four candidate shapes are affected:
  the **release check attached to the bump** cannot be "the record was updated", since that is
  exactly what happened while the bytes did not change — 0084 takes that shape and grounds it in a
  diff; and **accept it** got more expensive, because the workaround `CLAUDE.md` prescribes is a
  `diff -rq` needing a checkout, which the sessions most at risk do not have. The question left is
  narrower than when it was written: what can a session with **no source tree** read that is
  evidence about its own bytes? A `size: m` still looks right, and the tier argument is unchanged
  in kind but now has a measured instance behind it rather than only vigilance.
