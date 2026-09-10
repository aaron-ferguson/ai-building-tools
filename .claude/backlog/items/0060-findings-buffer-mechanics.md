---
id: "0060"
title: Decide how the findings buffer is emptied and gated
type: chore
next:
status: done
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0012", "0014", "0016", "0036", "0038", "0080", "0111"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
  - skills/queue/templates/FINDINGS.md
  - .claude/backlog/FINDINGS.md
  - skills/queue/templates/item.md
  - references/REPORTING.md
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-10
---

## Problem

`FINDINGS.md` is emptied by two sweepers that take different things, and every mechanism around it
assumes one. Five defects, and the first makes the gate permanently unsatisfiable.

**The retro gate counts a number retro cannot reduce.** `findings_threshold: 8` is read by
`./next --findings` and gated on by `--drive` (exit 5), and it counts *every* entry in the file. The
sweepers are not symmetrical: the 2026-08-25 retro processed 16 of ~100 and left the rest, almost
all of them units of work only `queue` can take. So the gate diverts drivers into a retro that reads
the remainder again and correctly finds nothing new, and no number of retros can clear it — only a
`queue` sweep can, and nothing gates on that. The count the gate wants is entries a *retro* could
act on, or the gate belongs on both sweepers.

**An entry taken by both sweepers has no way to record that one half is done.** The header says an
entry that is both a lesson and a unit of work is taken by both, and `retro` Step 4 says to leave
the work entries — so an entry whose lesson has landed stays in the file, unmarked, and the next
retro pays full price to read it and re-derive that there is nothing left to do. The 2026-08-25
retro named five it kept in exactly that state.

**No sweeper has a procedure for a buffer far past its threshold.** `queue` Step 5 says "for each
entry that is a unit of work, do the Step 2 work properly" — right per entry, silent on everything
that matters at 86 entries. Nothing says to cluster first, nothing says an entry and a ticket are
not one-to-one, and nothing says what a sweep does when the honest answer is more tickets than one
session can write. The 2026-08-25 sweep clustered by root cause, asked the user to scope, took two
tiers and left the rest; every one of those decisions was invented, and the bundling question has a
real trade-off in this repo — narrower `touches:` collides less, while one rule landed three times
drifts.

**Entries cross-reference each other by quoted phrase, so removing one silently breaks another.**
The surviving `design` Step 4 entry quotes a sibling entry that the same sweep processed into 0050
and removed. The reference now resolves to nothing, and it is worse than a dead link because the
sentence still reads as though the evidence is at hand. Neither sweeper is told to look, and a
quoted phrase is not a key, so nothing could look automatically.

**And the dates carry no timezone.** `claimed_at:` is specified as ISO-8601 UTC; `created:` and
these entries are bare dates. At 2026-08-23 local / 2026-08-24 UTC, two sessions working the same
hour wrote different dates and both are defensible. This matters because `retro` Step 1 expires
anything older than about two weeks.

## Functional requirements

- FR1 — The findings gate counts **every entry in the buffer**, unchanged, and the invariant that
  makes that count reducible by a retro is written down where the counting happens: `retro` is the
  **terminal sweeper**, so no entry survives the pass that read it, and every entry left is
  therefore work a retro can still do. Stated as a comment beside `count_findings` and asserted by
  a guard against `skills/retro/SKILL.md`, so the asymmetry this ticket opened on cannot return
  unnoticed.
- FR2 — Both sweepers state what a pass does when the buffer holds more than it can finish.
  `queue` Step 5: cluster the entries after reading them, an entry and a ticket are not
  one-to-one, and what is left behind is named in the report. `retro` Steps 1 and 2: **reading is
  cheap and only writing is sliced** — the slice is chosen *after* the cross-entry read, never
  before it, because that read is what tells you which entries are one lesson.
- FR3 — The entry format states that a cross-referencing entry names the item id or file path it
  refers to rather than quoting a sibling.
- FR4 — Dates written into the backlog and this buffer state their timezone, matching
  `claimed_at:`'s existing ISO-8601 UTC.
- FR5 — Whatever mechanism FR1 lands, the code that implements it is named: `count_findings` in
  `skills/queue/templates/next` and its installed copy, not only the prose.
- FR6 — `queue` Step 5 states that when a ticket is bundled from several entries, the removal list
  is derived from **the ticket's FRs**, not from the cluster that produced it. Sweeping this buffer's
  second batch, three of forty-six entries read as covered because a neighbouring concern in the same
  bundle was, and were caught only by a check nothing asked for; had it been skipped they would have
  left the buffer with no ticket, no trace, and a sweep reporting success.
- FR7 — The hand-over marker moves to a **greppable head token**, immediately after the date:
  `- 2026-09-05 [->0060] — **what happened.** …`. `[->NNNN]` means a row now carries this entry's
  work half; `[->none]` means a pass read the entry and established that no destination exists yet.
  The header specifies the token, states that it is written on the way **out** by a sweeper and
  never at write time by the noticer, and states that it does not change what the gate counts. The
  old trailing-prose form stays readable: nothing rewrites an entry it is not processing.
- FR8 — `queue` Step 5 carries the **absorbed** disposition it lacks: a swept entry whose work half
  an existing row already carries is not a new row and not a `next: queue` stub — name the row,
  append one dated line to its *Notes & decisions*, mark the entry `[->NNNN]`, and remove it only
  if it holds no lesson half.
- FR9 — The gate reaches a hand-driven run. `references/REPORTING.md` states that a stage session's
  report carries the buffer's count against the threshold — the `./next --findings` line — and says
  a retro is due when it is at or over. One rule, in the file every stage's report step already
  cites, rather than a paragraph in each skill.
- FR10 — The gate counts the buffers the retro it would dispatch will actually read: the resolved
  local buffer, **plus the tools repo's buffer where `config.yml` resolves `tools.path`** (`retro`
  Step 1, and *Routing a finding to the repo it is about*). Where `tools.path` is absent or does not
  resolve, the count is the local buffer alone and the line says so. Sibling backlogs under a shared
  workspace are **not** counted: `0111` FR5 makes them unreachable by construction, and a gate
  counting a buffer its retro cannot reach is the defect this ticket opens with.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | An entry-format change meets ~60 existing entries; readers must accept the old form before anything requires the new one, and no sweeper rewrites entries it is not processing | `migration-conventions.md` |
| Progressive delivery | `--drive`'s exit codes are a stated contract 0038 built against; changing them reaches installed copies only through the version bump | `progressive-delivery-conventions.md` |
| Documentation | The buffer's header is the specification readers actually follow, so it changes in the same commit as the sweepers | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a buffer every entry of which a retro pass has dispositioned, when
  `./next --findings` runs, then it reports `0 entries` and `under the threshold`.
- [x] AC2 — Given `skills/queue/SKILL.md` Step 5, when read, then it states what a sweep does when
  it cannot finish: that entries are clustered after reading, that an entry and a ticket are not
  one-to-one, and that what is left behind is reported.
- [x] AC3 — Given the buffer's header in `skills/queue/templates/FINDINGS.md`, when read, then it
  states that a cross-referencing entry names an item id or a file path rather than quoting a
  sibling entry.
- [x] AC4 — Given the buffer's header and `skills/queue/templates/item.md`, when read, then each
  states that a written date is UTC.
- [x] AC5 — Given `skills/queue/SKILL.md` Step 5, when read, then it states that a bundled ticket's
  removal list comes from its FRs.
- [x] AC6 — Given `skills/retro/SKILL.md` Step 1, when read, then it states that reading is cheap
  and only writing is sliced, and the sentence directing a pass to read fewer entries before the
  cross-entry read is gone.
- [x] AC7 — Given a buffer entry carrying a head token — `- 2026-09-05 [->0060] — **x.**` — when
  `count_findings` runs over it, then it counts as one entry and prints no `MALFORMED` line; and
  given the same entry in the bolded shape, likewise.
- [x] AC8 — Given `skills/queue/SKILL.md` Step 5, when read, then it names the **absorbed**
  disposition and what it writes: the row, one dated line in that row's *Notes & decisions*, and the
  marker.
- [x] AC9 — Given `references/REPORTING.md`, when read, then it states that a stage report carries
  the buffer count against the threshold and says a retro is due at or over it.
- [x] AC10 — Given a project whose `config.yml` resolves `tools.path` to a checkout holding its own
  `FINDINGS.md`, when `./next --findings` runs, then the reported count is the sum over both buffers
  and the line names each; and given a `config.yml` with no `tools.path`, then the count is the local
  buffer alone.
- [x] AC11 — Given `skills/queue/templates/next`, when read, then the comment above `count_findings`
  states that the count is every entry **because** `retro` is the terminal sweeper; and a guard
  asserts that sentence still stands in `skills/retro/SKILL.md` Step 4, failing if it is removed.
- [x] AC12 — Given `skills/queue/templates/next` and `.claude/backlog/next`, when compared, then
  they are identical, so the installed reader carries every change above.

## QA plan

- **Level:** unit — this project's `unit` command runs every `tests/*.test.sh`, and the answer
  touches both `count_findings` and prose, so `unit` subsumes the scripted-assertion half.
- **Why this level:** settled by the design pass — the counting change is code, so the provisional
  argument in the earlier draft no longer has to be carried.
- **Specific checks:**
  - `tests/next.test.sh` — AC1, AC7, AC10, AC12 against fixture buffers: an entry with a head token
    in both shapes, a `tools.path` that resolves and one that does not.
  - a prose guard (extend `tests/citations.test.sh` or add `tests/findings-buffer.test.sh`) — AC2,
    AC3, AC4, AC5, AC6, AC8, AC9, AC11.
  - `tests/backlog-scripts-installed.test.sh` already compares the template against the installed
    copy; AC12 is its existing assertion and needs no new guard if that holds.
  - **Quote every asserted phrase within one line of the file as it is wrapped** — `grep` is
    line-based, and a phrase straddling a wrap matches nothing and reads as absent (`CLAUDE.md`,
    *Tests*).
- **0038 and 0053 also reach `tests/next.test.sh`.** `--drive`'s exit codes are untouched by this
  answer, which is most of why the two-gate shape was rejected.

## Out of scope

- **Emptying the buffer.** That is what a sweep does; this ticket changes the mechanism around it.
- Changing what either sweeper *takes* — the lessons/work split is the design and is not in
  question.
- `retro`'s cadence.

## Notes & decisions

- **Amended 2026-08-25**, during the third sweep, adding FR6/AC5 — the bundled-removal rule.
  Re-checked: `size` stays `m` (one paragraph in a step FR2 already rewrites), the QA plan is
  unchanged because AC5 is a scoped grep on the same step, and *Out of scope* is unchanged. It
  belongs here rather than in 0057 because it is a rule about the **sweep**, which this ticket owns,
  not about a `queue` operation.
- Routed to `design` on trigger 1. The marker and the gate are one decision, not two: a marker
  makes the count derivable, and without one the gate has to be re-based on something else.
- The header's own reasoning — that nothing is tagged at write time, because classification at the
  moment of noticing is the friction worth avoiding — is a constraint on the answer, not an
  objection to it. A marker written on the way out costs the sweeper, not the noticer.
- **Evidence from the 2026-09-05 retro, which ran this buffer at 84 entries — 10.5x the threshold.**
  Recorded here rather than in `FINDINGS.md` because it bears directly on the open design question
  above. Four things that pass could see and no earlier one could:
  - **The composition of a large buffer, measured.** Of 84 entries: **21** were lessons a retro
    could land, **40** belonged to an existing ticket, **15** had no destination anywhere, and
    **8** were `queue`'s work half. So roughly half of a buffer at volume is neither a lesson nor
    a unit of work but an **unrouted note about a row that already exists** — a third category the
    header does not name, and the one that makes the count in *The retro gate counts a number retro
    cannot reduce* behave as it does. A gate counting "entries a retro could act on" would have read
    **21**, not 84.
  - **The per-entry marker was run in practice, and its format was wrong in a way worth pinning.**
    That pass wrote one as **trailing prose** on each deferred entry — `— read and triaged
    2026-09-05 by retro: belongs to item NNNN, deferred, not yet written.` It records the routing
    correctly and buys the next sweeper nothing, because partitioning the file still requires
    reading every entry to its end. A marker earns its keep only if it is greppable **at the entry's
    head**: a token after the date, `- 2026-09-05 [->0060] — **what happened.**`, partitions with one
    `grep` and preserves the `^- (\*\*)?20[0-9]{2}-` line shape every reader and `count_findings`
    depend on. If the design picks the marker shape, this is an argument for where it sits, not only
    for whether it exists.
  - **A refinement of the write-time constraint, not a challenge to it.** *Notes* above holds that
    classification at the moment of noticing is the friction worth avoiding, and that stands. But
    most of those 40 entries already carry the parking session's token (`[becd]`, `[0051]`,
    `[0f0a]`), so those sessions knew which row they held. Naming the row you were holding is not
    classification — it is not a rung, a destination or a lessons/work call, and it is already in
    the session's head. Whether that cheap hint is admissible under the same constraint is a
    question the design pass should answer explicitly rather than inherit.
  - **A scope gap in this ticket.** FR2 states what a sweep does at volume for **`queue` Step 5**.
    `retro`'s own Step 1 and Step 2 have the same problem and are covered by no FR here and by no
    row anywhere: "work in ranked slices" never says ranked by *what*, the Step 2 gate has no
    smaller form when the proposal is itself a large artifact, and Step 1's expiry is time-based
    when the pressure is volume-based — nothing expired at 84 entries, because the oldest was 12
    days old. *Out of scope* excludes `retro`'s **cadence**, which this is not. Either FR2 widens to
    both sweepers or that half needs its own row; the claiming session should decide which and say
    so.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **the gate is missing from the hand-driven
  path, and the buffer proves it.** The entry that parked this recorded the buffer at 14 against
  `findings_threshold: 8`; the retro of 2026-09-09 found **32**, four times the threshold, none of
  it stale — every entry dated within three days. `verify` has no gate on the count and neither does
  `develop`; only `./next --drive` reads it, so a hand-driven or supervised-by-a-person run fills
  the buffer indefinitely and nothing says so. Whatever this row decides about emptying, the gating
  half has to reach the stages a person drives, not only the ones a driver dispatches.

- 2026-09-09 (queue, from `FINDINGS.md` parked the same day) — **the retro-side scope gap recorded
  above has now been hit, and it names which half of Step 1 is wrong.** That pass ran the buffer at
  32 entries against a threshold of 8 with **nothing stale** — every entry dated within three days —
  so the time-based expiry dropped none, and Step 1's *"work in ranked slices — read fewer entries
  and finish each"* had no reading: there was no cheap basis for choosing a slice **before** reading,
  because the cross-entry view Step 1 exists to produce is precisely what tells you which entries are
  one lesson. The pass read all 32 and then dispositioned every one, which is the opposite of the
  instruction and was the only honest option. So the choice this row has to make on `retro`'s behalf
  is narrower than *Notes* above suggests: either the slice is chosen **after** reading rather than
  before, or the step says that **reading is cheap and only writing is sliced**. Both leave the
  cross-entry read intact; the current wording does not. Filed here rather than as its own row
  because the note above already reserves this half for whoever claims this ticket ("Either FR2
  widens to both sweepers or that half needs its own row"), and a second row would split one
  decision across two.

- **2026-09-09 (retro, from `FINDINGS.md`)** — The half this ticket reserves has now been hit from
  the other sweeper, and the shape is narrower than "one half is done". **`queue` Step 5 has no
  disposition for a swept entry whose work half an existing row already carries.** Step 5 offers
  exactly two outcomes: specify and rank it, or write an unranked `next: queue` stub. A sweep found
  an entry belonging wholly to this ticket — so a new row would have split one decision across two,
  and a stub would have been a row `develop` must refuse — and the session invented the missing
  disposition by borrowing `retro` Step 4's **absorbed**: name the row, append one dated line to its
  *Notes & decisions*, remove the entry. That is the right answer and it is not written down for
  `queue`. Note the asymmetry it exposes: both sweepers empty this file and only one of them can say
  *this already has a home*, which is also why the marker rule beside Step 5 covers only the
  work-and-lesson case and not this one. Whatever FR2 decides about counting should decide this
  alongside it — a disposition only one sweeper has is the same defect as a gate only one sweeper
  can satisfy.

- **2026-09-10 (design) — SETTLED. The gate keeps counting every entry, and the marker stays but
  moves to the head of the line.** Re-read that day against the checkout, not against this ticket's
  own summary of it, and the premise had moved: `retro` Step 4 now reads *"Every entry you read gets
  one of four dispositions — landed, absorbed, filed or dropped"* and *"no entry survives the pass
  that read it"*, and *filed* explicitly covers a pure unit of work (*"A pure unit of work is filed,
  not handed back"*). **`retro` is the terminal sweeper.** So the opening defect — a count only
  `queue` could reduce — is already discharged in prose, and what is left is an invariant nobody
  wrote down: the count is every entry *because* every entry is retro-actionable. FR1 states it
  beside `count_findings` and guards it; that is the whole of the counting change.
  - **Rejected: two counts and a gate on both sweepers.** It buys nothing now that retro is
    terminal, and it costs `config.yml`'s shape plus `--drive`'s exit codes, which 0038 and 0131
    build against.
  - **Rejected: a marker-aware count that skips marked entries.** It goes quiet exactly when
    deferred and handed-over entries accumulate — the gate's whole job is to be loud then.
  - **Trade-off accepted:** a buffer far past the threshold re-trips the gate after every sliced
    retro pass, so a driver may dispatch several. That is churn, and it is loud churn; each pass
    makes real progress because everything it reads leaves. Silence was the alternative.
  - **The marker's shape, decided on the 2026-09-05 evidence above:** a head token,
    `- 2026-09-05 [->0060] — **what happened.**`, so a large buffer partitions with one `grep` on
    `\[->`. Verified against the counter: the token sits after the date, so both `dated()` and
    `bolded()` in `count_findings` still match and nothing is reported malformed. Trailing prose was
    tried in practice and bought the next sweeper nothing.
  - **The write-time question, answered explicitly.** A noticer may **not** write the head token.
    The token means *a sweeper dispositioned this*, and the header's rule that nothing is classified
    at the moment of noticing stands. The cheap hint the note above asks about — the row the parking
    session was holding — is admissible and already has a home: the `(pointer: …, item NNNN)` clause
    at the end of the entry, which is not a classification and needs no new rule.
  - **The scope half.** The gate counts what the retro it dispatches will read — the local buffer
    plus the tools repo's buffer where `tools.path` resolves (FR10). Sibling backlogs under a shared
    workspace are not counted, because 0111 FR5 settled that a retro cannot reach them; a gate over
    an unreachable buffer would be this ticket's opening defect rebuilt. The 6/6/6/6 workspace case
    is real and stays uncaught by any single project's gate — each project gates its own, and
    nothing in this design pretends otherwise. Two consuming projects both counting the tools
    buffer may each dispatch a retro for it; the second finds it swept, and `retro` Step 2 already
    holds that finding nothing is a complete result.
  - **The `retro`-side scope gap is taken here rather than given its own row** (FR2), on the note
    above reserving it, and the 2026-09-09 note names the fix: the slice is chosen after the
    cross-entry read, or equivalently, reading is cheap and only writing is sliced.
  - **Depends on nothing outstanding.** 0111 is closed; `--drive` is untouched.
- **2026-09-10 — `size` raised `m` → `l`, and `expects:` widened.** The answer reaches two skills,
  the buffer header in both its copies, `references/REPORTING.md`, `templates/item.md`, the `next`
  reader in both copies and the tests — FR7 to FR10 did not exist when this was sized `m`.
- **2026-09-10 — 0080 is the same decision and is settled by this one.** *Let a findings entry's
  lesson half be removed independently of its work half* asks the marker-or-two-halves question and
  whether `./next --findings` counts a marked entry; FR1 and FR7 answer both. `relates:` now carries
  it, and a dated line was appended to its own *Notes & decisions*. **A `queue` pass should withdraw
  or re-scope 0080** — it is not this stage's call, and leaving it at `next: design` invites a
  second design session to re-litigate what is decided here.

- **2026-09-10 (develop, token 3929) — BUILT.** All ten FRs landed; the whole suite is green (29
  files) and `skills/queue/templates/next` and `.claude/backlog/next` are byte-identical (AC12).
  Four commits: the counter and its tests, the prose across both sweepers and both header copies,
  the `touches:` widenings, and one refinement to the gate's wording.

- **A guarded phrase that straddles a line wrap is unmatchable, and on a NEGATIVE assertion that
  reads as a pass.** AC6's absence check — *the sentence directing a pass to read fewer entries is
  gone* — was written as `read fewer entries and finish each` and went green **while the rule was
  still fully present**, because the file wrapped it as `…and finish` / `each**, rather than…`. A
  positive assertion in that state fails loudly and gets fixed in seconds; a negative one returns
  exactly what you were hoping for. It was caught only by running the guard before writing the
  prose, which is the one ordering that makes an unfalsifiable absence check visible. Re-anchored to
  `read fewer entries and finish`, which sits within the line, and the same trap then bit twice more
  on prose *this* session wrote — `reading is cheap and only writing is\nsliced` and `counts every
  entry, marked or\nnot` — both fixed by moving the wrap, never the phrase. `CLAUDE.md` says
  rewrapping a guarded paragraph is a breaking change; the half it does not say is that **writing** a
  new assertion has the same hazard, and that only the negative ones are silent about it.

- **AC1 and AC7 were green on arrival, and that was the design's prediction rather than a gap.** The
  head token sits *after* the date, so `dated()` and `bolded()` in `count_findings` match it
  unchanged — the token was shaped that way precisely so no reader had to change. Both are therefore
  **regression pins, not discriminating checks**, and both were mutation-proved rather than trusted:
  narrowing `dated()` to require an em-dash straight after the date reds AC7's first two assertions,
  and changing the `under the threshold` wording reds AC1's third. AC1 remains the weaker of the two
  — a counter that double-counted every entry would still report `0` on an empty buffer, so what AC1
  actually pins is the wiring and the wording, not the arithmetic. AC7 is where the shape is held.

- **AC11's second assertion deliberately duplicates one in `tests/retro-tool-edit.test.sh`.** Both
  match `no entry survives the pass that read it` in `retro` Step 4. They are not one guard written
  twice: that one holds the claim *Step 4 names four terminal dispositions*, this one holds *the
  gate is satisfiable by the stage it dispatches*, which is the premise `count_findings` now rests
  on. Delete either and one of the two claims goes unheld. Both files say so at the assertion, so a
  later tidy-up argues with a judgement rather than re-deriving it. (0146 — *when a required
  duplication earns a drift guard* — is the open row on exactly this question; this is an instance
  for it, not a decision on it.)

- **`references/REPORTING.md` had four bytes of headroom, and FR9 required adding a rule to it.**
  6053 bytes against `tests/reference-size.test.sh`'s 6057 goal. Checking the budget *before*
  writing turned an end-of-session red into a decision: the section was tightened from 828 bytes to
  ~590, and relocation was rejected on both of the payback test's conditions — every stage's closing
  step cites this file on every run (p ≈ 0) and the rule is mandatory the moment a stage reports.
  The reason is recorded in the guard, which is why `tests/reference-size.test.sh` joined `touches:`
  mid-session. **`develop` Step 3 sends you to grep the project's guards for the mechanism you are
  introducing; it does not send you to check the budget of a file you are about to grow**, and that
  is the cheaper of the two checks.

- **Two judgement calls in the code, both worth arguing with rather than re-deriving.**
  A `tools.path` resolving to the project's own buffer is detected and refused, so a tool repo that
  fills the key in anyway does not double every entry and fire the gate at half the threshold. That
  is a guard against a misconfiguration nobody has made yet, which is a YAGNI tension — kept because
  the failure it prevents is a *silently wrong count*, the exact class this ticket exists to close,
  and it is four lines. And `tally_findings` both sets globals and prints `MALFORMED` lines, which
  the conventions' *return a value or cause a side effect* rule would normally refuse; it matches
  `count_findings` directly above it, and in a POSIX `sh` file with no locals the alternative is a
  second parse of the same report. Consistency with the surrounding file won.

- **The `retro`-side scope half was taken here, as the ticket's own note reserved it** — FR2 covers
  both sweepers, and no new row was split off. Step 1 now slices the writing rather than the
  reading; Step 2 gained the smaller form it lacked, which is that past the threshold the gate is
  asking about the **write** list, since Step 1 has already read everything.

- **Still outstanding, and not this stage's call: `0080` should be withdrawn or re-scoped by a
  `queue` pass.** The design note records that FR1 and FR7 settle it; it is still sitting at
  `next: design`, where a second design session would re-litigate what this ticket decided.

## QA evidence

**Verified 2026-09-10 (verify, token 328c) at `qa_level: unit`** — the frontmatter level and the QA
plan's `**Level:** unit` agree, so no drift to report. The whole suite ran file-by-file (29 files,
every one `0 failed`; the two the verdict rests on are `tests/findings-buffer.test.sh` **46 passed,
0 failed** and `tests/next.test.sh` **364 passed, 0 failed**, both pasted from their own tallies).
`git status --porcelain` was **empty** before the first command and empty again after the last, so
no whole-project gate needed a worktree and the advisory intersection is empty.

**Which copy was read.** The repo checkout is the authority, as `CLAUDE.md` requires for a skill
change: this session's own `verify` skill resolved from the 0.9.23 install, which predates these
commits, and `diff -rq skills/ ~/.claude/plugins/cache/.../0.9.23/skills/` shows nine files
differing — expected, since the release has not been run since. No AC here is about the install.

| # | How it was checked | Result |
|---|---|---|
| AC1 | Ran `./next --findings` over a fixture buffer with every entry dispositioned (body empty): `FINDINGS  0 entries; threshold 8 … — under the threshold`. Mutation: `under the threshold` → `below` in the template reds `— and says it is under` | PASS |
| AC2 | `queue` Step 5 carries *cluster them after reading*, *not one-to-one*, *name what you left behind*. Mutation: dropping *after reading* and *name what you left behind* reds two AC2 cases | PASS |
| AC3 | Both header copies carry *by item id or file path* / *never by quoting it* / *resolves to nothing*. Mutation on the template's phrase reds AC3 | PASS |
| AC4 | Both header copies carry **The date is UTC** beside `claimed_at`, and `templates/item.md` states it above `created:`. Two mutations (local header, item template) each red their own case | PASS |
| AC5 | Step 5: *removal list comes from the ticket's FRs … never the cluster*. Mutation to *drawn from the cluster* reds AC5 | PASS |
| AC6 | `retro` Step 1 carries *reading is cheap and only writing is sliced* and *after the cross-entry read*; the old rule is gone. **Both directions proved:** removing the replacement reds the positive case, and re-inserting `read fewer entries and finish each` into the window reds the absence case — so the negative assertion the build note flagged as silently green is now falsifiable | PASS |
| AC7 | Ran `./next --findings` over a fixture holding `- 2026-09-05 [->0060] — **…**`, `- **2026-09-05 [->none] — …**` and an untokened entry: `3 entries`, no `MALFORMED`. Mutation: narrowing `dated()` to require an em-dash after the date drops the count to `2` and prints `MALFORMED …:6`, and reds three `next.test.sh` cases | PASS |
| AC8 | Step 5 names **Absorbed**, *not a new row*, *name the row*, *one dated line to its Notes & decisions*, `[->NNNN]`. Mutation removing the word `Absorbed` reds AC8 | PASS |
| AC9 | `references/REPORTING.md` *The findings buffer*: the count against the threshold, the `./next --findings` line, *a retro is due*. Mutation on *a retro is due* reds AC9 | PASS |
| AC10 | Fixture project with `tools.path: ../tools` (2 entries) over a 3-entry local buffer: `5 entries` with `local 3 (…) + tools 2 (…)`. With `tools.path: ../nowhere`: `3 entries`, `local buffer only — tools.path ../nowhere did not resolve to a backlog buffer`. With no `tools:` block: `local buffer only — config.yml names no tools.path`. Mutation `FCOUNT=$FLOCAL` reds four `next.test.sh` cases | PASS |
| AC11 | The comment above `count_findings` names the TERMINAL SWEEPER premise and cites `no entry survives the pass that read it`; `findings-buffer.test.sh` asserts that sentence in `retro` Step 4. Two mutations — removing the comment phrase, and altering the sentence in `skills/retro/SKILL.md` — each red their own case | PASS |
| AC12 | `diff -q skills/queue/templates/next .claude/backlog/next` → identical. Mutation of the installed copy alone leaves `next.test.sh` green (it reads the template) and reds `backlog-scripts-installed.test.sh` with *next has diverged from skills/queue/templates/next* — so AC12's guard is the one holding this, exactly as the QA plan said | PASS |
| NFR Migration | `count_findings` matches both old shapes; the live 24-entry buffer, all old-form, counts with no `MALFORMED`. Both headers say the old form *stays readable* and that nothing rewrites an entry it is not processing | PASS |
| NFR Progressive delivery | `--drive`'s contract is untouched: `FINDINGS_GATE=5` unchanged, and `./next --drive` here exits **5** with `DISPATCH  retro — FINDINGS.md holds 24 entries against a threshold of 8` — the provenance clause is suppressed where only the local buffer was counted, so the pre-0060 line shape is byte-preserved for a single-buffer project | PASS |
| NFR Documentation | Both buffer headers changed in `ae6cf8f`, the same commit as `queue` Step 5, `retro` Step 1, `templates/item.md` and `references/REPORTING.md` | PASS |

**Newly reachable, checked beyond the ACs.** The only new reach is a read of a file outside the
repo. It is *resolved* from `config.yml`, never discovered; a `tools.path` pointing at the project
itself is detected and refused rather than double-counted; and a `MALFORMED` line from the second
buffer names its own path, so a foreign entry is never hunted for in the wrong repo. Nothing is
written to the second repo and nothing from it is written locally — the only egress is one count and
one path into this session's own report, which `retro` Step 1 already reads wholesale by rule.

**Advisory:** not advisory. The dirty set was empty at Step 2 and at the verdict, so the
intersection with the evidence set is empty.
