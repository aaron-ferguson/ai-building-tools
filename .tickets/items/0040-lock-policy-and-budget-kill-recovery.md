---
id: "0040"
title: Harden the supervised loop against a held lock and a budget-killed stage
type: feature
next:
status: done
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent: "0036"
blocked_by: ["0039"]
expects:
  - skills/orchestrate/SKILL.md
  - tests/orchestrate.test.sh
  - .claude/backlog/config.yml
  - skills/queue/templates/config.yml
claimed_by:
claimed_at:
touches:
closed: 2026-09-08
---

## Problem

0039 delivers a loop that launches stage processes unattended. Two of its failure modes strand the
whole repository, and 0036's first draft mentioned neither.

**The lock.** `claim` and `close` take `.claude/backlog/.lock/`, and the supervisor's entire job is
launching processes that take it. **A stage killed holding the lock blocks every future claim and
close in the repo** — not just the run's. Two entries already in `FINDINGS.md` say the busy-lock
procedure strands a close and that the protocol cannot be satisfied by hand. Nothing in 0039 says
what the supervisor may do about a lock, and the tempting answer — break it and carry on — has a
driver silently stealing a lock from a stage that is still working.

**The spend cap.** `--max-budget-usd` is the blast-radius control AC19 requires, and it **creates**
the nastiest failure in the design: a stage killed mid-work leaves a claim held, a tree dirty,
possibly the lock taken, and a ticket half-built. 0039's AC16 covers the *supervisor* being killed,
which is a different and easier case — there the tree is clean. **Orphan detection is not enough on
its own: a dirty tree is not something `./next --drift` can see.** And the cap itself, guessed
rather than derived, is the thing that fires: this repo's observed figures are **USD 4.23 and
USD 5.71 per closed ticket** (`MEASUREMENT.md`, as at 2026-08-30 — corrected on 2026-09-08 from the
pre-2026-08-30 pair this ticket was written with, which that file names this id as still holding),
so a gate of three tickets under a USD 1 cap is a stage killed by arithmetic on its first run.

This is hardening on a loop that has to exist first, which is why it is the third slice rather than
folded into 0039.

## Functional requirements

**FR numbers are 0036's**, kept rather than renumbered so the review amendment in the parent still
resolves.

- **FR15 — The lock has a policy, and the supervisor never breaks it.** The supervisor takes the
  lock **never**, breaks it **never**, and **escalates on a lock older than a stated age**, naming
  the process that should have held it from 0039's FR10 log and dispatching nothing. The age is a
  key in `config.yml`, alongside the findings threshold, so it is one place rather than a number
  inside a skill.
- **FR16 — A stage killed by its own spend cap is a recoverable state, not a discovered one.**
  Three parts, each of which is a way for the cap to make things worse rather than safer:
  - **The cap is set from `cost_tracking:` history rather than guessed** — per stage and per gate
    size — and **the derivation is stated where the number is**, so the next person to change it
    knows what it was derived from rather than rounding it.
  - **An over-budget exit is one of the escalations**, routed like any other rather than read as a
    crash.
  - **The escalation names the claim token, the dirty paths and the lock state.** A human following
    it needs no information that exists only in the dead stage's transcript.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | The recovery path acquires no authority the loop did not already have: the supervisor does not remove a lock, does not release another session's claim, and does not clean a working tree it did not dirty. Every one of those is a human's action, and the escalation is what hands it over | `security-conventions.md` |
| Observability | The escalation lands on disk with a timestamp before it reaches the user, carrying the claim token, the dirty paths and the lock's age and holder. The supervising conversation is what dies; an escalation that reached only the transcript is unrecoverable | `observability-conventions.md` |

## Acceptance criteria

**AC numbers are 0036's.**

- [x] **AC25 — the supervisor never takes or breaks the lock.** Given a run at any point, when
  `.claude/backlog/.lock/` is inspected, then it was never created by the supervisor and never
  removed by it. **Given a lock older than the configured age with no live stage process**, when
  the supervisor acts, then it escalates, naming the lock's age and the process from the FR10 log
  that should have held it — and dispatches nothing. **Given a lock younger than that age**, then
  it waits rather than escalating, because a lock in use is the normal case and it is held for
  seconds.
- [x] **AC26 — a stage killed by its spend cap leaves a state the escalation describes.** Given a
  stage dispatched with a cap it exceeds mid-work, when it is killed, then the supervisor escalates
  with the ticket's claim token, the dirty paths and the lock state named — and starts nothing
  further. Given that escalation, when a human follows it, then no information needed to recover is
  only in the dead stage's transcript. **And the cap itself is derived, not guessed:** it is set
  from `cost_tracking:` history for the stage and gate size, and the derivation is stated where the
  number is.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`).
- **Why this level:** both requirements are about *state on disk that the supervisor reads and
  refuses to change*, and disk state is exactly what a fixture is. A stale `.lock/` directory with
  a written `held-by`, a claimed row whose process is gone, and a dirty tree are all constructible
  in a test; nothing here needs a real budget kill to exercise the response to one.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), and specifically —
  - **An aged-lock fixture and a fresh-lock fixture** (AC25), asserting escalate-and-dispatch-
    nothing in the first and wait in the second, plus an assertion that no code path in
    `skills/orchestrate/` removes `.lock` — a scripted grep, matched on a phrase short enough to
    stay on one line.
  - **A killed-stage fixture** — claim held, tree dirty, lock taken — asserting the escalation text
    names all three (AC26).
  - **A derivation assertion**: the cap in `config.yml` is accompanied by the `cost_tracking:`
    figures it was derived from, so a bare number fails (AC26).
  - **The pre-existing suite unchanged**, since nothing here alters what a hand-driven session does.

## Out of scope

- **Recovering the state itself** — releasing the claim, cleaning the tree, removing the lock.
  Every one of those is a human's action; this ticket makes the escalation sufficient to take it.
  Automating recovery is a separate decision, and the Security NFR is why.
- **Changing `claim`, `close` or the lock protocol.** The supervisor lives with the lock as built.
  If the protocol itself needs to change, that is a ticket against `CONCURRENCY.md`, not this one.
- **Setting the cap** — 0039's AC19 does that. This ticket makes it *derived* rather than guessed,
  and owns what happens when it fires.
- **Concurrent stage sessions**, which would make the lock a contention problem rather than a
  stranding one. Out of scope for the whole project; see 0036.

## Notes & decisions

- **The reasoning behind both requirements is in
  `items/0036-orchestrate-the-stage-sessions.md`, *Notes & decisions*, review amendment of
  2026-08-24** — the four things nobody had thought through — and is not restated here.
- **Third of three slices, and it stays third.** Both requirements are responses to a loop's
  behaviour, and neither is testable before the loop exists. But it should not be allowed to drift:
  0039 shipped without this is a runnable unattended loop with no lock policy, which is exactly the
  hazard FR15 exists for. It is ranked directly below 0039 for that reason and not merely by
  dependency order.

### Built 2026-09-08, claim `ef8e`

**The lock's age cannot come from `held-by`, and that is the one thing a session would get wrong
here.** `claim:81` writes `claim <id> by <token>` and no timestamp; `close:71` and `handoff:112`
both write one. So the *commonest* holder of the lock — a claim — is exactly the one a timestamp
read cannot see, and a supervisor prescribing that read would work in every test against a
close-held lock while silently calling every claim-held lock ageless. `CONCURRENCY.md`'s *Lock
every write* says to put a timestamp there, so the protocol and the script already disagree and
nothing was reading the field closely enough to notice. The age comes from the lock **directory's**
mtime, which `mkdir` sets on every path. Repairing `claim` is *Out of scope* here and sits next to
item 0047; **it still needs a row and does not have one** — parked in `FINDINGS.md`.

**The guard runs the prescribed check rather than grepping for it**, which is what makes the above
falsifiable: an aged fixture, a fresh one and no-lock-at-all, with the aged fixture's `held-by`
written in `claim`'s shape. Swapping the mtime read for a `held-by` read reds on the *fresh*
fixture, calling a lock taken a second ago aged — verified by mutation, with four others.

**AC26's subject did not exist.** It asserts "the cap in `config.yml`" while *Out of scope* assigns
setting the cap to 0039, which delivered it as a prose sizing instruction in Step 3 and no key. The
derivation assertion has no subject without the key, so the key is added here — that is what "makes
it derived rather than guessed" requires, and it is not the same act as choosing the number.

**`NF == 8` is not a table selector.** The first derivation guard read MEASUREMENT.md's per-stage
figures by pipe-field count and returned **74,970** — the context-token table's mean, two tables
below the one intended — as though it were a dollar figure. Every citation resolved and the
arithmetic stayed self-consistent. Now the table is selected by its header and the **column index
is read from that header**, so adding a column cannot silently move what is read.

**A `$` followed by a digit in skill prose is substituted before the session sees the file**
(`tests/money-in-skill-prose.test.sh`). The lock-age block was first drafted with an awk field
reference that `/orchestrate 0040` would have delivered as `print 00402`. A `sed` substitution
avoids the class. Step 3's grep for the project's own guards is what caught it, ahead of the guard.

**Over the size goal by ~900 bytes, recorded rather than cut.** Payback test (`skill-size.test.sh`):
B is about 2,100, giving p = 89%, and Step 7 is read by every run before it dispatches anything, so
(a) is not cleared; the policy is mandatory the moment a lock is met, so (b) fails outright. Both
fail, relocation is rejected, and the justification is recorded.

**Two reds in the tree are not this ticket's.** `tests/measurement.test.sh`'s privacy NFR fails on a
home-directory path in `items/0060` and in the untracked `items/0111`. At this ticket's base commit
`fb481a0` that file carried none; the path arrived in `b9d11af`, which landed *after* this ticket's
implementation commit. Another session's, reported rather than touched — but worth its own row,
because **this repo is public** and the guard is a privacy NFR.

**Not done here:** `cost_tracking:` is not configured in this backlog, so no cost was recorded, and
`stage_budget_usd` is derived from `MEASUREMENT.md` instead — the same history by another route,
and what the config comment cites.

## QA evidence

Verified 2026-09-08, claim `ae47`, at `qa_level: unit` — the whole `tests/` suite, run file-by-file
rather than fail-fast per `config.yml`'s attribution note. Frontmatter level and the QA plan's
`**Level:** unit` agree, so no drift to report. The **repo** copy is the authority and is what the
guards read (`ROOT`); the session itself ran the installed plugin at **0.9.17**, one version behind
the repo's 0.9.18, and `skills/orchestrate/SKILL.md` is among the four files that differ between
them — so this verdict is about the repo copy, not the copy that executed.

| Criterion | How it was checked | Result |
|---|---|---|
| **AC25** — never takes or breaks the lock | Direct state read of every fenced block in `skills/orchestrate/`: the only lock operations are `[ -d "$LOCK" ]` and `stat`; both `mkdir`s target `runs/`, not the lock. Guard `no fenced block ... removes the lock` reds on an inserted literal remover (M2b) | **pass** |
| **AC25** — aged lock escalates, names the age, dispatches nothing | The prescribed block is *extracted and run* against three authored fixtures. Aged (mtime 2026-01-01, `held-by` in `claim`'s no-timestamp shape) → `aged 1788876767`, so the age is named. Prose guards for `dispatches nothing` and `run log` both red under mutation | **pass** |
| **AC25** — younger lock waits | Fresh fixture → `fresh <age>`; no-lock fixture prints nothing and decides nothing. `waits rather than escalating` reds when reworded (M3) | **pass** |
| **AC25** — the age is config, not a number in a skill | `lock_stale_seconds: 900` in `.claude/backlog/config.yml` and in `skills/queue/templates/config.yml`; removing either reds (M4, M8) | **pass** |
| **AC26** — escalation names claim token, dirty paths, lock state | Three separate `says` assertions over Step 7. `the dirty paths` reds when reworded — and note the phrase spans a line break in the source, which matches only because `section()` flattens the section with `tr '\n' ' '` (M5) | **pass** |
| **AC26** — over-budget exit routed, run stops | `not read as a crash` and `starts nothing further` both red when reworded | **pass** |
| **AC26** — the cap is derived, and the derivation is stated beside it | `stage_budget_usd` present in config and template; template ships the key with the instruction and no figure (a planted figure reds). Every cited mean checked against MEASUREMENT.md's `$/session` table by header-derived column: develop 4.03, verify 3.63, retro 2.51 — all three match, and rounding one citation reds (M6) | **pass, with a gap** |
| **Security NFR** — no authority the loop lacked | Step 7 assigns releasing the claim, cleaning the tree and removing the lock to a human; Step 8 states it never claims a row or mints a token | **pass** |
| **Observability NFR** — escalation on disk, timestamped, before the user | Step 7 states it lands in the run log timestamped before it reaches the user, carrying token, dirty paths and lock state. Prose is the artifact here; the timestamp half carries no guard of its own | **pass, unguarded** |
| Always-on conventions (`CONVENTIONS_CORE.md`) | Public-repo/privacy pass over the four touched files: no home-directory path, no company material. Build notes record the learning in-change | **pass** |

**Mutations re-run rather than taken on trust** (the build notes' table was not accepted as
evidence): 11 in total, each confirmed to land by a non-empty diff and each restored by pathspec,
with a green control run at the end (130 passed, 0 failed). The headline one holds — swapping the
directory-mtime read for a `held-by` timestamp read reds on the **fresh** fixture (`aged
1788876767`), calling a lock taken a second ago aged, exactly as recorded.

**Two mutations did not redden, and are published rather than papered over** (`verify` Step 3):

- `rm -rf "$LOCK"` in a fenced block — the skill's own idiom — leaves the suite at 130 passed; so
  does a path built through a variable. Only the literal `.lock` spelling reds. The delivered prose
  is clean either way, so AC25 is verified on state; the coverage is what is thin.
- `retro: 99.00`, citation left intact, leaves the suite at 130 passed. The cap's *figure* is
  unguarded; only its citation is. The shipped figures are self-consistent under mean x 1.5 rounded
  to the nearest five cents, but that granularity is unstated, so a literal RECOMPUTE gives 6.04
  and 3.76.

Both are parked in `FINDINGS.md` (commit `bb9a16c`) and **still need rows**; neither is a defect in
what this ticket delivered.

**Pre-existing red, not this ticket's.** `tests/measurement.test.sh` — *Privacy & data NFR* — fails
on home-directory paths in `FINDINGS.md`, `items/0060` and `items/0111`. `git log -S` dates the path
to `b9d11af`, which landed after this ticket's implementation commit `5c16447`, and the guard is
green at `5c16447` in a detached worktree (106 passed, 0 failed). Reported, not touched. It is
already in `FINDINGS.md` and **still needs a row** — this repo is public and the guard is a privacy
NFR. Every other file in the suite is green.

**Tree state.** Clean at Step 2 and clean again at verdict time, so the intersection with this
run's evidence set is empty and the verdict is not advisory.

