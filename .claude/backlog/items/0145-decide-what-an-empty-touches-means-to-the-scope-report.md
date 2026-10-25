---
id: "0145"
title: Decide what an empty touches means to the scope report, and record it where the field is read
type: debt
next: design
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
claimed_by: "6e1a"
claimed_at: 2026-10-25T22:38:38Z
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
