---
id: "0136"
title: Stop two gates sharing a file through a row neither lead names
type: bug
next:
status: done
qa_level: verify
close_by: verify
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0038", "0059", "0137"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-10
---

## Problem

**`gate_from` tests every candidate against the *lead's* `expects:`, never against the set it has
already accumulated**, so the gates it produces are not guaranteed disjoint from each other.

```sh
gate_from() {
  lexpects="$(fm_list "$(item_for "$lead")" expects)"
  ...
  if paths_overlap "$lexpects" "$(fm_list "$(item_for "$gid")" expects)"; then printf ' %s' "$gid"; fi
```

Gate 1 is formed as `{A, B}` where B overlaps A. Gate 2 is then formed from what remains, led by C,
where C does not overlap A — so C is correctly excluded from gate 1. But nothing ever compares C to
**B**. If C and B name the same file, two gates hold rows that collide, and the walk reports them as
separate takeable units.

**Today this is latent, because dispatch is sequential** — one gate goes to one session at a time, so
two colliding gates never run together. It bites in two places anyway:

- **The depth count is wrong.** `--drive`'s `DEPTH` line walks gates to say how deep the backlog is.
  A partition that splits rows which actually collide reports more takeable gates than exist, and
  `0130`'s proposal is built on that walk.
- **It is a live hazard the moment anything runs two gates at once**, which is exactly what `0137`
  would introduce. A correctness defect that only appears under a later change is the kind that gets
  attributed to the later change.

Found 2026-09-09 while reading `gate_from` for `0130`; no incident has been traced to it.

## Functional requirements

- FR1 — Gate membership is tested against the **accumulated** scope of the gate — the union of the
  `expects:` of every row already in it — rather than against the lead's alone.
- FR2 — The change lands in `skills/queue/templates/next` as well as `.claude/backlog/next`. This
  repo ships that template.
- FR3 — The chaining this introduces is bounded and its bound is stated. Transitive accumulation is
  what the existing comment warns can *"sweep half a backlog into one gate via a file two unrelated
  efforts both happen to touch"*, so the fix must say what stops it, and `0130`'s proposal is what
  makes the resulting group legible to a person.
- FR4 — `DEPTH`'s gate count is computed from the corrected partition.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reason sits beside `gate_from`, where the current comment already explains the opposite hazard; the two bounds have to be readable together | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a fixture of three rows where A and B share `f1`, and C shares `f2` with B but
      shares nothing with A, when `--drive` forms gates, then C is in the same gate as A and B.
      **Red if** C forms a second gate — today's behaviour, and the discriminating case: a fixture
      where C overlaps the lead cannot tell the old rule from the new one.
- [x] AC2 — Given that fixture, when `DEPTH` is printed, then it reports one takeable gate. **Red
      if** it reports two, which is what the current partition counts.
- [x] AC3 — Given a fixture of two rows sharing no file, when gates are formed, then they are two
      gates. **Red if** accumulation is written without a termination condition and merges
      everything reachable, which is the failure FR3 guards.
- [x] AC4 — Given the repo after this ticket, when `diff .claude/backlog/next
      skills/queue/templates/next` runs, then they are identical. **Red if** only this project's
      copy is fixed.

## QA plan

- **Why that level:** `next` is a shell script with no runner configured; `tests/next.test.sh` is its
  existing self-contained guard.
- **Specific checks:** `tests/next.test.sh` against the three-row fixture in AC1, which is
  deliberately shaped so the old and new rules disagree; the AC3 fixture as the negative case.

## Out of scope

- Running gates in parallel — `0137`.
- Changing how a person is shown a gate's composition — `0130`.

## Notes & decisions

- **2026-09-09 — filed as a bug rather than folded into `0137`.** It is a defect in the partition
  `--drive` publishes today, independent of whether anything ever dispatches two gates at once, and
  leaving it inside a deferred ticket would have hidden it behind work that may not happen.

- **2026-09-09 — the bound FR3 asked for is a single forward pass, not a hop count.** Accumulating
  the gate's scope *is* chaining, so the old comment's "one hop, deliberately not a transitive
  closure" could not survive the fix as written. What replaces it is two bounds stated together
  beside the hazard: the pool is walked once in rank order with each row tested exactly once and
  never reconsidered — so scope grows forward only and a row stepped over is never pulled back in —
  and the pool is the takeable `develop` rows alone. A chain of rows that really do share files
  pairwise still forms one long gate, and that is correct: it is one file scope and cannot be split
  into sessions that could run together. Making that group legible to a person stays `0130`'s.
- **2026-09-09 — AC4 needed no new test.** `tests/backlog-scripts-installed.test.sh` already
  compares both copies of all four scripts, so the parity criterion is discharged by a guard that
  was green before this ticket and stayed green after. Verified directly as well:
  `diff .claude/backlog/next skills/queue/templates/next` is silent.
- **2026-09-09 — `add_ticket` could not express the discriminating fixture.** It hardwires one
  `expects:` path, and the case that separates the old rule from the new one needs a middle row
  naming two files. Added `add_ticket_expects`, which takes the `expects:` block whole, in the same
  shape as the existing `add_item_lists`. Confirmed red before the fix: AC1 saw
  `DISPATCH  develop 0101 0102` and `DEPTH     2`, exactly the two-gate partition the ticket
  describes.

## QA evidence

Verified 2026-09-09 at `qa_level: verify` (token `1217`) against `a800e20`. Tree clean at Step 2
and at verdict; dirty set empty, so the intersection with the evidence set is empty and this is a
plain PASS. Evidence set: `skills/queue/templates/next`, `.claude/backlog/next`,
`tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`.

| Row | How it was checked | Result |
|---|---|---|
| AC1 — C joins A and B's gate | `tests/next.test.sh` case *0136 AC1*, three-row fixture (0102 shares `shared/one.md` with the lead and `shared/two.md` with 0103; 0103 shares nothing with the lead). Suite tally pasted: `236 passed, 0 failed` | PASS |
| AC1 mutation | Deleted both `gscope="$gscope $gexpects"` accumulation lines from `skills/queue/templates/next` (diff 2 lines, non-empty). Went red: `expected to contain: DISPATCH  develop 0101 0102 0103` / `saw: DISPATCH  develop 0101 0102`. `234 passed, 2 failed`. Restored, control `236 passed, 0 failed` | reddens |
| AC2 — DEPTH reports one gate | Same case asserts `DEPTH     1`. Under the AC1 mutation it read `DEPTH     2 develop gate(s) takeable`, the two-gate partition the ticket describes | PASS |
| AC3 — two disjoint rows stay two gates | `tests/next.test.sh` case *0136 AC3* | PASS |
| AC3 mutation | Replaced `if paths_overlap "$gscope" "$gexpects"` with `if true` — unbounded merge. Went red: `expected NOT to contain: 0101 0102` / `saw: DEPTH     1`. `233 passed, 3 failed`. Restored, control green | reddens |
| AC4 — both copies identical | `diff .claude/backlog/next skills/queue/templates/next` silent; `tests/backlog-scripts-installed.test.sh` → `37 passed, 0 failed` | PASS |
| AC4 mutation | Appended a comment line to the template. Went red: `FAIL next has diverged from skills/queue/templates/next`, `36 passed, 1 failed`. Restored via `git checkout -- skills/queue/templates/next`, guard green | reddens |
| FR4 — DEPTH from the corrected partition | `depth_line()` walks `gate_from` directly (`.claude/backlog/next:659-666`); AC2's assertion is its runtime proof | PASS |
| NFR Documentation | The two bounds — one forward pass in rank order, each row tested once; pool is takeable `develop` rows only — sit in one comment block immediately above `gate_from`, alongside the original transitive-closure hazard the fix had to replace | PASS |

Probe on real data: `.claude/backlog/next --drive` against this repo's live queue reported
`DEPTH     5 develop gate(s) takeable` — no runaway merge under the accumulated rule.
