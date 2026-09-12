# 004 — A gate ticket, and the work it decides

**Date:** 2026-09-12 · **Status:** accepted · **Related:** `003`, tickets `0110`, `0104` (withdrawn, preserved at `7764732`), `0016`, `0026`

## Context

Some work should exist only if a measurement clears written kill criteria
(`discovery-conventions.md`, *Write the Kill Criteria Before the Test*), and its verdict must be
recorded even when it is "it didn't work" (`measurement-conventions.md`, *The Verdict Gets Recorded*).
The item template had no place for either. `0104` put the gate in FR1 and made FR2-FR7 conditional on
it inline, then spent an acceptance criterion asserting the *killed* state so `verify` would not read a
kill as unfinished work. `0001` invented a `## Kill criteria` heading; `0016` kept one in *Notes &
decisions*, where it went unresolved until `0026` happened to settle it.

`0110` put two shapes up: **A**, a conditional-FR form inside one ticket; **B**, the gate as its own
ticket, with the dependents `blocked_by` it.

## Decision

**The gate is its own ticket, and the work it decides is not filed until it clears.**

- The gate ticket carries an optional `## Kill criteria` section, written at queue time: each
  threshold, the measurement that produces it, and a `**Verdict:**` line left empty until the
  measurement runs. The session that runs it writes `cleared` or `killed`, the figures against each
  criterion, and the date.
- The same section carries an **`If it clears:`** outline of the follow-on work — prose, not FRs or
  ACs, so nothing in it can be ticked or built.
- The gate's acceptance criteria are **satisfiable either way**: they assert the verdict was recorded
  against every criterion, never that it was favourable. The ticket closes `done` on a kill as well as
  on a clear. This is `0026` FR8's shape, generalized.
- On `cleared`, the closing session parks one `FINDINGS.md` entry pointing at the outline, and
  `queue`'s buffer sweep specifies the follow-on against the measured figures. On `killed`, nothing
  else exists, so there is nothing to withdraw.

`close`, `next` and `verify` are unchanged: a gate ticket ends in the same two terminal states as any
other.

## Rejected alternatives

**A — conditional FRs in one ticket.** Rejected on an observed mechanism, not preference.
`.claude/backlog/close` ticks **every** `- [ ]` box in *Acceptance criteria* unconditionally
(`in_ac && /^- \[ \]/ { sub(/^- \[ \]/, "- [x]") }`, read 2026-09-12). A killed ticket carrying ACs for
unshipped FRs would close with those boxes ticked — a record that checks ran which never did, the
defect `0044` built the checkbox form to prevent. Making A honest needs a third AC state in `close`, a
third terminal reading in `verify`, and a template form most tickets never use.

**B — dependents `blocked_by` the gate.** Rejected on the reconcile. `close` frees every dependent
whose blockers are all `done` to `ready`, **whatever the verdict** — `tests/close.test.sh` AC8, run
green (246 passed) on 2026-09-12. A killed gate closing `done` therefore releases the work it killed
straight to `develop`. Withdrawing the gate instead leaves its dependents blocked for good, since
`next` treats any blocker that is not `done` as open. Either way a rule for dependents is needed that
`blocked_by` cannot express: it means *wait for*, not *exists only if*.

**Pre-specifying the follow-on as tickets at all.** `0104` spent six FRs and five ACs on work that
could have died, and every threshold in them would have been rewritten once real figures existed.
Specifying after the verdict is specifying against evidence.

## Consequences

- **Accepted cost:** a gate that clears costs one `queue` sweep to turn its outline into a ticket, and
  the follow-on's FRs are written a stage later than they could have been.
- **A killed FR is distinguishable from a skipped one** because no killed FR exists: the only record is
  a `done` gate whose *Verdict* line reads `killed` with its figures. Abandoned work, by contrast, is a
  `withdrawn` ticket with a withdrawal note.
- **Residual risk:** the `FINDINGS.md` line on a clear is prose an instruction asks for, and a session
  could forget it. The verdict line survives in the closed ticket regardless, so the loss is a delay,
  not a lost verdict.
