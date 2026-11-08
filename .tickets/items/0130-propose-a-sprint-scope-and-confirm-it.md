---
id: "0130"
title: Propose a sprint scope and dispatch nothing until a person confirms it
type: feature
next:
status: done
qa_level: verify
close_by: verify
size: l
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0038", "0135"]
expects:
  - skills/orchestrate/SKILL.md
  - tests/orchestrate.test.sh
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-10
---

## Problem

**The skill dispatches on `--drive`'s first decision line, and a person sees the shape of the run
only afterwards.** Step 1 prints a depth line — *"Nine develop gates takeable; runs dry at 0080"* —
and Step 2 dispatches. Nothing between them asks whether that is the work anyone wanted.

**The gate is the wrong unit to show a person, and this is measurable rather than theoretical.** Run
on 2026-09-09, `./next --drive` returned:

```
DEPTH     10 develop gate(s) takeable; runs dry at 0080 (next: design — a person decides)
DISPATCH  develop 0111 0114 0075 0089 0126 0091 0127 0064 0112 0100 0101 0113 0118
```

Thirteen tickets. Their `expects:` lists show what actually binds them:

| joins the gate via | tickets |
|---|---|
| `skills/retro/SKILL.md` | 0114, 0075, 0126, 0091, 0127, 0064, 0112, 0100, 0113, 0118 |
| `references/CONVENTIONS.md` | 0101 |
| `tests/retro-tool-edit.test.sh`, one of the 21 files it names | 0089 |

Every one joins through the **lead's** `expects:`, and the lead is 0111. So the gate is held together
by a hub file, which is the sweep `gate_from`'s own comment warns about. 0064 is a README and
CLAUDE.md sweep, 0089 is a guard audit, 0114 is retro's release chain: three unrelated efforts, one
gate. The grouping is right — those tickets genuinely cannot run concurrently — but presenting it as
a coherent slice is how a person approves thirteen tickets meaning to approve four.

**A count alone would not have shown it.** "13 tickets" reads as a large sprint; "13 tickets, ten of
which are here because they all edit `skills/retro/SKILL.md`" reads as a grouping artefact, and only
the second is actionable.

**Taking part of a gate has a real and payable cost that nobody is currently told.** Selecting four
of the thirteen leaves the other nine un-takeable while the four are in progress — their `expects:`
overlaps the in-progress `touches:`. They were un-takeable anyway; the cost is re-paying one session
startup floor later, about **$4.03** at the develop mean. That is a fine price for not doing nine
tickets nobody chose, and it is a decision a person can only make if they are shown it.

## Functional requirements

- FR1 — `sprint` dispatches no stage session until a person has confirmed a proposal. The probe, the
  supervisor marker and the depth read all still happen first; what is gated is the first *stage*.
- FR2 — The proposal states **how many tickets** the sprint expects to work.
- FR3 — The proposal names **which tickets**, by id and title.
- FR4 — The proposal says **what the work is** for each, in one line drawn from the ticket rather
  than invented.
- FR5 — The proposal says **why these tickets** — and where a gate is held together by a shared
  file, it names that file and how many rows join through it, so a grouping artefact is visible as
  one rather than presented as a theme.
- FR6 — The proposal carries an **estimate in real-world time, tokens and dollars**, sourced per
  `0135`. Where no prior exists for a figure it is labelled an estimate with no prior rather than
  presented as derived — `MEASUREMENT.md` records no wall-clock data at all, so the time figure has
  no basis until `0135` accumulates one.
- FR7 — Where the proposal takes **part** of a gate, it names the rows left behind and states the
  cost of resuming them later as one additional session floor.
- FR8 — The confirmed scope is written to the run log before the first dispatch, so a resuming
  supervisor reads what was agreed rather than re-deriving a scope the person never saw.
- FR9 — A person may confirm, amend the scope, or decline. Declining ends the run without a stage
  session and releases the supervisor marker.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The proposal is built from the `--drive` call and the item frontmatter the skill reads anyway; it adds no per-cycle turn, and the supervisor's turn budget in the skill's own bound section still holds | `observability-conventions.md` |
| Documentation | The confirmed scope is recorded in the run log, which is provenance and not state — the backlog stays the authority for what to do next | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a backlog with takeable work, when `sprint` runs, then no `claude -p` stage
      process is started before a confirmation is received. **Red if** the skill dispatches on
      `--drive`'s exit 0 as it does today.
- [x] AC2 — Given the 2026-09-09 backlog state, when the proposal is produced, then it names
      `skills/retro/SKILL.md` and the count of rows joining through it. **Red if** the proposal
      lists thirteen ids with no grouping reason, which is the current depth line plus a count.
- [x] AC3 — Given a proposal, when it is printed, then it carries all five of count, ids, per-ticket
      work, reason, and a three-part estimate. **Red if** any one is absent — checked as five
      separate assertions, not one, so a proposal missing only the estimate still fails.
- [x] AC4 — Given a proposal taking part of a gate, when it is printed, then it names the rows left
      behind. **Red if** a partial gate is proposed with no mention of the remainder, which reads as
      though nothing was displaced.
- [x] AC5 — Given a person declining, when the run ends, then no stage ran and
      `.claude/backlog/runs/.active` is removed. **Red if** the marker is left behind, which makes
      the next sprint report the backlog as held by another supervisor.
- [x] AC6 — Given a confirmed proposal, when the first stage is dispatched, then the run log already
      contains the confirmed scope. **Red if** the scope is written after the dispatch, which is the
      ordering that loses it when the first stage is what kills the supervisor.

## QA plan

- **Why that level:** no runner applies to a skill's prose contract, but each criterion is a
  mechanical check — a `grep` over the skill for the required proposal elements, and a scripted
  reading of a run log fixture for AC5 and AC6.
- **Specific checks:** `tests/sprint.test.sh` asserts FR2–FR7 are each stated in the skill; a run-log
  fixture exercises AC5 and AC6; the AC2 assertion runs the real `./next --drive` against a fixture
  backlog rather than the live one, so the guard does not change meaning as the queue drains.

## Out of scope

- Changing `gate_from`'s grouping. The gate is correct as a conflict unit; this ticket makes its
  composition legible. Whether two gates can overlap each other is `0136`.
- The estimate's accuracy or its learning loop — that is `0135`. This ticket consumes whatever
  `0135` provides and labels what has no prior.
- Any interactive UI. The proposal is printed and confirmed in the conversation.

## Notes & decisions

- **2026-09-09 — the proposal is what makes a hub-file gate survivable.** The alternative considered
  and rejected was tightening `gate_from` to exclude hub files. Rejected because the gate's job is
  conflict avoidance and it is doing that correctly: those thirteen rows genuinely collide. The
  defect is presenting a conflict group as a plan, which is a reporting problem, not a grouping one.

- **2026-09-10 — built as `orchestrate`, not `sprint`, and the QA plan's file name is a
  substitution.** Every FR here says "`sprint`"; no such skill exists — the rename is `0129`, still
  `blocked`. The work landed in `skills/orchestrate/SKILL.md` and `tests/orchestrate.test.sh`, and
  **the QA plan's `tests/sprint.test.sh` does not exist and will not until `0129` lands**. The next
  QA pass reads the plan, not this note, which is why it is recorded here as well: the named checks
  are in `tests/orchestrate.test.sh` (the prose contract) and `tests/next.test.sh` (the mechanical
  half). Nothing was renamed in passing.
- **2026-09-10 — AC2's numbers are the ticket's, and the live gate is now 41 rows, not 13.** With
  `0142` leading, `./next --drive` returns 41 ids, of which **16 join through
  `tests/citations.test.sh`** — a worse instance of exactly the defect this ticket describes, and
  confirmation rather than staleness. AC2's guard is pinned to a purpose-built fixture for that
  reason: a case written against either number would have been wrong within a day.
- **2026-09-10 — the first working implementation reproduced the defect one level down, and that
  changed the design.** Printing every file two or more rows share gave **34 `JOIN` lines over the
  41-row gate**, of which the top one was the whole story. A person made to read 34 lines to find
  the hub is exactly where the bare count left them. So the block is capped at the five files
  explaining the largest shares (`PROPOSE_JOIN_CAP`) and **the remainder is counted, never dropped**
  — a block that silently stops listing is a proposal whose numbers cannot be reconciled against the
  gate it describes. A guard drives the cap and the tail count, and mutating the ranking to
  first-seen reds it.
- **2026-09-10 — the gate has two join mechanisms and a proposal explaining one mislabels the
  other.** `gate_from` batches on a shared `parent:` as well as on a shared file. A row that joined
  by slice and names no shared file would have appeared in the list with nothing to explain it —
  which is the row a person is most likely to think was included by mistake. Hence the
  `JOIN      parent NNNN` line.
- **2026-09-10 — `WORK` is the first *paragraph*, never the first source line.** Taking the line
  produced cuts mid-clause, because these sections are wrapped prose and a line break is a
  typographic accident: the live backlog gave *"…is invisible to the only reader that is"*. Flattened
  then truncated on a width `problem_line` chooses.
- **2026-09-10 — FR6's estimate has no wall-clock prior today, and that is the case FR6 describes
  rather than a gap in this build.** `0135` is `ready`, not done, so nothing sources an elapsed-time
  figure; `MEASUREMENT.md` records none at all. The section therefore requires the time figure to be
  **labelled as having no prior**, sources tokens and dollars from `MEASUREMENT.md` and
  `config.yml`'s gate model, and quotes no figure of its own — a quoted figure is a cache of another
  file, and `tests/money-in-skill-prose.test.sh` independently enforces that here.
- **2026-09-10 — the section is unnumbered on purpose; do not "tidy" it into Step 2.** Renumbering
  Steps 2-9 would re-aim every ordinal anchor (`testing-conventions.md`: an assertion anchored to an
  ordinal is re-aimed rather than broken) and would require editing `skills/retro/SKILL.md`, which
  cites `orchestrate` Step 8 and which this ticket does not own. The file already carries an
  unnumbered section before Step 1, so this is the existing shape, not a new one. AC1's ordering
  guard anchors to the dispatch's own `--session-id` line for the same reason.
- **2026-09-10 — a correct skill reddened AC3, and the bug was in the matcher.** `how many tickets`
  and `why these` both open bolded bullets, so they are capitalised, and `grep -F` is
  case-sensitive. `testing-conventions.md` names this as the mirror of the absence-grep casing trap.
  Fixed with a `says_ci` helper — **normalise in the matcher, never choose the prose to suit the
  guard**.
- **2026-09-10 — `git checkout --` deleted an uncommitted refactor mid-sweep, exactly as `develop`
  Step 5 warns.** The main work was committed and then mutated safely; the loss came from making a
  *further* uncommitted change (the `pb_` rename) and reverting a mutation over it. The restore is
  silent and the suite stays green, so nothing signals it — `grep -c pb_` returning 0 is what found
  it. The rule as written already covers this; it was not applied.

## QA evidence

**Session token `a3f1`, 2026-09-10.** `qa_level: verify` — the scripted assertions the QA plan
names, executed, plus a mutation run behind every check cited below. No lint or typecheck is
configured, so neither was run. Suite tallies are pasted from the commands that produced them:
`tests/orchestrate.test.sh` **153 passed, 0 failed, 0 skipped**; `tests/next.test.sh` **303 passed,
0 failed**.

**Which copy executed.** The repo copy is the authority and is what was tested.
`~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.23/skills/orchestrate/SKILL.md`
carries no proposal section — `grep -c` returns 0 — so this change is **not live in the installed
plugin** and will not be until a version bump and `tools/release`. That is the normal state at
close, not a defect of this ticket.

**Drift, as `verify` Step 2 requires it be reported rather than quietly honoured.** The QA plan
names `tests/sprint.test.sh`, which does not exist and will not until `0129` renames the skill. The
checks were read from `tests/orchestrate.test.sh` and `tests/next.test.sh`, as the 2026-09-10 build
note says. Frontmatter `qa_level: verify` and the QA plan's level agree; only the file name drifts.

| # | How it was checked | Result |
|---|---|---|
| AC1 | `tests/orchestrate.test.sh`, three assertions: proposal section before the dispatch's own `--session-id` line (81 < 104), after the marker `mkdir`, and the section forbidding a stage session. **Mutation:** renaming the `## The proposal` heading → **19 failed**, so the AC's own "red if" (dispatch on exit 0 with no proposal) is caught. | PASS, with a gap below |
| AC2 | `tests/next.test.sh` against the purpose-built five-row fixture: `JOIN hub/shared.md \| 3 of 5 rows`, `edge/other.md \| 2 of 5`, `parent 0091 \| 2 of 5`, and the out-of-gate row `0109` absent from every denominator. **Mutations** on `skills/queue/templates/next` (the copy the harness runs): suppress the JOIN line → 3 failed; count single-row files → 3 failed; drop the tail count → 1 failed. Live surface: `./next --drive --propose` on today's backlog printed `tests/citations.test.sh \| 16 of 41 rows join through this file` above four lesser files and `29 further file(s) … not listed`. | PASS, with a gap below |
| AC3 | Five separate section-scoped assertions in `tests/orchestrate.test.sh` (count, ids, per-ticket work, why these, three-part estimate), plus the mechanical half in `tests/next.test.sh`. **Mutations:** blanking the estimate bullet → 1 failed; weakening "How many tickets" → 1 failed; `PROPOSE %s \| 99 ticket(s)` → 3 failed; suppressing the `TICKET` line → 3 failed; suppressing the `WORK` line → 1 failed. The matcher is `says_ci`, section-bounded and line-joined, so no assertion can be satisfied from elsewhere in the file. | PASS |
| AC4 | Assertions on `rows left behind` and `session floor`. **Mutations:** removing each phrase → 1 failed apiece. | PASS |
| AC5 | The decline path names `.claude/backlog/runs/.active` and is one of three stated answers. **Mutation:** replacing the literal path with "the marker" → 1 failed. | PASS |
| AC6 | Skill-side: `Step 5` names `scope_confirmed`, and the section states the ordering. **Mutation:** "before the first dispatch" → "at some point" → 1 failed. | PASS |
| NFR Performance | `--propose` is opt-in and adds no turn: guard *"the proposal is opt-in, so a cycle after the confirmed one pays nothing for it"* asserts a later cycle prints no proposal and dispatches the same gate. Confirmed at the surface — one `./next --drive --propose` call produced the whole block. `observability-conventions.md` read. | PASS |
| NFR Documentation | The scope is one `scope_confirmed` run-log event; `Step 5`'s *"provenance, not state"* paragraph is unchanged, so the backlog stays the authority. `documentation-conventions.md` read. | PASS |

**Always-on pass (`CONVENTIONS_CORE.md`).** No secrets, no home paths, no company material in the
diff (`company: none` holds — the repo is public). `tests/citations.test.sh` 46/0,
`tests/money-in-skill-prose.test.sh` 12/0 (FR6 quotes no figure), `tests/skill-size.test.sh` 27/0,
`tests/last-line.test.sh` 17/0, `tests/falsifiable-acs.test.sh` 17/0, `tests/item-ac-form.test.sh`
4/0, `tests/qa-level-once.test.sh` 11/0. Newly reachable paths: `--propose` is a read-only flag
adding no destructive or privileged route.

### Two gaps, published rather than papered over

- **The JOIN ranking has no guard, and the 2026-09-10 build note saying it has one is wrong.**
  That note reads *"a guard drives the cap and the tail count, and mutating the ranking to
  first-seen reds it"*. The first half holds — both mutations redden. The third does not:
  replacing the selection sort's comparison with `;` on `skills/queue/templates/next` left
  **303 passed, 0 failed**, with a green control either side. The cap fixture is eight rows each
  naming the hub plus two `pair/N.md` files, so first-seen insertion order is hub, `pair/1`,
  `pair/0`, `pair/2`… — the hub is still first and `pair/7` is still dropped, so both
  `assert_contains` and both `assert_not_contains` hold under either ordering. `assert_contains
  "the hub leads the block"` asserts presence, not position, so nothing in the file tests rank at
  all. The ranking **works** — today's live run printed 16, 9, 8, 8, 7 in descending order — it is
  only unguarded. No assertion was invented to close this; per `verify` Step 3 it is recorded and
  left uncovered.
- **AC1's prose assertion is satisfied by a sentence belonging to AC5.** `says "$SKILL" "$PROPSEC"
  'no stage session'` also matches the decline sentence, *"…which ends the run with no stage session
  and releases the marker"*, inside the same section. Deleting FR1's actual prohibition —
  *"Dispatch no stage session until a person has confirmed the scope."* — leaves **153 passed, 0
  failed**. AC1 still passes on its two ordering assertions, which redden hard, but one of its three
  legs measures something adjacent.

Both belong to `0089`'s sweep (*guards for assertions that cannot fail*), which is already `ready`
in the queue; neither is a new criterion for this ticket, and neither falsifies an AC.

### Noted, not blocking

- Three AC6 assertions (`run-good`/`run-late`/`run-none`) run an `awk` reader defined inside
  `tests/orchestrate.test.sh` over fixtures defined in the same file. They prove the ordering is
  *decidable* and can fail in both directions, which is what they claim — but they observe neither
  the skill nor the script, so no change to either can redden them. AC6's real guard is the
  skill-side pair, which does redden.
- `skills/orchestrate/SKILL.md:267` is 149 characters, left by this change's rewrap of Step 5's
  first paragraph. In a repo whose every guard greps prose line-by-line
  (`CLAUDE.md`, *rewrapping a guarded paragraph is a breaking change*), an unwrapped line is a
  latent hazard for whatever asserts over that paragraph next.
- 🔍 Probed the flag's misuse paths at the CLI: `./next --propose` → exit 2, `unknown stage:
  --propose`; `./next --drive --propose=1` → exit 2, `unknown argument to --drive: --propose=1`.
  Both name the flag they could not place, and `--help` carries `--propose` on the usage line.
