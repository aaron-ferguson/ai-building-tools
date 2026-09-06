---
id: "0050"
title: Decide how file scope works when the prose files are the product
type: chore
next: design
status: ready
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
claimed_by:
claimed_at:
touches:
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

## Open design question

- **Question:** What replaces "prefer single-writer files" in a repo whose prose files are the
  product? The shapes worth weighing: **accept it** and state that this repo serialises `develop`,
  making the stall a designed outcome rather than a surprise; **make the unit of scope smaller than
  a file** — a section, a heading — and solve the pathspec problem that today makes that unsafe;
  **isolate the tree** so concurrent sessions work in separate worktrees and merge, which the
  `verify` batching note already reaches for; or **rank against the held set** so the queue orders
  work to avoid collisions rather than discovering them at claim time.
- **Why it blocks specification:** each shape has entirely different acceptance criteria — a
  documented serialisation is prose; a sub-file scope is a change to `touches:`, to `./next` and to
  how commits are staged; worktrees are a change to every stage skill's opening step. And the
  answer determines whether the `verify`-claim case is the same rule or a stricter one, since a
  corrupted verdict is a worse failure than a commit conflict and nothing currently says so.
- **Settle it with:** `/design` — the inputs are the concurrency rules, git's staging behaviour and
  this repo's own collision history. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — `references/CONCURRENCY.md` states what a session does when every takeable row at its stage
  collides, rather than leaving "prefer single-writer files" as the only guidance in a repo where
  it cannot be followed.
- FR2 — The rule distinguishes a collision with a live **`verify`** claim from a collision with a
  `develop` claim, or states explicitly that it does not, since the first corrupts a verdict and
  the second conflicts a commit.
- FR3 — `CLAUDE.md`'s *Concurrency* section, which currently records the weakness with no remedy,
  points at the settled rule.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rejected shapes and why are recorded, not only the chosen one — this question will be reopened, and re-deriving four options is the expensive part | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given `references/CONCURRENCY.md`, when read, then it states an outcome for the case
  where every takeable row at a stage collides with a held scope.
- [ ] AC2 — Given the same file, when read, then a collision with a row held at `verify` is either
  given its own rule or explicitly stated to follow the same one.
- [ ] AC3 — Given `CLAUDE.md` *Concurrency*, when read, then it points at that rule rather than
  only recording that the file-scope rule is weak here.

## QA plan

- **Level:** unit — provisional, argued across the candidate placements: a prose answer is `verify`
  with a named scripted assertion, a `./next` or `touches:` answer is `unit`, and this project's
  `unit` command runs every `tests/*.test.sh`, so `unit` subsumes both.
- **Why this level:** the level is the same across every candidate shape.
- **Specific checks:** settled by the design pass. Any grep over prose must match a phrase short
  enough to sit on one source line, and must be scoped to the section rather than the document.

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
