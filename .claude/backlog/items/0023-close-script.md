---
id: "0023"
title: Add a close script mirroring claim
type: chore
next: verify
status: done
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0002"
blocked_by: []
relates: ["0022"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/claim
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
closed: 2026-08-23
---

## Problem

Closing a ticket is a five-step sequence under the lock — tick the ACs, set `status: done`, delete the
row, append to `DONE.md`, commit, release — and it is done by hand every time. `claim` exists as a script
for exactly this shape of work, and `CONCURRENCY.md` states why: *"the commit is exactly the thing a
session under load forgets, and a script cannot forget."* The close has the same failure mode and no
script.

Measured on 2026-08-23: one session closed eleven tickets, and each close cost roughly four tool calls of
pure mechanism with no information content — about 44 calls across the session. That is the cost. The
*risk* is worse and is the reason this is not merely ergonomics: a hand-close that edits `QUEUE.md` and
`DONE.md` but does not commit inside the lock leaves both files dirty in one working tree, so the next
window to commit either carries the close off under its own message — the identical failure that made
`claim` a script.

The asymmetry is also a readability problem: a reader of `CONCURRENCY.md`'s *The two scripts* sees the
open side automated and is left to infer that the close side is hand-work by choice rather than omission.

## Functional requirements

- FR1 — `templates/close <id>` performs the whole close as one step: lock, re-read the row, tick the ACs
  in the item file, set `status: done` with the date, clear `claimed_by:`/`claimed_at:`/`touches:`, delete
  the row from `QUEUE.md`, append it to `DONE.md` newest-first, **commit by pathspec, then release**.
- FR2 — It refuses rather than guessing, on the same three grounds `claim` refuses: a table shape it
  cannot parse, a row whose `next` is not `verify`, and a row whose `claimed_by:` token was not passed to
  it. The third is the ownership test — a close is only yours if you hold the claim.
- FR3 — A `trap` releases the lock on every failure path, and the commit is retried briefly if
  `.git/index.lock` is held, matching `claim`'s behaviour exactly. Never remove another process's git lock.
- FR4 — It writes the `DONE.md` row from the `QUEUE.md` row plus the item's frontmatter, so the two files
  cannot disagree about a ticket's title.
- FR5 — `verify`'s Step 5 names it as the supported path, the way `develop`'s Step 1 names `claim`, and
  hand-closing under the lock remains documented as the fallback.
- FR6 — `CONCURRENCY.md`'s *The two scripts* becomes three, without growing past 1,500 tokens — the
  ceiling 0020 set. Trade the words for it in that section rather than anywhere else.
- FR7 — The close also **reconciles every row that named this ticket in `blocked_by`**, in the closing
  commit, setting each row whose remaining blockers are all `done` to `ready` (or `waiting` where its
  `## Waiting on` section says a person is needed) — and never a row another session holds
  `in-progress`, which it reports instead. *Added at develop time:* 0024 landed after this ticket was
  written and made the reconcile part of `verify` Step 5, which FR1 says the script encodes. A close
  script that skipped it would make 0024's stale-cache defect systematic rather than occasional.
  *Sharpened after the first verify pass:* a dependent is selected on its own `status:` reading
  `blocked`, never on `blocked_by` alone, and *held* is a non-empty `claimed_by:` in the item — not
  an `in-progress` row, which a dependent need not have.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule each script encodes is stated once, in `CONCURRENCY.md`, and cited by the skills — not restated in three places. | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a fixture backlog with a `next: verify` row claimed by token `ab12`, when
      `./close 0001 ab12` runs, then the row is absent from `QUEUE.md`, present in `DONE.md`, the item's
      `status` reads `done`, and `git log -1 --name-only` shows exactly those three paths.
- [x] AC2 — Given the same fixture, when `./close 0001 ab12` runs, then `.lock/` does not exist
      afterwards and the commit precedes its removal (asserted by the commit existing while the working
      tree is clean).
- [x] AC3 — Given a row whose `next` is `develop`, when `./close` is called on it, then it refuses,
      names what it found, exits non-zero, and leaves both files unchanged.
- [x] AC4 — Given a row claimed by a different token, when `./close <id> <wrong-token>` runs, then it
      refuses, exits non-zero, and leaves both files unchanged.
- [x] AC5 — Given a `QUEUE.md` whose header is not `ID/Title/Next/Status/Parent`, when `./close` runs,
      then it errors on the shape rather than editing anything.
- [x] AC6 — Given a forced failure between the row edit and the commit, when the script exits, then
      `.lock/` has been removed by the `trap`.
- [x] AC7 — Given `references/CONCURRENCY.md`, when its size is measured, then it is still under 1,500
      tokens.
- [x] AC8 — Given a fixture where one row is blocked only by the ticket being closed and another is
      blocked by it *plus* a ticket that is still open, when the close runs, then the first row and its
      item read `ready`, the second read `blocked` untouched, the freed ID is named in the output, and
      both changes land in the close commit rather than a follow-up.
- [x] AC9 — Given a dependent whose item `status:` is `done` and whose `blocked_by` still names the
      ticket being closed, and which has no `QUEUE.md` row, when the close runs, then its item still
      reads `status: done`, it is not named in the reconcile report, and its path is not in the close
      commit.
- [x] AC10 — Given a rowless dependent held by another session — a non-empty `claimed_by:` — when the
      close runs, then its `status:` and `claimed_by:` are unchanged, it is named in the "left alone"
      report rather than silently skipped, and its path is not in the close commit.

## QA plan

- **Level:** verify — a shell script with no test runner.
- **Scripted assertion:** a fixture backlog in a temp directory with its own `git init`, driven by a
  shell script asserting on `QUEUE.md`, `DONE.md`, the item frontmatter, `git log --name-only`, the
  existence of `.lock/`, and the exit code. AC3–AC6 pin exit codes and file-unchanged separately from
  output, because "printed a refusal" and "changed nothing" are different claims and only the second one
  protects the queue. AC6 is driven by a deliberately failing `git` — point `GIT_DIR` at a
  non-repository — rather than by editing the script.

## Out of scope

- `claim`'s column-index defect — 0022 owns it. This script must parse by the same mechanism `claim` uses
  once 0022 lands, so **sequence them**: build on 0022's parser rather than writing a third one.
- Any change to *what* closing means. FR1 encodes the sequence `verify` Step 5 already specifies.

## Notes & decisions

- **FR2's third refusal is the one worth arguing about.** `claim` mints the token; `close` has to be
  *given* it, because there is no ambient session id and `CONCURRENCY.md`'s ownership test is memory
  ("yours only if you minted its token in this conversation"). A script cannot check memory, so the token
  argument is how the session proves it. Passing the wrong one must fail loudly rather than close someone
  else's ticket.
- Parented under 0002 rather than 0009: it is scaffold tooling, which is that effort's subject. 0009 is
  finished bar 0021.

### Learned while building (2026-08-23)

- **A mutation that silently fails to apply is indistinguishable from a guard that holds.** Six
  mutations were run to prove the new guards could fail. Two came back green — and one of those,
  unscoping the AC ticking, had simply not applied: the `perl` pattern never matched, so the "green"
  was a report about an unmodified file. `diff` the mutated file before believing its result. Applied
  properly it went red immediately. This is the mutation-testing analogue of the conventions'
  *"a guard only ever seen passing is indistinguishable from one wired to nothing"* — the mutation
  needs the same scepticism as the test. A related trap in the same pass: `perl -pe` interpolated
  `$bfile` out of a shell line, producing a syntactically broken mutation whose red proved only that
  the assertions touch that *line*, not that they test its *semantics*. Use a non-interpolating
  editor for shell mutations.
- **The other genuinely-green mutation was not a hole.** Removing the fatal "not a git repository"
  check left the retry loop to fail instead, whose message also contains "uncommitted" — so AC6's
  assertion passed on a different, and misleading, path: it would have reported "git busy" about a
  repository that does not exist. Both behaviours are honest about the *lock*; only one is honest
  about the *reason*. AC6 now pins the reason.
- **FR3 says "matching `claim`'s behaviour exactly", and `close` deliberately diverges in one place.**
  `claim` wraps its commit in `if git rev-parse …`, so outside a repository it silently skips
  committing and exits 0. For `close` that is the failure the script exists to prevent, so an
  uncommittable repository is fatal and says the files are edited but uncommitted. Worth flagging:
  by the same argument `claim`'s tolerant skip is probably a latent bug, but it is 0022's file and
  not this ticket's to change.
- **AC5 is satisfied by requiring the columns the script needs, not by pinning the five-column
  shape.** A literal `ID/Title/Next/Status/Parent` check would reject the pre-0010 eight-column table
  that `claim` still deliberately claims (its own AC3), so the script resolves `ID`, `Title`, `Next`
  and `Status` by name and errors naming whichever is missing. Any header lacking one of those errors,
  which is what AC5 asks for; a reordered header with all four works, which no AC pins and the suite
  now does.
- **"Build on 0022's parser rather than writing a third one" means the same mechanism, not shared
  code.** `next`, `claim` and `close` are copied independently into a project's `.claude/backlog/`, so
  a shared library would break the template model — there is nowhere for it to live that all three
  can reach. `close` reimplements by-name resolution as `header_of` / `column_in`. DRY's trigger is
  the *third* repetition and this is the second, so the duplication is correct for now; the third
  script to need it is the signal to find it a home.
- **`close` refuses when `DONE.md` is absent rather than creating it.** Creating a file the project
  never scaffolded would hide a scaffolding gap behind a working close, and the script's whole
  character is refusing rather than guessing.

### FR6: the ceiling was already breached before this ticket

`references/CONCURRENCY.md` measured **6,610 bytes / ~1,637 tokens** at HEAD, against the 1,500-token
ceiling 0020 set — it had grown from 6,017 / ~1,490 via 0024's additions and the retro's edit. So AC7
was failing before this ticket touched the file, and FR6's instruction to *"trade the words for it in
that section rather than anywhere else"* could not be followed: *The two scripts* is ~370 bytes and
naming a third script grows it. **Measure in bytes at the 4.038 bytes/token ratio the ticket lineage
established** — Python's `len()` on the decoded text undercounts by ~46 here, because the file is full
of multi-byte em-dashes.

The trade came instead from prose the file's own split assigns elsewhere. Nothing that is a *rule* was
cut. Precisely:

- Two histories **`CONCURRENCY-INCIDENTS.md` already carries in full** — *"Replaces `verify` never
  writes the queue…"* (its §*The rule that was deleted, not narrowed*) and *"Closing was once exempt —
  true of the row, false of the file…"* (its §*The rule that was narrowed and widened back*). Pure
  deduplication, which is what this ticket's NFR asks for.
- Justifications restating the rule in the sentence they follow: *"a suite over a file set that never
  existed means nothing either way"*, *"and this is the part that surprises people"*, *"and since
  when"*, *"count rows to learn a rank"*, *"staged work is exposed until it lands"*.
- Two headings shortened to **the exact stems they are already cited by** — *The working tree is
  shared too*, *Claim tokens* — which 0020's own notes say is how rules are cited. This makes the
  citations in `CONCURRENCY-INCIDENTS.md` and `develop` SKILL.md exact rather than approximate.
- One clause that is arguably a rule and was dropped: *"and `./next --drift` will show its own
  session"*, from the reconcile bullet. `verify` Step 5 states the whole drift procedure, so it is
  said once rather than twice.

Result: **6,610 → 6,030 bytes, ~1,637 → ~1,493 tokens.** The margin is 7 tokens, so the next edit to
this file breaches it again. That is a standing cost of the ceiling, not a defect in this change.

- **Renaming the rule broke two live citations**, in `CONCURRENCY-INCIDENTS.md` §*A backlog with no
  scripts* and §*The parser that reported an empty backlog*. Rules are cited by name, so a rename is
  never a one-file edit — hence `references/CONCURRENCY-INCIDENTS.md` was added to `touches:` mid-work.
- **`README.md`'s *"Only two operations take a lock"* was already false** before this change — closing
  a row has taken the lock since the exemption was removed. Corrected to three with the reason, per
  the documentation conventions' rule that a change contradicting a documented statement fixes it in
  the same commit.

### Verify pass 2026-08-23 — FAIL (token `fd27`)

AC1–AC8 all pass, and each was mutation-checked rather than taken on trust: eleven mutations of
`close`, every one diff-verified as applied (the trap this ticket's own notes set), and every one
caught by the assertion specific to it — no holes. AC7 measures 6,030 bytes / ~1,493 tokens, and is
provably falsifiable: the same measure at `3b29524` was 6,610 / ~1,637, i.e. red.

**The failure is Step 4's reachability walk, not an AC.** The reconcile FR7 added writes item files
of tickets this session does not hold, and its only ownership guard is gated behind a `QUEUE.md`
row:

```sh
dep_row="$(awk ... "$QUEUE")"
if [ -n "$dep_row" ] && [ "$(read_cell "$dep_row" "$Q_STATUS")" = "in-progress" ]; then
```

A dependent with **no row** therefore gets its `status:` rewritten unconditionally. Two reachable
states, one root cause, neither pinned by any AC:

1. **A `done` dependent is resurrected.** `close` never clears `blocked_by` on the ticket it closes,
   so a closed ticket keeps naming its blockers for ever. Closing a blocker later flips it back:

   ```
   === BEFORE: 0050 status ===    status: done
   closed 0001 — The blocker being closed
   reconciled (no longer blocked): 0050
   === AFTER: 0050 status ===     status: ready
   ```

   It stays in `DONE.md` while its item reads `ready`, so the two files disagree about whether the
   ticket is finished — the "queue that lies" failure FR7 exists to prevent, in the other direction.

2. **A dependent another session holds is overwritten — a direct FR7 violation.** FR7 says "never a
   row another session holds `in-progress`, which it reports instead". With no row, it is neither
   skipped nor reported:

   ```
   === BEFORE ===  status: in-progress   claimed_by: "ff99"
   reconciled (no longer blocked): 0060
   === AFTER  ===  status: ready         claimed_by: "ff99"
   ```

   The row is the wrong place to look: `CONCURRENCY.md` *Claim tokens* says the item's `claimed_by:`
   **is** the token's home, "the pared `QUEUE.md` has no ownership column". The guard consults the one
   place the protocol says ownership does not live.

Not triggered on this repo today — 0021 is the only row naming 0023, and its other blocker 0025 is
`ready`, so it correctly stays `blocked`. That is luck about the current graph, not a working guard.

**Suggested fix:** guard on the dependent's own frontmatter rather than its row — skip unless its
`status:` is `blocked`, and skip-and-report when `claimed_by:` is non-empty. Then add the two ACs
that pin them, since AC8's three cases are all row-bearing and cannot see this.

Everything else checked clean: FR5 (both skills name `./close`, hand-close kept as the documented
fallback), FR6/AC7, the `README.md` "three operations take a lock" correction, and the Documentation
NFR — the rule is stated once in `CONCURRENCY.md` *The three scripts* and cited by name elsewhere.
No privacy, security or accessibility surface: no log field, analytics event or egress destination is
added, and the script's only inputs are two argv values, both validated at the top.

**Note on which copy was tested:** the repo copy is the authority and is what ran. The skill executing
this session is the pinned install `0.9.1`, which predates this change and carries no `close` template
at all.

### Develop pass 2 (2026-08-23) — the FAIL fixed

- **The defect was in the rule, not only in the script.** `CONCURRENCY.md` stated the exception as
  "Reconcile no row another session holds `in-progress`", and `verify` Step 5 spelled the same
  procedure out for the hand-close. Fixing the script alone would have left the documented fallback
  instructing the next session to make both mistakes by hand, so all three changed together. This is
  the Documentation NFR working in the direction that costs something: the single statement being
  wrong is what made the implementation wrong.
- **`blocked_by` is deliberately still not cleared at close.** Clearing it would fix the resurrection
  at the cost of the graph's history of *why* a ticket was blocked, and no FR asks for that. The
  guard is what stops a historical edge being read as a live one.
- **The guards are ordered, and the order is a requirement rather than a preference.** Ownership is
  tested first so a held dependent is *reported*, which FR7 demands; the `blocked` allowlist is
  second and silent. Reversed, a held dependent at `status: in-progress` would be skipped by the
  allowlist and never reported — correct outcome, wrong reason, exactly the shape AC6's note already
  flagged in this ticket. Mutation M1 lands on precisely that: dropping the ownership guard leaves
  the file unwritten and only the *report* assertion red.
- **The allowlist is on `blocked`, not a denylist on `done`.** M4 weakened it to `!= done` and
  survived every AC — an already-`ready` dependent still naming this ticket then gets a no-op write,
  a spurious "freed" line, and an extra path in the close commit. Pinned by a fixture case rather
  than an AC.
- **Eight ACs passed over a defect because every fixture dependent had a row.** The rowless case was
  not an exotic input: a closed dependent has no row by construction, since closing deletes it. A
  guard written against one shape of input is verified only against that shape — recorded as an
  incident in `CONCURRENCY-INCIDENTS.md` rather than only here.
- **AC7's ceiling was paid, not breached.** The rule had to gain two clauses against 7 tokens of
  margin. The trade came from moving the incident to `CONCURRENCY-INCIDENTS.md`, whose stated job is
  "each rule's incident, its reasoning" — so nothing that is a rule was cut and the reasoning is not
  lost, only relocated. 6,030 → 6,050 bytes, ~1,493 → ~1,498 tokens. The margin is now ~7 bytes: the
  next edit to that file cannot be paid for this way, because the incidents are already out.
- **`touches:` was widened mid-work** to `references/CONCURRENCY-INCIDENTS.md`, for the same reason
  it was widened in pass 1: rules are cited by name, and the file that carries their reasoning moves
  with them.

### Verify pass 2 (2026-08-23) — PASS (token `b6da`)

- 62/62 assertions green in `tests/close.test.sh`, and the suite was shown to bite rather than taken
  on trust: **seven mutations of `close`, every one diff-verified as applied** before its result was
  believed (this ticket's own trap), every one red on the assertion specific to it. The four on the
  new guards: dropping the item-`claimed_by:` half leaves AC10's *report* assertion red and nothing
  else — the write is stopped by the allowlist, so the ownership guard's unique contribution is the
  report, which is why FR7 demands one; deleting the allowlist reds four including AC9 and the
  commit-paths assertion; weakening it to `!= done` reds only the already-`ready` dependent case;
  and **reversing the two guards reds AC10's report** — the order is pinned, as the develop notes
  claimed. Three more on paths pass 1 had checked (`AC3`, `AC4`, the commit) reddened 27, 25 and 6.
- **AC7 measured 6,050 bytes / ~1,498 tokens.** Falsifiable rather than merely true: the same measure
  at `3b29524` is 6,610 / ~1,637, i.e. red. Margin ~1.7 tokens.
- **The close of this ticket reconciled nothing, correctly.** 0021 is the only ticket naming 0023 in
  `blocked_by`; its other blocker 0025 reads `ready`, so it stays `blocked`. Pre-existing drift on
  0026 — `blocked` with no open blocker, left by an earlier close — was reported, not reconciled: it
  names no ticket this session held.
- Parked rather than fixed: `close` treats an `in-progress` row with no token as held, and the rule
  and hand-close fallback now define *held* as `claimed_by:` alone, so the script is stricter than
  the rule it encodes. The AC7 ceiling has no margin to state it (`FINDINGS.md`, this date).

### Superseded (2026-08-24, by 0028)

- **AC7's hard ceiling of 1,500 tokens is retired**, on Aaron's call of 2026-08-23 — see 0020's
  matching note for the reasoning. AC7 and FR6 above stand as written and stay ticked. What replaces
  the number is `tests/reference-size.test.sh`: a 6,057-byte goal (the same 1,500 tokens at 4.038
  bytes/token) that an over-goal file passes with a recorded reason.
- The parked finding in the last note — `close` stricter than the rule about what *held* means — is
  now 0029, and the ceiling that left it no margin to state is what this supersession removes.
