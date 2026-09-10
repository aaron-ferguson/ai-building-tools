---
id: "0147"
title: Make claim name the declared paths that do not exist instead of reserving them
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0075"]
expects:
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A ticket's `expects:` can name a file that has never existed, and the lifecycle presents it as a
path.** `0075` expected `tests/skill-prose.test.sh`; there is no such file in the tree or anywhere in
the history. `./next develop`'s `EXPECTS` line is the first thing a claiming session reads about scope,
and `./claim` seeds `touches:` from it verbatim — so a fictional path is *reserved as held scope*,
against which the file-scope check then compares every other session's work, until somebody narrows it
by hand.

`./claim` already warns that `touches:` is provisional and must be narrowed. What it cannot currently
say is **which** of the paths are not real, which is the one fact that distinguishes "narrow this" from
"this ticket's scope is partly fiction" — and it is a fact the script is standing in the right place to
check.

A fictional `expects:` entry is also a signal about the ticket rather than about the tree: `0075`'s was
a test file a capture pass assumed would exist. Naming it at claim time is the cheapest moment to
discover that the ticket was specified against a file nobody wrote.

## Functional requirements

- **FR1** — `./claim` reports, for each path it seeds into `touches:`, whether it resolves in the
  working tree, and names the ones that do not.
- **FR2** — A non-existent path is a **warning, not a refusal**: a ticket may legitimately declare a
  file it is about to create, and that is the common case for a new guard.
- **FR3** — A directory and a glob both count as resolving if they match anything, so declaring
  `tests/` or `items/` is not reported.
- **FR4** — The report distinguishes *does not exist* from *exists and is held by another claim*, which
  the script already reports separately and must keep separate.

## Non-functional requirements

- **Compatibility** — a claim whose every declared path exists produces the output it produces today.
  How this would red: a case comparing the full output over an all-resolving fixture.

## Acceptance criteria

- [ ] AC1 — Given an item whose `expects:` names one path that does not exist and one that does, when
  `./claim` runs, then it names the missing one and not the existing one, and the claim succeeds.
  Red-making input: today's `claim`, which names neither.
- [ ] AC2 — Given an item whose `expects:` names only paths that exist, when `./claim` runs, then the
  output is byte-identical to today's. Red-making mutation: printing an unconditional line.
- [ ] AC3 — Given an item declaring a directory that exists and a glob that matches at least one file,
  when `./claim` runs, then neither is reported missing. Red-making mutation: testing with `-f`, which
  reports every directory as absent.
- [ ] AC4 — Given an item declaring a path that exists and is held by another claim, when `./claim`
  runs, then it is reported as held and not as missing. Red-making mutation: reporting both from one
  branch.
- [ ] AC5 — Given `0075`'s real item file, when `./claim 0075` runs against it, then
  `tests/skill-prose.test.sh` is named as not existing. Red-making input: today's script.
- [ ] AC6 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing the template and not `.claude/backlog/claim`.

## QA plan

- **Why this level:** `unit` — `claim` has a large existing suite that already scaffolds fixture
  backlogs with `expects:` lists.
- **Specific checks:**
  - Run `tests/claim.test.sh` and `tests/backlog-scripts-installed.test.sh` individually, then the
    whole suite with `|| true` per `config.yml`'s note.
  - Confirm AC2 by capturing today's output before the change and diffing, not by reading the new
    branch.

## Out of scope

- Correcting `0075`'s own `expects:`. The field is the ticket's and editing it is an `amend`.
- Refusing a claim over a fictional path. FR2 decides against it.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0075`. The park identified the exact place
  to report it — `claim`'s existing `touches: is set provisionally` warning — which FR1 follows.
