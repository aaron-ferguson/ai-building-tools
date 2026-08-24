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

- 2026-08-24 — **`claim`'s success message is stage-blind: it tells every claimant to set `touches:`,
  which is `develop`'s field.** A `verify` claim holds no `touches:` — it reads and runs, it does not
  open a file scope — but the script prints "now set touches: ... before you open anything" regardless.
  The consequence is not cosmetic: `./next` then reports the row to every other session as
  `0027 [b8d3] none declared — assume held, ask`, so a correct `verify` claim is indistinguishable from
  an under-specified `develop` one, and CONCURRENCY's *read an empty `touches:` as held* makes that the
  safe-but-wrong reading (pointer: .claude/backlog/claim success path, references/CONCURRENCY.md
  *The working tree is shared too*, items/0027 AC5).

- 2026-08-24 — **`verify` has no correct answer for exercising a write-script when another session
  holds the backlog.** 0027 AC5 asks for a live `./claim` on "a scratch row", which means inserting and
  then removing a row in the shared `QUEUE.md` — while a `develop` session was mid-ticket on 0028 in the
  same table. Neither Step 2 (which forbids tidying another session's tree) nor Step 5 covers the case.
  Resolved by cloning the repo to the scratchpad and exercising `claim` and `close` there, which tests
  the same bytes without touching a live table; the skill should either name that as the method or AC5s
  should stop asking for a live row (pointer: skills/verify Step 2/Step 3, items/0027 AC5).

- 2026-08-24 — **the templates↔copies identity now has a permanent guard; repo↔installed-plugin
  identity still has none.** 0027 added `tests/backlog-scripts-installed.test.sh` so a drifted copy
  fails a suite run. The same failure one level up is unreported: the installed plugin at
  `~/.claude/plugins/cache/.../0.9.3/` is behind this repo by two merged tickets (0030's
  `notion`→`external_feedback` rename and 0027's own Step 0 edit), so the sessions running these skills
  are executing prose the repo no longer contains, and nothing points at it. `SOURCE` explains why the
  cache is disposable but gates nothing (pointer: SOURCE, skills/verify Step 2 *check which copy*).

- 2026-08-24 — **the lock protocol cannot be satisfied by hand, because a lock cannot be held across
  tool calls.** `CONCURRENCY.md` *Lock every write to `QUEUE.md`* requires the lock to be held "for the
  read, the write and the commit". A shell `trap` releases it when the Bash call exits, so a by-hand
  insert is two separate acquisitions with an **uncommitted `QUEUE.md` edit sitting unlocked between
  them**; omitting the trap instead leaks the lock on any failure path. `claim` and `close` satisfy the
  rule because each is one process — but **`queue` has no script for the row insert**, so the one
  operation this skill performs on `QUEUE.md` is the one with no compliant path. Either the insert
  earns a fourth script or the rule needs a documented by-hand form (pointer: references/CONCURRENCY.md
  *Lock every write*, skills/queue Step 3, items/0027).
- 2026-08-24 — **dates in the backlog have no stated timezone, and this file's stated order is not the
  order it is in.** `claimed_at:` is specified as ISO-8601 UTC but `created:` and these entries are bare
  dates: at 2026-08-23 local / 2026-08-24 UTC, two sessions working the same hour wrote different dates,
  and both are defensible. Separately, the header here says "newest at the top" while every entry so far
  was appended at the bottom — which matters because `retro` Step 1 expires "anything older than about
  two weeks" and reads the file in order (pointer: skills/queue/templates/item.md `created:`, this
  file's header, skills/retro Step 1).
- 2026-08-23 — **the installed plugin and the source tree can differ at the same version number, and
  nothing says so.** `0.9.2`'s installed `prototype/SKILL.md` is 26,262 bytes; source is 23,394 — the
  pre-0021 copy, so that trim was committed and never released. The installed `references/` is also
  missing `NOTION.md`. A session therefore resolves skills from a copy it cannot date, and `retro`'s
  Step 3 trap ("you may be running an older copy") has no check behind it: comparing the two needs the
  source checkout, which most sessions do not have. Bumping the version on a skill edit is already the
  rule; what is missing is anything that *fails* when the install and the source disagree, or any
  version marker a session can read from the installed side alone (pointer: SOURCE, skills/retro
  Step 5, .claude-plugin/plugin.json).
- 2026-08-23 — **"one skill per session" has no correct answer for a user who deliberately runs two.**
  `/queue` was invoked inside a live `retro` session, with approval of the retro's proposals as its
  argument. Both skills open by asserting isolation, neither says what to do when the human overrides
  it, and the two have different commit disciplines (`queue` commits only under `.claude/backlog/`,
  `retro` commits across several repos) — so the combined session's commits had to be split by hand
  against two rules that each assume they own the session. It worked, but nothing said it should
  (pointer: skills/queue Step 6, skills/retro Step 5, this session).

- **2026-08-24 — removing a preference from the base suite leaves a follow-up nothing owns.** 0030
  took Notion out of the base tool suite and documented the `external_feedback:` extension point a
  profile plugs into, but *wiring Aaron's own solo projects back up* is named in that ticket's *Out
  of scope* and therefore has no ticket at all. Any solo project with `notion.enabled: true` in a
  live `config.yml` now has a stated wiring path and no one carrying it out. The general shape is
  worth a rule: a ticket that moves a preference behind a profile creates a second, smaller ticket
  by construction — the port — and *Out of scope* is where it silently goes to die
  (pointer: items/0030, references/EXTERNAL-FEEDBACK.md "If you had `notion:` configured").
- **2026-08-24 — the base suite has no home for a solo profile, only a company one.**
  `CONVENTIONS_CORE.md` resolves preferences through `companies/<name>/`, and the conventions repo is
  public, so a *solo* preference (which feedback product, which personal tooling) has nowhere to live
  that is both private and discoverable. 0030 hit this deciding where `NOTION.md` should move to and
  could only answer "not here"; it deleted the file and pointed at git history instead. Every future
  "move X behind a profile" ticket hits the same wall (pointer: items/0030 FR4, CONVENTIONS_CORE.md
  "Profiles & How Overrides Work").
- 2026-08-24 — **`verify` Step 2's advisory trigger has no answer when the only dirty paths are the
  backlog's own coordination files.** Step 2 says any change outside the ticket makes the verdict
  advisory, and Step 7 says an advisory PASS does not close. But a concurrent `queue` session leaves
  `QUEUE.md` modified and an item file untracked — dirt that provably cannot influence a verdict
  (0030's own guard excludes `.claude/` by design), while the literal rule would forbid closing
  whenever another window is queueing, which is the concurrency the suite is built for. The
  distinction the rule wants is "dirty *under test*", not "dirty anywhere" (pointer: skills/verify
  Steps 2 and 7, items/0034).
- 2026-08-24 — **the busy-lock procedure is written for a claim and strands a close.**
  `CONCURRENCY-INCIDENTS.md` says a lock under 5 minutes old means "report it to the user and stop,
  do not break it". At claim time stopping costs nothing. At *close* time the verdict already exists
  and lives only in the session holding it, so stopping leaves the row `in-progress` under a token
  whose session is ending — the failure `verify` owns closing to prevent. Hit live this session: the
  lock was held by another window at close time, and the only safe move (wait, then retry) is
  nowhere in the procedure (pointer: references/CONCURRENCY-INCIDENTS.md *A busy or stale lock*,
  skills/verify Step 5, items/0034).
- 2026-08-24 — **"never rewrite `QUEUE.md` by hand" needs to name stream editors, not just `Write`.**
  Closing 0030 without the scripts, a stray `perl -i -ne` invocation left in the script with an
  unset variable expanded its match to `"\n"` and deleted **every blank line in the file** — the row
  removal itself was correct, so the commit's diffstat (14 deletions for a one-row close) was the
  only signal. `Edit`'s uniqueness check cannot produce this class of damage; an in-place regex over
  the whole file can, and the rule as written reads as being about `Write` and read-rebuild-write.
  Repaired in the next commit. This is the strongest argument yet for 0027 (pointer:
  references/CONCURRENCY.md *Never rewrite `QUEUE.md` by hand*, items/0027, commits 7d5ce6f/1850ef2).
- 2026-08-24 — **`develop`'s "say inline that it is new" instruction poisons the reader it installs.**
  Step 1 says to declare a file you will create in `touches:` and mark it new inline. `fm_list` in
  `next` and `claim` does not strip YAML `#` comments (0031), so an inline comment there is emitted
  verbatim in `./next`'s CLAIMED FILES block as though it were a path. The two instructions are
  individually right and jointly wrong, and nothing in either flags the other. Either the skill says
  where the "it is new" note goes instead, or 0031 lands first (pointer: skills/develop Step 1,
  items/0031).
- 2026-08-24 — **`tests/skill-size.test.sh`'s exception registry cites a ticket that never accepted
  the cost.** `skills/develop/SKILL.md`'s entry reads `0027 — carries the re-entry and staleness
  rules`, but 0027 is the script install and never touched that file; the described work ("its
  anecdotes are the relocation candidates") is 0035's question. The registry's own contract is "the
  ticket that accepted the cost", and a wrong ID there is invisible because the test passes either
  way — the reason is the control, not a number, so nothing ever checks the citation resolves. Same
  failure class as 0033 but for ticket IDs rather than rule names (pointer:
  tests/skill-size.test.sh:39, items/0033, items/0035).
- 2026-08-24 — **this project has no `CLAUDE.md`, so no session reads its Profile.**
  `CONVENTIONS_CORE.md` requires every project to declare `collaboration`, `company` and `release` in
  its own `CLAUDE.md`, and the precedence chain names it as the top override. There is none at the
  repo root, so a session inherits `~/Documents/AI/CLAUDE.md` — a personal memory file for a
  different purpose — and `release:` is absent, which the conventions say resolves to `released`. Both
  `queue` Step 0 and `develop` Step 3 tell a session to read the project's `CLAUDE.md`; here that
  read silently finds a parent (pointer: CONVENTIONS_CORE.md *Profiles & How Overrides Work*,
  skills/develop Step 3).
- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
- 2026-08-24 — **`develop` Step 1 tells a session to run `./next develop`, and the run leaves the
  Bash tool's working directory inside `.claude/backlog/`** for the rest of the session, because the
  natural way to reach the scripts is `cd .claude/backlog && ./next`. Every later repo-root path then
  fails with `no such file or directory` — including `.claude/backlog/claim`, which reads as the
  script being absent rather than the cwd having moved. Two calls were lost to it here. The step
  could show the invocation from the repo root (pointer: skills/develop Step 1).
- 2026-08-24 — **`develop` Step 5's mutation rule is stated for the *result* but not for the
  *mutation's own validity*, and the cheap mutation is the invalid one.** Deleting a `case` branch
  from a `sh` guard to prove it can fail left a dangling `echo` and red on a syntax error — a red
  that looks like the guard biting. `testing-conventions.md` names this ("a malformed one reds for
  the wrong reason"); the skill cites the diff-the-mutation half but not the read-the-red half, and
  the diff was non-empty in both the valid and the invalid attempt, so the diff alone does not
  separate them (pointer: skills/develop Step 5, testing-conventions.md *Prove a new guard fails*,
  items/0028 develop-pass notes).
- 2026-08-24 — **`tests/backlog-scripts-installed.test.sh` is not in README's guard list**, so the
  block README offers as "run every guard" runs seven of eight. Noticed from 0028 while adding the
  eighth line beside it; left for whoever owns 0027's tail rather than fixed, since that file landed
  in a session running concurrently with this one (pointer: README.md *Testing*, items/0027).
- 2026-08-24 — **a justification entry whose file no longer exists passes silently, in both size
  gates.** Removing `references/CONCURRENCY-INCIDENTS.md` while its `case` branch stayed left the
  gate green at 9/0, exit 0 — the pass line just stops naming it. This is the staleness AC4 exists to
  catch, from the other direction, and it is a live risk precisely because the gate's own first
  recommendation is *relocation*, the operation most likely to rename a file out from under its
  entry. `tests/skill-size.test.sh` has the identical shape (iterate the tree, look up a reason;
  never the reverse), so a fix wants to land in both — which is the third-instance DRY question the
  entry above already parks. A `[ -f ]` sweep over the recorded paths closes it in about three lines
  (pointer: tests/reference-size.test.sh, tests/skill-size.test.sh, items/0028 verify notes).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
