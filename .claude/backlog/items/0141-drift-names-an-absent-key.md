---
id: "0141"
title: Make a drift line say a frontmatter key is absent instead of printing an empty value
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0115", "0096"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`--drift` reports an absent frontmatter key as a disagreement with the empty string**, which reads
as a rendering fault rather than as the defect it is.

`0115` FR5 saw this one level up and guarded it: every `fm` read against a **missing file** returns
empty, so a row with no item would have presented as a `next:` disagreement with `""`, and the
missing-item check was put first precisely to stop that. The same reasoning does not reach an item
file that **exists** but is missing the key.

Driven at the CLI during `0115`'s QA pass on 2026-09-09, token `2390`, on a scaffolded fixture whose
item carried every key except `next:`:

```
$ ./next --drift
DRIFT     0001 | row Next develop, item next:  — the row and its item disagree about the stage
$ echo $?
1
```

The exit code and the id are right, and the line is not false — the row and the item do disagree.
But `item next:` followed by nothing tells the reader the value failed to print, not that the key is
gone, and the two need different fixes: a disagreement is reconciled by moving one side, an absent
key is repaired by writing it. A session that dies mid-edit on an item, or a hand-written ticket
that skipped a key, is exactly the input this mode is pointed at.

The same shape is reachable for `status:` and `claimed_by:` — the `claimed_by:` branch is the one
case where empty is a legitimate, meaningful value and must keep reading as one.

## Functional requirements

- **FR1 — a row whose item is missing the key being compared is named as an absent key**, saying
  which key and which item, rather than as a disagreement with the empty string. Covers `next:` and
  `status:`.
- **FR2 — an empty `claimed_by:` keeps its present meaning**, since `0115` FR3 is built on empty
  being the signal there rather than a fault. An absent `claimed_by:` key and an empty one are the
  same state for that branch.
- **FR3 — one line per row is preserved.** `0115` FR4 settled that a row is reported once; the
  absent-key class takes its place in the existing precedence chain rather than reporting alongside
  another class.
- **FR4 — the edit lands in both copies**, `skills/queue/templates/next` and `.claude/backlog/next`,
  leaving `tests/backlog-scripts-installed.test.sh` green — it forces the two byte-identical.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Observability | The absent-key line names the id, the key and the item path, on the pattern the existing `DRIFT` lines set. Would red on a line that names the id alone, or that still prints a bare `item next:` with nothing after it. | `observability-conventions.md` |
| Testing | FR1 and FR2 each get a case in `tests/next.test.sh` asserting on the printed line **and** the exit code, and each is mutation-proved: neuter the branch, confirm the mutation landed, confirm the suite reds, restore. Would red if the branch could be removed with the suite still green. | `testing-conventions.md` |
| Documentation | The class list in `next`'s `--drift` header gains this class in the one place it is listed; `usage()` keeps its one-line summary. Would red on a second copy of the class list. | `documentation-conventions.md` |
| Dependencies | `/bin/sh`, `git`, `awk` and the `fm`, `field`, `row_for`, `item_for` helpers `next` already carries. Nothing new. Would red on any added binary. | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an item file that exists and carries every frontmatter key except `next:`, when
  `./next --drift` runs, then the line for that row says the key is absent and names it, and does not
  print `item next:` followed by nothing. Exits non-zero. Red-making input: today's `next`, whose
  output is captured in the Problem section.
- [ ] AC2 — Given an item file missing `status:`, when `./next --drift` runs, then the same holds for
  `status:`. Red-making mutation: handling only `next:`, which leaves this row printing an empty
  value.
- [ ] AC3 — Given an item whose `claimed_by:` key is absent and whose row reads `in-progress`, when
  `./next --drift` runs, then it is reported as the tokenless class `0115` FR3 defines, not as an
  absent key. Red-making mutation: routing `claimed_by:` through the new absent-key branch, which
  replaces a meaningful report with a spurious one.
- [ ] AC4 — Given a row that qualifies for the absent-key class, when `./next --drift` runs, then that
  id appears on exactly one line. Red-making mutation: reporting the class as an independent `if`
  after the chain, which prints two lines for one row.
- [ ] AC5 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing `skills/queue/templates/next` and not
  `.claude/backlog/next`.

## QA plan

- **Why this level:** `unit` — `next` is a shell script with an existing suite, and every requirement
  is an ordinary case in `tests/next.test.sh` over a scaffolded fixture backlog.
- **Specific checks:**
  - Run `tests/next.test.sh` and `tests/backlog-scripts-installed.test.sh` individually first, then
    the whole suite file-by-file with `|| true` per `config.yml`'s note, so another window's red does
    not mask these.
  - Mutate each new branch away one at a time, confirming the mutation landed before reading the
    result, with a no-op control run before and after the sweep — the sweep shape `0115` used.
  - AC4 asserts on the **line count** for the id, not merely on the line's presence; `0115` recorded
    that every arm of this chain prints a superficially similar line, so a mutated branch can be
    covered by its neighbour and still look green.

## Out of scope

- **The missing-item-file class.** `0115` FR5 ships it, and it stays first in the chain.
- **Validating item frontmatter generally.** Whether a required key may be absent at all is a
  different question from how `--drift` renders one that is; `0096` holds the neighbouring work on
  frontmatter path lists.
- **Repairing the item.** `--drift` reports and never writes.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed from `0115`'s verify pass, 2026-09-09 `[2390]`**, as a probe finding. Cosmetic in effect —
  the exit code and the id are already correct — but it is the same class of misdirection `0115` FR5
  was written to prevent, arriving one level in, so the remedy is the one that ticket already chose.
- **Routed to `develop`, not `design`.** One remedy, and `0115` already settled the precedence rule
  the new branch has to sit inside. Nothing is undecided.
