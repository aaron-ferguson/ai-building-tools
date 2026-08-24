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
