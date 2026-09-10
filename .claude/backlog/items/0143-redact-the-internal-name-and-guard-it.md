---
id: "0143"
title: Redact the internal organisation name from this public repo and guard the rule forbidding it
type: bug
next: develop
status: in-progress
qa_level: unit
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0118", "0122"]
expects:
  - tests/measurement.test.sh
  - .claude/backlog/items
  - .claude/backlog/RANKING-HISTORY.md
claimed_by: "8ca0"
claimed_at: 2026-09-10T04:01:58Z
touches:
  - tests/measurement.test.sh          # transiently MUTATED and restored to prove the guard reds
  - .gitignore                         # new: the name list must be unmissable to commit
  - CLAUDE.md
  - .claude/backlog/RANKING-HISTORY.md
  - .claude/backlog/items/0003-phase-2-readiness-and-outcomes.md
  - .claude/backlog/items/0004-phase-3-jira-bridge.md
  - .claude/backlog/items/0056-design-non-ui-and-write-step.md
  - .claude/backlog/items/0070-structured-debugging-discipline.md
  - .claude/backlog/items/0111-give-retro-a-resolution-order-for-several-backlogs.md
  - .claude/backlog/items/0113-give-retros-release-chain-a-multi-repo-form.md
---

## Problem

**`CLAUDE.md` forbids internal organisation material in this public repo, and five tracked files
carry an internal repository name anyway.** The rule is stated as the repo's defining constraint —
`company: none` "is not a default, it is the constraint" — and it is the one privacy rule with no
check behind it. The privacy guard that exists (`tests/measurement.test.sh`, `HOME_PATH_PAT`) matches
home-directory paths and nothing else, so an organisation name is published with the suite green.

The leaked token is an internal repository path, written in the `Problem` and `Decision` sections of
one item by a capture pass and a design pass, and then copied forward — it now appears in two more
item files, in `RANKING-HISTORY.md` and in `FINDINGS.md`. This row does not restate it; the session
that claims this row finds the occurrences by the search FR1 describes, which is also why `0122` —
whether a mention of a privacy rule may name the thing the rule forbids — is related and not a
blocker.

**The history is already pushed and cannot be unpublished by this row.** Redaction stops the
republishing; removing it from history is a rewrite of a branch other machines install from, which is
a person's decision and not this ticket's. The row records that boundary rather than deciding it.

`0118` covers the adjacent gap — that the sessions most likely to leak are the ones that run no
suite — and is deliberately left whole: this row adds the pattern, `0118` adds the reach.

## Functional requirements

- **FR1** — The guard matches an internal organisation or client name in any tracked file, from a
  configured list rather than a literal in the test, so adding a name does not mean editing an
  assertion. The list lives where a public repo can hold it: the names are the secret, so the list is
  a path the guard reads if present and skips if absent, never a committed enumeration.
- **FR2** — Every current occurrence is redacted to a placeholder form that still says what the
  sentence needed it for (*an internal repository*, *a second backlog*), so no item loses its meaning.
- **FR3** — The guard has the same redaction exemption `HOME_PATH_PAT` has, proved the same way, so
  prose *about* this defect can be written without reddening it.
- **FR4** — A falsification control asserts the pattern still catches a real-shaped name, with the
  samples assembled rather than written, for the reason the existing block documents.

## Non-functional requirements

- **Security** — the configured name list is never committed and never printed by a failing
  assertion; the guard reports the file and line, not the matched text. How this would red: a case
  asserting the failure output does not contain the matched token.
- **Compatibility** — the home-path guard keeps working unchanged. How this would red: the existing
  `HOME_PATH_PAT` cases, which must stay green.

## Acceptance criteria

- [ ] AC1 — Given a configured name list and a tracked file containing one of those names, when
  `tests/measurement.test.sh` runs, then it fails and names the file and line. Red-making input: the
  tree as it stands today, which contains five such files and passes.
- [ ] AC2 — Given no configured name list present, when the test runs, then the name check is reported
  as not applicable and the file still reports `0 failed`. Red-making mutation: failing closed on a
  missing list, which makes the suite unrunnable on a fresh clone.
- [ ] AC3 — Given a tracked file containing the placeholder form FR2 uses, when the test runs, then it
  is not flagged. Red-making mutation: dropping the exemption, which flags this item file itself.
- [ ] AC4 — Given the assembled real-shaped sample, when the pattern is applied, then it matches.
  Red-making mutation: widening the exemption until the sample passes.
- [ ] AC5 — Given `git grep` over the tracked set for the redacted token, when it runs, then it
  reports nothing. Red-making input: today's tree.
- [ ] AC6 — Given a failing run, when its output is read, then the matched token does not appear in
  it. Red-making mutation: interpolating the match into the message, the obvious implementation.
- [ ] AC7 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`.

## QA plan

- **Why this level:** `unit` — the guard is a shell assertion block in an existing suite file, and
  every requirement is a case over assembled samples and a fixture tree.
- **Specific checks:**
  - Run `tests/measurement.test.sh` first on its own, then the whole suite file-by-file with
    `|| true` per `config.yml`'s note.
  - Confirm AC5 by `git grep` rather than by reading the files changed, so a sixth occurrence nobody
    listed is found.
  - Mutate the exemption and the pattern independently — `0111`'s AC5 and the `findings-routing` AC5
    block are both precedents for one guard silently covering two claims.

## Out of scope

- Rewriting pushed history. Named in the Problem section as a person's decision.
- Running the guard from the skills that commit without a suite — that is `0118`.
- Deciding whether a rule's own prose may name what it forbids — that is `0122`, and this row is
  written to be correct under either answer.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `verify` park on `0111`. The park found one item file; the
  retro's own `git grep` found five files, which is why FR2 is scoped by a search and not by a list.
  Written without naming the token, on the reading of `0122` that is safe under both answers.
