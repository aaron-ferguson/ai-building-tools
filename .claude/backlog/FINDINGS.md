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
