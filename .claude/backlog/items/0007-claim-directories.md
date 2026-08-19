---
id: "0007"
title: Replace the Owner column with claim directories
type: chore
status: blocked
qa_level: verify
size: s
created: 2026-08-18
parent: "0002"
blocked_by: ["0005"]
relates: []
touches:
---

## Problem

Claiming a ticket is currently a read-modify-write on `QUEUE.md` — read the row as `ready`, write
it `in-progress` — which is why it needs the lock. It also writes to the file two windows edit
most, on every claim and every release.

`mkdir` is already the atomic primitive the lock itself uses. Applying it directly to the claim
removes the read-modify-write, so one of `CONCURRENCY.md`'s two lock cases disappears. It also
lays the groundwork for more than one person: git merges independent files without conflict, and
two people claiming the same ticket collide on the same path — an add/add conflict, which is the
correct outcome rather than a silent overwrite.

## Functional requirements

- FR1 — A claim is `claims/<id>/`, created with `mkdir`, holding a `held-by` file with the claim
  token and an ISO-8601 UTC timestamp.
- FR2 — Claiming takes no lock. The `mkdir` succeeding *is* the claim; failing means another
  session holds it.
- FR3 — Releasing is `rm -rf claims/<id>/`, done in the same turn as setting the row's status.
- FR4 — `CONCURRENCY.md` Rule 3 states one remaining lock case (claiming an ID) rather than two,
  and Rule 4 defines ownership by the claim directory rather than the `Owner` column.
- FR5 — A claim carries an expiry; a claim older than it is reported as stale with its timestamp,
  never silently reclaimed.
- FR6 — `.claude/backlog/claims/` is gitignored in this repo and named in the README's ignore note
  alongside `.lock/`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | An existing backlog whose rows still carry an `Owner` token stays readable; the value is ignored rather than erroring. | `migration-conventions.md` |
| Documentation | `CONCURRENCY.md` is corrected in the same change — it is the file that will be followed, so a stale rule there is followed too. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given no claim on 0042, when `mkdir claims/0042` runs twice, then the first succeeds
  and the second fails non-zero.
- [ ] AC2 — Given `CONCURRENCY.md`, when Rule 3 is read, then it names exactly one operation that
  takes the lock.
- [ ] AC3 — Given `CONCURRENCY.md`, when Rule 4 is read, then ownership is defined by the claim
  directory and the `Owner` column is not referenced as authoritative.
- [ ] AC4 — Given the repo `.gitignore`, when it is read, then `claims/` is present.

## QA plan

- **Level:** verify — shell mechanics and prose, no test runner in this project.
- **Why this level:** AC1 is a two-line shell assertion; the rest are greps.
- **Specific checks:**
  - `mkdir /tmp/c/0042 && ! mkdir /tmp/c/0042` in a scratch dir
  - `grep -c 'takes the lock' references/CONCURRENCY.md` reflects one case
  - `grep 'claims/' .gitignore`

## Out of scope

Anything about multiple people beyond this mechanism — no reservation batches, no ID blocks, no
cross-clone coordination. Jira owns assignment for team work (0004).

## Notes & decisions
