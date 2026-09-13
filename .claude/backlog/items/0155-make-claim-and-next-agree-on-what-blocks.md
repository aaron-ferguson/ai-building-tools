---
id: "0155"
title: Make claim and next agree on what blocks a take
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0067", "0147", "0045", "0066"]
expects:
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/claim.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Five defects where `claim` and `next` disagree, each from the findings buffer:

1. **`claim` reads any `*` inside an `expects:` entry as the exclusive claim `"*"`.** The detector is
   `if ($0 ~ /\*/)`, so `tests/*.test.sh` is refused with *"its expects: declares \"*\", an exclusive claim
   over the whole tree"* whenever anything else is held; `next` uses `contains_word '*'` and reads the
   glob as one path (verify 2026-09-10, develop 0147).
2. **`next` offers a takeable exclusive-claim row that `claim` then refuses.** With another row held,
   `./next develop` printed `TAKE 0001 … EXPECTS *`; 0067 FR5/FR6 key on a *held* `"*"` row only.
3. **`./claim <id>` makes no file-scope check.** `/develop 0130` claimed a row whose four `expects:`
   paths were the four `0131` held, with no warning; only `./next <stage>` prints the comparison, and
   only for its own candidate.
4. **`--drift` does not flag an `expects:` path that exists nowhere.** After the 0129 rename four open
   rows expected `skills/orchestrate/SKILL.md`; a path that exists nowhere collides with nothing, so the
   row reads clear exactly when nobody can tell (four sessions reported it).
5. **`next --help` calls the collision test the third of four; since 0140 it is the fourth.**

## Functional requirements

- FR1 — `claim`'s exclusive detector matches only an entry that is exactly `"*"` or `*`, in both copies.
- FR2 — `next` does not print TAKE for an exclusive-claim row while another row is held.
- FR3 — `./claim <id>` reports a collision between the row's `expects:` and every held row's `touches:` (or predicted set, per `CONCURRENCY.md`) before granting.
- FR4 — `./next --drift` reports an open row whose `expects:` names a path that does not exist and matches no glob.
- FR5 — the usage paragraph names the collision test rather than its ordinal.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | Each FR has a fixture case, and the template copies are what the cases exercise. | `backlog-scripts-installed` reds on a single-copy edit. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture item with `expects:` `- tests/*.test.sh` and another row held, when `./claim` runs, then it is not refused as exclusive. Red-making input: today's detector.
- [ ] AC2 — Given a takeable row with `expects: "*"` and another row held, when `./next develop` runs, then that row is not printed as TAKE. Red-making input: today's take loop.
- [ ] AC3 — Given a held row touching `a.md` and a ready row expecting `a.md`, when `./claim <ready id>` runs, then the output names the collision and the holder. Red-making input: today's claim.
- [ ] AC4 — Given an open row expecting a path that does not exist, when `./next --drift` runs, then that id and path are reported and the exit is non-zero. Red-making input: today's drift.
- [ ] AC5 — Given `./next --help`, when it runs, then the output contains no ordinal naming the collision test. Red-making input: the word `third` in today's usage.

## QA plan

- **Why that level:** `unit` — every requirement is a case over scaffolded fixture backlogs in the existing suites.
- **Specific checks:** `tests/claim.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`, each mutated in the template copy.

## Out of scope

- Whether an empty `touches:` is held, which is 0145's decision; FR3 follows whatever it settles.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Six buffer entries from five sessions, grouped because each is the two scripts giving opposite answers about one take, and they share both files.
