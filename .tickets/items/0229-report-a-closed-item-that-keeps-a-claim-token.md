---
id: "0229"
title: Make next --drift report a closed item that still carries a claim token
type: debt
next: develop
status: ready
qa_level: unit
close_by: develop
qa_manual:
size: s
created: 2026-11-08
source: user
parent:
blocked_by: []
relates: ["0228", "0115"]
expects:
  - skills/queue/templates/next
  - tests/next.test.sh
  - .tickets/next
ac_digest: AC1=a54c5bfa AC2=d0c8f45e AC3=c3ff28f7 AC4=2347757a
claimed_by:
claimed_at:
touches:
---

## Problem

Closed items can keep a `claimed_by:` token, and nothing reports it. `close`, `handoff` and
`reopen` all clear the field today, but closes made by hand before a project had `close` did not:
AetherWorks holds **21** `status: done` items with a token, every one closed between 2026-08-15
and 2026-08-22, two days before its `close` script arrived (2026-08-24). The other four repos
using these tools hold none.

What it has cost so far:

- `migrate` refused AetherWorks' move on 2026-11-08 — *"a row is claimed by another token:
  0023 … [3e1c] …"* — until 0228 made it skip closed statuses.
- `skills/develop/SKILL.md` already warns against grepping `claimed_by:` over `items/*.md`, because
  *"at least five closed items still carry the token"* and a session reading them as live scope
  *"concludes there is nothing safe to develop"*. That is a rule kept as prose where a check could
  hold it.

`./next --drift` walks only the rows in `QUEUE.md` (the loop around
`skills/queue/templates/next` line ~990), so a closed item, which has no row, is never looked at.

## Functional requirements

- FR1 — `./next --drift` also reads every `items/*.md` whose `status:` is `done`, `withdrawn` or
  `rejected`, and for each one with a non-empty `claimed_by:` prints one line,
  `DRIFT     <id> | status <status>, item claimed_by: <token> — a closed item keeps its token; clear claimed_by:`,
  counting as drift (non-zero exit) like every other class.
- FR2 — A closed item with an empty `claimed_by:` is not reported, and nothing about how an
  **open** item's token is judged changes.
- FR3 — `./next --help`'s `--drift` line names the new class alongside the existing ones.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | `--help` names the class a session will now see | AC4's assertion on the `--drift` usage text | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture whose `items/` holds a `status: done` item with `claimed_by: "ab12"` and no `QUEUE.md` row, when `./next --drift` runs, then it exits non-zero and prints one DRIFT line naming that id, `done` and `ab12` — `tests/next.test.sh`
- [ ] AC2 — Given the same item at `status: withdrawn`, and again at `status: rejected`, when `./next --drift` runs, then each is reported the same way — `tests/next.test.sh`
- [ ] AC3 — Given a `status: done` item with an empty `claimed_by:` and no other drift, when `./next --drift` runs, then it prints no DRIFT line and exits 0 — `tests/next.test.sh`
- [ ] AC4 — Given the template, when `./next --help` runs, then its `--drift` line names a closed item keeping a token — `tests/next.test.sh`

Red: AC1/AC2 by removing the new scan; AC3 by a scan that reports every closed item regardless of
the token; AC4 by leaving the usage text as it is.

## QA plan

- **Why that level:** the change is one script's behaviour against fixtures; the suite already
  drives `--drift` this way.
- **Specific checks:** `tests/next.test.sh`, then the whole `unit` command, since `--drive` runs
  the same drift check before it picks a gate.

## Out of scope

- Clearing AetherWorks' 21 tokens. That is AetherWorks' data and its own one-line fix once this
  check names them; it is not provable from this repo.
- Changing `close`, `handoff` or `reopen`, which already clear the field.
- Rewording `skills/develop/SKILL.md`'s warning; it stays true.

## QA evidence

## Notes & decisions

- 2026-11-08 — Filed at the user's request. It was reported as "`close` leaves `claimed_by:` set";
  reading the template showed `close` clears it (`if ($0 ~ /^claimed_by:/) { print "claimed_by:" }`)
  and 0228, closed with it, holds an empty field. Every stale token traced to a by-hand close, so
  the ticket is the check that makes them visible rather than a fix to `close`.
- 2026-11-08 — Routed to `develop`: no surface and no open decision; the DRIFT line's wording is
  given in FR1.
- 2026-11-08 — **Knock-on to know about:** `--drive` escalates on any drift, so a sprint in
  AetherWorks will stop on these 21 lines until they are cleared. The line names the fix for that
  reason.
