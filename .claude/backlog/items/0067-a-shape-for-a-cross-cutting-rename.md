---
id: "0067"
title: Decide what shape a cross-cutting rename takes in the backlog
type: chore
next: develop
status: in-progress
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0001", "0005", "0045", "0049", "0050"]
expects:
  - references/CONCURRENCY.md  # also transiently mutated to prove the prose guards red
  - references/CONCURRENCY-INCIDENTS.md  # also transiently mutated to prove the prose guards red
  - .claude/backlog/next
  - .claude/backlog/claim
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - tests/next.test.sh
  - tests/claim.test.sh
  - tests/cross-cutting-change.test.sh  # new file, created by this ticket
claimed_by: "f582"
claimed_at: 2026-09-10T19:02:21Z
touches:
  - references/CONCURRENCY.md  # also transiently mutated to prove the prose guards red
  - references/CONCURRENCY-INCIDENTS.md  # also transiently mutated to prove the prose guards red
  - .claude/backlog/next
  - .claude/backlog/claim
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - tests/next.test.sh
  - tests/claim.test.sh
  - tests/cross-cutting-change.test.sh  # new file, created by this ticket
---

## Problem

A vocabulary rename has no shape the backlog can hold. Renaming the container ticket type
effort → project (`267d13f`, 2026-08-23) touched **30 files** across `QUEUE.md`, `RANKING.md`,
`SCHEDULED.md`, the item template, two skills, three test suites and **20 item files**. No
`touches:` list can usefully declare that, no single ticket owns it, and `claim` protects one row
at a time — so a cross-cutting rename is **invisible to every concurrency mechanism the repo has**.
That is how it reddened `0005`'s held guard mid-pass: the rename rewrote a file 0005 had committed
in `touches:`, turning a held ticket's own guard red against a contract the ticket never agreed to.

The same event produced the audit-trail defect recorded separately: the rename's commits were
tagged with another ticket's live claim token, and swept 41 lines of that ticket's uncommitted notes
into their own message.

This is not the ordinary file-scope collision. A collision is two tickets wanting one file; a rename
is one change wanting *every* file, including files belonging to tickets that are closed and to
tickets that are held. The mechanisms this repo has — `expects:`, `touches:`, the lock, the claim
token — are all per-row, and a rename has no row.

## Functional requirements

- FR1 — `references/CONCURRENCY.md` states that a change touching every file is outside what
  `expects:`, `touches:` and the per-row lock can express, since today the mechanisms read as though
  they cover everything.
- FR2 — The rule names what a session does when it *discovers* a cross-cutting change is underway —
  the case 0005 was in, where a held ticket's guard reddened for a reason nothing in its own scope
  explained. Two halves: it claims nothing while the exclusive claim stands, and a red it cannot
  explain from its own scope is **not evidence about its own ticket** — it holds its verdict rather
  than releasing an advisory pass, because the exclusive claim is bounded and an advisory release
  buys a re-verification later.
- FR3 — The rule states that a rename **does not rewrite closed tickets' files**. It rewrites the
  product — the files a guard reads and a future session acts on — and the *live* backlog surfaces:
  `QUEUE.md`, `RANKING.md`, `SCHEDULED.md`, and the item files of tickets that are open and unheld.
  A closed ticket's item file is the record of what was built and verified and stands as written.
  The rename instead records the substitution **once, dated**, where the vocabulary is defined, so a
  reader meeting the retired word in an old ticket can resolve it.
- FR4 — `references/CONCURRENCY.md` defines the **exclusive claim**: a cross-cutting change is an
  ordinary ticket, claimed the ordinary way, whose `touches:` is `"*"`. Three preconditions, stated
  as such: nothing else is held when it is claimed; the change lands in **one commit**; the suite is
  green before it and green after it, never between.
- FR5 — `./next` treats a held row whose `touches:` contains `"*"` as colliding with **every**
  candidate row at every stage, reported through the existing COLLIDES line so the holder and its
  token are named. Both copies of the script, per
  `tests/backlog-scripts-installed.test.sh`'s byte-identity requirement.
- FR6 — `./claim` refuses a ticket whose `expects:` contains `"*"` while any other ticket is held,
  naming the holders — the precondition in FR4 enforced rather than remembered. Both copies.
- FR7 — `references/CONCURRENCY-INCIDENTS.md` carries the narrative under the rule's name: the
  2026-08-23 rename with its verified figures, what reddened 0005, and the shapes that were
  rejected and why.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | Settled by FR3 and stated in the rule: **forward-only**, never a rewrite of the record. Expand/contract does *not* govern here — its "dual-write both shapes" step has no prose analogue but two live names for one concept, which is the defect the rename exists to remove | `migration-conventions.md` |
| Documentation | The rule lands in the concurrency reference and the narrative in `CONCURRENCY-INCIDENTS.md`, per the split 0020 made. The rejected shapes are recorded, not only the chosen one | `documentation-conventions.md` |
| Context rent | `CONCURRENCY.md` is in the always-read set. The new section is one rule with its preconditions; the incident, the figures and the rejected shapes go to `CONCURRENCY-INCIDENTS.md` | `CONVENTIONS_CORE.md`, *Every rule pays rent in context* |

## Acceptance criteria

Every prose assertion is scoped to its section and matches a phrase short enough to sit on one
source line — `grep` is line-based here, and an asserted phrase straddling a line break cannot match.

- [ ] AC1 — Given `references/CONCURRENCY.md`, when `tests/cross-cutting-change.test.sh` reads the
  section defining the exclusive claim, then it finds a line stating that a change touching every
  file is not expressible in `expects:`, `touches:` or the per-row lock.
- [ ] AC2 — Given the same section, when read by that test, then it states both halves of FR2: that
  a session claims nothing while an exclusive claim stands, and that an unexplained red is not
  evidence about the session's own ticket.
- [ ] AC3 — Given the same section, when read by that test, then it states that closed tickets'
  files are not rewritten, and that the substitution is recorded once with a date.
- [ ] AC4 — Given the same section, when read by that test, then all three preconditions of FR4 are
  present: nothing else held, one commit, green before and after.
- [ ] AC5 — Given a fixture backlog where ticket A is held with `touches: ["*"]` and ticket B is a
  `ready` `develop` row whose `expects:` shares no path with A, when `./next develop` runs, then B
  is reported COLLIDES naming A and its token, and no row is offered. Asserted in
  `tests/next.test.sh`.
- [ ] AC6 — Given the same fixture with A *not* held, when `./next develop` runs, then B is
  offered — the `"*"` entry collides only from a held row, so a stale `touches:` cannot freeze the
  stage. Asserted in `tests/next.test.sh`.
- [ ] AC7 — Given a fixture where ticket X `expects: ["*"]` and any other ticket is held, when
  `./claim X` runs, then it refuses, names the holders, and writes neither `QUEUE.md` nor the item.
  Given nothing else held, then it claims normally. Asserted in `tests/claim.test.sh`.
- [ ] AC8 — Given `references/CONCURRENCY-INCIDENTS.md`, when `tests/cross-cutting-change.test.sh`
  reads it, then an entry names the exclusive-claim rule in its heading and carries the 2026-08-23
  rename's figures.
- [ ] AC9 — Given `tests/backlog-scripts-installed.test.sh`, when the suite runs, then both copies
  of `next` and both copies of `claim` are byte-identical — FR5 and FR6 land in the template and the
  installed copy together.

## QA plan

- **Level:** unit — `tests/*.test.sh` is the whole runner here, and it covers both halves: the
  prose greps in a new `tests/cross-cutting-change.test.sh`, and the script behaviour in
  `tests/next.test.sh` and `tests/claim.test.sh` against fixtures.
- **Why this level:** confirmed rather than provisional now the shape is settled — the answer has a
  script half, and a script half is `unit`.
- **Specific checks:** each prose assertion must be proved by mutation to fail when the sentence is
  moved out of its section, per `testing-conventions.md` on guards that cannot fail. AC5 and AC6 are
  a pair on purpose: the second is what proves the first is testing *heldness* and not the literal
  string.

## Out of scope

- **The token reuse and the swept notes from the same incident.** That is 0049; the two findings
  came from one event and have different root causes.
- **Ordinary file-scope collisions**, which are 0050. This ticket does not depend on 0050's outcome
  and 0050 does not depend on this one — see *Notes & decisions*.
- Performing any rename.
- Any retitling or renumbering of this ticket. The title still reads as a question because it is the
  citation anchor other items and `RANKING.md` use.

## Notes & decisions

- **2026-09-10 — Design pass, `/design`. The shape is an ordinary ticket with an exclusive claim.**
  A repo-wide vocabulary change is *not* new machinery. It is a normal row, claimed with a normal
  token, whose `touches:` is `"*"`, taken only when nothing else is held, landed in one commit. Every
  mechanism the repo already has then works on it unchanged: the claim is durable and committed,
  `./next` shows it held, the token tags the commits, and a session arriving mid-change sees a held
  row rather than an unexplained red. The ticket's premise — "a rename has no row" — is the thing to
  reject, not to design around.

- **The prior question is answered first because it shrinks the problem: a rename does not touch
  closed tickets.** Three reasons, all verified 2026-09-10 against `267d13f`:
  1. **No guard reads a real item file.** Every prose guard targets `skills/**`, `references/**`,
     `README.md` or its own fixtures — `tests/graph-fields.test.sh`, the guard that reddened, reads
     `skills/queue/templates/item.md`. Rewriting closed items buys zero greenness.
  2. **A closed item is the record of what was observed.** The rename rewrote 0024's
     "four of effort 0009's tasks sat at `status: blocked`" into "project 0009" — a statement about
     what a session saw on 2026-08-23, when the word was *effort*. Forward-only applies to a record
     as much as to a database.
  3. **It is a third of the blast radius.** Of the 20 item files touched, **9 belonged to tickets
     that were already `done`** (19 tickets were in `DONE.md` at `267d13f^`). Excluding them removes
     the entire "does this invalidate a verdict" question along with the files.
  **The cost accepted:** closed tickets keep the retired word, so a `grep` for the new term misses
  the history and a reader of an old ticket meets a dead term. Bought back with one dated line where
  the vocabulary is defined, which is cheaper than a rewrite and truer than one.

- **The ticket's own figures were wrong, and re-verifying them changed the answer.** It read
  "27 files … 21 closed tickets"; the commit is 30 files, 20 item files, 9 of them closed. The
  21-of-27 figure makes closed tickets look like the bulk of the work, which argues for a project
  with slices; 9-of-20, all of them excludable, argues for one commit. The Problem section above is
  corrected. This is `develop` Step 2's rule — a figure a ticket quotes about a file it does not own
  is a cache, not a fact — reaching a design pass.

- **What the incident actually was, which is narrower than "a rename collided".** Two distinct
  defects, and only the first is this ticket's:
  - The rename was **not atomic across a guard and the file it guards**:
    `tests/graph-fields.test.sh` asserted the new wording while `skills/queue/templates/item.md`
    still carried the old. 0005 held the test file in `touches:` and read a red it had not caused.
    One commit fixes this by construction — there is no observable half state in history, and the
    exclusive claim covers the window in the working tree.
  - The rename **edited a held ticket's requirements** — 0005's FR2 and FR5 were rewritten while
    0005 was at `verify`. That needs no new rule: *A stage writes only the ticket it holds* already
    forbids it. What the rule gains is an explicit statement that a cross-cutting change is not
    exempt from it, which is precisely what the session performing one will assume.

- **Rejected — a scheduling rule alone ("vocabulary changes only when nothing is claimed").** It is
  kept, as FR4's first precondition, and it is not a shape on its own: it says nothing about
  atomicity, nothing about closed tickets, and nothing about the session that *starts* during the
  change. It would win if sessions never started mid-rename. They do.

- **Rejected — a project with a slice per affected area.** It would win if a vocabulary change could
  not land in one commit — one spanning repositories, say. Two reasons it loses here. Slices that
  each touch everything collide with **each other**, so the machinery reintroduces the problem
  inside the project. And a project holds one outcome carried by children with distinct outcomes,
  whereas a rename's outcome is only true when the last file changes — a half-landed rename is the
  failure, not a milestone. **The escape hatch, stated so the option is not re-derived:** a
  vocabulary change that genuinely cannot be one commit is not a rename, it is a redesign, and then
  it is a project and its first slice introduces the new term as an addition.

- **Rejected — expand/contract (add the new term, dual-write, remove the old).**
  `migration-conventions.md` says "renaming is add + backfill + dual-write + remove, not a rename",
  and that governs *schema under running code*, where both shapes must be live because both old and
  new code are. Prose has no old code still running. Its dual-write step is two names for one
  concept, which is the exact defect 0005's own notes record having to fix — "leaving 'container' in
  place would have left one file naming the same concept two ways" — and the guards assert the
  *absence* of retired wording, so the contract phase is the only phase that turns them green.
  Forward-only survives from that file, and is what FR3 rests on.

- **Not coupled to 0050.** 0050 settles ordinary section-level file scope in a multi-writer repo;
  this settles the case where scope is *everything*. The exclusive claim is compatible with all four
  of 0050's candidate shapes — including worktrees, where the rename is the one change that lands on
  the shared checkout. Neither blocks the other, which is why `blocked_by:` stays empty.

- **`touches: "*"` rather than a new field.** `touches:` already means "the files this claim holds",
  and "all of them" is a value it can carry. Verified 2026-09-10 that this is a real code change and
  not already true: `paths_shared` in `.claude/backlog/next:415` matches path words exactly, so a
  `"*"` entry collides with nothing today.

- **A split line, if a `develop` session wants one.** FR5 (`./next` reports it) is separable from
  FR6 (`./claim` enforces it) and each is independently useful; FR1–FR4 and FR7 are the prose and
  land together. Size raised `m` → `l` for the two script changes across four files.

- Routed to `design` on trigger 1: three candidate shapes with incompatible criteria, plus a prior
  question — whether closed tickets are rewritten — that has to be answered before any of them can
  be specified.
- Ranked in Tier 2 rather than Tier 5 despite no rename being planned. The mechanisms read as
  complete, which is what makes the gap dangerous: the next cross-cutting change will be started by
  a session that has checked `expects:` against `touches:` and concluded it is safe.

- **2026-09-10 — Built, `/develop` [f582].** All seven FRs landed as specified; the design pass's
  shape needed no revision. Prose in `CONCURRENCY.md` (34 lines) and `CONCURRENCY-INCIDENTS.md`
  (45), the two script changes in both copies, and 21 new prose cases plus 8 script cases.

- **Both YAML forms of the marker parse to a bare `*`, which the ticket did not settle.** `touches:
  ["*"]` (inline) and `- "*"` (block) reach `fm_list` by different branches — the inline one strips
  quotes with `gsub(/[][",]/, " ")`, the block one through `decomment`, which also strips a leading
  and trailing quote. Both yield `*`, so `contains_word '*'` catches either. Asserted for both forms
  rather than assumed, because they are genuinely different code paths. A **bare** `- *` is invalid
  YAML — `*` is the alias indicator — so the quoted form is the one to write.

- **`claim` reads `expects:`, `next` reads `touches:`, and that asymmetry is deliberate.** At the
  point `claim` must refuse, it has not yet seeded `touches:` from `expects:`, so `touches:` still
  holds whatever the ticket was authored with. `next` asks the opposite question — what a session
  has actually claimed against the code — and `touches:` is that field. Each reads the only field
  that can answer its own question.

- **A guard's independence has to be proved per clause, and two of them shared a source line.** The
  AC9 deletion probes red not only when a phrase survives its own deletion but when deleting it
  removes a *second* asserted phrase — which caught `one commit` and `green before it and green
  after it` sitting on one line of `CONCURRENCY.md`, where a single `grep -v` took both. Split onto
  separate lines. This is the line-based-`grep` hazard `CLAUDE.md` names, arriving from the guard
  side rather than from a rewrap.

- **AC6 was green before the implementation and is the case that matters most.** It asserts that a
  stale `"*"` on an *unheld* row collides with nothing, and it passed both before and after — so it
  was mutation-proved rather than trusted: hoisting the `*` test above `held_by` in the copy the
  harness runs turns it red, naming `[MUTANT]` as the holder. Without that proof, AC6 is a guard
  never seen failing. The mutation was made to `skills/queue/templates/next` in place and restored
  in the same turn, because relocating the *test* breaks its `ROOT` derivation — parked as a finding.

- **Adjacent and NOT fixed here: `gate_from` composes a batch from takeable rows' `expects:` via
  `paths_overlap`, which has no `"*"` case.** A takeable (unheld) exclusive-claim row would therefore
  sweep every pairwise-reachable row into one gate. It is not reachable through this ticket's FRs —
  FR5 and FR6 both key on a *held* row — and narrowing or widening a contract is not this stage's
  call, so it needs its own row rather than a silent fix here (pointer: `.claude/backlog/next`
  `gate_from`, `paths_overlap`).

- **The QA plan's "prove by mutation that a sentence moved out of its section fails" is built in
  rather than left to the QA pass.** `tests/cross-cutting-change.test.sh` carries the out-of-section
  fixture and the empty-section case as ordinary cases, so the scoping claim reds in the suite rather
  than depending on a session remembering to check it.
