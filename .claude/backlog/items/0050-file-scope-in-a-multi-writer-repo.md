---
id: "0050"
title: Decide how file scope works when the prose files are the product
type: chore
next: develop
status: in-progress
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0007", "0034", "0036", "0038", "0045"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - CLAUDE.md
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by: "5884"
claimed_at: 2026-10-28T02:45:10Z
touches:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - CLAUDE.md
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
ac_digest: AC1=4628a33e AC2=0f12239c AC3=59be2e64 AC4=fff4269d AC5=168c1e58 AC6=59b75fbe AC7=29421536 AC8=5df1dc6b
---

## Problem

`CONCURRENCY.md`'s *The working tree is shared too* says to compare a candidate's `expects:`
against every `in-progress` `touches:`, and "prefer single-writer files". In a plugin repo the
skill and reference files **are** the product, so they are structurally multi-writer and that rule
degenerates into a stage-wide lock held by whichever row happened to rank first. This project's own
`CLAUDE.md` already records the weakness; nothing states what to do instead.

**Twice in one day, on different file pairs, the whole `develop` stage stalled.**

- 0034 held `skills/verify/SKILL.md` + `references/CONCURRENCY.md`. Every other takeable `develop`
  row collided — 0036 on the first, 0007 on the second — while 0035 was at `design` and
  0006/0008/0003/0004/0037 were genuinely blocked. The session claimed nothing and stopped with the
  stage non-empty.
- 0038 held `skills/queue/templates/next` + `tests/next.test.sh` at **`verify`**. The only takeable
  `develop` row, 0007, expects both plus `.claude/backlog/next`, which
  `tests/backlog-scripts-installed.test.sh` AC2 forces byte-identical to the template. Here the
  hazard is worse than a commit conflict: a QA pass runs the suite, and edits to the files under it
  make that verdict a statement about a tree that was never a commit, with nothing in either
  session's output revealing it. `CONCURRENCY.md` covers the reverse case — `verify` marking its
  verdict advisory on changes outside the ticket — and offers `develop` no rule for this one.

Two facts make the obvious answers hard. The collisions are **section-level, not file-level** (0034
rewrites CONCURRENCY.md's advisory line, 0007 rewrites its claim rules) — but a pathspec commit
carries the other session's edits to the same path regardless, so "different sections is fine" is
not true today whatever it ought to be. And overlap **chains**: by exact file the five-row `verify`
batch of 2026-08-25 was a chain rather than a set, so any starting row reaches the entire stage.

This is now the repo's normal operating mode rather than an incident, which is what moves it out of
debt and into something that gets more expensive every day: every ticket about the tooling touches
the tooling's prose, so the collision rate rises with the very work meant to reduce it.

## Functional requirements

- FR1 — `references/CONCURRENCY.md`, *The working tree is shared too*, replaces "Prefer
  single-writer files" (in *A pathspec is necessary but not sufficient*) with the settled rule:
  **the file stays the unit of scope, and where a file cannot have one writer, the session does** —
  rows sharing a file are worked by one session, as one develop gate (`--drive` already joins rows
  by shared file) or, hand-driven, one after another. `develop` is serialised in this repo by
  design until `0137` decides otherwise.
- FR2 — The same section states the outcome when every takeable row at a stage collides: **a
  designed wait, not a failure.** Claim nothing; report each holder's id, token and shared paths as
  `./next` prints them; stop, or take work at another stage that collides with nothing. Never edit a
  held file to get unstuck, and never rewrite another row's `touches:`.
- FR3 — The same section states that a collision with a row held at **`verify`** follows the same
  taking rule **and a stricter editing one**: a `develop` session already in progress does not open
  or widen `touches:` into a file a live `verify` claim holds — it waits for the close — because
  that collision corrupts a verdict where a `develop` one only conflicts a commit.
- FR4 — The bullet ending "(preventing the collision is 0050)" and `skills/sprint/SKILL.md`'s
  *Design beside other stages* ("`0050`'s open question, not settled here") stop describing the
  question as open and point at the settled rule, still citing `0050` and keeping `disjoint` on its
  own line so `tests/sprint.test.sh`'s 0134 FR6 guard (`says … '0050'`, `says … 'disjoint'`)
  stays green.
- FR5 — `CLAUDE.md` *Concurrency* points at the settled rule by section name, rather than only
  recording that the file-scope rule is weaker here.
- FR6 — `references/CONCURRENCY-INCIDENTS.md` records the rejected shapes and why (see *Notes &
  decisions*, 2026-10-27), so the question is not re-derived when it is reopened.
- FR7 — A section-scoped guard asserts FR1–FR3's phrases. Every asserted phrase sits on one source
  line (CLAUDE.md, *Tests*: rewrapping a guarded paragraph breaks `grep`).

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rejected shapes and why are recorded, not only the chosen one — this question will be reopened, and re-deriving four options is the expensive part | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/CONCURRENCY.md`, *The working tree is shared too*, when read, then it states that when every takeable row at a stage collides the session claims nothing, reports the holders, and waits — and that this is a designed outcome.
- [ ] AC2 — Given the same section, when read, then a collision with a row held at `verify` follows the same taking rule and additionally forbids a `develop` session opening or widening into a `verify`-held file mid-session.
- [ ] AC3 — Given `CLAUDE.md` *Concurrency*, when read, then it names the section holding the settled rule rather than only recording that the file-scope rule is weak here.
- [ ] AC4 — Given `references/CONCURRENCY.md`, when grepped for `Prefer single-writer files`, then nothing matches, and the section states that rows sharing a file are worked by one session.
- [ ] AC5 — Given `references/CONCURRENCY.md` and `skills/sprint/SKILL.md` *Design beside other stages*, when read, then neither describes `0050` as an open question, and `tests/sprint.test.sh` passes.
- [ ] AC6 — Given `references/CONCURRENCY-INCIDENTS.md`, when read, then it records sub-file scope, worktree-per-session and rank-against-the-held-set as rejected, each with its reason.
- [ ] AC7 — Given the guard FR7 names, when any one asserted phrase is removed from the section, then the guard reds, and restored, it greens.
- [ ] AC8 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` is run at the closing commit, then every file passes.

## QA plan

- **Level:** unit — this project's unit command runs every `tests/*.test.sh`, which carries the new
  section-scoped guard and `tests/sprint.test.sh`'s existing 0134 FR6 guard.
- **Why this level:** the answer is prose plus a guard; no script changes.
- **Specific checks:** AC7 by mutation (remove one phrase, confirm red, restore by path, confirm
  green). AC5 by running `tests/sprint.test.sh`. AC4 by `grep -c 'Prefer single-writer files'
  references/CONCURRENCY.md` returning 0.

## Out of scope

- **Making `./next` report the collision.** That is 0045, which lands the tool change under
  today's rule; this ticket decides whether the rule itself should change. 0045 is worth having
  either way — a reader who must work out the intersection by hand should not have to.
- Changing `tests/backlog-scripts-installed.test.sh`'s byte-identity requirement, which is one
  source of the coupling but is load-bearing for a different reason.
- Anything about the batching rule's own breadth. Related, and its own question.

## Notes & decisions

- Routed to `design` on trigger 1. Ranked normally rather than sunk: two whole-stage stalls in one
  day is the cost of not having this answer, and it recurs on every subsequent day.
- Deliberately **not** bundled with 0045. That ticket implements the rule as it stands and is
  correct under any of the four shapes; this one asks whether the rule is right. Bundling would
  hold a needed tool fix behind an open decision.

### From `FINDINGS.md`, landed 2026-09-05

Five entries, and they narrow the *Open design question* rather than answering it. Each is a way
today's file-level scope fails that none of the four candidate shapes is obviously safe from, so
each is a test the chosen shape has to pass.

- **The declared scope is wrong in both directions, and both cost the top of the queue** (FINDINGS
  2026-08-30 and 2026-09-05). Over-declaration first: `touches:` has no way to say *named in an AC
  but not edited*, so 0053 declared `README.md` because AC5 names it, AC5 needed no change, and
  until the claim was released `./next develop` reported 0051, 0038 and 0046 as COLLIDES against a
  file nobody had open. `develop` Step 1 tells a session to **widen** `touches:` the moment work
  reaches further and says nothing about narrowing it the moment work turns out not to — the cost
  of the over-declaration is visible to every other session and invisible to the one holding it.
  Under-declaration second, and worse: a `verify` session's file scope is invisible, because
  `./claim` tells it to declare `touches:` and nothing checks that it did. `0081` sat `in-progress`
  for a whole session with `touches:` empty, so the only scope signal available to a second session
  was the `expects:` `queue` had predicted for its **develop** pass — stale by construction once
  develop has handed off. *The working tree is shared too* says to read that as *assume held*, and
  assuming held on a stale prediction refused `0086`, `0078` and `0075` while the session actually
  holding the files was editing neither `develop` nor `verify`. AC1's "every takeable row collides"
  case is reachable from either direction, and neither is a real collision.
- **A scope is a snapshot, and it goes stale inside the session that declared it** (FINDINGS
  2026-08-30 and 2026-09-03). `develop` reads the held file set once at claim and never again, but
  Step 5 runs the full suite an hour later: 0053's `./next develop` reported no claimed files, 0045
  then claimed and began editing `skills/queue/templates/next` and `tests/next.test.sh` mid-session,
  and the Step 5 run came back with 11 `next.test.sh` failures plus a red
  `backlog-scripts-installed.test.sh` in files 0053 never touched. Step 5 has the worktree recipe
  for telling whose red it is, but frames it as diagnosis after the fact; a `./next --claimed`
  re-read costs one line and answers it before the suite is run. The snapshot-vs-subscription gap is
  structural — any session long enough to build something can be overtaken — and it applies to the
  *other* side of the comparison too: `expects:` and a ticket's own *Notes* can disagree about who
  owns a file, and Step 1 checks `expects:` against the **code** rather than against the notes.
  `0084` listed `skills/retro/SKILL.md` in `expects:` while its Notes assigned that same prose to
  `0075` ("whichever lands second implements against the other rather than restating it"); both
  readings are internally consistent and the file plainly exists, so the grep Step 1 asks for cannot
  separate them and only reading the notes does. A `touches:` copied from `expects:` would have
  reserved and rewritten a paragraph a sibling ticket exists to rewrite.
- **Some fixes need a scope no claim can express, which is a constraint on the sub-file shape**
  (FINDINGS 2026-08-30). A comment shared byte-identically across three files cannot be improved by
  the session holding two of them. The note above the suites' shared helpers reads "each carry this
  pair" and now covers two pairs (`saw`/`saw_on_pass` and `assert_rc`/`assert_rc_nonzero`) — the
  exact imprecision that let `assert_rc` reach `next.test.sh` and `close.test.sh` and miss
  `claim.test.sh`, which is what bounced 0053 from verify. Tightening it inside 0053 meant editing
  `tests/next.test.sh`, held by 0045, so the fix was written and then backed out: half-changing it
  leaves the three copies disagreeing, which is worse than the imprecision. There is no "shared
  prose" unit a claim can hold, so this class of fix is only ever available to a session holding
  every copy at once. A scope smaller than a file does not help here; the unit needed is *larger*
  than a file and spans three of them, which is an argument for the rank-against-the-held-set shape
  over the sub-file one.
- 2026-09-07 — `retro` absorbed the design half of two `FINDINGS.md` entries into this row; the
  mechanical half is filed as `0106`. Two facts this row's decision has to accommodate:
  **(1) a file mutated transiently and restored is inside a session's file scope and no step says to
  declare it.** `develop` Step 1 defines `touches:` as "what you will actually open" and adds a rule
  for a file you will *create*; a file you break on purpose and put back fits neither, since the
  committed diff never shows it. But it is the sharpest kind of hold — proving a guard red means the
  suite is deliberately red while the mutation is live, and a concurrent whole-suite run collects
  reds that belong to nobody, cannot be reproduced a moment later, and point at a file its own
  ticket never touched. Step 5 tells the *arriving* session to check `pgrep`; nothing addresses the
  session holding the mutation. **(2) A version bump is a release act, not a build act, and so
  cannot be in a `develop` ticket's scope at all.** `tools/release` derives the next version from the
  **remote's** `plugin.json` (`0075`, after a hand-picked version collided), so a hand-bump both
  re-introduces that defect and still needs the push approval the chain opens with. `touches:` naming
  `.claude-plugin/plugin.json` invited three sessions in a row to record not having done it.
- **2026-10-27 — DECIDED (design pass, sprint run-20261027T185815Z).** *Chosen:* keep the file as
  the unit of scope and make the **session**, not the file, the single writer: rows sharing a file
  go to one session (one develop gate), a stage where every takeable row collides is a designed
  wait, and a `verify`-held file is not opened mid-session by `develop`. Re-verified against the
  tree today rather than the August narrative: `./next` already walks past colliding rows across
  every stage and prints a distinct all-collide line (`skills/queue/templates/next:1967`, from
  0045); `--drive` already joins rows by shared file into one gate (`skills/sprint/SKILL.md`,
  *Design beside other stages* and gate rules); and parallel `develop` is declined pending `0137`
  (still `next: design`). So most of the mechanism has landed under other tickets and what is
  missing is the **rule** that says these together are the answer — the stall the Problem
  describes is now the designed outcome, stated, rather than a surprise.
- *Rejected — sub-file scope (section/heading).* A pathspec commit carries every change to the
  path, so a section claim is unenforceable without a staging change no git primitive offers;
  and the 2026-08-30 finding shows the unit some fixes need is **larger** than a file (a comment
  shared by three suites), which a smaller unit makes worse.
- *Rejected — worktree per session, merge after.* That is `0137`'s question (whether `develop` may
  run in parallel at all), not a file-scope answer; backlog writes are refused from a linked
  worktree (*A second checkout never writes the backlog*); and prose merges conflict at the
  paragraph, where line-based guards then break. Worktrees stay what they are today: a read-only
  place to pin a verdict to a commit.
- *Rejected — rank against the held set.* Rank is absolute (`develop`, *On size*) and a join
  decides batching, never selection (`sprint`, 0178). The held set already shapes takeability and
  gate membership; letting it reorder rank would build rank-2 work ahead of the head.
- *Confirmed, not changed:* AC1–AC3 (reworded to the settled rule). *Added:* AC4–AC8. FR2's
  question is answered "stricter": the same taking rule, plus a no-edit rule for `verify`-held files.
- *Accommodated from the 2026-09-07 notes:* the transient-mutation hold is `0106` (done) plus
  `verify`'s one-ticket-at-a-time ordering; the version bump stays a release act and is out of
  this ticket. *Observed today, not in scope:* `./next`'s CLAIMED FILES block tells a reader to
  "assume held" the `expects:` of a row held at `next: design`, though a design session writes only
  its item and row (`skills/queue/templates/next:847`); the collision walk itself ignores it, so it
  stalls nothing mechanically — parked in `FINDINGS.md`.
- `qa_level: unit` re-read and kept; no `close_by` override — the closing stage stays `verify`.
- 2026-10-27 — develop (token a557), built in `c41610d` and `5ffbbbf`.
  - **FR1** — *The working tree is shared too* gains three bullets after *A `touches:` collision
    warns neither session*: one session per shared file (`--drive` gate or one after another,
    `develop` serialised until `0137`); FR2's designed wait; FR3's `verify`-held editing rule. The
    first bullet's "All rows collide → nothing is developable right now" now points at the
    designed wait. *A pathspec is necessary but not sufficient* drops "Prefer single-writer files"
    for "where a file cannot have a single writer, the session is the single writer instead".
  - **FR4** — CONCURRENCY.md's "(preventing the collision is 0050)" now reads "Preventing the
    collision is the next rule's job (0050)"; sprint's *Design beside other stages* says `0050`
    *settled* file scope, citing the rule, with the `disjoint` sentence untouched. sprint.test.sh's
    0134 FR6 `ok` label, which called 0050 "the open general question", reworded (label only;
    the `says` assertions unchanged). FR5 — CLAUDE.md *Concurrency* names the section.
    FR6 — CONCURRENCY-INCIDENTS.md, *The file-scope shapes that were rejected*, with each reason.
  - **FR7 guard: `tests/shared-dirty-tree.test.sh`** (its subject already includes this section),
    using its `section`/`present` helpers; each phrase on one source line, which is why some of the
    new bullets wrap short. Red before the prose: 20 passed, 15 failed. AC4 and AC5's absences are
    asserted over the whole file / section on purpose — absence is only meaningful there.
  - **AC7 mutation sweep (run)**, one mutation at a time on the subject, restored in the same
    call, control 38/0 after. Each reddened exactly one case: removing or rewording each of the
    eight FR1–FR3 phrases (`where a file cannot have one writer, the session does`, `rows sharing a
    file are worked by one session`, `serialised in this repo by design until \`0137\` decides
    otherwise`, `a designed wait, not a failure`, `claim nothing; report each holder`, `Never edit a
    held file to get unstuck`, the `verify`-held lead-in, `does not open or widen \`touches:\` …`);
    re-inserting `Prefer single-writer files` (AC4); re-inserting `open question` and `preventing
    the collision is 0050` (AC5, each its own case); deleting sprint's `` `0050` `` (AC5 cite);
    CLAUDE.md's section name (AC3); each of the three rejected-shape labels and, added after a
    gap was noticed in the first sweep, each shape's reason phrase (AC6 — "each with its reason").
  - AC8: whole suite run file-by-file at `5ffbbbf`, clean tree: no file red.
- **2026-10-27 — verify (token b127), FAIL → `develop`. The prose is right; four clause rows have
  no guard.** The build notes carry no clause table, and every mutation in the AC7 sweep was a
  guarded phrase, so the sweep could only redden. Each mutation below was applied to
  `references/CONCURRENCY.md`, landed (non-empty diff), and left `tests/shared-dirty-tree.test.sh`
  at 38/0. Gap test, whitespace-tolerant, over *The working tree is shared too*:
  1. **AC1 Given, "when every takeable row at a stage collides":** `**Every takeable row at a stage
     colliding is` → `**One row colliding is` stays green. The phrase occurred once and then zero
     times. The guard asserts the outcome and never the condition it applies to.
  2. **AC2 subject, "a `develop` session":** `stricter editing one:** a \`develop\`` → `a \`queue\``
     stays green. The phrase occurred once and then zero times. It straddles a line break
     (`a \`develop\`` / `session already under way`), so no line-based guard can assert it as it
     stands.
  3. **AC2 qualifier, "mid-session":** `session already under way` → `session before it claims`
     stays green. That inverts the rule, which would then forbid nothing mid-session. "mid-session"
     is not in the prose, so no guard can assert the AC's word.
  4. **AC5, "neither [CONCURRENCY.md] describes `0050` as an open question":** inserting
     `(0050, still an open question)` into the section stays green. The CONCURRENCY.md half of AC5
     asserts only the absence of one historical string, `preventing the collision is 0050)`, and
     only within one section, while the AC names the whole file.
  **The constraint:** rows 1–3 each need a guard in `tests/shared-dirty-tree.test.sh`'s 0050 block
  that reds under that mutation. Rejoin the AC2 sentence so that `a \`develop\` session` and the
  mid-session qualifier sit on one source line, and reword the prose to the AC's words where it only
  paraphrases them ("already under way" for "mid-session"), per `develop`'s gap-test rule (0180).
  Row 4 needs an absence assertion over the whole of `references/CONCURRENCY.md`: no line naming
  `0050` also says `open`. Write the clause table into the build notes this time.

## QA evidence

Conventions: ../ai-building-conventions
Level: `qa_level: unit`, which runs `commands.unit` as configured. There is no lint or typecheck.
The batch ran in the reporting form so that every file reports:
`for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`) at `7a4451a`, with
`git status --porcelain` empty in the same call. Every one of the 44 files printed
`passed, 0 failed` and none printed `ABORTED`, so the fail-fast form `commands.unit` would also have
exited 0 at this tree (AC8). Mutations were run with `python3 .verify-scratch/mutate.py` (scratch,
not committed), each restored by path and checked with `git diff --quiet -- <path>`.
`ac_digest matches` (`./next --ac-digest 0050 --check`).
Dirty set at Step 2: empty. Evidence set: `references/CONCURRENCY.md`,
`references/CONCURRENCY-INCIDENTS.md`, `CLAUDE.md`, `skills/sprint/SKILL.md`,
`tests/shared-dirty-tree.test.sh`, `tests/sprint.test.sh`, the whole `tests/` suite (AC8).
Intersection: empty, so the label is not advisory.

**Clause table**

| AC | Row | Mutation | Result |
|---|---|---|---|
| AC1 | Given: every takeable row at a stage collides | `Every takeable row at a stage colliding is` → `One row colliding is` | **GREEN 38/0 — gap** |
| AC1 | predicate: claims nothing | `claim nothing; report each holder` → `claim the top row; …` | RED 37/1 |
| AC1 | predicate: reports the holders | → `claim nothing; ignore each holder` | RED 37/1 |
| AC1 | predicate: waits, as a designed outcome | `a designed wait, not a failure` → `a failure` | RED 37/1 |
| AC2 | Given: a collision with a row held at `verify` | `A file held at \`verify\`` → `` `design` `` | RED 37/1 |
| AC2 | predicate: follows the same taking rule | `the same taking rule` → `a looser taking rule` | RED 37/1 |
| AC2 | predicate: forbids opening or widening into the file | `does not open or widen` → `may open or widen` | RED 37/1 |
| AC2 | subject: a `develop` session | `a \`develop\`` → `a \`queue\`` | **GREEN 38/0 — gap** |
| AC2 | qualifier: mid-session | `already under way` → `before it claims` | **GREEN 38/0 — gap** |
| AC3 | `CLAUDE.md` names the section | drop `, *The working tree is shared too*` | RED 37/1 |
| AC4 | no `Prefer single-writer files` | re-inserted | RED 37/1 |
| AC4 | rows sharing a file are worked by one session | `one session` → `any session` | RED 37/1 |
| AC5 | CONCURRENCY.md: no open-question description | insert `(0050, still an open question)` | **GREEN 38/0 — gap** |
| AC5 | CONCURRENCY.md: old phrase gone | re-insert `(preventing the collision is 0050).` | RED 37/1 |
| AC5 | sprint section: no open question | `` `0050` settled `` → `` `0050`'s open question `` | RED 37/1 |
| AC5 | sprint section: still cites `0050` | delete the `` `0050` `` cite | RED 37/1 |
| AC5 | `tests/sprint.test.sh` passes | 0 failed in the suite run | PASS |
| AC6 | sub-file scope label / reason | each mutated separately | RED 37/1, RED 37/1 |
| AC6 | worktree per session label / reason | each mutated separately | RED 37/1, RED 37/1 |
| AC6 | rank against the held set label / reason | each mutated separately | RED 37/1, RED 37/1 |
| FR1 | `where a file cannot have one writer, the session does` | → `anything goes` | RED 37/1 |
| FR1 | serialised until `0137` | → `parallel in this repo` | RED 37/1 |
| FR2 | `Never edit a held file to get unstuck` | → `Edit a held file …` | RED 37/1 |

Control after the sweep: `tests/shared-dirty-tree.test.sh` 38 passed, 0 failed.

| Check | How | Result |
|---|---|---|
| AC1 | outcome guarded; the Given condition is unguarded | **FAIL — gap 1** |
| AC2 | Given and predicates guarded; the subject and "mid-session" are unguarded | **FAIL — gaps 2, 3** |
| AC3 | guard case, mutation-proved | PASS |
| AC4 | `grep -c 'Prefer single-writer files' references/CONCURRENCY.md` returns 0; both halves mutation-proved | PASS |
| AC5 | the sprint half is guarded; the CONCURRENCY.md half asserts one string in one section, not the AC | **FAIL — gap 4** |
| AC6 | all six labels and reasons mutation-proved | PASS |
| AC7 | depends on the gaps above: removing the Given or the subject phrase does not red the guard | **FAIL** (rows 1–3) |
| AC8 | 44 files, each `passed, 0 failed` | PASS |
| NFR Documentation | rejected shapes recorded with reasons, guarded by the AC6 cases | holds, guarded |
| Always-on (`CONVENTIONS_CORE.md`) | prose and guard change, commits carry the trailer, no company material | holds |
