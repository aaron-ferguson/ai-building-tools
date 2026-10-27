---
id: "0145"
title: Decide what an empty touches means to the scope report, and record it where the field is read
type: debt
next: verify
status: in-progress
qa_level: verify
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0050", "0029"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - skills/queue/templates/claim
  - skills/queue/templates/item.md
  - .claude/backlog/close
  - .claude/backlog/handoff
  - .claude/backlog/claim
  - references/CONCURRENCY.md
  - tests/close.test.sh
  - tests/handoff.test.sh
  - tests/claim.test.sh
ac_digest: AC1=d17c382c AC2=2d4130ed AC3=d3afa06b AC4=90afc7eb AC5=8f6b7035 AC6=65bde2f6 AC7=06419276 AC8=11c26142
claimed_by: "d31d"
claimed_at: 2026-10-27T02:54:34Z
touches:
---

## Problem

**An empty `touches:` suppresses the whole scope report, and which of the two readings that encodes
was never written down.** `scope_note()` returns early on `[ -n "$declared" ] || return 0`, with no
comment and no test in either direction, so the behaviour is an artefact rather than a decision.

The two readings give opposite answers:

- Under `references/CONCURRENCY.md`'s *The working tree is shared too* — "read an empty `touches:` on
  an `in-progress` row as *its files are held*" — empty means **everything**, nothing can be
  undeclared, and suppressing the report is correct.
- Under `0106` FR3 as worded, empty declared **nothing**, so every touched path is undeclared and the
  report should list them all.

Observed: a ticket with an empty `touches:` whose commits changed `src/undeclared.ts` closed with no
scope line at all.

This matters more than the size suggests, because `0106`'s own FR2 is what makes an empty `touches:`
the **normal** shape for a `verify` claim. So the report `0106` added is structurally silent on the
stage that does most of the closing, unless a session hand-populates the field — in a ticket whose
whole subject is that field meaning one thing.

## Functional requirements

- **FR1** — To the scope report in `close` **and** `handoff`, an empty `touches:` means **nothing was
  declared**. The `[ -n "$declared" ] || return 0` early return goes; every non-bookkeeping path the
  commits since the claim changed is reported as `scope: touched but undeclared:`. Where the range
  changed only backlog bookkeeping, the report prints
  `scope: nothing declared, and the commits since the claim changed only backlog bookkeeping`.
  The two copies of the block stay identical.
- **FR2** — An exclusive claim — `touches: "*"` written inline, or `"*"` / `*` as a list entry —
  covers every path in the scope report: nothing is undeclared, nothing is untouched, and the report
  prints `scope: exclusive claim — touches: "*" covers every path`. No new marker shape is added:
  *unset* (empty) and *claimed-the-tree* (`"*"`) are already different bytes.
- **FR3** — The decision is written where the field is read: a comment beside `scope_note()` in both
  scripts, and the `touches:` comment in `skills/queue/templates/item.md`, each saying that an empty
  value reads as *held* to a session deciding what to take and as *nothing declared* to the report
  at release, and that `"*"` is the exclusive claim.
- **FR4** — `references/CONCURRENCY.md`, *The working tree is shared too*, gains one sentence beside
  the empty-is-held rule: that rule answers a session choosing what to take; the release-time scope
  report answers what this pass changed, and reads empty as nothing declared. The ownership rule
  itself and every rule name are unchanged.
- **FR5** — `claim`'s message for a stage that does not build stops telling the session to "set it
  to what <stage> will write". It says the stage writes only its item and row, which the claim
  already holds, so `touches:` stays empty — and that the release will report any other path the
  pass's commits change.
- **FR6** — The report attributes to this ticket only the commits since its claim whose subject
  carries `[<token>]` or names the ticket id as a word (`0145`, `(0145)`, `0145's`). Other commits in
  the range are other sessions' work on a shared branch and are not reported as this ticket's. When
  any were left out, the report says how many, in one line:
  `scope: <n> commits since the claim name neither 0145 nor [<token>] and were not counted`.

## Acceptance criteria

- [ ] AC1 — Given a claimed ticket with an empty `touches:` whose commits since the claim changed
  `src/undeclared.ts`, when `close` closes it, then its output contains
  `scope: touched but undeclared: src/undeclared.ts`; and the same holds for `handoff`.
- [ ] AC2 — Given a claimed ticket with an empty `touches:` whose commits since the claim changed
  only its item file and `QUEUE.md`, when `close` or `handoff` releases it, then the output contains
  `scope: nothing declared, and the commits since the claim changed only backlog bookkeeping` and no
  `touched but undeclared` line.
- [ ] AC3 — Given a claimed ticket with `touches: "*"` inline, and another with `"*"` as its only
  list entry, each with commits changing `src/a.ts`, when `close` or `handoff` releases it, then the
  output contains `scope: exclusive claim — touches: "*" covers every path` and neither
  `undeclared` nor `untouched` appears.
- [ ] AC4 — Given the existing populated-`touches:` cases in `tests/close.test.sh` and
  `tests/handoff.test.sh`, when the suites run after the change, then every one still passes
  unchanged.
- [ ] AC5 — Given `skills/queue/templates/close`, `skills/queue/templates/handoff` and
  `skills/queue/templates/item.md`, when grepped, then each contains the line-unwrapped phrase
  `empty touches: means nothing declared` within its scope or field comment; and
  `references/CONCURRENCY.md` contains it in *The working tree is shared too*.
- [ ] AC6 — Given a row at `next: design` or `next: verify`, when `claim` takes it, then its output
  contains `touches: stays empty` and does not contain `to what design will write` or
  `to what verify will write`.
- [ ] AC7 — Given the installed scripts, when `tests/backlog-scripts-installed.test.sh` runs, then
  `.claude/backlog/close`, `handoff` and `claim` are byte-identical to their templates.
- [ ] AC8 — Given a claimed ticket with an empty `touches:`, whose range holds one commit
  `Fix it (<id>)` changing `src/mine.ts` and one commit `Claim 9876 [abcd]` changing another item
  file, when `close` or `handoff` releases it, then the output names `src/mine.ts` as undeclared,
  does not name the other item file, and contains `1 commits since the claim name neither`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | AC1–AC3 and AC6 are new cases in `tests/close.test.sh`, `tests/handoff.test.sh` and `tests/claim.test.sh`, each seen red before the fix | `testing-conventions.md` |
| Documentation | The decision is recorded beside every reader it changes (FR3, FR4), never only in this ticket | `documentation-conventions.md` |

## Out of scope

- How `./next`'s TAKE loop reads an empty `touches:` on a held row. `collision_report` compares
  against `touches:` alone, so an empty one collides with nothing — the reverse of the ownership
  rule. That is an ownership reader, not the attribution reader this ticket settles, so it is
  parked in FINDINGS.md for `queue` instead of being folded in here.
- Changing what `close` refuses. `0090` FR3 owns the refusals.
- Changing how `claim` seeds the field. That is the shape `0106` FR2 decided.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0106` that identified both readings and
  asked for the decision. Routed to `design` rather than `develop` because the park's own finding is
  that the behaviour is undecided, not that it is wrong — and `0106` reserved the question for
  whoever claims it, which no session has.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Related reading of empty `touches:` in the take loop, not only the scope report: `./next develop` printed `TAKE 0132` directly under a CLAIMED FILES line predicting `skills/orchestrate/SKILL.md` held by `0129` (empty touches), because the fourth takeability test compares against `touches:` alone. `CONCURRENCY.md` says an empty `touches:` means its files are held, so the take loop steers into the collision (develop 0107). Whatever this decides for the report should decide it for TAKE.
- **2026-10-06 (retro, run-20261004T232135Z tail, absorbed from FINDINGS.md).** A third reader disagrees, parked by design 0188 (2026-09-26): `./claim` on a design row prints "Set [touches:] to what design will write", but `skills/design/SKILL.md` never tells a design session to set `touches:`, and `CONCURRENCY.md` reads an empty `touches:` on an in-progress row as all files held — so read literally every design claim in a sprint blocks every other claim. 0188 sidestepped it by reading a design row's `expects:`. The decision this row takes should say what a design claim holds, and the claim message and the design skill should then agree with it.
- **2026-10-25 (design, token 6e1a) — decided: the two readings coexist by *reader*, not by stage,
  and the answer is the same for `close` and `handoff`.** `CONCURRENCY.md`'s "empty means held"
  answers a session deciding what it may take, where the safe default is to assume the files are
  held. The scope report answers what *this* pass changed against what it declared, where the safe
  default is to report. Silence is not permission, and silence is not agreement either. So, to the
  report, empty means **nothing declared** (FR1). The ownership rule is not revised; FR4 adds one
  sentence saying which question each reading answers.
  - *The `verify` claim is no longer silent.* Under 0106 FR2 a `verify` or `design` pass writes only
    its item and `QUEUE.md`, which the report already excludes as bookkeeping. So the normal case
    prints a positive "only bookkeeping" line (AC2), and a QA pass that edits code gets that code
    named (AC1). This needs no change to the field's default, which the question asked about.
    Seeding the field for non-building stages would have reversed 0106 FR2 and is out of scope.
  - *No third marker.* `"*"` already means "deliberately everything" (`CONCURRENCY.md`, *A change
    that touches every file takes an exclusive claim*). Observed 2026-10-25 by running
    `declared_touches`'s awk on fixtures: inline `touches: "*"` parses as **empty**, so today the
    report goes silent on an exclusive claim, and a list entry `- "*"` parses as the literal `"*"`,
    which covers no path. FR2 makes `"*"` cover everything in both shapes.
  - *Rejected:* (a) **empty means everything held**, i.e. keep the silence and only add a comment.
    That makes the report useless on most closes, which is the defect. (b) **Seed `touches:` for
    `verify`/`design`** with the item path. That reverses 0106 FR2, and the item is already excluded
    as bookkeeping, so it would buy nothing. (c) **A new explicit marker** such as `touches: none`.
    It adds a third shape every reader must learn, when the only shape missing a meaning was empty.
  - *What a design claim holds (the 2026-10-06 note):* only its item and row, which the claim
    already owns, so `touches:` stays empty. FR5 brings `claim`'s message into line. It is the
    message alone that tells a design session to set the field; `skills/design/SKILL.md` is silent
    on it and stays silent.
  - *Attribution (FR6), folded in from the 2026-10-25 FINDINGS park by design 0172.* The range is
    `claim^..HEAD` on a shared `main`, so it already blamed a concurrent session's item file on a
    hand-off with populated `touches:`. With FR1 alone, every empty-`touches:` release would list
    every concurrent path, and a note that is wrong on most closes teaches its reader to skip it.
    Observed in `git log` on 2026-10-25: work commits name their ticket as `(0169)`, `0110's` or
    `[9fa0]`, and lifecycle commits carry `[token]`. So filtering on subject is the attribution the
    history actually supports. *Accepted cost:* a commit that names neither is not counted. FR6
    makes that visible as a count instead of hiding it. *Rejected:* filtering on the token alone,
    because most build commits carry only the id.
  - *Criteria accounting:* the ticket arrived with no FRs or ACs. All of FR1–FR6 and AC1–AC8 are new.
    `qa_level: verify` and the missing `close_by` stand: this is a script change with
    fixture-testable criteria, closed by `verify`.

- **2026-10-26 (develop, token 9c30)** — Built in 3976882 (templates, item.md, CONCURRENCY.md,
  tests, CHANGELOG) and f875d73 (installed `.claude/backlog/{claim,close,handoff}`, byte-identical:
  `tests/backlog-scripts-installed.test.sh` 53 passed). Whole suite at f875d73: every file 0 failed.
  - **FR1/FR2/FR6:** the early return is gone. `declared_touches` now prints `*` for an inline
    `touches: "*"` (or `'*'` / `*`) and normalises a quoted `"*"` list entry. Before this change it
    dropped the inline value, so inline read as empty and the list entry was a literal `"*"`.
    `scope_note` short-circuits to the exclusive-claim line, then counts only the range commits whose
    subject carries `[token]` or the id as a word (`names_this_ticket`). It lists files per counted
    commit and appends the `<n> commits … were not counted` line when n > 0. The block is still
    byte-identical in `close` and `handoff`: the existing 0106 drift check is green.
  - **Ordering choice:** the exclusive-claim branch sits after the claim-commit lookup, so a claim
    with no claim commit still gets no report. That matches 0106's "no range, no report".
  - **FR5:** `claim` now says "`<stage>` writes only its item and row, which this claim already holds,
    so touches: stays empty — the release will report any other path the pass's commits change".
    The existing `does not build` assertion still holds.
  - **AC5** is guarded too, in `tests/close.test.sh` (`0145 AC5`): the phrase is in the three
    templates, and in CONCURRENCY.md inside *The working tree is shared too*.
  - **Clause table and mutations, all run** on the committed templates, mutated in both `close` and
    `handoff`, then restored with `git restore` (status empty afterwards):

    | AC clause | Guard | Mutation | close / handoff |
    |---|---|---|---|
    | AC1 empty touches: → `touched but undeclared: src/undeclared.ts` | 0145 AC1 cases | early return restored | 4 / 4 failed |
    | AC2 bookkeeping-only → `nothing declared, … only backlog bookkeeping` | 0145 AC2 cases | message blanked | 1 / 1 failed |
    | AC2 no `touched but undeclared` line | same | early return (also covers it) | as AC1 |
    | AC3 inline `"*"` → exclusive line | 0145 AC3 inline | inline parse removed | 2 / 2 failed |
    | AC3 list `"*"` → exclusive line, no undeclared/untouched | 0145 AC3 list | list normalisation removed | 3 / 3 failed |
    | AC3 exclusive line printed | both shapes | exclusive branch disabled | 2 / 2 failed |
    | AC8 other session's item not named | 0145 AC8 | every commit counted | 3 / 3 failed |
    | AC8 `1 commits since the claim name neither` | 0145 AC8 | count line suppressed | 1 / 1 failed |
    | AC6 `touches: stays empty`, not `to what <stage> will write` | `tests/claim.test.sh` 0145 AC6 (verify, design) | the pre-change template | 6 failed (the red before the fix) |
    | AC4 populated cases unchanged | existing 0106/0144 cases | (not mutated: no assertion text edited) | green |
    | AC5 phrase in four places | `0145 AC5` | reasoned: removing the phrase fails the `grep -qF` | — |
    | AC7 installed byte-identical | `tests/backlog-scripts-installed.test.sh` | reasoned: any byte difference reds it | — |

  - **Not this ticket:** `next`'s `fm_list` still reads an inline `touches: "*"` as no scope (a
    FINDINGS entry from 2026-10-26 already parks this; the TAKE loop is Out of scope here). A
    pre-existing unfalsifiable assertion in `tests/handoff.test.sh` (`grep` given `- src/two.ts` as
    an option) is parked in FINDINGS.md (85e576f).

## QA evidence

**2026-10-26 (verify, token d31d) — PASS.** Level `verify` (frontmatter; the item has no QA plan prose, so no drift).
Conventions: ../ai-building-conventions (resolved from `.claude/backlog/config.yml` `conventions.path`)
Commands: `tests/close.test.sh` → `304 passed, 0 failed`; `tests/handoff.test.sh` → `151 passed, 0 failed` (plus the pre-existing stray `grep` usage line on stderr, already parked at 85e576f); `tests/claim.test.sh` → `106 passed, 0 failed`; `tests/backlog-scripts-installed.test.sh` → `53 passed, 0 failed`. Whole suite per file (`for t in tests/*.test.sh; do "$t" || exit 1; done`, each file run so every file reports) at f1cd907, whose non-backlog tree equals the verified HEAD 72b6a26: 39 files, every one rc=0. No lint or typecheck configured. `ac_digest` matched.
Tree: `git status --porcelain` at Step 2 showed only this session's untracked `.verify-scratch/`; the same at verdict time. Intersection with the evidence set is empty → not advisory.
Mutations ran in a detached worktree at 72b6a26 via `.verify-scratch/sweep2.py` (not committed). Each had a non-empty diff and was restored by path. The control was green before and after on all four files, and worktree status was empty at the end. Copy executed: the repo templates in the worktree, plus the installed `.claude/backlog/*` copies for AC7. Live corroboration: this session's own `close 0172` and `close 0182`, both on an empty `touches:`, printed `scope: nothing declared, and the commits since the claim changed only backlog bookkeeping`, and `claim` printed `touches: stays empty`.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC1 | empty `touches:` → `touched but undeclared: src/undeclared.ts`, `close` **and** `handoff` | the 0106 early return `[ -n "$declared" ] || return 0` restored in both | red: close 300/4 failed, handoff `FAIL — names the path as undeclared` |
| AC1 | per script | early return in `handoff` only; in `close` only | red in each script's own suite |
| AC2 | bookkeeping-only line | message blanked | red, both suites (`says only bookkeeping changed`) |
| AC2 | no `touched but undeclared` line | bookkeeping exclusion removed | red, both (`and names nothing as undeclared`) |
| AC3 | inline `"*"` → exclusive line | inline parse removed | red, both (`inline: says the exclusive claim covers every path`) |
| AC3 | list `"*"` → exclusive line, no undeclared or untouched | list normalisation removed | red, both (3 failed each) |
| AC3 | exclusive line printed | exclusive branch disabled | red, both shapes in both suites |
| AC3 | neither `undeclared` nor `untouched` | exclusive branch falls through to the diff | red, both (`names nothing undeclared`) |
| AC4 | existing populated cases pass unchanged | 3976882 deletes no line of `tests/close.test.sh` or `tests/handoff.test.sh` (`git show … | grep '^-[^-]'` empty); both suites green | pass |
| AC5 | phrase in `close`, `handoff`, `item.md`, CONCURRENCY.md *The working tree is shared too* | phrase replaced in each of the four, separately | red, each (`… the phrase is missing or wrapped` / `missing, wrapped or moved`) |
| AC6 | `touches: stays empty`, not `to what <stage> will write`, for design **and** verify | message reverted; reverted for design only | red: 6 failed; 4 failed |
| AC7 | installed `close`, `handoff`, `claim` byte-identical | one-byte edit to each installed copy | red, each (`has diverged from skills/queue/templates/…`) |
| AC8 | names `src/mine.ts` | id not recognised (token only) | red, both (`names this ticket's path as undeclared`) |
| AC8 | does not name the other item | every commit counted | red, both (`does not name another session's item`) |
| AC8 | `1 commits since the claim name neither` | count line suppressed | red, both (`counts the commit it left out`) |
| NFR Testing | AC1–3, AC6 new cases, seen red before the fix | the pre-fix behaviour (early return; old claim message) restored → red, as above | pass |
| NFR Documentation | decision beside every reader (FR3, FR4) | read: `close`/`handoff` comment above `scope_note` names both readings and `"*"`; `item.md` `touches:` comment; CONCURRENCY.md sentence beside empty-is-held; AC5 guards hold | pass |

Always-on pass (CONVENTIONS_CORE): no secrets, no company material, no log or egress change; the reports are stdout only. Step 4, newly reachable: none. The report is a note, not a gate, and no refusal changed.
