---
id: "0242"
title: Make every backlog write one script call, so no session takes the lock by hand
type: debt
next: develop
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-11-26
source: user
parent:
blocked_by: []
relates: ["0085", "0048", "0081", "0047", "0066", "0118", "0227"]
expects:
  - skills/queue/templates/capture
  - skills/queue/templates/park
  - skills/queue/templates/rank
  - skills/queue/templates/withdraw
  - skills/queue/templates/drain
  - skills/queue/templates/next
  - .tickets/capture
  - .tickets/park
  - .tickets/rank
  - .tickets/withdraw
  - .tickets/drain
  - tests/capture.test.sh
  - tests/park.test.sh
  - tests/rank.test.sh
  - tests/withdraw.test.sh
  - tests/drain.test.sh
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/SKILL.md
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
  - skills/sprint/SKILL.md
  - skills/prototype/SKILL.md
  - references/CONCURRENCY.md
  - CHANGELOG.md
ac_digest: AC1=3f4813fa AC2=00ed7e8d AC3=cc9098c3 AC4=c39ef3f4 AC5=cd5192a9 AC6=08ff8130 AC7=19b18cb5 AC8=6226b6e4 AC9=18fa1024 AC10=6e4e0541 AC11=4fce6a8a AC12=85333459 AC13=184dee36 AC14=e8fbc130 AC15=f8a8f901 AC16=b2de2b18 AC17=f8f530b6
claimed_by:
claimed_at:
touches:
---

## Problem

**The stage boundaries develop and verify cross are scripted, and since then their protocol cost has
roughly halved. The writes queue and retro make, and the findings park every stage makes, still
take the lock by hand.**

`0085` (closed 2026-09-03) set the rule *one command per stage boundary* and `./claim`, `./handoff`,
`./close` and `./reopen` carry it. Re-running `tools/classify-turns.sh` over this repo's store for
2026-09-04 to 2026-11-25 (68 sessions, run 2026-11-26), against the pinned August set in
`MEASUREMENT.md`:

| Stage | Mechanism share of turns, Aug | Since Sep 4 | By-hand lock, share of mechanism | Queue-file edits, share of mechanism |
|---|---|---|---|---|
| develop | 38.4% | 20.8% | 10.9% | 2.2% |
| verify | 49.5% | 27.7% | 6.5% | 4.3% |
| queue | 39.2% | **56.1%** | **21.7%** | **17.4%** |
| retro | 30.4% | **35.0%** | **28.6%** | **28.6%** |

The sample is small (4 develop, 6 verify, 3 queue, 1 retro sessions) because the store no longer
holds most driven sessions; read it as direction, not a verdict.

The write sites with no script, from the skills as at `6b7273d`:

- **queue Add.** The session mints the id from the disk, bumps `next_id`, writes the item, inserts
  the row at its rank with an `Edit`, stamps `ac_digest:` from `./next --ac-digest`, appends the
  reasoning to `RANKING.md`, commits by pathspec with `git add -N` first, and releases the lock, all
  by hand. Capturing 0240 and 0241 on 2026-11-26 took eight tool calls for this. The first attempt
  died on a script error with the lock already taken; it released only because the release was
  chained after it in the same call.
- **queue Rerank, Withdraw, Merge and Re-specify.** A row is moved by two `Edit`s, a ticket is
  withdrawn by hand (`status:`, emptied `next:`, a dated note, the row removed, every `blocked_by:`
  naming it re-pointed), and criteria are re-stamped by hand. `3b72d38` broke both withdrawal rules
  at once.
- **The findings park, in every stage and the supervisor.** Each stage's *Park what surprised you*
  step and `sprint` Step 9 take the lock, append one dated line, commit by pathspec and unlock, and
  route cross-repo by hand. Decision `001` retained this as one turn. As written it is a lock, an
  append, a commit and an unlock, and the head-token shape and the privacy bar for a public repo
  (`0118`) are checked by no one at that moment.
- **retro and queue draining `FINDINGS.md`.** Removing processed entries, marking `[->NNNN]`, and
  moving held entries to `FINDINGS-HELD.md` are all by-hand edits under a by-hand lock. `0227`
  records the header-matching hazard this creates.
- **develop Step 1's by-hand claim fallback**, kept for a backlog without `./claim`. `queue` Step 0
  now installs and byte-syncs the scripts in every backlog it opens.

`0048` asked which of these to script and was withdrawn in the 2026-10-28 triage for want of a
confirming project. The user asked for this on 2026-11-26: *"queue the work to script as much of
the backlog protocol as would still be effective so we can reduce those cost and reduce risk."*

## Functional requirements

**What stays out of the scripts, so they stay effective.** Every judgement the skills describe —
the FRs and ACs, which row a ticket beats, which findings entry is work and which is a lesson, where
a lesson lands — stays with the session. Each script takes that decision as an **argument** and does
only the mechanics. A script that chose a rank or a disposition would be the failure `0009` measured
in reverse: cheaper turns, wrong backlog.

**Shared by every script below**, matching `./claim`, `./handoff` and `./close`:

- **FR1** — Each script takes the backlog lock, retries a busy lock inside itself as `./claim` does
  (`0047`), and releases it on every exit path, success, refusal or error, within its own process.
- **FR2** — Each script commits only the paths it wrote, by pathspec, with the `Co-Authored-By`
  trailer the existing scripts carry, and leaves anything another session staged both staged and out
  of its commit.
- **FR3** — Each script refuses malformed input before taking the lock. It names what is wrong,
  exits non-zero, and changes and commits nothing.
- **FR4** — Each script lives in `skills/queue/templates/`, is installed and byte-synced by `queue`
  Step 0 like the existing five, and is held equal to this repo's `.tickets/` copy by
  `tests/backlog-scripts-installed.test.sh`.

**The scripts:**

- **FR5 — `./capture <draft> <top|above:<row-id>|below:<row-id>> [--ranking <file>]`.** It mints
  the id as `max(items on disk) + 1`, corrects `next_id` to match, writes the draft as
  `items/<id>-<slug>.md` with that id and an `ac_digest:` computed as `./next --ac-digest` computes
  it, inserts the row at the given rank, and appends `--ranking`'s text to `RANKING.md`. One commit,
  and the new id is printed last. The rank form reuses `./reopen`'s.
- **FR6 — `./park <entry> [--repo <checkout>]`.** Appends one dated entry to `FINDINGS.md` in the
  head-token shape the buffer's header specifies, to this backlog or to the backlog of the named
  checkout, and commits it in that repo. Where the destination is a public repo per its `CLAUDE.md`
  profile, it runs the privacy guard `0118` names and refuses an entry that fails it, writing nothing.
- **FR7 — `./rank <id> <top|above:<row-id>|below:<row-id>> [--ranking <file>]`.** Moves one row,
  appends the reasoning, and commits. It refuses to move a row `in-progress` under any token
  (`queue` Step 4).
- **FR8 — `./withdraw <id> <reason> [--into <absorbing-id>]`.** Sets `status: withdrawn`, empties
  `next:`, appends the dated reason to *Notes & decisions*, removes the row, and re-points every
  open item's `blocked_by:` naming `<id>` to `--into` (or removes it where there is no `--into`). It
  never touches `next_id` and never deletes the item file. It refuses a claimed item.
- **FR9 — `./capture --restamp <id>`**, the Re-specify and Amend path. Re-stamps `ac_digest:` on an
  existing unclaimed item from its current criteria and commits. It refuses a claimed item.
- **FR10 — `./drain <date> <disposition> [<row-id>]`**, where disposition is `removed`,
  `marked:<row-id>` or `held`. It acts on exactly the entry `./next`'s findings listing (`0227`)
  names for that date and head: it removes it, marks it in place, or moves it to `FINDINGS-HELD.md`,
  then commits. It refuses an entry the listing does not name, so no drain matches the header's
  example by hand again.

**The skills:**

- **FR11** — `queue`, `retro`, `develop`, `verify`, `design`, `prototype` and `sprint` call these
  scripts at every write site above, and each by-hand lock sequence a script now covers is removed,
  `develop` Step 1's claim fallback included. `references/CONCURRENCY.md`'s by-hand-lock guidance
  remains only for a write site still without a script, and says which those are.
- **FR12** — `CHANGELOG.md` `## Unreleased` gains one entry per script, naming the stage steps that
  now call it.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | A script that writes into a public repo's buffer screens the entry first and refuses rather than writes (FR6) | AC8: an entry carrying a home path is written | `security-conventions.md` |
| Privacy & data | No entry with a real home path reaches a public repo's `FINDINGS.md` through `./park`; company material has no mechanical detector and stays the session's judgement, as now | AC8 | `data-privacy-conventions.md` |
| Performance | The queue and retro sessions after release take no by-hand lock: `classify-turns.sh`'s `LOCK` column reads 0.0% for both stages over the first 10 such sessions, re-measured by 2027-01-31 | Observation after release, recorded in *Notes & decisions*; not a close condition | `measurement-conventions.md` |
| Migration / schema | A backlog scaffolded before this release gains the five scripts at its next `queue` Step 0 and keeps every file it owns untouched | AC15: an old-shape fixture backlog after the sync | `migration-conventions.md` |
| Documentation | Each script's usage line is its header comment and its `usage:` refusal, and the skills name the script rather than restating its steps | AC16, a reading | `documentation-conventions.md` |

## Acceptance criteria

Each scripted AC names its test file. Each fixture is a scratch git repo the test builds, so no AC
reads the live backlog.

- [ ] AC1 — Given a fixture backlog whose `next_id` is 5 while `items/` holds 0007, when `./capture
  draft.md above:0003` runs, then it writes `items/0008-*.md` carrying id `0008`, sets `next_id: 9`,
  inserts the row directly above 0003, and makes one commit. Red: mint from `next_id`.
  (`tests/capture.test.sh`)
- [ ] AC2 — Given AC1's capture, when `./next --ac-digest 0008` runs afterwards, then its output
  equals the item's `ac_digest:` line. Red: stamp the digest before the id is written.
  (`tests/capture.test.sh`)
- [ ] AC3 — Given a draft with no `- [ ] AC1 —` line, when `./capture` runs, then it exits non-zero,
  writes no file, leaves `QUEUE.md` and `config.yml` byte-identical, leaves no `.lock`, and makes no
  commit. Red: skip the draft check. (`tests/capture.test.sh`)
- [ ] AC4 — Given another path staged before `./capture` runs, when it commits, then that path is
  absent from the capture commit and still staged afterwards. Red: commit without a pathspec.
  (`tests/capture.test.sh`)
- [ ] AC5 — Given `above:9999`, a row not in the queue, when `./capture` runs, then it refuses before
  minting, leaves no `.lock` and changes no file. Red: append at the bottom on a missing anchor.
  (`tests/capture.test.sh`)
- [ ] AC6 — Given a fixture buffer, when `./park "what happened"` runs, then exactly one line is
  appended in the header's head-token shape with today's UTC date, and one commit names only
  `FINDINGS.md`. Red: write the entry without its date. (`tests/park.test.sh`)
- [ ] AC7 — Given `--repo <second fixture checkout>`, when `./park` runs, then the entry and its
  commit land in the second repo and the first repo is unchanged. Red: ignore `--repo`.
  (`tests/park.test.sh`)
- [ ] AC8 — Given a second checkout whose `CLAUDE.md` profile marks it public, when `./park` is given
  an entry holding a real-shaped home path (`/Users/someone/`), then it exits non-zero, writes
  nothing and names the failing shape; the same entry with the path redacted is written. Red: skip
  the guard. (`tests/park.test.sh`)
- [ ] AC9 — Given rows A, B, C, when `./rank C above:A` runs, then the order is C, A, B with every
  other line of `QUEUE.md` unchanged, and one commit. Red: re-sort the table. (`tests/rank.test.sh`)
- [ ] AC10 — Given B `in-progress` under a token, when `./rank B top` runs, then it refuses and
  changes nothing. Red: drop the claim check. (`tests/rank.test.sh`)
- [ ] AC11 — Given 0004 named in 0005's `blocked_by:`, when `./withdraw 0004 "merged" --into 0006`
  runs, then 0004's file stays with `status: withdrawn`, an empty `next:` and a dated note; its row is
  gone; 0005's `blocked_by:` names 0006; and `next_id` is unchanged. Red: delete the item file, or
  leave 0005 pointing at 0004. (`tests/withdraw.test.sh`)
- [ ] AC12 — Given an unclaimed item whose AC2 text was edited, when `./capture --restamp <id>` runs,
  then `./next --drift` reports no digest mismatch for it. Red: restamp from the old digest.
  (`tests/capture.test.sh`)
- [ ] AC13 — Given a buffer whose header carries the fenced example `- 2026-09-05 [->0060] — …` and
  one real entry dated 2026-09-05, when `./drain 2026-09-05 removed` runs, then only the real entry is
  removed and the header is byte-identical. Red: match the date by regex over the whole file.
  (`tests/drain.test.sh`)
- [ ] AC14 — Given a real entry, when `./drain <date> held` runs, then the entry is absent from
  `FINDINGS.md`, present verbatim in `FINDINGS-HELD.md`, and both changes are in one commit. Red: write
  the held file without removing the entry. (`tests/drain.test.sh`)
- [ ] AC15 — Given a fixture backlog holding only the five pre-existing scripts, when `queue` Step 0's
  sync runs, then all ten scripts are present and byte-equal to `templates/`, and `config.yml`,
  `QUEUE.md` and `FINDINGS.md` are byte-identical. Red: omit one new script from the sync list.
  (`tests/backlog-scripts-installed.test.sh`)
- [ ] AC16 — Given the seven skills and `references/CONCURRENCY.md`, when every write site in FR11 is
  read, then each calls its script, no covered by-hand lock sequence remains, and `CONCURRENCY.md` names
  the write sites still without one. A reading, not a grep (`CLAUDE.md`, *Tests*). Red: any covered
  site still describing `mkdir .lock`.
- [ ] AC17 — Given `CHANGELOG.md`, when `## Unreleased` is read, then one entry per new script names
  the stage steps that call it. A reading. Red: a script with no entry.

## Progress

- [ ] S1 — `./capture` with its restamp form, the shared lock, commit and refusal behaviour, and its install — discharges AC1, AC2, AC3, AC4, AC5, AC12, AC15
- [ ] S2 — `./park`, with the public-repo screen — discharges AC6, AC7, AC8
- [ ] S3 — `./rank` and `./withdraw` — discharges AC9, AC10, AC11
- [ ] S4 — `./drain`, on `0227`'s listing — discharges AC13, AC14
- [ ] S5 — the seven skills, `CONCURRENCY.md` and the CHANGELOG move onto the scripts — discharges AC16, AC17

## QA plan

- **Why that level:** every script is behaviour over a fixture git repo, which is how
  `tests/claim.test.sh`, `tests/close.test.sh` and `tests/handoff.test.sh` already test their
  scripts. S5 is prose, and per `CLAUDE.md` it is read rather than grepped.
- **Specific checks:** each named test file, applying each AC's mutation once. The whole suite,
  file by file (`commands.unit_by_file`), because these scripts sit under every stage.

## Out of scope

- Choosing a rank, a disposition or a destination for the session. The scripts take each one as an
  argument (see *What stays out of the scripts*).
- The existing scripts' correctness defects (`0066`, `0155`, `0156`, `0215`, `0217`, `0219`,
  `0225`, `0229`, `0230`). They share these files and are proposed for merging into this outcome in
  the 2026-11-26 consolidation; until that merge is confirmed they stay separate rows.
- A GitHub Issues backend or mirror (reviewed 2026-11-26 and not recommended; see the conversation
  record in *Notes & decisions*).
- `runs/` and `LEDGER.md` writes, which `tools/sprint-ledger.sh` already owns.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-11-26 (queue): captured at the user's request.** The trigger is their instruction quoted in
  the Problem, which `CLAUDE.md`'s *Where toolkit work comes from* accepts in place of a confirming
  project. It also reverses 0048's withdrawal. 0048's id stays burned, and this ticket is its outcome.
- **Amend-first test.** No open ticket's outcome is "every write is a script". The closest are
  0227 (a listing, which S4 builds on) and 0118 (a guard, which S2 runs at the moment of writing).
  Both are named rather than absorbed until the consolidation is confirmed. Minted as a new outcome
  ticket with ordered slices, not five tickets, on the user's instruction to work a whole outcome
  together.
- **Routed to `develop`.** Each script's contract follows from the by-hand sequence it replaces,
  which the skills already specify step by step, and from the existing scripts' conventions. No
  decision is open.
- **GitHub Issues, reviewed 2026-11-26, not recommended as a backend.** It would not cut turns,
  since the scripts already make one call per boundary. It would lose the atomic claim (no
  compare-and-set on assignees, labels or bodies), native rank, and the file-based digest and drift
  checks. It would also need a standing token in the unattended loop. A one-way mirror on the
  `references/TRACKER.md` pattern remains open if visibility is wanted.
