---
id: "0176"
title: Give an unattended stage a backlog write channel it can fall back to
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0172", "0154"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`skills/sprint/SKILL.md` Step 3 names one write channel for backlog files, and that channel is
refused non-deterministically, so a stage following the instruction stalls mid-sweep holding the
backlog lock.**

Observed on 2026-09-21 in one unattended `queue` stage. `cat > .claude/backlog/items/0172-….md
<<'ITEM'` landed, the identical form for `0173` landed, and the identical form for `0174` came back
*"requested permissions to edit … which is a sensitive file"*. Same session, same command shape, same
directory, three consecutive writes. What was permitted with no prompt was writing the heredoc to
`/tmp/i0174.md` and then `cp`-ing it into place.

This sweep reproduced the refusal in a shape the park's own theory does not cover: `sed -n '1,25p'
.claude/backlog/items/0174-*.md` — a **read**, with no redirect anywhere in the command — was refused
with the same message. So the trigger is not "the write target of the redirect", and a stage cannot
predict which of its commands will be refused.

The cost is not a retry. An unattended stage has nobody to answer the prompt, and a `queue` or
`retro` sweep is refused **while holding `.claude/backlog/.lock/`**, which blocks every claim and
close in the repository until a human clears it — the failure `config.yml`'s `lock_stale_seconds`
comment exists to bound.

Step 3 already rules that naming the channel is the whole fix and that the permission routes are
ruled out and must not be re-probed. That ruling stands; what is missing is the second form to fall
back to when the named one is refused.

## Functional requirements

- FR1 — Step 3's dispatch-prompt bullet names a fallback form: write the heredoc to a path outside
  `.claude/backlog/` and `cp` it into place, observed permitted in the same session that was refused.
- FR2 — The same bullet says the refusal is not predictable by command shape — identical heredocs to
  one directory were refused once in three, and a read naming a backlog path was refused with no
  redirect present — so a stage falls back rather than concluding the channel is unavailable.
- FR3 — The bullet's existing ruling survives intact: naming the channel is the whole fix, and the
  three probed permission routes are not re-probed (`0172` is the separate question of how a refusal
  and the instruction that satisfies it reach a session together).
- FR4 — `tests/sprint.test.sh` carries a guard asserting FR1's fallback in Step 3, written in the
  file's existing `guard_says` idiom, beside the `Bash heredoc` guard it already has.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The fallback is stated once, in Step 3, and is not restated in the stage skills it dispatches | `tests/citations.test.sh` | `documentation-conventions.md` |
| Observability | A stage that falls back says so, rather than falling back silently and leaving a refused command unexplained in the stage's stdout capture | A guard asserting the bullet tells the stage to report the fallback; reddened by deleting that clause | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md` Step 3, when `tests/sprint.test.sh` runs, then a guard asserts Step 3 names the write-outside-then-copy fallback — reddened by deleting that sentence from Step 3.
- [ ] AC2 — Given the same file, when `tests/sprint.test.sh` runs, then the existing `Bash heredoc` guard still passes — reddened by rewrapping the paragraph so the phrase straddles a line break.
- [ ] AC3 — Given the same file, when `tests/sprint.test.sh` runs, then a guard asserts the bullet still rules the three permission routes out of re-probing — reddened by removing that ruling while adding the fallback.
- [ ] AC4 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then it is green — reddened by leaving `skills/sprint/SKILL.md` over its size budget after the addition.

## QA plan

- **Why that level:** a prose rule in a shipped skill, guarded by this repo's shell suite, which is
  the only runner the project has.
- **Specific checks:** `tests/sprint.test.sh`, `tests/citations.test.sh`, `tests/skill-size.test.sh`.

## Out of scope

- Establishing what actually triggers the refusal. Three probes on 2026-09-17 already ruled out the
  permission-setting routes, Step 3 forbids re-probing them, and the remaining routes widen authority
  past one directory and are the user's call (`sprint` Step 3).
- Changing any permission setting, or the harness's sensitive-file classifier.
- `0172`'s question, which is about a refusal and its instruction binding at different times.

## Notes & decisions

- **2026-09-21 (queue sweep)** — Filed from a `FINDINGS.md` entry parked by the 2026-09-21 retro.
  Routed to `develop`, not `design`: the fallback form was observed working in the same session, so
  there is no open decision — only a sentence that is not written down. The entry offered
  "establish the refusal's trigger" as an alternative; that half is sent to *Out of scope* because
  Step 3 already forbids the probing it would need.
- **2026-09-21 (queue sweep)** — New evidence beyond the park: a plain `sed -n` read of a backlog
  item was refused identically, with no redirect in the command. The park's inference that the
  refusal "keys on the write target of the redirect" is therefore wrong, which is why FR2 tells a
  stage to fall back rather than to reason about the trigger.
