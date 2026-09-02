---
id: "0084"
title: Script the release chain and verify it against the installed bytes
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-09-01
source: user
parent:
blocked_by: []
relates: ["0075", "0061", "0064"]
expects:
  - tools/release
  - tests/release.test.sh
  - CLAUDE.md
  - skills/retro/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`claude plugin update` reports success, records a new commit sha, and extracts nothing.**
Measured in this repo on 2026-09-01, end to end, with both halves of the record observed wrong.

The marketplace clone sat at `49371a4` while `origin/main` was at `219f507`. After fast-forwarding
the clone and running the documented chain:

```
$ claude plugin update ai-building-tools@ai-building-tools
✔ Plugin "ai-building-tools" updated from 0.9.6 to 0.9.7 for scope user. Restart to apply changes.
```

`~/.claude/plugins/installed_plugins.json` then read
`"gitCommitSha": "219f5070739e30ce17ab6edb5ad4386742aa590e"`. The bytes it named were not there.
`~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.7/` kept its earlier mtime of
`22:14:47` and its `49371a4` content: eight differing files under `skills/`, and
`references/REPORTING.md` absent altogether.

**The cause is that the cache directory is keyed by version, and the version had not moved.**
`.claude-plugin/plugin.json` read `0.9.7` at both `49371a4` and `219f507`, because the bump landed
at `e5ad319` and every commit after it — the reporting contract, the falsifiable-AC guard,
`REPORTING.md` and eight edited skill and template files — rode on top of that bump with no version
of its own. The directory already existed, so nothing re-extracted, and the record was updated
regardless.

**Nothing reports this, and the session that then runs the stale copy cannot see it.** This session
resolved the `queue` skill from that exact directory; the skill's own base-directory line read
`.../0.9.7/skills/queue`.

**The record was wrong in the other direction on the same evening, too.** `/reload-plugins`
materialised a `0.9.7` cache directory from the clone and took an in-use marker on it at `22:14:47`
without rewriting `installed_plugins.json`, so `/plugin list` kept printing `0.9.6` — the version a
person reads to decide whether to act. So neither the recorded sha nor the reported version is
evidence about the bytes, and they fail independently.

`CLAUDE.md` already says every step of this chain is silent when skipped. What it does not say is
that a step can be *performed*, report success, and still not have happened.

## Functional requirements

1. **`tools/release` runs the whole chain in one invocation**: fetch, refuse if behind, derive the
   next version from the remote's current `plugin.json`, run `tests/*.test.sh`, commit, push,
   `claude plugin marketplace update`, `claude plugin update`, verify, and print the outcome.
2. **The verification compares bytes, not the record.** After the update it diffs the resolved
   install directory against the checkout at the pushed commit and exits non-zero naming every path
   that differs or is missing. A `gitCommitSha` equal to `HEAD` is never accepted as evidence on its
   own — that is the field that lied.
3. **The recorded sha is checked as well, as a second and independent assertion.** Bytes stale under
   a fresh sha, and fresh bytes under a stale record, were both observed on the same evening; one
   check cannot catch both.
4. **The run refuses before pushing when the release cannot take effect** — when the version in
   `plugin.json` is not greater than the installed version, so the version-keyed cache directory
   already exists and will not be re-extracted. Name that as the reason.
5. **The install directory is resolved from `installed_plugins.json`, never constructed from the
   version string**, so what is verified is the directory the harness will actually load.
6. **The verification is invocable on its own**, against an explicit install path and checkout, so
   the suite can drive it without pushing anything or shelling out to `claude plugin`.
7. **`CLAUDE.md`'s release-chain paragraph names the script** and states that `claude plugin
   update`'s success line is not evidence the bytes changed.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | The script pushes to `main` of a repo other machines install from, so the push is a release and is confirmed explicitly at the point it happens — never implied by having run the script. When the fetch shows the checkout behind, it reports and stops; it resolves no divergence itself. | `git-conventions.md` |
| Progressive delivery | The chain's steps are individually silent when skipped, so the script is safe to re-run and each step states whether it acted or was already satisfied. | `progressive-delivery-conventions.md` |
| Documentation | The mechanism is recorded where a session that suspects drift looks, which today is `CLAUDE.md`. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an install directory made to differ from the checkout in exactly one file, when
  the verification runs against it, then it exits non-zero and prints that file's path. Restoring
  that one file is what turns it green.
- [ ] AC2 — Given an install directory whose bytes match the checkout but whose recorded
  `gitCommitSha` is any other commit, when the verification runs, then it exits non-zero naming the
  sha mismatch. Byte equality alone must not pass it.
- [ ] AC3 — Given `.claude-plugin/plugin.json` at a version equal to the installed version, when
  `tools/release` starts, then it exits before any push and states that the cache directory for
  that version already exists and will not be re-extracted.
- [ ] AC4 — Given a run where every check passes, when it finishes, then it prints the released
  version, the pushed commit sha, and that a restart is required.
- [ ] AC5 — Given `CLAUDE.md`, when read, then its release-chain paragraph names `tools/release` and
  says `claude plugin update` reporting success is not evidence the bytes changed.
- [ ] AC6 — Given `tests/release.test.sh`, when the verification's comparison is mutated to return
  success unconditionally, then the suite goes red.

## QA plan

- **Level:** unit — `tests/*.test.sh`, this repo's whole suite, per `config.yml`'s `unit` command.
- **Why this level:** the deliverable is a shell script, and the repo has no other runner.
- **Specific checks:** add `tests/release.test.sh` driving the verification against three fixture
  trees built in a temp directory — identical, differing in one file, and differing only in the
  recorded sha — asserting the exit code and, for the second, that the differing path is named. FR6
  is what makes this possible without pushing; a test that has to run the real chain will not be
  written. Prove each case red by mutating the comparison, per AC6.

## Out of scope

- **Resolving divergence** — pulling, merging or rebasing when the fetch shows the checkout behind.
  0075's NFR *Git* holds: that can mean choosing between two of the author's own commits.
- **The no-checkout case.** A session on a machine with no source tree cannot diff against one, and
  what such a session can read is 0061's open design question. This item protects the person
  releasing, not the session running a stale copy.
- **Propagating to other machines.** Each machine still runs its own update; nothing here reaches
  across machines.
- How the harness caches plugins, which this repo does not control.

## Notes & decisions

- Routed to `develop`, not `design`: there is no open decision. The install layout is readable, and
  the comparison is a directory diff plus a field check. Neither trigger applies — no surface, and
  nothing blocks writing the criteria.
- **Deliberately the back half of the chain only.** 0075 owns the front — fetch before editing, and
  derive the bump from the remote — as prose in `retro`. This item is where that prose becomes a
  script, so whichever lands second implements against the other rather than restating it. Both
  `expects:` `skills/retro/SKILL.md`; they should not be built concurrently.
- The two failing checks are independent by observation, not by caution: the stale-bytes-fresh-sha
  case came from `claude plugin update`, and the fresh-bytes-stale-record case from
  `/reload-plugins`, both on 2026-09-01.
- Captured 2026-09-01 from a live investigation, with the install record, the cache mtimes and the
  `diff -rq` output all read directly rather than reconstructed.
