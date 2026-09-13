---
id: "0123"
title: Give queue a rule for withdrawing a criterion, as it has for withdrawing an id
type: bug
next: develop
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0062"]
expects:
  - skills/queue/SKILL.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`queue`'s re-specify has no rule for withdrawing a *criterion*, and the obvious move breaks
citations.** `0081` came back with AC4's instrument broken and its subject correct. Deleting AC4
renumbers AC5-AC7, which `tests/handoff.test.sh` cites by number in four section comments and which
two QA verdicts cite in evidence tables.

The skill already carries exactly this reasoning — *"a citation silently re-pointed at unrelated
work is one nobody can see"* — in its *Withdrawing a ticket* section, and states it **only of
`next_id`**. An FR or AC number is a citable identifier on precisely the same terms, and nothing
says so.

`0081` was resolved by marking FR5 and AC4 withdrawn in place and keeping the numbers. That was
**invented, not read**, which is the tell that the rule is missing rather than merely buried.

`0062` was opened and is adjacent but not this: `0062` is about an FR list that cannot express a
*removal of behaviour*, not about criterion numbering and citation stability.

## Functional requirements

- FR1 — `queue` Step 2's re-specify case states what happens to the numbering when a criterion is
  withdrawn.
- FR2 — the rule either extends the id reasoning to criteria explicitly, or says why a criterion
  differs from an id. Silence is what produced the invention.
- FR3 — the rule names the form a withdrawn criterion takes in the file, so a reader can tell a
  withdrawn AC from a missing one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Stated once, beside the id rule it extends, rather than as a second passage | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given `skills/queue/SKILL.md`, when grepped, then the re-specify case names criterion
  withdrawal and the numbering consequence; red by deleting that sentence.
- [ ] AC2 — the passage names the withdrawn-in-place form from FR3; red by replacing it with a bare
  instruction to delete.
- [ ] AC3 — the passage sits with the `next_id` withdrawal rule rather than in a separate section;
  red by moving it, which the guard detects by the heading it appears under.

## QA plan

- **Why that level:** the artifact is skill prose; the checks are greps, and `qa_level: verify` is
  the honest level for a mechanical check with no runner.
- **Specific checks:** `tests/citations.test.sh` for the new assertions; the whole suite, since
  `tests/handoff.test.sh`'s four AC-number citations are the thing being protected.

## Out of scope

Renumbering anything in `0081`. Whether an FR list can express a removal (`0062`).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-08 and deferred once by this retro
  before being filed properly.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Concrete instance: 0147 dropped AC5 and kept AC6's number, reasoning from the id-withdrawal rule, so its evidence and notes still resolve. `close` ticks by line form, so a gap is harmless — the rule this ticket writes should say keep the gap.
