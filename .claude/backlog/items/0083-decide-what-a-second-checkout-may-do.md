---
id: "0083"
title: Decide what a second checkout may do with the backlog
type: bug
next: develop
status: in-progress
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0081", "0082"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/handoff.test.sh
claimed_by: "7bf5"
claimed_at: 2026-09-12T22:27:25Z
touches:
  - references/CONCURRENCY.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/templates/claim  # also mutated transiently for AC5, restored in the same turn
  - skills/queue/templates/close  # also mutated transiently for AC5, restored in the same turn
  - skills/queue/templates/handoff  # also mutated transiently for AC5, restored in the same turn
  - .claude/backlog/claim  # installed copy, AC8
  - .claude/backlog/close  # installed copy, AC8
  - .claude/backlog/handoff  # installed copy, AC8
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/handoff.test.sh
---

## Problem

**The backlog lock is per-checkout, and nothing detects a second checkout.** `.claude/backlog/.lock/`
is a directory *inside the working tree*, so two clones — or two `git worktree`s — each get their own
lock **and their own `QUEUE.md`**. `./claim` would grant the same row twice with no warning, because
neither invocation can see the other's status cell. `CONCURRENCY.md`'s *A claim must be durable the
moment it is made* is written as though one tree is a given.

**What makes this worth settling now rather than after it bites: two skills actively send sessions into
worktrees.**

- `develop` Step 5 recommends a throwaway worktree for isolating a red that may not be yours, and for
  the deterministic/flaky discrimination.
- `verify` Step 2 — **as of 2026-09-01** — prescribes verifying a named commit in a worktree at
  `qa_level: e2e`, because the advisory intersection can never be empty there.

Both are correct and both are new load on an undefined rule. The 2026-09-01 retro used a worktree three
times in this repo, once to establish that a suite red was tree pollution rather than its own defect.

Today the hazard is **latent, not live** — AetherWorks is one checkout, and its two configured working
directories are the same inode on a case-insensitive volume.

**Worse than invisible — observed 2026-09-12 (design stage).** In a scratch clone with a
`git worktree add --detach` beside it, `./claim 0089` from the worktree exited 0 and committed
`Claim 0089 [aaaa]` onto the worktree's **detached HEAD**; `./claim 0089` from the primary then
exited 0 as well. After `git worktree remove`, `git branch -a --contains` on the worktree's claim
commit listed nothing: the claim is not merely unseen by the other session, it is **unreachable once
the worktree goes** — which the skills tell the session to do in the same turn. The script's own
durability test (*committed*) passed, and the claim was still destroyed.

## Functional requirements

1. `claim`, `close` and `handoff` refuse when run from a **linked worktree** — detected as
   `git rev-parse --git-dir` differing from `git rev-parse --git-common-dir` — before taking the lock,
   changing nothing, with a message naming the primary checkout to run from and citing
   `CONCURRENCY.md`. Placement matches `claim`'s existing *before the lock, deliberately* refusals.
2. `CONCURRENCY.md` states the rule **once, in its own section** (Part 1): a second checkout of the
   repository — a linked worktree **or a second clone** — may read and run tests and must never
   claim, close or hand off, because the lock and `QUEUE.md` are per-checkout. It says the scripts
   refuse the worktree case mechanically and that **a second clone is caught by nothing but this
   rule**. The existing sentence inside the `qa_level: e2e` bullet is replaced by a citation of that
   section, not left as a second statement.
3. `develop` Step 5 (the throwaway worktree, both the checkout and the replay form) and `verify`
   Step 2 (the e2e worktree and the whole-project-gate worktree) each cite that section at the point
   they prescribe a worktree — one citation, no restatement.
4. `./next` is unchanged: it only reads.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Stated once and cited, not restated in three skills. | `documentation-conventions.md` |
| Testing | Any mechanical check is proved able to fail from inside a real linked worktree, not from a simulated path. | `testing-conventions.md` |
| Guards | `tests/retro-tool-edit.test.sh` pins `worktree in the same turn` inside `develop` Step 5 — add the citation without rewrapping that line. | `CLAUDE.md` *Tests* |

## Acceptance criteria

- [ ] AC1 — **Given** a fixture repo with a `ready` row and a real `git worktree add --detach` of it,
  **when** `./claim <id>` runs from the worktree's `.claude/backlog/`, **then** it exits non-zero, the
  message names a linked worktree and `CONCURRENCY.md`, no commit is added to the worktree's HEAD, and
  the worktree's `QUEUE.md` and item file are byte-identical to before.
- [ ] AC2 — **Given** the same fixture with the row claimed in the primary, **when** `./handoff <id>
  <token> <stage>` runs from the worktree, **then** it exits non-zero and changes nothing, as in AC1.
- [ ] AC3 — **Given** the same fixture with the row claimed in the primary, **when** `./close <id>
  <token>` runs from the worktree, **then** it exits non-zero and changes nothing, as in AC1.
- [ ] AC4 — **Given** the primary checkout of the same fixture, **when** each of the three scripts runs
  its ordinary success case, **then** it succeeds as today — the check does not refuse a primary.
- [ ] AC5 — **Given** each new worktree case, **when** the detection is mutated to always report
  "primary", **then** that case fails — recorded in the verify notes as the proof the guard can fail.
- [ ] AC6 — **Given** `references/CONCURRENCY.md`, **when** it is read, **then** exactly one passage
  states that a second checkout must never claim, close or hand off, it names both a linked worktree
  and a second clone, and it says the clone case has no mechanical check.
- [ ] AC7 — **Given** `skills/develop/SKILL.md` Step 5 and `skills/verify/SKILL.md` Step 2, **when**
  each prescribes a worktree, **then** the same paragraph cites the `CONCURRENCY.md` section by name,
  and `tests/retro-tool-edit.test.sh` stays green.
- [ ] AC8 — **Given** the change, **when** `skills/queue/templates/{claim,close,handoff}` are compared
  with `.claude/backlog/{claim,close,handoff}`, **then** they match
  (`tests/backlog-scripts-installed.test.sh` green).

## QA plan

- **Level:** unit — this repo's whole suite; `claim.test.sh`, `close.test.sh` and `handoff.test.sh`
  each gain a case that adds a real `git worktree` to their fixture repo and runs the script from it.

## Out of scope

- Moving the backlog out of the working tree, or to a shared service. A much larger change than the
  hazard warrants.
- Detecting a second **clone**. Nothing in a clone distinguishes it from the primary without shared
  state outside the repo; the rule covers it.
- Relocating `.lock/` to the common git dir (rejected — see Notes).
- An override flag for running the scripts from a worktree. No caller needs one; add it when one does.

## Notes & decisions

- Recorded in AetherWorks' buffer 2026-08-25 (item 0051), and re-raised 2026-09-01 when `verify` gained
  a second worktree prescription.
- **2026-09-12 — design: option 3, both.** The scripts refuse from a linked worktree; `CONCURRENCY.md`
  states the rule for every second checkout and the skills cite it.
  - **Why not the rule alone (option 2):** the rule already exists — `142562e` (2026-09-01) put
    *must never claim, close or hand off* into `CONCURRENCY.md`'s e2e bullet — and the probe above
    shows what failing open costs here: a destroyed claim with a success message, in exactly the
    worktree the skills themselves create and remove. The shape the tools produce is the shape the
    tools should catch.
  - **Why not refusal alone (option 1):** a second clone passes the check (`--git-dir` equals
    `--git-common-dir` in a clone — observed), so the rule is the only thing covering it.
  - **Why not relocating `.lock/` to the common git dir:** the double grant in the probe was
    *sequential* — the worktree claim finished before the primary one began — so a shared lock would
    have serialised the two and granted both anyway. Each claim re-reads the row from its own
    checkout's `QUEUE.md`, which is the stale copy; the lock is not where the defect is.
  - **Accepted cost:** a person who deliberately runs the backlog from a linked worktree (their primary
    checked out on another branch) is refused and has to move. Fail-closed is the direction the
    scripts already take.
  - The existing sentence at `CONCURRENCY.md` *The working tree is shared too* was scoped to e2e;
    FR2 lifts it to its own section so `develop`'s worktrees can cite it too.
- **2026-09-12 — develop [7bf5].**
  - **Detection** compares `git rev-parse --path-format=absolute --git-dir` with `--git-common-dir`,
    so both sides are absolute and comparable; probed in a scratch repo from a subdirectory of both a
    primary and a linked worktree before building on it. The primary checkout named in the message is
    the first `worktree` line of `git worktree list --porcelain`.
  - **AC4 has no new case on purpose**: each suite's existing primary success case (`claim` AC1,
    `handoff` AC1, `close` AC1) exercises the new check and stayed green.
  - **AC5, as run here** (verify still owes its own): mutating `--git-common-dir)" ]; then` to
    `--git-dir)" ]; then` in each template (one line changed, diffed against a copy) reds exactly the
    6 assertions of that script's worktree case — claim 92/6, handoff 126/6, close 240/6 — and
    nothing else; restored byte-identical, control run 98/0, 132/0, 246/0.
  - **The NFR's guard citation was wrong.** `tests/retro-tool-edit.test.sh` windows
    `skills/retro/SKILL.md` Step 5, not `develop`'s; `worktree in the same turn` occurs only there.
    `develop`'s citation was added as its own line after the paragraph's last sentence anyway, so no
    guarded line was rewrapped.
  - **`item-ac-form.test.sh` was red on this item** from the design commit `470ba67`, which wrote the
    ACs as a numbered list `close` cannot tick. Converted to `- [ ] ACn —` with the wording unchanged.
  - **The worktree's copy of `.lock/`** is not reached by the refusal and needs nothing: the check
    runs before `mkdir`, so no refusal from a worktree ever creates one.
