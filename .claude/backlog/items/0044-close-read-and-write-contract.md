---
id: "0044"
title: Close the gaps in the close script's read and write contract
type: bug
next: verify
status: in-progress
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0029", "0031", "0034", "0035"]
expects:
  - skills/queue/templates/close
  - .claude/backlog/close
  - skills/queue/templates/next
  - .claude/backlog/next
  - skills/queue/templates/item.md
  - tests/close.test.sh
  - tests/next.test.sh
  - skills/verify/SKILL.md
claimed_by: "ce83"
claimed_at: 2026-08-30T16:35:21Z
touches:
---

## Problem

`./close` is the script `CONCURRENCY.md` names as the reason a close cannot be forgotten. It reads
frontmatter with a parser weaker than the one `./next` already ships, and it writes less than the
close is documented to write. Four defects, all live, all silent.

**1. The reconcile cannot read a block-list `blocked_by`.** `close` reads the field with
`fm_value`, which returns only what sits after the colon on the key's own line, so

```yaml
blocked_by:
  - "0028"
```

parses as empty, the `case "$blockers" in *"$ID"*)` test misses, and the loop `continue`s. Closing
0028 hit exactly this: it reported no reconcile at all, 0029 stayed `blocked` in both the item and
the row, and `./next --drift` exited 1 — the stale cache `close`'s own header calls the reason the
reconcile is part of the close. Reconciled by hand under the lock afterwards. `next` already
handles both forms via `fm_list`; `close` never got that parser. Today 24 of 25 items used the
inline flow form, so the blast radius is small — but the form is unstandardised, so both keep
appearing.

**2. `tests/close.test.sh` passes 62 assertions over the reconcile and could not have caught it.**
Every one of its `blocked_by` fixtures is the inline flow form: `mkitem 0008 develop blocked ''
'["0007"]'`. The block-list shape the parser cannot read is never fed to it, which is why this
reads as covered rather than untested.

**3. Both scripts' scalar readers are comment-blind.** `next`'s `fm()` and `close`'s `fm_value()`
take everything after `key:` and strip only surrounding quotes, so `claimed_by: "f0c3" # mine`
returns `f0c3" # mine` — and `close` compares that against the token it was given before it will
close anything. `develop` Step 1 actively invites the annotation ("say inline that it is new"), and
0031 fixed only the *list* reader, leaving an asymmetry no reader expects: a comment on `touches:`
is handled, one on `claimed_by:` or `size:` is not. `decomment` at `next:249` is already the fix;
it needs lifting out of `fm_list` and giving to both scalar readers and to `close`.

**4. `close` under-writes the ticket it closes.** Two halves:

- **It leaves `next:` set.** After closing 0005 the item reads `status: done`, `closed: 2026-08-24`,
  `next: verify`; 0010, closed by hand before the script existed, reads `next:` empty. The two close
  paths disagree about the same field, and the item is left saying a closed ticket is still due at a
  stage — the field-and-status disagreement the `next`/`status` split exists to prevent.
- **It ticks nothing when the ACs carry no checkbox, and closes anyway.** 0035's criteria are
  written `- **AC1** — Given …`; 0034's are `- [ ] AC1 — …`. `close` ticked 0034's seven, silently
  ticked none of 0035's eight, then closed the ticket, moved the row and reported success
  identically. `verify` closes on ticked ACs, so on the second format the one durable record that
  each criterion was checked is simply absent, and `DONE.md` cannot distinguish a ticket verified
  AC-by-AC from one waved through. `close` is documented to refuse rather than guess on three
  grounds; an AC block it cannot tick is a fourth and is not among them.

## Functional requirements

- FR1 — `close` reads list-valued frontmatter with the same parser `next` uses, so `blocked_by` in
  either the inline flow form or the block-list form is read identically by both scripts.
- FR2 — Both scripts' **scalar** readers strip a trailing YAML comment, so `claimed_by: "f0c3" # mine`
  yields `f0c3`. The `decomment` implementation is shared rather than copied a third time, or each
  copy names the others.
- FR3 — `tests/close.test.sh` drives at least one reconcile case whose dependent's `blocked_by` is
  in the block-list form, and at least one whose scalar field carries a trailing comment.
- FR4 — `close` clears `next:` on the ticket it marks `done`, so the script path and the pre-script
  by-hand path agree about the field.
- FR5 — `close` refuses, or reports loudly, when it ticks zero of a non-empty acceptance-criteria
  list, rather than closing and reporting success. This is a fourth documented refusal ground and
  is stated alongside the existing three.
- FR6 — `skills/queue/templates/item.md` settles **one** form for `blocked_by` and **one** form for
  an acceptance criterion, and says which, so new tickets stop producing both.
- FR7 — The parser changes land **before** the template narrows: both `blocked_by` forms are read
  correctly first, and only then does the template stop offering the second. Existing items are not
  rewritten by this ticket.
- FR8 — `.claude/backlog/close` and `.claude/backlog/next` are updated from the templates in the
  same change, since `tests/backlog-scripts-installed.test.sh` AC2 forces them byte-identical and
  the fix flows template → copy.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | `blocked_by` changes shape across 41 existing item files. FR7 is the expand-then-contract ordering: readers accept both forms before the template narrows, and no existing item is rewritten in the same change as the parser | `migration-conventions.md` |
| Progressive delivery | Other machines install this plugin and run these scripts. A ticket written to the narrowed template must still be readable by an installed older `close`, which FR7's ordering gives; the release is the version bump and the install, per this project's `CLAUDE.md` | `progressive-delivery-conventions.md` |
| Documentation | The fourth refusal ground of FR5 is written into `close`'s own documented refusals and into `verify`'s Step 5, not only into the code | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a dependent whose `blocked_by` is a block list naming the closing ticket, when
  `./close` runs, then that dependent is reconciled and reported, exactly as for the inline form.
- [ ] AC2 — Given an item whose `claimed_by:` carries a trailing ` # comment`, when `./close` is
  given the bare token, then it accepts the token; and when `./next` reads that item, then it
  prints the bare token.
- [ ] AC3 — Given `tests/close.test.sh`, when it is read, then it contains a reconcile fixture in
  the block-list form and a fixture with a commented scalar field.
- [ ] AC4 — Given a ticket closed by `./close`, when its frontmatter is read, then `next:` is
  empty and `status:` is `done`.
- [ ] AC5 — Given a ticket whose acceptance criteria carry no `- [ ]` checkbox, when `./close`
  runs, then it does not report a plain success: it either refuses, or reports that it ticked zero
  of N criteria.
- [ ] AC6 — Given a ticket whose criteria do carry checkboxes, when `./close` runs, then every one
  is ticked, unchanged from today.
- [ ] AC7 — Given `skills/queue/templates/item.md`, when it is read, then it offers exactly one
  `blocked_by` form and exactly one acceptance-criterion form.
- [ ] AC8 — Given `.claude/backlog/close` and `.claude/backlog/next`, when compared against
  `skills/queue/templates/`, then `tests/backlog-scripts-installed.test.sh` passes.
- [ ] AC9 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.

## QA plan

- **Level:** unit — the deliverables are two shell scripts and their fixtures, and this project's
  `unit` command runs every `tests/*.test.sh`.
- **Why this level:** every AC is a script invocation against a fixture item, which is what
  `tests/close.test.sh` already does; nothing crosses a seam.
- **Specific checks:** `tests/close.test.sh`, `tests/next.test.sh` and
  `tests/backlog-scripts-installed.test.sh` in full, then the whole suite. Exercise `./close`
  against a **clone of the repo in the scratchpad** rather than the live `QUEUE.md`, per the method
  0027's verify pass settled on — a live scratch row in a shared table is not safe while another
  session holds the backlog.

## Out of scope

- **Rewriting existing items' `blocked_by` into the settled form.** FR7 forbids it here; a
  normalisation pass is a separate ticket, and it must not run until every reader accepts both.
- `./claim --help` and `./close --help` answering `no row for --help in QUEUE.md`. Real, and a
  different defect: the interface, not the contract.
- `claim`'s success message telling every claimant to set `touches:` regardless of stage.
- Whether the handoff between stages should also be a script. That is 0048's decision.

## Notes & decisions

- **FR2's "shared rather than copied a third time" resolved as its fallback clause.** `decomment`
  now sits in one `DECOMMENT` shell variable per script, injected as awk source into both of that
  script's readers — so it is one copy per *script* (two) rather than one per *reader* (four), and
  each block names the other script. A genuinely single copy needs a fourth file the scripts source,
  which is a change to `queue` Step 0's scaffold and to `tests/backlog-scripts-installed.test.sh`'s
  three-name `SCRIPTS` list, not a refactor. Parked in `FINDINGS.md`.
- **`case "$blockers" in *"$ID"*` was replaced with a whole-id loop, not just re-pointed at
  `fm_list`.** The flattened list is bare space-separated ids, so the old substring test would read
  `0044` as naming `004`. Not a defect anyone had hit — four-digit ids and a short backlog — but the
  substring form only looked safe because `fm_value` was returning the raw `["0007"]` text.
- **One new guard could not fail, and the mutation is what showed it.** "A block list naming another
  ticket is not freed" passed with the id comparison deleted: its fixture's other blocker had no item
  file, so `other_blockers_all_done` refused the dependent first and the comparison never decided
  anything — `testing-conventions.md`'s "another check fires first and the new one never runs" case,
  arriving in a guard written the same hour. The fixture's blocker is now `done`, so nothing but the
  id comparison stands between that dependent and a reconcile it should not get, and the mutation
  reds it. Both new refusals were mutation-checked the same way, each mutation confirmed landed by
  diffing against a copy taken before the edit.
- **FR5 chose refusal over a loud report**, which FR5 left open and AC5 did not pin. `close`'s own
  header already frames every other unreadable shape as "an error, never a refusal that looks like a
  closed ticket", and a fourth *refusal ground* is what the Problem section asks for. The check
  counts before anything is written, so the refusal leaves the tree exactly as it found it.
- **An empty criteria section still closes.** Nothing to tick is not the same defect as criteria that
  cannot be ticked, and refusing there would block every chore ticket written without ACs — a
  different argument, and not this one's. Pinned by its own case.
- **Blast radius of the new refusal on this backlog: one item, already closed.** A scan of all 44
  items found only `0035` in the checkbox-less form, and it is `done`. No open ticket is affected, so
  FR7's "existing items are not rewritten" costs nothing today.
- **`next` gained four cases and `close` fifteen** — 154 and 93. The whole suite is green.

- Routed to `develop`, not `design`: every fix direction is named in the findings and the
  implementation already exists in the sibling script — `decomment` and `fm_list` are lifted, not
  invented. The one judgement call, expand-then-contract ordering, is `migration-conventions.md`'s
  answer rather than an open question.
- FR5 says "refuses, or reports loudly" deliberately. Which of the two is a judgement about how
  much a close should be allowed to proceed on partial evidence, and the AC pins the observable
  outcome — not a plain success — rather than the choice.
- Bundled from four findings because they are one root cause at the right altitude: `close`'s
  contract is incompletely implemented in both directions, and its file scope is a single unit.
  Splitting them would put two sessions in `close` and `close.test.sh` at once, which is this
  repo's live failure mode.
