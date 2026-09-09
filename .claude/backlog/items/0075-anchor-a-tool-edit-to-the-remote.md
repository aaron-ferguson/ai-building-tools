---
id: "0075"
title: Anchor a tool edit to the remote, at its start and at its bump
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0076", "0078"]
expects:
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - tests/skill-prose.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A session edited this repo 47 commits behind `origin/main` and did not know it**, during the
AetherWorks retro of 2026-09-01. Two costs, both measured rather than feared:

1. **The same work was done twice, four days apart.** Local `13a4e81` (2026-08-29, *"Trim the
   QUEUE.md header to a legend"*) and upstream `ec650cd` (2026-08-25, *"Condense the QUEUE.md header
   to rules and pointers"*) are the same job. Neither session could see the other. It surfaced only
   as a rebase conflict when the retro finally tried to push, and resolving it meant deciding which
   of two of Aaron's own commits to keep.
2. **A hand-picked version collided.** The retro bumped `.claude-plugin/plugin.json` to `0.9.6`
   while upstream had already released a `0.9.6` (`c1af6db`). The bump was chosen by reading the
   local file and adding one.

Every destination check that retro made — the greps that decide whether a rule already exists — ran
against stale files and had to be re-run after the pull. **`retro` Step 5 already names a release
chain (push → bump → install → restart), and every step of it is after the edits.** Nothing anywhere
tells a session to look at the remote *before* it starts.

This is the same failure `retro` Step 3 already warns about one layer in — *"you may be running an
older copy of a skill than the source"* — applied to the source itself. That warning compares the
install against the checkout; nothing compares the checkout against the remote.

## Functional requirements

1. **A session that will edit this repo or `ai-building-conventions` fetches first.** `git fetch`
   and a divergence report, before the first edit, not before the push.
2. **Being behind stops the session rather than warning it.** Report the repo, how many commits
   behind, and pull before editing. A destination check against a stale tree is worse than no check,
   because it reads as evidence.
3. **The version bump derives the next version from the remote's current version**, never from the
   local file alone. State the observed remote version and the derived one.
4. **`retro` Step 5's release chain gains the fetch as its first step**, so the chain reads
   fetch → edit → test → commit → push → bump → install → restart.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule states the failure it prevents — a duplicated commit and a colliding version — not the reasoning that produced it. | `documentation-conventions.md` |
| Git | The fetch is read-only. This item adds no automatic pull, merge or rebase: resolving divergence can mean choosing between two of the author's own commits, which is a person's call. | `git-conventions.md` |

## Acceptance criteria

- [ ] AC1 — `skills/retro/SKILL.md` instructs a fetch of every repo it will edit before Step 3's destination
  checks, and says a stale destination check is not evidence.
- [ ] AC2 — The release chain in `retro` Step 5 names the fetch as its first step.
- [ ] AC3 — The version-bump instruction says the next version is derived from the remote's current version,
  and names the collision that occurred.
- [ ] AC4 — Mutating the fetch sentence out of `skills/retro/SKILL.md` turns the new guard red.

## QA plan

- **Level:** unit — `tests/*.test.sh`, this repo's whole suite.
- **Why this level:** the deliverable is prose in a skill, and every guard here greps prose.
- **Specific checks:** extend `tests/skill-prose.test.sh` (or add a case where the retro guards
  live). Assert each on its own line, since `grep` is line-based and a reflow would red it: the word
  `fetch` in retro's destination-check step; `remote` in the same section as the version bump. Prove
  each can fail by deleting the sentence it matches.

## Out of scope

- Automating the pull, merge or rebase. See NFR *Git*.
- A pre-commit hook. The rule has to fire before the edits, and a hook fires after them.

## Notes & decisions

- Captured by the AetherWorks retro of 2026-09-01, which hit all of this in one pass.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-09) — **this row must say which checkout it means,
  because the plugin machinery offers one that reads as correct and is not.** The install directory
  (`~/.claude/plugins/cache/ai-building-tools/ai-building-tools/<version>/`) is **not a git
  repository at all**, so it fails a checkout test loudly and safely. The marketplace clone beside
  it (`~/.claude/plugins/marketplaces/ai-building-tools/`) **is** one — correct `origin`, `HEAD`
  identical to the real checkout's, and a complete `.claude/backlog/` with `FINDINGS.md`, the items
  and the scripts — so every cheap test for "is this the repo?" passes on a managed copy the plugin
  system refreshes. Directly against FR1: that clone reports `## main...origin/main [ahead 213]`
  while being exactly level, because its `origin/main` ref is stale. A session standing there and
  running this ticket's fetch-and-report-divergence check gets a confidently wrong answer **in the
  direction that reads as safe**.
