---
id: "0242"
title: Make every backlog write one script call, and make the scripts agree with each other
type: debt
next: verify
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-11-26
source: user
parent:
blocked_by: []
relates: ["0085", "0048", "0081", "0047", "0066", "0118", "0227", "0096", "0155", "0103", "0215", "0106", "0225", "0067", "0147", "0045", "0027", "0029", "0228", "0115", "0229", "0230", "0213", "0060", "0142", "0141", "0156", "0217", "0219", "0050", "0235", "0237", "0236", "0100"]
expects:
  - skills/queue/templates/capture
  - skills/queue/templates/park
  - skills/queue/templates/rank
  - skills/queue/templates/withdraw
  - skills/queue/templates/drain
  - skills/queue/templates/next
  - .tickets/capture
  - .tickets/park
  - .tickets/rank
  - .tickets/withdraw
  - .tickets/drain
  - tests/capture.test.sh
  - tests/park.test.sh
  - tests/rank.test.sh
  - tests/withdraw.test.sh
  - tests/drain.test.sh
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/SKILL.md
  - skills/retro/SKILL.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
  - skills/sprint/SKILL.md
  - skills/prototype/SKILL.md
  - references/CONCURRENCY.md
  - CHANGELOG.md
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/reopen
  - skills/queue/templates/item.md
  - tests/next.test.sh
  - tests/claim.test.sh
  - .claude/backlog/claim
  - .claude/backlog/next
  - .claude/backlog/close
  - tests/close.test.sh
  - .tickets/next
  - skills/queue/templates/handoff
  - .claude/backlog/handoff
  - tests/handoff.test.sh
  - tests/findings-routing.test.sh
ac_digest: AC1=3f4813fa AC2=00ed7e8d AC3=cc9098c3 AC4=c39ef3f4 AC5=cd5192a9 AC6=08ff8130 AC7=19b18cb5 AC8=b842bc08 AC9=18fa1024 AC10=6e4e0541 AC11=4fce6a8a AC12=85333459 AC13=184dee36 AC14=e8fbc130 AC15=f8a8f901 AC16=b2de2b18 AC17=f8f530b6 AC18=3c1c133b AC19=c00e3e5b AC20=b7aea097 AC21=2797aa8b AC22=2982ae38 AC23=2ae59f5d AC24=4ee45ae4 AC25=efb5b2ea AC26=d6679279 AC27=1900687b AC28=f0678e1a AC29=ca008731 AC30=2c0cb400 AC31=2fea3bb7 AC32=0ea2fa1f AC33=0798a7d2 AC34=17f78639 AC35=81a1eeed AC36=295a79f7 AC37=03c9ed76 AC38=99abb6b8 AC39=157525d8 AC40=ea7e3fba AC41=e8935ea1 AC42=d89f512e AC43=b2861434 AC44=7dfc9899 AC45=167587a8 AC46=e93172ec AC47=cef1068e AC48=66233639 AC49=e1f1156c AC50=d1b0c900 AC51=6158b990 AC52=553a49b4 AC53=71802b40 AC54=6a89e958 AC55=fc2745e7
claimed_by:
claimed_at:
touches:
slice: S2
---

## Problem

**Outcome (merged 2026-11-26, at the user's direction):** no session writes the backlog by hand, and every backlog script gives the same answer to the same question. Part A (S1–S7) makes the existing scripts agree; Part B (S8–S14) scripts every write that is still made by hand. The protocol then costs one call per write, and a wrong answer from one script can no longer strand a row.

**The stage boundaries develop and verify cross are scripted, and since then their protocol cost has
roughly halved. The writes queue and retro make, and the findings park every stage makes, still
take the lock by hand.**

`0085` (closed 2026-09-03) set the rule *one command per stage boundary* and `./claim`, `./handoff`,
`./close` and `./reopen` carry it. Re-running `tools/classify-turns.sh` over this repo's store for
2026-09-04 to 2026-11-25 (68 sessions, run 2026-11-26), against the pinned August set in
`MEASUREMENT.md`:

| Stage | Mechanism share of turns, Aug | Since Sep 4 | By-hand lock, share of mechanism | Queue-file edits, share of mechanism |
|---|---|---|---|---|
| develop | 38.4% | 20.8% | 10.9% | 2.2% |
| verify | 49.5% | 27.7% | 6.5% | 4.3% |
| queue | 39.2% | **56.1%** | **21.7%** | **17.4%** |
| retro | 30.4% | **35.0%** | **28.6%** | **28.6%** |

The sample is small (4 develop, 6 verify, 3 queue, 1 retro sessions) because the store no longer
holds most driven sessions; read it as direction, not a verdict.

The write sites with no script, from the skills as at `6b7273d`:

- **queue Add.** The session mints the id from the disk, bumps `next_id`, writes the item, inserts
  the row at its rank with an `Edit`, stamps `ac_digest:` from `./next --ac-digest`, appends the
  reasoning to `RANKING.md`, commits by pathspec with `git add -N` first, and releases the lock, all
  by hand. Capturing 0240 and 0241 on 2026-11-26 took eight tool calls for this. The first attempt
  died on a script error with the lock already taken; it released only because the release was
  chained after it in the same call.
- **queue Rerank, Withdraw, Merge and Re-specify.** A row is moved by two `Edit`s, a ticket is
  withdrawn by hand (`status:`, emptied `next:`, a dated note, the row removed, every `blocked_by:`
  naming it re-pointed), and criteria are re-stamped by hand. `3b72d38` broke both withdrawal rules
  at once.
- **The findings park, in every stage and the supervisor.** Each stage's *Park what surprised you*
  step and `sprint` Step 9 take the lock, append one dated line, commit by pathspec and unlock, and
  route cross-repo by hand. Decision `001` retained this as one turn. As written it is a lock, an
  append, a commit and an unlock, and the head-token shape and the privacy bar for a public repo
  (`0118`) are checked by no one at that moment.
- **retro and queue draining `FINDINGS.md`.** Removing processed entries, marking `[->NNNN]`, and
  moving held entries to `FINDINGS-HELD.md` are all by-hand edits under a by-hand lock. `0227`
  records the header-matching hazard this creates.
- **develop Step 1's by-hand claim fallback**, kept for a backlog without `./claim`. `queue` Step 0
  now installs and byte-syncs the scripts in every backlog it opens.

`0048` asked which of these to script and was withdrawn in the 2026-10-28 triage for want of a
confirming project. The user asked for this on 2026-11-26: *"queue the work to script as much of
the backlog protocol as would still be effective so we can reduce those cost and reduce risk."*

### Absorbed 2026-11-26: 0215 — Make claim and next read expects and touches through one parser that refuses or accepts the comma form

**Two readers of the same frontmatter field disagree, and both fail open.** Parked five times in one
week from AetherWorks (2026-10-18 ×3, 2026-10-24 ×2), each from a different session:

- `fm_list` in `skills/queue/templates/next` (line ~551, copied into `close` and `reopen`) reads
  `expects:` only as an inline `[a, b]` list or a `- ` block. A bare scalar `expects: a.ts, b.ts`
  reads as **empty**: `./next develop` prints `EXPECTS not predicted — check this one by hand`, and
  `collision_report` compares nothing, so two windows can land in one file. AetherWorks 0113 carried
  four real paths in that form; 11 open AetherWorks items did on 2026-10-24 (0104, 0109, 0117, …).
- `claim`'s `touches:` seeder (line ~315, `fm && inexp && /^[ \t]+-/`) reads **only** the `- ` block.
  AetherWorks 0130 was rewritten from block to inline at `8b8da81` *"so ./next reads it"*; within the
  same minute `./next develop` printed all four paths and `./claim 0130` printed *"touches: is unset:
  0130 declares no expects:"* and seeded nothing. A claimant who trusts that message reserves no files.

`templates/item.md` gives `blocked_by:` a ONE-form note (0044 hit the same two-shape defect there) and
gives `expects:`/`touches:` none, so the writers — `queue` and `design` hand-offs — produce all three.

### Absorbed 2026-11-26: 0225 — Make claim write an empty touches key when it has nothing to seed

`./claim` and `./handoff` disagree about an item whose frontmatter has no `touches:` key.
Observed in AetherWorks item 0027 (develop, sprint run-20261101T172121Z): the item had no
`expects:`, so `claim` seeded nothing and — because its awk adds the key only under
`!tou && n && seed` (`skills/queue/templates/claim`, the frontmatter-close rule) — wrote no
`touches:` key at all, telling the session to set it by hand. `./handoff` then refused outright:

```
<id>'s frontmatter has no: touches
```

(`skills/queue/templates/handoff`, the absent-keys check). The ticket was going back to `design`
before any scope existed, so the session had to commit an empty `touches:` key by hand only so the
hand-off could run. `claim` already backfills the other missing ownership keys
(`note: item predated some of the claim keys; added them`); `touches:` is the one it skips.

### Absorbed 2026-11-26: 0155 — Make claim and next agree on what blocks a take

Five defects where `claim` and `next` disagree, each from the findings buffer:

1. **`claim` reads any `*` inside an `expects:` entry as the exclusive claim `"*"`.** The detector is
   `if ($0 ~ /\*/)`, so `tests/*.test.sh` is refused with *"its expects: declares \"*\", an exclusive claim
   over the whole tree"* whenever anything else is held; `next` uses `contains_word '*'` and reads the
   glob as one path (verify 2026-09-10, develop 0147).
2. **`next` offers a takeable exclusive-claim row that `claim` then refuses.** With another row held,
   `./next develop` printed `TAKE 0001 … EXPECTS *`; 0067 FR5/FR24 key on a *held* `"*"` row only.
3. **`./claim <id>` makes no file-scope check.** `/develop 0130` claimed a row whose four `expects:`
   paths were the four `0131` held, with no warning; only `./next <stage>` prints the comparison, and
   only for its own candidate.
4. **`--drift` does not flag an `expects:` path that exists nowhere.** After the 0129 rename four open
   rows expected `skills/orchestrate/SKILL.md`; a path that exists nowhere collides with nothing, so the
   row reads clear exactly when nobody can tell (four sessions reported it).
5. **`next --help` calls the collision test the third of four; since 0140 it is the fourth.**

### Absorbed 2026-11-26: 0066 — Fix the three places the backlog scripts answer the wrong question

Three defects in the scripts the skills tell every session to use. Two are cosmetic-looking and one
is not.

**`claim`'s success message is stage-blind, and the consequence reaches other sessions.** It tells
every claimant "now set `touches:` … before you open anything" — but a `verify` claim holds no
`touches:`; it reads and runs, it does not open a file scope. The message is wrong for that stage,
and the effect is not cosmetic: `./next` then reports the row to every other session as
`0027 [b8d3] none declared — assume held, ask`, so a **correct** `verify` claim is indistinguishable
from an under-specified `develop` one. `CONCURRENCY.md`'s rule to read an empty `touches:` as held
makes that the safe-but-wrong reading, and it is how a whole stage's rows come to look dangerous.

**`./claim --help` and `./close --help` treat the flag as a ticket id.** `./claim --help` answers
`no row for --help in QUEUE.md`. `./next --help` works and documents every mode, so the
inconsistency reads as "this script has no help" rather than "you passed a bad id" — and these
scripts are the interface the skills tell every session to use.

**A non-takeable row 1 reads as an instruction.** 0026 sat at row 1 as `waiting` for a day and was
read as "the next thing to do"; the user asked why we would run that test now. The rank was correct
— a waiting ticket keeps its rank, deliberately — and `./next develop` correctly stepped over it,
but bare `./next` prints `ROW 1: … | waiting` with no indication that nothing can take it, right
beside the counts. It cost a session to explain rather than a script to answer.

### Absorbed 2026-11-26: 0229 — Make next --drift report a closed item that still carries a claim token

Closed items can keep a `claimed_by:` token, and nothing reports it. `close`, `handoff` and
`reopen` all clear the field today, but closes made by hand before a project had `close` did not:
AetherWorks holds **21** `status: done` items with a token, every one closed between 2026-08-15
and 2026-08-22, two days before its `close` script arrived (2026-08-24). The other four repos
using these tools hold none.

What it has cost so far:

- `migrate` refused AetherWorks' move on 2026-11-08 — *"a row is claimed by another token:
  0023 … [3e1c] …"* — until 0228 made it skip closed statuses.
- `skills/develop/SKILL.md` already warns against grepping `claimed_by:` over `items/*.md`, because
  *"at least five closed items still carry the token"* and a session reading them as live scope
  *"concludes there is nothing safe to develop"*. That is a rule kept as prose where a check could
  hold it.

`./next --drift` walks only the rows in `QUEUE.md` (the loop around
`skills/queue/templates/next` line ~990), so a closed item, which has no row, is never looked at.

### Absorbed 2026-11-26: 0230 — Make next say the queue is empty instead of printing a blank ROW 1

On a queue with no rows, bare `./next` prints a row of empty fields. Observed in `hoa` on
2026-11-08 (0.9.47 and 0.9.48 alike):

```
BY STAGE:  queue 0  design 0  develop 0  verify 0
BY STATUS: ready 0  waiting 0  blocked 0  in-progress 0
ROWS:      0
ROW 1:      |  |  | 
```

The `ROW 1:` line is printed unconditionally from `rows | head -1` (template `next`, the
`./next (no argument)` block), so with nothing to read every field is empty. A reader has to cross
check `ROWS: 0` to know the line is not a malformed row.

### Absorbed 2026-11-26: 0227 — Make next list the findings entries so no drain matches a buffer's header by hand

A sweeper draining `FINDINGS.md` by hand finds entries with the regex the buffer's header gives,
`^- (\*\*)?20[0-9]{2}-`. The header's own fenced example of the head token,
`- 2026-09-05 [->0060] — **what happened.** …` (line 32 of `skills/queue/templates/FINDINGS.md`),
matches that regex, so every buffer seeded from the template counts one entry too many to a
by-hand reader. `./next --findings` does not: `count_findings` in `skills/queue/templates/next`
skips everything above the first `---` rule, so the defect lives only in readers that re-derive
entry boundaries themselves.

It has now hit twice, both times in AetherWorks retros:

- run-20261017T193821Z — counted 8 entries where there were 7; an assertion caught it after the
  items, row and counter were written (recorded in item 0213's Problem).
- run-20261101T172121Z, 2026-11-06 — swept from this repo's `FINDINGS.md`, verbatim: *"a retro
  draining by that regex (as retro Step 4 and the header itself describe) found 3 entries in a
  2-entry AetherWorks buffer and would have truncated the header had it not asserted the count."*

Confirmed 2026-11-06: `grep -nE '^- (\*\*)?20[0-9]{2}-' skills/queue/templates/FINDINGS.md` prints
line 32, and the AetherWorks copy at `.claude/backlog/FINDINGS.md` matches on its line 32 too.

**Why not 0213.** 0213 fixed the template's example line and was withdrawn 2026-10-28 ("a guard over
a guard's wording … reopen if a real project hits the defect"). The second hit was in a project copy,
which 0213's own *Out of scope* leaves unfixed — the header is project-owned and never re-copied
(`skills/queue/SKILL.md` Step 0). Editing the template cannot reach the buffers that already exist,
so a template fix would not have prevented this hit. The reader can: the boundary rule already
exists in one script, and the fix is to expose it rather than have each sweeper re-derive it.

### Absorbed 2026-11-26: 0156 — Let handoff record a blocker without leaving drift that stops a driver

**The documented hand-off for a blocked develop stage produces drift, and since 0142 that drift
stops `--drive`.** A develop stage that cannot get green and adds a `blocked_by` entry leaves its row at
`ready`: `handoff` rejects `blocked` as "derived from blocked_by and never authored", and `develop`
Step 5 says the same. `./next --drift` calls that class 2 drift, and `--drive` escalates on it. 0142's
*Out of scope* reserves the class list to 0115 and 0141, so neither settled it (develop 0142).

### Absorbed 2026-11-26: 0217 — Stop a note written below the last AC from changing that AC's digest

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
`./next --ac-digest` hashes everything from an AC's checkbox to the next one, so a note appended below the last AC is hashed into it. On 0182 a develop stop note after AC62 made `--drift` report AC62 changed with its text untouched; moving the note to *Notes & decisions* restored `d0d0b2b8`. **It recurred 2026-10-26 on the same ticket** (the 7bff build note, a day after e50b7c4 fixed the first) — the prose guidance is not holding it.

### Absorbed 2026-11-26: 0219 — Make reopen leave a ticket that verify can close when it reopens a develop self-close

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
`./reopen` moved 0126, closed by develop under `close_by: develop`, back to `next: verify` but left `close_by: develop`, so `./close` refused the verify session the reopen was for ("the stage that may close it is 'develop'"). The person's answer was to re-verify independently and close on that verdict, which no script path permits; verify 0126 (fa1b) set `close_by: verify` by hand on its held item and recorded why. The re-verify itself was a supervisor misreading `close_by: develop` as self-certification (sprint run-20261025T215324Z, USD 0.99) — that half was landed in `skills/sprint/SKILL.md` by this retro.

### Absorbed 2026-11-26: 0235 — Decide whether claim, handoff and close refuse off the branch the backlog is shared on

In a consuming project (AetherWorks, item 0136) a design pass began on a `prototype/` branch one
commit ahead of `main`; `./claim`, the decision and `./handoff` all committed there. On `main` the row
still read unclaimed at `next: design`, so a second session working from `main` could claim it —
the single-holder guarantee does not reach across branches. `references/CONCURRENCY.md` refuses a
linked worktree (*A second checkout never writes the backlog*) and says nothing about a non-default
branch in the primary checkout.

### Absorbed 2026-11-26: 0237 — Give queue a way to send an open verify ticket back to design

A consuming project needed a `next: verify` design ticket sent back to `design` when the user
overturned its answer before close. `queue` Step 1 covers re-specify (`next: queue`) and `./reopen`
(done → verify only); `./handoff` can hand to `design` but needs a claim token, which `queue` does
not hold. So the `next:` field and the `QUEUE.md` row were edited by hand under the lock — the
two-file write the scripts exist to make atomic.

### Absorbed 2026-11-26: 0236 — Decide whether design may amend unheld sibling items its own FRs name

A consuming project's design ticket (written by `queue`) carried "FR49 — amend items B and C to
match, restamp their `ac_digest` in the same commit as the decision". `references/CONCURRENCY.md`,
*A stage writes only the ticket it holds*, forbids it, and `./claim` cannot take B or C (both
`blocked`). The session wrote B and C under the backlog lock after confirming both had empty
`claimed_by:` — the *unheld* test `retro` uses — in one commit with the decision. Handing the edits
back to `queue` costs a round trip and splits the decision from its consequences.

### Absorbed 2026-11-26: 0118 — Run the privacy guard where a sweep commits, not only where a suite runs

**This repo is public, it has a guard against publishing a real home path, and nothing in the
steps that commit to it runs that guard.** `2a69aa9` redacted two published home paths and fixed
the guard that could not tell a redaction from a leak — but the defect it fixed was *introduced*
by `b9d11af`, a sweep session committing tracked files with no cue to check. A `queue` or `retro`
pass that parks or lands prose can commit a file that reds the privacy guard and never find out;
the suite is what discovers it, and neither skill's steps run the suite for a prose park.

`CLAUDE.md` states the rule — this repo is public, no company material reaches it — and the guard
exists to enforce it. The gap is entirely one of *reach*: the rule is written and the check is
committed, and the sessions most likely to violate it are the ones that run neither.


## Functional requirements

**What stays out of the scripts, so they stay effective.** Every judgement the skills describe —
the FRs and ACs, which row a ticket beats, which findings entry is work and which is a lesson, where
a lesson lands — stays with the session. Each script takes that decision as an **argument** and does
only the mechanics. A script that chose a rank or a disposition would be the failure `0009` measured
in reverse: cheaper turns, wrong backlog.

**Shared by every script below**, matching `./claim`, `./handoff` and `./close`:

- **FR1** — Each script takes the backlog lock, retries a busy lock inside itself as `./claim` does
  (`0047`), and releases it on every exit path, success, refusal or error, within its own process.
- **FR2** — Each script commits only the paths it wrote, by pathspec, with the `Co-Authored-By`
  trailer the existing scripts carry, and leaves anything another session staged both staged and out
  of its commit.
- **FR3** — Each script refuses malformed input before taking the lock. It names what is wrong,
  exits non-zero, and changes and commits nothing.
- **FR4** — Each script lives in `skills/queue/templates/`, is installed and byte-synced by `queue`
  Step 0 like the existing five, and is held equal to this repo's `.tickets/` copy by
  `tests/backlog-scripts-installed.test.sh`.

**The scripts:**

- **FR5 — `./capture <draft> <top|above:<row-id>|below:<row-id>> [--ranking <file>]`.** It mints
  the id as `max(items on disk) + 1`, corrects `next_id` to match, writes the draft as
  `items/<id>-<slug>.md` with that id and an `ac_digest:` computed as `./next --ac-digest` computes
  it, inserts the row at the given rank, and appends `--ranking`'s text to `RANKING.md`. One commit,
  and the new id is printed last. The rank form reuses `./reopen`'s.
- **FR6 — `./park <entry> [--repo <checkout>]`.** Appends one dated entry to `FINDINGS.md` in the
  head-token shape the buffer's header specifies, to this backlog or to the backlog of the named
  checkout, and commits it in that repo. Where the destination is a public repo per its `CLAUDE.md`
  profile, it runs the privacy guard `0118` names and refuses an entry that fails it, writing nothing.
- **FR7 — `./rank <id> <top|above:<row-id>|below:<row-id>> [--ranking <file>]`.** Moves one row,
  appends the reasoning, and commits. It refuses to move a row `in-progress` under any token
  (`queue` Step 4).
- **FR8 — `./withdraw <id> <reason> [--into <absorbing-id>]`.** Sets `status: withdrawn`, empties
  `next:`, appends the dated reason to *Notes & decisions*, removes the row, and re-points every
  open item's `blocked_by:` naming `<id>` to `--into` (or removes it where there is no `--into`). It
  never touches `next_id` and never deletes the item file. It refuses a claimed item.
- **FR9 — `./capture --restamp <id>`**, the Re-specify and Amend path. Re-stamps `ac_digest:` on an
  existing unclaimed item from its current criteria and commits. It refuses a claimed item.
- **FR10 — `./drain <date> <disposition> [<row-id>]`**, where disposition is `removed`,
  `marked:<row-id>` or `held`. It acts on exactly the entry `./next`'s findings listing (`0227`)
  names for that date and head: it removes it, marks it in place, or moves it to `FINDINGS-HELD.md`,
  then commits. It refuses an entry the listing does not name, so no drain matches the header's
  example by hand again.

**The skills:**

- **FR11** — `queue`, `retro`, `develop`, `verify`, `design`, `prototype` and `sprint` call these
  scripts at every write site above, and each by-hand lock sequence a script now covers is removed,
  `develop` Step 1's claim fallback included. `references/CONCURRENCY.md`'s by-hand-lock guidance
  remains only for a write site still without a script, and says which those are.
- **FR12** — `CHANGELOG.md` `## Unreleased` gains one entry per script, naming the stage steps that
  now call it.
- FR13 *(was 0215 FR1)* — `claim`'s seeder and `next`'s `fm_list` read `expects:` through one definition, so for any
  item both report the same path list.
- FR14 *(was 0215 FR2)* — A scalar comma-separated `expects:` or `touches:` is either parsed as its paths by that one
  definition, or reported by `./next --drift` by item id and field; never read silently as empty.
  Which of the two is `develop`'s choice, recorded in *Notes & decisions*.
- FR15 *(was 0215 FR3)* — `templates/item.md` gives `expects:` and `touches:` a ONE-form note in the shape `blocked_by:`'s.
- FR16 *(was 0225 FR1)* — When an item's frontmatter has no `touches:` key, `claim` adds one, whether or not it seeds
  entries: with the seeded entries when it seeds, empty when it does not (no `expects:`, or a
  non-develop stage).
- FR17 *(was 0225 FR2)* — A populated `touches:` is still left exactly as it is (0106's rule is unchanged).
- FR18 *(was 0225 FR3)* — The added key is reported through the existing backfill note, not a new message.
- FR19 *(was 0155 FR1)* — `claim`'s exclusive detector matches only an entry that is exactly `"*"` or `*`, in both copies.
- FR20 *(was 0155 FR2)* — `next` does not print TAKE for an exclusive-claim row while another row is held.
- FR21 *(was 0155 FR3)* — `./claim <id>` reports a collision between the row's `expects:` and every held row's `touches:` (or predicted set, per `CONCURRENCY.md`) before granting.
- FR22 *(was 0155 FR4)* — `./next --drift` reports an open row whose `expects:` names a path that does not exist and matches no glob.
- FR23 *(was 0155 FR5)* — the usage paragraph names the collision test rather than its ordinal.
- FR24 *(was 0066 FR1)* — `claim`'s success message is stage-aware: it asks for `touches:` where the stage opens a
  file scope and does not where it does not.
- FR25 *(was 0066 FR2)* — Where a claim legitimately holds no `touches:`, `./next`'s claimed-files block distinguishes
  that from an undeclared one, so a correct `verify` claim does not read as an under-specified
  `develop` one.
- FR26 *(was 0066 FR3)* — `./claim --help` and `./close --help` print usage and exit zero, matching `./next --help`.
- FR27 *(was 0066 FR4)* — Bare `./next` prints the topmost **takeable** row alongside row 1 whenever the two differ,
  since that is the question the reader is actually asking.
- FR28 *(was 0066 FR5)* — The three installed copies under `.claude/backlog/` are updated from the templates in the
  same change, per `tests/backlog-scripts-installed.test.sh` AC31.
- FR29 *(was 0066 FR6)* — `./claim <id> --touches <paths>` writes `touches:` into the item and its `QUEUE.md` row
  inside the same lock and commit as the claim itself, taking exactly the paths the session names
  on the command line — **never defaulting to or deriving from `expects:`**, since `queue` writes
  `expects:` predicted and `develop` writes `touches:` actual, and the two must never be copied
  from one another.
- FR30 *(was 0066 FR7)* — Bare `./next`'s report on a non-takeable row 1 states the blocking reason inline — the
  `## Waiting on` question for a `waiting` row, or the `blocked_by` id for a `blocked` one — not
  just the status word, so a session is not sent back to `QUEUE.md` or the item to find out why.
  The same class of defect as FR27: a warning that requires a second read to act on.
- FR31 *(was 0229 FR1)* — `./next --drift` also reads every `items/*.md` whose `status:` is `done`, `withdrawn` or
  `rejected`, and for each one with a non-empty `claimed_by:` prints one line,
  `DRIFT     <id> | status <status>, item claimed_by: <token> — a closed item keeps its token; clear claimed_by:`,
  counting as drift (non-zero exit) like every other class.
- FR32 *(was 0229 FR2)* — A closed item with an empty `claimed_by:` is not reported, and nothing about how an
  **open** item's token is judged changes.
- FR33 *(was 0229 FR3)* — `./next --help`'s `--drift` line names the new class alongside the existing ones.
- FR34 *(was 0230 FR1)* — When the queue holds no rows, the `ROW 1:` line reads exactly
  `ROW 1:     none — the queue holds no rows`.
- FR35 *(was 0230 FR2)* — When it holds at least one row, the line is unchanged.
- FR36 *(was 0227 FR1)* — The shipped `skills/queue/templates/next` gains a mode that prints every findings entry, one
  line each, as `<buffer path>:<line number>` followed by the entry's first line, for every buffer
  `--findings` counts. Mode name is the builder's choice; `--findings-list` is the recommendation.
- FR37 *(was 0227 FR2)* — That mode decides what is an entry with the **same awk program** `count_findings` uses — one
  function both modes call, not a second parser — so the listing and the count can never disagree. A
  line `count_findings` reports as `MALFORMED` is listed as such, not dropped.
- FR38 *(was 0227 FR3)* — `.claude/backlog/next` is re-copied from the template so the two stay byte-equal, as
  `tests/backlog-scripts-installed.test.sh` already requires.
- FR39 *(was 0227 FR4)* — `skills/retro/SKILL.md` Step 4 and `skills/queue/SKILL.md` Step 5 name FR36's mode as how a
  sweeper enumerates the entries it will remove, in place of matching the header's pattern by hand.
- FR40 *(was 0227 FR5)* — `tests/next.test.sh` carries cases over a fixture buffer the test builds: a preamble holding
  a fenced example line that matches the reader regex, the `---` rule, and two entries, one of them
  `[->NNNN]`-marked.
- FR41 *(was 0156 FR1)* — after `./handoff <id> <token> develop` on an item whose `blocked_by` names an open ticket, the row and item carry `blocked`, written as the derived cache rather than authored, and `--drift` is silent for that row.
- FR42 *(was 0235 FR1)* — `claim`, `handoff` and `close` refuse (or warn, per the decision) when run off the shared
  branch, naming both branches.
- FR43 *(was 0235 FR2)* — `references/CONCURRENCY.md` states the rule beside *A second checkout never writes the backlog*.
- FR44 *(was 0237 FR1)* — An open row at `next: verify` can be moved to `next: design` by one script call that writes
  the item and its `QUEUE.md` row in one locked commit.
- FR45 *(was 0237 FR2)* — `queue` Step 1 names the operation and when it applies (the user reopens a decision).
- FR46 *(was 0236 FR1)* — Whichever is chosen is stated in `references/CONCURRENCY.md` and in the skill it binds
  (`design` Step 4 or `queue` Step 2), and the other skill does not contradict it.
- FR47 *(was 0118 FR1)* — the step in which `queue` commits a parked finding names the privacy guard and requires it
  to have run over the paths being committed.
- FR48 *(was 0118 FR2)* — `retro` Step 6 does the same for its own park, which is committed by pathspec in the same
  turn it is written.
- FR49 *(was 0118 FR3)* — the requirement names the command, not the concept, so a session can run it without
  deriving which guard is meant.


## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | A script that writes into a public repo's buffer screens the entry first and refuses rather than writes (FR6) | AC8: an entry carrying a home path is written | `security-conventions.md` |
| Privacy & data | No entry with a real home path reaches a public repo's `FINDINGS.md` through `./park`; company material has no mechanical detector and stays the session's judgement, as now | AC8 | `data-privacy-conventions.md` |
| Performance | The queue and retro sessions after release take no by-hand lock: `classify-turns.sh`'s `LOCK` column reads 0.0% for both stages over the first 10 such sessions, re-measured by 2027-01-31 | Observation after release, recorded in *Notes & decisions*; not a close condition | `measurement-conventions.md` |
| Migration / schema | A backlog scaffolded before this release gains the five scripts at its next `queue` Step 0 and keeps every file it owns untouched | AC15: an old-shape fixture backlog after the sync | `migration-conventions.md` |
| Documentation | Each script's usage line is its header comment and its `usage:` refusal, and the skills name the script rather than restating its steps | AC16, a reading | `documentation-conventions.md` |
| Testing | (0225) FR16 starts as a failing test that runs `claim` then `handoff` on an item with neither `expects:` nor `touches:`. *Red when:* the key is not added and `handoff` refuses. | FR16's failing case: `claim` then `handoff` on an item with neither key reds when the key is not added | `testing-conventions.md` |
| Testing | (0155) Each FR has a fixture case, and the template copies are what the cases exercise. | `backlog-scripts-installed` reds on a single-copy edit. | `testing-conventions.md` |
| Documentation | (0066) FR26's usage text documents every mode each script has, as `./next --help` already does | AC33: drop a mode from either script's usage text | `documentation-conventions.md` |
| Progressive delivery | (0066) The scripts ship to every machine installing the plugin; the release is the version bump and the install | AC36: edit one installed copy so it differs from its template | `progressive-delivery-conventions.md` |
| Correctness | (0066) FR29's `touches:` write happens inside the same lock and commit as the claim — no separate, unlocked follow-up write | `CONCURRENCY.md`, *A claim must be durable the moment it is made* |
| Documentation | (0229) `--help` names the class a session will now see | AC44's assertion on the `--drift` usage text | `documentation-conventions.md` |
| Testing | (0227) FR40's cases are proven red against `next` before FR36 lands, and again under a mutation of the shared awk program. | Delete the `!body && /^---$/` rule from the shared program: AC47 lists three entries, not two. | `testing-conventions.md` |
| Testing | (0156) The case runs the real hand-off then `--drift`, in fixture. | Two separately-built fixtures that never meet. | `testing-conventions.md` |
| Privacy & data | (0118) The rule being enforced is `CLAUDE.md`'s public-repo constraint; cite it, do not restate it | AC55: a tracked file carrying a real home path, run through the named command, is not refused | `data-privacy-conventions.md` |
| Documentation | (0118) Both skills state the same requirement once each, in their own voice | prose only — no artifact yet | `documentation-conventions.md` |

## Acceptance criteria

Each scripted AC names its test file. Each fixture is a scratch git repo the test builds, so no AC
reads the live backlog.

- [ ] AC1 — Given a fixture backlog whose `next_id` is 5 while `items/` holds 0007, when `./capture
  draft.md above:0003` runs, then it writes `items/0008-*.md` carrying id `0008`, sets `next_id: 9`,
  inserts the row directly above 0003, and makes one commit. Red: mint from `next_id`.
  (`tests/capture.test.sh`)
- [ ] AC2 — Given AC1's capture, when `./next --ac-digest 0008` runs afterwards, then its output
  equals the item's `ac_digest:` line. Red: stamp the digest before the id is written.
  (`tests/capture.test.sh`)
- [ ] AC3 — Given a draft with no `- [ ] AC1 —` line, when `./capture` runs, then it exits non-zero,
  writes no file, leaves `QUEUE.md` and `config.yml` byte-identical, leaves no `.lock`, and makes no
  commit. Red: skip the draft check. (`tests/capture.test.sh`)
- [ ] AC4 — Given another path staged before `./capture` runs, when it commits, then that path is
  absent from the capture commit and still staged afterwards. Red: commit without a pathspec.
  (`tests/capture.test.sh`)
- [ ] AC5 — Given `above:9999`, a row not in the queue, when `./capture` runs, then it refuses before
  minting, leaves no `.lock` and changes no file. Red: append at the bottom on a missing anchor.
  (`tests/capture.test.sh`)
- [ ] AC6 — Given a fixture buffer, when `./park "what happened"` runs, then exactly one line is
  appended in the header's head-token shape with today's UTC date, and one commit names only
  `FINDINGS.md`. Red: write the entry without its date. (`tests/park.test.sh`)
- [ ] AC7 — Given `--repo <second fixture checkout>`, when `./park` runs, then the entry and its
  commit land in the second repo and the first repo is unchanged. Red: ignore `--repo`.
  (`tests/park.test.sh`)
- [ ] AC8 — Given a second checkout whose `CLAUDE.md` profile marks it public, when `./park` is given
  an entry holding a real-shaped macOS or Linux home path (assembled in the test, never written
  literally), then it exits non-zero, writes
  nothing and names the failing shape; the same entry with the path redacted is written. Red: skip
  the guard. (`tests/park.test.sh`)
- [ ] AC9 — Given rows A, B, C, when `./rank C above:A` runs, then the order is C, A, B with every
  other line of `QUEUE.md` unchanged, and one commit. Red: re-sort the table. (`tests/rank.test.sh`)
- [ ] AC10 — Given B `in-progress` under a token, when `./rank B top` runs, then it refuses and
  changes nothing. Red: drop the claim check. (`tests/rank.test.sh`)
- [ ] AC11 — Given 0004 named in 0005's `blocked_by:`, when `./withdraw 0004 "merged" --into 0006`
  runs, then 0004's file stays with `status: withdrawn`, an empty `next:` and a dated note; its row is
  gone; 0005's `blocked_by:` names 0006; and `next_id` is unchanged. Red: delete the item file, or
  leave 0005 pointing at 0004. (`tests/withdraw.test.sh`)
- [ ] AC12 — Given an unclaimed item whose AC2 text was edited, when `./capture --restamp <id>` runs,
  then `./next --drift` reports no digest mismatch for it. Red: restamp from the old digest.
  (`tests/capture.test.sh`)
- [ ] AC13 — Given a buffer whose header carries the fenced example `- 2026-09-05 [->0060] — …` and
  one real entry dated 2026-09-05, when `./drain 2026-09-05 removed` runs, then only the real entry is
  removed and the header is byte-identical. Red: match the date by regex over the whole file.
  (`tests/drain.test.sh`)
- [ ] AC14 — Given a real entry, when `./drain <date> held` runs, then the entry is absent from
  `FINDINGS.md`, present verbatim in `FINDINGS-HELD.md`, and both changes are in one commit. Red: write
  the held file without removing the entry. (`tests/drain.test.sh`)
- [ ] AC15 — Given a fixture backlog holding only the five pre-existing scripts, when `queue` Step 0's
  sync runs, then all ten scripts are present and byte-equal to `templates/`, and `config.yml`,
  `QUEUE.md` and `FINDINGS.md` are byte-identical. Red: omit one new script from the sync list.
  (`tests/backlog-scripts-installed.test.sh`)
- [ ] AC16 — Given the seven skills and `references/CONCURRENCY.md`, when every write site in FR11 is
  read, then each calls its script, no covered by-hand lock sequence remains, and `CONCURRENCY.md` names
  the write sites still without one. A reading, not a grep (`CLAUDE.md`, *Tests*). Red: any covered
  site still describing `mkdir .lock`.
- [ ] AC17 — Given `CHANGELOG.md`, when `## Unreleased` is read, then one entry per new script names
  the stage steps that call it. A reading. Red: a script with no entry.
- [ ] AC18 *(was 0215 AC1)* — Given an item whose `expects:` is an inline `["a", "b"]` list, `./claim <id>` seeds
  `touches:` with `a` and `b`, asserted in `tests/claim.test.sh`.
- [ ] AC19 *(was 0215 AC2)* — Given the same item in block form and in inline form, `./next develop`'s EXPECTS line and
  `./claim`'s seeded `touches:` name the same paths, asserted in one test over both forms.
- [ ] AC20 *(was 0215 AC3)* — Given an item whose `expects:` is `a.ts, b.ts`, either `./next develop` prints both paths or
  `./next --drift` names that item and `expects:`; `EXPECTS not predicted` is not printed for it.
  Asserted in `tests/next.test.sh`.
- [ ] AC21 *(was 0215 AC4)* — `templates/item.md`'s `expects:` comment states one written form.
- [ ] AC22 *(was 0225 AC1)* — Given an item with no `expects:` and no `touches:` key, when `./claim <id>` runs, then the
      item's frontmatter carries a `touches:` key with no entries and `./handoff <id> <token> design`
      succeeds without a hand edit. *Red when:* `handoff` prints `has no: touches`.
- [ ] AC23 *(was 0225 AC2)* — Given an item with `expects:` entries and no `touches:` key, claimed at `develop`, then
      `touches:` holds those entries exactly once. *Red when:* the key is duplicated or empty.
- [ ] AC24 *(was 0225 AC3)* — Given an item whose `touches:` already has entries, `claim` leaves them byte-identical.
      *Red when:* any entry is added, removed or reordered.
- [ ] AC25 *(was 0155 AC1)* — Given a fixture item with `expects:` `- tests/*.test.sh` and another row held, when `./claim` runs, then it is not refused as exclusive. Red-making input: today's detector.
- [ ] AC26 *(was 0155 AC2)* — Given a takeable row with `expects: "*"` and another row held, when `./next develop` runs, then that row is not printed as TAKE. Red-making input: today's take loop.
- [ ] AC27 *(was 0155 AC3)* — Given a held row touching `a.md` and a ready row expecting `a.md`, when `./claim <ready id>` runs, then the output names the collision and the holder. Red-making input: today's claim.
- [ ] AC28 *(was 0155 AC4)* — Given an open row expecting a path that does not exist, when `./next --drift` runs, then that id and path are reported and the exit is non-zero. Red-making input: today's drift.
- [ ] AC29 *(was 0155 AC5)* — Given `./next --help`, when it runs, then the output contains no ordinal naming the collision test. Red-making input: the word `third` in today's usage.
- [ ] AC30 *(was 0066 AC1)* — Given a claim on a `next: verify` row, when `./claim` succeeds, then its message does
  not instruct the session to set `touches:`.
- [ ] AC31 *(was 0066 AC2)* — Given a claim on a `next: develop` row, when `./claim` succeeds, then its message does
  instruct the session to set `touches:`.
- [ ] AC32 *(was 0066 AC3)* — Given an `in-progress` row claimed at a stage that holds no file scope, when `./next`
  runs, then its claimed-files block says so rather than `none declared — assume held, ask`.
- [ ] AC33 *(was 0066 AC4)* — Given `./claim --help` and `./close --help`, when each is run, then it prints usage and
  exits zero.
- [ ] AC34 *(was 0066 AC5)* — Given a queue whose row 1 is `waiting` and whose topmost takeable row is lower, when
  bare `./next` runs, then it prints both and marks which is takeable.
- [ ] AC35 *(was 0066 AC6)* — Given a queue whose row 1 **is** the topmost takeable row, when bare `./next` runs,
  then it does not print the row twice.
- [ ] AC36 *(was 0066 AC7)* — Given `.claude/backlog/{claim,close,next}` compared against the templates, when
  `tests/backlog-scripts-installed.test.sh` runs, then it passes.
- [ ] AC37 *(was 0066 AC8)* — Given the whole suite, when it runs, then every suite passes.
- [ ] AC38 *(was 0066 AC9)* — Given `./claim <id> --touches path/a path/b`, when it succeeds, then the item's
  `touches:` and the `QUEUE.md` row reflect exactly `path/a` and `path/b`, written in the same
  commit as the claim.
- [ ] AC39 *(was 0066 AC10)* — Given `./claim <id> --touches <paths>` on an item whose `expects:` names different
  paths, when it succeeds, then `touches:` holds only the paths given on the command line — never
  `expects:`'s paths.
- [ ] AC40 *(was 0066 AC11)* — Given a queue whose row 1 is `waiting` or `blocked`, when bare `./next` runs, then its
  report names the blocking reason (the waiting question, or the `blocked_by` id) inline, not just
  the status word.
- [ ] AC41 *(was 0229 AC1)* — Given a fixture whose `items/` holds a `status: done` item with `claimed_by: "ab12"` and no `QUEUE.md` row, when `./next --drift` runs, then it exits non-zero and prints one DRIFT line naming that id, `done` and `ab12` — `tests/next.test.sh`
- [ ] AC42 *(was 0229 AC2)* — Given the same item at `status: withdrawn`, and again at `status: rejected`, when `./next --drift` runs, then each is reported the same way — `tests/next.test.sh`
- [ ] AC43 *(was 0229 AC3)* — Given a `status: done` item with an empty `claimed_by:` and no other drift, when `./next --drift` runs, then it prints no DRIFT line and exits 0 — `tests/next.test.sh`
- [ ] AC44 *(was 0229 AC4)* — Given the template, when `./next --help` runs, then its `--drift` line names a closed item keeping a token — `tests/next.test.sh`
- [ ] AC45 *(was 0230 AC1)* — Given a fixture whose `QUEUE.md` holds the header and table header and no rows, when bare `./next` runs, then its `ROW 1:` line is exactly `ROW 1:     none — the queue holds no rows` — `tests/next.test.sh`
- [ ] AC46 *(was 0230 AC2)* — Given a fixture with one row `0001 | Fixture row | develop | ready`, when bare `./next` runs, then its `ROW 1:` line is `ROW 1:     0001 | Fixture row | develop | ready` — `tests/next.test.sh`
- [ ] AC47 *(was 0227 AC1)* — Given FR40's fixture, when FR36's mode runs, then it prints exactly two lines, naming the
      two entries' line numbers and neither preamble line. *Red:* remove the preamble-skip rule from
      the shared program; the fenced example is listed as a third line (`tests/next.test.sh`).
- [ ] AC48 *(was 0227 AC2)* — Given the same fixture, when `./next --findings` runs, then its count equals AC47's line
      count, read from one fixture in one case. *Red:* give the listing its own copy of the program
      without the preamble rule; the count says 2 and the listing 3 (`tests/next.test.sh`).
- [ ] AC49 *(was 0227 AC3)* — Given a fixture whose body holds a `- ` line with no date, when FR36's mode runs, then
      that line is printed marked `MALFORMED`, with its line number. *Red:* drop the MALFORMED
      branch from the listing path (`tests/next.test.sh`).
- [ ] AC50 *(was 0227 AC4)* — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then
      it passes. *Red:* add FR36 to the template only.
- [ ] AC51 *(was 0227 AC5)* — `for t in tests/*.test.sh; do "$t" || exit 1; done` green.
- [ ] AC52 *(was 0156 AC1)* — Given a held fixture item whose `blocked_by` names an open ticket, when `./handoff` runs and then `./next --drift`, then drift reports nothing for that row and `--drive` does not escalate on it. Red-making input: today's handoff.
- [ ] AC53 *(was 0118 AC1)* — given `skills/queue/SKILL.md`, when grepped for the privacy guard's command, then it
  appears in the step that commits a park; red by deleting that sentence.
- [ ] AC54 *(was 0118 AC2)* — the same for `skills/retro/SKILL.md` Step 6.
- [ ] AC55 *(was 0118 AC3)* — given a tracked file carrying a real home path, when the named command is run as the
  skills instruct, then it exits non-zero and names the file — the control that the instruction
  points at a check that actually fires.


## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [x] S1 — `claim` and `next` read `expects:` and `touches:` through one parser, agree on what blocks a take, and `claim` writes an empty `touches:` key when it seeds nothing (0215, 0225, 0155) — discharges AC18, AC19, AC20, AC21, AC22, AC23, AC24, AC25, AC26, AC27, AC29
- [ ] S2 — the three places the scripts answer the wrong question (0066) — discharges AC30, AC31, AC32, AC33, AC34, AC35, AC36, AC37, AC38, AC39, AC40
- [ ] S3 — `next` reports a closed item still carrying a token, says an empty queue is empty, and lists the findings entries (0229, 0230, 0227) — discharges AC41, AC42, AC43, AC44, AC45, AC46, AC47, AC48, AC49, AC50, AC51
- [ ] S4 — `handoff` records a blocker without leaving drift that stops a driver (0156) — discharges AC52
- [ ] S5 — a note written below the last AC no longer changes that AC's digest (0217) — unspecified
- [ ] S6 — `reopen` of a develop self-close leaves a ticket verify can close (0219) — unspecified
- [ ] S7 — decide whether `claim`, `handoff` and `close` refuse off the branch the backlog is shared on (0235) — unspecified
- [ ] S8 — `./capture` with its restamp form, the shared lock, commit and refusal behaviour, and its install — discharges AC1, AC2, AC3, AC4, AC5, AC12, AC15
- [ ] S9 — `./park`, with the public-repo screen — discharges AC6, AC7, AC8
- [ ] S10 — `./rank` and `./withdraw` — discharges AC9, AC10, AC11
- [ ] S11 — `./drain`, on `0227`'s listing — discharges AC13, AC14
- [ ] S12 — `queue` can send an open verify ticket back to design (0237) — unspecified
- [ ] S13 — decide whether design may amend unheld sibling items its own FRs name (0236) — unspecified
- [ ] S14 — the seven skills, `CONCURRENCY.md` and the CHANGELOG move onto the scripts, and every step that commits a sweep runs the privacy guard (0118) — discharges AC16, AC17, AC53, AC54, AC55
- [ ] S15 — FR22 and AC28, `--drift` reporting an `expects:` path that exists nowhere: decide whether `--drive` gates on it (0142 FR3) and whether a path commented `# new` is exempt (0155) — unspecified


## QA plan

- **Why that level:** every script is behaviour over a fixture git repo, which is how
  `tests/claim.test.sh`, `tests/close.test.sh` and `tests/handoff.test.sh` already test their
  scripts. S5 is prose, and per `CLAUDE.md` it is read rather than grepped.
- **Specific checks:** each named test file, applying each AC's mutation once. The whole suite,
  file by file (`commands.unit_by_file`), because these scripts sit under every stage.

### From 0225

- **Level:** unit
- **Why this level:** both scripts are shell over a fixture item; `tests/claim.test.sh` already builds
  such fixtures.
- **Specific checks:** the repo's `unit` command.

### From 0155

- **Why that level:** `unit` — every requirement is a case over scaffolded fixture backlogs in the existing suites.
- **Specific checks:** `tests/claim.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`, each mutated in the template copy.

### From 0066

- **Level:** unit — the deliverables are three shell scripts, and this project's `unit` command runs
  every `tests/*.test.sh`.
- **Why this level:** every AC is a fixture plus one invocation, which the three suites already do.
- **Specific checks:** `tests/claim.test.sh`, `tests/close.test.sh`, `tests/next.test.sh`, then the
  full suite. Exercise the write-scripts against a **clone in the scratchpad**, never a live row in
  the shared table. Confirm each mutation reached the file the harness runs — `tests/next.test.sh`
  resolves its subject through `NEXT_SRC` — since mutating the backlog's own copy instead returns a
  clean pass, which is what a check that cannot fail also returns. `tests/claim.test.sh` gains
  `--touches` cases: multiple paths, no flag (unchanged behavior), and a run against an item whose
  `expects:` differs, to prove FR29 never copies from it.

### From 0229

- **Why that level:** the change is one script's behaviour against fixtures; the suite already
  drives `--drift` this way.
- **Specific checks:** `tests/next.test.sh`, then the whole `unit` command, since `--drive` runs
  the same drift check before it picks a gate.

### From 0230

- **Why that level:** one script's output against a fixture.
- **Specific checks:** `tests/next.test.sh`, then the whole `unit` command.

### From 0156

- **Why that level:** `unit` — fixture cases in the handoff and next suites.
- **Specific checks:** `tests/handoff.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`.

### From 0118

- **Why that level:** prose assertions plus one live run of the guard; no runner above unit applies.
- **Specific checks:** `tests/findings-routing.test.sh`, and a scratch tracked file carrying a real
  path to prove AC55 reddens, removed in the same turn.


## Out of scope

- Choosing a rank, a disposition or a destination for the session. The scripts take each one as an
  argument (see *What stays out of the scripts*).
- A GitHub Issues backend or mirror (reviewed 2026-11-26 and not recommended; see the conversation
  record in *Notes & decisions*).
- `runs/` and `LEDGER.md` writes, which `tools/sprint-ledger.sh` already owns.

### From 0225

- Relaxing `handoff`'s refusal — a missing key is still a malformed item; the fix is that `claim` stops
  producing one.
- 0215's comma-form parser.

### From 0155

- Whether an empty `touches:` is held, which is 0145's decision; FR21 follows whatever it settles.

### From 0066

- **`./next`'s take loop consulting the held file set.** That is 0045, which explicitly parks FR27's
  readability defect as out of its own scope; the two touch `next` and want sequencing rather than
  merging.
- The frontmatter readers' comment and list handling, which is 0044.
- Adding modes to any script beyond FR29's `--touches`.
- **`--touches` validating that the named paths exist, or that they match the ticket's `expects:`.**
  The flag records what the session declares, not what it verifies — matching `expects:`'s own
  "triage, not protection" role in the queue skill.

### From 0229

- Clearing AetherWorks' 21 tokens. That is AetherWorks' data and its own one-line fix once this
  check names them; it is not provable from this repo.
- Changing `close`, `handoff` or `reopen`, which already clear the field.
- Rewording `skills/develop/SKILL.md`'s warning; it stays true.

### From 0230

- The `--drive` and `<stage>` modes, which already say when nothing is takeable.

### From 0227

- Editing the template's fenced example line — that is 0213, withdrawn, and stays withdrawn.
- Rewriting project copies of the header in other repos.
- A new prose guard over FR39's skill wording: the 2026-10-27 triage stopped adding them, and the
  mechanism FR39 points at is asserted by AC47–AC49.
- Changing what `--findings` counts or how `--drive` gates on it.

### From 0156

- Rewriting the drift class list beyond this one reconciliation.

### From 0118

Whether a *mention of the rule* is exempt from the guard, and the company and product names still
in item prose — that is a separate decision and has its own deferred finding. Widening the guard's
pattern at all.


## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

### Leg S1 — verify `45e7`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `b21893b` (the claim commit over `cf43f99`; S1 code at `718a756`).
Copy executed: the repo templates (`tests/claim.test.sh` and `tests/next.test.sh` run
`skills/queue/templates/{claim,next}`); the session's skills came from the 0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last mutation: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.

**Whole suite:** 45 files, every one rc=0. Tallies pasted: `tests/claim.test.sh` `148 passed, 0 failed`;
`tests/next.test.sh` `735 passed, 0 failed`; `tests/backlog-scripts-installed.test.sh`
`55 passed, 0 failed`; `tests/declared-copies.test.sh` `declared-copies: 23 passed, 0 failed`;
`tests/handoff.test.sh` `250 passed, 0 failed`; `tests/close.test.sh` `322 passed, 0 failed`.

**Clause table, and the mutation that reddened each row.** Every mutation was applied to the
template the harness runs, its diff confirmed non-empty, then restored with `git checkout --` on that
path alone; `git status --porcelain` was empty after every restore.

| AC | Clause (Given / predicate / object) | Mutation in `skills/queue/templates/…` | Result |
|---|---|---|---|
| AC18 | Given inline `["a", "b"]` / `./claim` seeds `touches:` / `a` and `b` | `claim` fm-list inline branch → `exit` (M1); seed loop in the existing-key branch keeps only entry 1 (M2b) | red: `touches: holds a and b` (both) |
| AC19 | Given block **and** inline forms / EXPECTS and seeded `touches:` / the same paths (two paths per fixture) | M1; M2b; `claim` scalar branch dropped (M3b) | red: `claim seeds the paths next printed` on each form |
| AC20 | Given `a.ts, b.ts` / `./next develop` prints both, and not `EXPECTS not predicted` | `next` fm-list scalar branch dropped (M3) | red: `EXPECTS names both paths`, `is not read as unpredicted` |
| AC21 | `templates/item.md`'s `expects:` comment / one written form | reading | holds: "ONE form: a `- ` block, one path per line" |
| AC22 | Given no `expects:` and no `touches:` / claim writes an empty key / `./handoff … design` succeeds | key added only under `!tou && n && seed` (M4) | red: empty key, backfill note, handoff rc, `has no: touches` (4 FAIL) |
| AC23 | Given entries and no key, at develop / `touches:` holds them / exactly once | key printed twice (M5); no-key seed keeps only entry 1 (M2) | red: `touches: holds the entries once`, `one touches: key` |
| AC24 | Given a populated `touches:` / claim leaves it / byte-identical | `existing_touches=""` (M6) | red: `touches: is unchanged` plus five 0106 cases |
| AC25 | Given `- tests/*.test.sh` and another row held / not refused as exclusive | detector back to any `*` (M7) | red: rc, `is not refused as exclusive`, glob kept |
| AC26 | Given a takeable `"*"` row and another row held / `./next develop` / not TAKE | hold-back block `if false` (M8) | red: `0302 is not printed as TAKE`, holder named, walk continues |
| AC27 | Given a held row touching a path and a ready row expecting it / `./claim` output / names the collision and the holder | report suppressed (M9) | red: `names the collision, the path and the holder` |
| AC29 | `./next --help` / contains no ordinal for the collision test | usage restored to `that third test` (M10) | red: `no ordinal: that third test` |

**Mutations that stayed green, published, not covered:** both are FR21 qualifiers that AC27 does not
name, so neither leaves AC27 unverified. (M9b) Removing the `expects (predicted)` fallback for a held
row with an empty `touches:` kept `148 passed, 0 failed`: the holder fixture's `touches:` equals its
`expects:`. (M9c) Comparing only the first held row (`break` after the first collision) also kept
`148 passed, 0 failed`: every AC27 fixture holds one row. FR21's "every held row's `touches:` (or
predicted set)" is unguarded on both counts. Also not run here (develop recorded it as reasoned only):
whether `--drive`'s gate walk offers a `"*"` row while another is held. AC26 names `./next develop`
alone.

**NFR rows bearing on S1.** Testing (0225): FR16's claim-then-handoff case reds under M4, guarded.
Testing (0155): the cases run the template copies (`CLAIM_SRC`, `NEXT_SRC`). Appending a line to
`.tickets/claim` alone reddened `tests/backlog-scripts-installed.test.sh` (`54 passed, 1 failed`,
`claim has diverged from skills/queue/templates/claim`), guarded. Every S1 FR has a fixture case
except FR22, which moved out. Correctness (0066) and the other rows belong to later legs. Always-on:
nothing in this diff adds a log field, analytics event or egress, and its commits carry the trailer.

**FR22/AC28 → S15 (`bbd3531`): sound.** `templates/item.md` (*Ticked slices are history*) and
`develop` let an unticked slice be re-split with a dated note so long as no AC changes. The note is
present and AC28's digest still matches. The reason was checked. `tests/next.test.sh`'s *0142 FR3*
case asserts that `--drive` and `--drift` print identical DRIFT lines, and its fixture's `expects:`
paths (`a/one.md`, `b/two.md`) do not exist. So putting the class in `--drift` alone reds that
closed contract (0142 `done`), and putting it in the shared check makes `--drive` escalate on
fixtures like it. `claim`'s 0147 FR2 header calls declaring a file you are about to write *"the
common and correct case"*. That is a genuine contract conflict, not missing detail, so it is
`design`'s. One residual: S15 names AC28 but, being `unspecified`, does not yet discharge it, so the
design pass that sharpens S15 must name AC28 as discharged there.

### Leg S2 — verify `357a`, 2026-11-27 (sprint run-20261127T024025Z) — FAIL on AC30, no AC or slice ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `8f28d7c` (the claim commit over `f05f35f`; S2 code at `3a7e008` and `cbda31d`).
Copy executed: the repo templates (`tests/{claim,close,next}.test.sh` run `skills/queue/templates/…`).
The session's skills came from the 0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.

**Whole suite:** 45 files, every one rc=0. Tallies pasted: `tests/claim.test.sh` `189 passed, 0 failed`;
`tests/next.test.sh` `752 passed, 0 failed`; `tests/close.test.sh` `330 passed, 0 failed`;
`tests/backlog-scripts-installed.test.sh` `55 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`; `tests/handoff.test.sh` `250 passed, 0 failed`.

**Clause table, and the mutation that reddened each row.** Mutations ran in scratch clones of
`8f28d7c`, never in the shared tree. Each substitution had to match exactly once (`mut.py` refuses
otherwise), the diff was confirmed non-empty, and the file was restored with `git checkout --` on that
path alone. Controls: `claim` `189 passed, 0 failed`, `close` `330 passed, 0 failed`. For `next`, the clone
control was `748 passed, 4 failed`, all in 0060 findings-gate cases that no S2 mutation touches
(see FINDINGS). So each `next` result below is that mutation's fail set minus the control's.

| AC | Clause | Mutation | Result |
|---|---|---|---|
| AC30 | Given a claim on a `next: verify` row / claim succeeds / message does not instruct setting `touches:` | non-build branch keeps `BUILDS` (MA1); SEED=0 branch prints `set it in` (MA2) | red: `no instruction to widen it`, `says verify holds no file scope`; `no instruction: set it in` |
| AC30 | the same Given, **with `--touches`** | none: probed directly | **FAIL**: see below |
| AC31 | Given a `next: develop` row / message instructs setting `touches:` | `NARROW it in` → `trim in` (MB1); `set it in $item` → `fill $item` (MB2) | red: `seeded: told to narrow it` (+3); `nothing to seed: told to set it` |
| AC32 | Given in-progress row at a no-file-scope stage / `./next` claimed-files block / says so, not `assume held, ask` | `declared_scope` stage case `*)` → `zzz)` | red: `says the stage holds no file scope`, `not the undeclared wording`, `and not told to assume it held`, `bare ./next says the same` |
| AC33 | `./claim --help` / usage, exit 0 | help `case` line → `:` (MC1) | red: `exits 0`, `-h exits 0 too` |
| AC33 | `./close --help` / usage, exit 0 | `-h\|--help)` → `--nope)` (MD1) | red: `close --help exits 0`, `close -h exits 0` |
| AC34 | Given row 1 waiting, takeable lower / prints both | `TAKEABLE:` label renamed (MN2) | red: `and the topmost takeable row is printed, marked`, `the takeable row is printed`, `the takeable row is the verify one` |
| AC34 | … / marks which is takeable | ` — not takeable:` mark dropped (MN6) | red: `ROW 1 says it is not takeable, with the question`, `names the blocking id`, `names the holder` |
| AC35 | Given row 1 takeable / not printed twice | `if [ -n "$row1_why" ]` → `if true` (MN3) | red: `no TAKEABLE line repeats it` |
| AC36 | installed copies vs templates | one byte in `.tickets/next`, `.tickets/claim`, `.tickets/close` each, separately | red each: `<name> has diverged from skills/queue/templates/<name>` (`54 passed, 1 failed`) |
| AC37 | whole suite | the run above | 45/45 rc=0 |
| AC38 | `--touches path/a path/b` / touches: exactly both / same commit | keep only the first path (ME1) | red: `touches: holds path/a and path/b`, `the report says the scope was declared`. *Same commit*: guarded by `one commit on top of the fixture`, `and carries both files` and `the tree is clean`. Reasoned, no mutation run. |
| AC39 | Given `expects:` differs / touches: only the given paths | `SEED_LIST="$EXPECTS_LIST $TOUCHES_ARGS"` (MG1) | red: `touches: holds only path/a` (both fixtures) |
| AC40 | Given row 1 **waiting** / names the question inline | question dropped (MN4) | red: `ROW 1 says it is not takeable, with the question` |
| AC40 | Given row 1 **blocked** / names the `blocked_by` id inline | id dropped (MN5) | red: `ROW 1 names the blocking id` |

**AC30 FAIL, the actual output.** Fixture: one `| 0300 | Up for QA | verify | ready |` row, item with
`expects: [src/alpha.ts]`. The template `claim` ran as `.tickets/claim 0300 tok0 --touches src/alpha.ts`:

```
claimed 0300 with token tok0
touches: is set from --touches (1 paths) — exactly the paths named, never expects:'s;
widen it in <fixture>/.tickets/items/0300-fixture.md the moment the work reaches further
rc=0
```

A successful claim on a `next: verify` row instructs the session to widen `touches:`. That is the
wording the leg's own 0261 case asserts a verify claim must not print (`no instruction to widen it`).
It also breaks FR24 ("does not where it does not").

**NFR rows bearing on S2.** Documentation (0066): AC33's usage text documents every mode. Dropping
`--touches` from the usage is not run separately, but MC1/MD1 redden the usage line. The
`documents --touches` / `documents --note` cases name the modes. Progressive delivery (0066): AC36's
mutation, red, guarded. Correctness (0066), FR29 inside the claim's lock and commit: the `--touches`
write is in the same awk pass as the claim, and the AC38 single-commit and clean-tree assertions
would red on a follow-up write. The row names no check of its own, so it rests on AC38. Always-on:
no log field, analytics event or egress is added. The commits carry the trailer, and nothing
company-specific was added.

## Notes & decisions

- **2026-11-26 (queue): AC8 example reworded, meaning unchanged.** Its literal home-path example
  reddened `tests/measurement.test.sh` ("a tracked file publishes a home-directory path") at
  `53ecb3a`. The example now names the shape in prose and says the test assembles the sample, as
  that guard's own falsification control does; the criterion, its red and its test are unchanged.
  `ac_digest` AC8 re-stamped.
- **2026-11-26 (queue): captured at the user's request.** The trigger is their instruction quoted in
  the Problem, which `CLAUDE.md`'s *Where toolkit work comes from* accepts in place of a confirming
  project. It also reverses 0048's withdrawal. 0048's id stays burned, and this ticket is its outcome.
- **Amend-first test.** No open ticket's outcome is "every write is a script". The closest are
  0227 (a listing, which S4 builds on) and 0118 (a guard, which S2 runs at the moment of writing).
  Both are named rather than absorbed until the consolidation is confirmed. Minted as a new outcome
  ticket with ordered slices, not five tickets, on the user's instruction to work a whole outcome
  together.
- **Routed to `develop`.** Each script's contract follows from the by-hand sequence it replaces,
  which the skills already specify step by step, and from the existing scripts' conventions. No
  decision is open.
- **GitHub Issues, reviewed 2026-11-26, not recommended as a backend.** It would not cut turns,
  since the scripts already make one call per boundary. It would lose the atomic claim (no
  compare-and-set on assignees, labels or bodies), native rank, and the file-based digest and drift
  checks. It would also need a standing token in the unattended loop. A one-way mirror on the
  `references/TRACKER.md` pattern remains open if visibility is wanted.
- **2026-11-26 (queue): merged by outcome, at the user's direction.** The 2026-11-26 consolidation grouped the backlog by outcome so a whole outcome is worked in one ticket and its context is paid for once. Absorbed and withdrawn, each id burned and each item file kept as the record:
  - `0215` (Make claim and next read expects and touches through one parser that refuses or accepts the comma form): FR13–FR15, AC18–AC21
  - `0225` (Make claim write an empty touches key when it has nothing to seed): FR16–FR18, AC22–AC24
  - `0155` (Make claim and next agree on what blocks a take): FR19–FR23, AC25–AC29
  - `0066` (Fix the three places the backlog scripts answer the wrong question): FR24–FR30, AC30–AC40
  - `0229` (Make next --drift report a closed item that still carries a claim token): FR31–FR33, AC41–AC44
  - `0230` (Make next say the queue is empty instead of printing a blank ROW 1): FR34–FR35, AC45–AC46
  - `0227` (Make next list the findings entries so no drain matches a buffer's header by hand): FR36–FR40, AC47–AC51
  - `0156` (Let handoff record a blocker without leaving drift that stops a driver): FR41–FR41, AC52–AC52
  - `0217` (Stop a note written below the last AC from changing that AC's digest): no FRs, no ACs (an unspecified slice)
  - `0219` (Make reopen leave a ticket that verify can close when it reopens a develop self-close): no FRs, no ACs (an unspecified slice)
  - `0235` (Decide whether claim, handoff and close refuse off the branch the backlog is shared on): FR42–FR43, no ACs (an unspecified slice)
  - `0237` (Give queue a way to send an open verify ticket back to design): FR44–FR45, no ACs (an unspecified slice)
  - `0236` (Decide whether design may amend unheld sibling items its own FRs name): FR46–FR46, no ACs (an unspecified slice)
  - `0118` (Run the privacy guard where a sweep commits, not only where a suite runs): FR47–FR49, AC53–AC55
  Each absorbed ticket's Problem is quoted verbatim above, and its FRs, ACs, NFR rows, QA plan, Out of scope and Notes are carried below with `*(was NNNN FRn)*` tags. **Bare FR and AC numbers inside the carried text were renumbered to this ticket's.** A reference to another ticket's criterion not written as `NNNN ACn` may have been renumbered too, and the withdrawn file holds the original. An unspecified slice sends this ticket to `design` when it is next; its open question is below.

### S1 build notes — 2026-11-27, develop `5b13` (sprint run-20261127T024025Z)

- **S1 built at `36138a7`, citation fix `718a756`.** FR13–FR21 and FR23, discharging AC18–AC27 and
  AC29. Whole suite green file by file after `718a756`.
- **FR14 — parsed, not reported.** A bare scalar `expects: a.ts, b.ts` (or `touches: "*"`) is read
  as its paths, split on commas and quotes, by the `fm-list` block. Chosen because a live item in
  this backlog, 0214, carries eight paths in that form and read as empty until now. Reporting it
  would have left 0214 unpredicted until someone rewrote it.
- **FR13 — one definition through the declared copy.** `claim` now carries the `fm-list` and
  `decomment` copy-blocks `next`, `close` and `reopen` already share, so
  `tests/declared-copies.test.sh` reds if any copy diverges. Its counts are re-anchored from 3 to 4
  and from 4 to 5. `claim` seeds `touches:` from `fm_list`'s output as normalised `  - <path>`
  lines. An `expects:` entry's own comment is no longer copied into `touches:`.
- **FR16** — the key is added whenever it is absent, with seeds when the stage seeds and empty
  otherwise. It is reported through the existing backfill note (FR18).
- **FR17** — `existing_touches` is read through `fm_list` too, so a populated inline `touches:`
  is kept. Before this, only a block-form `touches:` counted as populated, so an inline one was
  seeded over. AC24's case is the inline form.
- **FR19** — the detector matches an entry that is exactly `*`.
- **FR21 — reported, not refused.** `claim` prints `COLLIDES <id> | <paths> — held by <id> [<tok>],
  its touches` (or `its expects (predicted)` when the holder's `touches:` is empty, as `next`'s
  `declared_scope` reads it) after `claimed …`. Closed items and the claimant's own token are
  skipped. Its comparison runs under `set -f`, so a glob entry is compared as written.
- **FR20 is scoped to `./next <stage>`**, the mode that prints TAKE. *Reasoned, not run:*
  `--drive`'s gate walk was not checked for an exclusive row offered while another row is held.
- **Red proofs, run.** The new cases ran in a worktree at `c8a4066`, with this leg's test files
  over the baseline scripts. `tests/claim.test.sh` failed 13 and `tests/next.test.sh` failed 7,
  and every new case passes at `718a756`. **AC23 is green at baseline** (also run): the old seeder
  already added a seeded key when none existed. Its case is a regression guard, not a red-to-green
  proof.
- **FR22 / AC28 moved out of S1 into S15, `unspecified` (re-split 2026-11-27).** Built as written
  inside `drift_report`, the class made `--drive` escalate on every fixture whose `expects:` names a
  file the fixture never made: 322 reds in `tests/next.test.sh`. On a live backlog it would
  escalate on every ticket that declares a file it will create. That is the case `claim`'s 0147
  FR2 calls "the common and correct case", and this ticket's own S8–S11 paths are examples. Built
  in `--drift` alone, it reds 0142 FR3's guard *"--drive and --drift name the same rows and
  classes, because they share the check"*. Both readings break a closed contract that is guarded,
  so this is a decision, not missing detail. The open questions are whether `--drive` gates on the
  class and whether a path commented `# new` (`develop` Step 1's own instruction) is exempt.
  Measured over the live backlog on 2026-11-27, the class would name 0240
  (`references/MEASUREMENT.md`, which is at the repo root) and 0242's to-be-created and
  `.claude/backlog/*` paths.
- **0242's own `expects:` is stale in one respect.** `.claude/backlog/{claim,next,close,handoff}`
  do not exist in this repo, whose backlog is at `.tickets/` (0228). Left for the leg that touches
  them.
- **`./claim` without a token dies here on `xxd: not found`.** This is already parked twice in
  `FINDINGS.md` (2026-11-26, 2026-11-27). This leg claimed with a token minted by `od`.

### S2 build notes — 2026-11-27, develop `b7b2` (sprint run-20261127T024025Z)

- **S2 built at `3a7e008`, plus guard `cbda31d`.** FR24–FR30, aiming at AC30–AC40. The whole
  suite ran file by file at `cbda31d`: all 45 files rc=0 (`tests/claim.test.sh` `189 passed`,
  `tests/next.test.sh` `752 passed`, `tests/close.test.sh` `330 passed`,
  `tests/backlog-scripts-installed.test.sh` `55 passed`, `tests/declared-copies.test.sh` `23 passed`).
- **FR24 was mostly already true. Run:** at baseline, a verify claim with an empty `touches:` already
  printed no set, narrow or widen instruction (0106/0145). The gap was a non-build claim over an
  item that still carried an earlier session's `touches:`. That branch printed `widen it in …`.
  It is now gated on the stage building, and both non-build branches say `<stage> holds no file
  scope`. AC31's two develop branches (`NARROW it`, `set it in`) were green at baseline, so their
  cases are regression guards, not red-to-green proofs.
- **FR25: "a stage that does not build" means what `claim`'s seed already means.** Any `Next` other
  than `develop`, with an empty or unreadable stage treated as building. `declared_scope` takes the
  row's `Next` cell and prints `none — <stage> holds no file scope; it writes only its item and row`.
  A held develop row with an empty `touches:` keeps `assume held, ask`. Only the CLAIMED FILES
  block changed. `collision_report` and `design_conflict` are untouched, since FR25 names only the
  block.
- **FR26:** `claim --help`/`-h` and `close --help`/`-h` print a usage block covering every mode and
  exit 0 before anything reads the queue. `claim` also refuses a flag in the id position (exit 2).
  The function is `claim_usage`, not `usage`, because `tests/declared-copies.test.sh` reds on a
  function name defined in two scripts outside a marked copy block (`next` has `usage`). That red
  was the only one in the first whole-suite run.
- **FR27/FR30:** bare `./next` appends ` — not takeable: <reason>` to `ROW 1:` when row 1 cannot be
  taken. The reason is `waiting on: <the ## Waiting on question>`, `blocked by <ids>`,
  `held by [<tok>]`, a non-dispatchable stage, a stray Status, a collision, or a held-elsewhere
  exclusive row. A `TAKEABLE:` line follows, giving the topmost row that can be taken, or
  `TAKEABLE:  none — no row is takeable at any stage`. A takeable row 1 prints exactly as before,
  with no `TAKEABLE:` line (AC35). The helper `not_takeable_because` repeats the `./next <stage>`
  take loop's tests in the same order. The empty queue is left to S3 (FR34): with no rows, neither
  addition fires.
- **FR29 and one interpretation to check.** `claim <id> [token] --touches <path>...` writes exactly
  the named paths. It replaces any existing `touches:` and never reads `expects:`. The write happens
  in the same awk pass, lock and commit as the claim. AC38's "the `QUEUE.md` row reflect[s] exactly
  `path/a` and `path/b`" was read as "the row is claimed in that same commit". No table shape these
  scripts read carries a touches column, since ownership and scope live in the item's frontmatter
  (`claim` header, *Columns are resolved by header name*). The case asserts the row reads
  `in-progress` and that the one commit carries both files. The missing-path warning is skipped
  under `--touches`, per *Out of scope* ("recorded, not validated").
- **FR28:** `.tickets/{claim,close,next}` were re-copied from the templates in `3a7e008`. This
  repo's installed copies live there, not under `.claude/backlog/` (0228), so AC36's
  `.claude/backlog/` paths read as `.tickets/` here.
- **Red proofs, run:** the new cases were written first and ran against the unchanged templates.
  `tests/claim.test.sh` had 20 FAIL, `tests/next.test.sh` 12 FAIL and `tests/close.test.sh`
  2 FAIL. All passed after `3a7e008`.
- **Mutation sweep, run** (each applied to the committed template the harness runs, the diff
  confirmed non-empty, then restored with `git checkout --`; `git status` clean after):

  | AC | Clause | Mutation | Result |
  |---|---|---|---|
  | AC33 | `./claim --help` / prints usage / exits zero | help branch deleted (M1) | red: `exits 0`, `-h exits 0 too` |
  | AC33 | `./close --help` / prints usage / exits zero | help branch → `-NOPE` (M6) | red: both flags |
  | AC38 | `--touches path/a path/b` / touches: reflects exactly them / same commit | seed list ← expects (M2) | red: 4 cases |
  | AC39 | expects names different paths / touches: only the given paths | M2; `SEED=1` dropped so an existing scope is kept (M4) | red: `holds only path/a` |
  | AC30 | Given a claim on a `next: verify` row / message does not instruct setting touches: | non-build branch keeps `BUILDS=1` (M3) | red: `no instruction to widen it` |
  | AC32 | in-progress row at a no-file-scope stage / block says so | stage case removed (M7) | red: 4 cases |
  | AC34 | row 1 waiting, takeable lower / prints both, marks which | reason forced empty (M8); first-takeable picks row 1 (M12) | red: 7 and 4 |
  | AC35 | row 1 takeable / not printed twice | TAKEABLE always printed (M9) | red: `no TAKEABLE line repeats it` |
  | AC40 | waiting → the question; blocked → the id | question dropped (M10); id dropped (M11) | red: each |
  | FR26 | a flag in the id position refuses | `-*` id branch disabled (M5) | first sweep GREEN, an unguarded clause; `cbda31d` adds the case, re-run red |

  AC31 (`NARROW it`, `set it in`) is the baseline behaviour this leg kept. AC36 is
  `tests/backlog-scripts-installed.test.sh` green, and AC37 is the whole suite above.
  *Reasoned, not run:* `not_takeable_because`'s collision and exclusive-row branches have no bare
  `./next` case. They reuse `collision_report` and the take loop's exclusive test, which
  `tests/next.test.sh` already guards in `./next <stage>`.
- **Stale sibling prose this leg creates (reported, not edited):** `skills/develop/SKILL.md` Step 1
  still tells a session to write `touches:` after the claim by hand. It does not name
  `--touches`. That prose is S14's (FR11) to move onto the script.

### S2 verify FAIL — 2026-11-27, verify `357a` → develop

- **AC30 fails on the `--touches` branch; everything else in the leg held under mutation.** The output
  is in *QA evidence*, Leg S2. `./claim <id> <tok> --touches <path>` on a `next: verify` row succeeds
  and prints `widen it in <item> the moment the work reaches further`.
- **The constraint, from FR24 and AC30:** a successful claim at a stage that does not build prints no
  instruction to set, narrow or widen `touches:` on any branch, `--touches` included. FR29 is not
  in question: the write itself still happens whatever the stage. Only the message is
  stage-gated, as the existing-`touches:` branch already gates it on `BUILDS`. AC30 needs a case for a
  verify claim given `--touches`, asserting none of `NARROW it`, `set it in`, `widen it`.
  Mutate it red by ungating the line.
- The rest of S2 needs no rework (AC31–AC40 each reddened under its own mutation, recorded in the
  evidence table). A re-entry verify reuses that clause table.

### S2 re-develop — 2026-11-27, develop `6e3a`

- `66afa28` — the `--touches` branch of `skills/queue/templates/claim` (and `.tickets/claim`) now
  prints `widen it …` only when `BUILDS` is 1, else `<stage> holds no file scope, so nothing here asks
  you to change it`, the same wording the existing-`touches:` branch uses. The `touches: is set from
  --touches (N paths)` line and the write itself are unchanged at every stage (FR29).
- New case in `tests/claim.test.sh`, `0242 AC30 — nor when the verify claim is given --touches`
  (fixture 0270, a `next: verify` row): asserts the write is reported and none of `NARROW it`,
  `set it in`, `widen it` appears. AC30 clause rows added: *Given a claim on a `next: verify` row*
  + `--touches` → this case; predicate *does not instruct to set `touches:`* → the three
  `assert_not_contains`.
- Mutation **run**: replacing the gated block with the ungated `echo "widen it …"` (committed file,
  restored by `git checkout --`) → `193 passed, 2 failed` (`no instruction: widen it`, `says verify
  holds no file scope`); control after restore `195 passed, 0 failed`. Whole suite green, tree clean.
- Environment note: `./claim 0242` with no token died at `xxd: not found` before writing anything
  (no lock, no commit); claimed with an explicit token instead. Already in FINDINGS.md (verify `357a`'s entry), so not re-parked.

### Open questions for the unspecified slices

**Established, not yet specified (it was at next: queue), from 0217 — Stop a note written below the last AC from changing that AC's digest:**

- Either `--ac-digest` ends an AC at a line that is not a `- [ ] ACn` continuation, or `develop`'s re-entry guidance names where a stop note goes. The recurrence argues for the script fix: a note's position is not something a session reliably reads guidance about.

**Established, not yet specified (it was at next: queue), from 0219 — Make reopen leave a ticket that verify can close when it reopens a develop self-close:**

- Options: `reopen` resets `close_by` to `verify` when the reopen is for an independent verify (a flag or a reason class), or `close` accepts a verify close on a reopened row. The first keeps `close`'s refusal simple.

**Open design question, from 0235 — Decide whether claim, handoff and close refuse off the branch the backlog is shared on:**

Refuse or warn when the checked-out branch is not the one the backlog is shared on — and how does a
script know which branch that is (a `config.yml` key, the remote's HEAD, or `main` by default)?

**Open design question, from 0237 — Give queue a way to send an open verify ticket back to design:**

Which carries it: a named operation in `queue` Step 1 that claims then `./handoff … design`, an
unclaimed form of `./handoff`, or `./reopen` taking a target stage?

**Open design question, from 0236 — Decide whether design may amend unheld sibling items its own FRs name:**

Either name a second narrow exception in *A stage writes only the ticket it holds* (unheld, non-done
items named in the held item's own FRs, under the lock, in the decision's commit), or have `queue`
stop writing FRs that amend other items. Which?

### Carried notes of the absorbed tickets

### From 0215 — Make claim and next read expects and touches through one parser that refuses or accepts the comma form

- 2026-10-24 — Filed by retro (second leg of AetherWorks run-20261024T195310Z's tail) from five tools-buffer
  entries naming the same defect. 0096 covers two other defects in these fields (unresolved paths, a
  wrong-block edit anchor) and is not this; 0103 asks whether the scripts may share a sourced file, which
  FR13 may want — check its state before choosing how to share the parser.
- 2026-10-27 — retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park (develop 0182): `touches: "*"` as an inline scalar reads through `next`'s `fm_list` as `none declared`, so an exclusive claim collides with nothing; only the block form registers. 0145 (done) made `close`/`handoff` read both forms; `next` was not in its scope. Same one-parser fix.
- 2026-11-18 — retro (findings gate of run-20261118T074205Z), from a FINDINGS.md park (develop 0231): `./claim 0231` reported "declares no expects:" over a flow-style `expects: [...]` that `./next develop` read, so `touches:` was left unset — a live instance of this row's parser split.

### From 0225 — Make claim write an empty touches key when it has nothing to seed

- 2026-11-06 — Filed by retro (sprint run-20261101T172121Z tail) from the tools-repo findings entry of
  2026-11-01 observed in AetherWorks 0027. Confirmed by a real project, so filed rather than held.

### From 0155 — Make claim and next agree on what blocks a take

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Six buffer entries from five sessions, grouped because each is the two scripts giving opposite answers about one take, and they share both files.
- 2026-10-27 — retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park, two more disagreements on what a file reservation holds: (1) develop 0169: `./close`'s scope report reads a glob `touches:` entry (`"tests/*.test.sh"`) literally — the entry reads untouched and all 34 matched files undeclared — and `next`'s held-file comparison presumably does too; decide expand-or-forbid for globs across `claim`/`next`/`close`. (2) design 0145: `collision_report` reads an empty `touches:` on a held develop row as holding nothing, while CLAIMED FILES says "assume held, ask" and `design_conflict` falls back to `expects:`. 0145 (done) settled only the scope report.

### From 0066 — Fix the three places the backlog scripts answer the wrong question

- Routed to `develop`: three named defects with named fixes and no competing shapes.
- **FR25 is the half that is not ergonomics.** FR24 alone fixes the message and leaves `./next` still
  reporting every correct `verify` claim as ambiguous — which is the part that reaches other
  sessions and makes rows look unsafe. It depends on 0044's decision about what `claim` writes only
  if that ticket changes the field; today it does not, so this is independent.
- Ranked last of this batch. All three are real, all three are inert — nothing degrades while they
  sit — but each is small and clears the deck.
- **Amended 2026-09-01 by `0085`'s queue pass.** FR29 and FR30 are the two FRs `0085`'s settled
  decision (`docs/decisions/001-one-command-per-stage-boundary.md`) routed here: FR29 is the
  `--touches` flag the decision record's *trade-off accepted* names as the one place its plan can
  weaken a rule if misused, and FR30 generalizes FR27's fix to every non-takeable-row-1 warning, not
  only the case FR27 already covers. **Size re-checked and raised `m` → `l`**: FR29 adds a new
  argument and a second field written atomically inside the claim's existing lock, which is more
  than the three original defects' scope.

### From `FINDINGS.md`, landed 2026-09-05

- **A malformed `touches:` makes a held row's file scope invisible, and the claiming session cannot
  fix it** (FINDINGS 2026-09-03). `0085`'s frontmatter read `touches: []` with a YAML list item on
  the following line, so `./next develop` printed `CLAIMED FILES — another session owns these` with
  the id `0085 [0bd8]` and **no paths at all**. Deciding whether the top row was takeable therefore
  cost a full read of the other session's item file — which is the read FR27 exists to remove, one
  file over: FR25 distinguishes a legitimately empty `touches:` from an undeclared one, and this is a
  third state neither covers, *unparseable*. Two halves worth separating. The scripts could refuse
  to print an empty holder without saying the frontmatter does not parse — a warning naming a holder
  and no paths is a warning that cannot be acted on, the same class of defect as FR27 and FR30.
  And nothing validates `touches:` at write time even though `./claim` writes the surrounding block,
  which is FR29's territory: the flag that writes the field is the cheapest place to reject a
  malformed one. `CONCURRENCY.md` (*A stage writes only the ticket it holds*) correctly forbade the
  session that found it from repairing the row, so a bad value can only be parked — which is an
  argument for rejecting it at write time rather than tolerating it at read time.

### From 0229 — Make next --drift report a closed item that still carries a claim token

- 2026-11-08 — Filed at the user's request. It was reported as "`close` leaves `claimed_by:` set";
  reading the template showed `close` clears it (`if ($0 ~ /^claimed_by:/) { print "claimed_by:" }`)
  and 0228, closed with it, holds an empty field. Every stale token traced to a by-hand close, so
  the ticket is the check that makes them visible rather than a fix to `close`.
- 2026-11-08 — Routed to `develop`: no surface and no open decision; the DRIFT line's wording is
  given in FR31.
- 2026-11-08 — **Knock-on to know about:** `--drive` escalates on any drift, so a sprint in
  AetherWorks will stop on these 21 lines until they are cleared. The line names the fix for that
  reason.

### From 0230 — Make next say the queue is empty instead of printing a blank ROW 1

- 2026-11-08 — Filed at the user's request. Routed to `develop`: no surface, no open decision.
- 2026-11-08 — The line is kept and given text rather than dropped: the script's header says its
  output is a fixed handful of lines whatever the queue holds, and a reader scanning for `ROW 1:`
  should always find it.

### From 0227 — Make next list the findings entries so no drain matches a buffer's header by hand

- 2026-11-06 (queue, unattended, AetherWorks sprint run-20261101T172121Z) — swept from this repo's
  `FINDINGS.md`, the entry parked by that run's retro. **Filed as a new ticket rather than
  un-withdrawing 0213**, because the second hit is in a project copy, which 0213 by its own scope
  cannot reach; the entry offered two fixes and this takes the reader-side one, expressed as a
  script rather than as a sentence telling sweepers where entries start. Routed to `develop`: no
  surface and no open decision — `count_findings` already holds the boundary rule. `close_by:
  develop`: every criterion names a case in a committed test file.

### From 0156 — Let handoff record a blocker without leaving drift that stops a driver

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry, filed because the tooling's own documented shape is what stops a sprint.

### From 0217 — Stop a note written below the last AC from changing that AC's digest



### From 0219 — Make reopen leave a ticket that verify can close when it reopens a develop self-close



### From 0235 — Decide whether claim, handoff and close refuse off the branch the backlog is shared on

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.

### From 0237 — Give queue a way to send an open verify ticket back to design

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.

### From 0236 — Decide whether design may amend unheld sibling items its own FRs name

- 2026-11-18 (retro) — filed from a consuming project's finding. Its other half (a decision-only
  ticket hands to `verify`) landed in `skills/design/SKILL.md` Step 4 the same day.

### From 0118 — Run the privacy guard where a sweep commits, not only where a suite runs

- 2026-09-09 (retro) — filed from the remaining half of the `FINDINGS.md` entry that recorded the
  landed fix at `2a69aa9`. The landed half is dropped from the buffer; this is what was left
  needing a row.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Another commit site: a QA-evidence table quoting a guard's failure message verbatim published a home-directory path in `items/0052-…md:294` (`Close 0052`), reddening `measurement.test.sh` and the fail-fast release gate. Since redacted and green, but `verify` Step 7's evidence write is the ordinary route and runs no privacy check before its commit.
