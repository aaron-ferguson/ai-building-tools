---
id: "0004"
title: Phase 3 — extend tracker mirroring with hierarchy and company ticket standards
type: feature
status: blocked
qa_level: verify
size: l
created: 2026-08-18
parent: "0001"
blocked_by: ["0002", "0003"]
relates: []
touches:
---

## Problem

`references/TRACKER.md` (added 2026-08-17) already defines one-way mirroring to an external
tracker: local is the source of truth, `develop` mirrors on claim / close / block, a tracker
outage never blocks work, and no network call happens inside the lock. That design is sound and
this ticket **extends it rather than replacing it**.

Three gaps remain, and one of them is a correctness problem in a company project:

1. **No hierarchy.** `tracker_key` is a flat pointer. Nothing maps `parent:` to a tracker parent,
   and nothing validates that a local chain is legal in the target project.
2. **The mirror writes its own ticket format.** TRACKER.md specifies title + problem + AC +
   item path, and explicitly not the NFR table. In a generic tracker that is right. Against
   Neumo's Jira it produces a ticket that fails the story rubric on user-story format, AC field
   placement, Requirements/SOW, Site field, Affects Variant/s, and scope declaration — a
   rubric-failing ticket filed automatically into a shared board.
3. **Only one direction is modelled.** Mirroring assumes the agent generates the work. When a
   team shares a Jira queue, assignment happens there and the local backlog holds a pulled slice.

## Functional requirements (sketch — decompose before starting)

- FR1 — `tracker.direction: mirror | pull`. **mirror** is TRACKER.md's existing behaviour, local
  authoritative, unchanged. **pull** is the team case: Jira owns assignment, local holds a slice.
- FR2 — **The writer is selected by company policy.** With no company profile, the generic mirror
  body in TRACKER.md stands. With one, every write goes through `/jira-ticket` write mode, which
  resolves the family, applies the rubric, places the fields and adds org-required ones. The
  bridge never calls `createJiraIssue` or `editJiraIssue` directly in that case.
- FR3 — Hierarchy mirrors: `parent:` maps to the tracker's parent field, discovered per project
  and cached, never hardcoded. Local depth beyond what the tracker supports stays local-only and
  is named rather than flattened.
- FR4 — Issue type resolves from `issue_type_for` by default, overridable per ticket, because
  local depth is arbitrary and the tracker's is not.
- FR5 — `blocked_by:` mirrors to tracker issue links.
- FR6 — In `pull` direction, the claim protocol is **transition first, assign second**: a workflow
  transition is validated against current status server-side and is the only compare-and-swap
  available; assignment is last-write-wins and fails silently. Read back and confirm both.
- FR7 — Where a project has no claim status (JUS runs Open / In Testing / Closed), fall back to
  assign-and-read-back and state that the guarantee is weaker rather than implying a lock. Where a
  workflow permits a self-loop transition, the compare-and-swap is void — check once at setup and
  record it.
- FR8 — Assigned to someone else is never takeable; a stale assignment is never auto-reclaimed.
  Report the assignee and the age. The local stale-lock rule does not cross this boundary, because
  in a tracker a stale claim is a person.
- FR9 — `pull --mine`: `assignee = currentUser() AND statusCategory != Done`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | Extends TRACKER.md's "what never goes in a ticket". Additionally: never import comments or attachments; descriptions off by default; import the metadata skeleton and write the local problem from the generalised problem. A tracker-routed backlog must not live in a public repo. | `data-privacy-conventions.md` |
| Security | Credentials resolve through the existing `/jira-ticket` setup and the OS secret store. No new secret handling. | `security-conventions.md` |
| Documentation | TRACKER.md is edited in place, not shadowed by a second document. Two files describing one mechanism is how the mechanism drifts. | `documentation-conventions.md` |

## Open design question

- **Question:** which Jira project is the test case, and does a standalone probation product warrant
  its own project key or an effort inside an existing Court-family project?
- **Why it blocks specification:** FR3's chain validation and FR6's claim protocol both depend on
  the target project's issue types and workflow statuses, which vary per project — AAT does not
  match ACT, and JUS matches neither.
- **Settle it with:** `/design`, once Aaron confirms the key.

## Out of scope

Reservation batches, per-person ID blocks, cross-clone coordination. Jira owns assignment for team
work; the local claim mechanism (0007) covers the single-machine case.

## Notes & decisions

- **2026-08-19** — Discovered `references/TRACKER.md` mid-planning; it was committed 2026-08-17,
  after this design started. Roughly 70% compatible — one-way, local-authoritative, outage-tolerant,
  no network calls inside the lock, import as a separate explicit operation. The conflicts are
  concentrated in **who writes the ticket body** and **which side owns the claim**, which is what
  FR2 and FR1 resolve. Adopt its `tracker_key` and `tracker:` naming rather than introducing a
  parallel `external:` block.
- **2026-08-19** — Test case is Aaron's standalone probation product in the Court family. It will
  start at discovery, not delivery: `epic.md` makes a missing discovery link Major, so the first
  push will correctly refuse an epic with no CTD idea behind it. That is the gate working.
- **2026-08-19** — This project is `routing.default: local`, so phase 3 cannot be tested here.
