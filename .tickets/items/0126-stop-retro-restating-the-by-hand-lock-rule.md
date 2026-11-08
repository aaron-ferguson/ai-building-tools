---
id: "0126"
title: Stop retro restating the by-hand lock rule it drifted from
type: bug
next:
status: done
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0048", "0091"]
expects:
  - skills/retro/SKILL.md
  - tests/retro-lock-citation.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-10-27
---

## Problem

**`retro` Step 4 restates `CONCURRENCY.md`'s by-hand-lock rule and drops half of it, and the half it
drops is the one a real absorption pass needs.**

`references/CONCURRENCY.md:159` permits two forms: *"Run the whole sequence in one call, or drop the
trap and `rm -rf` explicitly at the end."* `skills/retro/SKILL.md:225` carries only the first —
*"Read, write, commit and release in **one shell invocation**"* — and then gives the reference's own
reason for it, which is that a `trap ... EXIT` releases on the call's return. That reason constrains
the **trap**, not the invocation count, so the rule and the reason printed beside it disagree.

The cost is not theoretical. The retro pass of 2026-09-09 appended dated notes to eight items,
created ten item files, edited `config.yml` and `QUEUE.md`, drained `FINDINGS.md` and committed. One
invocation carrying all of that is a blob nobody can review before approving. That pass took the
lock with a plain `mkdir`, held it across several calls and released explicitly — the reference's
**second** permitted form, correct under the authority the step cites and forbidden by the step
itself. A session reading Step 4 literally has two options and both are wrong: write the
unreviewable blob, or believe the absorptions must be skipped.

This is the *cite, never restate* failure with a receipt. The copy drifted from source; the copy is
what the sweeper reads; and nothing reported it, because a restatement that is merely **incomplete**
reads as correct on its own.

## Functional requirements

- FR1 — `retro` Step 4's lock paragraph cites `CONCURRENCY.md` *Lock every write to the backlog
  directory* for the permitted by-hand forms and enumerates none of them itself, so there is one
  home for the rule and nothing to drift.
- FR2 — What Step 4 keeps is only what is true of `retro` and of no other stage: that it holds no
  claim token, so its writes are visible by the lock alone, and that draining `FINDINGS.md` and
  appending to an unheld item are both inside the boundary.
- FR3 — A guard executes FR1 and FR2 against Step 4's window rather than against the whole file,
  since `trap`, `lock` and `invocation` are ordinary words elsewhere in this skill and a file-wide
  grep stays green on a rule moved out of the step that must obey it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule keeps one home — `CONCURRENCY.md` — and `retro` cites it; the incident behind the second form stays in `CONCURRENCY-INCIDENTS.md` | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/retro/SKILL.md` Step 4's lock paragraph, when `tests/retro-lock-citation.test.sh`
  searches that window for the literal `one shell invocation`, then it is not found. Red-making
  input: today's file, which carries the phrase at line 225.
- [x] AC2 — Given the same window, when `tests/retro-lock-citation.test.sh` reads it, then it names
  `CONCURRENCY.md` and the section title `Lock every write to the backlog directory`. Red-making
  mutation: deleting the section title from the citation, leaving the bare filename.
- [x] AC3 — Given the same window, when `tests/retro-lock-citation.test.sh` reads it, then it
  contains neither of the reference's two permitted forms — no `in one call` and no `drop the trap`.
  Red-making mutation: pasting `or drop the trap and rm -rf explicitly at the end` into the
  paragraph, which is the plausible cheap fix this item rejects.
- [x] AC4 — Given a fixture carrying every asserted phrase **outside** Step 4's window, when
  `tests/retro-lock-citation.test.sh` runs against it, then it fails — proving the scoping in FR3 is
  real and not a file-wide grep wearing a window's name. Red-making input: widening the guard's
  window to the whole file, which turns that fixture green.
- [x] AC5 — Given the edited skill, when `tests/citations.test.sh` and `tests/skill-size.test.sh`
  run, then each reports `0 failed`. Red-making change: citing a section title that does not exist
  in `CONCURRENCY.md`.

## QA plan

- **Why that level:** the artifact is one paragraph of skill prose and one reference it points at;
  every criterion is a scoped grep, and there is no runner in this project that reaches skills.
- **Specific checks:** run `tests/retro-lock-citation.test.sh`, `tests/citations.test.sh` and
  `tests/skill-size.test.sh` individually — never through the `unit` command, which is fail-fast
  and will stop at another session's red before reaching them (`config.yml`).

## Out of scope

- The five other park steps that never mention the lock at all. That is `0091` FR1, and it is a
  different defect: an omission rather than a drifted copy.
- Whether the by-hand write becomes a script (`0048`).
- `CONCURRENCY.md` itself, which already states both forms correctly.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

Independent verify, token fa1b, 2026-10-27, after `./reopen` (the 02150de close was self-certified by
develop session 3b05). Subject: working tree at `8c8d609` (built in `c625f6b`), clean at Step 2 and at
verdict — dirty set empty, so the intersection with the evidence set is empty: **not advisory**.

Conventions: ../ai-building-conventions

Level: `qa_level: verify` (frontmatter; the QA plan agrees). Commands run, verbatim, individually as
the QA plan requires: `tests/retro-lock-citation.test.sh`, `tests/citations.test.sh`,
`tests/skill-size.test.sh`. No lint/typecheck is configured for this repo.
`./next --ac-digest 0126 --check`: `ac_digest absent — unverifiable`.
Copy executed: the repo copy is the subject (a skill change is not live until released); the guards
read `skills/retro/SKILL.md` in this checkout.

Tallies, pasted: `13 passed, 0 failed` · `51 passed, 0 failed` · `45 passed, 0 failed`.

Clause table and mutations — every one run by this session on the committed real file (not the
guard's own fixtures), restored by path, control green after:

| AC | Clause | Mutation (applied to the real file) | Result |
|---|---|---|---|
| AC1 | Step 4 window lacks `one shell invocation` | appended `Read, write, commit and release in **one shell invocation**.` to the paragraph | red: `FAIL AC1 — no 'one shell invocation'` (12/1) |
| AC2 | window names `CONCURRENCY.md` | moved the whole lock paragraph from Step 4 to Step 3 | red: `FAIL AC2 — names CONCURRENCY.md` (+4 more, 8/5) |
| AC2 | window names `Lock every write to the backlog directory` | deleted the title, bare filename left | red: `FAIL AC2 — names the section title` (12/1) |
| AC3 | no `drop the trap` | pasted ``Or drop the trap and `rm -rf` explicitly at the end.`` | red: `FAIL AC3 — no 'drop the trap'` (12/1) |
| AC3 | no `in one call` | pasted `Run the whole sequence in one call.` | red: `FAIL AC3 — no 'in one call'` (12/1) |
| AC4 | a fixture with every phrase outside Step 4 fails | widened the guard's `window()` to `cat` the whole file | red: `FAIL AC4 — … the fixture satisfied every case` (and FR3; 11/2) |
| AC5 | `citations` and `skill-size` 0 failed | cited `*Lock every by-hand write*` in the skill | citations red: `cites "Lock every by-hand write", which is not a rule in CONCURRENCY.md` (50/1) |
| FR2 | the three retro-only phrases are in Step 4 | the paragraph moved to Step 3 (above) | red on all three FR2 cases |

Control after restore: `13 passed, 0 failed` · `51 passed, 0 failed` · `45 passed, 0 failed`;
`git status --porcelain` empty.

NFR — Documentation: holds and is guarded. The by-hand forms live only in
`references/CONCURRENCY.md` (line 263); Step 4 cites that section and AC3's guard reds on either form
reappearing; `references/CONCURRENCY-INCIDENTS.md` exists and is cited. The one other
`one shell invocation` in `references/CONCURRENCY.md:122` is a different rule, out of scope.
Always-on pass (`CONVENTIONS_CORE.md`): prose and test change only; no secrets, no company material,
no new reachable state; the guard copies the abort-announce block and the declared `saw-on-pass` copy.

Evidence set: `skills/retro/SKILL.md`, `tests/retro-lock-citation.test.sh`, `tests/citations.test.sh`,
`tests/skill-size.test.sh`, `references/CONCURRENCY.md`, `references/CONCURRENCY-INCIDENTS.md`, `README.md`.

**PASS.**

## Notes & decisions

- Routed to `develop`: `CONCURRENCY.md` has already decided what a by-hand lock may do, and Step 4
  is a stale copy of that decision. There is no open question, only a paragraph to replace.
- **Why cite rather than complete the restatement.** Adding the missing clause is one line and
  leaves the same defect armed: two copies of one rule, drifting again the next time
  `CONCURRENCY-INCIDENTS.md` learns something. `0091` FR1 chose the same shape for the same reason.
  AC3 exists to make that choice falsifiable rather than a preference in a note.
- `close_by: develop` because every criterion is a scoped grep the build session commits and proves
  red first; none is a reading.
- 2026-09-09 (queue, from `FINDINGS.md` parked the same day) — line numbers were current at the
  park date; re-read the source rather than trusting them.
- 2026-10-27 (develop, token 3b05) — **Built in c625f6b.** Step 4's lock paragraph now names only
  what is true of `retro` (no claim token; draining `FINDINGS.md` and appending to an unheld item are
  inside the boundary) and cites `references/CONCURRENCY.md` *Lock every write to the backlog
  directory* as the only home of the by-hand forms. The trap rationale went with the restatement —
  it is the reference's reason, and keeping it beside a citation would be the half-copy again.
- `README.md` joined `touches:`: `tests/citations.test.sh` case 0046 reds unless the README guard
  block lists every `tests/*.test.sh`, which the ticket's `expects:` did not foresee.
- The guard's cases live in one `check()` so the AC4 probes run the *same* assertions against each
  fixture in a subshell, rather than a paraphrase of them. Every probe must red.
- **Clause table (run, not reasoned — each red-making input below was executed):**

  | AC | Clause | Guard case | Red-making input | Result |
  |---|---|---|---|---|
  | AC1 | Step 4 window lacks `one shell invocation` | `AC1 — no 'one shell invocation'` | pre-fix file (red at first run); probe re-inserting the sentence | red |
  | AC2 | names `CONCURRENCY.md` | `AC2 — names CONCURRENCY.md` | — (asserted positively) | green on fix |
  | AC2 | names `Lock every write to the backlog directory` | `AC2 — names the section title` | probe deleting the title, bare filename left | red |
  | AC3 | no `in one call` | `AC3 — no 'in one call'` | — | green on fix |
  | AC3 | no `drop the trap` | `AC3 — no 'drop the trap'` | probe pasting `Or drop the trap and rm -rf explicitly at the end.` | red |
  | AC4 | every phrase outside Step 4 fails | `AC4 — the phrases in a neighbouring step leave the guard red` | fixture with all phrases in Step 3 | red (as required) |
  | AC5 | `citations` and `skill-size` 0 failed | those files | citing `*Lock every by-hand write*` in the skill | citations red 1, restored |
  | FR2 | `holds no claim token`, ``Draining `FINDINGS.md` ``, `appending to an unheld item` | `FR2 — …` | pre-fix file lacked `unheld item` (red at first run) | red→green |
  | FR3 | heading gone is a named failure | `FR3 — an empty window is a named failure` | probe deleting Step 4's heading | red |
- The notes append was refused as a sensitive-file edit via heredoc; written to /tmp and appended
  with python per the dispatch prompt's fallback.
- 2026-10-27 — **Reopened to verify** by `./reopen`: closed by its own develop session (02150de) without an independent verify; re-verifying
- 2026-10-27 (verify, token fa1b) — `close_by` set from `develop` to `verify`: a person ruled that this ticket closes on an independent verify, `./reopen` left the field at `develop`, and `./close` refused this session on it. Verified PASS independently; see *QA evidence*.
