---
name: queue
description: >
  Turn project feedback, bugs, and work items into a stack-ranked local backlog that any agent
  can pick up later and build without asking a clarifying question. Use whenever the user
  reports a bug, requests a feature, or says "queue this", "add this to the backlog", "log this
  bug", "we should fix X sometime", "park this for later", or invokes /queue. Also use to
  reorder, inspect, block, or import the backlog — "what's next to build", "show the queue",
  "move X to the top", "reprioritise", "import feedback from Notion". Use proactively when the
  user describes engineering work that is clearly not for right now. The executor is the agent,
  and the artifact is code. NOT for the user's own tasks, meetings, or notes — that is /capture,
  which keeps a personal knowledge base and where the executor is the user. When the input is a
  commitment to a person, a meeting outcome, or a dated follow-up, it belongs there instead. The
  backlog lives in .claude/backlog/ inside the project.
---

# /queue

Turn something the user just said into a fully specified, stack-ranked backlog item that a
cold agent can pick up weeks later and implement without asking a single clarifying question.

The queue file is the product; this skill is a thin wrapper over it. If you ever can't run
this skill, `.claude/backlog/QUEUE.md` is still readable on its own.

**The backlog is worked by more than one session at a time** — commonly one window developing
while another queues. Read `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file) before writing anything. In short: edit one
row at a time, never rewrite `QUEUE.md` whole, and take the lock only to claim an ID.

**This skill states no standards of its own.** Every rule about security, privacy,
accessibility, testing, or documentation is cited from the project's conventions, never
restated here or in an item. Resolve them per `references/CONVENTIONS.md`; if none resolve,
stop as that file directs.

---

## Storage layout

Per project, at the repo root:

```
.claude/backlog/
  config.yml     project settings, next_id, conventions path, test commands, optional tracker / cost / Notion blocks
  QUEUE.md       the stack rank — line order IS the rank. Header and table only.
  RANKING.md     why the order is what it is. Standing reasoning, read only for re-ranks.
  next           reader: row 1, first takeable row, files in-progress items have claimed
  claim          claims a row: lock, edit, write frontmatter, commit, unlock — one atomic step
  DONE.md        completed items, newest first
  .lock/         transient; held for seconds during an ID or item claim. Never committed.
  items/
    0007-rate-limit-feedback-endpoint.md
```

Templates are in this skill's `templates/` directory. Copy `next` and `claim` too, and
`chmod +x` both.

**`FINDINGS.md` is a buffer, not a second queue.** It holds what a session noticed but cannot yet
place — a possible row, a skill that misled, a cost pattern. Anything whose home is already obvious
goes to that home instead, and anything that is a unit of work becomes a row here. `retro` empties
it; its template says how.

**`claim` is not a convenience.** A claim edits `QUEUE.md`, and until that edit is committed the
claim exists only in one working tree — so the next session to commit the queue carries it off
under their own message, silently. The script locks, edits, commits and unlocks as one step,
because the commit is exactly the thing a session under load forgets. See `CONCURRENCY.md`,
*A claim must be durable the moment it is made*.

**`QUEUE.md` holds the header and the table, and nothing else.** Standing reasoning about the
order lives in `RANKING.md`. The split is mechanical rather than tidy-minded: the queue is
rewritten on every claim and every close, by every window, so any prose parked in it is re-read
— and in an agent session, re-echoed — on each of those edits, while changing perhaps once a
week. `./next` exists for the same reason and goes further: it answers "what do I do next" in a
handful of lines whether the queue holds ten rows or three hundred.

---

## Step 0 — Locate or create the backlog

Find `.claude/backlog/` at the root of the current project. If it doesn't exist, scaffold it
by copying `templates/config.yml`, `templates/QUEUE.md`, `templates/RANKING.md`,
`templates/FINDINGS.md`, `templates/next`, `templates/claim` (both `chmod +x`), and creating
`items/`, then fill in
`config.yml` from what the repo actually uses: read `package.json` scripts (or `Makefile`,
`pyproject.toml`) for the real test/lint/typecheck commands rather than guessing. Leave the
`notion:` block out unless the user says this project collects feedback from other people,
and leave `tracker:` / `cost_tracking:` out unless the project's `CLAUDE.md` profile points
at a company tracker or the user asks for per-item cost attribution — see
`references/TRACKER.md`. Never invent a project key: an item mirrored into the wrong
project is noise in someone else's board.

**Resolve the conventions now**, per `references/CONVENTIONS.md`, and record the path in
`config.yml` under `conventions.path` so the next session doesn't have to re-derive it. If
nothing resolves, do not scaffold — report the missing wiring and stop. A backlog whose items
cite no standard is a backlog that cannot be verified later.

---

## Step 1 — Decide the operation

| User says | Do |
|---|---|
| describes a bug / feature / annoyance | **Add** (Step 2) |
| "what's next", "show the queue" | Read `QUEUE.md`, print the top rows, stop |
| "move X up", "do Y first", "reprioritise" | **Rerank** (Step 4) |
| "X is blocked on Y" | Set `status: blocked` (or `waiting`, if a person is what is needed), record it in the item file |
| "import from Notion", "any new feedback?" | **Import** (Step 5) |

Adding is the default when the intent is ambiguous.

Read-only operations — printing the queue, reporting what's next — do not need the conventions
resolved. Anything that writes an item does.

---

## Step 2 — Add an item

Read `templates/item.md`. That template is the contract — every section exists because
something downstream reads it. Fill it in as follows.

**Claim an ID — under the lock.** This is a read-modify-write and it is one of exactly two
operations in the whole backlog that needs coordination. Reading `next_id`, using it, and
writing back `next_id + 1` without the lock is how two parallel queue runs both take 29.

```bash
BACKLOG=".claude/backlog"
mkdir "$BACKLOG/.lock" 2>/dev/null || { cat "$BACKLOG/.lock/held-by"; }   # busy → see CONCURRENCY.md
```

Inside the lock: read `next_id`, write back `next_id + 1`, then `rm -rf "$BACKLOG/.lock"` in
the same turn. Everything after this — writing the item file, ranking, inserting the row — is
done unlocked.

Before using the number, confirm no `items/<id>-*.md` already exists. If one does, the counter
drifted behind reality (a session died after creating a file but before incrementing); take the
next free number and fix `next_id` rather than overwriting someone's item.

**Write the Problem section from evidence, not paraphrase.** If the user gave a repro, error
text, or a screenshot path, put it in verbatim. Details that live only in this conversation
are lost the moment it ends.

**Derive functional requirements.** Ask yourself what a reviewer would check to say "yes, this
is done." Each FR must be independently verifiable. Two vague FRs are worse than one sharp one.

**Fill the NFR table by elimination, not by default.** Read the conventions core's index first
— it names which file governs each dimension and when that file is triggered. Then walk every
row and decide whether it genuinely applies to *this* change. The triggers below are the ones
worth naming explicitly because they are the ones most often missed:

- Touches auth, credentials, data visibility, or untrusted input? → Security row is mandatory.
- Introduces or moves personal data, a new log field, a new egress destination, or sends data
  to a model? → Privacy row is mandatory.
- User-facing UI? → Accessibility row is mandatory.
- Schema change or backfill? → Migration row is mandatory.
- Real users already on this path? → Progressive delivery row is mandatory.

For each row you keep, write **what this specific item must satisfy** in the middle column, and
cite the governing convention file by bare filename in the third. Read that file if you aren't
certain what it requires — the row must be a real commitment, not a guess. Delete rows that
don't apply: a table of nine "N/A"s trains everyone to skip the table.

**Never restate a convention's rules inside an item.** The item says what *this change* must
do; the convention says what the rule *is*. Copy the rule in and it drifts from source the
first time you edit either one, and `verify` will then check the stale copy.

The always-on rules in the conventions core apply to every item and need no row.

**If the item cannot have acceptance criteria yet, set `next: design` instead of guessing
them.** Not every item arrives specifiable. When the blocker is a decision — which pattern,
which flow, what the empty state is — write the *Open design question* section in the item,
set the stage, and rank it normally. It keeps its rank: the work is worth what it was worth.

This is a real stage, not a euphemism for vague. The test is whether a *decision* is missing,
not whether detail is missing. Missing detail you sharpen now; a missing decision is settled by
`/design` (returns an answer) or `/prototype` (returns something to look at), and the findings
come back here to be written up. Guessing acceptance criteria to avoid the stage is how an item
gets built to a contract nobody agreed to.

**Clearing it:** when the question is answered, write the FRs and ACs it unblocks, record the
answer in *Notes & decisions*, delete the *Open design question* section, and set
`next: develop` / `status: ready`.
`design` and `prototype` hand findings here; they never write item files themselves.

**Set `qa_level` now, at queue time.** This is the decision that stops QA rigor quietly
sliding session to session. The levels sit on the testing pyramid defined in
`testing-conventions.md` — read it if the choice isn't obvious:

- `verify` — no test runner applies (docs, config, conventions, tooling). Requires a **scripted
  assertion** the item names explicitly — a grep, a path-existence check, a schema validation.
  If you cannot write one, the item isn't verifiable and needs sharper ACs, not this level.
- `unit` — pure logic, isolated module, no wiring changed.
- `integration` — crosses a seam: route → service → database, adapter contracts, serialization,
  migrations.
- `e2e` — a critical user journey whose breakage is unacceptable, or the change only manifests
  through the real build/infrastructure. Needs a one-line justification of why integration
  can't cover it, and the pyramid says there should be few of these.

**Estimate `size`** — `s` (one sitting), `m` (a focused session), `l` (multiple sessions, or
needs a design decision before it can start). This exists so a short session can see the cost of
row 1 without being tempted to reorder around it. It is an input to tie-breaker 4 only; it never
moves an item between tiers.

**Record `expects:` — the files this item is likely to reach — while the code is still open.**
You cannot write the FRs above without reading the code that implements the behaviour, so the
list costs almost nothing at this moment and cannot be reconstructed later at the same price.
Name the implementation files, and the tests that exercise the behaviour being changed: a change
that alters what an existing behaviour *means* reaches every spec that drives it, and those are
the ones a later reader will miss.

Its job is **triage, not protection**. A session deciding what to take next compares candidates'
`expects:` against the `touches:` of in-progress rows, and skips a collision without having to
research every candidate itself — which is the cost this field exists to remove. So:

- **It protects nothing and locks nothing.** Being wrong costs one suboptimal pick, which is why
  a best guess beats an empty field and why it is fine for it to age.
- **It is never promoted unchecked.** `develop` verifies it against the code on claim and writes
  the corrected list to `touches:`, which is the live claim. Finding it wrong there is the system
  working, not a defect in the capture.

**Write acceptance criteria as given/when/then.** `verify` checks these literally.

**An AC must be provable within the item's own scope.** An AC whose reproduction needs something
the same item sends to *Out of scope* cannot be met, and `verify` is right to fail it — which
leaves a finished item stuck between a red it cannot fix and a scope it must not grow. Write that
as the observation it is ("the run reports X, whose fix is item NNNN"), and keep the AC to what
this item can actually change.

If the user's report genuinely doesn't contain enough to write FRs or ACs, ask — but ask once,
batched, with your proposed defaults, not one question at a time.

---

## Step 3 — Insert at the right rank

**Every new item must be placed at a considered position. This is not optional and there is no
default slot.** Appending to the bottom because it's new, or putting it on top because it's
freshest, both destroy the property the queue exists for: that `develop` can take row 1 without
a judgement call. The session capturing the item is the one that decides — it has the context,
and a cold agent weeks later will not.

Rank is a **total order produced by pairwise comparison**, not a score. Never compute a weighted
number; false precision produces ties, and ties are the thing we're eliminating. The only
operator is:

> If I could ship exactly one of these two before the other, which would I regret skipping more?

### The coarse sort: five tiers

Place the item in a tier first, then position it within that tier.

| Tier | Name | The test |
|---|---|---|
| 1 | **Bleeding** | Damage accrues while it sits. Live user-visible breakage, security or privacy exposure, data loss or corruption, or output that is silently wrong — wrong answers that look right are the worst case, because nobody is counting the damage. |
| 2 | **Compounding** | Nothing is bleeding, but the fix gets more expensive every day it waits: a wrong pattern being copied into new code, a migration that costs more per row that accrues, a foundation defect each new project inherits, a decision that blocks design. |
| 3 | **Blocking** | Queued work cannot start until this lands. Its value is mostly the work it releases. |
| 4 | **Value** | Someone asked for it and it makes something better. Nothing degrades if it waits a month. |
| 5 | **Debt & polish** | Real, inert, and known. Accepted trade-offs, cleanups, ergonomics, speculative hardening. |

Tier 2 is the one that gets mis-ranked most often, because nothing looks wrong today. A
convention error that three more projects will copy this month is genuinely more urgent than a
feature request, and the queue should say so.

### Tie-breakers within a tier, applied in this order

Stop at the first one that separates them; do not average them.

1. **Blast radius** — all projects > one project > one path in one project.
2. **Unblocks more** — the item that releases two queued items beats the one that releases none.
3. **Knowledge freshness** — context that is hot right now is a perishable asset. An item you
   can specify precisely today and would have to re-derive in a month wins over an equal one
   that will be just as cheap later.
4. **Smaller and more certain** — clears the deck, returns feedback sooner, and costs less if
   what you learn doing it changes the plan for everything below.
5. **Capture order** — if nothing above separates them, the earlier item stays higher. Stability
   is a feature; a queue that reshuffles on every capture stops carrying signal.

### Rules that override the tiers

- **A prerequisite outranks its dependent.** If A makes B possible or materially cheaper, A goes
  above B even when B sits a tier higher. Dependency order beats importance order — otherwise
  row 1 is something that cannot actually be started.
- **An external deadline promotes.** Someone waiting on it, an API deprecation, a date — moves
  to the top of its tier, and above its tier if the date is close.
- **A regression guard ranks with the bug it guards.** Never split a fix from the test that
  stops it returning and let the test drift down the queue.
- **A blocked or waiting item keeps its rank.** Set the status and leave the line where it is. Do
  not sink it to the bottom — when the blocker clears you would have to rediscover why it
  mattered, and that judgement is exactly what you're storing here.

### Never rank by

- **Recency.** Freshest is not most important, and the append-to-top reflex is the single most
  common way a stack rank rots.
- **The session's current budget.** Do not sink a big item because tokens are short today or
  float a small one because they are. Rank is absolute; matching work to the session you
  actually have is `develop`'s problem, and the item's `size` field is there to inform that
  without touching the order. A queue reordered around convenience never surfaces the important
  expensive thing.
- **How interesting it is to build.**
- **A number.** No priority field, no score column. If two items feel equal, they aren't — apply
  the tie-breakers until one wins.
- **An imported label.** A Notion `Priority` of `Urgent` is one input to tier selection and
  nothing more; the reporter was rating their own annoyance, not your queue.

### Procedure

Compare the new item against the current row 1. If it doesn't beat row 1, walk down until you
find the first row it beats and insert above that. **Insert; do not re-sort the queue.** Rows
you aren't comparing against stay where they are.

**Insert with a single `Edit`**, matching the row you're going above and replacing it with your
new row followed by it. Re-read `QUEUE.md` immediately before that edit — another session may
have closed an item or inserted its own since you last read it. Never rebuild and rewrite the
whole file: there is no `#` column to renumber, so there is never a reason to touch a row you
did not decide about. See `CONCURRENCY.md` Rules 1 and 2.

If the `Edit` fails because the row no longer matches, that means the queue moved under you.
Re-read, re-check that your placement still holds, and edit again — do not widen the match to
force it through.

Then re-read rows 1–3. If the new item's presence makes the existing row 1 look wrong, that's
real information — say so and propose the rerank. Otherwise leave the rest alone.

If you cannot justify the placement in one sentence, the problem is upstream: the item's
problem statement is too vague to rank, so sharpen that before placing it.

### Report the placement

One line, naming the neighbours and the reason: *"Slotted at #3 — above the export tidy-up
because it blocks 0009, below the auth fix which is Tier 1."* Assert the placement rather than
asking permission; if the user disagrees they will say so, and that is cheaper than a question
every time.

---

## Step 4 — Rerank

Move whole rows. There is nothing to renumber — line order is the rank, and the table carries
no position column precisely so that moving one row does not rewrite every other. Never add a
priority field to resolve a tie; the tie is resolved by which line is higher.

A move is two single-line edits — delete the row from where it was, insert it where it goes —
each preceded by a fresh read. Do not reorder a row whose `Owner` column holds a token you did
not mint: another session is working it, and its rank is no longer the interesting fact about
it.

---

## Step 5 — Import from Notion (opt-in)

Only if `config.yml` has `notion.enabled: true`. Most projects won't; skip silently otherwise
and never prompt to set it up unless the user raises it.

The flow is **one-way, Notion → local**. Notion is where other humans report; the local queue
is what agents work from.

1. `mcp__claude_ai_Notion__notion-query-data-sources` on `notion.data_source_id`.
2. Skip any page whose id already appears in `imported-notion-ids.txt`.
3. For each new page, map its fields and then **do the Step 2 work properly** — a raw Notion
   row is a report, not a work item. It has a title, a type, a priority, and a paragraph; it
   has no functional requirements, no NFRs, no acceptance criteria, and no QA level. Write
   those. An imported item that skips this is the thing `develop` will choke on.
4. Set `source: notion:<page-id>` in the frontmatter, append the page id to the imported log,
   and rank per Step 3. A Notion `Priority` of `Urgent` is an input to ranking, not the answer.

Nothing is written back to Notion.

---

## Step 6 — Commit the backlog, and only the backlog

`queue` writes backlog files. It never writes source, so **every path in its commit is under
`.claude/backlog/`** — and that has to be enforced by what you stage, not by what you believe you
edited:

```bash
git commit -m "Capture 0007: <title>" -- \
  .claude/backlog/QUEUE.md .claude/backlog/items/0007-*.md .claude/backlog/config.yml
```

**Commit by pathspec — the `--` and the explicit paths are the whole safety feature**, and
`git add` followed by a bare `git commit` is not a substitute for it. `git commit` commits the
*entire index*, not the paths you happened to stage a moment earlier, so a careful
`git add .claude/backlog/… && git commit` still carries off whatever the other window had
staged. The pathspec form commits those paths and nothing else, whatever else is in the index.

**Never `git commit -a`, `git add .`, or `git add -A` here.** Capture usually runs in the window
that is *not* developing, so the other window's half-finished work is sitting in the same tree and
frequently in the same index. Sweeping it up is silent: no error, no conflict, and a source change
lands under a commit message about a backlog entry. This has happened, and it is why
`CONCURRENCY.md`'s *The git index is shared* exists.

If you find source paths already staged when you arrive, they are the other window's. Leave them:
`git restore --staged <path>` takes them out of *your* commit without touching their working tree.
Never `git stash` to tidy the tree — bare `stash` takes their uncommitted work with it.

---

## Step 7 — Report

One short block: the ID, the title, its position, and what else moved. Don't echo the whole
item file back — it's on disk.
