---
id: "0242"
title: Make every backlog write one script call, and make the scripts agree with each other
type: debt
next: queue
status: in-progress
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
  - tests/ac-digest.test.sh
  - tests/reopen.test.sh
  - .tickets/reopen
  - .tickets/claim
  - .tickets/handoff
  - .tickets/close
  - tests/backlog-location.test.sh
  - tests/design-hold.test.sh
  - tests/scaffold-close.test.sh
  - tests/sprint.test.sh
ac_digest: AC1=3f4813fa AC2=00ed7e8d AC3=cc9098c3 AC4=c39ef3f4 AC5=cd5192a9 AC6=08ff8130 AC7=19b18cb5 AC8=b842bc08 AC9=18fa1024 AC10=6e4e0541 AC11=4fce6a8a AC12=85333459 AC13=184dee36 AC14=e8fbc130 AC15=f8a8f901 AC16=b2de2b18 AC17=f8f530b6 AC18=3c1c133b AC19=c00e3e5b AC20=b7aea097 AC21=2797aa8b AC22=2982ae38 AC23=2ae59f5d AC24=4ee45ae4 AC25=efb5b2ea AC26=d6679279 AC27=1900687b AC28=f0678e1a AC29=ca008731 AC30=2c0cb400 AC31=2fea3bb7 AC32=0ea2fa1f AC33=0798a7d2 AC34=17f78639 AC35=81a1eeed AC36=295a79f7 AC37=03c9ed76 AC38=99abb6b8 AC39=157525d8 AC40=ea7e3fba AC41=e8935ea1 AC42=d89f512e AC43=b2861434 AC44=7dfc9899 AC45=167587a8 AC46=e93172ec AC47=cef1068e AC48=66233639 AC49=e1f1156c AC50=d1b0c900 AC51=6158b990 AC52=553a49b4 AC53=71802b40 AC54=6a89e958 AC55=fc2745e7 AC56=aa350e52 AC57=87c0e9e6 AC58=a583d20d AC59=dd572398 AC60=48f5e107 AC61=aa483225 AC62=c77fc918 AC63=e6003050 AC64=cd0488b1 AC65=dfa70118 AC66=49bcb542 AC67=9f11e85d AC68=ba932761 AC69=b7bd5a10 AC70=79bbe8a3 AC71=50e7157c AC72=7f1f7079 AC73=3902e103 AC74=4ae18559 AC75=ed583ed7 AC76=1f74adcb AC77=daa124e8 AC78=9de0f100 AC79=d33bbcc4 AC80=e46fe1e6 AC81=ff13b5c9 AC82=d9ab8d22 AC83=7d5d6a7c AC84=7e39137c AC85=4c37e61e AC86=034cf395 AC87=5714d3fe AC88=88f5d80c AC89=fe70c6dd AC90=4e8d4db0 AC91=d1ca1c88
claimed_by: "e782"
claimed_at: 2026-11-27T15:50:00Z
touches:
slice: S11
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
- FR22 *(was 0155 FR4; sharpened by design `56a2`, 2026-11-27)* — `./next --drift` reports an open row whose `expects:` names a path that does not exist and matches no glob, unless that entry carries a `# new` comment (FR63). The class sits in `drift_report`, the check `--drift` and `--drive` share, so `--drive` gates on it like every other class (FR64).
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
- FR42 *(was 0235 FR1; sharpened by design `3708`, 2026-11-27)* — `claim`, `handoff`, `close` and `reopen` **refuse**,
  and never only warn, when the primary checkout's current branch is not the shared branch (FR55).
  A detached HEAD also counts as off the branch. The check runs **up front**: before the lock is
  taken and before any file is read for writing, directly after the linked-worktree refusal in
  each script, so a session learns it is on the wrong branch at `./claim`, before it spends
  anything on the row. The refusal exits 1, writes nothing, takes no lock, and prints these four
  lines to stderr:
  `refusing to <verb> <id>: this checkout is on '<current>', and the backlog is shared on '<shared>'`,
  then `switch with: git switch <shared>, or set shared_branch: in <backlog dir>/config.yml if '<shared>' is wrong`,
  then `see references/CONCURRENCY.md, 'The backlog is written on one branch'`,
  then `nothing was changed and no lock was taken`.
  `<verb>` is the script's own verb (`claim`, `hand off`, `close`, `reopen`). `<current>` is
  `HEAD (detached)` when no branch is checked out. Outside a git work tree the check does not
  apply, as with the linked-worktree check. There is no flag that overrides it: the key is the
  one way to name another branch.
- FR43 *(was 0235 FR2; sharpened by design `3708`, 2026-11-27)* — `references/CONCURRENCY.md` gains a section
  *The backlog is written on one branch*, placed directly after *A second checkout never writes
  the backlog*. It states the refusal, the resolution order (FR55), that the check is made at
  claim time so it lands before any work starts, and the one-line fix. Prose only, and unguarded
  (`CLAUDE.md`, *Tests*: no new guard greps prose).
- FR44 *(was 0237 FR1; sharpened by design `56a2`, 2026-11-27)* — An open row at `next: verify` is moved to
  `next: design` by `queue` running `./claim <id>` and then `./handoff <id> <token> design`. That is
  two script calls, and each one writes the item and its `QUEUE.md` row in one locked commit. Between
  them the row is held by `queue`, so no other session can take it, and nothing edits `next:` or the row
  by hand. Neither script changes for this: `handoff` already accepts `design` as a target from a
  `verify` row (observed 2026-11-27, FR59). `./reopen` keeps its stated contract ("the destination is
  always `verify`", on a `status: done` item only), and `./handoff` keeps its token.
- FR45 *(was 0237 FR2; sharpened by design `56a2`, 2026-11-27)* — `queue` Step 1's routing table gains one row.
  The trigger is the user overturning the decision on an open ticket at `next: verify`. The steps are
  `./claim <id>`; then a dated line in `## Notes & decisions` naming what the user overturned; then an
  `## Open design question` section stating the question again, so `design` Step 1 has a contract
  to read; then `./handoff <id> <token> design`. If `./claim` refuses because another session (a
  verify pass) holds the row, `queue` stops and reports. It waits for that release, as
  `references/CONCURRENCY.md`, *A claimed ticket is never amended, even by `queue`*, already
  requires. It never writes the row unheld.
- FR46 *(was 0236 FR1)* — Whichever is chosen is stated in `references/CONCURRENCY.md` and in the skill it binds
  (`design` Step 4 or `queue` Step 2), and the other skill does not contradict it.
- FR47 *(was 0118 FR1)* — the step in which `queue` commits a parked finding names the privacy guard and requires it
  to have run over the paths being committed.
- FR48 *(was 0118 FR2)* — `retro` Step 6 does the same for its own park, which is committed by pathspec in the same
  turn it is written.
- FR49 *(was 0118 FR3)* — the requirement names the command, not the concept, so a session can run it without
  deriving which guard is meant.
- FR50 *(0217, design 2026-11-27)* — In `skills/queue/templates/next`'s `ac_digest_of`, a criterion's text is its
  label line plus every following line that is blank or begins with a space or a tab. The first line
  that is neither, and is not itself a label line, ends the criterion, as a `## ` heading and the
  next label already do. So prose written at column 0 below a criterion is outside every digest,
  and a blank line followed by an indented line (0161 AC1's shape) is still inside one.
- FR51 *(0217, design 2026-11-27)* — Expand, not contract (`migration-conventions.md`, *Expand, Migrate, Contract*):
  `./next --ac-digest <id>` prints FR50's digest only, while `--ac-digest <id> --check`, `close`
  and `--drift` accept, key by key, a stamped value equal to either FR50's digest or the legacy one
  (today's normalisation, text to the next label or heading). An upgrade therefore reports no drift
  that nobody caused, and every later stamp is written in the new form. The legacy computation sits
  beside the new one in `next`, named as legacy, with a comment naming 0242 S5. Removing it is the
  contract step, and it is out of scope.
- FR52 *(0217, design 2026-11-27)* — `.tickets/next` is re-copied from the template so the two stay byte-equal.
- FR53 *(0219, design 2026-11-27)* — `./reopen` on an item that records `close_by: develop` writes `close_by: verify`
  in the same locked commit as the rest of the reopen. The dated `## Notes & decisions` line it
  appends records the change after the reason, as `close_by: develop → verify — a reopen is for an
  independent verify`. An item that records `close_by: verify`, or no `close_by:` at all, keeps
  that key exactly as it was.
- FR54 *(0219, design 2026-11-27)* — `reopen`'s header comment lists the reset beside the other item resets it
  names, and `.tickets/reopen` is re-copied from the template so the two stay byte-equal.
- FR55 *(0235, design `3708`, 2026-11-27)* — The shared branch is resolved in this order, first hit wins:
  (1) a top-level `shared_branch: <name>` key in the backlog directory's `config.yml`, with a
  trailing `# comment` and surrounding blanks stripped as `findings_threshold` is read in `next`;
  (2) `git symbolic-ref --short refs/remotes/origin/HEAD` with its leading `origin/` removed,
  when that command succeeds; (3) `main`. Nothing fetches or touches the network. An empty
  `shared_branch:` value counts as unset.
- FR56 *(0235, design `3708`, 2026-11-27)* — The resolution and the comparison are one function, in one
  `copy-begin: shared-branch` / `copy-end: shared-branch` block that is byte-identical in
  `skills/queue/templates/claim`, `handoff`, `close` and `reopen`, which `tests/declared-copies.test.sh`
  already enforces. `.tickets/claim`, `handoff`, `close` and `reopen` are re-copied from the templates
  so `tests/backlog-scripts-installed.test.sh` stays green. Each backlog-writing script added after
  S7 (S8–S11's `capture`, `park`, `rank`, `withdraw`, `drain`) carries the same block. That is a
  build note for those slices, and their criteria are unchanged.
- FR57 *(0235, design `3708`, 2026-11-27)* — Every test fixture that runs one of the four scripts in a git
  repo starts on `main` (`git init -q -b main`, or a `shared_branch:` key that names its branch). As
  re-verified on 2026-11-27, a bare `git init -q` here starts on `master` (git 2.43, no
  `init.defaultBranch`), so an unpinned fixture would refuse.
- FR58 *(0235, design `3708`, 2026-11-27)* — `CHANGELOG.md` `## Unreleased` carries one line for consuming
  projects: the four scripts now refuse off the shared branch, how that branch is resolved, and
  that a project sharing on a branch other than `main` with no `origin/HEAD` needs one
  `shared_branch:` line in its `config.yml` after upgrading.
- FR59 *(0237, design `56a2`, 2026-11-27)* — `tests/handoff.test.sh` carries a case that runs the real
  `./claim` and then `./handoff <id> <token> design` on a fixture row at `next: verify`. It is a
  regression guard and is green at baseline. On a scratch clone on 2026-11-27, `./claim 0192 ab12`
  and then `./handoff 0192 ab12 design` exited 0 with `handed off 0192: verify -> design, status
  ready, claim ab12 released`. The item and the row then read `design | ready`, `claimed_by:` was
  empty, and the tree was clean.
- FR60 *(0235/0237, design `56a2`, 2026-11-27)* — No other skill or reference contradicts FR45. In
  particular, `references/CONCURRENCY.md` and `skills/verify/SKILL.md` do not say that only `verify`
  or `reopen` may move a row off `next: verify`.
- FR61 *(0155, design `56a2`, 2026-11-27)* — FR22's report is one line per entry:
  `DRIFT     <id> | expects: <path> exists nowhere — correct the path, or mark it '# new' if this ticket creates it`.
  It checks every row in `QUEUE.md`, held or not, because `expects:` is `queue`'s prediction
  whoever holds the row. It never checks a `DONE.md` row.
- FR62 *(0155, design `56a2`, 2026-11-27)* — A path resolves against the repo root, which is
  `git -C "$DIR" rev-parse --show-toplevel` or, outside git, the backlog directory's parent. A glob
  entry counts as present when shell pathname expansion matches at least one path. A plain entry
  counts as present when `[ -e ]` is true for it. Nothing is fetched, and nothing outside the repo
  root is read.
- FR63 *(0155, design `56a2`, 2026-11-27)* — An entry is exempt when the YAML comment that `decomment`
  cuts from its line begins with the word `new`. That covers `# new` and `# new — the script S8 adds`,
  but not `# renewed` and not `# not new`. The comment is read by a helper beside the
  `copy-begin: decomment` block. The block itself is a declared copy, and it is not changed.
  Prior art: `skills/queue/templates/item.md`'s `expects:` comment already names `# new` as the
  comment one path carries.
- FR64 *(0142 FR3 kept, design `56a2`, 2026-11-27)* — `--drive` spends ESCALATE (4) on the class, as on
  every class `drift_report` prints. `tests/next.test.sh`'s *0142 FR3* case still finds identical
  DRIFT lines in `--drive` and `--drift`, and still counts exactly three drifted rows. Its fixture
  paths (`a/one.md`, `b/two.md`) are written with `# new`, or the fixture creates them. The same
  applies to every fixture helper in `tests/*.test.sh` that writes `expects:` and then runs
  `--drift` or `--drive` (`add_ticket` and `add_item_held` in `tests/next.test.sh`, and any
  sibling). The suite stays green; 322 reds were observed when the class was built without this
  (S1 notes).
- FR65 *(0155, design `56a2`, 2026-11-27)* — The S15 leg corrects this item's own `expects:`. Develop holds
  0242 and may do this. The four `.claude/backlog/{claim,next,close,handoff}` entries do not exist
  in this repo (0228), so they are dropped. 0240's `references/MEASUREMENT.md` belongs to another
  ticket. The leg records in its notes that 0240 "still needs its `expects:` corrected", and does
  not write 0240. Until `queue` corrects it, `--drive` escalates on 0240, and that is the class
  working. Measured on 2026-11-27, those five entries are the only missing, unmarked `expects:`
  paths in the live open rows.
- FR66 *(0155, design `56a2`, 2026-11-27)* — `skills/queue/templates/item.md`'s `expects:` comment says
  that an entry naming a file the ticket will create carries `# new`, and that `--drift` and
  `--drive` report any other entry that exists nowhere. `--drift`'s usage text names the class.
  `CHANGELOG.md` `## Unreleased` carries one line for consuming projects: after upgrading,
  `--drive` escalates on every open row whose `expects:` names a missing, unmarked path, and the
  fix is to correct the path or mark it `# new`. The template comment and the CHANGELOG line are
  prose only, and unguarded (`CLAUDE.md`, *Tests*). The usage text is script output, and AC83
  checks it.
- FR67 *(0236, design `213b`, 2026-11-27)* — **No stage writes an item it does not hold, and no
  second exception is added.** `references/CONCURRENCY.md`, *A stage writes only the ticket it
  holds*, keeps its one exception (a close reconciling dependents). `design` amends no sibling item,
  even an unheld one its own FRs name. Rejected: a second narrow exception for `design` (the brief's
  Option A) and a `claim` mode for `blocked` rows (Option C). The reasons are in *Notes &
  decisions*, S13.
- FR68 *(0236, design `213b`, 2026-11-27)* — **A design pass whose decision changes what another
  item must say records it in the held item, then hands to `queue`.** It writes a subsection under
  `## Notes & decisions` headed `### Sibling consequences — <date>, design <token>`. Each entry
  carries the affected item's id, the FR or AC there that must change and how, why, and the item's
  state as observed at that moment: open and unheld, held (with the token), or `done`. Then it
  releases with `./handoff <id> <token> queue`, never `develop`. A consequence that lands on
  another slice of the item design holds is not a sibling consequence. `design` writes that itself,
  because it holds the file. A decision with no sibling consequence hands off as today.
  `skills/design/SKILL.md` Step 4 says this. The item-scoped path that hands to `develop` names
  this case as the exception. The path that is held by another is unchanged.
- FR69 *(0236, design `213b`, 2026-11-27)* — **`queue` folds sibling consequences in, judges them
  holistically, and may send the decision back.** `skills/queue/SKILL.md` Step 1 gets one routing
  row for a ticket at `next: queue` whose Notes carry an unresolved `### Sibling consequences`
  subsection. For each entry, `queue` first re-reads the sibling against the source, because the
  entry is a cached claim (`CONCURRENCY.md`, *A criterion belonging to another ticket…*). Then
  it checks the proposal against the other open tickets and their ACs, not only the sibling named.
  Then it does one of three things:
  - (a) **Amend** the sibling by Step 1's existing path: claim, amend, restamp `ac_digest`, hand
    back. For a held sibling, wait for the release first (*A claimed ticket is never amended…*).
  - (b) For a `done` sibling, `./reopen <id> <rank> "<reason>"`, then `./claim`, amend, restamp,
    and `./handoff <id> <token> develop`, so the fix is built and then verified, not only
    re-verified. The reopen and the amendment are named in both items' Notes as intentional rework.
  - (c) Judge that the consequence does not serve the outcome or conflicts with another ticket. In
    that case, restore an `## Open design question` in the held item that names the conflict, and
    `./handoff <id> <token> design`.

  `queue` marks each entry `resolved <date> queue <token>: <a|b|c and the commit>`, then hands the
  held item to `develop`, or to `design` if any entry took (c). It writes "still needs" for any
  entry it could not reach (*A stage may record what still needs filing…*).
- FR70 *(0236, design `213b`, 2026-11-27)* — **`queue` writes no FR that directs another stage to
  write an item it will not hold.** `skills/queue/SKILL.md` Step 2 says this. Work that must land in
  another item is either an Amend that `queue` performs itself, or, found by `design`, an FR68
  entry. `skills/design/SKILL.md` Step 4 says what to do with a held item's FR that directs such a
  write: treat it as an FR68 sibling consequence, write nothing outside the held item, and say so in
  Notes. That was 0236's consuming-project case.
- FR71 *(0236, design `213b`, 2026-11-27)* — **A queue pass follows every plan change before the
  changed work continues.** `references/CONCURRENCY.md` states this once, in *A stage writes only
  the ticket it holds*, with FR68's hand-off as the mechanism and the bounded wait as the accepted
  cost. The sibling reads stale until the `queue` pass runs. A sibling that is held when design
  records the consequence finishes its current leg against the old contract, at most one leg (0231
  FR18), and `queue` then amends it. `skills/design/SKILL.md` and `skills/queue/SKILL.md` cite
  that rule, and do not restate it.
- FR72 *(0236/0234, design `213b`, 2026-11-27)* — **`./next --drive` dispatches `queue` on an
  in-scope row that a `design` completion handed to `next: queue` / `ready`, and does not escalate
  it.** Read on 2026-11-27, `skills/queue/templates/next` (~line 2141) dispatches `queue` only when
  the completed stage is `verify` or `develop`. Any other completed stage reaches the
  `ESCALATE … went back to next: queue … the contract is stale` arm, so a `--completed design:<id>`
  hand-off to queue escalates today. The arm gains `design` with the same `bounce_count`, the same
  `bounce_max` bound and the same findings gate, and its NOTE says `from design`. A `queue`
  completion that leaves the row at `next: queue` still reaches the stale-contract arm (0234 FR14),
  and an out-of-scope row still escalates. Counting this hand-off against `bounce_max` is kept
  deliberately. It is the loop guard the run has today, and a later epic decides how it is
  replaced (the person's answer 6, *Notes & decisions*, S13). The `--drive` usage text and
  `skills/sprint/SKILL.md`'s routing prose name `design` beside `verify` and `develop`.
- FR73 *(0236, design `213b`, 2026-11-27)* — `CHANGELOG.md` `## Unreleased` carries one line: a
  design decision that changes other items now hands to `queue`, which folds the changes in, and
  `--drive` dispatches that pass rather than escalating. Prose only, unguarded (`CLAUDE.md`,
  *Tests*).


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
- [ ] AC56 *(0217)* — Given a fixture item stamped with FR50's digest, whose last criterion is followed by a blank
  line and then a column-0 note, when the note's text is edited and `./next --ac-digest <id> --check`
  runs, then it exits 0 and prints `ac_digest matches`. In `tests/ac-digest.test.sh`. Red: today's
  normalisation, which reports `changed:` for that criterion.
- [ ] AC57 *(0217)* — Given the AC56 fixture, when an indented continuation line of its last criterion is edited,
  then `--check` exits 1 and names that criterion as `changed:`. In `tests/ac-digest.test.sh`. Red:
  a rule that ends every criterion at its label line.
- [ ] AC58 *(0217)* — Given a fixture criterion whose text runs on after a blank line as an indented line (0161
  AC1's shape), when that indented line is edited, then `--check` exits 1 and names the criterion.
  In `tests/ac-digest.test.sh`. Red: a rule that ends a criterion at a blank line.
- [ ] AC59 *(0217)* — Given a fixture item stamped with the legacy digest, whose last criterion has a column-0 note
  below it, when nothing is edited, then `--check` exits 0 and `./next --drift` prints no
  `ac_digest` line for it. In `tests/ac-digest.test.sh`. Red: FR51's legacy acceptance removed.
- [ ] AC60 *(0217)* — Given the AC59 fixture, when the last criterion's own label-line text is edited, then `--check`
  exits 1 and names it. In `tests/ac-digest.test.sh`. Red: a legacy comparison that accepts any
  value.
- [ ] AC61 *(0217)* — Given the AC56 fixture, when `./next --ac-digest <id>` runs, then the value it prints for the
  trailing-note criterion differs from the legacy digest and equals FR50's digest. In
  `tests/ac-digest.test.sh`. Red: stamping the legacy form.
- [ ] AC62 *(0217)* — Given this repo after the change, when `tests/backlog-scripts-installed.test.sh` and
  `.tickets/next --ac-digest 0242 --check` run, then both pass. Red: an edit to the template alone,
  which leaves `.tickets/next` different. In this repo the migration has no live red, because the only
  stamped items with column-0 notes, 0229 and 0230, are withdrawn, and `--drift` reads open rows
  only. AC59 carries the migration case in fixture.
- [ ] AC63 *(0219)* — Given a fixture item at `status: done` recording `close_by: develop` and `qa_level: unit`, with a
  `DONE.md` row, when `./reopen <id> top "fixture reason"` runs, then the item reads
  `close_by: verify`, the last line of `## Notes & decisions` contains both `fixture reason` and
  `close_by: develop → verify`, and `git show --name-only HEAD` lists exactly the item, `QUEUE.md`
  and `DONE.md`. In `tests/reopen.test.sh`. Red: today's reopen, which leaves `close_by: develop`.
- [ ] AC64 *(0219)* — Given the AC63 fixture after the reopen, claimed, with a `## QA evidence` body written, when
  `./close <id> <token>` runs, then it exits 0 and never prints `the stage that may close it is
  'develop'`. In `tests/reopen.test.sh`. Red: FR53 omitted.
- [ ] AC65 *(0219)* — Given one done fixture item recording `close_by: verify` and another with no `close_by:` key,
  when each is reopened, then the first still reads `close_by: verify` and the second still has no
  `close_by:` line. In `tests/reopen.test.sh`. Red: a reopen that writes the key unconditionally.
- [ ] AC66 *(0235)* — Given a fixture repo on `main` with no `shared_branch:` key and no remote, after
  `git switch -c feature`, when `./claim <id>` runs on a `ready` row, then it exits 1, stderr
  carries `this checkout is on 'feature', and the backlog is shared on 'main'` and `nothing was
  changed and no lock was taken`, `git rev-list --count HEAD` is unchanged, `QUEUE.md` and the item
  are byte-identical to before, and no `.lock` directory exists. In `tests/claim.test.sh`. Red:
  today's claim, which claims on `feature`.
- [ ] AC67 *(0235)* — Given a fixture row claimed on `main`, after `git switch -c feature`, when
  `./handoff <id> <token> develop` runs, then it exits 1 with FR42's first line naming `feature`
  and `main`, the item still carries `claimed_by: <token>`, no commit is added and no `.lock`
  remains. In `tests/handoff.test.sh`. Red: the block omitted from `handoff`.
- [ ] AC68 *(0235)* — Given a fixture row claimed on `main` with a `## QA evidence` body, after `git switch -c
  feature`, when `./close <id> <token>` runs, then it exits 1 with FR42's first line, the row is
  still in `QUEUE.md` and absent from `DONE.md`, no commit is added and no `.lock` remains. In
  `tests/close.test.sh`. Red: the block omitted from `close`.
- [ ] AC69 *(0235)* — Given a fixture done row, after `git switch -c feature`, when `./reopen <id> top "r"` runs,
  then it exits 1 with FR42's first line, the row is still in `DONE.md` and absent from `QUEUE.md`,
  and no commit is added. In `tests/reopen.test.sh`. Red: the block omitted from `reopen`.
- [ ] AC70 *(0235)* — Given a fixture whose `config.yml` reads `shared_branch: trunk  # ours`, when `./claim`
  runs on branch `trunk`, then it exits 0. When it runs on `main`, then it exits 1 naming `'main'`
  and `'trunk'`. In `tests/claim.test.sh`. Red: a resolution that ignores the key, or keeps the
  comment in the value.
- [ ] AC71 *(0235)* — Given a fixture with no key, whose `refs/remotes/origin/HEAD` is a symbolic ref to
  `refs/remotes/origin/develop`, when `./claim` runs on `develop`, then it exits 0. When it runs on
  `main`, then it exits 1 naming `'develop'`. In `tests/claim.test.sh`. Red: resolution by the
  `main` fallback alone.
- [ ] AC72 *(0235)* — Given the AC71 fixture plus `shared_branch: trunk` in `config.yml`, when `./claim` runs on
  `trunk`, then it exits 0. When it runs on `develop`, then it exits 1 naming `'trunk'`. In
  `tests/claim.test.sh`. Red: `origin/HEAD` consulted before the key.
- [ ] AC73 *(0235)* — Given a fixture on `main` after `git checkout --detach`, when `./claim` runs, then it
  exits 1 and stderr carries `this checkout is on 'HEAD (detached)'`. In `tests/claim.test.sh`. Red:
  a check that reads an empty branch name as a match or skips it.
- [ ] AC74 *(0235)* — Given a fixture on `feature` whose backlog directory already holds a `.lock` directory
  that another session made, when `./claim` runs, then stderr carries FR42's first line and not
  the lock-held message, and the pre-existing `.lock` is still there afterwards. In
  `tests/claim.test.sh`. Red: the check placed after the lock is taken, which is no longer up front.
- [ ] AC75 *(0235)* — Given the tree after the change, when `tests/declared-copies.test.sh` and
  `tests/backlog-scripts-installed.test.sh` run, then both exit 0 and the first lists a
  `shared-branch` block in each of `claim`, `handoff`, `close` and `reopen`. Red: one copy edited
  alone, or one script left without the block.
- [ ] AC76 *(0235)* — Given the tree after the change, when the whole suite runs as
  `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=init.defaultBranch GIT_CONFIG_VALUE_0=master` with
  `for t in tests/*.test.sh; do "$t" || exit 1; done`, then it exits 0. Red: any fixture left on
  git's default branch (FR57).
- [ ] AC77 *(0235)* — Given `references/CONCURRENCY.md` and `CHANGELOG.md` after the change, when verify reads
  them, then the section FR43 names sits directly after *A second checkout never writes the
  backlog* and states the refusal, FR55's order and the `shared_branch:` fix, and `## Unreleased`
  carries FR58's line. Checked by reading, not by a guard (`CLAUDE.md`, *Tests*).
- [ ] AC78 *(0237)* — Given a fixture backlog whose row is at `next: verify`, `status: ready` and unheld,
  when `./claim <id>` and then `./handoff <id> <token> design` run, then both exit 0. The item
  then reads `next: design` and `status: ready` with `claimed_by:` empty, the row's Next and
  Status cells read `design` and `ready`, the last two commits are `Claim <id> [<token>]` and
  `Hand off <id> to design [<token>]`, and `git status --porcelain` is empty. This is in
  `tests/handoff.test.sh`. It is a regression guard: it is green at baseline (FR59). Red-making
  input: `handoff` refusing a `verify -> design` move, or leaving the claim held.
- [ ] AC79 *(0237)* — Given the same fixture with the row already held by another token, when
  `./claim <id>` runs, then it exits non-zero and the item, the row and `git log` are unchanged.
  This is in `tests/handoff.test.sh` or `tests/claim.test.sh`, beside AC78. Red-making input: a
  claim that takes a held verify row.
- [ ] AC80 *(0237)* — Given `skills/queue/SKILL.md` after the change, when verify reads Step 1, then
  one routing row names the trigger (the user overturns the decision on an open `next: verify`
  ticket), the two commands in order, the dated Notes line, the restored `## Open design question`,
  and stopping when `./claim` refuses. Also, `references/CONCURRENCY.md` and
  `skills/verify/SKILL.md` state nothing that FR60 forbids. Checked by reading, not by a guard
  (`CLAUDE.md`, *Tests*).
- [ ] AC81 *(0155)* — Given an open row whose `expects:` entry names a missing path and carries `# new`,
  when `./next --drift` runs, then no `expects:` DRIFT line names that row. The same is true for
  `# new — created by S8`. For `# renewed`, the line is printed. This is in `tests/next.test.sh`.
  Red-making input: no exemption, or an exemption that matches `new` anywhere in the comment.
- [ ] AC82 *(0155)* — Given open rows whose `expects:` holds an existing path, a glob that matches one
  file, and a glob that matches none, and a `DONE.md` row whose item expects a missing path, when
  `./next --drift` runs, then only the glob matching none is reported, in FR61's form. Red-making
  input: a glob compared as a literal path, or a closed row checked.
- [ ] AC83 *(0155)* — Given AC28's fixture, when `./next --drive` runs, then it exits 4 and prints the
  same `expects:` DRIFT line that `--drift` prints. When `./next --help` runs, the `--drift` usage
  text names the class. This is in `tests/next.test.sh`. Red-making input: the class added to
  `--drift`'s own path and not to `drift_report`.
- [ ] AC84 *(0155)* — Given the tree after the change, when the whole suite runs as
  `for t in tests/*.test.sh; do "$t" || exit 1; done`, then it exits 0, and the *0142 FR3* case
  still counts three drifted rows. Then `./next --drift` on this repo's live backlog names no
  `expects:` entry of 0242. Red-making input: any fixture helper left writing a missing, unmarked
  path (FR64), or 0242's `.claude/backlog/*` entries left in place (FR65).
- [ ] AC85 *(0155)* — Given `skills/queue/templates/item.md` and `CHANGELOG.md` after the change, when
  verify reads them, then the `expects:` comment states FR66's `# new` rule, and `## Unreleased`
  carries FR66's upgrade line. Checked by reading, not by a guard (`CLAUDE.md`, *Tests*).
- [ ] AC86 *(0236)* — Given a fixture whose in-scope row 0001 is at `next: queue` / `ready`, when
  `./next --drive --scope 0001 --completed design:0001` runs, then it exits 0, prints
  `DISPATCH  queue 0001` and a NOTE naming `design`, and prints no `ESCALATE` line. This is in
  `tests/next.test.sh`. Red-making input: today's arm, which keys on `verify` or `develop` only.
- [ ] AC87 *(0236)* — Given the same fixture with `--bounces 0001=<n>` past `bounce_max`, when
  `./next --drive` runs after `design:0001`, then it exits 4 with the `bounce_max` ESCALATE line.
  Given the row out of scope, it escalates as today. Given `--completed queue:0001`, it reaches the
  stale-contract ESCALATE line (0234 FR14 kept). This is in `tests/next.test.sh`. Red-making
  input: the `design` arm without the bound, or without the scope check, or keyed on any completed
  stage.
- [ ] AC88 *(0236)* — Given `skills/design/SKILL.md` after the change, when verify reads Step 4,
  then it states FR68 (the subsection heading and its four entry fields, `./handoff … queue`,
  own-slice consequences written by design) and FR70's handling of an FR that directs a write to
  another item, and it permits no write to an unheld sibling. Checked by reading, not by a guard
  (`CLAUDE.md`, *Tests*).
- [ ] AC89 *(0236)* — Given `skills/queue/SKILL.md` after the change, when verify reads Step 1 and
  Step 2, then one routing row carries FR69's re-read, the holistic check, and outcomes (a), (b)
  and (c), each with its commands in order, plus the `resolved` marking and the hand-off target.
  Step 2 also states FR70. Checked by reading, not by a guard.
- [ ] AC90 *(0236)* — Given `references/CONCURRENCY.md`, `skills/sprint/SKILL.md` and
  `CHANGELOG.md` after the change, when verify reads them, then *A stage writes only the ticket it
  holds* still names exactly one exception and states FR71 once, sprint's routing prose names
  `design` beside `verify` and `develop` for an in-scope dispatch to `queue` (FR72), and
  `## Unreleased` carries FR73's line. No other skill or reference permits a stage to write an
  item it does not hold. Checked by reading, not by a guard.
- [ ] AC91 *(0236)* — Given the tree after the change, when the whole suite runs as
  `for t in tests/*.test.sh; do "$t" || exit 1; done`, then it exits 0. When `./next --help`
  runs, the `--drive` text names `design` as a stage whose hand-off to `queue` is dispatched in
  scope. This is in `tests/next.test.sh`. Red-making input: the usage text left naming only
  `verify` and `develop`.


## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [x] S1 — `claim` and `next` read `expects:` and `touches:` through one parser, agree on what blocks a take, and `claim` writes an empty `touches:` key when it seeds nothing (0215, 0225, 0155) — discharges AC18, AC19, AC20, AC21, AC22, AC23, AC24, AC25, AC26, AC27, AC29
- [x] S2 — the three places the scripts answer the wrong question (0066) — discharges AC30, AC31, AC32, AC33, AC34, AC35, AC36, AC37, AC38, AC39, AC40
- [x] S3 — `next` reports a closed item still carrying a token, says an empty queue is empty, and lists the findings entries (0229, 0230, 0227) — discharges AC41, AC42, AC43, AC44, AC45, AC46, AC47, AC48, AC49, AC50, AC51
- [x] S4 — `handoff` records a blocker without leaving drift that stops a driver (0156) — discharges AC52
- [x] S5 — a note written below the last AC no longer changes that AC's digest (0217) — discharges AC56, AC57, AC58, AC59, AC60, AC61, AC62
- [x] S6 — `reopen` of a develop self-close leaves a ticket verify can close (0219) — discharges AC63, AC64, AC65
- [x] S7 — `claim`, `handoff`, `close` and `reopen` refuse up front when run off the branch the backlog is shared on (0235) — discharges AC66, AC67, AC68, AC69, AC70, AC71, AC72, AC73, AC74, AC75, AC76, AC77
- [x] S8 — `./capture` with its restamp form, the shared lock, commit and refusal behaviour, and its install — discharges AC1, AC2, AC3, AC4, AC5, AC12
- [x] S9 — `./park`, with the public-repo screen — discharges AC6, AC7, AC8
- [x] S10 — `./rank` and `./withdraw` — discharges AC9, AC10, AC11
- [x] S11 — `./drain`, on `0227`'s listing, and the ten-script sync — discharges AC13, AC14, AC15
- [ ] S12 — `queue` sends an open verify ticket back to design with `./claim` then `./handoff … design`, named in its Step 1 (0237; FR44, FR45, FR59, FR60) — discharges AC78, AC79, AC80
- [ ] S14 — the seven skills, `CONCURRENCY.md` and the CHANGELOG move onto the scripts, and every step that commits a sweep runs the privacy guard (0118) — discharges AC16, AC17, AC53, AC54, AC55
- [ ] S15 — `--drift` and `--drive` report an `expects:` path that exists nowhere unless it is marked `# new`, through the shared check; fixtures and this item's own `expects:` are corrected (0155; FR22, FR61–FR66) — discharges AC28, AC81, AC82, AC83, AC84, AC85
- [ ] S13 — design records sibling consequences and hands to `queue`, which folds them in, reopens a done sibling, or sends the decision back, and `--drive` dispatches that pass (0236; FR67–FR73) — discharges AC86, AC87, AC88, AC89, AC90, AC91


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

### Leg S2 re-verify — verify `c7d1`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `35cbff5` (the claim commit over `3c31f0e`; AC30 fix at `66afa28`).
Copy executed: the repo templates (`tests/claim.test.sh` runs `skills/queue/templates/claim`);
`.tickets/claim` is byte-identical to the template (`cmp`). The session's skills came from the
0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.

**Whole suite:** 45 files, every one rc=0. Tallies pasted: `tests/claim.test.sh` `195 passed, 0 failed`;
`tests/next.test.sh` `752 passed, 0 failed`; `tests/close.test.sh` `330 passed, 0 failed`;
`tests/backlog-scripts-installed.test.sh` `55 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`; `tests/handoff.test.sh` `250 passed, 0 failed`.

**Clause table.** AC31–AC40 reuse verify `357a`'s table above unchanged. Each of those rows reddened
under its own mutation then, and `66afa28` touches only the `--touches` message branch of `claim` and
one new case. AC30 was re-run. Mutations ran in a scratch clone of `35cbff5`, never in the shared
tree. Each substitution was scoped to the `if [ -n "$TOUCHES_GIVEN" ]` block and had to match exactly
once there. The diff was confirmed non-empty, then restored with `git checkout --` on that path
alone. Control after restore: `195 passed, 0 failed`.

| AC | Clause | Mutation in `skills/queue/templates/claim` | Result |
|---|---|---|---|
| AC30 | Given a claim on a `next: verify` row, **with `--touches`** / claim succeeds / message does not instruct setting `touches:` | gate removed, `widen it …` printed ungated (MA3) | red: `no instruction: widen it`, `says verify holds no file scope` (`193 passed, 2 failed`) |
| AC30 | the same / object: no *set* instruction | else branch prints `…; set it in $item` (MA4) | red: `no instruction: set it in` (`194 passed, 1 failed`) |
| AC30 | Given a `next: verify` row, without `--touches` | 357a's MA1, MA2 (branch unchanged by `66afa28`) | red then, reused |
| AC31–AC40 | as 357a's table | as 357a's table | red then, reused |
| AC37 | whole suite | the run above | 45/45 rc=0 |

The 357a FAIL probe now prints `verify holds no file scope, so nothing here asks you to change it`,
and the new case `0242 AC30 — nor when the verify claim is given --touches` asserts it.

**A mutation that stayed green, published, not covered.** (MC) `"$BUILDS" -eq 1` → `-eq 9` in the
`--touches` block, so a **develop** claim given `--touches` loses its `widen it` line: `195 passed,
0 failed`. AC31's Given names no `--touches`, and its own branches reddened under MB1/MB2. So AC31
is not left unverified, but no case pins a develop `--touches` claim's instruction.

**NFR rows bearing on S2:** unchanged from 357a's record. `66afa28` adds no log field, analytics
event or egress, and nothing company-specific. Its commit carries the trailer.

### Leg S3 — verify `2138`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `76ba642` (the claim commit over `c58383f`; S3 built at `53897af`).
Copy executed: the repo template (`tests/next.test.sh` runs `skills/queue/templates/next`, its
`NEXT_SRC`). `.tickets/next` is byte-identical to it (`cmp`). The session's skills came from the
0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.
Claim: bare `./claim 0242` died with `.tickets/claim: 149: xxd: not found` before the lock, so nothing
was written. It was re-run as `./claim 0242 2138`, with a python3-minted token. This is already in
`FINDINGS.md` (verify `357a`).

**Whole suite:** 45 files. 44 were rc=0 on the first pass. `tests/next.test.sh` read
`781 passed, 2 failed` there, in `0060 AC10` (`counts both buffers — 2 + 3`, `names the tools
buffer's own count`). That red was self-inflicted: it ran beside this session's parallel mutation
worktrees, and that fixture's tools buffer is the shared `/tmp/toolsrepo` (`tests/next.test.sh:681`;
parked in `FINDINGS.md`). Re-run alone in the checkout, with nothing beside it: `783 passed,
0 failed`. That is the control. Other tallies, pasted: `tests/backlog-scripts-installed.test.sh`
`55 passed, 0 failed`; `tests/findings-buffer.test.sh` `46 passed, 0 failed`;
`tests/skill-size.test.sh` `45 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`; `tests/claim.test.sh` `195 passed, 0 failed`;
`tests/close.test.sh` `330 passed, 0 failed`; `tests/handoff.test.sh` `250 passed, 0 failed`.

**Clause table and mutations, all run in this session.** Each mutation went into its own detached
worktree of `76ba642`, into `skills/queue/templates/next` (the copy the harness runs). The substitution
had to match exactly once, `git diff --shortstat` was confirmed non-empty, and each worktree was then
removed. M1, M2, M4, M6 and M10 ran in parallel. Their fail sets hold only S3 cases, with no `0060`
noise. M3, M5, M7, M8, M9 and M11 ran one at a time after the control.

| AC | Clause (AC text) | Mutation | Result |
|---|---|---|---|
| AC41 | Given a `status: done` item with `claimed_by: "ab12"` and no `QUEUE.md` row / exits non-zero / one DRIFT line naming id, `done`, `ab12` | M1: status case `done\|withdrawn\|rejected` → `closedX` (the class never fires) | red: `exits non-zero`, `one DRIFT line`, `names id, status, token` ×3 statuses (`774 passed, 9 failed`) |
| AC42 | the same at `withdrawn`, **and again** at `rejected` / each reported the same way | M2: status case narrowed to `done` | red ×2 statuses, 3 each (`777 passed, 6 failed`) |
| AC43 | Given a `done` item with an **empty** `claimed_by:` **and no other drift** / no DRIFT line / exit 0 | M3: the empty-token skip deleted | red: `exits 0`, `no DRIFT line`, plus seven `--drive`/`--drift` cases elsewhere whose fixtures carry closed items with empty tokens (`773 passed, 10 failed`) |
| AC44 | `--help`'s `--drift` line names a closed item keeping a token | M4: `keeping a token` → `with a token` in `usage()` | red: `names the class` (`782 passed, 1 failed`) |
| AC45 | header and no rows / `ROW 1:` exactly `ROW 1:     none — the queue holds no rows` | M5: the line's text shortened to `none` | red: `ROW 1 reads none` (`782 passed, 1 failed`) |
| AC46 | one row `0001 \| Fixture row \| develop \| ready` / `ROW 1:` is that row | M6: `if [ -z "$row1" ]` → `if true` | red: `ROW 1 is the row`, and four older ROW 1 cases (`778 passed, 5 failed`) |
| AC47 | FR40's fixture / exactly two lines / the two entries' line numbers / **neither** preamble line | M7: `!body { next }` removed from the shared awk program (the AC's own *Red:*, and the Testing (0227) NFR row's) | red: `exactly two lines`, `not the fenced example` (`779 passed, 4 failed`) |
| AC48 | the same fixture / `--findings`'s count equals AC47's line count / one fixture, one case | M8: the preamble skip disabled in `list` mode only, so the count keeps it and the listing does not (the AC's *Red:*) | red: `the count equals the listing's line count` (`778 passed, 5 failed`) |
| AC49 | a `- ` line with no date / printed marked `MALFORMED` / with its line number | M9: the MALFORMED printf gated off in `list` mode | red: `at line 14` (`782 passed, 1 failed`) |
| AC50 | both copies of `next` / `tests/backlog-scripts-installed.test.sh` passes | M11: a template-only edit inside `--findings-list` (the AC's *Red:*) | red: `next has diverged from skills/queue/templates/next` (`54 passed, 1 failed`) |
| FR36 | for **every** buffer `--findings` counts | M10: `$TOOLS_FINDINGS` dropped from the listing's loop | red: `three lines, both buffers`, `the tools entry, by its own path` (`781 passed, 2 failed`) |
| AC51 | whole suite | the run above | 45/45 green, with `tests/next.test.sh` green when run alone |

The plural rows have fixtures with at least two differing items. AC42 is one loop over three
statuses, and M2 reddened two of them. FR36 has two buffers, and M10 reddened the second. No
mutation stayed green.

**FR38, FR39, read:** FR38 names `.claude/backlog/next`, which does not exist in this repo. The
installed copy here is `.tickets/next` (0228), and it is byte-equal to the template. Recorded as drift
in FR38's wording, not a failure: AC50 is the assertion, and it holds. FR39's two paragraphs, in
`skills/retro/SKILL.md` Step 4 and `skills/queue/SKILL.md` Step 5, name `./next --findings-list` as how
a sweeper enumerates entries, in place of the header's pattern. Both were added rather than rewrapped,
and both are unguarded by design (*Out of scope*, from 0227).

**NFR rows bearing on S3:** Documentation (0229) is guarded by AC44's case, red under M4. Testing
(0227), "proven red … under a mutation of the shared awk program", is guarded: M7 is that mutation,
and it reddened AC47. The other rows belong to other slices. Always-on pass: no log field, analytics
event, egress, credential or UI. Nothing company-specific. `53897af` carries the trailer. Newly
reachable: `--drive` now escalates on class 8. `.tickets/next --drift` is clean on this backlog, as
develop recorded.

### Leg S4 — verify `e297`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `888486e` (the claim commit over `83496c7`; S4 built at `933484b`).
Copy executed: the repo template (`tests/handoff.test.sh` runs `skills/queue/templates/handoff`, its
`HANDOFF_SRC`, and copies `skills/queue/templates/next` into the fixture). `.tickets/handoff` is
byte-identical to the template (`cmp`). The session's skills came from the 0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.
Claim: `./claim 0242 e297`, with a python3-minted token (bare `./claim` dies on `xxd`, already parked).

**Whole suite:** 45 files, 45 rc=0 in one pass. Tallies, pasted: `tests/handoff.test.sh`
`268 passed, 0 failed`; `tests/next.test.sh` `783 passed, 0 failed`;
`tests/backlog-scripts-installed.test.sh` `55 passed, 0 failed`; `tests/declared-copies.test.sh`
`declared-copies: 23 passed, 0 failed`; `tests/claim.test.sh` `195 passed, 0 failed`;
`tests/close.test.sh` `330 passed, 0 failed`; `tests/reopen.test.sh` `reopen: 78 passed, 0 failed`.

**Clause table and mutations, all run in this session.** Each mutation went into its own detached
worktree of `888486e`, into `skills/queue/templates/handoff` (the copy the harness runs). Each
substitution matched exactly once, `git diff --shortstat` was non-empty, every run ended on its
sentinel, and the worktrees were removed. `tests/handoff.test.sh` fixtures are per-run `mktemp`, so
the parallel runs share nothing.

| AC52 clause (verbatim) | Mutation | Result |
|---|---|---|
| (the AC's *Red-making input: today's handoff*) | M0: the template replaced with its `9bb2de1` (pre-S4) bytes | red: `260 passed, 8 failed` — row, item, derived message, `--drift exits 0`, `--drift reports nothing` ×2, `--drive does not escalate` |
| Given a held fixture item whose `blocked_by` names an open ticket | M1: `\|\| WRITE_STATUS=blocked` → `\|\| true` | red: `261 passed, 7 failed` (row, item, `--drift` ×3, `--drive`) |
| … names an **open** ticket (open = not done, as `next` reads it; no item file is open) | M2: a missing item file not counted open | red: `266 passed, 2 failed` (row, `--drift reports nothing for the row`) |
| … **open** (a done blocker is not open) | M3: `= "done"` → `= "doneX"` | red: `266 passed, 2 failed` (row reads `ready`, says nothing about a blocker) |
| when `./handoff` runs (FR41: written as the derived cache, a `waiting` hand-off left as written) | M4: derivation applied to every status | red: `267 passed, 1 failed` (row reads `develop \| waiting`) |
| then `./next --drift` — drift reports nothing for that row | M6, at the outcome's altitude: the row writer AND its read-back both use the asked status, so the item says `blocked`, the row `ready`, and the script's own check is satisfied | red: `262 passed, 6 failed` — `--drift exits 0`, `--drift reports nothing for the row` ×2, `--drive does not escalate on drift`, row ×2. The `--drift` and `--drive` assertions red on their own, not only the row-shape one |
| and `--drive` does not escalate on it | M6 (above), and M1 | red in both |
| (read-back guard) | M5: row writer only uses the asked status | red: `256 passed, 12 failed` (the read-back refuses, so `exits 0` fails) |
| QA plan: `tests/backlog-scripts-installed.test.sh` covers `handoff` | template-only edit (`# drift` appended) | red: `handoff has diverged from skills/queue/templates/handoff` (`54 passed, 1 failed`) |

No mutation stayed green. The Given is singular, so no two-item fixture is owed; the "open"
qualifier was split into its two directions (M2, M3).

**NFR rows bearing on S4:** Testing (0156), "the case runs the real hand-off then `--drift`, in
fixture": guarded. `blocked_fixture` runs the real `handoff` and then the fixture's own `next`
on one fixture, and M6 reddened the `--drift` assertion through that path. The other rows belong to
other slices. Always-on pass: no log field, analytics event, egress, credential or UI. Nothing
company-specific. `933484b` carries the trailer. Newly reachable: a `ready` hand-off to any stage now
writes `blocked` over an open blocker. That matches `next`'s `derived_of`, and `close`'s reconcile
selects exactly `blocked` dependents, so the row is freed when the blocker closes. `blocked` stays
refused as an argument (FR2 cases green). Develop's `CHANGELOG.md` note for S4 is under
`## Unreleased` and is the note.

**Hand-off:** pass. S5, the next slice, is `unspecified`, and `skills/queue/templates/item.md`
sends such a ticket to `design`. But `.tickets/handoff 0242 e297 design --slice S4` was refused
(`refusing --slice on a verify -> design hand-off: a leg ends develop -> develop, develop -> verify,
or verify -> develop (the leg passed); nothing was changed`). A design hand-off without `--slice`
would leave the passed S4 unticked. So this leg hands back `./handoff 0242 e297 develop --slice S4`,
which ticks S4. develop then finds S5 `unspecified`, which is `design`'s (`skills/develop/SKILL.md`),
and forwards the ticket. Parked in `FINDINGS.md`.

### Leg S5 — verify `80c2`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `22d8e02` (the claim commit over `0bbddf6`; S5 built at `ee2e63d`).
Copy executed: the repo template (`tests/ac-digest.test.sh` copies `skills/queue/templates/next`
into each fixture). `.tickets/next` is byte-identical to the template (`cmp`). The session's skills
came from the 0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.
Claim: `./claim 0242 80c2`, with a python3-minted token.

**Whole suite:** 45 files, 45 rc=0 in one pass. Tallies, pasted: `tests/ac-digest.test.sh`
`ac-digest: 54 passed, 0 failed`; `tests/backlog-scripts-installed.test.sh` `55 passed, 0 failed`;
`tests/next.test.sh` `783 passed, 0 failed`. This run at `22d8e02` is also the control for every
mutation below, which ran in detached worktrees of that commit and never touched the checkout.

**Clause table and mutations, all run in this session.** Each mutation went into its own detached
worktree, into `skills/queue/templates/next` (the copy the harness runs). Each substitution matched
exactly once (asserted), `git diff --shortstat` was non-empty, and every run printed its tally.

| AC | Clause (verbatim) | Mutation | Result |
|---|---|---|---|
| AC56 | Given a fixture item stamped with FR50's digest, whose last criterion is followed by a blank line and then a column-0 note | M1: the new-mode end rule deleted (today's normalisation) | red: `50 passed, 4 failed` — `--check exited 1 … changed: AC2`, `--check printed: … changed: AC2` |
| AC56 | when the note's text is edited … then it exits 0 and prints `ac_digest matches` | M1, and M6 (`ac_digest_of` computes legacy) | red in both, same two assertions |
| AC57 | when an indented continuation line of its last criterion is edited, then `--check` exits 1 and names that criterion as `changed:` | M2: a rule ending every criterion at its label line | red: `47 passed, 7 failed` — `--check exited 0: 9956: ac_digest matches`, `does not name AC2` |
| AC58 | a criterion whose text runs on after a blank line as an indented line (0161 AC1's shape) … names the criterion | M3: a rule ending a criterion at a blank line | red: `51 passed, 3 failed` — `AC1's digest does not include its Red: line`, `--check exited 0: 9958`, `does not name AC1` |
| AC59 | Given a fixture item stamped with the legacy digest … `--check` exits 0 | M4: FR51's legacy acceptance removed from `ac_digest_diff` | red: `51 passed, 3 failed` — `--check exited 1`, `--check printed`, `--drift reports 9959` |
| AC59 | and `./next --drift` prints no `ac_digest` line for it | M7: legacy argument dropped from the `--drift` call only, `--check` keeps it | red: `53 passed, 1 failed` — `--drift reports 9959: DRIFT 9959 \| ac_digest differs … changed: AC2`. The drift half is guarded on its own |
| AC60 | when the last criterion's own label-line text is edited, then `--check` exits 1 and names it | M5: a legacy comparison that accepts any value | red: `39 passed, 15 failed` — AC60 `--check exited 0: 9959`, `does not name AC2`, plus AC57, AC58, 0195 AC3/AC4/AC6 |
| AC61 | the value it prints for the trailing-note criterion differs from the legacy digest and equals FR50's digest | M6: `ac_digest_of` stamps the legacy form; M1 | red in both: `AC2 is f2393ef4, FR50's is b46d92a1`, `AC2 is the legacy digest`. Expected values are `crc` over literal text in the test, not read back from `next` |
| AC62 | `tests/backlog-scripts-installed.test.sh` … passes. Red: an edit to the template alone | `# mutation` appended to the template only | red: `next has diverged from skills/queue/templates/next` (`54 passed, 1 failed`) |
| AC62 | `.tickets/next --ac-digest 0242 --check` … passes | in a worktree, AC1's `0008` edited to `0009` in this item | red: `0242: ac_digest differs from the criteria on disk — changed: AC1`, rc=1. Unedited, on the checkout: `0242: ac_digest matches` |

No mutation stayed green. No AC in S5 carries a plural or quantifier over fixture items, so no
two-item fixture is owed.

**FR51 read:** `close` calls `$DIR/next --ac-digest <id> --check` (`skills/queue/templates/close`,
the digest block), so it inherits the legacy acceptance, and M5 reddened 0195 AC6's close refusal
through that path. The legacy computation sits beside the new one, named as legacy, with a comment
naming 0242 S5. `--ac-digest <id>` prints only the new form (M6 reds it). FR52: `cmp` equal.

**NFR rows bearing on S5:** none of the table's rows is S5's. Always-on pass: no log field,
analytics event, egress, credential or UI. Nothing company-specific. `ee2e63d` carries the trailer.
Newly reachable: a column-0 line inside `## Acceptance criteria` no longer belongs to any digest,
so an edit there is not reported. That is FR50's stated intent, and design `b7a4` scanned every item
and found only notes in that position. `CHANGELOG.md` `## Unreleased` carries develop's S5 note,
which is the note.

**Drift recorded, not a failure:** the QA plan's "S5 is prose, read rather than grepped" predates
the renumbering, as develop recorded. AC56–AC62 are fixture-scripted and were run as such.

**Hand-off:** pass. `./handoff 0242 80c2 develop --slice S5`. S6 is specified (AC63–AC65).

### Leg S6 — verify `f5e3`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: ../ai-building-conventions
Level: `unit` (frontmatter). Command, `commands.unit_by_file` verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`, each file's rc and last line recorded.
Subject: the checkout at `329ffc6` (the claim commit over `8950797`; S6 built at `b9e6303`).
Copy executed: the repo template (`tests/reopen.test.sh` copies `skills/queue/templates/reopen`,
`claim` and `close` into each fixture). `.tickets/reopen` is byte-identical to the template (`cmp`).
The session's skills came from the 0.9.50 install.
Dirty set at Step 2: empty. Fresh capture after the last check: empty. Intersection: empty.
`./next --ac-digest 0242 --check`: `0242: ac_digest matches`.
Claim: `./claim 0242 f5e3`, with a python3-minted token.

**Whole suite:** 45 files, 45 rc=0 in one pass. Tallies, pasted: `tests/reopen.test.sh`
`reopen: 94 passed, 0 failed`; `tests/close.test.sh` `330 passed, 0 failed`;
`tests/backlog-scripts-installed.test.sh` `55 passed, 0 failed`; `tests/next.test.sh`
`783 passed, 0 failed`. This run at `329ffc6` is the control for every mutation below, which ran
in detached worktrees of that commit and never touched the checkout.

**Clause table and mutations, all run in this session.** Each mutation went into its own detached
worktree, into `skills/queue/templates/reopen` (the copy the harness runs). Each substitution
matched exactly once (asserted), `git diff --shortstat` was non-empty, and every run printed its
tally.

| AC | Clause (verbatim) | Mutation | Result |
|---|---|---|---|
| AC63 | Given a fixture item at `status: done` recording `close_by: develop` and `qa_level: unit`, with a `DONE.md` row | — | fixture (`scaffold` + `set_close_by 'close_by: develop'`) |
| AC63 | then the item reads `close_by: verify` | M1b: awk reset line and the `close_by` read-back both removed | red: `90 passed, 4 failed` — `the item reads close_by: verify`, `no longer reads close_by: develop`, AC64's two |
| AC63 | the last line of `## Notes & decisions` contains … `fixture reason` | M6: the reset branch overwrites the note, dropping the reason | red: `93 passed, 1 failed` — `the last notes line carries the reason` |
| AC63 | … and `close_by: develop → verify` | M2: the note suffix removed | red: `93 passed, 1 failed` — `the last notes line records the reset` |
| AC63 | `git show --name-only HEAD` lists exactly the item, `QUEUE.md` and `DONE.md` | M5: reopen also edits and commits `config.yml` | red: `92 passed, 2 failed` — AC63's and AC1's exact-three-files assertions |
| AC64 | then it exits 0 and never prints `the stage that may close it is 'develop'` | M1b (FR53 omitted) | red: `./close exits 0`, `it never names develop as the closing stage` |
| AC65 | the first still reads `close_by: verify` | M3: the reset flag set whatever the value | `close_by: verify` item: green — a `verify`→`verify` rewrite is observably the right outcome, not a gap; the no-key item reds through the read-back (`67 passed, 27 failed`, `the reopen did not apply to: close_by`) |
| AC65 | the second still has no `close_by:` line | M4: awk writes `close_by: verify` at the frontmatter end when no key was seen | red: `93 passed, 1 failed` — `no close_by: — still has no close_by: line` |

No mutation left an AC's named outcome standing. AC65's plural is covered by two fixture items
differing in the value under test. M1 (awk reset removed, read-back kept) also reds, `86 passed,
8 failed`, through the read-back refusal, matching develop's table; develop's M3 recorded a red on
the `verify` item's note that this session's M3 (flag only) does not reproduce, and the AC's outcome
there holds under both.

**FR53 read:** `close_by` is read by `fm_value`, the reader `close` uses. The reset rides the same
locked commit (M5's control assertion). **FR54:** header bullet present; `cmp` equal.

**NFR rows bearing on S6:** none of the table's rows is S6's. Always-on pass: no log field,
analytics event, egress, credential or UI. Nothing company-specific. `b9e6303` carries the trailer.
Newly reachable: a reopened develop self-close is now closable only by `verify`, which is FR53's
intent. `CHANGELOG.md` `## Unreleased` carries develop's S6 note, which is the note.

**Hand-off:** pass. `./handoff 0242 f5e3 develop --slice S6`. S7 is specified (AC66–AC77).

### Leg S7 — verify `27e9`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: `../ai-building-conventions`

**Subject:** `115bc34` (S7 code `9e76240`, docs `83364b8`), checkout on `main`. Step 2 capture
(`git status --porcelain`, fused onto the first run) was empty, so the dirty set is empty and the
intersection with the evidence set is empty: not advisory. Copy executed: the repo templates, which
the tests copy into fixtures. `.tickets/{claim,handoff,close,reopen}` `cmp`-equal to the templates.
`./next --ac-digest 0242 --check` → `0242: ac_digest matches`.

**Checked against the person's answer** (*S7 decision*, design `3708`): "refuse", and "a check up
front". Refuse, not warn: M11 (the function returns 0 after printing) reds claim, `206 passed, 11
failed`. Up front: the call sits directly after the linked-worktree refusal and before `mkdir "$LOCK"`
in all four templates (claim worktree→call→lock; handoff 200→244→266; close 148→192→237; reopen
124→167→184, read from the line numbers), and M10 (call moved after the lock) reds AC74.

**Commands, verbatim:**
- `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`) — 45 files, no file
  printed a non-zero failed count, none `ABORTED`.
- AC76: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=init.defaultBranch GIT_CONFIG_VALUE_0=master` then
  `for t in tests/*.test.sh; do "$t" || exit 1; done` — `AC76 loop exit 0`; probe under the same env:
  `probe default: master`.

**Clause table** (Given / predicate / object rows per AC):

| AC | Given | Predicate | Objects asserted |
|---|---|---|---|
| AC66 | repo on `main`, no key, no remote, after `git switch -c feature`, `ready` row | `./claim <id>` | exit 1; both stderr lines; commit count unchanged; `QUEUE.md` + item byte-identical (cksum of `.tickets`); no `.lock` |
| AC67 | row claimed on `main`, then `feature` | `./handoff <id> <token> develop` | exit 1; FR42 line names `feature` and `main`; `claimed_by:` kept; no commit; no `.lock` |
| AC68 | claimed on `main` with `## QA evidence`, then `feature` | `./close` | exit 1; FR42 line; row in `QUEUE.md`; absent `DONE.md`; no commit; no `.lock` |
| AC69 | done row, then `feature` | `./reopen <id> top "r"` | exit 1; FR42 line; row in `DONE.md`; absent `QUEUE.md`; no commit |
| AC70 | `shared_branch: trunk  # ours` | claim on `trunk` / on `main` | exit 0 / exit 1 naming `'main'` and `'trunk'` |
| AC71 | no key, `origin/HEAD` → `origin/develop` | claim on `develop` / on `main` | exit 0 / exit 1 naming `'develop'` |
| AC72 | AC71 plus `shared_branch: trunk` | claim on `trunk` / on `develop` | exit 0 / exit 1 naming `'trunk'` |
| AC73 | `main` after `git checkout --detach` | `./claim` | exit 1; `this checkout is on 'HEAD (detached)'` |
| AC74 | on `feature`, a foreign `.lock` present | `./claim` | FR42 first line; not the lock-held message; the foreign `.lock` still there |
| AC75 | tree after the change | `declared-copies` + `backlog-scripts-installed` run | both exit 0; a `shared-branch` block in each of the four (plural: 4 copies) |
| AC76 | tree after the change, `init.defaultBranch=master` | whole suite, fail-fast | exit 0 |
| AC77 | `CONCURRENCY.md`, `CHANGELOG.md` | read | section directly after *A second checkout never writes the backlog*; refusal; FR55 order; `shared_branch:` fix; `## Unreleased` line |

**Evidence (mutations run by this session by `python3` over the committed file, diff confirmed
non-empty, restored by path with `git checkout -- <path>`, tree clean after each; control
`tests/claim.test.sh` → `217 passed, 0 failed`):**

| AC | Checked by | Mutation | Result |
|---|---|---|---|
| AC66 | `tests/claim.test.sh` `0242 AC66` | M1 call removed from `skills/queue/templates/claim` | red `197 passed, 20 failed` (exits 1, names both branches, says nothing changed, no commit…) |
| AC66 (refuse ≠ warn) | same | M11 function `return 0` instead of `exit 1` | red `206 passed, 11 failed` (exits 1, byte-identical, no commit) |
| AC67 | `tests/handoff.test.sh` `0242 AC67` | M2 call removed from `handoff` | red `269 passed, 4 failed` (exits 1, FR42 line, claim kept, no commit) |
| AC68 | `tests/close.test.sh` `0242 AC68` | M3 call removed from `close` | red `331 passed, 5 failed` (row in QUEUE.md, absent DONE.md…) |
| AC69 | `tests/reopen.test.sh` `0242 AC69` | M4 call removed from `reopen` | red `reopen: 94 passed, 5 failed` |
| AC70 | `tests/claim.test.sh` `0242 AC70` | M5 key never read; M6 comment kept in value | red `211 passed, 6 failed`; red `215 passed, 2 failed` (`naming 'main' and 'trunk'`, `on trunk it exits 0`) |
| AC71 | `0242 AC71` | M7 `origin/HEAD` never read | red `214 passed, 3 failed` |
| AC72 | `0242 AC72` | M8 `origin/HEAD` read before the key | red `211 passed, 6 failed` |
| AC73 | `0242 AC73` | M9 empty branch returns 0 (read as match) | red `215 passed, 2 failed` |
| AC74 | `0242 AC74` | M10 call moved to after `mkdir "$LOCK"` | red `210 passed, 7 failed` (`prints FR42's first line`, `no lock exists`) |
| AC75 | `tests/declared-copies.test.sh`, `tests/backlog-scripts-installed.test.sh` | M12 one comment char in `handoff`'s block; M13 `reopen`'s markers renamed; M14 call removed from `.tickets/claim` only | M12 red `22 passed, 2 failed` (`block shared-branch differs …`); M13 red `22 passed, 2 failed` (`reports shared-branch: 4 copies`); M14 red `54 passed, 1 failed` (`claim has diverged`) |
| AC76 | AC76 command above | M15 `tests/claim.test.sh:59` back to `init -q`, run under the master env | red `110 passed, 107 failed`; unmutated run exits 0 |
| AC77 | read `references/CONCURRENCY.md` and `CHANGELOG.md` | — (prose, unguarded by design) | holds: `## The backlog is written on one branch` follows *A second checkout never writes the backlog* with nothing between; states refuse-never-warn, detached HEAD, up front at `./claim`, the order key → `origin/HEAD` → `main`, no fetch, the one-line `shared_branch:` fix, no override flag. `## Unreleased` carries the FR58 line including the upgrade note. |

**Not guarded (recorded, not a gap under any AC):** FR42's *before the lock* for `handoff`, `close`
and `reopen` is true by reading only. AC67/AC68's `no .lock remains` cannot see it, because each
script's EXIT trap removes its own lock; only `claim`'s position has a pre-existing-lock case
(AC74). No AC claims it for the other three, so no AC is unverified.

**NFR rows bearing on S7:** none of the table's rows is S7's. Always-on pass: no log field,
analytics event, egress, credential or UI. No home path added in the diff. Nothing
company-specific. `9e76240` and `83364b8` carry the trailer. Newly reachable: a checkout off the
shared branch can no longer write the backlog. That is FR42's intent, and the linked-worktree
refusal is unchanged. Live check: this session's `./claim 0242 27e9` on `main` succeeded
(`1630944`).

**Hand-off:** pass. `./handoff 0242 27e9 develop --slice S7`. S8 is next.

### Leg S8 — verify `26f6`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: `../ai-building-conventions`

**Subject:** `a4a4a09` (S8 code `bd65a89`, guard/README `90d357f`), checkout on `main`. The Step 2
capture (`git status --porcelain`, fused onto the first suite run) was empty. So the dirty set is
empty, its intersection with the evidence set is empty, and the verdict is not advisory. Copy
executed: the repo templates. `tests/capture.test.sh` runs `skills/queue/templates/capture` and
`next` in fixtures. `.tickets/capture` is `cmp`-equal to the template. `./next --ac-digest 0242
--check` → `0242: ac_digest matches`.

**Commands, verbatim:**
- `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`) — 46 files, each
  printing `N passed, 0 failed`, none `ABORTED`; `capture: 65 passed, 0 failed`.

**Clause table:**

| AC | Given | Predicate | Objects asserted |
|---|---|---|---|
| AC1 | `next_id: 5` while `items/` holds 0007 (and 0001, 0003) | `./capture draft.md above:0003` | `items/0008-*.md`; id `0008`; `next_id: 9`; row directly above 0003; one commit |
| AC2 | AC1's capture | `./next --ac-digest 0008` | output equals the item's `ac_digest:` line |
| AC3 | draft with no `- [ ] AC1 —` line | `./capture` | non-zero exit; no file written; `QUEUE.md`, `config.yml` byte-identical; no `.lock`; no commit |
| AC4 | another path staged before the run | `./capture` commits | path absent from the capture commit; still staged afterwards |
| AC5 | `above:9999`, no such row | `./capture` | refuses before minting; no `.lock`; no file changed |
| AC12 | unclaimed item whose AC2 text was edited | `./capture --restamp <id>` | `./next --drift` reports no digest mismatch for it |

**Evidence.** This session ran each mutation with `python3` over the committed
`skills/queue/templates/capture`, the copy the suite runs, and confirmed each diff was non-empty. Each
was restored with `git checkout -- skills/queue/templates/capture`, and `git status --porcelain` was
empty after each. Control `tests/capture.test.sh` → `capture: 65 passed, 0 failed`.

| AC | Checked by | Mutation | Result |
|---|---|---|---|
| AC1 (id, `next_id`) | `tests/capture.test.sh` `0242 AC1` | M1 mint from `next_id` − 1 (the AC's *Red*) | red `ABORTED before the tally: 4 passed, 6 failed so far` (`writes items/0008-<slug>.md`, `the item carries id 0008`, `sets next_id: 9`, `inserts the row directly above 0003`…) |
| AC1 (directly above) | same | M2 `above` inserts below the anchor | red `64 passed, 1 failed` (`inserts the row directly above 0003`) |
| AC1 (one commit) | same | M3 item committed separately first | red `63 passed, 2 failed` (`makes exactly one commit`) |
| AC2 | `0242 AC2` | M4 stamp a fixed stale digest, `ac_digest` read-back removed | red `64 passed, 1 failed` (`the item's ac_digest: line is ./next --ac-digest 0008's output`) |
| AC3 | `0242 AC3` | M5 draft AC1 check skipped (the AC's *Red*) | red `58 passed, 7 failed` (`exits non-zero`, `names what is wrong`, `writes no file … leaves no .lock`, `makes no commit`) |
| AC4 | `0242 AC4` | M6 `git add` the paths, then commit with no pathspec | red `63 passed, 2 failed` (`other.txt is absent from the capture commit`, `and is still staged afterwards`) |
| AC5 | `0242 AC5` | M7 anchor check removed and the row appended at the bottom on a miss (the AC's *Red*) | red `55 passed, 10 failed` (`exits non-zero`, `names the anchor`…) |
| AC5 (no `.lock`) | `0242 AC5`, `0242 AC1` | M8 cleanup no longer removes the lock | red `56 passed, 9 failed` (`changes no file and leaves no .lock`, `no .lock is left`) |
| AC12 | `0242 AC12` | M9 restamp writes the item's old stamp back, check removed (the AC's *Red*) | red `63 passed, 2 failed` (`after it, --drift reports no digest mismatch for 0003`, `--check agrees`) |
| FR4 (install) | `tests/backlog-scripts-installed.test.sh` | M10 one line appended to `.tickets/capture` | red `62 passed, 1 failed` (`capture has diverged from skills/queue/templates/capture`); restored `63 passed, 0 failed` |

**Not guarded (recorded, not a gap under any AC):** AC3's *leaves no `.lock`* holds by
construction. The draft check runs before `mkdir "$LOCK"`, so no mutation of the cleanup can reach
that path. The fingerprint does include `.lock`, so a refactor that took the lock first and leaked it
would red. AC2's literal *Red* ("stamp before the id is written") cannot be expressed through
`./next --ac-digest <id>`, which locates the item by its id. M4 breaks the AC's outcome instead, so
the stamp and the computed digest differ.

**NFR rows bearing on S8:** Testing, which the fixture cases cover. Documentation, met by the usage
header, the `usage:` refusal and `--help` (`0242 FR4` cases). Always-on pass: no log field,
analytics event, egress, credential or UI. The S8 diff adds no home path. Nothing is
company-specific. `bd65a89` and `90d357f` each carry the `Co-Authored-By` trailer. Newly reachable:
a backlog write that commits only by pathspec under the lock. It refuses off the shared branch
(`0242 FR56` case) and never breaks a held lock (`0242 FR1` case). No `CHANGELOG.md` note is owed
by this slice; S14 owns the CHANGELOG move. Develop's AC15 re-split from S8 to S11 changes no AC
text, and the digest matches.

**Hand-off:** pass. `./handoff 0242 26f6 develop --slice S8`. S9 is next.

### Leg S9 — verify `f34e`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: `../ai-building-conventions`

**Subject:** `e321f1f` (S9 code `e1b23af`, build notes `3f17bab`, hand-off `bd6971a`), checkout on
`main`. The Step 2 capture (`git status --porcelain`, fused onto the first suite run) was empty. So
the dirty set is empty, its intersection with the evidence set is empty, and the verdict is not
advisory. Copy executed: the repo templates. `tests/park.test.sh` runs `skills/queue/templates/park`
and `next` in fixtures. `.tickets/park` is `cmp`-equal to the template. `./next --ac-digest 0242
--check` → `0242: ac_digest matches`. Claim: `./claim 0242 f34e`, with a python3-minted token.

**Commands, verbatim:**
- `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`): 47 files, each printing
  `N passed, 0 failed`, none `ABORTED`. `park: 115 passed, 0 failed`.

**Clause table:** this is develop's S9 table, reused unchanged. Each AC's Given, predicate and every
object it names have a row.

| AC | Given | Predicate | Objects asserted |
|---|---|---|---|
| AC6 | a fixture buffer | `./park "what happened"` | exactly one line appended; head-token shape (`- YYYY-MM-DD — …`, the header's `Format:` line, read back via `./next --findings-list`); today's UTC date; one commit; naming only `FINDINGS.md` |
| AC7 | `--repo <second fixture checkout>` | `./park` runs | entry lands in the second repo; its commit lands there; first repo unchanged |
| AC8 | a second checkout whose `CLAUDE.md` profile marks it public | `./park` given an entry holding a real-shaped macOS or Linux home path (assembled) | exits non-zero; writes nothing; names the failing shape; the same entry redacted is written |

**Evidence.** This session ran its own mutations with `python3` over the committed
`skills/queue/templates/park`, the copy the suite runs. Each substitution asserted exactly one match,
and each diff was confirmed non-empty (`1 file changed`). Each was restored with `git checkout --
skills/queue/templates/park`. `git status --porcelain` was empty after the sweep, and the control
`tests/park.test.sh` → `park: 115 passed, 0 failed`.

| AC | Checked by | Mutation | Result |
|---|---|---|---|
| AC6 (date) | `tests/park.test.sh` `0242 AC6` | M1 write the entry without its date (the AC's *Red*) | red `105 passed, 10 failed` (`the line is '- <today, UTC> — what happened'`, `./next --findings-list counts it…`, `--findings now counts two`) |
| AC6 (today's date) | same | M2 a fixed 2020-01-01 date | red `106 passed, 9 failed` |
| AC6 (exactly one line) | same | M4 append the line plus a blank line | red `90 passed, 25 failed` (`appends exactly one line`…) |
| AC6 (commit names only FINDINGS.md) | `0242 FR2` | M3 `commit -a` in place of the pathspec | red `113 passed, 2 failed` (`other.txt is absent from the park commit`, `and is still staged afterwards`) |
| AC7 (lands in the second repo) | `0242 AC7` | M5 ignore `--repo` (the AC's *Red*) | red `75 passed, 40 failed` (`the entry is the second repo's last buffer line`, `one commit in the second repo`…) |
| AC7 (first repo unchanged) | same | M9 also append a line to the first repo's `FINDINGS.md` | red `107 passed, 8 failed` (`the first repo's backlog is byte-identical`, `and the first repo's tree is clean`) |
| AC8 (non-zero, writes nothing) | `0242 AC8` | M6 skip the guard (the AC's *Red*) | red `98 passed, 17 failed` (mac/linux/slug: `exits non-zero`, `writes nothing in the second repo`…) |
| AC8 (writes nothing on refusal) | same | M8 the refusal falls through instead of `exit 1` | red `104 passed, 11 failed` (`exits non-zero`, `writes nothing in the second repo`, `commits nothing in either`) |
| AC8 (names the failing shape) | same | M7 the macOS shape message replaced by `a path` | red `114 passed, 1 failed` (`mac: names the failing shape`) |
| FR4 (install) | `tests/backlog-scripts-installed.test.sh` | M10 one line appended to `.tickets/park` | red `70 passed, 1 failed` (`park has diverged from skills/queue/templates/park`); restored `71 passed, 0 failed` |

**NFR rows bearing on S9:**
- **Security and Privacy & data (AC8).** The screen holds and is guarded (M6, M8). Its pattern is
  `tests/measurement.test.sh`'s `HOME_PATH_PAT`, byte for byte, which a case asserts.
- **Testing.** Met by the fixture cases on the template copies.
- **Documentation.** Met by the usage header, the `usage:` refusal and `--help`.
- **Always-on pass.** There is no log field, analytics event, credential or UI. One egress-like
  path is new: a commit into another local checkout. It refuses on a linked worktree and off the
  destination's shared branch (`0242 FR56` case), and the lock is never broken (`0242 FR1` case).
  `e1b23af` carries the `Co-Authored-By` trailer. The diff adds no home path, and the
  measurement guard is green.
- **Newly reachable.** `--repo` writes into the conventions checkout. That repo is public, but its
  `## Profile` section does not say `public`, so park does not screen it. FR6 is satisfied
  literally, because it says "public per its `CLAUDE.md` profile". Develop's choice of marker is
  recorded in the S9 build notes, and develop already parked it (`c4e06f1`). It is not re-parked,
  and it is not a gap under any AC.
- **CHANGELOG.** No `CHANGELOG.md` note is owed by this slice. S14 owns the CHANGELOG move.

**Hand-off:** pass. `./handoff 0242 f34e develop --slice S9`. S10 is next.

### Leg S10 — verify `59fc`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: `../ai-building-conventions`

**Subject:** `bc48218` (S10 code `98b0179`, build notes `8772805`, hand-off `bc48218`), checkout on
`main`. The Step 2 capture (`git status --porcelain`, fused onto the first suite run) was empty. So
the dirty set is empty, its intersection with the evidence set is empty, and the verdict is not
advisory. The final capture, fused onto the last control run, was empty too. Copy executed: the repo
templates. `tests/rank.test.sh` runs `skills/queue/templates/rank`, and `tests/withdraw.test.sh`
runs `skills/queue/templates/withdraw` and `next`. `.tickets/rank` and `.tickets/withdraw` are
`cmp`-equal to the templates. `./next --ac-digest 0242 --check` → `0242: ac_digest matches`.
Claim: `./claim 0242 59fc`, with a python3-minted token.

**Commands, verbatim:**
- `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`): 49 files, each printing
  `N passed, 0 failed`, none `ABORTED`. `rank: 71 passed, 0 failed`, `withdraw: 87 passed, 0 failed`,
  `backlog-scripts-installed` `87 passed, 0 failed`.

**Clause table:** this is develop's S10 table, reused unchanged. Each AC's Given, predicate and every
object it names have a row.

| AC | Given | Predicate | Objects asserted |
|---|---|---|---|
| AC9 | rows A, B, C | `./rank C above:A` runs | order is C, A, B; every other line of `QUEUE.md` unchanged; one commit |
| AC10 | B `in-progress` under a token | `./rank B top` runs | refuses; changes nothing |
| AC11 | 0004 named in 0005's `blocked_by:` | `./withdraw 0004 "merged" --into 0006` runs | 0004's file stays; `status: withdrawn`; empty `next:`; a dated note; its row is gone; 0005's `blocked_by:` names 0006; `next_id` unchanged |

**Evidence.** This session ran its own mutations with a `python3` harness over the committed
templates, the copies the suites run. Each substitution asserted exactly one match, each diff was
confirmed non-empty, and each template was restored with `git checkout -- <that path>`. Where the
script's own read-back would have refused the broken output first, the read-back was disabled in
the same mutation, so that the AC's outcome itself was tested. `git status --porcelain` was empty
after the sweep. The controls gave `rank: 71 passed, 0 failed` and `withdraw: 87 passed, 0 failed`.

| AC | Checked by | Mutation | Result |
|---|---|---|---|
| AC9 (order C, A, B) | `tests/rank.test.sh` `0242 AC9` | R1 `above:` inserts below the anchor, read-back off | red `70 passed, 1 failed` (`the order is C, A, B`) |
| AC9 (order, the AC's *Red*) | same | R2 re-sort the table, read-back off | red `61 passed, 10 failed` (`the order is C, A, B`, `makes exactly one commit`…) |
| AC9 (every other line unchanged) | same | R3 drop the trailing prose line, read-back off | red `66 passed, 5 failed` (`every other line of QUEUE.md is unchanged, in its order`, `the line count is unchanged`) |
| AC9 (one commit) | same | R4 an extra empty commit after the rank | red `64 passed, 7 failed` (`makes exactly one commit`…) |
| AC10 (refuses, the AC's *Red*) | `0242 AC10` | R5 drop the claim check (cell and `claimed_by:`) | red `63 passed, 8 failed` (`exits non-zero`, `names why`, `changes no file and leaves no lock`) |
| AC10 (refuses) | same | R6 drop the Status-cell check only | red `70 passed, 1 failed` (`names why`). The fixture's B carries both the cell and a token, so the `claimed_by:` check still refuses. Only the message moved, and the outcome held. This is defence in depth, not a gap |
| AC10 (refuses) | same | R7 drop the `claimed_by:` check only | red `68 passed, 3 failed` (`exits non-zero`, `names the holder`…) |
| AC10 (changes nothing) | same | R8 the refusal appends to `QUEUE.md` before exiting | red `65 passed, 6 failed` (`changes no file and leaves no lock`) |
| AC10 (changes nothing) | same | R9 the refusal leaks the lock | red `65 passed, 6 failed` (same) |
| AC11 (file stays, the AC's *Red*) | `tests/withdraw.test.sh` `0242 AC11` | W1 delete the item file after the commit | red `80 passed, 7 failed` (`0004's item file stays`) |
| AC11 (`status: withdrawn`) | same | W2 write `status: done`, read-back off | red `85 passed, 2 failed` (`0004 is status: withdrawn`) |
| AC11 (empty `next:`) | same | W3 keep `next:`, read-back off | red `86 passed, 1 failed` (`0004's next: is empty`) |
| AC11 (a dated note) | same | W4 the note without its date | red `85 passed, 2 failed` (`0004 carries a dated note…`) |
| AC11 (a dated note) | same | W9 no note written, read-back off | red `85 passed, 2 failed` (same) |
| AC11 (row gone) | same | W5 keep the row, read-back off | red `82 passed, 5 failed` (`its row is gone`…) |
| AC11 (0005 names 0006, the AC's *Red*) | same | W6 leave 0005 on 0004, read-back off | red `75 passed, 12 failed` (`0005's blocked_by: names 0006`…) |
| AC11 (0005 names 0006) | same | W7 `--into` ignored, the entry dropped | red `83 passed, 4 failed` (`0005's blocked_by: names 0006`…) |
| AC11 (`next_id` unchanged) | same | W8 rewrite `next_id:` in `config.yml` | red `86 passed, 1 failed` (`next_id is unchanged (config.yml byte-identical)`) |
| FR4 (install) | `tests/backlog-scripts-installed.test.sh` | one line appended to `.tickets/rank` | red `86 passed, 1 failed` (`rank has diverged from skills/queue/templates/rank`); restored `87 passed, 0 failed` |

**NFR rows bearing on S10:**
- **Testing.** Met by the fixture cases on the template copies.
- **Documentation.** `./rank --help` and `./withdraw --help` both exit 0. Run bare, each refuses
  with its `usage:` line: `usage: rank <id> <top|above:<row-id>|below:<row-id>> [--ranking <file>]`
  and `usage: withdraw <id> <reason> [--into <absorbing-id>]`.
- **Always-on pass.** There is no log field, analytics event, egress, credential or UI. `98b0179`
  carries the `Co-Authored-By` trailer. The measurement guard (home paths) is green.
- **Newly reachable.** `withdraw` writes dependents' items, which are items it does not hold. It
  refuses a claimed dependent, leaves closed dependents alone, and keeps `waiting` as it is. All
  three are pinned by suite cases and recorded as decided in the S10 build notes. `rank` can move
  a row past an in-progress row, which queue Step 4 permits.
- **CHANGELOG.** No `CHANGELOG.md` note is owed by this slice. S14 owns the CHANGELOG move.

**Hand-off:** pass. `./handoff 0242 59fc develop --slice S10`. S11 is next.

### Leg S11 — verify `v5a1`, 2026-11-27 (sprint run-20261127T024025Z) — PASS, no AC ticked

Conventions: `../ai-building-conventions`

**Subject:** `b5d9310` (S11 code `636a1d2` and `d0db04d`, build notes `3bb8454`, hand-off
`b5d9310`), checkout on `main`, claim `2601b59`. The Step 2 capture (`git status --porcelain`, fused
onto the suite run) was empty. So the dirty set is empty, its intersection with the evidence set is
empty, and the verdict is not advisory. Copy executed: the repo templates. `tests/drain.test.sh` runs
`skills/queue/templates/drain` and `next`. `.tickets/drain` is `cmp`-equal to the template.
`./next --ac-digest 0242 --check` → `0242: ac_digest matches`. Claim: `./claim 0242` with no token
died at `.tickets/claim: 149: xxd: not found`, before the lock and with nothing written (parked as a
finding, `a6430e1`). `./claim 0242 v5a1` then landed.

**Commands, verbatim:**
- `for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`, each file's tail
  captured): 50 files, every one printing `0 failed`, none `ABORTED`. `drain: 96 passed, 0 failed`,
  `backlog-scripts-installed` `106 passed, 0 failed`, `backlog-location` `87 passed, 0 failed`,
  `declared-copies: 24 passed, 0 failed`, `citations` `52 passed, 0 failed`.

**Clause table:** develop's S11 table (in *S11 build notes*), reused unchanged. Each AC's Given,
predicate and every object it names have a row. No omission was found.

**Evidence and mutations.** All run by this session with a `python3` harness over the committed
copies the suites run. Each substitution asserted a match, each `git diff --stat` was non-empty, and
each file was restored with `git checkout -- <that path>`.

| AC / NFR | How checked | Mutation | Result |
|---|---|---|---|
| AC13 | `tests/drain.test.sh`, AC13 block, over the shipped `skills/queue/templates/FINDINGS.md` header | M1: the AC's red, `AT` from `grep -n "^- .*$DATE"` over the whole file | red: AC13 `exits 0` and `the real 2026-09-05 entry is gone` fail (the in-script header read-back refuses) |
| AC13 | same | M1b: M1 with the header read-back disabled | red: `the header is byte-identical`, `the header's fenced example is still there`; `drain: 86 passed, 10 failed` |
| AC14 "absent from FINDINGS.md" | `tests/drain.test.sh`, AC14 block | M2: the AC's red, `held` copies the buffer unchanged, line-count read-back off | red: `the entry is absent from FINDINGS.md`, `its continuation is absent`, `both changes are in it`; `drain: 92 passed, 4 failed` |
| AC14 "present verbatim" | same | M6: held copy keeps only the entry's first line, held read-back off | red: `it is present verbatim, last, in FINDINGS-HELD.md`; `drain: 95 passed, 1 failed` |
| AC14 "one commit" | same | M5: `FINDINGS-HELD.md` committed separately | red: `one commit`, `both changes are in it`; `drain: 93 passed, 3 failed` |
| AC15 "all ten … byte-equal" | `tests/backlog-scripts-installed.test.sh`, AC15 case | M4: the AC's red, the sync skips `drain` | red: `FAIL AC15 — drain is missing, not executable, or differs …`; `105 passed, 1 failed` |
| AC15 "config.yml, QUEUE.md and FINDINGS.md byte-identical" | same | M7: the sync copies every template file, not only the executables | red: `FAIL AC15 — the sync rewrote a project-owned file`; `105 passed, 1 failed` |
| NFR Migration / schema | AC15, above | M4, M7 | guarded |
| NFR Testing (0155), template copies | `tests/backlog-scripts-installed.test.sh` | appended a line to the installed `.tickets/drain` | red: `FAIL drain has diverged from skills/queue/templates/drain`; `105 passed, 1 failed` |
| NFR Documentation, usage | header comment, `drain_usage`, `--help` case in `tests/drain.test.sh` | read, not mutated | holds |
| Control | `tests/drain.test.sh`; `tests/backlog-scripts-installed.test.sh` after every restore | none | `drain: 96 passed, 0 failed`; `106 passed, 0 failed`; `git status --porcelain` empty |

- **AC15's guard runs a test-side rendering of Step 0's prose** (`step0_sync`), because Step 0's sync
  is a session following prose. It proves the template set carries the ten and that the rule as
  stated reaches each one. A change to the Step 0 sentence itself is invisible to it. That is
  inherent in a prose step, not a gap in this slice.
- **Always-on pass.** No log field, analytics event, egress, credential or UI. `636a1d2` and
  `d0db04d` carry the `Co-Authored-By` trailer. The S11 diff adds no real home path, and the fixture
  identity is `fixture@example.com`.
- **Newly reachable.** `drain held` creates `FINDINGS-HELD.md` and `git add`s that one path. An
  untracked held file that already exists is refused as another session's write. Both are pinned.
- **Observation, not a verdict input.** The commit retry loop in `drain` (and its siblings `park` and
  `close`) retries 30 times with no pause, so "retry briefly" lasts milliseconds against a held
  `.git/index.lock`. This was already true before S11.
- **CHANGELOG.** No note is owed by this slice. S14 owns the CHANGELOG move.

**Hand-off:** pass. `./handoff 0242 v5a1 develop --slice S11`. S12 is next and `unspecified`. Per
`templates/item.md` *Progress*, the next develop routes the ticket to `design`, and `./handoff
--slice` refuses a leg holding an unspecified slice.

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

### S3 build notes — 2026-11-27, develop `0c29` (sprint run-20261127T024025Z)

- **S3 built at `53897af`.** FR31–FR40, aiming at AC41–AC51. Claimed with `--touches` narrowed to
  `skills/queue/templates/next`, `.tickets/next`, `tests/next.test.sh`, `skills/retro/SKILL.md`,
  `skills/queue/SKILL.md`.
- **FR31/FR32 — the eighth `--drift` class.** `drift_report` now also walks `items/*.md`. For every
  `done`, `withdrawn` or `rejected` item with a non-empty `claimed_by:`, it prints FR31's line verbatim.
  An id that still has a `QUEUE.md` row is skipped there and left to the row classes, so one ticket
  stays one line. A closed status over a live row already reads as class 4. `--drive` shares the
  function, so it escalates on the class too (0229's knock-on note). **Checked on this backlog,
  2026-11-27:** `.tickets/next --drift` reports no drift, so no closed item here keeps a token and the
  running sprint's `--drive` is unaffected. The class comment's count was moved from seven to eight.
- **FR33:** the `--drift` usage line names *a closed item keeping a token* on one line, so AC44's
  phrase cannot straddle a wrap.
- **FR34/FR35:** an empty `rows` prints `ROW 1:     none — the queue holds no rows`. Otherwise the
  S2 line is unchanged.
- **FR36/FR37 — `--findings-list`, through `count_findings` itself.** `count_findings` takes an
  optional second argument, `list`, and in that mode it also prints `<buffer>:<line>  <first line>`
  for each entry it counts. There is one awk program and one function, and no second parser. The mode
  reads the same two buffers `--findings` does (`read_tools_buffer`) and drops the COUNT line. A
  MALFORMED line is listed with its line number, and the exit is then 1, as `--findings` exits. The
  function header stayed where `tests/findings-buffer.test.sh`'s window expects it. Live check: the
  listing printed the same number of lines as `--findings`'s count on this buffer.
- **FR38:** `.tickets/next` was re-copied (this repo's installed copy, 0228; `.claude/backlog/next`
  does not exist here). FR38 is `tests/backlog-scripts-installed.test.sh` green.
- **FR39:** one short paragraph each in `skills/retro/SKILL.md` Step 4 (after *Then empty what you
  read*) and `skills/queue/SKILL.md` Step 5 (after *Remove only the entries you processed*). These were
  added, not rewrapped. They are unguarded per *Out of scope* (from 0227), and AC47–AC49 assert the
  mechanism. Sizes: queue 51,644→~51,850 bytes and retro 30,801→~31,040, both inside `skill-size`'s
  margin.
- **FR40:** `fr40_findings` builds the buffer: a fenced `- 2026-09-05 [->0060] — …` at line 6, the
  rule at line 9, and entries at lines 11 and 13 (the second `[->0242]`-marked), with a continuation
  line at 12.
- **Red proofs, run:** before the implementation, the new cases failed 23 against the unchanged
  template (`760 passed, 23 failed`). **Green at baseline, so these are regression guards and not
  red-to-green proofs** (run): AC43, AC46 and FR32's held-open-row case.
- **Mutation sweep, run.** Each mutation was applied to the committed template the harness runs
  (`NEXT_SRC`), the diff was confirmed non-empty, and the file was restored with `git checkout --`.
  Control after: `783 passed, 0 failed` and `55 passed, 0 failed`, with `git status` clean.

  | AC | Clause (AC text) | Mutation | Result |
  |---|---|---|---|
  | AC47 | FR36's mode prints exactly two lines … neither preamble line | both preamble-skip lines removed (M1) | red, 4 |
  | AC48 | its count equals AC47's line count, one fixture, one case | list mode skips the `---` rule, i.e. a listing without the preamble rule (M2) | red, 5 (`the count equals …`) |
  | AC49 | a `- ` line with no date … printed marked `MALFORMED`, with its line number | MALFORMED printf gated off in list mode (M3) | red, 1 |
  | AC41 | a `status: done` item with `claimed_by: "ab12"` and no row … exits non-zero, one DRIFT line | items walk emptied (M5) | red, 9 |
  | AC42 | the same at `withdrawn`, and at `rejected` | status case narrowed to `done` (M4) | red, 6 |
  | AC43 | a `done` item with an empty `claimed_by:` … no DRIFT line, exit 0 | empty-token skip removed (M6) | red, 10 |
  | AC44 | `--help`'s `--drift` line names a closed item keeping a token | phrase removed from usage (M7) | red, 1 |
  | AC45 | header and no rows … `ROW 1:     none — the queue holds no rows` | empty branch disabled (M8) | red, 1 |
  | AC46 | one row … the line is the row | empty branch always taken (M9) | red, 5 (incl. `ROW 1 is the row`) |
  | FR36 | for every buffer `--findings` counts | tools buffer dropped from the loop (M10) | red, 2 |
  | AC50 | both copies of `next` … installed test passes | template-only edit (M11), `tests/backlog-scripts-installed.test.sh` | red, 1 (`next has diverged`) |

- **AC51 / whole suite, run at `53897af`:** `for t in tests/*.test.sh` file by file, 45 of 45 rc=0
  (`tests/next.test.sh` `783 passed, 0 failed`; `tests/backlog-scripts-installed.test.sh` `55 passed`;
  `tests/findings-buffer.test.sh` `46 passed`; `tests/skill-size.test.sh` `45 passed`;
  `tests/declared-copies.test.sh` `23 passed`). The tree was clean before and after.
- **Stale sibling prose (reported, not edited):** `skills/develop/SKILL.md` Step 1's warning about
  closed items keeping a token stays true, and *Out of scope* (from 0229) keeps it. The class it
  warns about is now reported by `--drift`, which S14 may want to cite.

### S4 build notes — 2026-11-27, develop `203d` (sprint run-20261127T024025Z)

- **S4 built at `933484b`.** FR41, aiming at AC52. Claimed with `--touches` set to
  `skills/queue/templates/handoff`, `.tickets/handoff` and `tests/handoff.test.sh`. It was widened
  to `tests/declared-copies.test.sh` and `CHANGELOG.md` when the work reached them. The token was
  passed by hand (`od -An -N2 -tx1`), because `./claim` with no token died on `xxd: not found`.
  That is already parked three times in `FINDINGS.md`/`FINDINGS-HELD.md`, so it is not re-parked.
- **The mechanism.** On a `ready` hand-off, `handoff` reads `blocked_by:` through the `fm-list`
  declared copy, the parser `next`, `claim`, `close` and `reopen` use. It counts an entry as open
  unless the entry's item exists and reads `done`, which is `next`'s `open_blockers_of` rule. A
  blocker with no item file is open. When any entry is open, the script writes `blocked` to the row
  and the item (`WRITE_STATUS`), reads it back the same way it reads every other field, and prints
  `status: blocked, derived rather than authored — blocked_by still open: <ids>`.
  **`blocked` is still refused as an argument** (FR2's case is unchanged and green). A `waiting`
  hand-off is never derived, because a person authors it. **Every destination stage derives, not
  only `develop`.** FR41 names develop, but the derived status is stage-independent, and `--drift`
  would report any other stage's row the same way. `close`'s reconcile frees the row later, since
  it selects exactly the dependents that read `blocked`.
- **Guard re-anchored (falsified, not exposed):** `tests/declared-copies.test.sh` pinned
  `fm-list: 4 copies` as a literal. `handoff` now carries a fifth copy, so the literal is now 5.
- **Mutation table, every row run** against the committed template that `HANDOFF_SRC` runs, each
  restored with `git checkout --`. Control after: `268 passed, 0 failed`, with `git status` clean.

  | Clause (AC52 / FR41 text) | Mutation | Result |
  |---|---|---|
  | Given a held fixture item whose `blocked_by` names an open ticket … the row and item carry `blocked` | never set `WRITE_STATUS=blocked` (M1) | red, 7 (row, item, `--drift` exit and line, `--drive`) |
  | when `./handoff` runs and then `./next --drift`, drift reports nothing for that row | row editor writes the asked status, not the derived one (M5) | red, 12 (read-back refuses: `exits 0` fails) |
  | `--drive` does not escalate on it | M1 | red (`--drive does not escalate on drift`) |
  | open = not done, as `next` reads it (a blocker with no item file is open) | missing item file counted closed (M2) | red, 2 |
  | a done blocker is not open | done blocker counted open (M3) | red, 2 |
  | written as the derived cache rather than authored (a `waiting` hand-off is left as written) | derivation applied to `waiting` too (M4) | red, 1 |

- **Stale sibling prose (reported, not edited; S14 owns the skills).** `skills/develop/SKILL.md`
  Step 5 (*If you cannot get the tree green*) says to set `status: ready` or add a `blocked_by`
  entry, *"since `blocked` is derived and never typed"*. That is still true, and `./handoff` now
  writes the derived value itself. No skill or reference states that `handoff` leaves `ready` over
  a blocker (grep of `skills/*/SKILL.md` and `references/*.md`, run).
- **Whole suite, run at `933484b`.** `for t in tests/*.test.sh`, file by file: 45 of 45 rc=0
  (`tests/handoff.test.sh` `268 passed`, `tests/declared-copies.test.sh` `23 passed`,
  `tests/next.test.sh` `783 passed`). The changelog guards were re-run once the note below was committed.
- `CHANGELOG.md` `## Unreleased` gains one behaviour note for S4. It was empty, because S1–S3 left
  theirs to S14.

### S5–S7 design — 2026-11-27, design `b7a4` (sprint run-20261127T024025Z)

Specified S5 and S6. S7 is briefed in `## Waiting on` and not decided. Nothing in S1–S4's criteria
was touched. FR42 and FR43 stand as written for S7.

**S5 (0217): fixed in the script, not in guidance.** The note recurred a day after the first fix,
on the same ticket (absorbed text above), so guidance about where a stop note goes is not holding.
- **What ends a criterion: the first non-blank line at column 0 (FR50).** Rejected: ending at a
  blank line, because `items/0161-*.md` AC1 runs on after a blank line as an indented `Red:` line,
  and a blank-line rule would cut it. Also rejected: an explicit end marker, which every author
  would have to remember, the same failure as the guidance. Scanned on 2026-11-27 over every item's
  `## Acceptance criteria`: 15 column-0 lines follow a criterion, in 0041, 0085, 0191, 0229 and 0230,
  and every one is a note about several criteria or about the section, never the criterion's own
  text. The only blank-then-indented continuation is 0161 AC1. 0242 has neither, so its own stamp
  does not move.
- **Migration: accept both digests per key, stamp only the new one (FR51).** Rejected: recomputing
  every stamp at upgrade. A stamp is the author's (0195), and a script that rewrote stamps in
  consuming backlogs would turn a mechanical upgrade into a restamp of criteria nobody re-read.
  Also rejected: a versioned stamp format, which would add a second contract. **Trade-off
  accepted:** an AC still carrying a legacy stamp keeps the old defect, so editing its trailing
  note reports drift until the next restamp. That drift is a false positive the author clears by
  restamping. It is never a missed edit, since an edit to the criterion itself fails both forms.
  Stamped items affected in this backlog: 0229 and 0230, both withdrawn. `--drift` checks the
  digests of `QUEUE.md` rows only, so neither would report, and the live tree has no red for FR51.

**S6 (0219): `reopen` resets `close_by` to `verify` (FR53).** `reopen`'s header already says its
destination is always `verify`, and that a reopen distrusts a verdict. On a `close_by: develop`
item, the verdict it distrusts is develop's self-close, so leaving `close_by: develop` in place
contradicts the destination. That makes a flag or a reason class unnecessary. Rejected: `close`
accepting a verify close on a reopened row. It would have to read history to know the row was
reopened, and it would weaken a refusal that is simple today. **Trade-off accepted:** a reopen
always raises the item to an independent close, even when the person might have wanted develop
to re-close it. A person who wants that can re-specify through `queue`.

**S7 (0235): not decided.** Refuse versus warn, and where the shared branch is read from, form a
concurrency architecture rule for every consuming project. Unattended, this pass prepared the
brief and recorded no answer.

**`qa_level: unit` and `close_by: verify` re-read against AC56–AC65:** all are fixture-scripted
and none needs a person, so both stand.

### S7 decision — 2026-11-27, design `3708` (sprint run-20261127T024025Z)

**The person's answer to the `b7a4` brief, verbatim:** "Making sure we are working from the same
branch is important. I am more interested in adding a check up front so we do not accidentally
create merge conflicts and extra work. We should also refuse if work is not being done in the same
branch."

**Decided: Option A, refuse, with the check made up front.** "Refuse" rules out B and C. "Up front"
puts the check at `./claim`, before the lock and before any work. `claim` is the first act of every
stage (design Step 1 claims before any reading), so a wrong-branch session is stopped before it
spends anything. `handoff`, `close` and `reopen` carry the same check, because a session can switch
branches mid-pass and every one of them commits to the backlog. The answer names no
branch-resolution source, and nothing in it contradicts the brief's recommendation, so FR55's order
stands: `shared_branch:` key, then `origin/HEAD`, then `main`.

**What this changes in the criteria:** FR42 and FR43 are sharpened. FR42 now says refuse, adds
`reopen`, fixes the position (before the lock) and gives the message. FR43 names the new section.
FR55–FR58 and AC66–AC77 are added. No S1–S6 or S8–S15 criterion changed, and no `ac_digest` value
for AC1–AC65 moved.

**Facts re-verified 2026-11-27:**
- `git rev-parse --abbrev-ref origin/HEAD` fails in this repo. This repo resolves by the `main`
  fallback, on which it works, so it needs no key.
- A bare `git init -q` starts on `master` here (git 2.43, `init.defaultBranch` unset). The fixtures
  in `tests/claim.test.sh:59`, `tests/handoff.test.sh:164`, `tests/close.test.sh:61`,
  `tests/reopen.test.sh:195` and `tests/next.test.sh:59` all use it. Without FR57 the check would
  turn them red. AC76 forces `master` as the default, so the suite cannot pass on a machine that
  happens to default to `main`.
- `tests/declared-copies.test.sh` already enforces byte-identical `copy-begin` blocks over
  `skills/queue/templates/*`. FR56 adds no new guard.

**Rejected:**
- **Warn (B, C):** the person said refuse. `claim`'s header records a warning that was read and
  committed past anyway (AetherWorks 0091).
- **An override flag:** it would become the warn path under another name. The `shared_branch:` key
  is the one sanctioned way to name a different branch.
- **Gating `./next` as well:** `next` only reads, so a refusal there protects nothing. It would
  also be a fifth copy of the rule that could drift from the other four.
- **Checking freshness against `origin`:** that needs a fetch, which means network in every claim,
  and it is a different guarantee.

**Trade-off accepted:** a consuming project that shares on `master` or `trunk`, with no
`origin/HEAD` and no key, refuses at its first claim after upgrading. It fixes this with one
config line, which the refusal names. Also accepted: the check is about branch identity, not
freshness. A session on a `main` that is behind `origin/main` still claims, and that conflict
surfaces at push, as it does today.

**`qa_level: unit` and `close_by: verify` re-read against AC66–AC77:** AC66–AC76 are
fixture-scripted. AC77 is a read verify does anyway. Both values stand.

**The `b7a4` brief, moved here from `## Waiting on` when it was answered:**

> ## Waiting on
>
> ### Outcome
> The single-holder guarantee reaches across branches: a claim made in the primary checkout is one
> that every other session sees, whatever branch that checkout has out (0235, slice S7).
>
> ### Where it stands
> S1–S4 are built and have passed verify. This design pass (`b7a4`, 2026-11-27) specified S5 (0217,
> AC56–AC62) and S6 (0219, AC63–AC65), both decided on evidence and ready to build. S7 is the only
> open question in front of them, and the row waits on it alone. S8–S15 wait behind in slice order.
> FR42 and FR43 already exist for S7 and read "refuse (or warn, per the decision)".
>
> ### What needs you
> Decide whether `claim`, `handoff` and `close` refuse when run off the shared branch, and how they learn which branch that is.
> This changes which checkouts may write every consuming project's backlog, so it is a concurrency
> architecture rule (`coding-conventions.md`, *What Not to Delegate to AI*). It also rests on a fact
> this repo cannot see: what branch each consuming project shares its backlog on. Observed here on
> 2026-11-27: `git symbolic-ref refs/remotes/origin/HEAD` prints `fatal: ref
> refs/remotes/origin/HEAD is not a symbolic ref`, so the remote's HEAD is not a dependable source,
> even in this repo.
>
> ### Options
>
> #### Option A — Refuse, resolving the branch from config, then the remote, then `main`
> The branch is `shared_branch:` in `config.yml` if that key is set, otherwise `origin/HEAD` if
> that resolves, otherwise `main`. The refusal names both branches and the key. Pros: matches the
> linked-worktree refusal (`CONCURRENCY.md`, *A second checkout never writes the backlog*), and
> `claim`'s own header comment records a warning that was read and committed past anyway (AetherWorks
> 0091). The answer is always deterministic. Cons: a consuming project that shares on `master` or
> `trunk`, with no `origin/HEAD` and no key, refuses at its next upgrade until it adds one config line.
> A prototype-branch session has to claim from the shared branch. Wins if a loud, one-line breakage
> on upgrade is acceptable.
>
> #### Option B — Refuse when the branch is known, warn when it is not
> Same resolution without the `main` fallback. With no key and no `origin/HEAD`, the scripts print
> a warning naming the key and go ahead. Pros: no project breaks on upgrade. Cons: in this repo, and
> in any checkout like it, the guard is only a warning until someone sets the key, which is the
> warn-and-commit shape `claim`'s history says fails. Wins if breaking a consuming project's backlog
> on upgrade costs more than a window of claims that are not guarded.
>
> #### Option C — Warn only
> Pros: nothing breaks, and the code is smallest. Cons: the AetherWorks 0136 case (a claim committed
> on `prototype/`, invisible on `main`) happens again whenever the warning scrolls by. Wins only if
> non-default-branch backlog work is a pattern worth keeping.
>
> ### Recommendation
> Option A. Prior art in this repo answers every comparable case with a refusal, and a refusal that
> names its one-line fix costs a consuming project a minute. The silent fork it prevents cost a
> second session a whole design pass on a row it could not see was held.
>
> ### What to do
> Reply `A`, `B` or `C`, naming a different key if `shared_branch:` is wrong. The next
> `/ai-building-tools:design 0242` then writes S7's FRs and ACs and hands the row to develop at S5.
> To build S5–S6 first and leave this open, reply `build S5–S6 first`: that design session moves this
> brief into *Notes & decisions*, leaves S7 `unspecified`, and hands off to develop.
>
> ### If no answer
> S5 and S6 wait, specified but unbuilt, along with every later slice of 0242. No other row names
> 0242 in `blocked_by`, so the rest of the backlog is unaffected.

### S5 build notes — 2026-11-27, develop `be4c` (sprint run-20261127T024025Z)

- **2026-11-27: S5 built in `ee2e63d`** (FR50–FR52): `skills/queue/templates/next`, `.tickets/next`,
  `tests/ac-digest.test.sh`, `CHANGELOG.md`. One normalisation, `ac_digest_compute <new|legacy>`, with
  `ac_digest_of` (new) and `ac_digest_legacy_of` (named legacy, comment naming 0242 S5) beside it; the
  mode decides only what ends a criterion's text. `ac_digest_diff` takes the legacy digest as an
  optional third argument and accepts a stamped key equal to either form. `--check` (so `close`,
  which runs it) and `--drift` pass it; `--ac-digest <id>` prints the new form only. `close` is
  unchanged: it carries no digest of its own (0195 AC9).
- **Mutations, all run** against the committed template, each restored with `git checkout --`, then a
  control run green (54/54). Each is the AC's own named red:

  | Mutation | Reds |
  |---|---|
  | M1 today's normalisation (new-mode end rule deleted) | AC61 (2), AC56 (2) |
  | M2 a rule ending every criterion at its label line | AC57, AC58, AC61, and 0195 AC1's rewrap case |
  | M3 a rule ending a criterion at a blank line | AC58, AC61's AC1 `Red:` case |
  | M4 FR51's legacy acceptance removed | AC59 (`--check` and `--drift`) |
  | M5 a legacy comparison that accepts any value | AC60, AC57, AC58 and 0195 AC3/AC4/AC6 |
  | M6 `ac_digest_of` stamping the legacy form | AC61, AC56 |
  | AC62: `# mutation` appended to the template only | `backlog-scripts-installed`: `next has diverged` |

- **AC57–AC60 were green before the change, by design**: they guard against the wrong fixes the ACs
  name (M2–M5), not against today's code. Only AC56 and AC61 were red at baseline, and were run red
  before `ee2e63d`.
- **AC61's expected values are computed in the test** (`crc` over the literal normalised text), not
  read back from `next`, so the test does not assert the code against itself.
- **AC62 evidence, run at `ee2e63d`:** `.tickets/next --ac-digest 0242 --check` → `0242: ac_digest
  matches`; the printed line is byte-identical to the stamped `ac_digest:` (0242 has no column-0 line
  in its criteria, as design said). `tests/backlog-scripts-installed.test.sh` 55/55. `.tickets/next
  --drift` → no drift. Not added to the suite: a guard pinned to a live ticket's stamp would red on a
  legitimate restamp.
- **Whole suite, run at `662ebd8`** (`ee2e63d` plus a `FINDINGS.md` append): 45 of 45 files pass.
- **The QA plan's "S5 is prose, read rather than grepped" is stale**: it predates the slice
  renumbering, and today's S5 is script behaviour over fixtures. AC56–AC62 are all fixture-scripted.
  The plan is not this stage's to edit.
- **`./claim 0242` with no token died before the lock** with only `xxd: not found`; claimed with an
  `od`-minted token. Parked in `FINDINGS.md` (`662ebd8`).

### S6 build notes — 2026-11-27, develop `9232` (sprint run-20261127T024025Z)

- **2026-11-27 — S6 landed at `b9e6303`** (FR53, FR54; AC63–AC65). `skills/queue/templates/reopen`
  reads `close_by` with `fm_value`, the same reader `close` uses, so a quoted or commented
  `close_by: "develop"  # …` is caught. On `develop` it sets a flag. The item awk replaces the
  `close_by:` line with `close_by: verify` only when that flag is set, so a `verify` value or a
  missing key passes through as it was. The note gets
  `; close_by: develop → verify — a reopen is for an independent verify` after the reason. The
  existing read-back now also refuses, before anything moves, when a reset was due and the temp
  item does not read `verify`. Header bullet added (FR54). `.tickets/reopen` re-copied, `cmp` equal.
- **AC64 fixture:** the fixture copies the `claim` and `close` templates in, claims with `ab12`, and
  writes a `## QA evidence` body. That body carries a `Conventions: ../conventions` line, because
  `close`'s sixth refusal (0160) needs one. Without it, close refuses for a reason that has nothing
  to do with AC64. A real verify pass writes the line anyway.
- **Clause table, AC text → assertion → mutation (all run on the committed `b9e6303`, template only,
  each restored by `git checkout` in the same call, control green at 94/0 after):**

| AC | clause | assertion in `tests/reopen.test.sh` | mutation | result |
|---|---|---|---|---|
| AC63 | Given … `status: done` recording `close_by: develop` and `qa_level: unit`, with a `DONE.md` row | fixture: `scaffold` + `set_close_by 'close_by: develop'` | — | fixture |
| AC63 | the item reads `close_by: verify` | `the item reads close_by: verify` | M1b: the awk reset line **and** the read-back removed | red, 90/4 |
| AC63 | the last line of `## Notes & decisions` contains both `fixture reason` | `the last notes line carries the reason` | M1 (reset removed, read-back kept: the script refuses) | red, 86/8 |
| AC63 | and `close_by: develop → verify` | `the last notes line records the reset` | M2: the note suffix removed | red, 93/1 |
| AC63 | `git show --name-only HEAD` lists exactly the item, `QUEUE.md` and `DONE.md` | `git show --name-only HEAD lists exactly …` | M1 (no commit happens) | red. **Reasoned, not run:** an extra file in the commit would also red it, by the same `assert_eq` AC1 already proves |
| AC64 | `./close <id> <token>` … exits 0 | `./close exits 0` | M1b | red |
| AC64 | never prints `the stage that may close it is 'develop'` | `it never names develop as the closing stage` | M1b | red |
| AC65 | the first still reads `close_by: verify` | `close_by: verify still reads …` + `exactly one close_by: line` | M3: reset taken whatever the value | red, 66/28 (the read-back refuses the no-key item; the `verify` item's note records a reset) |
| AC65 | the second still has no `close_by:` line | `no close_by: — still has no close_by: line` | M4: awk writes `close_by: verify` when the key is absent | red, 93/1 |

  No mutation stayed green. AC65 is the only AC with two fixture items, and it has both.
- **Whole suite:** `for t in tests/*.test.sh` green at `b9e6303`, with `git status --porcelain`
  clean before and after the run.
- **Sibling read, left alone:** the `./reopen` row in `skills/queue/SKILL.md:147`, Step 1, lists
  what reopen does and does not yet mention the `close_by` reset. It is incomplete, not false. Skill
  prose is S14's, and the file is outside this leg's `touches:`.
- **NFR rows bearing on S6:** none of the table's rows is S6's. No log field, egress, credential or
  UI. Nothing company-specific. `b9e6303` carries the trailer. `CHANGELOG.md` `## Unreleased`
  carries the S6 note.
- **`./claim 0242` with no token died again** with `.tickets/claim: 149: xxd: not found`, before
  the lock, writing nothing. Claimed with an `od`-minted token. Already parked four times in
  `FINDINGS.md`, so nothing new is parked.

### S7 build notes — 2026-11-27, develop `331a` (sprint run-20261127T024025Z)

- **Commits:** `f9e3483` claim, `3155d1c` touches widened to `tests/declared-copies.test.sh`,
  `9e76240` scripts, installs and tests, `83364b8` `CONCURRENCY.md` section and changelog line.
- **Mechanism (FR42, FR55, FR56):** one `copy-begin: shared-branch` block defines
  `refuse_off_shared_branch <verb>`. Each of `claim`, `handoff`, `close` and `reopen` calls it on
  the line after the block, and the block sits directly after the linked-worktree refusal, so the
  order is worktree, then branch, then the dirty-file refusals, then the lock. Resolution: an awk
  read of `^shared_branch:` in `$DIR/config.yml`, with `# comment` and blanks stripped as `next`
  reads `findings_threshold` (an empty value is unset). Then `git symbolic-ref --short -q
  refs/remotes/origin/HEAD` minus `origin/`. Then `main`. The current branch is
  `git symbolic-ref --short -q HEAD`, and empty means `HEAD (detached)`. The `<backlog dir>` in the
  second refusal line is printed as `git rev-parse --show-prefix` plus `config.yml`, which is
  repo-relative (for example `.tickets/config.yml`). Outside a work tree the function returns 0.
  `.tickets/{claim,handoff,close,reopen}` were re-copied from the templates.
- **FR57:** every `git init -q` fixture that can reach one of the four scripts now reads
  `init -q -b main`. That covers `tests/{ac-digest,backlog-location,claim,close,design-hold,handoff,
  next,reopen,scaffold-close}.test.sh` and both sites in `tests/sprint.test.sh`. `release.test.sh`
  already pinned `main`.
- **AC75's listing:** `tests/declared-copies.test.sh <root>` already listed
  `shared-branch: 4 copies, identical`. But the default run asserted only that copies were
  identical, so a script left without the block (3 copies) stayed green. The default run's list
  now includes `shared-branch: 4 copies`. This is a behaviour assertion over the scan, not a prose
  grep.
- **Where each AC is asserted:** AC66, AC70–AC74 in `tests/claim.test.sh` (`0242 AC66` … `0242 AC74`).
  AC67 in `tests/handoff.test.sh`, AC68 in `tests/close.test.sh`, AC69 in `tests/reopen.test.sh`.
  AC75 in `tests/declared-copies.test.sh` and `tests/backlog-scripts-installed.test.sh`. AC76 is the
  whole-suite run below. AC77 is checked by reading.
- **Mutation sweep (run, not reasoned), each applied to the committed template and restored with
  `git checkout --`, tree clean after:**

  | Mutation | Suite | Result |
  |---|---|---|
  | call removed from `handoff` | handoff | red: AC67 exit, first line, claim kept |
  | call removed from `close` | close | red: AC68 exit, first line, row kept |
  | call removed from `reopen` | reopen | red: AC69 exit, first line, DONE row kept |
  | call removed from `claim` | claim | red: AC66 and every branch case |
  | key never read | claim | red: AC70 both halves |
  | comment kept in the value | claim | red: AC70 naming `'trunk'`, exit 0 on trunk |
  | `origin/HEAD` never read | claim | red: AC71 both halves |
  | `origin/HEAD` read before the key | claim | red: AC72 (and AC70's main half) |
  | empty branch read as a match | claim | red: AC73 both assertions |
  | call moved after the lock | claim | red: AC74 first line, not-lock-message; AC66 no-lock |
  | block deleted from `reopen` | declared-copies | red: `reports shared-branch: 4 copies` |

- **AC76 run (run):** `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=init.defaultBranch
  GIT_CONFIG_VALUE_0=master`, then `for t in tests/*.test.sh; do "$t" || exit 1; done` at `83364b8`.
  All 45 files ran and the loop exited 0. A probe confirmed the env really moves the default: a bare
  `git init` under it starts on `master`, and with `trunkx` on `trunkx`.
- **This repo's own backlog:** it resolves by the `main` fallback (no key, no symbolic
  `origin/HEAD`), and its claims and hand-offs work on `main`. This leg's own `./handoff` is the
  live check.
- **NFR rows bearing on S7:** no log field, egress, credential or UI. Nothing company-specific. Both
  code commits carry the trailer.
- **`./claim 0242` with no token died again** with `.tickets/claim: 149: xxd: not found`, before the
  lock, writing nothing. Claimed with an `od`-minted token. Already parked, so nothing new is parked.
- **Sibling grep (widening):** the four scripts' new refusal is not an enumeration another open
  item's FR lists. S8–S11 must carry the block, per FR56's build note; nothing staled.

### S8 build notes — 2026-11-27, develop `89b0` (sprint run-20261127T024025Z)

- **2026-11-27 — S8 landed:** `bd65a89` (script, install, suite, guard counts) and `90d357f`
  (README guard block, a citation kept on one line). The subject is `skills/queue/templates/capture`,
  copied to `.tickets/capture`. Its suite is `tests/capture.test.sh`, 65 cases, and it runs the
  template copies of `capture` and `next`.
- **2026-11-27 — AC15 moved from S8 to S11 (slice re-split, no AC changed).** AC15 asserts that
  *all ten* scripts are present after the sync. Only S11 (`drain`) completes that set, so S8 could not
  discharge it, and handing it to verify as S8's would fail by construction. S8 now discharges AC1–AC5
  and AC12. S11 discharges AC13, AC14 and AC15. FR4's install half holds today regardless:
  `tests/backlog-scripts-installed.test.sh` derives its script list from the executables on either
  side (0089), so `capture` is already held byte-equal there (63 passed).
- **FR1's "as `./claim` does (0047)" is not true of the tree.** No backlog script retries a busy
  lock. `claim`, `close`, `handoff` and `reopen` each `mkdir` once and refuse. 0047 changed the
  close-time *procedure*, not a script. `capture` builds FR1's own requirement: it retries `mkdir`
  once a second for `BACKLOG_LOCK_TRIES` tries (default 10), then refuses, naming the holder, and it
  never breaks the lock. The S9–S11 scripts should carry the same loop. The FR's parenthetical is a
  stale cache; this note leaves it unedited.
- **Choices left open by FR5, recorded so verify reads them as decided, not missed:**
  - The draft is a whole item file. Its `id:` is replaced by the minted id and any `ac_digest:` is
    replaced.
  - Refused before the lock:
    - a missing `title:`, a `|` in it, or the `<…>` placeholder;
    - a `next:` outside queue/design/develop/verify, or a `status:` outside ready/waiting/blocked;
    - an unparseable position;
    - `--ranking` naming an empty file;
    - `QUEUE.md`, `config.yml` or (with `--ranking`) `RANKING.md` changed against HEAD;
    - no git repo, a linked worktree, or a branch other than the shared one.
  - The slug is the title, lowercased and hyphenated, cut at a word boundary past 60 characters.
  - The new id is the last line printed.
  - `--restamp` commits the item with its edits. Those edits are what a re-specify restamps, so a
    dirty item is the expected input and is not refused.
- **Declared copies carried** (FR56, plus the readers): `shared-branch`, `decomment`, `fm-value`,
  `header-of`, `column-in`, and the location block. `tests/declared-copies.test.sh`'s exact counts are
  bumped to 5/6/4/3/3, and `tests/backlog-location.test.sh` lists `capture` in its script list and its
  allowlist. The function guard refused `refuse` and `usage` as names already defined elsewhere, so
  they are `capture_refuse` and `capture_usage`.
- **Mutation sweep (run, not reasoned).** Each mutation was applied to the committed template, the
  suite was run, and the template was restored with `git checkout --`. The tree was clean after each.

  | AC | Mutation (the AC's own *Red*) | Result |
  |---|---|---|
  | AC1 | mint from `next_id` − 1 | red: id, next_id, row order, commit (aborted mid-suite) |
  | AC2 | stamp a stale value, read-back check removed | red: stamp ≠ `./next --ac-digest 0008` |
  | AC3 | skip the AC1 draft check | red: exit, message, fingerprint, commit count |
  | AC4 | commit without a pathspec | red: commit contents, 15 cases |
  | AC5 | anchor check removed and append at the bottom on a miss | red: exit, message, fingerprint, commit |
  | AC12 | `--restamp` keeps the old stamp | red: `--drift` still names 0003, `--check` |

  The first AC5 mutation removed only the anchor check. The read-back then refused on a missing row,
  and only the message assertion went red. The AC's own *Red* ("append at the bottom") is the row
  above, and it reds four cases.
- **Whole suite:** `for t in tests/*.test.sh` at `90d357f`, run file by file, `git status` clean
  before it, 46 files, all green. The first run at `bd65a89` had one red file, `tests/citations.test.sh`,
  for two reasons. The suite was missing from README's guard block. A `CONCURRENCY.md` citation in
  `capture` was wrapped across two lines, which the line-based checker cannot match. Both are fixed
  in `90d357f`.
- **Restated contract:** FR1–FR5, FR9 and FR56, with AC1–AC5 and AC12, at `qa_level: unit`, closed
  by verify. NFR rows bearing on S8: Testing, which the fixture cases cover, and Documentation, where
  the usage line is the header comment, the `usage:` refusal and `--help`. Nothing company-specific,
  and every commit carries the trailer.
- **Sibling grep (widening):** `capture` adds a backlog-writing script. The two guards whose
  enumerations it falsified are updated above. Every other open FR enumerating "the five scripts" is
  S14's (FR11, AC16, and `queue` Step 0's `chmod +x` list), so nothing outside this ticket was staled.

### S9 build notes — 2026-11-27, develop `e509` (sprint run-20261127T024025Z)

- **2026-11-27 — S9 landed:** `e1b23af`. The subject is `skills/queue/templates/park`, copied to
  `.tickets/park`. Its suite is `tests/park.test.sh`, 115 cases, and it runs the template copies of
  `park` and `next`. The commit also lists the suite in README's guard block, bumps
  `tests/declared-copies.test.sh`'s `shared-branch` count to 6, and adds `park` to
  `tests/backlog-location.test.sh`'s script list and allowlist.
- **"Public per its CLAUDE.md profile" has no defined marker, so this leg chose one.** The
  conventions' Profile block (`../ai-building-conventions/README.md`) defines only
  `collaboration:`, `company:` and `release:`. Nothing says `visibility:`. This repo's CLAUDE.md
  says "This repo is public" in prose inside its `## Profile` section. `park` treats the destination
  as public when the word `public` appears anywhere in the destination's `## Profile` section (up to
  the next `## ` heading), case-insensitive, as a whole word. The test errs towards screening: "not
  public" is screened too, which costs only a redaction. Two cases are not screened: a destination
  with no CLAUDE.md, and one that says `public` only outside `## Profile`. Both are pinned by the
  `FR6 — the screen applies where the destination is public, and only there` cases. The conventions
  repo's CLAUDE.md does not say `public` in its Profile section, so a park into its `.tickets/`
  would not be screened. Its *root* buffer is out of `park`'s reach anyway: FR6 says "the backlog of
  the named checkout". This is a mechanism choice under FR6, not an AC change. If verify or the
  author wants a structured `visibility:` key instead, that is a conventions change and a row.
- **The screen is the tracked-tree guard's pattern, not a second one.** `HOME_PATH_PAT` in `park` is
  byte-equal to `tests/measurement.test.sh`'s line, and a `park.test.sh` case asserts that. The
  shape named on refusal is macOS (`/Users/<name>/…`), Linux (`/home/<name>/…`) or the dash slug.
  Every real-shaped sample in the suite is assembled, so the suite cannot red the guard it mirrors.
- **Choices left open by FR6, recorded so verify reads them as decided:**
  - The entry is the text after the date. `park` writes `- <UTC date> — <entry>` and adds no bold.
  - Refused before the lock:
    - an empty entry, or one holding a line break;
    - an entry that starts with a date, bolded or not, which would be dated twice;
    - an entry that starts with a `[->…]` token, because the noticer never writes the token;
    - an unknown argument;
    - a `--repo` that is no directory, is not in a git checkout, or holds no backlog or more than one;
    - a buffer missing, or with no `---` rule, since `./next` counts nothing above the rule;
    - `FINDINGS.md` changed against HEAD;
    - a linked worktree, or a destination off its shared branch.
  - `--repo` accepts any path inside the checkout and resolves the checkout's root.
  - The declared `shared-branch` block reads `$DIR`. `park` reassigns `DIR` to the destination
    backlog first, so the block judges the repo being written. A case covers a `--repo` destination
    on another branch.
  - The lock is the destination backlog's `.lock`. It uses `capture`'s retry loop and is never
    broken. The function names are `park_usage`, `park_refuse` and `park_cleanup`, because the
    declared-copies guard refuses a second undeclared `cleanup`.
- **TDD order, stated plainly:** the script was written before its suite, so the suite's first run
  was green. The red half is the mutation sweep below. Every AC's own *Red* was applied to the
  committed template and reddened it.
- **Clause table (from the AC text):**

  | AC | Given | Predicate | Objects asserted |
  |---|---|---|---|
  | AC6 | a fixture buffer | `./park "what happened"` | exactly one line appended; head-token shape (read back through `./next --findings-list`); today's UTC date; one commit; naming only `FINDINGS.md` |
  | AC7 | `--repo <second fixture checkout>` | `./park` runs | entry lands in the second repo; its commit lands there; first repo unchanged (fingerprint, commit count, status) |
  | AC8 | a second checkout whose `CLAUDE.md` profile marks it public | `./park` given an entry holding a real-shaped macOS or Linux home path (assembled) | exits non-zero; writes nothing (both fingerprints, both commit counts); names the failing shape; the redacted entry is written |

- **Mutation sweep (run, not reasoned).** Each mutation was applied with `python3` to the committed
  `skills/queue/templates/park`, and its diff was confirmed non-empty. `tests/park.test.sh` was run,
  then the template was restored with `git checkout --`. The tree was clean after the sweep, and the
  control run gave `park: 115 passed, 0 failed`.

  | Target | Mutation | Result |
  |---|---|---|
  | AC6 (the AC's *Red*) | write the entry without its date | red `105 passed, 10 failed` (shape, `--findings-list`, count) |
  | AC6 / FR2 | commit `-a` with no pathspec | red `113 passed, 2 failed` (staged `other.txt` in the commit, no longer staged) |
  | AC7 (the AC's *Red*) | ignore `--repo` | red `87 passed, 28 failed` |
  | AC8 (the AC's *Red*) | skip the guard | red `97 passed, 18 failed` (all three shapes) |
  | FR6 scope | screen every destination | red `112 passed, 3 failed` (private, no CLAUDE.md) |
  | FR6 scope | read `public` anywhere, not only in `## Profile` | red `113 passed, 2 failed` |
  | FR6 pattern | `HOME_PATH_PAT` drops the `-` separator | red `109 passed, 6 failed` (slug shape, byte-equality) |
  | FR1 | cleanup leaves the lock | red `110 passed, 5 failed` |
  | FR1 | break a busy lock | red `111 passed, 4 failed` |
  | FR3 | date check removed | red `97 passed, 18 failed` |
  | FR3 | head-token check removed | red `103 passed, 12 failed` |
  | FR4 | one line appended to `.tickets/park` | `backlog-scripts-installed` red `70 passed, 1 failed`; restored |

- **Whole suite:** `for t in tests/*.test.sh` at `e1b23af`, with `git status` clean before it. All
  47 files reported 0 failed.
- **Restated contract:** FR1–FR4, FR6 and FR56, with AC6–AC8, at `qa_level: unit`, closed by
  verify. NFR rows bearing on S9:
  - Security and Privacy & data (AC8), met by the screen.
  - Testing, met by the fixture cases.
  - Documentation, met by the usage header, the `usage:` refusal and `--help`.

  Nothing is company-specific, and the commit carries the trailer.
- **Sibling grep (widening):** `park` adds a backlog-writing script. The two guards whose
  enumerations it falsified are updated above. The skills' park steps (FR11, AC16) and `queue` Step
  0's install list are S14's, so nothing outside this ticket was staled.

### S10 build notes — 2026-11-27, develop `661e` (sprint run-20261127T024025Z)

- **2026-11-27 — S10 landed:** `98b0179`. The subjects are `skills/queue/templates/rank` and
  `skills/queue/templates/withdraw`, copied to `.tickets/rank` and `.tickets/withdraw`. Their suites
  are `tests/rank.test.sh` (71 cases) and `tests/withdraw.test.sh` (87 cases), and each runs the
  template copy. The same commit adds both suites to README's guard block, bumps
  `tests/declared-copies.test.sh`'s exact counts by two each (decomment 8, fm-value 6, column-in 5,
  header-of 5, shared-branch 8), and adds both scripts to `tests/backlog-location.test.sh`'s script
  list and allowlist.
- **Shared mechanics carried from `capture`:** the location block, the declared copies, the
  linked-worktree and shared-branch refusals, and `capture`'s lock loop, which retries
  `BACKLOG_LOCK_TRIES` times and never breaks the lock. Both commit by pathspec with the trailer.
  Function names carry the `rank_`/`withdraw_` prefix because the declared-copies guard refuses a
  second undeclared definition.
- **Choices left open by FR7, recorded so verify reads them as decided:**
  - "Every other line unchanged" is enforced, not only tested. Before writing, `rank` checks that
    the moved row appears once in the result, and that with that row taken out the old and new
    files are identical (`cmp`).
  - A row already at its position exits 0, prints `already at`, and commits nothing. A `--ranking`
    text is not appended in that case, and the script says so.
  - "In-progress under any token" is read two ways under the lock: the row's Status cell, and the
    item's `claimed_by:`. Either one refuses. Moving a different row past an in-progress row is
    allowed.
  - Refused: a bad id or position, an anchor that is the row itself, a row or anchor not in the
    queue, a duplicated row, an empty `--ranking`, a dirty QUEUE.md or RANKING.md.
- **Choices left open by FR8, recorded so verify reads them as decided:**
  - **The dated note** is `- <UTC date> — **Withdrawn** by \`./withdraw\`: <reason>`, with
    ` — absorbed into <id>` added when `--into` is given. It goes after the last non-blank line of
    `## Notes & decisions`, which is `reopen`'s placement. The reason is also the commit body.
  - **"Every open item"** means every item whose status is not `done`, `withdrawn` or `rejected`.
    A closed item that names the id is history and is left alone (pinned by the `0002` case).
  - **Re-pointing keeps order and never duplicates.** An entry already naming `--into` is dropped,
    and so is the absorbing item's own entry, so no item ends up blocked by itself. The list is
    written back in the inline form `templates/item.md` specifies, and a `- ` block is read too.
  - **`blocked` is derived, so `withdraw` re-derives it.** This goes beyond FR8's text, and it is
    needed to keep FR8 from leaving drift that stops `--drive` (the 0156 class). A dependent at
    `ready` or `blocked` gets its status recomputed from its new list, on both the item and the
    row. A `waiting` dependent keeps its status, because a person clears `waiting`, not a script.
    `./next --drift` is asserted clean after each withdrawal case.
  - **Refused:**
    - a claimed item or an in-progress row;
    - a dependent another session holds;
    - an item already closed;
    - an `--into` that is the id itself, has no item, or is closed;
    - an empty reason, or one holding a line break;
    - a dirty QUEUE.md, item or dependent. Dependents are checked under the lock, once the set is
      known.
  - **An item with no row** (a project) is withdrawn anyway, and the script says so on stderr.
  - `config.yml` is never opened, so `next_id` cannot move.
- **Fixture correction found by the suite.** The first `withdraw` fixture had a `waiting` item with
  an open blocker. `./next --drift` already calls that drift ("written waiting, derived blocked"),
  so the fixture was wrong, not the script. 0007 is now `blocked`, and a separate case shows a
  `waiting` item staying `waiting`.
- **The installed-copies guard reported a two-line awk program as a "quote defect".** `cell_of`'s
  program opened on one line and closed on the next, after code. Reshaping it to the sibling
  layout (opening quote alone on its line, closing quote on its own line) cleared it. Parked.
- **TDD order, stated plainly:** each script was written before its suite, so each suite's first
  run was green apart from the fixture correction above. The red half is the mutation sweep below.
- **Clause table (from the AC text):**

  | AC | Given | Predicate | Objects asserted |
  |---|---|---|---|
  | AC9 | rows A, B, C | `./rank C above:A` runs | order is C, A, B; every other line of `QUEUE.md` unchanged (lines minus the row equal, row byte-equal, line count); one commit |
  | AC10 | B `in-progress` under a token | `./rank B top` runs | refuses (non-zero, names why); changes nothing (fingerprint incl. `.lock`, commit count, order) |
  | AC11 | 0004 named in 0005's `blocked_by:` | `./withdraw 0004 "merged" --into 0006` runs | 0004's file stays; `status: withdrawn`; empty `next:`; a dated note; its row is gone; 0005's `blocked_by:` names 0006; `next_id` unchanged (config.yml cksum) |

- **Mutation sweep (run, not reasoned).** Each mutation was applied with `python3` to the committed
  template at `98b0179`, and its diff was confirmed non-empty. The suite was run, then the template
  was restored with `git checkout --`. `git status` was clean afterwards, and the control runs gave
  `rank: 71 passed, 0 failed` and `withdraw: 87 passed, 0 failed`.

  | Target | Mutation | Result |
  |---|---|---|
  | AC9 (the AC's *Red*) | re-sort the table, read-back disabled | red `63 passed, 8 failed` |
  | AC10 (the AC's *Red*) | drop the claim check (cell and `claimed_by:`) | red `63 passed, 8 failed` |
  | FR1 | rank cleanup leaves the lock | red `57 passed, 14 failed` |
  | FR2 | rank commits with no pathspec | red `55 passed, 16 failed` |
  | AC11 (the AC's *Red*) | delete the item file | red `80 passed, 7 failed` |
  | AC11 (the AC's *Red*) | leave 0005 pointing at 0004 | red `75 passed, 12 failed` |
  | AC11 | decrement `next_id` | red `85 passed, 2 failed` |
  | FR8 | drop the claimed-item check | red `86 passed, 1 failed` |
  | FR8 | never re-derive `blocked` | red `82 passed, 5 failed` |
  | FR8 | re-derive a `waiting` item too | red `86 passed, 1 failed` |
  | FR8 | rewrite a closed dependent | red `85 passed, 2 failed` |
  | FR2 | withdraw commits with no pathspec | red `59 passed, 28 failed` |
  | FR4 | one line appended to `.tickets/withdraw` | `backlog-scripts-installed` red `86 passed, 1 failed`; restored |

- **Whole suite:** `for t in tests/*.test.sh` at `98b0179`, with `git status` clean before it. All
  49 files exited 0.
- **Restated contract:** FR1–FR4, FR7, FR8 and FR56, with AC9–AC11, at `qa_level: unit`, closed by
  verify. NFR rows that bear on S10:
  - Testing, met by the fixture cases.
  - Documentation, met by the usage header, the `usage:` refusal and `--help`.

  Nothing is company-specific, and the commit carries the trailer.
- **Sibling grep (widening):** `rank` and `withdraw` add two backlog-writing scripts. The two
  guards whose enumerations they falsified are updated above. queue Step 4 and *Withdrawing a
  ticket* still describe the by-hand moves, and moving them onto the scripts is S14's (FR11, AC16),
  so nothing outside this ticket was staled.

### S11 build notes — 2026-11-27, develop `8c46` (sprint run-20261127T024025Z)

- **2026-11-27 — S11 landed:** `636a1d2`, then `d0db04d`, which puts one citation back on a single
  line. The subject is `skills/queue/templates/drain`, copied to `.tickets/drain`. Its suite is
  `tests/drain.test.sh` (96 cases), which runs the template copies of `drain` and `next`. The fixture
  buffer is the shipped `skills/queue/templates/FINDINGS.md` with entries added after it, so AC13's
  header is the real one every project carries. AC15 is a new case at the end of
  `tests/backlog-scripts-installed.test.sh` (106 passed). The same commit adds `drain` to
  `tests/backlog-location.test.sh`'s script list and allowlist, bumps `tests/declared-copies.test.sh`
  to `shared-branch: 9 copies`, and adds the suite to README's guard block.
- **Choices left open by FR10, recorded so verify reads them as decided:**
  - **How the entry is found.** `drain` runs `./next --findings-list` and keeps the lines for this
    backlog's own `FINDINGS.md` (never the tools buffer). It matches the date as the first 10
    characters after `- ` or `- **`. Each entry is addressed by the line number the listing prints,
    so the preamble above the `---` rule can never be picked. Before writing, the script also checks
    that the preamble is byte-identical.
  - **FR10's `[<row-id>]`** is read as a second way to write the mark: `marked 0060` is the same as
    `marked:0060`. A row id given with `removed` or `held` is refused. A mark names `none` or a
    four-digit id that has an item file.
  - **Several entries on one date** cause a refusal that lists them. `--line <n>`, taken from the
    listing, picks one, and it is refused if the listing does not name that line for that date. This
    goes beyond FR10's text. Without it, two entries parked on the same day could not be drained.
  - **An entry's extent** is its listed line plus every following line that starts with a space or
    a tab. `removed` and `held` take the whole extent. `marked` rewrites only the first line, and it
    replaces any `[->…]` token already after the date rather than adding a second one.
  - **`held`** appends the extent, unchanged, to the end of `FINDINGS-HELD.md`. If that file does
    not exist, it is created with a one-line title. An untracked file is `git add`ed by its path
    only, so that it can be committed by pathspec. An untracked `FINDINGS-HELD.md` that already
    exists is refused, because it is another session's write.
  - **Refused, with nothing changed and no lock held:** a bad date, a bad disposition or a bad mark;
    a date or `--line` the listing does not name; an ambiguous date; a dirty `FINDINGS.md` or
    `FINDINGS-HELD.md`; a linked worktree; any branch other than the shared one. A busy lock is
    retried `BACKLOG_LOCK_TRIES` times and is never broken.
- **AC15 runs Step 0's sync as written, because Step 0's sync is prose.** The case's `step0_sync`
  follows Step 0's own sentence: every executable in `templates/`, plus `item.md`, re-copied when it
  is missing or differs, then `chmod +x`. It runs over a fixture that holds only the five scripts the
  scaffold names. It asserts that the ten scripts are present, executable and byte-equal, and that
  `config.yml`, `QUEUE.md` and `FINDINGS.md` keep the same checksums. The sync also copies
  `migrate`, the eleventh executable; the AC names ten, and nothing asserts against the eleventh.
  The AC's red ("omit one new script from the sync list") is M4 below. Because the list is derived
  from the template set, the case proves two things: the template set carries all ten, and Step 0's
  rule reaches each one.
- **For S14, not built here:** Step 0's *scaffold* sentence in `skills/queue/SKILL.md` still says
  ``chmod +x` `next`, `claim`, `close`, `handoff` and `reopen``, five names. Its retrofit paragraph
  ("every executable in this skill's `templates/`") already covers all ten. S14 owns the skill
  prose.
- **This repo's own `.tickets/FINDINGS.md` still shows the damage 0227 describes.** Its fenced
  example block is empty: the opening and closing fences are there with nothing between them. The
  shipped template still has the example line. That file belongs to the project and Step 0 never
  re-copies it, so the line will not come back unless someone restores it. That is outside this
  slice. It is recorded here so nobody takes the empty block for the intended shape.
- **The installed-copies quote scanner flagged `printf '# Findings held …'`** as an awk program
  closed early. A single-quoted string that begins with `#` reads to it as a comment start. Changing
  it to double quotes cleared the flag. This is the same misdiagnosis class S10 parked, so it is not
  parked again.
- **Clause table (AC13–AC15)**, each row's guard in `tests/drain.test.sh` unless named:

  | AC | Clause | Guard |
  |---|---|---|
  | AC13 | Given a buffer whose header carries the fenced example `- 2026-09-05 [->0060] — …` | `the header holds '- 2026-09-05 [->0060] — '` (shipped template) |
  | AC13 | and one real entry dated 2026-09-05 | fixture `E1`; `./next --findings-list names three entries` |
  | AC13 | when `./drain 2026-09-05 removed` runs | AC13 block, `run 2026-09-05 removed` |
  | AC13 | then only the real entry is removed | `the real 2026-09-05 entry is gone`, `the other entries stay` |
  | AC13 | and the header is byte-identical | `the header is byte-identical`, `the header's fenced example is still there` |
  | AC14 | Given a real entry, when `./drain <date> held` runs | AC14 block, `run 2026-09-06 held` |
  | AC14 | the entry is absent from `FINDINGS.md` | `the entry is absent from FINDINGS.md` (+ its continuation) |
  | AC14 | present verbatim in `FINDINGS-HELD.md` | `it is present verbatim, last, in FINDINGS-HELD.md` |
  | AC14 | both changes are in one commit | `one commit`, `both changes are in it` |
  | AC15 | Given a fixture backlog holding only the five pre-existing scripts | `backlog-scripts-installed`: `OLD` fixture of next/claim/close/handoff/reopen |
  | AC15 | when `queue` Step 0's sync runs | `step0_sync` (Step 0's retrofit rule, as written) |
  | AC15 | all ten scripts are present and byte-equal to `templates/` | ten `AC15 — <s> is present, executable and byte-equal` lines |
  | AC15 | `config.yml`, `QUEUE.md` and `FINDINGS.md` are byte-identical | `AC15 — config.yml, QUEUE.md and FINDINGS.md are byte-identical` |

- **Mutations, all run 2026-11-27 against committed files, each restored with `git checkout --` in
  the same turn:**

  | # | Mutation | Result |
  |---|---|---|
  | M1 | AC13's red: pick the first line matching the date by regex over the whole file | `drain: 76 passed, 20 failed`. AC13 `exits 0` fails because the in-script header read-back refuses. |
  | M1b | M1 with the header read-back also deleted | AC13 `the header is byte-identical` and `the header's fenced example is still there` fail. The example line is deleted, which is the 0227 damage. |
  | M2 | AC14's red: `held` writes the held file without removing the entry | `drain: 87 passed, 9 failed` (AC14 `exits 0`, `one commit`, `both changes are in it`) |
  | M3 | FR2: commit without `-- $paths` | `drain: 67 passed, 29 failed` (`other.txt is still staged`, `the commit names only FINDINGS.md`) |
  | M4 | AC15's red: the sync skips `drain` | `105 passed, 1 failed` (`AC15 — drain is missing …`) |

- **Whole suite:** `for t in tests/*.test.sh` at `d0db04d`, all 50 files green, `git status` clean.
  The first run hit one red, in `tests/citations.test.sh`, from a citation wrapped across two
  comment lines in this slice's own script. `d0db04d` fixes it.

### S12, S15 decision; S13 briefed — 2026-11-27, design `56a2` (sprint run-20261127T024025Z)

**S12 (0237): `queue` claims and then runs `./handoff <id> <token> design`. No new script mode.**
Prior art decided it. `references/CONCURRENCY.md`, *A claimed ticket is never amended, even by
`queue`*, already gives `queue` exactly this shape for an amend: wait for the release, claim,
amend, hand back. `handoff` accepts all four stages as a target (`handoff:148`). As observed on a
scratch clone (FR59), `./claim 0192 ab12` and then `./handoff 0192 ab12 design` moved a live
`verify` row to `design | ready` with the claim released and the tree clean. So the gap 0237 hit was
a missing *instruction*, not a missing *operation*.
- Rejected: **an unclaimed form of `./handoff`**. It removes the token check, and that check is the
  single-holder guarantee. A verify pass mid-run would have its row moved under it.
- Rejected: **`./reopen` taking a target stage**. Its header states that the destination is always
  `verify` and that it acts on a `status: done` item only. A contract change is a re-specify, not
  a reopen. Widening it would make one script answer two questions.
- Accepted cost: two calls and two commits, not FR44's original "one script call". Each call is
  atomic, and the state between them is a held row, which is a valid state, not drift. So the
  two-file hand edit 0237 recorded cannot recur.
- Criteria accounting: FR44 and FR45 were sharpened. FR59 and FR60 and AC78–AC80 were added.
  AC78 is a regression guard, green at baseline, and says so.

**S15 (0155): the class goes in the shared `drift_report`, and `--drive` gates on it. An entry
marked `# new` is exempt.** This keeps both closed contracts that the S1 build found in conflict:
- 0142 FR3 ("--drive and --drift name the same rows and classes, because they share the check")
  is kept by placing the class in `drift_report`.
- `claim`'s 0147 FR2 ("declaring a file you are about to write is the common and correct case")
  is kept by the `# new` exemption. `skills/queue/templates/item.md` already names `# new` as the
  comment an `expects:` path carries, so the marker is prior art, not new vocabulary.
- The 322 fixture reds the S1 build saw come from fixtures naming files they never create. FR64
  makes those fixtures honest, and the 0142 FR3 count stays three.
- Rejected: **the class in `--drift` only**. It reds 0142 FR3's guarded contract.
- Rejected: **a non-gating "advisory" class in `--drive`**. It is a new concept, a class that prints
  without escalating, invented for one case. It would also make "every DRIFT line escalates" untrue.
- Accepted cost: on upgrade, a consuming project's `--drive` escalates on every open row that names
  a to-be-created file without `# new`, until `queue` marks or corrects it. FR66's CHANGELOG line
  names the fix. Here, measured on 2026-11-27, it would name 0242's four `.claude/backlog/*`
  entries (fixed in the S15 leg, FR65) and 0240's `references/MEASUREMENT.md` (left for `queue`).
- Criteria accounting: FR22 was sharpened. AC28 is confirmed unchanged and is now discharged by
  S15, which settles verify `45e7`'s residual. Its "a path that does not exist" reads as an
  *unmarked* path, and its digest is untouched. FR61–FR66 and AC81–AC85 were added.

**S13 (0236): not decided. A brief is in `## Waiting on`.** S13 changes who may write which item,
which is concurrency architecture (`coding-conventions.md`, *What Not to Delegate to AI*), and this
pass is unattended. The recommendation (Option B) is in the brief only. No S13 FR or AC is written.
S13 is moved to the end of `## Progress` (unticked slices may be re-ordered, `templates/item.md`), so
a `defer S13` reply releases S12, S14 and S15 to `develop` without waiting on the decision.

`qa_level: unit` and `close_by: verify` were re-read against AC78–AC85, and both still fit: every new
criterion is a fixture case or a reading. The slice-kind parser (`progress-slices` in `handoff` and
`next`) reads the kind from the text after the last ` — `, so S13's annotation sits before its
`— unspecified`.

### S13 decision — 2026-11-27, design `213b` (sprint run-20261127T024025Z)

**S13 (0236): the person chose a variant of Option B. `design` records the sibling consequences in
the held item and hands to `queue`. `queue` folds them in, checks them holistically, and may send
the decision back. A done sibling is reopened and fixed. A queue pass follows every plan change.**
The person gave the answer in the supervising session. Their words are quoted here verbatim from
the machine-local, uncommitted `.tickets/runs/s13-answer.md`, so the decision does not rest on a
file that is not in the repo.

> First reply to the brief:
> "Design should add what it found to the ticket as a finding and then mark the ticket as ready for queue. Then Queue should wrap the finding into the actual tickets AC. This easy we leverage the context design already has, but also compare the proposal against other tickets and AC to make sure our plan is holistic. Do you see gaps with that approach before we lock it in?"
>
> The supervisor raised six gaps (1 finding means the ticket's Notes, not FINDINGS.md; 2 which ticket is marked for queue; 3 siblings stale until queue runs; 4 a sibling claimed or done; 5 queue's holistic check disagreeing with design; 6 sprint counting design->queue as a bounce). The person's answers:
>
> 1. Agreed
> 2. We have essentially changed our build tools from focusing on traditional user stories to Epics and are focusing on the larger view and outcome, but because we have built it as Epics are the ticket and every story underneath it is part of the same file, our lock system is tricky. If something we find actually affects another ticket then we update that ticket and everything works smoothly, but if we are updating the same ticket for a different slice, that is where the complication happens. I like having all of the context in one place, but also there's no reason we couldn't update the system to have a separate file per slice and then have our sessions pull in each slice file that it needs to be effective for its job that would also make it easier here to mark something as needing to be revisited because that slice would need to be revisited. Would love your recommendation.
> 3. After making changes to the plan, we would want to run the queue session before continuing to work on the plan to make sure that it is up-to-date and effective. This is just a matter of discipline and intentional organization.
> 4. If we update work that is already claimed then we are talking about number three and we just need to make sure that we are running a queue session after the design session finishes and before we do that work. If the work had already been marked done and we updated it, like in the case of a missed red test, then we would need to reopen that ticket and make sure it is actually fixed.
> 5. Agreed. our goal is always effectiveness first, then efficiency. If we are adding scope or clarity to a ticket, we need to make sure that it makes sense, that it actually gets us closer to the specified outcome and that we are working in a way that sets us up for the future. Rework is OK when it is needed to build a clean high-quality system and we just need to be intentional and call it out. going fast and trying to save on token usage because something's already implemented in a certain way is often the wrong approach. We can work quickly enough that spending the time to do it correctly right now is the way this tool kit should be built.
> 6. The bounce limit is a tool. We added it in to help keep track of runaway sessions and to identify potential loops. The sprint tool needs the ability to be smart, to look at what is happening and make good decisions on its own. when there is a loop or a potential loop identified then it should escalate to me so that I can intervene and fix the thing before we go off the rails, but we want to build sprint in a way that maximizes its own ability to identify those possible loops and address them on its own. A hard bounce limit is less important to me than designing and building a system that understands the goal and has the autonomy to move us toward that outcome effectively.
>
> The supervisor's recommendation on 2, which the person approved ("Yes, go ahead with all three"):
> - Split each slice into its own file, with the epic file kept as the index (outcome, problem, NFRs, the slice list linking each slice file) and each slice file holding its FRs, ACs, digest, claim, QA evidence and notes, so claims and locks work per slice and "needs revisiting" is a slice status. Sessions load the epic plus the slice files their job needs.
> - Do it as its own epic, ranked right after 0242, not inside 0242: 0242 is rewriting the same scripts. Within 0242 today, sibling consequences that land on other slices of the ticket design already holds are written by design itself.
> - 6 becomes a second new epic: sprint judges loops and likely loops itself and escalates those, rather than stopping on a hard bounce count.
> Both new epics are captured by a queue session after this design; they are not S13's work.

How each answer became criteria:
- **Answers 1 and 2.** The "finding" is a `### Sibling consequences` subsection in the held item's
  Notes, not a `FINDINGS.md` line. The ticket "marked ready for queue" is the held item, through
  `./handoff … queue` (FR68). A consequence on another slice of the held item is written by design,
  as the approved recommendation says (FR68). The one-file-per-slice split is **not** S13 work. It
  still needs a row, which the queue session after this pass captures.
- **Answers 3 and 4.** A queue pass follows the plan change (FR71). A held sibling finishes its leg,
  and then `queue` amends it. A done sibling is reopened, amended and rebuilt (FR69 (b)). This is
  intentional rework, named in both items.
- **Answer 5.** `queue`'s holistic check may disagree and send the decision back to design
  (FR69 (c)). Effectiveness comes before efficiency, so the round trip is accepted, not minimised.
- **Answer 6.** This was the one fact the decision turned on. Read on 2026-11-27,
  `skills/queue/templates/next` (~line 2141) dispatches queue only after a verify or develop
  completion, so a design → queue hand-off escalates today (`ESCALATE … the contract is stale`).
  FR72 adds `design` to that arm, under the existing `bounce_max` bound for now. The judging-loops
  epic replaces the bound, and it still needs a row. FR72 is written so that epic can delete the
  bound in one place.

Rejected:
- **Option A, a second exception for design.** A non-author would rewrite criteria and restamp
  their `ac_digest`, which is the one edit the digest cannot catch.
- **Option C, a `claim` mode for `blocked` rows.** It creates a new held-blocked state that `--drive`
  and `--drift` would both have to learn, for one rare case.
- **Every design pass hands to queue, siblings or not.** Answer 3 asks for a queue pass after "changes
  to the plan". A design that changes only its own item is the author of those criteria, and `queue`
  would re-read work no other item depends on. If a later queue pass disagrees, this is the line to
  reopen.
- **A `handoff` refusal for `design → queue` without a `### Sibling consequences` subsection.** It is
  exact enough to script. But it would add a new refusal to a script that S14 is moving every skill
  onto, and nothing has yet gone wrong that it would catch. Prose for now.

Criteria accounting: FR67–FR73 and AC86–AC91 are added. No existing FR or AC changes. FR60 (S12) is
compatible, because FR69's routing row sits beside AC80's row, and neither forbids the other.
`qa_level: unit` and `close_by: verify` were re-read against AC86–AC91 and still fit. AC86, AC87 and
AC91 are fixture cases, and AC88–AC90 are readings. S13 stays last in `## Progress`. It edits the
same `design`, `queue` and `sprint` prose that S14 moves onto the scripts, so building it after S14
means it edits the final text once. S13's own criteria were cross-read against S12's FR45/FR60 and
S15's FR64. `tests/next.test.sh` is shared with S15, which is a sequencing note and not a conflict.

**Hand-off: `next: queue`, not `develop`**, per the person's answer 3 and the dispatch. The queue
pass reviews S12, S13 and S15 against each other and against the open backlog before develop
resumes. Until S13 is built, this hand-off escalates under `--drive` (FR72's own gap), so the
supervisor dispatches that queue pass by hand.

### Sibling consequences — 2026-11-27, design `213b`

This entry uses FR68's form on its own decision, so the first `queue` pass to read the shape reads
a real one.
- **0069** (Add a live domain-model and decision-record discipline to design and develop). It is at
  `design | ready`, and `claimed_by:` was empty when read. Its work lands in `skills/design/SKILL.md`
  Step 4, which FR68 and FR70 also change. Queue should check that 0069's criteria do not contradict
  "design writes no unheld item" or the `### Sibling consequences` hand-off, and should check where
  a decision record about another item goes. Why: two tickets rewriting one step, each blind to the
  other.
- **One file per slice** (no row yet; it still needs one). FR68 places the subsection in the held
  item's Notes. Once slices are files, "needs revisiting" becomes a slice status, and FR68/FR69 should
  name the slice file. The epic's criteria should carry that migration.
- **Sprint judges loops** (no row yet; it still needs one). FR72 deliberately counts design → queue
  against `bounce_max`. That epic's criteria should name FR72's arm as one it replaces.

### Open questions for the unspecified slices

**Settled 2026-11-27 by design `b7a4` (S5, FR50–FR52) — kept as the question it answered. Established, not yet specified (it was at next: queue), from 0217 — Stop a note written below the last AC from changing that AC's digest:**

- Either `--ac-digest` ends an AC at a line that is not a `- [ ] ACn` continuation, or `develop`'s re-entry guidance names where a stop note goes. The recurrence argues for the script fix: a note's position is not something a session reliably reads guidance about.
- **2026-11-27 (develop, b3fa): S5 is next and `unspecified`, so this leg routes the ticket to `design` and builds nothing.**
  The defect still reproduces in the code: `ac_digest_of` in `skills/queue/templates/next`
  appends every line after an AC's label line to that AC until the next `label` line or `## `
  heading (`label != "" { text = text " " $0 }`), so prose below the last AC is part of its
  digest. What design owes, so that S5 can carry ACs:
  1. **Script fix or guidance?** The established lean above is the script fix.
  2. **If it is the script fix, what ends an AC.** It could be a blank line, a line that is neither
     indented nor a label, or an explicit marker. A blank-line rule would also cut a multi-paragraph
     AC, so check the live items for one before choosing.
  3. **Migration.** Changing the normalisation changes the digest of every stamped AC that has
     trailing text, in this backlog and in every consuming one. After an upgrade, `--drift` and
     `close` would report drift that no person caused. Decide whether stamps are recomputed
     (by whom, and in which commit) or whether the old digest is accepted alongside the new one.
  S6 and S7 come straight after S5 and are also `unspecified`. If design specifies S5–S7 in one
  pass, it saves two more develop→design round trips. This leg did not reorder the specified S8
  ahead of them: the dispatch pointed at the unspecified-slice route, and the slice order is the
  author's sequencing.

**Settled 2026-11-27 by design `b7a4` (S6, FR53–FR54) — kept as the question it answered. Established, not yet specified (it was at next: queue), from 0219 — Make reopen leave a ticket that verify can close when it reopens a develop self-close:**

- Options: `reopen` resets `close_by` to `verify` when the reopen is for an independent verify (a flag or a reason class), or `close` accepts a verify close on a reopened row. The first keeps `close`'s refusal simple.

**Settled 2026-11-27 by design `3708` (S7, FR42–FR43, FR55–FR58) — kept as the question it answered. Open design question, from 0235 — Decide whether claim, handoff and close refuse off the branch the backlog is shared on:**

Refuse or warn when the checked-out branch is not the one the backlog is shared on — and how does a
script know which branch that is (a `config.yml` key, the remote's HEAD, or `main` by default)?

**Settled 2026-11-27 by design `56a2` (S12, FR44–FR45, FR59–FR60) — kept as the question it answered. Open design question, from 0237 — Give queue a way to send an open verify ticket back to design:**

Which carries it: a named operation in `queue` Step 1 that claims then `./handoff … design`, an
unclaimed form of `./handoff`, or `./reopen` taking a target stage?

**Settled 2026-11-27 by design `213b` (S13, FR67–FR73), on the person's answer — kept as the question it answered. Open design question, from 0236 — Decide whether design may amend unheld sibling items its own FRs name:**

Either name a second narrow exception in *A stage writes only the ticket it holds* (unheld, non-done
items named in the held item's own FRs, under the lock, in the decision's commit), or have `queue`
stop writing FRs that amend other items. Which?

- **2026-11-27 (develop, 38d6): S12 is next and `unspecified`, so this leg routes the ticket to `design` and builds nothing.**
  S11 passed verify at `0c2da1e`; the first unticked slice is S12, and S13 and S15 are also
  `unspecified`. A grep for `0237` and `0236` outside `.tickets/` finds nothing, so neither has
  been built ad hoc. `skills/queue/templates/reopen` still takes only `<id> <top|above:<row-id>> <reason>`,
  with no target stage, and `handoff` still needs a claim token. What design owes:
  1. **S12 (FR44–FR45, from 0237):** which carries the verify → design move, as the open question
     above puts it: a `queue` Step 1 operation that claims and then runs `./handoff … design`, an
     unclaimed form of `./handoff`, or `./reopen` taking a target stage. Then the ACs, and the slice
     they belong to.
  2. **S13 (FR46, from 0236):** a second narrow exception in *A stage writes only the ticket it holds*,
     or `queue` stops writing FRs that amend other items. Then its ACs.
  3. **S15 (FR22, AC28):** whether `--drive` gates on an `expects:` path that exists nowhere, and
     whether a path commented `# new` is exempt. AC28 is already written, so design specifies it
     rather than writes it.
  If one design pass settles S12, S13 and S15 together, it saves two develop → design round trips.
  This leg did not move the specified S14 ahead of them. The dispatch pointed at the
  unspecified-slice route, and the slice order is the author's. If design would rather build S14
  first, it can re-order the slices.
  The first `./claim 0242` died at `claim:149` with `xxd: not found` before taking the lock, so
  nothing was written. `./claim 0242 38d6`, with the token minted by `od`, succeeded at `40e2b59`.
  That gap is already parked twice in `.tickets/FINDINGS.md`.

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
