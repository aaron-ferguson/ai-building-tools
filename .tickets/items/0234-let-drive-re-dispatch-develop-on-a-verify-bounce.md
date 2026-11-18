---
id: "0234"
title: Let --drive re-dispatch develop on a verify bounce instead of escalating
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-11-18
source: user
parent:
blocked_by: []
relates: ["0231"]
expects:
  - skills/queue/templates/next
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

In sprint run-20261118T074205Z, 0231's leg S5 failed verify on AC14, and
`./next --drive --completed verify:0231` exited 4 with
`ESCALATE  0231 bounced from verify back to next: develop — verify already decided whether the build or the contract was wrong, and re-developing blind spends a stage session rediscovering it`
(`skills/queue/templates/next`, the `--drive` bounce branch). The user's answer, verbatim:
*"going back and redeveloping when something fails is always the right choice. You do not need to ask
me first as the sprint coordinator I fully expect you to be able to handle situations like this on
your own."* The re-develop then cost one $0.66 session pointed at verify's diagnosis.

**This reverses a tested behaviour.** 0231's AC7 asserts "after the fail, exit 4 with the bounce
escalation" (`tests/sprint.test.sh`), so the change is a contract change on the user's call, not a
regression fix — the test is amended, not worked around.

## Open design question

The user has decided *that* a bounce re-dispatches. What is left: is there a bound — after how many
consecutive bounces of one row does `--drive` escalate after all, so a contract that cannot be met
does not loop a run to its budget — and how does verify's diagnosis reach the dispatch (the
outcome's `detail` pointer in the `DISPATCH` line, or the supervisor's prompt)?

## Functional requirements

- FR1 — `./next --drive --completed verify:<id>` leaving the row at `next: develop` prints
  `DISPATCH  develop <id>` rather than exiting 4, up to the bound the decision names.
- FR2 — `skills/sprint/SKILL.md` (Step 2 and Step 8) says a verify bounce is routed, not escalated,
  and that the develop dispatch carries verify's `detail` pointer.
- FR3 — 0231's AC7 assertion in `tests/sprint.test.sh` is amended to the new contract, citing this item.

## Notes & decisions

- 2026-11-18 (retro, run-20261118T074205Z findings gate) — filed at the user's request from
  `.tickets/FINDINGS.md`; not held, because the user asked for it.
