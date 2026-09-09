---
id: "0075"
title: Anchor a tool edit to the remote, at its start and at its bump
type: bug
next:
status: done
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
  - tests/remote-anchor.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-09
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

- [x] AC1 — `skills/retro/SKILL.md` instructs a fetch of every repo it will edit before Step 3's destination
  checks, and says a stale destination check is not evidence.
- [x] AC2 — The release chain in `retro` Step 5 names the fetch as its first step.
- [x] AC3 — The version-bump instruction says the next version is derived from the remote's current version,
  and names the collision that occurred.
- [x] AC4 — Mutating the fetch sentence out of `skills/retro/SKILL.md` turns the new guard red.

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

- 2026-09-09 (develop, `0968`) — **`expects:` named `tests/skill-prose.test.sh`, which does not
  exist and never has.** The guards went into a new self-contained `tests/remote-anchor.test.sh`,
  which is this repo's idiom — every test file defines its own `window()` helper rather than
  sourcing a shared one. `expects:` is corrected above.

- 2026-09-09 (develop, `0968`) — **FR3 and FR4 were already satisfied in the machinery and unsaid
  in the prose, which is the whole of what was left to build.** `tools/release` was written by
  `0084` and cites this ticket by number: its step 1/9 is `git fetch`, and step 3 derives the next
  version from the *remote's* `plugin.json` precisely because "a hand-picked version collided
  (0075)". `tests/release.test.sh` already guards both. So FR4's literal chain —
  *fetch → edit → test → commit → push → bump → install → restart* — is **stale in shape**: since
  `0114`, retro Step 5 names one invocation, `tools/release --bump --yes`, and there are no
  separate steps to reorder. What the deliverable actually is: Step 5 now *states* that the chain
  begins with the fetch and where the version comes from, because a session reads the prose and
  not the script. ACs 2 and 3 are met as written; the FR's arrow-list is not reproduced.

- 2026-09-09 (develop, `0968`) — **FR1 reaches `develop`, not only `retro`, and the ACs do not say
  so.** `expects:` named `skills/develop/SKILL.md`, and a `develop` session on *this* backlog edits
  the skills in it every ticket; Step 2's staleness greps and Step 3's guard greps are damaged by a
  stale tree in exactly the way retro Step 3's destination greps are. The rule went into Step 1,
  before `./claim`, since the claim itself commits. That case is asserted in the guard as FR1
  rather than as an AC.

- 2026-09-09 (develop, `0968`) — **the 2026-09-09 note above was verified, not taken on trust.**
  `~/.claude/plugins/marketplaces/ai-building-tools` is a real repository with the right `origin`,
  and `git status -sb` there reported `## main...origin/main [ahead 278]` against the real
  checkout's `ahead 19`. The answer to "which checkout" is cited rather than restated: the repos
  are the ones `references/CONVENTIONS.md` already resolves — the conventions ladder and
  `tools.path` — and never the plugin install.

- 2026-09-09 (develop, `0968`) — **the capitalisation of a guarded phrase is part of the guard.**
  Two cases went red after the prose was written because `**Behind the remote stops the pass**`
  opens a sentence while the assertion was lowercase, and a third because a bold span wrapped
  across a source line. Both are the line-based-`grep` hazard `CLAUDE.md` names, in a form that
  survives a careful read of the paragraph.

## QA evidence

Verified 2026-09-09, token `f5d0`, at `qa_level: unit` — frontmatter and the QA plan's
`**Level:** unit` agree, so no level drift to report. Commit under test `dfd93a8`.
**The subject is the repo copy, not the install**: no cached version carries this prose
(`grep -c 'every repo it will edit'` is 0 in all nine, including the `0.9.22` this session's own
skills resolved from), so the change is committed and unreleased and the checkout is the authority.
Suite: 26 files, 0 failed, run individually per `config.yml`'s note that `unit` is fail-fast;
`tests/remote-anchor.test.sh` reports `20 passed, 0 failed`.

| Row | How it was checked | Result |
|---|---|---|
| AC1 — retro instructs a fetch of every repo before Step 3's destination checks, and says a stale check is not evidence | Read `skills/retro/SKILL.md` Step 3 (window `## Step 3` → `## Step 4`); `tests/remote-anchor.test.sh` five AC1 cases. **Mutated**: deleting `every repo it will edit` → `19 passed, 1 failed`; deleting `Behind the remote stops the pass` → `18 passed, 2 failed`. **Altitude mutation**: relocating the whole paragraph into Step 2, unchanged, → `15 passed, 5 failed`, so the rule's *step* is what is asserted, not its presence in the file | PASS |
| AC2 — the Step 5 release chain names the fetch as its first step | `skills/retro/SKILL.md` Step 5, *"That chain begins with a fetch, and the version comes from it."* **Mutated**: deleting `chain begins with a fetch` → `19 passed, 1 failed`. The guard's own `AC4 — Step 5's chain rule is not readable from Step 3's window` case proves the two windows are distinguishing | PASS |
| AC3 — the bump derives from the remote's current version, and names the collision | `skills/retro/SKILL.md` Step 5 names the **remote's `plugin.json`**, **never the local file**, and *"collided with a version already released"* (2026-09-01). **The prose's claim about the script was checked against the script**: `tools/release` step 1/9 is `git fetch`, step 2/9 dies on behind, step 3/9 derives from `$UPSTREAM:.claude-plugin/plugin.json` and reports both the observed and derived versions. **Mutated**: deleting the remote-`plugin.json` phrase → `19 passed, 1 failed` | PASS |
| AC4 — mutating the fetch sentence out of `skills/retro/SKILL.md` turns the new guard red | The five mutations above were run against the real files, not the guard's own fixtures, each confirmed to have removed exactly one line (`git diff --numstat` = `0 1`) and each restored by pathspec with a green control run after | PASS |
| FR1 (asserted as FR1, not an AC) — develop anchors to the remote before it claims | `skills/develop/SKILL.md` Step 1, immediately above **Claim it with `./claim`**. **Mutated**: deleting `Fetch before you claim` → `19 passed, 1 failed` | PASS |
| NFR Documentation — the rule states the failure it prevents, not the reasoning | Both paragraphs name the 2026-09-01 pass: 47 commits behind, a commit rewritten four days after someone else pushed it, a rebase conflict, and a released version collided with. `tests/skill-size.test.sh` and `tests/reference-size.test.sh` green | PASS |
| NFR Git — the fetch is read-only; no automatic pull, merge or rebase is added | Every added line mentioning pull/merge/rebase is narrative about the incident or hands the choice to the user (*"the pull is the user's call"*); the only commands added are `git fetch` and `git status -sb`, both read-only. **True as delivered, but unguarded** — see the finding below | PASS (unguarded) |

**Published gap, not papered over** (`verify` Step 3, *a mutation that does not redden is a result
to publish*): replacing the read-only command with `git pull --rebase` in **either** skill leaves
all 26 test files at 0 failed. No assertion was invented to close it; it is parked in
`FINDINGS.md` (2026-09-09) and belongs with `0107`.

**Advisory label:** not advisory. The dirty set captured before the first suite run was empty, and
a fresh capture after the last evidence command was empty, so the intersection with the evidence
set — `skills/retro/SKILL.md`, `skills/develop/SKILL.md`, `tests/remote-anchor.test.sh`,
`tools/release`, `references/CONVENTIONS.md`, `.claude/backlog/config.yml`, `tests/*.test.sh` — is
empty.
