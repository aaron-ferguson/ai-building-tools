---
id: "0007"
title: Replace the Owner column with claim directories
type: chore
next: develop
status: blocked
qa_level: verify
size: m
created: 2026-08-18
parent: "0002"
blocked_by: ["0005"]
relates: ["0005", "0006"]
expects:
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/item.md
  - references/CONCURRENCY.md
  - .gitignore
  - README.md
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
- FR7 — **The two scripts that implement ownership are converted, not just the prose.**
  `skills/queue/templates/claim` creates `claims/<id>/held-by` per FR1 and FR2; `close`'s ownership
  test reads that file rather than the item's `claimed_by:`, and stops writing `claimed_by:` /
  `claimed_at:` on close. Without this the mechanism exists only in `CONCURRENCY.md` while both
  scripts still run the token protocol — two live protocols, which is the defect parked twice in
  `FINDINGS.md` rather than a migration.
- FR8 — `claimed_by:` and `claimed_at:` are retired from `skills/queue/templates/item.md`, and the
  comment that documents them goes with them. A field no script reads is a field the next session
  fills in for nothing.

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
- [ ] AC5 — Given a fixture backlog with a claim held as `claims/0042/held-by`, when `close 0042
  <wrong-token>` runs, then it exits non-zero naming the holding token, and when it runs with the
  token from `held-by`, then it closes and the claim directory is gone.
- [ ] AC6 — Given `skills/queue/templates/claim`, `close` and `item.md`, when each is searched for
  `claimed_by`, then there are no matches.

## QA plan

- **Level:** verify — shell mechanics and prose, no test runner in this project.
- **Why this level:** AC1 is a two-line shell assertion; AC5 needs a throwaway fixture backlog
  driven through the real scripts, because an ownership test is only proved by a wrong token being
  refused; the rest are greps.
- **Specific checks:**
  - `mkdir /tmp/c/0042 && ! mkdir /tmp/c/0042` in a scratch dir
  - `grep -c 'takes the lock' references/CONCURRENCY.md` reflects one case
  - `grep 'claims/' .gitignore`
  - a scratch backlog: `claim 0042`, then `close 0042 wrong` (expect non-zero, holder named), then
    `close 0042 "$(head -1 claims/0042/held-by)"` (expect success, `claims/0042/` gone)
  - `! grep -rq claimed_by skills/queue/templates/` for AC6

## Out of scope

Anything about multiple people beyond this mechanism — no reservation batches, no ID blocks, no
cross-clone coordination. Jira owns assignment for team work (0004).

## Notes & decisions

- 2026-08-23 — **FR7 and FR8 added after 0006 gained its instantiation FR.** 0006 FR8 instantiates
  all three scripts into this backlog and AC8 requires the local copies to `diff` clean against the
  templates; that is only provable if the templates by then implement one ownership protocol. This
  ticket defined the directory mechanism and corrected `CONCURRENCY.md`, but named neither script —
  so the conversion had no owner, and 0006 would have inherited template surgery in a ticket about
  `next`. It belongs here: this ticket is the ownership protocol.
- 2026-08-23 — **`claimed_by:` is retired here rather than in 0005**, even though 0005 owns
  `item.md`'s frontmatter. 0005 *adds* the graph fields; the field being removed is dead only
  because of FR7, in this ticket, and splitting the two halves would leave whichever landed first
  describing a protocol the other had not built yet.
- 2026-08-23 — **`size` raised `s` → `m`.** It was sized for a mechanism plus two prose edits;
  converting `claim` and `close` and retiring a frontmatter pair from the shipped template is a
  focused session, not one sitting. Rank is untouched — `size` feeds tie-breaker 4 only.
