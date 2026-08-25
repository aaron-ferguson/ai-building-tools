---
id: "0007"
title: Replace the Owner column with claim directories
type: chore
next: develop
status: ready
qa_level: verify
size: l
created: 2026-08-18
parent: "0002"
blocked_by: ["0005"]
relates: ["0005", "0006"]
expects:
  # Corrected 2026-08-25 from 6 paths to 14, checked against the code rather than predicted, then
  # to 19 once `design` settled the conditional five below. `claimed_by:`/`claimed_at:` are read in
  # 14 places; FR8 retires them, so every reader is in scope.
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
  # Settled 2026-08-25 by `design` (Option A): these were conditional and are now in scope,
  # because every reader of `claimed_by:`/`in-progress` must consult `claims/` before FR8 retires
  # the field. `.claude/backlog/next` is forced byte-identical to its template by
  # tests/backlog-scripts-installed.test.sh AC2, so it comes with the template.
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
touches:
claimed_by:
claimed_at:
---

## Problem

Claiming a ticket is currently a read-modify-write on `QUEUE.md` — read the row as `ready`, write
it `in-progress` — which is why it needs the lock. It also writes to the file two windows edit
most, on every claim and every release.

`mkdir` is already the atomic primitive the lock itself uses. Applying it directly to the claim
removes the read-modify-write, so one of `CONCURRENCY.md`'s two lock cases disappears. It does **not**
lay groundwork for more than one person, and the original claim that it did was withdrawn on
2026-08-25: `claims/` is gitignored, so git never sees it and two clones cannot collide on it at
all. Cross-clone coordination stays out of scope (below); Jira owns assignment for team work
(0004). What the directory buys is local: claiming and releasing stop touching — and stop
committing — the one file both windows edit.

## Functional requirements


Ownership lives in `claims/<id>/`, and **nothing else records it**. The `QUEUE.md` half was settled
on 2026-08-25 — see *Notes & decisions*.

- FR1 — A claim is `claims/<id>/`, created with `mkdir`, holding a `held-by` file with the claim
  token and an ISO-8601 UTC timestamp.
- FR2 — Claiming takes no lock, **because claiming stops writing `QUEUE.md` at all**. The `mkdir`
  succeeding *is* the claim; failing means another session holds it.
- FR3 — Releasing is `rm -rf claims/<id>/`, and it is paired with no `QUEUE.md` write: neither
  claiming nor releasing touches a row. (Handing a ticket to the next stage still writes the `Next`
  cell, under the lock, as any row edit does — that is a stage transition, not a claim.)
- FR4 — `CONCURRENCY.md` is corrected in four named places. (Citations corrected 2026-08-23: 0020
  replaced the numbered rules with named ones, so "Rule 3" and "Rule 4" no longer resolve.)
  - *Lock every write to `QUEUE.md`* — **its headline is unchanged**: every write still takes the
    lock, no exemptions. What changes is that *claiming a row is no longer a write*, so it leaves
    that rule's enumeration, which then reads: claiming an ID (`queue`), closing a row (`verify`).
    Nothing is weakened; a case disappears because the operation disappears.
  - *Claim tokens* — ownership is the claim directory. The token still exists and is still minted,
    reported and remembered; its home moves from the item's frontmatter to `claims/<id>/held-by`.
  - *A claim must be durable the moment it is made* — gains the ignored-path clause (FR9).
  - *A stage writes only the ticket it holds* — *held* is defined in exactly one place, and that
    place becomes "a `claims/<id>/` directory exists, and nothing else". Its current wording ("a
    non-empty `claimed_by:` in the item, and nothing else") is what `close`'s reconcile guard
    implements, so the two move together or 0029's one-definition fix is undone.
- FR5 — A claim carries an expiry; a claim older than it is reported as stale with its timestamp,
  never silently reclaimed.
- FR6 — `.claude/backlog/claims/` is gitignored in this repo and named in the README's ignore note
  alongside `.lock/`.
- FR7 — **The two scripts that implement ownership are converted, not just the prose.**
  `skills/queue/templates/claim` creates `claims/<id>/held-by` per FR1 and FR2, and loses three
  things with it: the lock, the whole-file `QUEUE.md` rebuild, and the `status: in-progress` write
  into the item's frontmatter. `close`'s ownership test reads `claims/<id>/held-by` rather than the
  item's `claimed_by:`, releases the claim with `rm -rf`, and stops writing `claimed_by:` /
  `claimed_at:`. Without this the mechanism exists only in `CONCURRENCY.md` while both scripts still
  run the token protocol — two live protocols, which is the defect parked twice in `FINDINGS.md`
  rather than a migration.
- FR8 — **Contract phase, and it lands last.** `claimed_by:` and `claimed_at:` are retired from
  `skills/queue/templates/item.md` with the comment that documents them, and from
  `tests/graph-fields.test.sh`'s key list. A field no script reads is a field the next session fills
  in for nothing — but it must stop being read *before* it stops being written, which is FR9.
- FR9 — **Expand before contract: every reader consults `claims/` in an earlier commit than the one
  that retires the field.** `migration-conventions.md` (*Expand, Migrate, Contract — Never One
  Step*) applies here with commits in place of deploys, because both windows share one checkout and
  a commit is what they exchange. The readers are: `./next` — `show_claimed` (which builds its whole
  CLAIMED FILES block from `claimed_by:`), every `in-progress` predicate in `--drive`, `depth_stopper`,
  the rank walk and the stage lists, and the BY STATUS tally; `close`'s reconcile held-guard;
  `develop` Step 1.3 and Step 5.4; `verify`; `design` Step 4's claimed/unclaimed test. Collapsing
  FR7–FR9 into one commit is the failure this FR exists to prevent: retire the field first and the
  file-scope triage `develop` Step 1 depends on goes blind with nothing reporting it.
- FR10 — **`in-progress` is retired as an *authored* value, in both places it is authored** — the
  `Status` column and the item's `status:`. The documented set becomes `ready | waiting | blocked`,
  and `QUEUE.md`'s *Two columns* prose says held is not a column value, names `claims/` as the
  authority and `./next` as the reader. It does **not** become a cache the way `blocked` did in
  0024: a cache needs a writer, and the only two events that could write this one — claim and
  release — are exactly the two this ticket takes off the file. A cache with no writer is drift by
  construction.
- FR11 — **Compat runs in the safe direction only.** A reader treats a row still reading
  `in-progress`, in a backlog written before this change, as *held* — it withholds work rather than
  offering it — while nothing writes that value any more. Over-reporting held costs a session one
  row; under-reporting it costs two sessions one file.


## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | An existing backlog whose rows still carry an `Owner` token or an `in-progress` cell stays readable — withheld as held (FR11), never an error. | `migration-conventions.md` |
| Migration / sequencing | Expand before contract, with commits standing in for deploys: every reader consults `claims/` in an earlier commit than the one retiring `claimed_by:` (FR9 before FR8). | `migration-conventions.md` — *Expand, Migrate, Contract — Never One Step* |
| Documentation | `CONCURRENCY.md` is corrected in the same change — it is the file that will be followed, so a stale rule there is followed too. | `documentation-conventions.md` |

## Acceptance criteria


- [ ] AC1 — Given no claim on 0042, when `mkdir claims/0042` runs twice, then the first succeeds
  and the second fails non-zero.
- [ ] AC2 — Given `CONCURRENCY.md`, when *Lock every write to `QUEUE.md`* is read, then its
  enumeration names claiming an ID and closing a row, and does **not** name claiming a row.
  (Restated 2026-08-25 from cardinality to membership: 0023 added a third lock case — closing a row
  — after this AC was written, so "exactly one operation" would now force the lock off `./close`
  and automate away the atomicity 0023 and 0024 exist to provide.)
- [ ] AC3 — Given `CONCURRENCY.md`, when *Claim tokens* and *A stage writes only the ticket it
  holds* are read, then ownership and *held* are both defined by the claim directory, and neither
  the `Status` column nor `claimed_by:` is referenced as authoritative.
- [ ] AC4 — Given the repo `.gitignore`, when it is read, then `claims/` is present. (Already true
  at capture — verified 2026-08-25; this AC guards it rather than adding it.)
- [ ] AC5 — Given a fixture backlog with a claim held as `claims/0042/held-by`, when `close 0042
  <wrong-token>` runs, then it exits non-zero naming the holding token, and when it runs with the
  token from `held-by`, then it closes and the claim directory is gone.
- [ ] AC6 — Given `skills/queue/templates/claim`, `close` and `item.md`, when each is searched for
  `claimed_by`, then there are no matches.
- [ ] AC7 — Given a fixture backlog, when `./claim 0042` runs, then `QUEUE.md` is byte-identical
  before and after, and no commit is made against it.
- [ ] AC8 — Given a fixture backlog whose `.lock/` is held by another session, when `./claim 0042`
  runs, then it succeeds — claiming no longer waits on the lock.
- [ ] AC9 — Given a fixture backlog where `claims/0042/` exists and 0042's row reads `ready`, when
  `./next develop` runs, then 0042 is not offered, and when `./next` runs, then 0042 appears under
  CLAIMED FILES with the token from `held-by`.
- [ ] AC10 — Given a fixture backlog whose 0042 row still reads `in-progress` and which has no
  `claims/` directory at all, when `./next develop` runs, then 0042 is not offered and nothing
  errors.
- [ ] AC11 — Given this ticket's commits, when `git log -p` is read, then the commit converting the
  readers (FR9) precedes the commit retiring `claimed_by:` (FR8), and at no commit does `./next`
  read a field `item.md` no longer defines.


## QA plan


- **Level:** verify — shell mechanics and prose, no test runner in this project.
- **Why this level:** AC1 is a two-line shell assertion; AC5, AC7–AC10 need a throwaway fixture
  backlog driven through the real scripts, because an ownership test is only proved by a wrong token
  being refused and a derived `held` is only proved by a row that reads `ready` and is not offered;
  the rest are greps and one `git log` read.
- **Specific checks:**
  - `mkdir /tmp/c/0042 && ! mkdir /tmp/c/0042` in a scratch dir
  - `grep -A6 'Lock every write' references/CONCURRENCY.md` names claiming an ID and closing a row,
    and not claiming a row
  - `grep 'claims/' .gitignore`
  - a scratch backlog: `claim 0042`, then `close 0042 wrong` (expect non-zero, holder named), then
    `close 0042 "$(head -1 claims/0042/held-by)"` (expect success, `claims/0042/` gone)
  - the same scratch backlog: `git diff --quiet -- QUEUE.md` after `claim 0042`; `mkdir .lock` then
    `claim 0043` (expect success)
  - the same scratch backlog with `claims/0042/` present and the row `ready`: `./next develop` omits
    0042; `./next` lists it under CLAIMED FILES
  - a legacy fixture: row `in-progress`, no `claims/` — `./next develop` omits it, exit 0
  - `! grep -rq claimed_by skills/queue/templates/` for AC6
  - `git log --oneline -p -- skills/queue/templates/item.md skills/queue/templates/next` for AC11


## Out of scope

Anything about multiple people beyond this mechanism — no reservation batches, no ID blocks, no
cross-clone coordination. Jira owns assignment for team work (0004).

## Notes & decisions

- 2026-08-25 — **DECISION: Option A. Claiming stops writing `QUEUE.md`; *held* is derived from
  `claims/<id>/`.** Settled by `design` against an unclaimed ticket, so it is written here rather
  than handed back. What it rejected, and why:
  - **Option B (keep the lock for the `Status` cell)** — smallest blast radius, but it delivers none
    of the benefit. The benefit is not the lock, which is a `mkdir` and a `trap` held for two
    seconds; it is that claim and release stop *committing* the one file both windows edit, which is
    how `./claim`'s commit carried two foreign pending claims (`CONCURRENCY-INCIDENTS.md`, *The
    uncommitted claim*). Keeping the cell write keeps the whole-file rebuild, the lock and the
    commit — FR2 would simply be false, and AC2 unsatisfiable as written.
  - **Option C (author the item's `status:` only, derive the column)** — leaves two committed
    answers to one question plus one ignored one. That is the exact shape
    `CONCURRENCY-INCIDENTS.md` records under *The rule that was deleted, not narrowed*: a second
    definition of *held* lost on **one definition beating two**, after the documented fallback and
    the script disagreed about the same dependent. 0024 rejected it for `blocked` on the same
    ground.
  - **What made A affordable** was reading the code rather than the estimate. The reader changes are
    a substitution, not a rewrite: one helper (`is_held() { [ -d "$DIR/claims/$1" ]; }`) and about
    eight call sites in `./next`, while `./claim` gets *shorter* — it loses the lock, the awk
    rebuild and the commit. `./next`'s reader changes are 0006's file but not 0006's session: 0006
    is `blocked_by: 0007`, so they are sequential and there is no collision, only the rework of
    0006 rewriting lines this ticket touched. **The chain does not reorder.**
  - **The trade-off accepted, stated rather than discovered later:** `QUEUE.md` no longer tells a
    human what is held — a held row reads `ready` to anyone who opens the file instead of running
    `./next`. Accepted because the alternative is a cache no event writes (FR10), and because the
    readers that matter already route through `./next`, whose CLAIMED FILES block gets *more*
    reliable, not less: it stops depending on a column being right. Second, smaller cost: claims
    leave no git history. The `Claim <id> [<token>]` commits disappear; the token still appears in
    `Close <id> [<token>]`, and a claim that never closes leaves no trace once released.
  - **What it depends on:** that both windows share one checkout. Verified as this repo's stated
    model, and it is what makes an ignored claim visible. Two clones would invalidate the answer —
    ignored claims are invisible across them — and the answer would become "`claims/` is tracked",
    which reopens durability from the other side. That case is already *Out of scope*.

- 2026-08-25 — **Second question settled: a gitignored claim is durable, and the rule says why.**
  *A claim must be durable the moment it is made* defines durable as "visible to the other session
  with no further act by you", then adds "local file → only once committed". That second clause is
  not a definition, it is a consequence of one failure mode: an uncommitted edit to a **tracked**
  file is swept by the next session's pathspec commit. An ignored path has no such failure — no
  commit can carry off a path git never sees — and in a shared checkout it is visible the instant
  `mkdir` returns. So the rule gains a clause rather than an exception, with its boundary stated:
  **a claim is checkout-local and does not survive the checkout**, which is correct, because a claim
  is a live session's hold and not a fact about the ticket. The rule's closing line — "*A directory
  is not a file:* git records no empty directory" — stays true of tracked paths and must be reworded
  so it is not read as an objection to FR1; it is also why FR1 puts `held-by` inside the directory.

- 2026-08-25 — **`in-progress` is authored in two places, not one, and the design question named
  only one.** `./claim` writes the `Status` cell *and* `status: in-progress` into the item's
  frontmatter. Retiring the column value while leaving the frontmatter one is Option C by accident,
  so FR10 retires both. Checked: nothing reads the item's `status:` for `in-progress` — `./next`
  reads it only for `done`, `close`'s reconcile only for `blocked` — so removing it costs no reader.


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

- 2026-08-25 — **`size` raised `m` → `l` by `design`.** Not because Option A is harder than it
  looked — the reader change is a substitution — but because settling the question added FR9's
  two-commit sequence and five fixture-driven ACs (AC7–AC11) to a ticket that already carried two
  script conversions and four prose corrections. Rank is untouched; `size` feeds tie-breaker 4 only.
