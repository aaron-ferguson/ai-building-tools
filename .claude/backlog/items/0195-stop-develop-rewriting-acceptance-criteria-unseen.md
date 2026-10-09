---
id: "0195"
title: Stop a criterion changing without its author by digesting it at write and checking it at close
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: l
created: 2026-10-08
source: user
parent:
blocked_by: []
relates: ["0123", "0062"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/close
  - skills/queue/templates/item.md
  - .claude/backlog/next
  - .claude/backlog/close
  - skills/queue/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - tests/ac-digest.test.sh
  - tests/backlog-scripts-installed.test.sh
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`develop` can rewrite a ticket's acceptance criteria, and `verify` then passes the edited text,
so the agreed contract changes without its author and nothing records that it did.**

The rule exists only as prose. `skills/develop/SKILL.md:306-307` reads: *"Only the author may narrow
a contract, and only `queue` may write the row that carries the remainder."* It was broken in a real
run, by a session that was right on the substance:

- `../quantum-catan/.claude/backlog/items/0003-implement-core-on-the-road-rules.md`, *Notes &
  decisions*, verbatim:
  > 2026-10-07 — develop (cd55): AC8 read "a player at 5 VP … build a City over a Settlement and
  > reach 7", which FR9 and AC6 make impossible — a City over a Settlement is net +1 (2 − 1), so
  > 5 → 6. Corrected the example to 6 VP; the criterion's substance (the win is checked the moment
  > the build lands, and every later action is `GAME_FINISHED`) is unchanged.
- Both verify sessions on that ticket — `caee` (FAIL, on other criteria) and `a7d1` (PASS → done) —
  checked AC8 **as edited** and neither flagged that the text differed from what `queue` wrote.
- The author ratified it only afterwards, same file:
  > 2026-10-08 — Owner confirmed develop (cd55)'s AC8 correction from 5 VP to 6 VP: a City over
  > a Settlement is net +1 (FR9, AC6), so 5 → 7 is impossible. AC8 as written (6 VP) is the agreed
  > criterion.

The fix was correct, and that is the dangerous case: a correct-looking rewrite is exactly the one no
reader questions, so the same path carries an incorrect one just as quietly. `verify` checks criteria
*literally*, against whatever text is on disk, so it has no way to see that the text moved.

**Why not a commit hook:** a hook cannot tell which stage is committing and would block legitimate
`queue` and owner edits. Enforcement therefore goes at the gates that read the contract — `./next
--drift` and the close — not at the write.

## Functional requirements

- **FR1 — A digest command, one definition.** `./next --ac-digest <id>` (template:
  `skills/queue/templates/next`) prints the digest of item `<id>`'s `## Acceptance criteria` section,
  read from the file bytes every time, as one line `ac_digest: AC1=<hex> AC2=<hex> …` — **one key
  per criterion**, so a mismatch can name which criterion moved. The unit is a criterion identified
  by its `ACn` label (checkbox form or struck form); its text runs from its label line to the next
  label line or the section's end. Normalisation, all of it here and nowhere else:
  - tick state is ignored (`- [x]` and `- [ ]` digest identically) — `./close` ticks and `./reopen`
    unticks, and neither is an edit to the contract;
  - runs of whitespace, newlines included, collapse to one space — a rewrap is not an edit
    (`CLAUDE.md`, *rewrapping a guarded paragraph is a breaking change*, is the hazard);
  - prose above the first label line is excluded — it is the template's instructions, not the
    contract.
  The hash tool must be one POSIX guarantees and gives identical output on macOS and Linux (`cksum`
  qualifies). This detects an unilateral edit; it is not a tamper control (see *Out of scope*).
- **FR2 — The field.** `skills/queue/templates/item.md` declares `ac_digest:` in the frontmatter,
  with a comment saying who writes it (FR3), what an absent value means (FR8), and that `develop` and
  `verify` never write it.
- **FR3 — Who stamps it.** `queue` writes `ac_digest:` from `./next --ac-digest` on every write path
  that writes or edits criteria — Add, Re-specify, Amend — in the same commit as the criteria
  (`skills/queue/SKILL.md`). `design` does the same in its clearing step when it writes or changes
  criteria (`skills/design/SKILL.md`, the step that writes the FRs and ACs an answer unblocks) — see
  *Notes & decisions*, 2026-10-08, for why this extends the owner's "only queue" and needs their
  confirmation. A `next: design` ticket with no criteria yet carries no digest.
- **FR4 — `--drift` reports a mismatch.** `drift_report` in `skills/queue/templates/next` gains a
  class, reported after the existing six and listed in the class comment above it: an item whose
  stamped `ac_digest:` differs from the computed one. One line per row, naming every criterion that
  **changed**, was **added** (key computed, not stamped) or was **removed** (key stamped, not
  computed). Because `--drive` already calls `drift_report`, it exits 4 on this with no further
  change — and that is the point: a person decides whether the new text is agreed.
- **FR5 — `close` refuses a mismatch, by the same computation.** `skills/queue/templates/close`
  refuses to close an item whose stamped digest differs from `./next --ac-digest`'s output, naming
  the criteria as FR4 does; nothing is ticked, moved or committed, and the lock is released. It
  obtains the digest **by invoking the sibling `next`**, never by re-implementing FR1's
  normalisation (`CONVENTIONS_CORE.md`, *One concept, one definition*; whether scripts may share a
  sourced file is `0103`'s open question and is not settled here). This is the code that executes
  FR6 — and it covers `close_by: develop`, where no `verify` session exists to apply FR6.
- **FR6 — `verify` treats a mismatch as a stale contract, never a pass.** `skills/verify/SKILL.md`
  says: before checking criteria literally, compare the digest; on a mismatch, write the reason
  naming the changed criteria into *Notes & decisions* and `./handoff <id> <token> queue` — the
  existing *stale contract* branch. It never passes a criterion whose text the author did not write,
  however right the new text is.
- **FR7 — `develop` routes instead of editing.** `skills/develop/SKILL.md` replaces the bare
  prohibition at lines 306-307 with the action: when a criterion is wrong or impossible, **stop**,
  record in *Notes & decisions* which `ACn`, why, and the proposed text, and `./handoff <id> <token>
  queue`. It does not edit the criterion, even to correct it. The cd55 case is the worked example.
- **FR8 — Migration: stamp on next touch; absent is unverifiable, not a pass.** An item with no
  `ac_digest:` (or an empty one) is reported by neither `--drift` nor `--drive` — every backlog that
  installs these templates holds such items, and flagging them would stop every driver on exit 4
  for a state nobody caused. Instead `close` closes it and prints one line containing `ac_digest
  absent` and `unverifiable`, and `verify` writes that same state into its QA evidence rather than
  any word that reads as a match. There is **no backfill**: a backfill writes tickets the session
  does not hold (`CONCURRENCY.md`, *A stage writes only the ticket it holds*), and stamping today's
  text would bless any criterion already edited the way cd55's was. An item gains its digest the
  next time `queue` or `design` writes its criteria.
- **FR9 — This repo's installed copies match the templates** (`.claude/backlog/next`,
  `.claude/backlog/close`), per `queue` Step 0's byte comparison.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | The check is an integrity control on the contract: the digest is recomputed from file bytes at every check (FR1), never read from a cache, and a mismatch refuses rather than warns (FR5). It does not claim tamper resistance — that is stated in the field comment (FR2) and *Out of scope*. | AC6: mutate `close` to warn and continue on a mismatch, and the fixture closes. | `security-conventions.md` |
| Observability | Every refusal and drift line names the item and each changed/added/removed `ACn`; the absent state prints a distinct, greppable line rather than nothing. | AC3 and AC8 assert the `ACn` labels in the output; AC5 asserts the `ac_digest absent` line. Dropping the label from the message reds them. | `observability-conventions.md` |
| Migration / schema | New optional frontmatter key, additive: absent never escalates and never reads as a pass (FR8), so every installed backlog keeps driving after the templates are re-copied into it. | AC5: treat absent as a mismatch and `--drift` exits 1 on the fixture; treat it as a silent match and the `unverifiable` line is missing. | `migration-conventions.md` |
| Documentation | A `## Unreleased` note in `CHANGELOG.md` for each stage that now behaves differently: `develop` hands off instead of editing, `verify` and `close` refuse a mismatch, `--drift` has a new class. | `tools/release` refuses a bump on an empty `## Unreleased` (already guarded); `grep -n 'ac_digest' CHANGELOG.md` returns nothing if omitted. | `documentation-conventions.md` |

## Acceptance criteria

Every scripted criterion lives in a new `tests/ac-digest.test.sh`, which builds its own fixture
backlog — never `tests/next.test.sh`, whose 485 cases run past a tool timeout (`config.yml`, the
`commands:` comment). Fixture ids must not look like real backlog rows, e.g. `9901`.

- [ ] AC1 — Given a fixture item whose criteria are `AC1` and `AC2`, with AC2 reading "a player at
  5 VP", when `./next --ac-digest` runs before and after (a) ticking AC1 to `[x]` and (b) rewrapping
  AC2 across two lines, then all three outputs are identical; and after changing AC2's "5 VP" to
  "6 VP", AC2's key differs and AC1's does not. Red: remove the tick normalisation and (a) differs;
  remove the whitespace collapse and (b) differs; key the whole section as one hash and AC1's key
  changes with AC2's.
- [ ] AC2 — Given the same fixture, when the prose above the first `ACn` label is edited, then
  `./next --ac-digest`'s output is unchanged. Red: start the digest at the section heading.
- [ ] AC3 — Given a queued fixture row whose item has `ac_digest:` stamped and AC2's text then
  changed, when `./next --drift` runs, then it exits 1 and prints one `DRIFT` line for that row
  naming `AC2` and not `AC1`. Red: delete the new class from `drift_report` and it exits 0.
- [ ] AC4 — Given the AC3 fixture, when `./next --drive` runs, then it exits 4 and prints the AC3
  drift line. Red: same mutation as AC3.
- [ ] AC5 — Given a queued fixture item with no `ac_digest:` key, when `./next --drift` and then
  `./close` run, then `--drift` exits 0 with no line for that row, and `close` closes it and prints a
  line containing both `ac_digest absent` and `unverifiable`. Red: treat absent as a mismatch and
  `--drift` exits 1; treat it as a silent match and the line is not printed.
- [ ] AC6 — Given the AC3 fixture held under a token, when `./close` runs with that token, then it
  exits non-zero naming `AC2`, the row is still in `QUEUE.md` and absent from `DONE.md`, no commit was
  made (`git rev-parse HEAD` unchanged) and `.lock/` does not exist afterwards. Red: remove the
  check, or make it warn and continue, and the row reaches `DONE.md`.
- [ ] AC7 — Given a fixture whose stamped digest matches, when `./close` runs and then `./reopen`
  restores it and `./next --drift` runs, then the close succeeds, and after the reopen (which unticks
  every criterion) `--drift` reports no line for that row. Red: invert the comparison and the close
  refuses; remove the tick normalisation and the post-reopen `--drift` reports the row.
- [ ] AC8 — Given a stamped fixture to which an `AC3` is then added, and a second from which `AC2`
  is then removed, when `./next --drift` runs, then it names `AC3` as added on the first and `AC2` as
  removed on the second. Red: compare only the keys present in the stamp, and the added `AC3` reports
  nothing.
- [ ] AC9 — Given `skills/queue/templates/close`, when the test greps it, then it invokes `next
  --ac-digest` and names no hash tool itself. Red: copy the normalisation into `close` and the second
  assertion fails. (Proves FR5's single definition.)
- [ ] AC10 — Given `skills/queue/templates/item.md`, when the test reads its frontmatter, then
  `ac_digest:` is declared, and its comment contains `unverifiable`. Red: delete the field.
- [ ] AC11 — Given `skills/queue/SKILL.md` and `skills/design/SKILL.md`, when the test greps each,
  then each instructs writing `ac_digest` from `./next --ac-digest` where it writes criteria. Red:
  delete either sentence. Each asserted phrase fits on one line, per `CLAUDE.md`'s rewrap hazard.
- [ ] AC12 — Given `skills/develop/SKILL.md`, when the test greps it, then it finds the instruction to
  hand a wrong or impossible criterion to `queue` naming the `ACn` and proposed text. Red: delete it.
- [ ] AC13 — Given `skills/verify/SKILL.md`, when the test greps it, then it finds that a digest
  mismatch takes the stale-contract branch to `queue` and is never passed, and that an absent digest
  is recorded as `unverifiable`. Red: delete either sentence.
- [ ] AC14 — Given this repo after the change, when `tests/backlog-scripts-installed.test.sh` runs,
  then it passes: `.claude/backlog/next` and `.claude/backlog/close` match their templates byte for
  byte. Red: edit either installed copy.

## QA plan

- **Why that level:** the mechanism is two shell scripts with a fixture-driven test; the prose half
  is greppable. `unit` here is the whole `tests/*.test.sh` suite (`config.yml`), which also re-runs
  `close.test.sh`, `reopen.test.sh` and the size gates the skill edits could move.
- **Specific checks:** run `tests/ac-digest.test.sh`, then the suite by file (`unit_by_file`). Apply
  every red named on AC1-AC14 and confirm each reds. Additionally mutate FR1's normalisation **in
  `next` only** and confirm AC7's close case follows it — the behavioural proof that `close` has no
  second definition. Run `tests/skill-size.test.sh` and record each touched skill file's byte growth
  in *Notes & decisions*; FR7 *replaces* a sentence and should grow `develop` little or not at all.

## Out of scope

- **Tamper resistance.** A session that edits a criterion *and* restamps the digest defeats this;
  it would then be visible only in `git log`. The failure observed was a session acting in good
  faith, which this catches. Signing or an audit of who stamped is a separate ticket if wanted.
- **A commit hook** — rejected by the owner, reason in *Problem*.
- **Backfilling existing items** — FR8 says why.
- **Withdrawing or renumbering a criterion** — `0123`'s subject. This ticket only requires that a
  removed key is reported (AC8).
- **Whether backlog scripts may share a sourced file** — `0103`. FR5 invokes `next` instead.
- **Retro-flagging quantum-catan 0003** — closed and ratified by its owner.

## Notes & decisions

- 2026-10-08 — queue: **Routed to `develop`.** The owner made the design decision on 2026-10-08
  (digest at queue write, `--drift` drift, `verify` refuses, `develop` routes); no surface and no open
  decision remains, so `design` has nothing to settle.
- 2026-10-08 — queue: **Decisions taken at capture, inside the owner's design.**
  1. *Per-criterion keys rather than one section hash* — point 3 requires naming the changed
     criterion, and a single hash cannot; keyed digests name it with no git archaeology.
  2. *Migration: stamp on next touch, absent = unverifiable* (FR8) — the owner's suggested option,
     chosen over a backfill for the two reasons stated there.
  3. *`close` enforces too* (FR5) — `queue` Step 2 requires an FR naming the code that executes a
     rule; `verify` is prose, and a `close_by: develop` ticket never meets a `verify` session.
  4. **Needs the owner's confirmation: `design` stamps too** (FR3). The decision said *"only
     queue's write path stamps it"*, but `design`'s clearing step writes criteria (design
     `SKILL.md`, step 2) on a ticket `queue` stamped with none. Without a stamp there, every
     design-cleared ticket either drifts on exit 4 or closes unverifiable forever. Read as intended —
     the *author's* write path stamps, `develop` and `verify` never do — `design` is part of it,
     recording the owner's decision. If the owner meant it literally, strike `design` from FR3 and
     AC11 and route design-cleared tickets back through `queue` instead; nothing else changes.
