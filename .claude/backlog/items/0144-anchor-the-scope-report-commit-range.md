---
id: "0144"
title: Anchor the scope report's commit range to the claim commit for this ticket, not any commit carrying the token
type: bug
next: develop
status: in-progress
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0049"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - .claude/backlog/close
  - .claude/backlog/handoff
  - tests/close.test.sh
  - tests/handoff.test.sh
claimed_by: "7af7"
claimed_at: 2026-09-11T22:08:51Z
touches:
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - .claude/backlog/close
  - .claude/backlog/handoff
  - tests/close.test.sh
  - tests/handoff.test.sh
---

## Problem

**`close` and `handoff` find the claim commit that anchors the scope report with a bare token grep
over the whole history, so the first token reuse silently attributes another ticket's files to this
one.** Both scripts run
`git log --format='%H %s' | grep -F "[$TOKEN]" | tail -1` — every commit, any subject, oldest match
wins. Claim tokens are four hex characters and nothing checks one for reuse, so once a token repeats,
the *older* ticket's claim commit becomes the range start and every commit in between is read as this
ticket's work.

Reproduced in a throwaway repo: an ancient `Claim 0001 [abcd]` commit ahead of `Claim 0700 [abcd]`
made the close report `ancient/unrelated-a.ts ancient/unrelated-b.ts` as `0700`'s
touched-but-undeclared paths. No collision exists in this repo's history yet — no token has claimed
two tickets — which is exactly why nothing is red, and why the failure arrives as a confident,
specific, wrong report rather than as an error.

The scripts already know the id, so the precise anchor costs nothing:
`grep -E "^Claim $ID \[$TOKEN\]"`. The failure this produces — a report naming files the ticket never
touched — is the same failure `0106`'s own Problem section exists to prevent, which makes the current
anchor a hole in the feature that added it.

## Functional requirements

- **FR1** — Both scripts anchor the range to a commit whose subject matches the ticket id *and* the
  token, not the token alone.
- **FR2** — Where no such commit exists, the behaviour is the one the scripts have today for a missing
  anchor, unchanged — this row narrows a match, it does not add a refusal.
- **FR3** — The template and the installed copy change together, and the byte-for-byte comparison that
  already guards the shared scope block covers the new line.

## Non-functional requirements

- **Compatibility** — a history with no token collision produces byte-identical reports before and
  after. How this would red: a case capturing the report over a collision-free fixture and comparing
  it against the pre-change output.

## Acceptance criteria

- [ ] AC1 — Given a fixture history with `Claim 0001 [abcd]` older than `Claim 0700 [abcd]`, and
  commits between them touching files the ticket never declared, when `close` runs for `0700`, then the
  scope report names none of those files. Red-making input: today's scripts, whose output is captured
  in the Problem section.
- [ ] AC2 — Given the same fixture, when `handoff` runs for `0700`, then the same holds. Red-making
  mutation: fixing `close` and not `handoff`, which is the shape the shared-block comment warns about.
- [ ] AC3 — Given a fixture history with no collision, when `close` runs, then the report is identical
  to the one today's script produces. Red-making mutation: anchoring on the id alone, which re-breaks
  a ticket whose claim was superseded.
- [ ] AC4 — Given a ticket with no claim commit at all, when `close` runs, then it behaves as it does
  today. Red-making mutation: making the narrower match fatal.
- [ ] AC5 — Given `tests/close.test.sh`'s byte-for-byte comparison of the scope block in `close` and
  `handoff`, when it runs, then it passes. Red-making change: editing one script and not the other.
- [ ] AC6 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing the templates and not the installed copies.

## QA plan

- **Why this level:** `unit` — both scripts have large existing suites that already scaffold fixture
  repositories with claim commits, which is all the collision case needs.
- **Specific checks:**
  - Build the collision fixture first and confirm today's scripts produce the wrong report, so AC1's
    red is observed rather than assumed.
  - Run `tests/close.test.sh`, `tests/handoff.test.sh` and
    `tests/backlog-scripts-installed.test.sh` individually, then the whole suite with `|| true`.

## Out of scope

- Making tokens collision-proof, or checking a token for reuse at claim time. A longer token is a
  different decision and `0049` owns what a token guarantees.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0106` that marked itself NEEDS A ROW. The
  reproduction and the exact replacement grep are the park's, verified in a throwaway repo by that
  session.
