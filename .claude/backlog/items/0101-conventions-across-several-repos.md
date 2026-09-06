---
id: "0101"
title: Say what a capture session does when only some repos resolve conventions
type: bug
next: develop
status: ready
qa_level: verify
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0078"]
expects:
  - references/CONVENTIONS.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`references/CONVENTIONS.md`'s stop-and-report path has no answer for a **single capture session asked
to queue related work across several repositories when only some of them resolve conventions**.

Observed: one session was asked to turn one comparison's findings into tickets across four repos.
One (this one) already had `conventions.path` set; three others — a PM-tooling repo, a
Jira-ticket-drafting repo, and a general skills repo — had no conventions wiring at all. The file's
instruction is unambiguous per repo (*stop, do not scaffold, do not guess*) and says nothing about
the batch: whether to proceed with the repos that resolve and report the rest, or hold the whole
batch until the user decides how the unwired repos should be wired.

The session handled it by doing the resolvable repo and stopping to ask about the other three. That
looks like the right default and **is written nowhere**, so the next session in the same position
will decide again, and may decide the other way — which on the *stop* reading means correctly
specified tickets are withheld, and on the *proceed everywhere* reading means tickets citing no
standard, which is what the stop rule exists to prevent.

This is more likely, not less, now that findings route by what they are about rather than by which
repo a session is standing in (`0078`).

## Functional requirements

- FR1 — `references/CONVENTIONS.md` states the batch case: a session capturing across several repos
  proceeds in each repo that resolves conventions and reports each that does not, naming the repo and
  what wiring is missing. It never blocks a resolvable repo on an unresolvable sibling.
- FR2 — It states the boundary that makes this safe: per repo, nothing changes — the unresolved repo
  is still not scaffolded and its tickets are still not written. Only the *batch* proceeds
  partially.
- FR3 — The report of what was skipped names the missing wiring specifically enough to act on
  (`conventions.path` in that repo's `.claude/backlog/config.yml`, or the profile the project's
  `CLAUDE.md` should declare), since a report that says only "three repos failed" costs the user the
  same investigation the session already did.
- FR4 — A guard asserts FR1 is present in `references/CONVENTIONS.md` — the code behind the rule,
  without which it is one sentence in a file nothing checks.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule is stated in `CONVENTIONS.md` alone and not copied into `queue`, which already resolves conventions by citing that file | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/CONVENTIONS.md`, when its resolution-order section is read, then it
  states what a session does when some repos in one batch resolve and others do not. Red-making
  input: today's file, which is silent on it.
- [ ] AC2 — Given that rule, when it is read for the partial case, then it says the resolvable repos
  proceed. Red-making mutation: replacing "proceed" with "hold", which reverses the default the
  observed session chose and reddens the guard asserting the word.
- [ ] AC3 — Given that rule, when the skipped-repo report is described, then it requires naming the
  repo and the missing wiring. Red-making mutation: deleting the wiring clause, leaving a report
  that says only which repos failed.
- [ ] AC4 — Given FR4's guard, when FR1's rule is deleted from `references/CONVENTIONS.md`, then the
  guard fails and names the file. Red if it passes.
- [ ] AC5 — Given `references/CONVENTIONS.md` after the change, when `tests/reference-size.test.sh`
  runs, then it reports `0 failed`. The file is 3,287 bytes today, well under its goal; red if the
  addition is written long enough to change that.

## QA plan

- **Why that level:** no runner applies — the deliverable is a rule in one reference file plus a
  guard. The scripted assertions are FR4's guard and the greps AC2 and AC3 name.
- **Specific checks:** FR4's guard, `tests/reference-size.test.sh`, `tests/citations.test.sh`. Apply
  AC4's deletion, confirm the guard reddens, revert.

## Out of scope

- Wiring the three unwired repos. That is work in those repos, and this ticket is about the rule.
- How a finding is routed to the repo it is about — that is `0078`.
- The per-repo stop rule, which is correct and unchanged.

## Notes & decisions

- Routed to `develop`: `CONVENTIONS.md` already fails closed per repo, and the batch case is that
  rule applied per repo rather than a new policy. Reading it any other way makes one unwired repo
  block three wired ones, which the fail-closed argument does not support.
