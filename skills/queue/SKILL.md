---
name: queue
description: >
  Turn project feedback, bugs, and work items into a stack-ranked local backlog that any agent
  can pick up later and build without asking a clarifying question. Use whenever the user
  reports a bug, requests a feature, or says "queue this", "add this to the backlog", "log this
  bug", "we should fix X sometime", "park this for later", or invokes /queue. Also use to
  reorder, inspect, block, or import the backlog — "what's next to build", "show the queue",
  "move X to the top", "reprioritise", "sweep the findings". Use proactively when the
  user describes engineering work that is clearly not for right now. The executor is the agent,
  and the artifact is code. NOT for the user's own tasks, meetings, or notes — that is /capture,
  which keeps a personal knowledge base and where the executor is the user. When the input is a
  commitment to a person, a meeting outcome, or a dated follow-up, it belongs there instead. The
  backlog lives in .claude/backlog/ inside the project.
---

# /queue

Turn something the user just said into a fully specified, stack-ranked ticket a cold agent can pick up
weeks later and implement without asking a single clarifying question.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff — the
ticket's `next` field and `FINDINGS.md`, never a conversation. Measured **2026-08-22**: **85% of $15.11
went on context handling** at **191,752 tokens per turn**, modelling to **~$5.09** isolated. **No standard
is relaxed** — the rigour is all in the 15% that was output. Batch every related ticket into
one capture session: isolation is per skill, not per ticket, because reading the source material is a
shared cost paid once.

**The backlog is worked by more than one session at a time.** Read `references/CONCURRENCY.md` at the
plugin root before writing anything.

**This skill states no standards of its own.** Every rule about security, privacy, accessibility,
testing or documentation is cited from the project's conventions, never restated here or in a ticket.
Resolve them per `references/CONVENTIONS.md`; if none resolve, stop as that file directs.

---

## Storage layout

```
.claude/backlog/
  config.yml     project settings, next_id, conventions path, test commands, optional tracker/cost blocks
  QUEUE.md       the stack rank — line order IS the rank. Header and table only.
  RANKING.md     why the order is what it is NOW. Standing reasoning, read only for re-ranks.
  RANKING-HISTORY.md  optional; the dated narrative, once it outgrows RANKING.md's current-state head
  FINDINGS.md    what sessions parked and could not place. A buffer, not a second queue.
  next           reader: `next <stage>` the takeable row · `next --waiting` who is waited on
  claim          claims a row: lock, edit, write frontmatter, commit, unlock — one atomic step
  close          closes a row: lock, tick ACs, move to DONE.md, reconcile dependents, commit, unlock
  DONE.md        completed tickets, newest first
  .lock/         transient; held for seconds during a claim or a close. Never committed.
  items/0007-rate-limit-feedback-endpoint.md
```

Templates are in this skill's `templates/`.

**`QUEUE.md` holds the header and the table, and nothing else** — standing reasoning lives in
`RANKING.md`. The queue is rewritten on every claim and close, by every window, so prose parked there is
re-read on each of those edits while changing perhaps once a week. `./next` goes further, answering
"what do I do next" in a handful of lines whether the queue holds ten rows or three hundred.

**Its header is a legend, not an essay** — the same argument, applied to itself. It names what the
columns mean and points at the reasoning; the reasoning is here, read when someone is about to change
the schema rather than on every claim.

### Why the columns are what they are

Each of these is a plausible-looking change away, and the header no longer carries the argument:

- **No priority column.** A priority and a position can disagree, and then nothing is unambiguous.
- **No position number.** Line order already carries the rank, and a `#` column has to be renumbered on
  every insert and close — turning each one-row change into a full-file rewrite, which is exactly how
  two windows silently overwrite each other (`CONCURRENCY.md`, *Never rewrite `QUEUE.md` by hand*).
- **Stage and state are two columns.** Merged into one, a reader cannot filter for "work I can start"
  without already knowing which values are stages and which are states.
- **`waiting` is not `blocked`, and the difference is who clears it** — a person, versus the ticket named
  in `blocked_by` closing. One value for both means opening the ticket to find out which kind of stuck it
  is, and there is nothing a session could do about either without knowing.
- **`blocked` is derived, never a judgement.** Two consequences, neither optional: **closing a ticket
  reconciles every row naming it in `blocked_by`, in the same commit as the close**, since a blocker that
  clears without touching its dependents is how the cache goes stale; and `./next` offers a row on the
  graph's answer whatever the column says. A stale `blocked` hides takeable work and no reader notices —
  it once left four rows unavailable for a whole session.
- **Something blocked by a non-ticket is not `blocked`.** If a person clears it the row is `waiting` with
  the question in its `## Waiting on` section; if an external event does, capture that event as a ticket
  and name it in `blocked_by`. There is no third case — a `blocked` the column cannot derive is a
  `blocked` nothing can ever clear.
- **A `design` row keeps its rank.** The work is worth what it was worth; sinking it means rediscovering
  why it mattered later.
- **No `Type`, `Size`, `QA` or `Item` column.** None changes a reader's behaviour at read time, and the
  ticket is a file they open anyway. **The `ID` resolves to `items/<id>-*.md` by glob**, so the path is
  not worth a column — it was the bulk of every row.

**Use `./claim` and `./close` rather than hand-editing either**; the commit inside the lock is the
point in both cases, and `CONCURRENCY.md`'s *A claim must be durable the moment it is made* and
*The four scripts* are why.

---

## Step 0 — Locate or create the backlog

Find `.claude/backlog/` at the project root. If it doesn't exist, scaffold it by copying every template
above (`chmod +x` `next`, `claim` and `close`), creating `items/`, and filling `config.yml` from what the repo
actually uses — read `package.json` scripts (or `Makefile`, `pyproject.toml`) for the real
test/lint/typecheck commands rather than guessing. Leave `tracker:`, `cost_tracking:` and
`external_feedback:` out unless the project's `CLAUDE.md` profile wires one in or the user asks
(`references/TRACKER.md`, `references/EXTERNAL-FEEDBACK.md`). Never invent a project key: a ticket
mirrored into the wrong project is noise on someone else's board.

**A backlog that already exists can still be missing the scripts — or be running stale copies of
them.** Check every executable in this skill's `templates/`, plus `item.md`, each time you open a
backlog rather than only when you create one: every backlog predating a script has none, and the
project that develops them is the last to receive them — six sessions hit that before it became a
ticket. **Compare the bytes, not a version string.** Drift is silent and fast: one project was
measured 582 lines behind, re-synced, and behind again the same day when an upstream release added a
script it did not have. A version line would be a second thing to keep true, and the release chain
already learned the harder half of this — a reported success can extract nothing, and only a
byte-level comparison catches it. Re-copy whatever is absent or differs, `chmod +x`, commit.

**Which files that covers, and which it must never touch.** The executables and `item.md` belong to
the plugin and are replaced whenever they differ. `config.yml`, `QUEUE.md`, `DONE.md`, `FINDINGS.md`
and `RANKING.md` belong to the project — seeded once at scaffold, never overwritten, because they
hold the project's own content. **The templates are the source and a fix flows one way** — a copy
that needs to differ is a defect in the template, fixed there and re-copied. Editing the copy leaves
the project running one set of rules and shipping another, and nothing reports it.

**Resolve the conventions now**, per `references/CONVENTIONS.md`, and record the path in `config.yml`
under `conventions.path` so the next session doesn't re-derive it. If nothing resolves, do not scaffold —
report the missing wiring and stop. A backlog whose tickets cite no standard cannot be verified later.

---

## Step 1 — Decide the operation

| User says | Do |
|---|---|
| describes a bug / feature / annoyance | **Add** (Step 2) |
| "what's next", "show the queue" | `./next <stage>`, print it, stop |
| "move X up", "do Y first", "reprioritise" | **Rerank** (Step 4) |
| "X is blocked on Y" | Record `blocked_by:` in the item file; set the column to `blocked` **because** that derives it, never as a judgement of your own |
| "X needs an answer from someone" | Set `status: waiting` **and write the `## Waiting on` section** — the question and who can answer it. A `waiting` row with no such section is a defect `./next --waiting` reports, being indistinguishable from a forgotten one |
| "sweep the findings", "import the reported feedback" | **Surface parked work** (Step 5) |
| a ticket sits at `next: queue` — bare `/queue`, or an ID | **Re-specify** it (Step 2), then **skip Step 3**: it already has a rank and keeps it |
| "add an FR to X", "this ticket also needs Y" | **Amend** an already-specified ticket (Step 2) |

Adding is the default when the intent is ambiguous — but only where there is something to capture. A
bare invocation with nothing new to record is the **re-specify** case, not an Add: `next: queue` is the
one stage this skill owns, and every other stage's skill opens by taking the row at its own stage. Those
rows exist by design — captured half-baked, or sent back by a later stage that found the contract stale
— so a session that cannot see them hands the work back to the user to find by hand.

**Re-specifying and amending both reuse Step 2 and both skip the ID claim.** Two things they also
change, and neither is optional:

- **Re-specify** (a ticket bounced back to `next: queue`): read the stage's recorded reason first — it
  says which part of the contract failed — and **skip Step 3 entirely**, because the rank is already
  set and the work is worth what it was worth. **Un-tick every AC the re-specification touches**: a
  tick is evidence about the contract as it then stood, and a ticket returning with ACs still green
  from a pass against the *old* contract is how `verify`, which closes on ticked ACs, closes over a
  real regression.
- **Amend** (a new FR on an unclaimed, fully-specified ticket): widening the scope invalidates whatever
  was sized *against* the old scope, so re-check **`size`, the ACs, the QA plan's named checks and
  *Out of scope*** against the new shape, and record the reason in *Notes & decisions*. That re-check
  is where the work actually is; the FR itself is the cheap part. Never amend a claimed ticket — its
  session is building against the contract you are changing.

Read-only operations don't need the conventions resolved; anything that writes a ticket does.

---

## Step 2 — Add an item

Read `templates/item.md`. That template is the contract — every section exists because something
downstream reads it.

**Claim an ID under the lock** — reading `next_id`, using it, and writing back the increment unlocked is
how two parallel runs both take 29. Release in the same turn; the item file, ranking and the row are all
unlocked.

**Mint from the disk, not from the counter: the id is `max(items on disk) + 1`, and `next_id` is then
corrected to match.** The counter is a cache and it drifts — a session found it reading `94` against an
`items/` already holding `0094`, `0095` and `0096`, and the collision it predicted happened in the very
next run: a new ticket was written as `0094-…`, alongside the closed `0094-…`, and **committed** before
anyone noticed. A lock does not fix this, because the counter was not racing anyone; it was simply
stale. Nor does the older instruction to "confirm no `items/<id>-*.md` exists" — that is a check on the
number rather than on the write, it reads as satisfied by a listing taken a moment ago for another
purpose, and it fails open: nothing about writing the file, committing it, or editing `QUEUE.md`
refuses when the id is taken. Deriving from the disk makes the failure unreachable instead. The cleanup
is the expensive part if you get it wrong — the queue and `DONE.md` disambiguate by title, but every
cross-reference in prose ("item 0094") is ambiguous across the repo's whole history until renumbered.

**Write the Problem section from evidence, not paraphrase.** A repro, error text, a screenshot path goes
in verbatim; details living only in this conversation are lost the moment it ends.

**Derive functional requirements.** What would a reviewer check to say "yes, this is done"? Each FR
independently verifiable; two vague FRs are worse than one sharp one. Where the ticket changes
something this repo also **ships** — a template, a script, a scaffold — write the FRs *and* the Out of
scope about the shipped artifact, never about this repo's copy of it. A scope line reasoned from the local
instance ("ours already has no such column") leaves the template losing whatever that copy lacked.

**An FR stating what a mechanism *is* needs a sibling FR naming the code that implements it.**
Otherwise the ticket verifies its own documentation: one ticket replacing an ownership protocol
specified the mechanism, the concurrency reference and the ignore file, but named neither of the two
scripts that actually implement ownership — so closing it as written would have left the prose
describing the new protocol and the code still running the old one, the exact defect it existed to
remove. Where an FR describes a rule, ask what executes it, and give that its own FR.

**Fill the NFR table by elimination, not by default.** Read the conventions core's index first — it names
which file governs each dimension and when it is triggered — then decide row by row whether it applies to
*this* change. Mandatory triggers, the ones most often missed: auth, credentials, data visibility or
untrusted input → **Security**; personal data, a new log field, a new egress destination, or data sent to
a model → **Privacy**; user-facing UI → **Accessibility**; schema change or backfill → **Migration**;
real users already on this path → **Progressive delivery**.

For each row you keep, write **what this ticket must satisfy** and cite the governing convention by bare
filename; read that file if you are not certain what it requires, because the row must be a commitment
rather than a guess. Delete rows that don't apply — a table of nine "N/A"s trains everyone to skip the
table. **Never restate a convention's rules inside a ticket**: the ticket says what *this change* must
do, the convention says what the rule *is*, and a copy drifts the first time either is edited, after
which `verify` checks the stale copy. The same holds for any **set** the ticket does not own: enumerate
it in an FR and the FR is false the day the set grows, having read green the whole way. The core's
always-on rules apply to every ticket and need no row.

**Set `qa_level` now, at queue time** — the decision that stops QA rigour quietly sliding session to
session. **It must be a level the project's `config.yml` can actually resolve to a command**, checked
against that file rather than recalled: a level with no command leaves the QA session nothing to run,
and it is discovered at the far end of the pipeline by the one stage that cannot fix it. **And write it
exactly once, in the frontmatter.** A QA plan that also states a `Level:` line can disagree with the
field — both written by the same pass, differing by a multi-minute suite — and `verify` then has to pick
between two answers the ticket gave with equal confidence. The plan describes *what* to exercise; the
frontmatter says at which level. The levels are `testing-conventions.md`'s pyramid; what this skill adds is where each one lands.
**`unit`** for pure logic, no wiring changed. **`integration`** where it crosses a seam. **`e2e`** for a
critical journey whose breakage is unacceptable, or a change only manifesting through the real build —
needs a one-line justification of why integration can't cover it, and there should be few. **`verify`**
where no test runner applies (docs, config, tooling), requiring a **scripted assertion** the ticket names
explicitly — a grep, a path check, a schema validation; if you cannot write one the ticket needs sharper
ACs, not this level. **A grep over prose must survive reflow** — match a phrase short enough to stay on
one line, or collapse newlines before matching; rewrapping a paragraph moves a phrase across a line break
and reds an assertion whose text still says the right thing. **The same break defeats an `Edit`**,
which matches literally: a replacement quoting a phrase the file happens to wrap between two words
matches nothing, and it reads as the text being absent rather than split across a newline. Quote within
one line, or anchor on a line you have just read.

**Write `qa_manual:` where some ACs can be observed by no runner** — a physical device, a person's eye
— naming which ACs, on what surface and who: `AC1-AC3 — iPhone Safari, the author`. It does not replace
`qa_level`, which keeps naming the runner for the scripted half; a split ticket carries both, and a
split is the common case. **Do not reach for a `device` level instead**: a level names a command, and
one resolving to none leaves the *scripted* ACs unrun — the same defect mirrored. Measured on a ticket
whose first three ACs needed an iPhone, authored `e2e` with *"then device"* in the QA plan's prose, so
QA was directed at a browser suite structurally unable to see the behaviour while the device half
survived only in a section the frontmatter contradicted.

**Estimate `size`** — `s` one sitting, `m` a focused session, `l` multiple sessions or needs a design
decision first. Input to tie-breaker 4 only, never moving a ticket between tiers.

**Record `expects:` — the files this ticket is likely to reach — while the code is still open**, since
it cannot be reconstructed later at the same price. Name the implementation files *and* the tests that
exercise the behaviour being changed: a change altering what a behaviour *means* reaches every spec that drives it,
and those are the ones a later reader misses. Its job is **triage, not protection** — it locks nothing, a
best guess beats an empty field, and `develop` verifies it against the code on claim.

**Write acceptance criteria as given/when/then**; `verify` checks these literally. **An AC must be
provable within the ticket's own scope** — one whose reproduction needs something the same ticket sends
to *Out of scope* cannot be met, and `verify` is right to fail it, leaving a finished ticket stuck between
a red it cannot fix and a scope it must not grow. Write that as the observation it is ("the run reports
X, whose fix is ticket NNNN"). **State any size or budget target absolutely** — bytes, a count, a
ceiling — never as a percentage of a baseline a sibling ticket in the same project is still moving: two
independently-written targets over a shifting baseline leave the second one unclosable.

**Name what would make each AC red** — the input, change or mutation that turns it from green to
red, and an AC for which none can be named **is not a criterion yet**. It cannot be *met*, only not
contradicted, and `verify` closing on it records a check nobody ran. The underlying rules are
`testing-conventions.md`'s; three shapes have each closed a ticket here while reading as criteria:

- **A tolerance wider than the effect it measures** — "within the stated tolerance" over a per-cycle
  growth orders below the per-turn floor is a green light dressed as a measurement.
- **A cardinality claim over a set the ticket does not own** — "names exactly one operation that
  takes the lock" goes quietly false the day a sibling adds a second, and reads as correct prose
  while it does. The enumerated-set rule above is the same failure in an FR.
- **A mutation applied on the far side of the boundary under test** rather than across it — a phrase
  added *after* the paragraph a window should stop at leaves every presence assertion satisfied by
  the real paragraph, so the suite is green under bug and fix alike. The discriminating mutation
  **moves** a phrase across the boundary.
- **Figures that cannot tell the old rule from the new one.** An AC asserting a display does *not*
  change is only a criterion if its own numbers disagree under the two rules: `12.02` rounding to `12`
  under both is green before the change and after it. Pick the values deliberately, and check the
  figure against **every formatter that renders it** — one AC pinned a source's yield as unchanged
  while the same number reached the screen through a second formatter as the pool readout, where it
  moved visibly, which made the criterion unsatisfiable rather than merely weak.
- **A criterion quantifying over a whole screen** — "the panel contains no `<value>`" — is unverifiable
  wherever that value arrives by more than one path, and it fails in the direction that looks fine: the
  clause only bites when someone reads the entire rendered panel, so it passes by default. Name the
  element instead ("the Yield row shows…").

**An AC set can span every FR and still miss the defect, because every AC measures the same instant.**
Where an FR describes a *state* — "the subject is visible", "where the player is looking is theirs" —
at least one AC must **act again afterwards and re-assert**. Persistence is a separate claim from
establishment. One ticket's five ACs all asserted against the moment a panel opened; each was
mutation-proved able to fail, all five genuinely held, and an 8px drag immediately afterwards put the
subject back under the panel — the item's own problem statement returning, with no criterion able to
see it.

**Check a QA plan's absence assertions against the guards already shipped**, or the plan demands the
removal of a phrase an existing test requires and the next session must choose between its own
ticket and another's guard. **Compute an absence assertion's expected wrong answer
from the fixture rather than estimating it**, or name no value at all: an estimated constant that
never appears reddens through some generic branch instead, so the message that would have named the
cause never fires.

If the report genuinely doesn't contain enough to write FRs or ACs, ask — once, batched, with your
proposed defaults.

### Set `next` now — this skill routes, and `design` does not screen

**Every ticket this skill writes leaves with `next: design` or `next: develop`, and the reason recorded
in *Notes & decisions*.** Never leave it blank for a later stage to work out: deciding whether
acceptance criteria can be written **is** the design question, and you answer it here with the code
already open. The recorded reason lets a later reader tell a considered skip from an oversight.

**Those two exits govern a ticket *entering* the pipeline. A ticket re-entering it has a third.** A row
sent back from `verify` because its *contract* was wrong arrives with its code already built and green,
and both permitted exits are then wrong: `design` has no open decision to settle, and `develop` would
claim the row, re-run a green suite and hand it straight back. **Where the re-specify changes only
criteria and leaves every FR's code standing, set `next: verify`** and say why in the note. Where any FR
gains code, it is a `develop` row like any other.

**And a re-specify that leaves code standing owes `develop` a one-line state-of-the-code header** — the
SHA and the verdict, opening the *Re-specified* note: *"The code at `3c3a93b` is right and stays."* This
is not decoration. `develop`'s re-entry guidance reads a `verify` verdict as "what turned out to be
wrong", and a session opening a ticket whose feature is already built must otherwise re-derive whether
the diff is another window's mid-work — which costs exactly the orientation the batch rule exists to
save. Measured on the return leg: that one sentence was what made the ticket cheap.

**Two triggers send a ticket to `design`:**

1. **A decision blocks writing acceptance criteria** — which pattern, which flow, one step or several.
2. **A person will look at the surface** — a screen, a layout, an interaction, an empty or error state.
   The ACs may be writable, but what they should *say* turns on a judgement about the look.

**Everything else routes to `develop`, and this is the case most often mis-sent.** No surface and no open
decision goes straight to `develop` however unfamiliar it is — unfamiliar is not undecided. Concretely:
**a parser** (the input format is the contract), **a migration** (the schema before and after is the
contract), **a schema change**, **an API contract**, a config reader, a build script, a CLI flag. Each
has a right answer discoverable by reading the code.

For a `design` ticket: write the *Open design question* section, set the stage, and **rank it normally** — the work is worth
what it was worth. A real stage, not a euphemism for vague: the test is whether a *decision* is missing, not whether detail is. Guessing acceptance criteria
to avoid the stage is how a ticket gets built to a contract nobody agreed to.

**Clearing a `design` ticket:** `design` writes the answer into *Notes & decisions*, adds the FRs and ACs
it unblocks, deletes the *Open design question* section, and sets `next: develop` itself when the ticket
is unclaimed. It hands off here only when the ticket is already claimed.

---

## Step 3 — Insert at the right rank

**Every new ticket is placed at a considered position. Not optional, and there is no default slot** —
appending to the bottom or dropping it on top both destroy the property the queue exists for: that
`develop` can take row 1 without a judgement call. The capturing session decides; it has the context, and
a cold agent weeks later will not.

Rank is a **total order produced by pairwise comparison**, never a score. False precision produces ties,
and ties are what the queue eliminates. The only operator is:

> If I could ship exactly one of these two before the other, which would I regret skipping more?

### The coarse sort: five tiers

| Tier | Name | The test |
|---|---|---|
| 1 | **Bleeding** | Damage accrues while it sits: live user-visible breakage, security or privacy exposure, data loss, or output that is silently wrong, which is the worst case because nobody is counting the damage |
| 2 | **Compounding** | Nothing bleeding, but the fix gets more expensive every day: a wrong pattern being copied into new code, a migration costing more per row that accrues, a foundation defect each new project inherits |
| 3 | **Blocking** | Queued work cannot start until this lands. Its value is mostly the work it releases |
| 4 | **Value** | Someone asked for it and it makes something better. Nothing degrades if it waits a month |
| 5 | **Debt & polish** | Real, inert, known. Accepted trade-offs, cleanups, ergonomics, speculative hardening |

Tier 2 is mis-ranked most often, because nothing looks wrong today.

### Tie-breakers within a tier, applied in this order

Stop at the first one that separates them; do not average them.

1. **Blast radius** — all projects > one project > one path in one project.
2. **Unblocks more** — releasing two queued tickets beats releasing none.
3. **Knowledge freshness** — a ticket you can specify precisely today and would have to re-derive in a
   month wins over an equal one that stays cheap.
4. **Smaller and more certain** — clears the deck, returns feedback sooner, costs less if what you learn
   changes the plan below it.
5. **Capture order** — otherwise the earlier ticket stays higher. A queue that reshuffles on every
   capture stops carrying signal.

### Rules that override the tiers

- **A prerequisite outranks its dependent.** If A makes B possible or materially cheaper, A goes above B
  even when B sits a tier higher — otherwise row 1 is something that cannot be started.
- **An external deadline promotes** to the top of its tier, and above its tier if the date is close.
- **A regression guard ranks with the bug it guards.** Never split a fix from the test that stops it
  returning and let the test drift down the queue.
- **A blocked or waiting ticket keeps its rank.** Set the status and leave the line. Sinking it means
  rediscovering why it mattered when the blocker clears, which is exactly the judgement being stored.

### Never rank by

- **Recency.** The append-to-top reflex is the single most common way a stack rank rots.
- **The session's current budget.** Rank is absolute; matching work to the session you actually have is
  `develop`'s problem, and `size` informs that without touching the order.
- **How interesting it is to build**, or **a number** — if two feel equal they aren't, so apply the
  tie-breakers until one wins.
- **An imported label.** A reported `Priority: Urgent` is one input to tier selection and nothing
  more; whoever set it was not ranking this queue.

### Procedure

Compare the new ticket against row 1. If it doesn't beat row 1, walk down to the first row it beats and
insert above that. **Insert; do not re-sort** — rows you aren't comparing against stay where they are.

**Insert with a single `Edit`**, matching the row you're going above and replacing it with your new row
followed by it (`CONCURRENCY.md`, *Never rewrite `QUEUE.md` by hand* and *Re-read immediately before you
write*). If the `Edit` fails the queue moved under you — re-read, re-check the placement, edit again;
never widen the match to force it through.

Then re-read rows 1–3: if the new ticket makes the existing row 1 look wrong, that's real information, so
say so and propose the rerank. **Write the reasoning into `RANKING.md`** — the pared table cannot carry
it, and a re-rank a month from now is an argument from nothing without it.

If you cannot justify the placement in one sentence, the problem statement is too vague to rank. Sharpen
it first.

### Report the placement

One line naming the neighbours and the reason: *"Slotted at #3 — above the export tidy-up because it
blocks 0009, below the auth fix which is Tier 1."* Assert it rather than asking permission; if the user
disagrees they will say so, which is cheaper than a question every time.

---

## Step 4 — Rerank

Move whole rows. There is nothing to renumber — line order is the rank. Never add a priority field to
resolve a tie; the tie is resolved by which line is higher.

A move is two single-line edits — delete from where it was, insert where it goes — each preceded by a
fresh read. Do not reorder a row that is `in-progress` under a token you did not mint: another session
is working it, and its rank is no longer the interesting fact about it. Record why in `RANKING.md`.

---

## Step 5 — Surface work that was parked somewhere else

**One step, two sources.** Both hand you a report rather than a work item, so both get the same
treatment.

| Source | Availability | What it holds |
|---|---|---|
| `.claude/backlog/FINDINGS.md` | always, no config | what a session noticed while working and could not place |
| an external feedback source | only if `config.yml` has `external_feedback.enabled: true` | what other humans reported |

### The buffer — `FINDINGS.md`

**`queue` takes the entries that are units of work; `retro` takes the lessons.** Two sweepers, one file,
neither waiting for the other. **An entry that is both is taken by both**, so nothing has to be
classified at the moment of noticing.

For each entry that is a unit of work:

1. **Do the Step 2 work properly.** A parked line is one sentence and a pointer: no FRs, no NFR
   citations, no ACs, no QA level. Write them.
2. **If you cannot specify it, do not rank it.** Write the item file with a *Problem* section and
   `next: queue`, and **leave it out of `QUEUE.md`**. The queue is what every session reads to find its
   next row, so it holds only specified, ranked tickets — an unspecified row costs every reader a look
   and gives `develop` something it must refuse.
3. **Rank per Step 3** once specified. A parked finding gets no rank bonus for having been noticed
   recently; that is the recency trap.

**Check the entry is still true before specifying it.** The buffer is where staleness is most likely —
an entry sits for weeks while the code moves under it — and a fully-specified row describing behaviour
that no longer exists is worse than no row. Two entries in one sweep had been discharged by later work:
a missing test file that now exists, and a click-swallowing bug whose cause a later change had removed.
`develop` Step 2 has the right instrument and it applies here unchanged — **grep the symbol the entry
names, not just `DONE.md`**, because a fix that landed outside the lifecycle leaves no row behind.

**Remove only the entries you processed, and commit in the same turn**, by pathspec. Leaving a processed
entry is re-read by the next sweep; removing an unprocessed one loses `retro`'s half.

**For an entry that is *both* work and lesson, annotate it in place rather than choosing.** Deleting it
loses `retro`'s half; leaving it untouched makes the next sweep pay to read it again, which on a large
buffer is the dominant cost. Neither is acceptable, so append the row its work half became — *"filed as
item 0108; kept for the lesson, do not re-file"* — and leave the entry for `retro`. The same marker is
what `retro` writes from the other side, so one convention serves both sweepers.

### The external source (opt-in)

Only if `config.yml` has `external_feedback.enabled: true`. Most projects won't; **skip silently
otherwise and never prompt** — *which* product holds other people's reports is a profile question, not
one this skill answers for every project it scaffolds. When it is on, read
`references/EXTERNAL-FEEDBACK.md`: the flow is one-way, source → local, and it holds what a source must
provide, the de-duplication log and the field mapping.

---

## Step 6 — Commit the backlog, and only the backlog

`queue` writes backlog files and never source, so **every path in its commit is under
`.claude/backlog/`** — enforced by what you stage, not by what you believe you edited:

```bash
git add -N .claude/backlog/items/0007-*.md          # a file git does not know yet
git commit -m "Capture 0007: <title>" -m "Co-Authored-By: <model> <noreply@anthropic.com>" -- \
  .claude/backlog/QUEUE.md .claude/backlog/items/0007-*.md .claude/backlog/config.yml
```

**The `git add -N` is not optional**: the item file is the one capture just wrote, and a pathspec
naming a path git has never seen fails the *whole* commit — queue rows included — with *"did not match
any file(s) known to git"* (`CONCURRENCY.md`, *The git index is shared*). The retry happens while the
lock is held and `QUEUE.md` is dirty, which is the worst moment to be improvising.

The `--` and the explicit paths are the whole safety feature; **`git add` then a bare `git commit` is not
a substitute** (`CONCURRENCY.md`, *The git index is shared*). It matters most here because capture
usually runs in the window that is *not* developing, so the other window's half-finished work is in the
same tree and frequently the same index.

Source paths already staged when you arrive are the other window's: `git restore --staged <path>` takes
them out of *your* commit without touching their working tree. Never `git stash` to tidy.

---

## Step 7 — Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

---

## Step 8 — Report

What belongs on the screen and what belongs on disk is `references/REPORTING.md` at the plugin root.
The instance of it that bites this stage: the item file is the detail, so name its path rather than
echoing it back — everything a session would quote from it, it just wrote there.
