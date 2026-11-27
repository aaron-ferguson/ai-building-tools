---
id: "NNNN"
title: <verb + noun phrase, what the change does>
type: bug | feature | chore | debt
# Which skill acts next. `queue` = not specified enough for any stage to take it — captured
# half-baked, or found stale by a later stage · `design` = a decision has to be settled before
# acceptance criteria can exist · `develop` = specified, build it · `verify` = built, QA it.
next: queue | design | develop | verify
# Whether anything can act at all. `ready` = it can · `waiting` = a PERSON is needed · `blocked`
# = an open `blocked_by` · `in-progress` = a session holds a claim · `done` = terminal, the
# ticket's row has moved to `DONE.md`. `blocked` is DERIVED and never authored: it holds when
# `blocked_by` names a ticket that is not `done`, so it is written by whatever closes that
# ticket, never typed as a judgement. `./next --drift` reports where it has gone stale.
# `withdrawn` = terminal the other way: the work is not being done. The file STAYS as the
# record — the id is burned, never reissued, and this file is what a citation to it resolves to.
# `waiting` and `blocked` are not one value because
# different things clear them: a person answering, versus another ticket closing. Merged,
# telling which would mean opening the ticket. Two values sit off the stack rank and so out of
# this list: a project is `active` (see `parent:` below — its `next:` stays empty), and a dormant
# ticket in `SCHEDULED.md` is `scheduled` with a `wake:` date.
status: ready | waiting | blocked | in-progress | done | withdrawn
# What is checked, and by which runner. `unit`/`integration`/`e2e` are `testing-conventions.md`'s
# pyramid and are CUMULATIVE. The two below it are not on the pyramid and imply nothing else:
# `verify` = no runner applies, but a MECHANICAL check does — a grep, a path check, a schema
# validation the ticket names explicitly. `review` = no runner and no mechanical check either,
# because the artifact is prose and the checks are judgement; its content is a checklist
# configured per repo (`review: checklist:` in `config.yml`), and a ticket declaring it where
# nothing is configured is REFUSED rather than quietly dropped to a lower level.
# `verify` and `review` are both live and neither replaces the other.
qa_level: verify | review | unit | integration | e2e
# WHO CLOSES, which is a different question from what is checked — two orthogonal fields, never
# one enum, because an enum holding both drifts. `verify` (the DEFAULT, and what an absent field
# means) = an independent pass reads the criteria and closes. `develop` = the light tier: the
# session that BUILT it closes it, paying no second session's startup floor.
#
# `develop` IS PERMITTED ONLY where every acceptance criterion is discharged by a committed
# automated assertion, NAMED ON THE AC LINE, which the build session proved red before green. No
# criterion whose verdict is a reading, a judgement or an eyeball — the tier is safe only where
# there is no belief to be wrong about, and the two recorded times the independent gate bit in
# this repo, it bit on AC quality rather than on code. `.tickets/close` enforces this
# mechanically and refuses the close otherwise.
#
# `queue` SETS this field. `develop` may RAISE it from `develop` to `verify` when it finds a
# criterion that is not a real assertion, and may never set or lower it to `develop`.
# `qa_level: review` can never carry `close_by: develop` — a review's checks are judgement.
close_by: verify | develop
# OPTIONAL, and only where some ACs can be observed by NO runner — a physical device, a person's
# eye. Free text naming which ACs, on what surface, and who: `AC1-AC3 — iPhone Safari, the author`.
# It does not replace `qa_level`, which keeps naming the runner that discharges the scripted half;
# a split ticket carries both. Absent means every AC is scripted.
qa_manual:
# Rough cost, so a session can see what it's taking on WITHOUT reordering the queue.
# s = one sitting · m = a focused session · l = multiple sessions or needs a design decision first.
size: s | m | l
# The date is UTC, like `claimed_at:` below and every entry in FINDINGS.md. Two sessions an hour
# apart either side of midnight otherwise write different dates and both are defensible.
created: YYYY-MM-DD
source: user | agent | external:<report-id>
# The graph. `parent:` points UP at the ticket this one belongs to — 0 or 1 id, never a list, and
# the only stored edge in the hierarchy. Children are DERIVED, never stored: one `grep` over
# `items/` finds them, and a stored reverse edge is a second place to update and the one that
# goes stale. A ticket with children is a PROJECT — it holds the outcome, the scope and the
# measure, and it is never ranked, claimed, or built, because its children carry the stages and
# its row leaves `QUEUE.md`. A ticket with no children is a TASK, and tasks are where all the
# work lives; a task becomes a project the moment it gains a child.
parent:
# The tickets that must close FIRST — a list of ids. These are this ticket's dependencies, and
# never its dependents. This is what DERIVES `status: blocked` above, so an entry naming a ticket
# already `done` blocks nothing, and whatever closes a ticket reconciles every ticket naming it.
# ONE form: the inline flow list below, `[]` when empty and `["0002", "0007"]` when not. Both
# readers accept a `- ` block too, and neither did until 0044 — closing a ticket whose dependent
# used the block form reconciled nothing and reported nothing. Two shapes for one field is what
# made that possible, so write this one.
blocked_by: []
# Undirected, and carries NO scheduling meaning: neither ticket waits on the other and nothing
# derives from it. Use it for "read these together"; "do that one first" is `blocked_by:`.
relates: []
# The files this item is PREDICTED to reach, written by `queue` while the code is already open
# to write the FRs below — so a session choosing what to take next can spot a collision with an
# in-progress item's `touches:` without researching every candidate itself. Advisory: it
# protects nothing, it goes stale, and being wrong here costs one suboptimal pick. `develop`
# checks it against the code on claim and promotes the corrected list to `touches:`.
# ONE form: a `- ` block, one path per line, so a path can carry its own comment (`# new`). Every
# reader also accepts the inline `["a", "b"]` list and a bare `a, b` scalar, and until 0242 one of
# them read each of those as EMPTY — a scope that compares nothing and lets two sessions land in one
# file. Three shapes for one field is what made that possible, so write this one.
# An entry naming a file this ticket will CREATE carries `# new` — a comment beginning with the word,
# so `# new — the script S8 adds` counts and `# renewed` does not. `./next --drift` and `--drive`
# report any other entry that exists nowhere in the repo, and `--drive` escalates on it.
expects:
# The digest of the criteria the AUTHOR agreed, one key per ACn: `ac_digest: AC1=<hex> AC2=<hex>`.
# Written from `./next --ac-digest <id>` by `queue` (Add, Re-specify, Amend) and by `design` when it
# writes criteria, in the same commit as them; `develop` and `verify` never write it. `--drift` and
# `close` recompute it from the file and refuse a mismatch. Absent or empty means unverifiable —
# neither drift nor a match. It detects an edit made in good faith; an edit that restamps defeats it.
ac_digest:
# Written by `develop` when it claims the item, cleared when it closes or releases it.
# This is where the token lives; the pared QUEUE.md carries no ownership column. An item is
# yours only if you minted its token in this conversation — see the ai-building-tools
# CONCURRENCY.md.
claimed_by:
claimed_at:
# The files this item is ACTUALLY claiming — a live claim, not just on the row. `develop` writes
# it on claim by verifying `expects:` against the code, clears it on close or release, and widens
# it the moment the work reaches further. Unlike `expects:`, being wrong here costs two sessions
# in one file, which has no merge protocol behind it. It warns, it does not lock.
# Empty reads two ways by reader: as *held* to a session deciding what to take, and to the
# release-time scope report an empty touches: means nothing declared, so every path the pass
# changed is named. `touches: "*"` is the exclusive claim and covers every path (0145).
# ONE form, the same as `expects:`: a `- ` block, one path per line; `./claim` writes it that way.
touches:
# ONLY on a sliced ticket — one carrying `## Progress` below. The last slice of the most recent
# leg: written by `./handoff --slice S<n>` and by nothing else, in the same commit as the hand-off.
# With the ticked state of that slice it tells a leg verify passed (ticked) from one it bounced
# (unticked), which `next --drive` routes differently. Empty until the first leg ends.
slice:
---

## Problem

Who is hurt, how, and how we know. For a bug: exact repro steps, observed vs expected,
and the evidence (log line, screenshot path, failing request). For a feature: the job the
user is trying to do that they currently can't.

## Functional requirements

Each one independently verifiable. If you can't say how you'd check it, it isn't a
requirement yet.

- FR1 —
- FR2 —

## Non-functional requirements

Keep only the rows that apply and delete the rest. An empty row is noise; a filled row is a
commitment `develop` and `verify` will hold you to.

The second column says what **this item** must satisfy. The third names the check, mutation or
observation that would fail if it did not: **Each row names how it would red**, and a row for which
none can be named **is not a commitment and does not ship**. **A filename alone is not an answer**:
the cell names the case, criterion or mutation within it, because a file that exists reads as a
check whether or not it can see this requirement. The fourth cites the convention file
that defines the rule — by bare filename, since the conventions directory is resolved per project.
**Cite, never restate:** a rule copied in here drifts from source, and `verify` will then verify the
stale copy. The convention files below are the usual mapping; check the conventions core's index
for the authoritative list.

Where the honest answer is that nothing exists yet to assert against — a log format no run emits, a
metric nothing records — write **`prose only — no artifact yet`**. That is a permitted answer and a
different state from an unanswered one: **An empty cell is an unanswered row**, and `verify` Step 4
reads the two differently.

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | | | `security-conventions.md` |
| Privacy & data | | | `data-privacy-conventions.md` |
| Performance | | | `observability-conventions.md` |
| Accessibility | | | `accessibility-conventions.md` |
| Observability | | | `observability-conventions.md` |
| Migration / schema | | | `migration-conventions.md` |
| Progressive delivery | | | `progressive-delivery-conventions.md` |
| Dependencies | | | `dependency-conventions.md` |
| Documentation | | | `documentation-conventions.md` |

The always-on rules in `CONVENTIONS_CORE.md` apply to every item and get no row here — they are
never optional, so a row would only invite treating them as a choice. `verify` reads them from source
on every run.

## Waiting on  *(only while `status: waiting`)*

A **decision brief**, written by whoever sets the status: a person reading it cold, away from the
session that wrote it, decides from it and nothing else. `./next --waiting` and every `--drive`
escalation print the first line under `### What needs you`, so the set of things needing a person
is scannable without opening a ticket. A `waiting` row with no section here is reported as a defect
in the row rather than skipped. **`./handoff <id> <token> <stage> waiting` refuses a section missing
any of the seven subsections below, or holding fewer than two `#### Option` entries under
`### Options`**, naming what is missing and changing nothing. Rows already `waiting` are not
re-checked.

### Outcome
What the work is driving toward.

### Where it stands
What is done, what is blocked, and what keeps running meanwhile.

### What needs you
The challenge, in one first line, and why it cannot be decided without a person.

### Options
#### Option A — <name>
Pros, cons, and what would have to be true for it to win.
#### Option B — <name>
Pros, cons, and what would have to be true for it to win.

### Recommendation
Which option, and why.

### What to do
The exact steps or reply that unblocks it, and the command that resumes.

### If no answer
What waits, and what does not.

Delete this section when the status changes.

## Open design question  *(only while `next: design`)*

What has to be settled before this item can have acceptance criteria. Write it as a question with
a decidable answer, not a topic — "modal or full page for the bulk edit?" not "bulk edit UX".
State it before the design work starts; that is the same discipline as writing kill criteria
before running a test.

- **Question:**
- **Why it blocks specification:** which AC cannot be written until this is answered
- **Settle it with:** `/ai-building-tools:design` (returns a decision) or `/ai-building-tools:prototype <level>` (returns something
  to look at, when the answer needs to be seen rather than reasoned about)

Delete this section when the item moves to `next: develop`, and record the answer in
**Notes & decisions**.

## Kill criteria  *(only on a gate ticket)*

A gate ticket is a measurement whose verdict decides whether further work exists
(`docs/decisions/004-a-gate-ticket-and-the-work-it-decides.md`). Write each threshold and the
measurement that produces it **before the measurement runs**.

- **Criterion:** <threshold> — measured by <how>

**Verdict:** <empty until the measurement runs; then `cleared` or `killed`, the figure against every
criterion, and the date>

**If it clears:** <the follow-on work as prose outline — never FRs or checkbox criteria, so nothing
here can be ticked or built>

Delete this section on any other ticket.

## Acceptance criteria

Given / when / then. `verify` checks these literally and will not close the item without them.

**Each criterion names what would make it red** — the input, change or mutation that turns it from
green to red. One for which none can be named **is not a criterion yet**; `queue`'s Step 2 names the
three shapes that read as criteria and are not.

**ONE form: every criterion is a `- [ ] ACn — ` checkbox**, and `./close` ticks exactly that.
Written any other way — `- **AC1** —` is the one that happened — it ticks none of them, and until
0044 it closed the ticket anyway, leaving no record that anything was checked.
**To strike a criterion, take it out of the list:** a non-list line `~~ACn — …~~ (moved to NNNN)`.
A struck bullet, `- ~~ACn …~~`, is the plain-bullet shape `./close` misreads, and it reds
`tests/item-ac-form.test.sh` (`580b434`).

- [ ] AC1 —
- [ ] AC2 —

## Progress  *(only on a ticket worked across several sessions)*

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").
A ticket that fits one session has no `## Progress` and behaves exactly as one always has — delete
this section.

One line per slice, in order, each ending in exactly one of three forms:

    - [ ] S1 — <what lands> — discharges none
    - [ ] S2 — <what lands> — discharges AC1, AC2
    - [ ] S3 — <what lands> — unspecified

- **Every AC is named by exactly one slice**, the one where it first becomes true.
- **`unspecified`** is a slice in scope but not yet sharp enough to give ACs. When it is next, the
  ticket goes to `design`, which gives it ACs and re-stamps `ac_digest`; `./handoff --slice` refuses
  a leg holding one. Work ruled out stays in *Out of scope*, so unsharp and ruled-out stay distinct.
- **A leg is one or more consecutive slices**, ended by `./handoff <id> <token> <stage> --slice S<n>`,
  which also writes `slice:` above. A leg discharging no AC goes develop → develop and is ticked
  then; one discharging an AC goes to `verify`, and is ticked only when verify passes it
  (`./handoff … develop --slice S<n>`). `./close` ticks the closing leg and refuses while an earlier
  slice is unticked.
- **Ticked slices are history.** `develop` may re-split or re-order unticked slices, with a dated
  line in *Notes & decisions*, and never changes an AC in doing so.

## QA plan

**The level is `qa_level:` in the frontmatter, chosen at queue time, and is not restated here.**
Two copies can disagree — both written by the same pass, differing by a multi-minute suite — and
`verify` then has to pick between two answers the ticket gave with equal confidence. This section
says *what* to exercise; the frontmatter says at which level.

- **Why that level:** <one line; e2e needs a reason that unit + integration can't cover it>
- **Specific checks:** <suites to run, journeys to drive, manual steps if any>

At `qa_level: review` the checks come from the checklist `config.yml` names, and `verify` records
one ticked box per checklist line in a `## Review checklist` section it adds below. `close` refuses
a checklist of bullets with no box ticked, so an unperformed review cannot be closed as a clean one.

## Out of scope

What this item deliberately does not do, so `develop` doesn't scope-creep.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

Each AC and NFR row, how it was checked, and the actual output — the table `verify` produces at its
verdict, kept where a reader finds it after the session that produced it has ended. Empty until a QA
pass has run; a closed ticket with an empty one is a ticket whose ticks assert a check nobody can see.

## Notes & decisions

Appended as work happens — non-obvious mechanisms, disproved theories, why an approach was
rejected. Per `documentation-conventions.md`, this gets written when understood, not at the end.
