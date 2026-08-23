# Findings — parked, not yet placed

**One or two lines each, dated, newest at the top.** This is a buffer, not a second backlog: it
holds findings whose home is **not local and not yet decided** — a possible row, a suspected skill
or convention problem, a cost pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in
a comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a
row. Parking those is how a session ends with nothing written down *and* a growing file.

**Two sweepers empty this file, and they take different things.** `queue` takes the entries that
are **units of work** and specifies and ranks each one properly. `retro` takes the **lessons** and
lands them where they will be read again. **An entry that is both is taken by both** — classifying
at write time would put friction exactly where it is least wanted, at the moment of noticing, so
nothing here is tagged and neither sweeper waits for the other.

**Each sweeper removes only the entries it processed, and commits in the same turn.** Leaving a
processed entry is how the next sweep pays to read it again; removing an unprocessed one is how the
other sweeper's half disappears silently.

Every entry ends as a row, an edit, or a drop with a stated reason — so the normal state of this
file is empty. Entries older than about two weeks are dropped rather than processed: a finding
nobody acted on in two weeks was not worth acting on, and saying so is more honest than re-reading
it forever.

**If this file has grown, that is itself the finding** — retros are not running, or not emptying.

Format: `- YYYY-MM-DD — what happened, why it might matter (pointer: file, item id)`

---
- 2026-08-23 — `verify` Step 2's ownership test cannot see a **claimless writer**. It checks for an
  `in-progress` row under a token you did not mint; `retro` by design holds no ticket, so while it
  landed lessons into `skills/verify/SKILL.md`, `skills/queue/SKILL.md` and `references/CONCURRENCY.md`
  mid-pass, `QUEUE.md` showed exactly one in-progress row — mine — and the field-and-claim check read
  as clean while three files were dirty. Only `git status` caught it, and only because Step 2 is run
  again by habit rather than by instruction (pointer: skills/verify Step 2, skills/retro).
- 2026-08-23 — an **advisory PASS has no way to bank what it verified**. 0024's greens were checked
  against both the committed and the working-tree copy of every file its ACs rest on, so none was
  luck — but Step 7 still forbids closing, and the row goes back to `next: verify` carrying no record
  that the whole pass already ran. The next session re-runs 21 assertions, six mutations and a
  tree-wide grep to reach the same verdict, and the only thing that actually has to change is a dirty
  tree nobody in the pass controls. Either the verdict needs somewhere durable to sit, or advisory
  needs to distinguish "green may be luck" from "green survived both states" (pointer: skills/verify
  Steps 2 and 7, items/0024).
- 2026-08-23 — this repo's own backlog has **neither `next` nor `claim` installed**, so `/develop`'s
  Step 1 ("run `./next develop` rather than reading `QUEUE.md`") had no correct answer and the whole
  queue had to be read. The skill treats the scripts as present; the repo that ships them is the one
  place they are not (pointer: skills/develop Step 1, .claude/backlog/).
- 2026-08-23 — `/develop` Step 1 tells a session to claim with `./claim` and a minted token under
  `.lock`, but this repo's `QUEUE.md` prose now says ownership is the directory `claims/<id>/` and
  needs no lock. Two live protocols, and the item frontmatter still carries `claimed_by:`. Worse:
  **an empty `claims/<id>/` is invisible to git**, so it cannot be "durable the moment it is made"
  per CONCURRENCY.md — it needs a file in it. Input to 0007 (pointer: QUEUE.md prose, 0007).
- 2026-08-23 — the missing-scripts finding above names `/develop` Step 1, but `/verify` Step 1 has
  the identical gap: it says to run `./next verify` and `./claim <id>`, and this repo's backlog has
  neither, so the queue was read by hand and the claim done by hand under `.lock`. A retro fixing
  only the develop pointer would leave verify broken (pointer: skills/verify Step 1, 0023).
- 2026-08-23 — `next`/`claim`'s `fm_list` does not strip YAML `#` comments, so an inline comment on a
  `touches:` entry is returned as list entries and printed as claimed *files* in `./next`'s CLAIMED
  FILES block. Annotating a frontmatter list is a natural thing to do and there is nothing to warn
  you (pointer: templates/next `fm_list`, 0024).
- 2026-08-23 — `develop` Step 5 says run "the project's whole test suite, every runner it has", and
  this project has no runner at all: the suite is `tests/*.test.sh` run by hand, discoverable only by
  `ls`. Neither `config.yml`'s empty `commands:` block nor the skill says where the suite is, so each
  session rediscovers it (pointer: skills/develop Step 5, .claude/backlog/config.yml).
- 2026-08-23 — `develop` Step 1 opens "run `./next develop` rather than reading `QUEUE.md`", and this
  repo's own backlog has no `./next` and no `./claim`: both exist only as `skills/queue/templates/`,
  which `queue` instantiates on first use, and this backlog predates that. The documented fallback is
  to read the queue and apply the same rules by hand — which means reading the `Status` column, the
  stale cache this backlog's whole 0024 exists to stop anyone trusting. It bit immediately: this
  session read 0026 as `blocked`, skipped it, and took row 2; the template reader run afterwards
  offered `TAKE 0026`. The fallback should derive from `blocked_by` explicitly, or the skills should
  say to instantiate the scripts (pointer: skills/develop Step 1, skills/queue/templates/next,
  .claude/backlog/).
- 2026-08-23 — with the scripts un-instantiated, `.claude/backlog/QUEUE.md`'s header now documents
  `./next --drift` as the gate on a backlog where that command does not run. Kept matching the
  template deliberately — diverging the wording to describe a local gap is the two-conventions defect
  0024 forbids — so the fix belongs in instantiating the scripts, not in the prose (pointer: 0024,
  .claude/backlog/QUEUE.md).
- 2026-08-23 — `retro` cites `references/CONVENTIONS.md` with no qualifier, but the installed skill
  directory has no `references/` — the path is relative to the **plugin root**, which `develop` and
  `queue` both say explicitly ("at the plugin root") and `retro` and `verify` do not. Cost a wrong
  turn at Step 0, on the one instruction that says to stop if it does not resolve (pointer:
  skills/retro, skills/verify, skills/develop:30).
- 2026-08-23 — the reflow rule landed in `queue` this pass covers a *grep* over prose, but the same
  break hit an `Edit`: a replacement string quoting "…is edited, after which `verify` checks…" matched
  nothing, because the file wraps between the two words. Every prose edit to these files has the
  defect its assertions have, and nothing warns an editor (pointer: skills/queue qa_level, this
  session).
