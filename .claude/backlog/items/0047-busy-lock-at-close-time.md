---
id: "0047"
title: Give the busy-lock procedure a close-time path
type: bug
next: verify
status: in-progress
qa_level: verify
size: s
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0034", "0023"]
expects:
  - references/CONCURRENCY-INCIDENTS.md
  - skills/verify/SKILL.md
  - tests/citations.test.sh
claimed_by: "9ff7"
claimed_at: 2026-10-27T06:22:59Z
touches:
---

## Problem

`references/CONCURRENCY-INCIDENTS.md`, *A busy or stale lock*, says: **under 5 minutes → another
session is mid-claim, report it to the user and stop, do not break it.** That is correct at claim
time, where stopping costs nothing — the row is still there, and the session tries again.

At **close** time it strands the work. The verdict already exists and lives only in the session
holding it. Stopping leaves the row `in-progress` under a token whose session is ending, which is
precisely the failure `verify` owns closing in order to prevent: a green that goes stale because
nobody wrote it down. Hit live while closing 0034 — the lock was held by another window, and the
only safe move (wait, then retry until the holder finishes) is nowhere in the procedure.

The procedure already opens with "wait a couple of seconds and retry, up to about three times", so
the close-time case is not a new mechanism — it is the same retry with a longer patience and an
explicit instruction not to abandon the verdict. What is missing is anything that says so, and a
session reading the rule literally at close time does the wrong thing.

## Functional requirements

- FR1 — *A busy or stale lock* states the close-time case distinctly from the claim-time case: a
  session holding a verdict retries with more patience rather than stopping, because stopping
  discards evidence that exists nowhere else.
- FR2 — It says what the session does when the lock is still held after that retry — where the
  verdict is written down so it survives the session, rather than being lost or the lock broken.
- FR3 — The claim-time instruction is unchanged, and the two cases are distinguished by what the
  session is holding rather than by which script it is running.
- FR4 — `skills/verify/SKILL.md` Step 5 points at the close-time case, since that is the step that
  meets it.
- FR5 — Whatever rule name FR1 lands under resolves under `tests/citations.test.sh`, so a later
  rename cannot leave `verify` pointing at nothing.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The live-conflict procedure is where this belongs by the split 0020 made — rules in `CONCURRENCY.md`, the procedure in `CONCURRENCY-INCIDENTS.md` — so the rule statement does not grow | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/CONCURRENCY-INCIDENTS.md` *A busy or stale lock*, when read, then it
  names the close-time case and says the session retries rather than stopping.
- [ ] AC2 — Given the same section, when read, then it says where a verdict goes if the lock is
  still held after the retry.
- [ ] AC3 — Given the same section, when read, then the under-5-minutes claim-time instruction to
  report and stop is still present and still says not to break the lock.
- [ ] AC4 — Given `skills/verify/SKILL.md` Step 5, when read, then it points at that section by the
  rule name.
- [ ] AC5 — Given `tests/citations.test.sh`, when it runs, then the citation added by AC4 resolves.

## QA plan

- **Level:** verify — the deliverable is prose in two files and no runner applies.
- **Why this level:** there is nothing executable here; the scripted assertion below is the
  evidence, and `tests/citations.test.sh` already owns citation resolution.
- **Specific checks:** a `grep` for the close-time phrase within the *A busy or stale lock* section
  body — **scoped to the section, not to the file**, since a document-wide match pins vocabulary
  rather than structure and this repo has shipped three such guards already. Match a phrase short
  enough to sit on one source line: `grep` is line-based here, so a phrase that straddles a wrap
  cannot be matched at all. Then `tests/citations.test.sh` and the full suite.

## Out of scope

- Changing the 5-minute threshold, or how staleness is decided.
- Making the close retry automatically inside `./close`. That is a change to the script's refusal
  behaviour and wants its own ticket; this one fixes the instruction a human or agent follows.
- The three silent by-hand-lock failures already documented in the same section.

## Notes & decisions

- Routed to `develop`: the correct behaviour is stated in the finding and follows from `verify`
  owning the close — the verdict must not be discarded, and the lock must not be broken, which
  leaves retrying. No decision is open.
- Sized `s` deliberately: this is two paragraphs and a pointer. It is Tier 2 rather than Tier 5
  because the failure it prevents destroys a verdict, and the window it fires in is the one where
  the session has no budget left to work anything out.

- **2026-10-27 (develop, token 4229) — built.** Commit `a001b73`. Guard: eight cases appended to
  `tests/by-hand-lock.test.sh` (built in the same gate for `0091`), scoped to the *A busy or stale
  lock* section and to `verify` Step 5.
  **FR2's destination, and why it is not a new mechanism:** every backlog write takes the lock
  (`CONCURRENCY.md`, *Lock every write to the backlog directory*, no exemptions, item files named),
  so a verdict cannot be *committed* anywhere in the backlog while the lock is live. It does not
  need to be: `verify` Step 7 already writes the evidence table into the held item's
  `## QA evidence` **before** the close, so at a busy lock it exists on disk under the session's
  token. The procedure says so, keeps retrying to the 5-minute staleness line (after which the
  existing stale path applies), and — if the session must end first — reports the row as
  `in-progress` with the close owed and the evidence uncommitted. **Residual risk for verify/the
  author to weigh:** that uncommitted section is one `git stash` from gone. Committing a held item
  outside the lock would close it, and would be a lock exemption, which is a decision this session
  did not take. `verify`'s rejection of a *banked* verdict (0034) is respected: the evidence is a
  record for the session that owes the close, not a tick a later session may close on.
  **Citation (FR5):** `CONCURRENCY-INCIDENTS.md` section titles are not resolvable by
  `tests/citations.test.sh`, which resolves against `CONCURRENCY.md` headings only, so `verify`
  cites the section by its rule name — `` `CONCURRENCY-INCIDENTS.md`, rule *Lock every write to the
  backlog directory* `` — plus the phrase "busy lock at close".
  **Clause table, all RUN** (committed files, restored in the same call, 31/0 after):
  | AC | clause | mutation | red case |
  |---|---|---|---|
  | AC1 | names the close-time case, retries not stops | drop "retry rather than stop" | AC1 |
  | AC2 | says where the verdict goes | replace "stays in the item you hold" | AC2 |
  | AC3 | claim-time report and stop present | "Report it to the user and stop." → "Continue." | AC3 report/stop |
  | AC3 | still says not to break the lock | "**Do not break it.**" → "Break it." | AC3 do-not-break |
  | FR3 | told apart by what is held, not the script | reword the distinction | FR3 |
  | AC4 | verify Step 5 points by the rule name | delete the pointer | AC4 |
  | AC5 | the citation resolves | rename the cited rule in verify | `citations.test.sh` names the unresolved rule |
  Whole suite green after.
