---
id: "0246"
title: Make sprint refuse to start on a stale main or a stale plugin
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: m
created: 2026-11-27
source: user
parent:
blocked_by: []
relates: ["0064", "0245"]
expects:
  - skills/sprint/preflight # new — the refusing script
  - tests/sprint-preflight.test.sh # new — its behaviour test
  - skills/sprint/SKILL.md
  - tools/release
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=8eb231e8 AC2=a8fd38f2 AC3=c3ec75f8 AC4=d1245f15 AC5=42c1e7f4 AC6=c17a915c AC7=26842efe AC8=3f6e51dd AC9=aba5b8d4
---

## Problem

**Outcome:** every sprint starts on current information — the checkout is the shared branch and
equals its remote, and, in this plugin's own repo, the installed plugin is the latest release and
holds that release's bytes. A sprint that cannot prove all of this refuses before its first stage
and says which part failed.

Filed at the user's direct request on 2026-11-27, during sprint run-20261127T205235Z, rather than
held. The request, verbatim:

> Make /sprint refuse to start on a stale main or a stale plugin. Each time a sprint starts, main
> must be fully up to date with the remote, and the plugin must be fully up to date, released and
> installed, so a sprint never starts on old information. Proposed shape, in skills/sprint/SKILL.md
> Step 1, before the first stage: (1) git fetch, and refuse unless the checkout is on main and local
> main equals origin/main; (2) tools/release verify --commit origin/main, and refuse unless the
> installed plugin bytes match it; (3) if CHANGELOG.md has a non-empty ## Unreleased, stop and ask
> the person to release first (a release is always the person's decision, never automated). A
> script that refuses, with a behaviour test, rather than prose.

Evidence from that run, as reported:

> this run started with the installed plugin at 0.9.49 while origin/main was 0.9.51, and local main
> was a stale 53ecb3a diverged 50/50 from origin/main. The cloud session also started on a claude/*
> branch that ./claim refuses, so develop 0245 escalated before doing any work. The environment
> setup script has since been changed to refresh the marketplace and plugin and reset main at
> container build, which covers only new containers, not a later sprint in the same container.

Absorbed parked finding (`.tickets/FINDINGS.md`, 2026-11-27, parked at `c0a1884`), verbatim:

> **A fresh cloud session does not start on current `main` or the current plugin, and nothing says
> so until a stage fails.** sprint run-20261127T205235Z: the installed plugin was 0.9.49 while
> `origin/main` was 0.9.51, because the environment setup script only adds the marketplace if
> missing and runs `claude plugin install`, which neither refreshes the marketplace nor updates; the
> container's local `main` was a stale 53ecb3a diverged 50/50 from `origin/main`; and the session is
> put on a `claude/*` branch, which `./claim` refuses (it claims only on `main` unless
> `shared_branch:` is set), so develop 0245 escalated before doing any work. A setup step running
> `claude plugin marketplace update` and `claude plugin update --scope user`, plus a sprint Step 1
> check that fails on a stale install or a checkout that is not current `main`, would catch all
> three (pointer: `skills/sprint/SKILL.md` Step 1, `skills/queue/templates/claim`
> `refuse_off_shared_branch`, `tools/release verify`).

**One correction to the proposed shape, from reading the code.** `tools/release verify --commit
origin/main` compares *every* tracked path at that commit against the install directory
(`verify_one` → `paths_that_differ`), so it reds on the first backlog commit after a release — the
defect 0157 recorded and 0064 FR5/FR6 now carry. Every sprint pushes backlog commits, so check (2)
against `origin/main` would refuse almost every sprint on a correct install. FR3 below checks the
install against the commit it was released at, and the version against `origin/main`'s, which
answers the same question without that false red.

## Functional requirements

- FR1 — A new script, `skills/sprint/preflight`, run from the project root, makes three checks in
  order and stops at the first that fails, with a distinct non-zero exit per check and a message
  naming the check, the observed state and the command a person would run. It changes nothing but
  remote-tracking refs: it never checks out, resets, merges, bumps, pushes or releases.
- FR2 — **Check 1, the checkout.** It fetches the shared branch from `origin`, and refuses when the
  fetch fails (currency is then unprovable), when the current branch is not the shared branch, or
  when local and `origin/<shared>` differ — naming *behind N*, *ahead M* or *diverged N/M*. The
  shared branch resolves exactly as `skills/queue/templates/claim`'s `refuse_off_shared_branch`
  resolves it (`shared_branch:` in `config.yml`, then `origin/HEAD`, then `main`), so the two can
  never disagree about which branch is current.
- FR3 — **Check 2, the install, only in the plugin's source checkout** (one whose
  `.claude-plugin/plugin.json` names this plugin). It refuses unless the version in the installed
  record equals the version in `origin/<shared>`'s `.claude-plugin/plugin.json`, and
  `tools/release verify --commit <the record's gitCommitSha>` exits 0 — the install holds the bytes
  of the commit it claims, and that commit is the latest release. It never compares against
  `origin/<shared>` itself, so a backlog-only commit after the release does not red it.
- FR4 — **Check 3, unreleased work, only in the plugin's source checkout.** When
  `origin/<shared>`'s `CHANGELOG.md` has a non-empty `## Unreleased`, it refuses with its own exit
  code and a message saying the release is the person's decision and naming `tools/release`; it
  runs no part of the release.
- FR5 — In any other project, checks 2 and 3 print one line each saying they were skipped and why,
  and the script's result is check 1's.
- FR6 — `skills/sprint/SKILL.md` Step 1 runs `skills/sprint/preflight` (from the plugin root) before
  the CLI probe; a non-zero exit ends the run before any dispatch and reports the script's message
  as the escalation. The heading's count of checks, and the "four checks above" back-reference in
  *The proposal*, are updated to match.
- FR7 — The script accepts `--record <file>` (passed through to `tools/release verify`) so the
  behaviour test drives it against fixture repositories and a fixture install record rather than
  the machine's real install.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | The refusal is fail-closed: a fetch failure, a missing record or an unreadable `plugin.json` refuses rather than passes. | AC3 reds if the fetch is `\|\| true`; AC8's fixture reds if check 2 runs outside a source checkout and passes on a missing record. | `security-conventions.md` |
| Observability | Each refusal names which check failed, the observed state (branch name, ahead/behind counts, both versions, differing paths) and the next command. | AC1, AC2, AC4, AC5 and AC7 each assert the named state in the output; dropping it reds them. | `observability-conventions.md` |
| Privacy & data | Nothing it prints reaches a tracked file; the test fixtures are built under `mktemp -d` and hard-code no home path. | `tests/measurement.test.sh` reds on a home path in a tracked file. | `data-privacy-conventions.md` |
| Documentation | One `## Unreleased` entry in `CHANGELOG.md` saying a sprint now refuses to start on a stale checkout or install, per the repo's release rule. | `tools/release` refuses a bump on an empty `## Unreleased`; a reading at verify finds the entry absent. | `documentation-conventions.md` |

## Acceptance criteria

All fixtures are built by `tests/sprint-preflight.test.sh`: a bare `origin`, a clone, and for the
plugin-source cases a `.claude-plugin/plugin.json`, a `CHANGELOG.md`, an install directory and a
fixture install record passed with `--record`.

- [ ] AC1 — Given a clone on branch `claude/x` whose `main` equals `origin/main`, when `preflight` runs, then it exits with check 1's code, the output names `claude/x` and `main`, and `git symbolic-ref HEAD` is still `refs/heads/claude/x`. Red: delete the branch comparison.
- [ ] AC2 — Given a clone on `main` and a commit pushed to the bare `origin` from a second clone *after* the first clone's last fetch, when `preflight` runs, then it exits with check 1's code naming *behind 1*, and local `main` still points at its old commit; a second case with one local and one remote commit names *diverged 1/1*. Red: compare against the existing `origin/main` ref without fetching — the fixture's stale ref then matches and the case passes.
- [ ] AC3 — Given a clone whose `origin` URL points at a path that does not exist, when `preflight` runs, then it exits non-zero naming the failed fetch. Red: make the fetch `|| true`.
- [ ] AC4 — Given a current plugin-source clone whose fixture record names version `0.1.0` while `origin/main`'s `plugin.json` says `0.1.1`, when `preflight` runs, then it exits with check 2's code naming both versions. Red: drop the version comparison.
- [ ] AC5 — Given versions that agree and a fixture install directory differing from the record's `gitCommitSha` in one tracked file, when `preflight` runs, then it exits with check 2's code and the output carries that file's path. Red: skip the `tools/release verify` call.
- [ ] AC6 — Given an install whose record and bytes match the release commit, an empty `## Unreleased`, and one later commit on `origin/main` that changes only `.tickets/QUEUE.md`, when `preflight` runs, then it exits 0. Red: pass `--commit origin/main` to `tools/release verify` instead of the record's `gitCommitSha`.
- [ ] AC7 — Given AC6's fixture with one bullet under `## Unreleased` on `origin/main`, when `preflight` runs, then it exits with check 3's code, the output names `tools/release`, and the clone's `HEAD`, `plugin.json` and `origin` refs are unchanged. Red: delete check 3.
- [ ] AC8 — Given a current clone with no `.claude-plugin/plugin.json` and no install record, when `preflight` runs, then it exits 0 and prints that checks 2 and 3 were skipped. Red: run check 2 unconditionally — it then refuses on the missing record.
- [ ] AC9 — Given `skills/sprint/SKILL.md`, when Step 1 is read, then it runs `skills/sprint/preflight` before the CLI probe and ends the run on a non-zero exit with the script's message as the escalation, and the check count in the heading and in *The proposal* matches. Red: the step absent, placed after the probe, or the counts left at four.

## Out of scope

- **Checking a consuming project's install against the marketplace's latest version.** It needs
  `claude plugin marketplace update`, a network write the preflight must not make, and a project
  other than this one has no `tools/release` or source `plugin.json` to compare against. Raise it
  as its own ticket if a consuming project confirms the need.
- **The container setup script.** Already changed out of band to refresh the marketplace and
  plugin and reset `main` at build; this ticket covers the later sprint in the same container.
- **Repairing what it finds** — resetting `main`, switching branch, updating the install or
  releasing. Each is a person's decision; the script names the command and stops.
- **0064 FR5/FR6** (`tools/release verify`'s own default against `HEAD`). FR3 passes `--commit`
  explicitly, so this ticket neither needs nor changes that default.

## Notes & decisions

- 2026-11-27 — Filed at the user's direct request in sprint run-20261127T205235Z, so filed rather
  than held (CLAUDE.md, *Where toolkit work comes from*). **Amend-first test:** 0064's outcome is
  that a session can tell which installed copy runs and that it matches the released commit; this
  ticket's is that a sprint refuses to *start* on a stale checkout or install. Related but separate
  outcomes, and the user asked for its own ticket ranked below 0064, so minted, not amended.
- 2026-11-27 — **Routed to `develop`:** no surface and no open decision — a refusing script whose
  inputs (git refs, the install record, `plugin.json`, `CHANGELOG.md`) are all readable in code.
  The one deviation from the proposed shape (check 2 against the record's commit, not
  `origin/main`) is a correction with a right answer, recorded in the Problem.
- 2026-11-27 — `close_by: verify`, because AC9 is a reading of skill prose and the repo's rule is
  that no new guard greps prose.
