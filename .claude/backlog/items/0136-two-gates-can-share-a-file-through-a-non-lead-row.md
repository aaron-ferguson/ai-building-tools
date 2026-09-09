---
id: "0136"
title: Stop two gates sharing a file through a row neither lead names
type: bug
next: develop
status: ready
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

- [ ] AC1 — Given a fixture of three rows where A and B share `f1`, and C shares `f2` with B but
      shares nothing with A, when `--drive` forms gates, then C is in the same gate as A and B.
      **Red if** C forms a second gate — today's behaviour, and the discriminating case: a fixture
      where C overlaps the lead cannot tell the old rule from the new one.
- [ ] AC2 — Given that fixture, when `DEPTH` is printed, then it reports one takeable gate. **Red
      if** it reports two, which is what the current partition counts.
- [ ] AC3 — Given a fixture of two rows sharing no file, when gates are formed, then they are two
      gates. **Red if** accumulation is written without a termination condition and merges
      everything reachable, which is the failure FR3 guards.
- [ ] AC4 — Given the repo after this ticket, when `diff .claude/backlog/next
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
