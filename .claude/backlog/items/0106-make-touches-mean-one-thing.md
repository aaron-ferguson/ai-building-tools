---
id: "0106"
title: Make touches mean one thing across claim, close and a transient mutation
type: bug
next: develop
status: in-progress
qa_level: unit
qa_manual:
size: m
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: ["0050"]
expects:
  - .claude/backlog/claim              # the seeding defect
  - skills/queue/templates/claim       # its source of truth
  - .claude/backlog/close              # declared-vs-actual reporting
  - skills/queue/templates/close
  - skills/develop/SKILL.md            # Step 1's definition of what belongs in touches
  - tests/claim.test.sh
claimed_by: "1a3e"
claimed_at: 2026-09-09T20:17:31Z
touches:
  - .claude/backlog/claim              # the seeding defect
  - skills/queue/templates/claim       # its source of truth
  - .claude/backlog/close              # declared-vs-actual reporting
  - skills/queue/templates/close
  - skills/develop/SKILL.md            # Step 1's definition of what belongs in touches
  - tests/claim.test.sh
---
## Problem

Four findings landed on one field in two days. They are one ticket because they are one question —
what `touches:` means — and fixing any one alone leaves the field still meaning three things.

**1. `claim` prepends its `expects:` seed above an existing `touches:` instead of replacing it.**
Claiming `0039` for QA turned a deliberately narrowed two-path `touches:` — carrying a comment
explaining why `.claude-plugin/plugin.json` was *excluded* — into a nine-entry list: all seven
`expects:` paths, then the prior session's narrowing comment, then its two paths, with `README.md`
and `tests/orchestrate.test.sh` each listed twice, under a comment saying the scope is "the ONE
gap". The script's header says the seed exists because an absent `touches:` reads as "every file
this item names is held" — right for a *fresh* claim, wrong for a re-claim, where it silently
discards the narrowing the previous session was instructed to perform and leaves the reasoning
annotating the wrong list.

**2. A non-building stage seeds a build scope it will never write.** `verify` opens none of those
files to write — it writes the item and the queue. So a QA claim reserved seven paths against
concurrent sessions for a pass that touched none of them, which is exactly the suboptimal-pick cost
`expects:`/`touches:` exist to avoid. `close` then hides it by clearing the field. `claim` already
knows the row's `next:`.

**3. `touches:` can name a file for an edit that never happens, and nothing notices.** `0039`'s
re-entry declared `.claude-plugin/plugin.json` for a version bump that never occurred. An unused
reservation is invisible by construction: `./next --drift` compares Status against `blocked_by`,
`claim` and `close` never diff the range, and no test compares declared touches against what the
commits changed. The asymmetry matters — a touch reaching **further** than declared is the dangerous
one and is also unchecked, but one reaching **less far** carries an intention that reads, to the next
session, as a completed step.

**4. A file mutated transiently and restored fits neither reading of the field.** `develop` Step 1
defines `touches:` as "what you will actually open" and adds a rule for a file you will *create*; a
file you break on purpose and put back is neither, since the committed diff never shows it. But it
is the sharpest kind of hold: proving a guard red means the suite is deliberately red while the
mutation is live, and a concurrent whole-suite run collects reds that belong to nobody, cannot be
reproduced a moment later, and point at a file its own ticket never touched. Step 5 tells the
*arriving* session to check `pgrep`; nothing addresses the session holding the mutation.

## Functional requirements

- **FR1** — `claim` seeds `touches:` from `expects:` only when `touches:` is empty. Where it is not,
  it either replaces it and says so in its output, or leaves it alone — never prepends.
- **FR2** — `claim` does not seed a build scope for a stage that does not build. It knows the row's
  `next:`; a `verify` claim reserves what `verify` writes.
- **FR3** — At close or hand-off, the ticket's commit range is diffed against `touches:` and **both**
  directions are reported: declared-but-untouched, and touched-but-undeclared. A note, not a gate —
  over-declaring is legitimate, and under-delivering is the half that wants saying out loud.
- **FR4** — `develop` Step 1 covers the transiently-mutated file: whether it is declared, and what
  the session holding a live mutation owes a concurrent whole-suite run.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `claim`'s header stops describing a seed that unconditionally applies | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an item with a non-empty `touches:`, when it is re-claimed, then the field is not
  prepended to and no path appears twice.
- [ ] AC2 — Given a re-claim that replaces `touches:`, when it completes, then its output says the
  field was replaced and what it was.
- [ ] AC3 — Given a row at `next: verify`, when it is claimed, then `touches:` is not seeded from
  `expects:`.
- [ ] AC4 — Given a ticket whose commits changed a path its `touches:` never named, when it closes,
  then the output names that path as touched-but-undeclared.
- [ ] AC5 — Given a ticket whose `touches:` names a path its commits never changed, when it closes,
  then the output names that path as declared-but-untouched, and the close still succeeds.
- [ ] AC6 — Given `develop` Step 1, when read, then it states whether a transiently-mutated file is
  declared and what the mutating session owes a concurrent suite run.
- [ ] AC7 — Deleting the seed-only-when-empty condition from `claim` turns a test red.

## QA plan

- **Level:** unit — `tests/claim.test.sh` and `tests/close.test.sh` scaffold throwaway git repos and
  assert on exit code, message and resulting files; both new behaviours fit that shape.
- **Why this level:** these are shell scripts whose only contract is what they do to a file of a
  given shape.
- **Specific checks:** a fixture with a populated `touches:` re-claimed, asserting no duplicate path;
  a `next: verify` row claimed, asserting the field is untouched; a fixture whose commits and
  `touches:` disagree in each direction, asserting both messages. Prove each falsifiable by
  mutation, and per `testing-conventions.md` scope the phrase count to the guard's own subject.

## Out of scope

- Deciding what file scope *means* when the prose files are the product — that is `0050`, and this
  ticket takes its answer as given rather than pre-empting it.
- Making `touches:` enforce anything. It warns; `CONCURRENCY.md` is explicit that it does not lock.
- Removing a version bump from a ticket's expected scope. `0075` owns the release-versus-build
  question and the reason a bump cannot be discharged by a `develop` session at all.

## Notes & decisions

- 2026-09-07 — Filed by `retro` from four `FINDINGS.md` entries dated 6-7 Sep, all pointing at this
  one field. The design half — what scope means where the product *is* the prose — was left with
  `0050` rather than duplicated here.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **defect 1 recurred on `0086`, which
  establishes it as systematic rather than a one-off.** `claim` prepended all 15 `expects:` paths
  above `b708`'s 18 narrowed ones — re-adding the four paths that item's inline comments say
  explicitly are NOT touched (`MEASUREMENT.md`, `references/TRACKER.md`,
  `.claude/backlog/config.yml`, and a `status: done` item) — and committed the result under
  `Claim 0086 [afac]` with the printed message unchanged: *"touches: is set provisionally from
  expects: (15 paths) — NARROW it"*. Nothing is lost, but the field the other window reads to decide
  what is safe to take now reserves a strictly wider set than the work needs, and the narrowing a
  previous session did *and commented* is silently demoted to a duplicate list below the widened
  one. A ticket returning to `verify` after a `develop` pass is the normal case for this. The rule
  the script is missing is the one `develop` already has for `expects:` versus `touches:` —
  **a populated `touches:` is a verified scope and a prediction never overwrites one**: re-claim
  should leave it alone and say it did, or merge and report the delta.
