---
id: "0239"
title: Codex test
type: chore
next: develop
status: ready
qa_level: verify
close_by: verify
size: s
created: 2026-11-22
source: user
parent:
blocked_by: []
relates: []
expects:
  - README.md
ac_digest: AC1=86d5a764
claimed_by:
claimed_at:
touches:
---

## Problem

The requester wants to confirm that AI Building Tools can take a queued ticket through Codex and produce a small, observable repository change.

> a one line comment being added to a file with instructions to delete it when found just as a way to test that the tools are working correctly when I use Codex

## Functional requirements

- FR1 — Add exactly one line immediately below the first heading in `README.md`: `<!-- Codex test: Delete this comment when you find it. -->`

## Acceptance criteria

- [ ] AC1 — Given the README at the start of development, when the implementation diff is inspected, then it adds exactly the specified comment immediately below the first heading and changes zero other lines or files outside the backlog.

## QA plan

- This comment-only change can be checked against the implementation diff.
- Run `sed -n '2p' README.md` and compare the output with the exact line in FR1. Run `git diff --numstat <before> <after> -- . ':(exclude).tickets/**'` for the implementation range and require exactly one row with one insertion, zero deletions and path `README.md`. A missing, moved or changed comment or any additional edit outside the backlog fails AC1.

## Out of scope

- Removing the comment is a separate cleanup after it is found.

## QA evidence

## Notes & decisions

- 2026-11-22 — The open tickets address other outcomes. This one-off test has its own result and goes directly to development. Selected `README.md` as an easy place to find the comment in source.
