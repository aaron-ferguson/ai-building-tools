---
id: "0074"
title: Give the suite one reporting rule and route the detail to disk
type: debt
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-30
source: user
parent:
blocked_by: []
relates: ["0009", "0036", "0039", "0073"]
expects:
  - references/REPORTING.md      # new — the single home for the rule
  - skills/develop/SKILL.md      # Step 8
  - skills/verify/SKILL.md       # Step 7
  - skills/queue/SKILL.md        # Step 8
  - skills/retro/SKILL.md        # Step 7
  - skills/design/SKILL.md       # Step 6
  - skills/prototype/SKILL.md
  - tests/reporting.test.sh      # new guard
  - tests/reference-size.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A stage session narrates continuously, and inside a 39-turn session every sentence it writes is
paid for again on every turn that follows it.** Aaron's request, verbatim, 2026-08-30:

> In addition to taking a lot of turns per session, another piece that I assume would make a big
> difference is that right now the agents are fairly verbose and give a lot of updates instead of
> giving critical updates only. Being willing to go into additional context when requested, we could
> save a lot of tokens by simply consolidating and summarizing agent work.

**The cost premise was measured on 2026-08-30 and does not hold — see *Notes & decisions*.** Human-facing
narration is **4.6% of output tokens**, and deleting every word of it saves **1.7% of a session**. The
ticket survives on a different argument, which `0036` had already found from the other direction: **the
report is where a lesson goes to die.** A stage with an audience writes its diagnosis to the audience
instead of to `FINDINGS.md` or *Notes & decisions*.

**Nothing in the suite covers this surface today.** `0036`'s FR13 trims what a stage returns **to a
supervisor**, enforced by `--json-schema` — a machine consumer, and only in an orchestrated run. What a
stage tells a **human in its own terminal** has no rule at all: each skill's closing step says what to
report, six times over, and nothing says where the detail should have gone instead.

**The boundary this ticket must not cross is already fixed and was fixed for a reason.** `0036`'s
cross-cutting commitments: *"No rule is dropped anywhere in this project… the trim is to a stage's
closing narrative, never to a check, a test or a standard."* Aaron's framing agrees — *"I don't want to
neuter the power of these tools"*. A trim that quietly removes a step's output removes the step, because
a step with no visible output is the kind this project has already recorded getting dropped: parking a
finding, running the full suite, releasing a claim.

## Functional requirements

- FR1 — The reporting rule is stated **in exactly one place** and cited by every stage skill, never
  restated in each. Six copies of a paragraph is six things to drift.
- FR2 — The rule names the **expansion path**: what the human does to get the detail, and what the
  session then produces. A default with no way back is a deletion, not a summary.
- FR3 — **No check, test, standard, or durable write is removed or weakened.** What shrinks is what
  reaches the screen; what reaches disk — a ticket's *Notes & decisions*, `FINDINGS.md`, the item file,
  the commit — is unchanged or larger. Inherited unchanged from `0036`'s cross-cutting commitments.
- FR4 — The terse human report and `0036` FR13's machine outcome **do not state different facts** about
  the same run. One of them being shorter is fine; them disagreeing is not.
- FR5 — Whatever the rule turns out to be, it is **enforced by something that fails** — a guard in
  `tests/`, in the manner every other rule in this repo is held — and not only by prose describing
  itself. A rule about what a skill says, verified only by reading the skill that says it, verifies its
  own documentation.
- FR6 — The rule lives at `references/REPORTING.md` and is a **routing rule, not a verbosity budget**:
  it says where each kind of content goes, and the screen getting quieter is a consequence rather than
  the instruction. **No token, word, line or sentence budget appears anywhere in it** — the measurement
  in *Notes & decisions* is what disqualifies one.
- FR7 — The default screen set is **exactly four kinds**, and everything else routes to disk:
  **(a)** state changes the session made that outlive it — the row claimed, the commit written, the
  transition taken; **(b)** what failed, what was skipped and what it refused to do; **(c)** what the
  session needs from the human — a decision, an approval, the next command; **(d)** where the detail
  landed, as paths.
- FR8 — The rule binds a skill's **step-level reports only** — the ones its own steps instruct — and
  **says so, with the reason**. It does not attempt to govern per-turn commentary.
- FR9 — The expansion path of FR2 **is the durable artifact** named by FR7(d). The rule introduces
  **no flag, no trigger phrase and no verbosity mode**.
- FR10 — Where `references/REPORTING.md` leans on the log-level distinction between what needs a human
  and what is merely notable, it **cites `observability-conventions.md`** rather than restating the
  levels, per `references/CONVENTIONS.md`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The decision, what it rejected, and the boundary in FR3 are recorded in *Notes & decisions* when settled, not at the end. The rule itself pays context rent on every session of every project, so it is written once and short. | `documentation-conventions.md` |
| Observability | A session that reports less must not become a session whose failures are less visible. FR7(b) is the discharge of this and is not optional. | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the six stage skills, when each is read, then each cites `references/REPORTING.md`
      exactly once in its Report step and states no default report set of its own. **Red when** a skill
      file enumerates what to report inline instead of citing.
- [ ] AC2 — Given `tests/reporting.test.sh`, when run against a tree in which any one stage skill's
      citation of `references/REPORTING.md` has been deleted, then it exits non-zero and names that
      file. **Red input: delete the citation line from `skills/design/SKILL.md`.**
- [ ] AC3 — Given `references/REPORTING.md`, when read, then it lists the four content kinds of FR7 and
      gives each an explicit destination, screen or disk. **Red when** a kind appears with no
      destination.
- [ ] AC4 — Given `references/REPORTING.md`, when read, then the expansion path is a file path a human
      can open. **Red input: a `--verbose` flag or a "just ask" trigger phrase appearing in the file**,
      which `tests/reporting.test.sh` greps for and fails on.
- [ ] AC5 — Given `tests/reporting.test.sh`, when run against a `references/REPORTING.md` containing a
      numeric token, word or line budget, then it exits non-zero. **Red input: insert the line
      `Keep the report under 200 tokens.`** Guards FR6.
- [ ] AC6 — Given `verify` Step 7 and `develop` Step 8 after the change, when read, then no step that
      performed a check has lost its only visible output. **Red when** a report line is deleted and its
      content appears in no item file, `FINDINGS.md` entry or commit. Guards FR3.
- [ ] AC7 — Given `references/REPORTING.md`, when read, then it names `0036` FR13's machine outcome as
      the other channel and states that the two carry the same facts at different lengths. **Red when**
      the file describes the human channel as the only one. Guards FR4.

## QA plan

- **Level:** verify — the change is prose in skill files and a guard over it; no runner applies.
- **Why this level:** matches every other skill-file ticket in this backlog.
- **Specific checks:**
  1. `tests/reporting.test.sh` passes on the tree, and fails on each of the three red inputs named in
     AC2, AC4 and AC5 — each injected and reverted, not merely asserted to be caught.
  2. `tests/reference-size.test.sh` passes with `references/REPORTING.md` in scope, or records a reason
     for its overage per that guard's soft-goal contract.
  3. The full suite: `for t in tests/*.test.sh; do "$t" || exit 1; done`.
  4. Per this repo's `CLAUDE.md`, **every phrase the new guard greps for sits on one line** in
     `references/REPORTING.md` and in each skill, so a later rewrap cannot silently red it. Check by
     rewrapping a guarded paragraph in a scratch copy and confirming the guard still fires.

## Out of scope

- **Changing `0036` FR13's outcome schema.** `0039` owns it; FR4 here only requires consistency.
- **Reducing what a stage writes to disk.** The opposite: FR3 requires the detail to land durably.
- **Cutting the turn count.** `0073` owns it, and after this ticket's measurement it owns the *whole*
  cost case — see *Notes & decisions*.
- **Constraining per-turn commentary.** Ruled out on evidence rather than deferred; FR8 records it.
- **Relaxing any standard, or removing any step.** `0009`'s commitment, inherited.

## Notes & decisions

- **Routed to `design`, and deliberately not blocked on `0073`.** `0073` sizes the compounding half and
  would sharpen the target, but the design question — what a human needs to stay in the loop — is
  answerable without it, and `0073` sits behind two tickets.

### The design answer, 2026-08-30 (claim `5ac2`)

**Question:** what must a stage session put on the human's screen while it runs, and what becomes
available only when the human asks for it?

**Answer: the four kinds in FR7 stay on the screen, everything else is written to disk, and there is no
"asking" — the disk *is* the expansion path. The rule is a routing rule, not a verbosity rule.**

**The cost premise did not survive measurement, and the ticket asked for it to be checked.** Its own
words: *"this ticket must not be specified from the 22.5% figure alone"*, naming the compounding half as
the thing nobody had sized. Sized, from this repo's 81 transcripts and 3,088 turns:

| Term | Share of output tokens |
|---|---|
| Human-facing narration (`text` blocks) | **4.6%** — 43 tokens per turn |
| Tool-call inputs — the edits, writes and greps | 24.9% |
| Thinking | **70.5%** |

Narration's **lifetime** cost, direct output plus one cache write plus re-reads at `$0.50/M` over the
remaining turns, is **1.64x** its direct cost in a 39-turn session — so **deleting every human-facing
word saves 1.7% of a session**, and halving it saves 0.85%. The multiplier is 1.52x at 27 turns and
2.25x at 100, so the answer is **1.6%–2.4% across any plausible session length**: `0073`'s figures can
sharpen this but cannot reverse it.

Two consequences fall straight out, and they settle the ticket's two sub-questions.

- **(a) Can a skill file constrain per-turn commentary?** No, and it should not try. At 43 tokens per
  turn the per-turn surface is already terse, and the dominant output term is **thinking at 70.5%**,
  which no instruction in a skill file governs and which the stored transcript does not even retain —
  the `thinking` field is empty and only a `signature` survives, so it cannot be measured from the
  record either. FR5 independently rules it out: nothing can grep a session's running commentary, so a
  per-turn rule could only ever be prose describing itself. FR8 records this rather than leaving it to
  be re-asked.
- **(b) What does "on request" mean concretely?** **The durable artifact, not a flag or a phrase.** The
  detail is already required to be on disk by FR3 and by `0036` FR14. A `--verbose` mode would be a
  second channel for content that is required to exist in the first, and a skill file cannot implement
  a flag in any case. So the report's last line names paths, and the human opens them — or asks the
  session, which is still live.

**What the rule is actually for, since it is not tokens.** `0036` reached this independently and it is
quoted rather than re-derived: *"The real argument is behavioural: the report is where a lesson goes to
die. A stage with an audience writes its diagnosis to the audience instead of to `FINDINGS.md` or
*Notes & decisions*. Removing the audience removes the sink."* `MEASUREMENT.md` supplies the evidence
that this is a live failure and not a theory — 42 findings parked across two days against the baseline
run's 4, *"of which two existed only in conversation and would have been lost."* Routing to disk is
therefore the requirement and brevity is the side effect, which is why FR6 forbids a word budget: a
budget would buy the 1.7% and miss the point entirely.

**Rejected, with what would have to be true for each to win.**

- **A verbosity budget per step report** — the shape the ticket implies. Wins if narration were a
  material share of spend. It is 4.6% of output and 1.7% of a session; `0036` had already priced the
  closing report at ~800 tokens, *"roughly 0.3% of the $4.45-per-closed-ticket baseline. Nobody should
  spend a requirement on that."* Two independent measurements, same verdict.
- **A `--verbose` flag, a trigger phrase, or a standing user default.** Wins if terse mode actually
  destroyed information. FR3 and `0036` FR14 guarantee it does not, so the flag would gate access to a
  file the human can already open. Also unimplementable: a skill file cannot add a flag to its own
  invocation.
- **Closing the ticket as not worth doing.** The strongest rival, and it wins **if Aaron's goal is
  cost** — because on cost the honest answer is that this ticket is worth ~1.7% and `0073`'s turn-count
  work is worth ~2.6% *per turn removed*. It loses only on the behavioural argument above. This is
  flagged rather than buried: it is a re-ranking call, and it is Aaron's.

**The trade-off being accepted.** The ticket was filed as a cost saving and is being specified as a
quality fix; the screen gets quieter only incidentally. And a routing rule is **harder to enforce than a
word budget** — a guard can count words, but nothing can check that a lesson went to disk *instead of*
the screen. AC1 and AC2 check citation, not compliance; the compliance signal is the findings-parked
count `0036` AC21 already puts in the supervisor's cycle report, and outside an orchestrated run there
is none. That gap is real and is not papered over.

**Two amendments made rather than left implied.**

1. **Retitled**, from *"Decide what a stage session tells the human as it runs, and cut the rest"*. The
   old title asserts the cut this decision declines to make for the stated reason, and a title that
   contradicts the ticket's own answer is exactly what re-litigation grows from.
2. **`size` re-checked and stays `m`**, per `queue`'s amend rule. The decision *removed* scope — no
   per-turn rule, no flag, no verbosity mode to build — leaving one new reference file, six one-line
   citations and one guard. It stays `m` rather than dropping to `s` because the guard has three red
   inputs to satisfy and the reference file is new surface under `reference-size.test.sh`.

**How the measurement was taken, so it can be re-run or disputed.** Assistant `text`, `tool_use` and
`thinking` blocks were counted across every `*.jsonl` in this project's transcript store, deduplicated
by `message.id` the way `tools/harvest-usage.sh` defines a turn, with output tokens taken from each
turn's `usage`. **Narration and tool-input tokens are estimated at 4 characters per token and thinking
is the residual** — that is the weak point, and it is why the figure is quoted as a share rather than to
the token. It does not threaten the conclusion: narration would have to be **six times** the measured
share before halving it bought even 5% of a session. **`0073` owns turning this into a recorded,
scripted measurement**; it is deliberately not scripted here, because that is that ticket's job and
duplicating it would put two recipes in the repo.
