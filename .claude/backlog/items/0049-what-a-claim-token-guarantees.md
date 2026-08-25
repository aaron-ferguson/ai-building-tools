---
id: "0049"
title: Decide what a claim token guarantees and what enforces it
type: chore
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0022", "0023", "0029"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`CONCURRENCY.md`'s *Claim tokens* says ownership is memory: a ticket is yours only if you minted
its token in this conversation, and an unfamiliar token is the other window's. Two live failures
sit in the gap that rule leaves.

**A familiar token on work you did not do.** While `develop` held 0026 as `ebff`, a concurrent
session committed `267d13f` and `2cfc227` tagged `[ebff]` for an unrelated repo-wide rename.
Whether that was a 1-in-65536 collision on `head -c2 /dev/urandom` or a token read out of a file
and reused, the effect is the same: the audit trail cannot say who did what, and the rule as
written gives a session no way to notice, because it only tells you what to do with an *unfamiliar*
token. The same commit also swept 41 lines of that ticket's uncommitted *Notes & decisions* into
its own message — the documented hazard arriving from the direction the rule does not cover, since
the notes were mid-write rather than a claim.

**A stale token on a closed ticket.** 0010 is `status: done`, `closed: 2026-08-23`, and still
carries `claimed_by: "1b2e"`. `./close` clears both claim fields, so this is a by-hand close
predating the script — but `CONCURRENCY.md` defines *held* as a non-empty `claimed_by:` and nothing
else, and the close-reconcile rule refuses to write a held dependent. A stale token on a closed
ticket is therefore a row a future reconcile will silently skip and report as someone else's.

The two share a root: the token is treated as an identity, and nothing anywhere establishes that it
is unique, live, or attributable.

## Open design question

- **Question:** What is a claim token, and what enforces it? The candidates named when this was
  found were: **widen the token** so collision stops being plausible; **have `./claim` refuse a
  token already live in another item's `claimed_by:`**, making uniqueness checkable at mint time;
  or **drop the pretence that a commit tag identifies a session** and say what the tag is actually
  for. They are not exclusive, and the third changes what the other two are worth.
- **Why it blocks specification:** the acceptance criteria differ completely between them. Widening
  is an AC about `./claim`'s output format and a migration across 41 existing items. Refusing is an
  AC about a new refusal path and its message. Dropping the pretence is an AC about prose in
  `CONCURRENCY.md` and about what, if anything, replaces the commit tag. Nothing can be written
  until it is known which problem is being solved — and a fourth possibility is that the honest
  answer is "a token is a hint, not an identity", which would make both mechanisms unnecessary and
  the fix entirely a documentation one.
- **Settle it with:** `/design` — the inputs are the existing rules, the script, and the collision
  arithmetic. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — `references/CONCURRENCY.md` *Claim tokens* states what a session does when it meets its
  **own** token on work it does not remember doing, which today it does not cover.
- FR2 — A `done` ticket carries no `claimed_by:`, and something reports it when one does — so a
  reconcile cannot silently skip a dependent it should have freed.
- FR3 — 0010's stale token is cleared, since it is the live instance and leaving it means the rule
  and the tree disagree the day this lands.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | If the answer widens the token, 41 existing items carry the old width; readers must accept both before anything narrows, and nothing rewrites history to match | `migration-conventions.md` |
| Documentation | Whichever answer wins, the reasoning is recorded — the next reader's question is why a stronger mechanism was or was not chosen | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These two hold regardless:

- [ ] AC1 — Given `references/CONCURRENCY.md` *Claim tokens*, when read, then it says what to do on
  meeting your own token on work you did not do.
- [ ] AC2 — Given `items/0010-*.md`, when its frontmatter is read, then `claimed_by:` is empty.

## QA plan

- **Level:** unit — provisional, argued across the candidate placements: a `./claim` refusal path
  or a widened mint is `unit`; a documentation-only answer is `verify` with a named scripted
  assertion, and this project's `unit` command runs every `tests/*.test.sh`, so `unit` subsumes it.
- **Why this level:** the level is the same across every candidate, so it is set now.
- **Specific checks:** settled by the design pass. `tests/claim.test.sh` runs in every case.

## Out of scope

- The `git add` hazard that carried 41 lines of another ticket's notes into an unrelated commit.
  Real, and already covered by *The git index is shared*; this ticket is about the token.
- Introducing an ambient session id. `CONCURRENCY.md` records that there is none, and inventing one
  is a much larger change than any candidate above.
- Whether a commit should be tagged with a token at all beyond what the answer to the third
  candidate implies.

## Notes & decisions

- Routed to `design` on trigger 1: which mechanism is right determines every acceptance criterion,
  and the four candidates are mutually incompatible in what they would assert.
- FR2 and AC2 are separable from the decision and stated now on purpose: 0010's stale token is a
  live defect whatever the token turns out to mean, and leaving it out would let the whole ticket
  sit behind a decision while a known-wrong row stayed in the tree.
