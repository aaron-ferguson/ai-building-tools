---
id: "0091"
title: Make a by-hand backlog write take the lock and prove its commit landed
type: bug
next: develop
status: ready
qa_level: verify
ac_digest: AC1=5ff73aa9 AC2=ff53688f AC3=b8925e9b AC4=80636787 AC5=f8468659 AC6=692d4ad4
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0048"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
  - skills/prototype/SKILL.md
  - skills/queue/SKILL.md
  - docs/decisions/001-one-command-per-stage-boundary.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Three separate failures of the same by-hand write, all of them silent.

1. **The park step never mentions the lock.** `retro` Step 4 says *"Take the backlog lock for every
   write inside `.claude/backlog/`"* (`retro/SKILL.md:213`). Step 6, in the same skill, tells the
   same session to append to `FINDINGS.md` and does not. The two disagree only by omission, so a
   session that locks correctly in Step 4 and then follows Step 6 literally appends **unlocked** and
   reads as having done the whole pass properly. The identical park step is in `develop` Step 7,
   `verify` Step 6, `design`, `prototype` and `queue` Step 7 — **five more copies, none of which
   names the lock** — against `CONCURRENCY.md` *Lock every write to the backlog directory*, which
   names `FINDINGS.md` explicitly.

2. **A by-hand locked write can release the lock having committed nothing, and the sequence reads as
   success.** Landing two items in one shell invocation, the commit was written as
   `git commit -m … -- $paths` with `paths` accumulated in a loop. **zsh does not word-split an
   unquoted parameter expansion**, so git received one argument of two space-joined paths and
   refused with *"pathspec … did not match any file(s)"*. The `rm -rf` released the lock on the next
   line regardless, leaving both item files edited and `FINDINGS.md` drained **uncommitted** in a
   shared tree — the *uncommitted claim* failure shape, arriving from a direction the lock cannot
   see. `CONCURRENCY-INCIDENTS.md` names three ways a by-hand lock leaks and all three are about the
   lock outliving the turn, not about the commit inside it failing while the release succeeds. The
   scripts are immune because they commit their own fixed paths; this bites only the by-hand
   sequence, which is what `retro` and every withdraw-by-hand close use.

3. **`docs/decisions/001` tells a session to do what both skills now forbid.** Its FR2 says *"Fold
   it into the boundary commit where the shell invocation allows"* of the `FINDINGS.md` append
   (`001:79`). Neither `./handoff` nor `./close` commits `FINDINGS.md`, so it cannot ride along, and
   `develop` Step 7 and `verify` Step 6 both now say to write and commit it **before** the boundary.
   The decision record is the authority a session consults when the skills' step numbers look wrong,
   and it currently sends them the other way.

## Functional requirements

- FR1 — The park step in `develop`, `verify`, `design`, `prototype`, `queue` and `retro` states that
  the `FINDINGS.md` append is a write inside the backlog directory and takes the lock, citing
  `CONCURRENCY.md` rather than restating it.
- FR2 — `CONCURRENCY.md`'s by-hand-lock rule requires two things of the commit inside the lock:
  **every pathspec named literally, never through a variable**, and **`git status` confirmed clean
  for those paths before the release**, not after.
- FR3 — `CONCURRENCY-INCIDENTS.md` gains the zsh word-split incident as an entry in its list of
  things that bite a by-hand lock — the first that is about the commit failing while the release
  succeeds, rather than about the lock outliving the turn. The list's lead-in and both of
  `CONCURRENCY.md`'s pointers to it (*"three ways a by-hand lock leaks"*) stop carrying a count, so
  the next entry added does not stale three sentences in two files.
- FR4 — `docs/decisions/001` FR2's *"fold it into the boundary commit"* clause is corrected to match
  what the scripts actually commit, and says the append precedes the boundary commit.
- FR5 — A guard asserts FR1 across all six skills: the park section of each names the lock. This is
  the code that executes FR1, without which the rule is prose six files can drift from
  independently.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | FR3's incident is written as an incident with its observed sequence, not as a restated rule; `CONCURRENCY.md` keeps the rule and `-INCIDENTS.md` keeps the story | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the six skill files, when FR5's guard runs, then it reports `0 failed`. Red-making
  change: deleting the lock sentence from `skills/design/SKILL.md`'s park step — the guard names
  that file and fails.
- [ ] AC2 — Given `references/CONCURRENCY.md`, when it is searched for the literal phrase
  `never through a variable`, then it is found on a single line. Red before this item: the phrase is
  absent.
- [ ] AC3 — Given `references/CONCURRENCY.md`, when it is searched for the phrase describing the
  pre-release status check, then the rule states the check happens **before** the release. Red-making
  mutation: moving the word `before` to `after` — the guard asserting the ordering reddens.
- [ ] AC4 — Given `references/CONCURRENCY-INCIDENTS.md`, when its list of things that bite a
  by-hand lock is read, then it carries an entry for a commit that fails while the release
  succeeds, and neither that list's lead-in nor `references/CONCURRENCY.md` states how many ways a
  by-hand lock leaks or bites (no number word — `three`, `four`, `five` — directly before
  `ways a by-hand lock` or `things bite a by-hand lock`). Red-making mutations: deleting that entry
  — the guard asserting its presence reddens; and today's files, which say `Four things bite` and
  `three ways a by-hand lock` — the count assertion reddens.
- [ ] AC5 — Given `docs/decisions/001-one-command-per-stage-boundary.md`, when the `FINDINGS.md`
  clause is read, then it does not instruct folding the append into the boundary commit. Red-making
  input: today's file, which does.
- [ ] AC6 — Given all six skills after FR1, when `tests/citations.test.sh` and the reference and
  skill size gates run, then each reports `0 failed`. Red if the added sentences push a file past
  its goal without a recorded reason.

## QA plan

- **Why that level:** no runner applies — the change is prose in six skills, two references and a
  decision record. The scripted assertions are FR5's guard plus the greps AC2–AC5 name.
- **Specific checks:** run FR5's new guard, `tests/citations.test.sh`, `tests/skill-size.test.sh`
  and `tests/reference-size.test.sh` individually. Then apply AC1's and AC4's mutations and confirm
  each reddens the named guard, and reverts green.

## Out of scope

- Giving the by-hand write a script. That is `0048`'s open decision — *which* remaining write sites
  become scripts — and this item makes the by-hand path safe **while** it exists rather than
  removing it.
- The lock's busy and stale paths, which `CONCURRENCY-INCIDENTS.md` already covers.
- `retro` Step 4 itself, which already states the rule correctly.

## Notes & decisions

- Routed to `develop`: `CONCURRENCY.md` already decides that every write inside the backlog
  directory takes the lock, and names `FINDINGS.md`. The six park steps are an omission, not an open
  question.
- The three problems are one ticket because they are one act — a session writing to the backlog
  without a script — and they touch the same two references and the same six skills. Split, each
  session re-reads all eight files.
- The grep phrases in AC2 and AC3 are deliberately short enough to survive a reflow onto one line;
  `0063` is the general fix and this item does not depend on it.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-07) — **`queue` Step 2 and `CONCURRENCY.md`
  disagree about what the lock covers, in one sentence each, and this ticket has to settle it to be
  specifiable.** Step 2: *"Release in the same turn; the item file, ranking and the row are all
  unlocked."* `CONCURRENCY.md`, *Lock every write to the backlog directory*: *"Every write, no
  exemptions … `config.yml`, `FINDINGS.md`, `RANKING.md` and the item files are all inside the
  boundary."* A capture session followed `CONCURRENCY.md` as the named authority — the queue skill's
  own preamble sends you there before writing anything — and held the lock across the `QUEUE.md`
  edits, an item amendment and `RANKING.md`. That is the stricter reading and it cost a lock held
  for minutes, which `CONCURRENCY-INCIDENTS.md` sanctions while also advising against it (*"keep
  every edit that is not to `QUEUE.md` outside it"*). Three documents pull three ways; a by-hand
  write cannot be told to take the lock until one of them wins.

- 2026-09-09 (queue) — **this item's *Out of scope* says `retro` Step 4 "already states the rule
  correctly", and that is now known to be false.** Step 4 restates `CONCURRENCY.md`'s two permitted
  by-hand forms and carries only the first, so a pass whose absorptions cannot fit one reviewable
  call is told to do something the authority it cites permits it not to do. That paragraph is
  **`0126`**, which sits directly above this row: it replaces the restatement with a citation. Read
  it before writing FR1's six park steps — the sentence FR1 asks for in five other skills is
  precisely the shape `0126` is settling, and drafting FR1 against today's Step 4 propagates the
  drifted copy into six files at once. This item's scope is unchanged: the omission in five park
  steps, not the drifted copy in the sixth.

- **2026-09-09 (retro, from `FINDINGS.md`)** — A sixth park step, and it fails worse than the five
  FR1 covers: **`design` Step 4 prescribes a by-hand backlog write that `CONCURRENCY.md` forbids and
  `handoff` exists to replace.** Its item-scoped path says to set `next: develop` / `status: ready`
  "and commit by pathspec in the same turn" — an edit to `QUEUE.md` and the item, unlocked and
  untokened, which `.claude/backlog/handoff` refuses to perform that way for six documented reasons
  (`handoff:37-41`). It also has **no correct answer for an unclaimed ticket**, because `handoff`
  requires the token the item records and `design` never tells the session to mint one. A session
  working `0140` resolved it by claiming first (`./claim 0140` → `e1ec`), writing, then handing off —
  the shape `develop` uses — and `./claim` itself supplied the missing half by printing that
  `touches:` is not seeded for a `design` stage and must be set to what the design pass will write.
  Neither `touches:` nor the claim appears anywhere in `design`'s SKILL.md. This is a *write site*
  and not only an omitted lock, so it may belong to `0048` rather than here; recorded on this ticket
  because the session that claims it is the first to be in a position to say which.

- **2026-10-27 (develop, token 5dc5) — STOPPED before building: AC4's count is stale.** No code
  written. `references/CONCURRENCY-INCIDENTS.md`, *A busy or stale lock*, already reads **"Four
  things bite a by-hand lock"** with four bullets — the fourth, *The snippet is `sh`, and an agent's
  Bash tool runs zsh* (the unmatched-glob strand, 2026-09-21), landed after this item was captured.
  Adding FR3's word-split incident makes **five**, so AC4 ("names four, the fourth being a commit
  that fails while the release succeeds"; mutation "returns the count to three") cannot be met
  without deleting a real entry. **Proposed AC4:** "Given `references/CONCURRENCY-INCIDENTS.md`,
  when its list of things that bite a by-hand lock is read, then it names five, one of them a
  commit that fails while the release succeeds. Red-making mutation: deleting that entry, which
  returns the count to four." Better still, count-free: "…then it carries an entry for a commit
  that fails while the release succeeds; red-making mutation: deleting that entry."
  **Same staleness in prose this ticket would touch:** `references/CONCURRENCY.md` says "three ways
  a by-hand lock leaks" twice (lines 261 and 268) against the four already listed; FR2's edit should
  make both count-free rather than move the number again.
  **Re-checked and still current at HEAD 7551285:** the six park steps (`develop` Step 7, `verify`
  Step 6, `design` Step 5, `prototype` Step 8, `queue` Step 7, `retro` Step 6) carry an identical
  paragraph and none names the lock (FR1); `never through a variable` appears nowhere in
  `references/` (FR2); `docs/decisions/001` lines 79–80 still say "Fold it into the boundary
  commit" (FR4). The paths are now `.backlog/` (0182). **Not a blocker, for queue to weigh:**
  `0126` (one row above) is still open and rewrites `retro`'s restated lock rule; FR1 asks for a
  citation rather than a restatement, so it does not collide, but the queue note above asked that
  it be read first. And the 2026-09-09 `queue` Step 2 vs `CONCURRENCY.md` disagreement (item,
  ranking, row "all unlocked") is still in `queue/SKILL.md:204-205`; it concerns those writes, not
  `FINDINGS.md`, which `CONCURRENCY.md` names explicitly, so FR1 is specifiable without settling it.

- **2026-10-27 (queue, re-specified on a person's escalation answer)** — Adopted develop's
  count-free AC4 rather than the "names five" variant: a count over a list this ticket does not own
  is the cardinality shape `queue` Step 2 warns against, and it went stale once already between
  capture and claim. FR3 widened to make the list's lead-in and `CONCURRENCY.md`'s two pointers
  (lines 261, 268) count-free, which develop flagged as the same staleness in prose this ticket
  already edits; AC4 now asserts that too, so the widening is checked rather than merely written.
  `size` stays `m` — three sentence edits in files FR2/FR3 already open. No other AC, FR or *Out of
  scope* line changes; ACs were all unticked. Back to `next: develop`: no FR has code yet, and
  develop's re-check at `7551285` found FR1, FR2 and FR4 still current. `0126` and the `queue`
  Step 2 disagreement stay as develop recorded them — notes, not blockers.
