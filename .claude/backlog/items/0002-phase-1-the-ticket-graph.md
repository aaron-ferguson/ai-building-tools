---
id: "0002"
title: Phase 1 — the ticket graph
type: feature
next:
status: active
created: 2026-08-18
parent: "0001"
ships: together
---

## Outcome

Tickets nest to any depth, dependencies are recorded and enforced, and the rank is checkable
against them. Everything later in 0001 assumes this.

## Why `ships: together`

The four tasks are one capability. Fields with no reader (0005 alone), a reader with no rules
(0006 alone), or rules citing a shape that has not landed (0008 alone) each deliver nothing on
their own and leave the backlog in a shape that is worse than before — half-migrated, with two
sessions reading different conventions. So the ranking decision is the whole group, at the cost
of the whole group.

## Slices

In dependency order: **0005** (fields) → **0007** (claims) → **0006** (reader) → **0008** (rules).

## Cross-cutting commitments

- **Readers tolerate both shapes.** `next` resolves columns from the header row by name, never by
  index, so a backlog that has not migrated still works. This is the commitment every task in this
  project must satisfy.
- **No full-file writes to `QUEUE.md`.** Every change here is a single-row edit
  (`CONCURRENCY.md` Rule 1), including the one-time column migration, which touches the header and
  each row separately.

## Out of scope

The readiness gate, `measure`, rollup close, and anything Jira. Those are 0003 and 0004.

## Notes & decisions

- Doing 0007 before 0006 means the reader is written once against the final column set rather than
  learning to parse an `Owner` column that is about to be deleted.
