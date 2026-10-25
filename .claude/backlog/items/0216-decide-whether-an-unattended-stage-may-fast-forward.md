---
id: "0216"
title: Decide whether an unattended stage may fast-forward a clean checkout that is only behind
type: feature
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: s
created: 2026-10-25
source: agent
parent:
blocked_by: []
relates: ["0177", "0113"]
expects:
  - references/CONCURRENCY.md
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - tests/remote-anchor.test.sh
  - CHANGELOG.md
claimed_by: "60da"
claimed_at: 2026-10-25T17:39:55Z
touches:
---

## Problem

**An unattended sprint tail lost a whole pass over the tools buffer because the tools checkout was one
commit behind `origin/main` — and the only commit it lacked was another session's backlog capture.**

Parked in AetherWorks `FINDINGS.md` on 2026-10-24, during run-20261024T195310Z, verbatim:

> An end-of-sprint retro told to sweep the tools buffer could not write to the tools repo: its
> checkout was 1 commit behind `origin/main`, because another session pushed a capture (0214, moving
> `next_id`) during the run. `retro` Step 3 stops on behind and leaves the pull to the user, so the
> 16-entry tools buffer was triaged and nothing was written. That costs a second pass on the same
> entries. The skill's cluster-and-defer guidance assumes it can at least mark entries `[->none]`,
> and here it could not. Either the sprint tail fetches and fast-forwards a clean, behind-only tools
> checkout before dispatching retro, or retro may fast-forward when the tree is clean and the remote
> commits touch only `.claude/backlog/`.

The second pass did happen (`ec5458e`, `cabe7cf`), so the cost was real and paid: the same 16
entries were read twice.

Where the stop comes from. `skills/retro/SKILL.md` Step 3: *"Behind the remote stops the pass, and
the pull is the user's call because that choice is theirs (`git-conventions.md`)."*
`skills/develop/SKILL.md` has the same stop at *"Fetch before you claim, and stop if you are behind"*.
**`git-conventions.md` contains no rule about pulling** — checked 2026-10-25, its only match for
`pull` is the collaborative-mode pull-request line — so "the user's call" is the skills' own rule,
and this ticket may change it without amending a convention.

**Why `0177` does not cover this.** `0177` answers what an unattended pass does when it *cannot*
pull: continue over the current repos, leave the stale repo's findings undispositioned, report. That
answer is exactly what produced this second pass. `0177`'s *Out of scope* names this question
explicitly — *"Letting any session pull on the user's behalf"* — so it is a separate decision, now
with a measured cost. `0177` stays needed either way: a diverged or dirty checkout still has nothing
safe to fast-forward.

## Functional requirements

- FR1 — **One rule, in `references/CONCURRENCY.md` Part 1, under the heading *A behind checkout
  fast-forwards only over backlog commits*.** A session that fetched and found its checkout behind
  fast-forwards it when, and only when, all of these hold, checked and acted on under the backlog lock
  (`.claude/backlog/.lock/`) in one shell invocation: a clean working tree (`git status --porcelain`
  prints nothing); ahead of nothing (`git rev-list --count @{u}..HEAD` is 0); every incoming path
  under `.claude/backlog/` (`git diff --name-only HEAD @{u}`); and the merge is `git merge --ff-only @{u}`.
  Any precondition failing leaves today's stop exactly as it is (and `0177`'s answer for it).
- FR2 — **The performer is the stage, at the fetch it already makes** — `retro` Step 3 per repo it
  will edit, `develop`'s fetch-before-claim. The `sprint` supervisor fetches and fast-forwards
  nothing, and `skills/sprint/SKILL.md` is not edited.
- FR3 — **Attended and unattended alike**, said in so many words in the rule (FR4 of the provisional
  list asked for exactly that sentence if the attended behaviour changes; it does).
- FR4 — **Reported, never silent:** the stage's report names the repo, the SHA before and after, and
  the incoming paths. A pass that fast-forwarded and does not say so is a defect.
- FR5 — `retro` Step 3 and `develop`'s fetch paragraph each **cite the rule by its heading and
  restate none of its preconditions**; the stop on every other behind state stays in each, worded so
  the pull outside the rule is still the user's call.
- FR6 — `tests/remote-anchor.test.sh` guards the rule's clauses in the CONCURRENCY.md section's
  window, the citation in each stage window, the absence of the restated precondition from each
  stage window, and one falsifying fixture.
- FR7 — `CHANGELOG.md` `## Unreleased` carries one note: a behind checkout whose incoming commits are
  backlog-only is now fast-forwarded and reported instead of stopping the pass.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | One definition in `CONCURRENCY.md`, cited by heading from `retro` and `develop`; neither restates a precondition | AC6 — `every incoming path under` found in a stage window | `documentation-conventions.md` |
| Observability | A fast-forward on the user's behalf reaches the report with repo, before/after SHA and incoming paths | AC3 — the report clause missing from the rule's window | `observability-conventions.md` |
| Size | `retro` and `develop` stay inside `tests/skill-size.test.sh`'s caps — the citation replaces words, it does not add a paragraph | AC8 — `tests/skill-size.test.sh` red | `CONVENTIONS_CORE.md` (every rule pays rent) |

## Acceptance criteria

- [ ] AC1 — Given `references/CONCURRENCY.md`, when the window opening on the heading `A behind checkout fast-forwards only over backlog commits` is read, then it holds each of `clean working tree`, `ahead of nothing`, `every incoming path under`, `--ff-only` and `under the backlog lock`, each on one source line, and the window is non-empty.
- [ ] AC2 — Given that same window, when it is read, then it names the performer with `the stage that fetched` and says `attended and unattended alike`.
- [ ] AC3 — Given that same window, when it is read, then it requires the report to carry `the SHA before and after` and `the incoming paths`.
- [ ] AC4 — Given `retro` Step 3's existing window in `tests/remote-anchor.test.sh`, when the suite runs, then the window cites `A behind checkout fast-forwards only over backlog commits`, still holds `Behind the remote stops the pass`, and the old case `the pull is the user` is replaced by name with `any other pull is the user`.
- [ ] AC5 — Given `develop`'s fetch window, when the suite runs, then it cites `A behind checkout fast-forwards only over backlog commits`, still holds `Behind the remote stops the session`, and holds `any other pull is the user`.
- [ ] AC6 — Given the `retro` Step 3 and `develop` fetch windows, when the suite runs, then neither contains `every incoming path under` — the precondition lives only in `CONCURRENCY.md`.
- [ ] AC7 — Given a fixture copy of `retro` Step 3 that says to fast-forward but omits the citation, when the citation case runs against it, then it fails; the fixture is part of the suite and the suite reports it as a passing negative.
- [ ] AC8 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it exits 0, including `tests/remote-anchor.test.sh`, `tests/citations.test.sh` and `tests/skill-size.test.sh`.
- [ ] AC9 — Given `CHANGELOG.md`, when `## Unreleased` is read, then it carries one note that a behind checkout whose incoming commits are backlog-only is fast-forwarded and reported rather than stopping the pass.

## QA plan

- **Why that level:** the result is a prose rule in a shipped reference and two skills, guarded by this
  repo's shell suite (`unit` in `config.yml`), the only runner the project has.
- **Specific checks:** `tests/remote-anchor.test.sh` (AC1–AC7), `tests/citations.test.sh`,
  `tests/skill-size.test.sh`, then the whole suite (AC8); read `CHANGELOG.md` for AC9.

## Out of scope


- What a pass does when it cannot fast-forward (diverged, dirty, or the decision says no) — that is
  `0177`.
- `tools/release`'s behind-the-remote refusal (`0075`, `0084`), which guards a push, not a pull.
- Pulling the plugin install or the marketplace clone, which are never edited
  (`references/CONVENTIONS.md`, *Routing a finding to the repo it is about*).

## Notes & decisions


- **2026-10-25 (queue sweep, run-20261024T195310Z tail)** — Filed from the one AetherWorks
  `FINDINGS.md` entry left after that run's retro. Routed to `design`, not `develop`: the entry
  itself offers two incompatible fixes, and choosing which session may change the user's checkout
  is a decision, not a fact readable from the code. Ranked directly above `0177` because the answer
  decides how much of the paragraph `0177` edits survives — settling it first avoids rewriting
  retro Step 3 twice. Not made a blocker of `0177`: `0177`'s FRs hold whatever this decides.
- **2026-10-25 (design)** — **Decided: yes, a stage may fast-forward a clean checkout that is only
  behind, when every incoming path is under `.claude/backlog/`; the stage does it at its own fetch,
  attended or not, under the backlog lock, and reports it.** The question had three parts:
  - *May it at all?* Yes. The stop's own stated reason, in both `retro` Step 3 and `develop`, is that
    *resolving divergence* can mean choosing between two of the author's commits. A `--ff-only` over a
    clean tree that is ahead of nothing chooses nothing, so the reason never covered this case — the
    stop was wider than its justification. `git-conventions.md` has no pull rule (re-checked
    2026-10-25: its only `pull` match is line 61, the collaborative-mode pull-request line).
  - *(a) Backlog-only, not any commits.* Chosen because **the backlog is the one tree every session
    already expects to change under it**: `CONCURRENCY.md` makes it multi-writer under a lock, so a
    fast-forward there is the same event as another session's `./claim` landing. Code and skill
    files have no such protocol — the shared working tree means a fast-forward of `skills/**` or
    `tests/**` changes files under a sibling `develop` mid-cycle, which a clean tree rules out only at
    that instant. It covers the observed case exactly: re-checked 2026-10-25, `8dd00ea` (the 0214
    capture) touched only `.claude/backlog/` (`QUEUE.md`, `RANKING.md`, `config.yml`, one item), and
    every `Capture` commit since 2026-10-01 touched nothing outside it. **Rejected: any commits** —
    would also cover a skill edit landing mid-run, but that is the case where the stale-tree rule
    earns its keep and the shared-tree hazard is real; it would win only if sessions ran in separate
    checkouts, which `CONCURRENCY.md` (*A second checkout never writes the backlog*) forbids for writers.
  - *(b) The stage, not the supervisor.* The observed commit landed **during** the run, so the check
    must sit at point of use; a supervisor fast-forward before dispatch leaves the window between it
    and the stage's own fetch open, and the supervisor would have to re-derive which repos a retro
    resolves (conventions ladder, `tools.path`), duplicating `retro`'s resolution. The fetch already
    lives in the stage; adding the fast-forward there is one cited sentence per stage. **Rejected:
    supervisor-side** — would win if stages could not be trusted to hold the lock, but they already
    hold it for every backlog write. `skills/sprint/SKILL.md` drops out of `expects:`.
  - *Attended too.* No stage can tell which mode it runs in — re-checked 2026-10-25, neither
    `skills/retro/SKILL.md` nor `skills/develop/SKILL.md` contains `unattended` — so a mode-gated rule
    would need a detector that does not exist. Same rule both ways, stated in so many words.
  - **Trade-off accepted:** an attended user no longer gets the stop-and-ask for a backlog-only
    behind; they get the report line instead. And a retro still stops when a skill edit lands
    mid-run — that remains `0177`'s case, which this does not shrink to zero.
  - **Lock is required, not decorative:** a fast-forward rewrites `config.yml` and item files, which
    is a write to the backlog directory under *Lock every write to the backlog directory*; without it
    the fast-forward can interleave with a sibling's `./claim` read-modify-write.
  - **Criteria accounting:** the queue-written provisional FRs are replaced. Provisional FR1 is
    confirmed and narrowed (precondition fixed at backlog-only, performer fixed at the stage, lock
    added). FR2 confirmed, with `sprint` removed as a citer. FR3 confirmed (now FR4). FR4 *changed*:
    attended behaviour changes too, said explicitly (FR3). FR5 confirmed, with `the pull is the user`
    replaced by name (AC4). Added: FR6's no-restatement and falsifying-fixture checks, FR7's changelog
    note, and the Size NFR. `qa_level: unit` and `close_by: verify` re-read against the ACs: both hold.
- 2026-10-25 — develop (3c97): **built** in `510f52d`.
  - The rule sits in `CONCURRENCY.md` Part 1, between *A second checkout never writes the backlog*
    and *A change that touches every file*; `retro` Step 3 and `develop` Step 1 cite it by heading,
    keep `Behind the remote stops the pass|session`, and say `any other pull is the user's call`.
    `sprint` is not edited (FR2). The old `the pull is the user` case is renamed in place, and the
    leak fixture's text and phrase list moved with it so that probe still means something.
  - **`window()` in `tests/remote-anchor.test.sh` could not open a window whose end regex matches its
    own heading** — `first` was never set, so `!first` was true on the opening line and the window
    closed at once (the class 0089 records for `falsifiable-acs.test.sh`). The CONCURRENCY window
    needs `^## ` as its end, so `first = 1` is now set on the opening line. Existing windows' end
    regexes never matched their headings, so their behaviour is unchanged — run: 22 pre-existing
    cases still pass.
  - **Mutation sweep — run**, scratch copy, one per clause: each of the five AC1 phrases, both AC2
    phrases, both AC3 phrases, each stage citation, develop's `any other pull`, a restated
    `every incoming path under` in each stage window (AC6), and the rule heading renamed (empty
    window, named). Every one reddened exactly its own case (34/1); the heading rename reddened all
    nine CONCURRENCY cases as EMPTY. AC7 is the `uncited-ff.md` fixture, reported as a passing negative.
  - Clause table (AC text → guard): `clean working tree`, `ahead of nothing`, `every incoming path
    under`, `--ff-only`, `under the backlog lock` → 0216 AC1 ×5; `the stage that fetched`, `attended
    and unattended alike` → AC2 ×2; `the SHA before and after`, `the incoming paths` → AC3 ×2;
    rule heading in W3, `Behind the remote stops the pass`, `any other pull is the user` → AC4 (the
    second is the pre-existing AC1 case); heading, `Behind the remote stops the session`, `any other
    pull is the user` in WD1 → AC5 (the stop is the pre-existing FR1 case); `every incoming path
    under` absent from W3 and WD1 → AC6 ×2; uncited fixture → AC7.
  - CHANGELOG note written here (AC9 is checked before the close), so **verify: do not pass
    `--note`**. Sizes, measured: `develop` +111 bytes,
    `retro` +129, `CONCURRENCY.md` +963; `skill-size` and `reference-size` green.


## QA evidence

2026-10-25 — verify (60da). **PASS.**

Conventions: ../ai-building-conventions
Command (`commands.unit`, verbatim): `for t in tests/*.test.sh; do "$t" || exit 1; done` — run at `b5f8f7d`, clean tree, **exit 0** (all 34 files). The by-file form ran earlier at `0b85f60` (same non-backlog tree): every file `0 failed`, including `remote-anchor` `35 passed, 0 failed`, `citations` `46 passed, 0 failed`, `skill-size` `27 passed, 0 failed`, `reference-size` `15 passed, 0 failed`.
Copy executed: repo copies (`references/CONCURRENCY.md`, `skills/{retro,develop}/SKILL.md`); the installed 0.9.42 plugin predates this change.
Digest: `.claude/backlog/next --ac-digest 0216 --check` → `0216: ac_digest absent — unverifiable`. Recorded as **ac_digest absent — unverifiable**, not a match.

Mutations: re-run by this pass in a detached worktree at `b5f8f7d`, each restored by path, worktree clean afterwards; control `35 passed, 0 failed`. Each phrase mutation below gave `34 passed, 1 failed`, naming its own case.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | `clean working tree` | phrase reworded in `references/CONCURRENCY.md` | red, own case |
| AC1 | `ahead of nothing` | reworded | red, own case |
| AC1 | `every incoming path under` | reworded | red, own case |
| AC1 | `--ff-only` | reworded | red, own case |
| AC1 | `under the backlog lock` | reworded | red, own case |
| AC1 | window non-empty | heading renamed | red, `26 passed, 9 failed`, every CONCURRENCY case `EMPTY` |
| AC2 | `the stage that fetched` / `attended and unattended alike` | each removed | each red, own case |
| AC3 | `the SHA before and after` / `the incoming paths` | each removed | each red, own case |
| AC4 | retro W3 cites the heading | citation replaced in `skills/retro/SKILL.md` | red, `0216 AC4` |
| AC4 | `Behind the remote stops the pass` | reworded | red, `AC1 — being behind stops the pass` |
| AC4 | `the pull is the user` replaced by `any other pull is the user` | reworded; `grep` finds no `the pull is the user` in `tests/remote-anchor.test.sh` | red; old case gone |
| AC5 | develop WD1 cites / `stops the session` / `any other pull is the user` | each reworded in `skills/develop/SKILL.md` | each red, own case |
| AC6 | `every incoming path under` absent from W3 and WD1 | phrase inserted into each window | each red, own case |
| AC7 | uncited fixture stays red | citation inserted into the `uncited-ff.md` fixture | red, `an uncited fast-forward satisfied the citation case` |
| AC8 | whole suite exits 0 | configured fail-fast command | exit 0 |
| AC9 | one `## Unreleased` note | read `CHANGELOG.md`: the `develop` and `retro` fast-forward note (0216) | present, one note |

NFRs:

| Row | Check | Result |
|---|---|---|
| Documentation | AC6 mutations | holds, guarded |
| Observability | AC3 mutations | holds, guarded |
| Size | `tests/skill-size.test.sh` `27 passed, 0 failed`, `tests/reference-size.test.sh` `15 passed, 0 failed` | holds, guarded |

Newly reachable: a session now runs `git merge --ff-only` without asking. The rule limits it to a clean tree, ahead of nothing, backlog-only incoming paths, under the lock, and it must be reported. `--ff-only` cannot discard or rewrite local work, which is consistent with `git-conventions.md` (nothing destructive).
Always-on (`CONVENTIONS_CORE.md`): no secrets, no company material, one definition cited by heading.
Advisory: Step 2 dirty set empty; verdict-time capture empty; intersection empty → not advisory.
