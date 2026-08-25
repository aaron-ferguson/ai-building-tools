---
id: "0007"
title: Replace the Owner column with claim directories
type: chore
next: design
status: ready
qa_level: verify
size: m
created: 2026-08-18
parent: "0002"
blocked_by: ["0005"]
relates: ["0005", "0006"]
expects:
  # Corrected 2026-08-25 from 6 paths to 14, checked against the code rather than predicted.
  # `claimed_by:`/`claimed_at:` are read in 14 places; FR8 retires them, so all 14 are in scope.
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/item.md
  - .claude/backlog/claim          # forced byte-identical to its template by
  - .claude/backlog/close          # tests/backlog-scripts-installed.test.sh AC2
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - README.md
  - .gitignore                     # already carries claims/ — AC4 is pre-satisfied
  - .claude/backlog/QUEUE.md       # its prose documents the token protocol and names 0007 as owner
  - tests/claim.test.sh            # asserts the item records the token
  - tests/close.test.sh            # asserts the claim is released via claimed_by:
  - tests/graph-fields.test.sh     # asserts item.md's key list CONTAINS claimed_by/claimed_at
  - skills/develop/SKILL.md        # Step 1.3 and Step 5.4 instruct writing/clearing the pair
  # Conditional on the design answer below — in scope only under Option A:
  #   skills/queue/templates/next, .claude/backlog/next (line 351 reads claimed_by to build
  #   the CLAIMED FILES block), tests/next.test.sh, skills/verify/SKILL.md, skills/design/SKILL.md
touches:
claimed_by:
claimed_at:
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
- FR4 — `CONCURRENCY.md` *Lock every write to `QUEUE.md`* states one remaining lock case (claiming
  an ID) rather than two, and *Claim tokens* defines ownership by the claim directory rather than by
  a minted token. (Citations corrected 2026-08-23: 0020 replaced the numbered rules with named ones,
  so "Rule 3" and "Rule 4" no longer resolve.)
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

## Open design question

**Raised 2026-08-25 by `develop` (token `c7a9`), which claimed this ticket, could not restate its
contract without deciding this, and handed it back rather than inventing the answer.**

### The question

**When a claim becomes `claims/<id>/`, does `QUEUE.md`'s `Status` column still get `in-progress`
written into it at claim time — and if so, what protects that write once FR2 removes the lock?**

The ticket answers this three ways and they are not compatible:

- The **Problem** says the point is that "`mkdir` … removes the read-modify-write", and complains
  that claiming "writes to the file two windows edit most, on every claim and every release" — so
  `QUEUE.md` is *not* written at claim time.
- **FR2** says "Claiming takes no lock", which is only safe if nothing shared is written.
- **FR3** says releasing is done "in the same turn as **setting the row's status**", which presumes
  a row status is still authored.

`./claim` today does not edit one cell in place: it `awk`s the whole file and `mv`s it (`claim`,
*edit the row*). `CONCURRENCY.md` *Never rewrite `QUEUE.md` by hand* names that full-file rebuild as
the thing that silently clobbers a concurrent row, and *The three scripts* says `./claim` and
`./close` "earn it by holding the lock while they rebuild". Remove the lock without removing the
rebuild and the ticket ships the exact race the lock exists for.

### The three readings, and what each costs

- **Option A — the claim stops writing `QUEUE.md`; `in-progress` becomes derived from `claims/<id>/`.**
  Internally consistent, and it is this project's own precedent: 0024 made `blocked` derived from the
  graph for the same reason — two answers to one question, and the authored one was wrong. FR2 becomes
  true because no shared file is written at all.
  *Costs:* `./next`, `./next --drift` and `QUEUE.md`'s documented value set must all learn the new
  source. `.claude/backlog/next:351` builds its entire CLAIMED FILES block from `claimed_by:`, so the
  file-scope triage in `develop` Step 1 goes blind the moment FR8 lands — that block is the safety
  mechanism the stage uses to avoid collisions. Reading `./next` is **0006's** declared territory, and
  0006 is `blocked_by: 0007`, so the chain would have to reorder. Well beyond `size: m`.
- **Option B — the claim keeps the lock for the `Status` cell.** Smallest blast radius, and FR7/FR8
  still land: ownership moves off `claimed_by:` into a directory.
  *Costs:* FR2 is simply false, and the ticket's headline benefit — "one of `CONCURRENCY.md`'s lock
  cases disappears" — does not materialise. AC2 becomes unsatisfiable as written.
- **Option C — only the item's `status:` frontmatter is set; the column is derived.** FR3's "setting
  the row's status" reads naturally this way.
  *Costs:* leaves two committed sources of truth (the item's `status:` and the column) plus one
  ignored one (`claims/`), which is the multiple-answers defect 0024 exists to remove.

### Second question — is a gitignored claim "durable", and can it ever conflict?

`.gitignore` **already** carries `.claude/backlog/claims/` today, and FR6 keeps it. But
`CONCURRENCY.md` *A claim must be durable the moment it is made* defines durable, for a local file,
as **"only once committed"** — and an ignored path is never committed. Two consequences the ticket
does not address:

- FR4 names only *Lock every write* and *Claim tokens* as the rules to correct. The **durability**
  rule also contradicts the new mechanism and is not in FR4's list. (There is a good answer available
  — an ignored claim is arguably durable *because* ignored, since no other session's pathspec commit
  can carry it off, and both windows share one checkout — but it has to be written down, not assumed.)
- The Problem's multi-person rationale — "two people claiming the same ticket collide on the same
  path — an add/add conflict" — **cannot happen for an ignored path**. Git never sees it. So either
  that rationale is dropped, or `claims/` becomes tracked, which reopens durability from the other
  side.

### What is NOT being asked

FR1, FR5, FR7 and FR8 are clear and are not in question. The mechanism (`claims/<id>/held-by`, a
token, a timestamp, an expiry, converted in both scripts and retired from the template) survives every
option above. Only the `QUEUE.md`/lock half is undecided.

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

- 2026-08-25 — **AC2 is stale, and the staleness came from a sibling, not from the code.** AC2 asks
  that `CONCURRENCY.md` "names exactly one operation that takes the lock", and the Problem says "one
  of `CONCURRENCY.md`'s **two** lock cases disappears". Both were true at capture on 2026-08-18. On
  2026-08-23 **0023** (`60ebd36`) added a **third** case — *closing a row* — because `./close` holds
  the lock while it deletes the `QUEUE.md` row, prepends to `DONE.md` and reconciles every dependent
  naming this ticket in `blocked_by`. Built literally, AC2 now forces the lock off `./close` as well,
  which would automate away the atomicity 0023 and 0024 exist to provide. Every file 0007 names was
  still untouched, so nothing in a diff would have looked wrong. Whatever the design answer, AC2 must
  assert **membership** ("closing a row still takes the lock") rather than **cardinality**.

- 2026-08-25 — **`expects:` was wrong by more than a factor of two, and one cause is structural.**
  It named 6 paths; `claimed_by:`/`claimed_at:` are read in 14. The structural half:
  `tests/backlog-scripts-installed.test.sh` AC2 requires `.claude/backlog/{next,claim,close}` to be
  **byte-identical** to `skills/queue/templates/`, so *any* ticket that edits one of those templates
  silently also owns its installed copy. 0007's `expects:` named the two templates and neither copy.
  The two-line `AC4` case is the opposite error: `.gitignore` already carries
  `.claude/backlog/claims/`, so AC4 is satisfied before the ticket starts.

- 2026-08-25 — **`develop` claimed this (`c7a9`) and released it unbuilt.** No code was written. The
  claim, this section and the *Open design question* above are the only changes. Per `develop` Step 2,
  a missing **decision** is escalated rather than settled by the session about to build against it.
