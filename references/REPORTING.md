# What a stage session puts on the screen

Read by `design`, `develop`, `prototype`, `queue`, `retro` and `verify` at their closing step, and
**cited there, never restated** — six copies of one rule is six things to drift.

**This is a routing rule.** It says where each kind of content a stage produces belongs. The screen
getting quieter is a consequence of that routing, never the instruction, and there is deliberately no
size target of any kind in this file. Narration was measured against this repo's own transcripts and
is a small fraction of a session's output (0074, *Notes & decisions*), so a target would buy almost
nothing — and it would miss what the routing is actually for. **A stage with an audience writes its
diagnosis to the audience instead of to disk, and the audience does not outlive the session.**

## What goes where

| Kind | Destination | Where its detail lives |
|---|---|---|
| **State that outlives the session** | screen | the commit, the item file, `DONE.md` |
| **What failed, was skipped, or was refused** | screen | the failing output itself, in the item file or `FINDINGS.md` |
| **What the session needs from you** | screen | nowhere — it is the reason the session stopped |
| **Where the detail landed** | screen | the paths, which are the whole content of this kind |
| Everything a step worked out on the way | disk | *Notes & decisions*, `FINDINGS.md`, the commit message |

The first row is the state the work was **left in**, not only the artifacts written: a row claimed, a
transition taken, a tree left green. A step that ran something and reports nothing has not routed its
output to disk — it has dropped it.

The first two rows are the same split `observability-conventions.md` draws between a level that needs
a human and one that is merely notable. The levels are defined there and are not restated here.

The fourth row is the one that is easy to skip and the one that makes the rest safe: a report whose
detail went to disk without saying where is a deletion, not a summary.

## The way back to the detail is a path, not a switch

Nothing here introduces a mode to turn on or a phrase to say, and that is a deliberate choice rather
than an omission. Everything routed to disk is *required* to be there — by the step that wrote it, and
by 0039 FR14 — so a second channel would only gate a file you can already open. The report's last act
is to name the paths; you open one, or you ask the session, which is still running.

A skill file could not implement a switch in any case. It instructs a session; it does not define how
that session was invoked.

## This binds a step's report, not the running commentary

The rule governs the reports a skill's own steps instruct: the closing report, the verdict, the claim
announcement. It does not try to govern what a session says turn by turn, and the reason is worth
keeping so it is not re-asked.

**Nothing can check it.** A running conversation is not a file a guard can read, so a per-turn rule
could only ever be prose describing itself — which is exactly the failure `tests/reporting.test.sh`
exists to avoid. **And it would not pay.** The 0074 measurement puts per-turn narration far below the
level at which constraining it would change a session's cost, while the dominant term is a session's
thinking, which no instruction in a skill file reaches and which the stored transcript does not retain.

## The other channel

A supervised run reads 0036 FR13's structured outcome, and the two channels state the same facts.
One of them being shorter is fine; the two disagreeing is not, and neither is a place where a fact
appears for the first time. Hand-driven, this report is the only channel there is.

## Nothing here removes a check

**What shrinks is what reaches the screen. What reaches disk is unchanged or larger.** A step that ran
a check still reports what the check found — that is the second row, and it is not optional. A step
whose only visible output was a line in the report keeps that line unless its content now lands
somewhere durable, named by the fourth row.

The failure this forbids is specific and has happened in this project: a step with no visible output
is the kind that gets quietly dropped — parking a finding, running the full suite, releasing a claim.
Routing a step's output to disk is fine. Routing it nowhere removes the step.

## The findings buffer

**Every stage session's report carries the buffer's count against the threshold** — the line that
`./next --findings` prints — and says **a retro is due** when it is at or over it.

Only `./next --drive` read that count, so a run a person drives filled the buffer indefinitely with
nothing to say so: one retro found 32 entries against a threshold of 8, none of them stale. The rule
sits here, in the file every stage's closing step already cites, rather than in six skills.

Reporting it is the whole obligation — a stage neither runs the retro nor stops for one.

## The hand-off line

**Every stage ends on one line, and it is the very last thing printed:**

```
<ID> — <VERDICT> — next: <stage>, status: <status>
```

It is what a reader who scrolled nothing at all still sees: what this session did to the ticket, and
which stage takes it next. That reader is usually the next session, which otherwise opens the backlog
to work out what the last one left — and `verify` shipped this line first precisely because a verdict
buried mid-report was read as the opposite of what it said.

The verdict word and the values a stage may legitimately print are **that skill's own**, stated in its
closing step: only the stage knows which outcomes it can reach, and a shared list of them would be
wrong for every skill at once. What is shared is the shape and the position.

**Adding or renaming a verdict word is editing `skills/orchestrate/outcome.schema.json`.** Its
`verdict` enum carries the union of every stage's vocabulary and a driven session validates against
it, so a stage printing a word the enum lacks is a correct stage that reads as a schema failure and
escalates. No guard catches it: the line's *shape* is asserted, its vocabulary is not.

**A session that holds no row** — `retro`, an ad-hoc `prototype`, a standing `design` question — writes
a dash in the ID slot and names the command that runs next in place of a stage: `next: /queue`.
Holding no ticket is not an exemption; "nothing to hand off" is itself the answer a reader needs.

Nothing follows it. Not a sign-off, not a closing offer, not one more caveat — a line with prose under
it is not the last line, and the scroll it saves is the entire feature.
