---
id: "0034"
title: Derive the advisory label from the paths the verdict rested on
type: feature
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: agent
expects:
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
---

## Problem

`verify` Step 2 labels a run **advisory** when the working tree carries changes outside the ticket,
and Step 7 forbids an advisory PASS from closing. The row returns to `next: verify, status: ready`
carrying **no record that the pass ran at all**.

On 0024 that cost a full re-run: 21 assertions, six mutations and a tree-wide grep, to reach a
verdict that had already been reached. And that pass was not luck — every AC was checked against
**both** the committed and the working-tree copy of every file it rested on, precisely so the dirty
tree could not change the answer. The only thing that actually had to change was a tree nobody in
the pass controlled.

So "advisory" currently conflates two different states:

- *green may be luck* — the run touched files another session is mid-editing, and a different tree
  could give a different answer;
- *green survived both states* — the run was checked against committed and working copies and the
  dirty paths provably cannot affect it.

The second deserves either a close or a durable record. The first deserves neither.

## Functional requirements

The decision is in *Notes & decisions*: **advisory becomes derived, not authored** — from the
intersection of the dirty paths and the paths the verdict rested on. Nothing is banked.

- FR1 — `verify` records an **evidence set**: for each AC and each checked NFR row, the repo paths
  its verification actually read or executed — the files asserted over, the fixture, the script run.
  Step 3 already records *how* each was verified; it also records *where*. **A path in doubt is in
  the set**, because the conservative direction costs a re-run and the other direction is a wrong
  close.
- FR2 — Advisory is **derived**: a run is advisory if and only if Step 2's dirty set intersects the
  evidence set. An empty intersection is a plain PASS that closes by Step 5's normal path, and the
  verdict names the dirty paths it excluded and states the intersection was empty. No session
  labels a run advisory as a judgement about whether the dirt *looks* relevant.
- FR3 — A non-empty intersection stays advisory and still does not close — **even when the pass
  checked both the committed and the working copy and they agreed**. Step 7 says so with the
  reason: agreement across two snapshots is not independence, because the other session's edit is
  unfinished and the state it will commit does not exist yet. Say it explicitly, since "I checked
  both copies" is the argument a session in this position will reach for.
- FR4 — **Nothing is banked.** No new field, no staleness rule, no expiry. Step 5's "no durable
  verdict file exists or is needed" stands, and gains the one-line reason it was kept: a banked
  verdict is a tick the next session did not write, and no file hash can certify that the earlier
  pass broke the right behaviour.
- FR5 — `references/CONCURRENCY.md`'s "`verify` marks its verdict advisory on changes outside the
  ticket" is corrected in the **same change** to the derived rule — dirty *under test*, not dirty
  anywhere. Per `documentation-conventions.md`, a change contradicting a documented rule updates
  that rule in its own commit; left alone this line is the stale half that gets the old behaviour
  restored by someone who thinks they are fixing a regression.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whichever way this goes, the reasoning is recorded — a future session will meet the same advisory state and needs to know this was decided rather than overlooked | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/verify/SKILL.md`, when Step 3 is read, then it requires recording the repo
      paths each AC's and each checked NFR row's verification read or executed, and states that a
      path in doubt is included in the set.
- [ ] AC2 — Given `skills/verify/SKILL.md`, when Step 7 is read, then advisory is defined as Step 2's
      dirty set intersecting Step 3's evidence set, and no other trigger for the label remains
      anywhere in the file.
- [ ] AC3 — Given a run whose dirty paths do not intersect the evidence set, when Step 7 is read,
      then it directs a plain PASS closing by Step 5, and requires the verdict to name the excluded
      dirty paths and state that the intersection was empty.
- [ ] AC4 — Given a run whose dirty paths do intersect the evidence set, when Step 7 is read, then it
      still forbids the close, and explicitly refuses "both copies agreed" as grounds for closing,
      with the reason.
- [ ] AC5 — Given `skills/verify/SKILL.md` Step 5, when read, then it still states that no durable
      verdict file exists or is needed, and carries the reason banking was rejected.
- [ ] AC6 — Given `references/CONCURRENCY.md`, when read, then its advisory line states the derived
      rule, and no line in the file says that a change anywhere outside the ticket makes a verdict
      advisory.
- [ ] AC7 — Given the recorded case in `FINDINGS.md` dated 2026-08-24 — a concurrent `queue` session
      leaving `QUEUE.md` modified and an item file untracked, on a ticket whose ACs rest on skill and
      template files — when Step 7's rule is applied to it by hand, then the run is not advisory and
      the ticket closes.

## QA plan

- **Level:** verify — confirmed by the design. The outcome is prose in `verify` and one corrected
  line in `CONCURRENCY.md`, with no runner behind either: FR4 adds no field, so nothing gains
  parsing and the level does not move up.
- **Why this level:** every AC is a statement about what a file says, checkable by reading it. AC7
  is the exception worth noting — it is the rule applied by hand to a recorded case, which is the
  only way to test a prose rule against the situation that produced it.
- **Specific checks:** read Steps 3, 5 and 7 of `skills/verify/SKILL.md` for AC1–AC5; grep
  `references/CONCURRENCY.md` for `advisory` for AC6; walk AC7's case against the written Step 7.

## Out of scope

- Changing what Step 2 *does*. It still runs `git status --porcelain` on every pass, still records
  every change outside the ticket, and still forbids stashing or reverting to tidy. What this ticket
  moves is where the **label** is decided — at Step 7, against evidence — because at Step 2 the pass
  does not yet know which files its ACs rest on. **This narrows the ticket's original out-of-scope
  line**, which read "Step 2's trigger is not in question": the trigger is not in question, but its
  resolution had to be, or the answer is a permanently unclosable state.
- Anything that would have `verify` tidy a dirty tree. Destroying another session's work to get a
  clean verdict is forbidden and stays forbidden.

## Notes & decisions

- Recorded 2026-08-23 from the retro. Aaron's read of the finding was that this might be `verify`
  failing to write its findings to the ticket; it is not — `verify` does write its verdict on red
  and on stale-contract. The gap is specifically the **advisory PASS**, which writes nothing because
  no field exists for "ran completely, passed, could not close".

### Decision — 2026-08-23: advisory is derived, and nothing is banked

**The answer to the open question is neither "it closes" nor "it banks" as posed — it is that the
label was being computed from the wrong set.** A run is advisory when the dirty paths intersect the
paths the verdict rested on. Empty intersection: not advisory at all, plain PASS, closes normally.
Non-empty: advisory, does not close, and nothing is written down.

**Why this shape.** `FINDINGS.md` (2026-08-24) records what the motivating state actually was: a
concurrent `queue` session leaving `QUEUE.md` modified and an item file untracked, on tickets whose
ACs rested on skill and template files. That dirt provably could not influence the verdict, and the
finding named the distinction the rule wanted — *dirty under test*, not *dirty anywhere*. So the
common case needs no bank; it needs the label to stop firing on dirt that is not under test. Under
the literal old rule, no ticket could close while another window was queueing, which is precisely
the concurrency this suite is built for.

**It follows prior art rather than inventing a mechanism.** 0024 made `blocked` derived from the
graph rather than authored into a column, for the same reason: two answers to one question, and the
written one was wrong. This is that pattern applied to `advisory`. Sub-question 1 asked whether
*provably independent* is a rule or a judgement — as an intersection of two path lists it is a rule.
Step 2 produces one list from `git status`; Step 3 produces the other as a by-product of work it
already does. The one soft edge is enumerating the evidence set honestly, which is the same
judgement Step 3 already demands in "record how you verified it", so it adds no new trust. FR1
biases it toward inclusion, and the asymmetry is deliberate and the same one 0024 reasoned from: a
missed path costs a re-run and is caught, a wrong close is not.

**Rejected — banking a durable verdict** (the option the ticket was named for). Sub-question 2 asked
whether writing the verdict to the item changes `CONCURRENCY.md`'s reasoning about a verdict
travelling between sessions. It does not, and the reason is that the rule is about *warrant*, not
medium: `verify` closes because the session that ran the pass is the only one that knows what it
checked and how hard it tried to break it. Step 3 already says **never trust a tick you did not
write** — a banked verdict is exactly a tick you did not write, wearing a file-hash badge. The hash
certifies which bytes were read; it cannot certify that the earlier pass mutated the right behaviour
and saw it go red. Banking therefore imports the judgement the separate QA pass exists to refuse.
Sub-question 3's staleness rule is worse than moot: it can only invalidate on files the pass
*enumerated*, so a commit to a file the pass read but did not list silently fails to invalidate — an
under-approximation that fails silently, and untestable, because you cannot write a test for the
file you forgot. **What would have made banking win:** if the intersection were usually non-empty,
so deriving closed almost nothing. The recorded case says the opposite.

**Rejected — requiring a clean tree before QA** (sub-question 4). The sessions cannot be serialised:
`retro` writes without holding a claim by design, and a second window queueing is the normal state
rather than an anomaly. A clean-tree precondition either blocks QA indefinitely or creates pressure
to tidy, which Step 2 forbids for a much better reason than this one.

**The cost accepted.** The genuinely-lucky case — dirty paths *are* under test — still ends with no
durable record and a possible re-run, which is the thing the ticket's title asked for. That is
deliberate: there the verdict rests on files being rewritten under it, so re-running is not waste,
it is the work, and banking would bank the one verdict that might be wrong. Second cost: Step 3
gains bookkeeping in a skill file 0021 is trying to trim, so FR1 should land as a clause on the
existing sentence rather than a new paragraph.

**Recorded here rather than as an ADR.** `documentation-conventions.md` puts decision records in
`docs/decisions/`; this repo has no such directory, and the same file says a mechanism belongs in
the working doc for its class of problem. That doc is `references/CONCURRENCY.md`, which FR5 makes
carry the rule — starting an orphaned `docs/decisions/001` for one entry is the failure that file
warns about.

**No design system or accessibility check applies** — the artefacts are two prose files in a
plugin, with no user-facing UI.
