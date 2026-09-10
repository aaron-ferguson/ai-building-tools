---
id: "0060"
title: Decide how the findings buffer is emptied and gated
type: chore
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0012", "0014", "0016", "0036", "0038", "0111"]
expects:
  - .claude/backlog/config.yml
  - skills/queue/templates/next
  - .claude/backlog/next
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
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

## Open design question

- **Question:** What does the findings gate count, and how does an entry record that one sweeper is
  finished with it? The two halves are coupled: if an entry can record "lesson landed, work
  remains", the gate can count what is actually actionable and the marker answers both. The shapes:
  **a per-entry marker** written by whichever sweeper finishes its half; **two counts** derived
  some other way, with the gate on both sweepers; or **no marker**, with the gate re-based on
  something a retro can move and `queue` given its own gate.
- **Why it blocks specification:** the acceptance criteria differ entirely. A marker is a change to
  the entry format, to both sweepers, and to `count_findings` in `./next`. Two gates is a change to
  `config.yml`'s shape and to `--drive`'s exit codes, which are a stated contract 0038 has just
  built against. And a marker interacts with the header's own rule that nothing is tagged at write
  time, because classifying at the moment of noticing is the friction the design deliberately
  avoids — so a marker must be written on the way *out*, not on the way in, and saying that is part
  of the decision.
- **A second axis the gate has, added by the `queue` sweep of 2026-09-07.** `findings_threshold` is
  **per-project**, and a workspace holds several. Measured that day from
  `/Users/<name>/Documents/AI`: four backlogs beneath it holding 22, 3, 4 and 0 entries —
  and had they been distributed 6/6/6/6, **no gate anywhere would have tripped while 24 findings sat
  unswept**. So "what does the gate count" has a scope half as well as a kind half: entries a retro
  can act on, *in which buffers*. It is recorded here rather than given its own row because it is
  the same decision — a gate re-based on something a retro can move has to say what a retro reaches,
  and answering the kind half without the scope half leaves the gate correct per project and blind
  per workspace. **Which buffers a retro reaches at all is 0111**, and this depends on that answer
  without being blocked by it: whatever 0111 settles, this decides what the gate counts across them.
- **Settle it with:** `/design` — the inputs are the file's header, both sweepers' steps, and
  `./next`'s counting code. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — The findings gate's count and the work a retro can do are the same quantity, so a retro that
  processes everything it can leaves the gate satisfied.
- FR2 — `queue` Step 5 states what a sweep does when the buffer holds more work than one session can
  specify: how to cluster, that entries and tickets are not one-to-one, and what is left behind and
  how it is reported.
- FR3 — The entry format states that a cross-referencing entry names the ticket or file it refers
  to rather than quoting a sibling.
- FR4 — Dates written into the backlog and this buffer state their timezone, matching
  `claimed_at:`'s existing ISO-8601 UTC.
- FR6 — `queue` Step 5 states that when a ticket is bundled from several entries, the removal list
  is derived from **the ticket's FRs**, not from the cluster that produced it. Sweeping this buffer's
  second batch, three of forty-six entries read as covered because a neighbouring concern in the same
  bundle was, and were caught only by a check nothing asked for; had it been skipped they would have
  left the buffer with no ticket, no trace, and a sweep reporting success.
- FR5 — Whatever mechanism FR1 lands, the code that implements it is named: `count_findings` in
  `skills/queue/templates/next` and its installed copy, not only the prose.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | An entry-format change meets ~60 existing entries; readers must accept the old form before anything requires the new one, and no sweeper rewrites entries it is not processing | `migration-conventions.md` |
| Progressive delivery | `--drive`'s exit codes are a stated contract 0038 built against; changing them reaches installed copies only through the version bump | `progressive-delivery-conventions.md` |
| Documentation | The buffer's header is the specification readers actually follow, so it changes in the same commit as the sweepers | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given a buffer whose every retro-actionable entry has been processed, when
  `./next --findings` runs, then it does not report the gate as reached.
- [ ] AC2 — Given `skills/queue/SKILL.md` Step 5, when read, then it states what a sweep does when
  it cannot finish.
- [ ] AC3 — Given the buffer's header, when read, then it states how a cross-referencing entry
  names its subject.
- [ ] AC5 — Given `skills/queue/SKILL.md` Step 5, when read, then it states that a bundled ticket's
  removal list comes from its FRs.
- [ ] AC4 — Given the buffer's header and `templates/item.md`, when read, then the timezone of a
  written date is stated.

## QA plan

- **Level:** unit — provisional, argued across the candidate shapes: any answer touching
  `count_findings` or `--drive` is `unit`, a prose-only answer is `verify` with a named scripted
  assertion, and this project's `unit` command runs every `tests/*.test.sh`, so `unit` subsumes both.
- **Why this level:** the level is the same across every candidate.
- **Specific checks:** settled by the design pass. `tests/next.test.sh` covers `--findings` and
  `--drive` and runs in every case; note 0038 and 0053 also reach that file.

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
